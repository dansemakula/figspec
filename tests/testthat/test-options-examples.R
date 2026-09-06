test_that("every fig_save argument has an executable documentation example", {
  skip_if_not_installed("yaml")
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("ragg")

  examples_file <- options_examples_path()
  examples <- yaml::read_yaml(examples_file)$fig_save

  expected_arguments <- c(
    "filename", "plot", "spec", "column", "width", "height",
    "panel_width, panel_height", "units", "dpi", "transform", "check",
    "art_type", "..."
  )
  expect_setequal(names(examples$arguments), expected_arguments)

  example_env <- new.env(parent = globalenv())
  eval(parse(text = examples$setup), envir = example_env)

  for (argument in expected_arguments) {
    example <- examples$arguments[[argument]]
    expect_true(nzchar(example$prose), info = argument)
    expect_true(nzchar(example$result), info = argument)

    evaluate_example <- function() {
      suppressMessages(eval(parse(text = example$code), envir = example_env))
    }
    value <- if (identical(argument, "check")) {
      checked_value <- NULL
      expect_warning(checked_value <- evaluate_example(), "Axis origin")
      checked_value
    } else {
      evaluate_example()
    }

    if (identical(argument, "check")) {
      expect_s3_class(value, "data.frame")
      expect_true(all(c("check", "requirement", "actual", "status") %in% names(value)))
      axis_origin <- value[value$check == "Axis origin", , drop = FALSE]
      expect_equal(axis_origin$status, "fail")
    } else {
      expect_true(file.exists(as.character(value)), info = argument)
      expect_gt(file.size(as.character(value)), 0)
    }
  }
})

test_that("fig_save argument examples achieve the dimensions and resolution they describe", {
  skip_if_not_installed("yaml")
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("ragg")

  examples_file <- options_examples_path()
  examples <- yaml::read_yaml(examples_file)$fig_save
  example_env <- new.env(parent = globalenv())
  eval(parse(text = examples$setup), envir = example_env)

  run <- function(argument) {
    suppressMessages(eval(parse(text = examples$arguments[[argument]]$code),
                          envir = example_env))
  }
  geometry <- function(path) attr(path, "figspec_geometry")

  expect_equal(geometry(run("width"))$canvas_width_mm, 120, tolerance = 0.05)
  expect_equal(geometry(run("height"))$canvas_height_mm, 50, tolerance = 0.05)

  pnas <- run("spec")
  expect_equal(geometry(pnas)$canvas_width_mm, 90, tolerance = 0.05)
  expect_equal(figspec:::inspect_file(pnas)$dpi, 300, tolerance = 1)
  expect_equal(geometry(run("column"))$canvas_width_mm, 180, tolerance = 0.05)

  panel <- geometry(run("panel_width, panel_height"))
  expect_equal(panel$panel_width_mm, 62, tolerance = 0.05)
  expect_equal(panel$panel_height_mm, 45, tolerance = 0.05)

  centimetres <- geometry(run("units"))
  expect_equal(centimetres$canvas_width_mm, 85, tolerance = 0.05)
  expect_equal(centimetres$canvas_height_mm, 60, tolerance = 0.05)

  high_resolution <- run("dpi")
  expect_equal(figspec:::inspect_file(high_resolution)$dpi, 600, tolerance = 1)

  line_art <- run("art_type")
  expect_equal(figspec:::inspect_file(line_art)$dpi, 1000, tolerance = 1)

  project_file <- fig_save(
    file.path(tempdir(), "project-specification.png"),
    example_env$p,
    spec = example_env$report_spec,
    column = "full",
    check = FALSE
  )
  expect_equal(geometry(project_file)$canvas_width_mm, 160, tolerance = 0.05)
  expect_equal(figspec:::inspect_file(project_file)$dpi, 300, tolerance = 1)
})

test_that("every fig_check argument has an executable real-world example", {
  skip_if_not_installed("yaml")
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("ragg")

  examples_file <- options_examples_path()
  examples <- yaml::read_yaml(examples_file)$fig_check
  expected_arguments <- c(
    "x", "spec", "column", "width, height", "units", "dpi", "format",
    "colour_mode", "color_mode", "art_type"
  )
  expect_setequal(names(examples$arguments), expected_arguments)

  example_env <- new.env(parent = globalenv())
  eval(parse(text = examples$setup), envir = example_env)
  expect_true(file.exists(as.character(example_env$pnas_file)))

  reports <- lapply(expected_arguments, function(argument) {
    example <- examples$arguments[[argument]]
    expect_true(nzchar(example$prose), info = argument)
    expect_true(nzchar(example$result), info = argument)
    value <- suppressMessages(
      eval(parse(text = example$code), envir = example_env)
    )
    expect_s3_class(value, "data.frame")
    expect_true(all(c("check", "requirement", "actual", "status") %in% names(value)))
    value
  })
  names(reports) <- expected_arguments

  row_for <- function(argument, check) {
    reports[[argument]][reports[[argument]]$check == check, , drop = FALSE]
  }

  saved_file_checks <- reports$x[
    reports$x$check %in% c("File validity", "Width", "Resolution", "File format"),
    , drop = FALSE
  ]
  expect_true(all(saved_file_checks$status == "pass"))

  expect_equal(trimws(row_for("column", "Width")$actual), "110 mm")
  expect_equal(row_for("column", "Width")$status, "pass")
  expect_equal(trimws(row_for("width, height", "Width")$actual), "90 mm")
  expect_equal(row_for("width, height", "Width")$status, "pass")
  expect_equal(trimws(row_for("units", "Width")$actual), "90 mm")
  expect_equal(row_for("units", "Width")$status, "pass")
  expect_equal(row_for("dpi", "Resolution")$status, "pass")
  expect_equal(row_for("format", "File format")$status, "fail")
  expect_equal(row_for("format", "File format")$actual, "JPEG")
  expect_equal(row_for("colour_mode", "Colour mode")$status, "pass")
  expect_equal(row_for("color_mode", "Colour mode")$status, "pass")

  resolution_comparison <- reports$art_type
  expect_equal(resolution_comparison$status, c("pass", "fail"))
  expect_match(resolution_comparison$requirement[[1]], "300 dpi")
  expect_match(resolution_comparison$requirement[[2]], "1000 dpi")

  project_report <- fig_check(
    example_env$p,
    spec = example_env$report_spec,
    column = "full",
    height = 95,
    dpi = 300,
    format = "png",
    art_type = "colour"
  )
  project_core <- project_report[
    project_report$check %in% c("Width", "Resolution", "File format"),
    , drop = FALSE
  ]
  expect_true(all(project_core$status == "pass"))
})

test_that("fig_geometry examples measure and draw a real exported figure", {
  skip_if_not_installed("yaml")
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("ragg")

  examples_file <- options_examples_path()
  examples <- yaml::read_yaml(examples_file)$fig_geometry
  expect_setequal(names(examples$arguments), c("x", "..."))

  example_env <- new.env(parent = globalenv())
  eval(parse(text = examples$setup), envir = example_env)
  expect_true(file.exists(as.character(example_env$saved)))
  expect_s3_class(fig_geometry(example_env$saved), "figspec_geometry")

  measured <- suppressMessages(eval(
    parse(text = examples$arguments$x$code),
    envir = example_env
  ))
  expect_s3_class(measured, "figspec_geometry")
  expect_equal(measured$panel_width_mm, 62, tolerance = 0.05)
  expect_equal(measured$panel_height_mm, 45, tolerance = 0.05)
  expect_gt(measured$canvas_width_mm, measured$panel_width_mm)
  expect_gt(measured$canvas_height_mm, measured$panel_height_mm)

  diagram_with_dots <- suppressMessages(eval(
    parse(text = examples$arguments[["..."]]$code),
    envir = example_env
  ))
  expect_s3_class(diagram_with_dots, "ggplot")

  diagram_data <- ggplot2::ggplot_build(diagram_with_dots)$data[[1]]
  expect_equal(nrow(diagram_data), 2L)
  expect_setequal(toupper(diagram_data$fill), c("#F1F4F5", "#DCEFF5"))
  expect_setequal(toupper(diagram_data$colour), c("#98A6AD", "#1A7391"))
})

test_that("fig_apply_spec examples make the stated changes to a real plot", {
  skip_if_not_installed("yaml")
  skip_if_not_installed("ggplot2")

  examples_file <- options_examples_path()
  examples <- yaml::read_yaml(examples_file)$fig_apply_spec
  expected_arguments <- c(
    "spec", "colour", "shapes", "style", "base_size", "color"
  )
  expect_setequal(names(examples$arguments), expected_arguments)

  old_styles <- .figspec_cache$styles
  withr::defer(.figspec_cache$styles <- old_styles)
  example_env <- new.env(parent = globalenv())
  eval(parse(text = examples$setup), envir = example_env)

  plots <- lapply(expected_arguments, function(argument) {
    example <- examples$arguments[[argument]]
    expect_true(nzchar(example$prose), info = argument)
    expect_true(nzchar(example$result), info = argument)
    value <- suppressMessages(
      eval(parse(text = example$code), envir = example_env)
    )
    expect_s3_class(value, "ggplot")
    expect_no_error(ggplot2::ggplot_build(value))
    value
  })
  names(plots) <- expected_arguments

  expect_setequal(
    figspec:::plot_colours(plots$spec),
    figspec_palette("okabe_ito", 3)
  )
  expect_setequal(
    unique(ggplot2::ggplot_build(plots$spec)$data[[1]]$shape),
    figspec_shapes(3)
  )
  journal_check <- fig_check(plots$spec, "cell_press", column = "single")
  expect_equal(journal_check$status[journal_check$check == "Type size"], "pass")

  expect_setequal(
    toupper(unique(ggplot2::ggplot_build(plots$colour)$data[[1]]$colour)),
    toupper(unname(example_env$manual_colours))
  )
  expect_setequal(
    unique(ggplot2::ggplot_build(plots$shapes)$data[[1]]$shape),
    unname(example_env$manual_shapes)
  )

  styled_theme <- ggplot2::ggplot_build(plots$style)$plot$theme
  expect_identical(styled_theme$legend.position, "bottom")
  expect_s3_class(styled_theme$panel.grid.minor, "element_blank")
  expect_gte(min(figspec:::collect_text_sizes(plots$style)$size_pt), 8)

  large_theme <- ggplot2::ggplot_build(plots$base_size)$plot$theme
  expect_equal(large_theme$text$size, 10)
  expect_equal(large_theme$axis.title$size, 10)
  expect_equal(large_theme$plot.title$size, 12)

  expect_setequal(
    figspec:::plot_colours(plots$color),
    figspec_palette("okabe_ito", 3)
  )

  project_plot <- example_env$base_plot + fig_apply_spec(example_env$report_spec)
  expect_no_error(ggplot2::ggplot_build(project_plot))
  expect_setequal(
    figspec:::plot_colours(project_plot),
    figspec_palette("cividis", 3)
  )
  expect_gte(min(figspec:::collect_text_sizes(project_plot)$size_pt), 10)
})

test_that("fig_preview examples open at the stated physical sizes", {
  skip_if_not_installed("yaml")
  skip_if_not_installed("ggplot2")

  examples_file <- options_examples_path()
  examples <- yaml::read_yaml(examples_file)$fig_preview
  expected_arguments <- c("plot", "spec", "column", "height", "units")
  expect_setequal(names(examples$arguments), expected_arguments)

  example_env <- new.env(parent = globalenv())
  eval(parse(text = examples$setup), envir = example_env)

  withr::local_dir(withr::local_tempdir())
  testthat::local_mocked_bindings(is_interactive = function() TRUE)
  on.exit(
    while (grDevices::dev.cur() > 1L) grDevices::dev.off(),
    add = TRUE
  )

  expected_mm <- list(
    plot = c(90, 67.5),
    spec = c(90, 67.5),
    column = c(180, 135),
    height = c(90, 60),
    units = c(90, 60)
  )

  for (argument in expected_arguments) {
    while (grDevices::dev.cur() > 1L) grDevices::dev.off()
    example <- examples$arguments[[argument]]
    expect_true(nzchar(example$prose), info = argument)
    expect_true(nzchar(example$result), info = argument)

    returned <- suppressMessages(
      eval(parse(text = example$code), envir = example_env)
    )
    expect_identical(returned, example_env$p)
    expect_equal(
      grDevices::dev.size("in") * 25.4,
      expected_mm[[argument]],
      tolerance = 0.03
    )
  }

  while (grDevices::dev.cur() > 1L) grDevices::dev.off()
  returned <- suppressMessages(fig_preview(
    example_env$p,
    example_env$report_spec,
    "full"
  ))
  expect_identical(returned, example_env$p)
  expect_equal(
    grDevices::dev.size("in") * 25.4,
    c(160, 120),
    tolerance = 0.03
  )
})

test_that("fig_panel_size examples set and render real panel dimensions", {
  skip_if_not_installed("yaml")
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("ragg")

  examples_file <- options_examples_path()
  examples <- yaml::read_yaml(examples_file)$fig_panel_size
  expected_arguments <- c("plot", "width, height", "units")
  expect_setequal(names(examples$arguments), expected_arguments)

  example_env <- new.env(parent = globalenv())
  eval(parse(text = examples$setup), envir = example_env)

  geometries <- lapply(expected_arguments, function(argument) {
    example <- examples$arguments[[argument]]
    expect_true(nzchar(example$prose), info = argument)
    expect_true(nzchar(example$result), info = argument)
    value <- suppressMessages(
      eval(parse(text = example$code), envir = example_env)
    )
    expect_s3_class(value, "figspec_geometry")
    value
  })
  names(geometries) <- expected_arguments

  expect_equal(geometries$plot$panel_width_mm, 28, tolerance = 0.05)
  expect_equal(geometries$plot$panel_height_mm, 40, tolerance = 0.05)
  expect_equal(geometries$plot$panels_across, 3L)
  expect_equal(
    geometries$plot$canvas_width_mm,
    28 * 3 + geometries$plot$left_mm + geometries$plot$right_mm +
      geometries$plot$gap_x_mm,
    tolerance = 0.05
  )

  for (argument in c("width, height", "units")) {
    expect_equal(
      geometries[[argument]]$panel_width_mm,
      62,
      tolerance = 0.05
    )
    expect_equal(
      geometries[[argument]]$panel_height_mm,
      45,
      tolerance = 0.05
    )
    expect_gt(
      geometries[[argument]]$canvas_width_mm,
      geometries[[argument]]$panel_width_mm
    )
  }

  rendered <- fig_panel_size(example_env$faceted, width = 28, height = 40)
  output <- file.path(withr::local_tempdir(), "three-panels.png")
  ragg::agg_png(output, width = 140, height = 80, units = "mm", res = 150)
  on.exit(
    if (grDevices::dev.cur() > 1L) grDevices::dev.off(),
    add = TRUE
  )
  grid::grid.newpage()
  grid::grid.draw(rendered)
  grDevices::dev.off()
  expect_true(file.exists(output))
  expect_gt(file.info(output)$size, 10000)
})

test_that("fig_panel_width examples align and export a real figure set", {
  skip_if_not_installed("yaml")
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("ragg")

  examples_file <- options_examples_path()
  examples <- yaml::read_yaml(examples_file)$fig_panel_width
  expected_arguments <- c(
    "plots", "spec", "column", "width", "units", "format"
  )
  expect_setequal(names(examples$arguments), expected_arguments)

  example_env <- new.env(parent = globalenv())
  eval(parse(text = examples$setup), envir = example_env)

  values <- lapply(expected_arguments, function(argument) {
    example <- examples$arguments[[argument]]
    expect_true(nzchar(example$prose), info = argument)
    expect_true(nzchar(example$result), info = argument)
    value <- suppressMessages(
      eval(parse(text = example$code), envir = example_env)
    )
    expect_true(is.numeric(value), info = argument)
    expect_true(all(is.finite(value) & value > 0), info = argument)
    value
  })
  names(values) <- expected_arguments

  per_figure <- attr(example_env$shared_width, "per_figure")
  expect_named(per_figure, names(example_env$figs))
  expect_equal(
    as.numeric(example_env$shared_width),
    min(per_figure),
    tolerance = 1e-8
  )
  expect_lt(
    per_figure[["labels_with_units"]],
    per_figure[["numeric_labels"]]
  )

  expect_equal(
    as.numeric(example_env$cell_press_width),
    as.numeric(example_env$tiff_width),
    tolerance = 1e-8
  )
  expect_gt(
    as.numeric(example_env$double_column_width),
    as.numeric(example_env$cell_press_width)
  )
  expect_equal(
    as.numeric(example_env$report_width_cm) * 10,
    as.numeric(example_env$report_width),
    tolerance = 0.05
  )

  project_width <- fig_panel_width(
    example_env$figs,
    example_env$report_spec,
    column = "full"
  )
  expect_equal(
    as.numeric(project_width),
    as.numeric(example_env$report_width),
    tolerance = 0.05
  )

  outputs <- file.path(
    withr::local_tempdir(),
    paste0(names(example_env$figs), ".png")
  )
  saved <- Map(function(path, plot) {
    suppressMessages(fig_save(
      path,
      plot,
      width = 150,
      height = 95,
      panel_width = example_env$report_width,
      dpi = 150,
      check = FALSE
    ))
  }, outputs, example_env$figs)
  geometry <- lapply(saved, fig_geometry)

  expect_true(all(file.exists(outputs)))
  expect_true(all(file.info(outputs)$size > 10000))
  expect_equal(
    unname(vapply(geometry, function(x) x$canvas_width_mm, numeric(1))),
    rep(150, 2),
    tolerance = 0.05
  )
  expect_equal(
    diff(range(vapply(
      geometry,
      function(x) x$panel_width_mm,
      numeric(1)
    ))),
    0,
    tolerance = 0.05
  )
})

test_that("theme_spec examples apply and render the stated theme choices", {
  skip_if_not_installed("yaml")
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("ragg")

  examples_file <- options_examples_path()
  examples <- yaml::read_yaml(examples_file)$theme_spec
  expected_arguments <- c(
    "spec", "base", "style", "base_size", "base_family"
  )
  expect_setequal(names(examples$arguments), expected_arguments)

  old_styles <- .figspec_cache$styles
  withr::defer(.figspec_cache$styles <- old_styles)
  example_env <- new.env(parent = globalenv())
  suppressMessages(eval(parse(text = examples$setup), envir = example_env))

  plots <- lapply(expected_arguments, function(argument) {
    example <- examples$arguments[[argument]]
    expect_true(nzchar(example$prose), info = argument)
    expect_true(nzchar(example$result), info = argument)
    value <- suppressMessages(
      eval(parse(text = example$code), envir = example_env)
    )
    expect_s3_class(value, "ggplot")
    expect_no_error(ggplot2::ggplot_build(value))
    value
  })
  names(plots) <- expected_arguments

  publication_sizes <- collect_text_sizes(plots$spec)$size_pt
  expect_gte(min(publication_sizes), 8)
  expect_lte(max(publication_sizes), 12)
  publication_check <- fig_check(plots$spec, "plos_one")
  expect_equal(
    publication_check$status[publication_check$check == "Type size"],
    "pass"
  )

  project_plot <- example_env$base_plot + theme_spec(example_env$report_spec)
  expect_gte(min(collect_text_sizes(project_plot)$size_pt), 10)
  expect_lte(max(collect_text_sizes(project_plot)$size_pt), 14)

  minimal_theme <- ggplot2::ggplot_build(plots$base)$plot$theme
  expect_s3_class(minimal_theme$panel.background, "element_blank")

  styled_theme <- ggplot2::ggplot_build(plots$style)$plot$theme
  expect_identical(styled_theme$legend.position, "bottom")
  expect_s3_class(styled_theme$panel.grid.minor, "element_blank")
  expect_equal(styled_theme$axis.text$size, 8)

  larger_theme <- ggplot2::ggplot_build(plots$base_size)$plot$theme
  expect_equal(larger_theme$text$size, 10)
  expect_equal(larger_theme$plot.title$size, 12)

  family_theme <- ggplot2::ggplot_build(plots$base_family)$plot$theme
  expect_identical(family_theme$text$family, "serif")
  expect_gte(min(collect_text_sizes(plots$base_family)$size_pt), 10)

  outputs <- file.path(
    withr::local_tempdir(),
    paste0("theme-", expected_arguments, ".png")
  )
  Map(function(path, plot) {
    ggplot2::ggsave(
      path,
      plot,
      device = ragg::agg_png,
      width = 140,
      height = 90,
      units = "mm",
      dpi = 150
    )
  }, outputs, plots)
  expect_true(all(file.exists(outputs)))
  expect_true(all(file.info(outputs)$size > 10000))
})

test_that("style_register examples register and apply real styles", {
  skip_if_not_installed("yaml")
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("ragg")

  examples_file <- options_examples_path()
  examples <- yaml::read_yaml(examples_file)$style_register
  expected_arguments <- c("name", "theme", "description")
  expect_setequal(names(examples$arguments), expected_arguments)

  old_styles <- .figspec_cache$styles
  withr::defer(.figspec_cache$styles <- old_styles)
  example_env <- new.env(parent = globalenv())
  eval(parse(text = examples$setup), envir = example_env)

  values <- lapply(expected_arguments, function(argument) {
    example <- examples$arguments[[argument]]
    expect_true(nzchar(example$prose), info = argument)
    expect_true(nzchar(example$result), info = argument)
    suppressMessages(eval(parse(text = example$code), envir = example_env))
  })
  names(values) <- expected_arguments

  expect_s3_class(values$name, "data.frame")
  expect_s3_class(values$theme, "ggplot")
  expect_no_error(ggplot2::ggplot_build(values$theme))
  expect_s3_class(values$description, "data.frame")

  registered <- style_list()
  expect_true(all(c(
    "research_report", "presentation", "manuscript"
  ) %in% registered$name))
  expect_equal(
    registered$description[registered$name == "manuscript"],
    "Black-and-white manuscript figures"
  )

  named_plot <- example_env$p + theme_spec(
    example_env$report_spec,
    style = "research_report"
  )
  named_theme <- ggplot2::ggplot_build(named_plot)$plot$theme
  expect_identical(named_theme$legend.position, "bottom")

  presentation_theme <- ggplot2::ggplot_build(values$theme)$plot$theme
  expect_identical(presentation_theme$legend.position, "bottom")
  expect_s3_class(presentation_theme$panel.grid.major.y, "element_line")
  expect_equal(presentation_theme$panel.grid.major.y$colour, "#D7E3E8")
  expect_equal(presentation_theme$panel.grid.major.y$linewidth, 0.3)
  expect_equal(presentation_theme$axis.text$size, 9)
  expect_identical(presentation_theme$plot.title$face, "bold")

  style_register("dynamic_style", function() ggplot2::theme_void())
  expect_s3_class(resolve_style("dynamic_style"), "theme")

  output <- file.path(withr::local_tempdir(), "registered-style.png")
  ggplot2::ggsave(
    output,
    values$theme,
    device = ragg::agg_png,
    width = 140,
    height = 90,
    units = "mm",
    dpi = 150
  )
  expect_true(file.exists(output))
  expect_gt(file.info(output)$size, 10000)
})

test_that("style_list example lists the styles available in the session", {
  skip_if_not_installed("yaml")
  skip_if_not_installed("ggplot2")

  examples_file <- options_examples_path()
  examples <- yaml::read_yaml(examples_file)$style_list
  expect_true(nzchar(examples$introduction))
  expect_true(nzchar(examples$example$prose))
  expect_true(nzchar(examples$example$code))
  expect_true(nzchar(examples$example$result))

  old_styles <- .figspec_cache$styles
  withr::defer(.figspec_cache$styles <- old_styles)
  .figspec_cache$styles <- NULL

  example_env <- new.env(parent = globalenv())
  suppressMessages(eval(parse(text = examples$setup), envir = example_env))
  available <- suppressMessages(eval(
    parse(text = examples$example$code),
    envir = example_env
  ))

  expect_s3_class(available, "data.frame")
  expect_identical(names(available), c("name", "description"))
  expect_equal(nrow(available), 2L)
  expect_setequal(available$name, c("research_report", "presentation"))
  expect_equal(
    available$description[available$name == "research_report"],
    "Figures for research reports"
  )
  expect_equal(
    available$description[available$name == "presentation"],
    "Figures for presentations"
  )
})

test_that("style_remove example removes only the named style", {
  skip_if_not_installed("yaml")
  skip_if_not_installed("ggplot2")

  examples_file <- options_examples_path()
  examples <- yaml::read_yaml(examples_file)$style_remove
  expect_setequal(names(examples$arguments), "name")

  old_styles <- .figspec_cache$styles
  withr::defer(.figspec_cache$styles <- old_styles)
  .figspec_cache$styles <- NULL

  example_env <- new.env(parent = globalenv())
  suppressMessages(eval(parse(text = examples$setup), envir = example_env))
  example <- examples$arguments$name
  expect_true(nzchar(example$prose))
  expect_true(nzchar(example$code))
  expect_true(nzchar(example$result))

  result <- suppressMessages(eval(
    parse(text = example$code),
    envir = example_env
  ))
  expect_type(result, "list")
  expect_true(result$removed)
  expect_setequal(
    result$before$name,
    c("research_report", "presentation")
  )
  expect_identical(result$after$name, "research_report")
  expect_error(
    theme_spec(
      list(name = "Report", font_min_pt = 9),
      style = "presentation"
    ),
    class = "figspec_not_found"
  )
})

test_that("style_save example writes the current style registry", {
  skip_if_not_installed("yaml")
  skip_if_not_installed("ggplot2")

  examples_file <- options_examples_path()
  examples <- yaml::read_yaml(examples_file)$style_save
  expect_setequal(names(examples$arguments), "path")

  old_styles <- .figspec_cache$styles
  withr::defer(.figspec_cache$styles <- old_styles)
  .figspec_cache$styles <- NULL

  example_env <- new.env(parent = globalenv())
  suppressMessages(eval(parse(text = examples$setup), envir = example_env))
  withr::defer(unlink(example_env$style_file))
  example <- examples$arguments$path
  expect_true(nzchar(example$prose))
  expect_true(nzchar(example$code))
  expect_true(nzchar(example$result))

  file_details <- suppressMessages(eval(
    parse(text = example$code),
    envir = example_env
  ))
  expect_s3_class(file_details, "data.frame")
  expect_identical(example_env$saved_path, example_env$style_file)
  expect_true(file.exists(example_env$saved_path))
  expect_gt(file.info(example_env$saved_path)$size, 0)

  stored <- readRDS(example_env$saved_path)
  expect_named(stored, "research_report")
  expect_identical(
    stored$research_report$description,
    "Figures for research reports"
  )
  expect_s3_class(stored$research_report$theme, "theme")
})

test_that("style_load examples restore themes and protect function loading", {
  skip_if_not_installed("yaml")
  skip_if_not_installed("ggplot2")

  examples_file <- options_examples_path()
  examples <- yaml::read_yaml(examples_file)$style_load
  expect_setequal(names(examples$arguments), c("path", "allow_functions"))

  old_styles <- .figspec_cache$styles
  withr::defer(.figspec_cache$styles <- old_styles)
  .figspec_cache$styles <- NULL

  example_env <- new.env(parent = globalenv())
  suppressMessages(eval(parse(text = examples$setup), envir = example_env))
  withr::defer(unlink(c(
    example_env$style_file,
    example_env$function_file
  )))

  path_example <- examples$arguments$path
  expect_true(nzchar(path_example$prose))
  expect_true(nzchar(path_example$code))
  expect_true(nzchar(path_example$result))
  after_theme <- suppressMessages(eval(
    parse(text = path_example$code),
    envir = example_env
  ))
  expect_s3_class(after_theme, "data.frame")
  expect_identical(example_env$loaded_names, "research_report")
  expect_true("research_report" %in% after_theme$name)

  expect_error(
    style_load(example_env$function_file),
    "executable R code",
    class = "figspec_bad_input"
  )

  function_example <- examples$arguments$allow_functions
  expect_true(nzchar(function_example$prose))
  expect_true(nzchar(function_example$code))
  expect_true(nzchar(function_example$result))
  after_function <- suppressMessages(eval(
    parse(text = function_example$code),
    envir = example_env
  ))
  expect_s3_class(after_function, "data.frame")
  expect_identical(example_env$loaded_functions, "dynamic_style")
  expect_true(all(c(
    "research_report", "dynamic_style"
  ) %in% after_function$name))

  dynamic_theme <- resolve_style("dynamic_style")
  expect_s3_class(dynamic_theme, "theme")
  expect_identical(dynamic_theme$legend.position, "bottom")
})

test_that("fig_tag_panels examples label and render real multi-panel figures", {
  skip_if_not_installed("yaml")
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("patchwork")
  skip_if_not_installed("ragg")

  examples_file <- options_examples_path()
  examples <- yaml::read_yaml(examples_file)$fig_tag_panels
  expected_arguments <- c(
    "plot", "spec", "level", "open, close", "strips",
    "x, y, hjust, vjust", "..."
  )
  expect_setequal(names(examples$arguments), expected_arguments)

  example_env <- new.env(parent = globalenv())
  eval(parse(text = examples$setup), envir = example_env)
  values <- lapply(expected_arguments, function(argument) {
    example <- examples$arguments[[argument]]
    expect_true(nzchar(example$prose), info = argument)
    expect_true(nzchar(example$code), info = argument)
    expect_true(nzchar(example$result), info = argument)
    suppressWarnings(suppressMessages(eval(
      parse(text = example$code),
      envir = example_env
    )))
  })
  names(values) <- expected_arguments

  expect_s3_class(values$plot, "patchwork")
  expect_identical(panel_tag_levels(values$plot), "A")
  expect_equal(count_panels(values$plot), 2L)
  expect_identical(
    attr(values$plot, "figspec_panel_tags_placement"),
    "outside_image"
  )

  expect_s3_class(values$spec, "figspec_report")
  label_check <- values$spec[values$spec$check == "Panel labels", ]
  expect_equal(label_check$status, "pass")
  expect_match(label_check$actual, "capital letters")

  label_data <- function(plot) {
    built <- ggplot2::ggplot_build(plot)
    built$data[[length(built$data)]]
  }
  expect_equal(label_data(values$level)$label, c("(1)", "(2)", "(3)"))
  expect_equal(
    label_data(values[["open, close"]])$label,
    c("a.", "b.", "c.")
  )

  strips_theme <- ggplot2::ggplot_build(values$strips)$plot$theme
  expect_false(inherits(
    ggplot2::calc_element("strip.text", strips_theme),
    "element_blank"
  ))

  positioned <- label_data(values[["x, y, hjust, vjust"]])
  expect_true(all(is.infinite(positioned$x) & positioned$x > 0))
  expect_true(all(is.infinite(positioned$y) & positioned$y > 0))
  expect_true(all(positioned$hjust == 1.2))
  expect_true(all(positioned$vjust == 1.4))

  styled_labels <- label_data(values[["..."]])
  expect_true(all(styled_labels$size == 4))
  expect_true(all(styled_labels$fontface == "bold"))
  expect_true(all(styled_labels$family == "sans"))
  expect_true(all(styled_labels$colour == "#183A4A"))

  project_panels <- fig_tag_panels(
    example_env$faceted,
    spec = example_env$report_spec
  )
  expect_equal(label_data(project_panels)$label, c("(1)", "(2)", "(3)"))
  project_check <- fig_check(project_panels, example_env$report_spec)
  expect_equal(
    project_check$status[project_check$check == "Panel labels"],
    "pass"
  )

  outputs <- file.path(
    withr::local_tempdir(),
    c("labelled-composition.png", "labelled-facets.png")
  )
  ggplot2::ggsave(
    outputs[[1]],
    values$plot,
    device = ragg::agg_png,
    width = 180,
    height = 90,
    units = "mm",
    dpi = 150
  )
  ggplot2::ggsave(
    outputs[[2]],
    values[["..."]],
    device = ragg::agg_png,
    width = 180,
    height = 90,
    units = "mm",
    dpi = 150
  )
  expect_true(all(file.exists(outputs)))
  expect_true(all(file.info(outputs)$size > 10000))
})

test_that("spec_linewidth example draws the required physical line weight", {
  skip_if_not_installed("yaml")
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("patchwork")
  skip_if_not_installed("ragg")

  examples_file <- options_examples_path()
  examples <- yaml::read_yaml(examples_file)$spec_linewidth
  expect_setequal(names(examples$arguments), "spec")

  example_env <- new.env(parent = globalenv())
  eval(parse(text = examples$setup), envir = example_env)
  example <- examples$arguments$spec
  expect_true(nzchar(example$prose))
  expect_true(nzchar(example$code))
  expect_true(nzchar(example$result))
  comparison <- suppressMessages(eval(
    parse(text = example$code),
    envir = example_env
  ))

  expect_s3_class(comparison, "patchwork")
  expect_equal(
    ggplot_linewidth_to_pt(example_env$required_width),
    2,
    tolerance = 1e-9
  )
  expect_equal(
    plot_linewidths(example_env$before),
    ggplot_linewidth_to_pt(0.5),
    tolerance = 1e-9
  )
  expect_equal(
    plot_linewidths(example_env$after),
    2,
    tolerance = 1e-9
  )

  before_check <- fig_check(example_env$before, "frontiers")
  after_check <- fig_check(example_env$after, "frontiers")
  expect_equal(
    before_check$status[before_check$check == "Line width"],
    "fail"
  )
  expect_equal(
    after_check$status[after_check$check == "Line width"],
    "pass"
  )

  project_width <- spec_linewidth(example_env$report_spec)
  expect_equal(
    ggplot_linewidth_to_pt(project_width),
    1.25,
    tolerance = 1e-9
  )

  output <- file.path(withr::local_tempdir(), "line-width-comparison.png")
  ggplot2::ggsave(
    output,
    comparison,
    device = ragg::agg_png,
    width = 180,
    height = 90,
    units = "mm",
    dpi = 150
  )
  expect_true(file.exists(output))
  expect_gt(file.info(output)$size, 10000)
})

test_that("colour_safety_check examples inspect real mapped colours", {
  skip_if_not_installed("yaml")
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("patchwork")
  skip_if_not_installed("colorspace")
  skip_if_not_installed("farver")
  skip_if_not_installed("ragg")

  examples_file <- options_examples_path()
  examples <- yaml::read_yaml(examples_file)$colour_safety_check
  expected_arguments <- c("plot", "spec", "threshold")
  expect_setequal(names(examples$arguments), expected_arguments)

  example_env <- new.env(parent = globalenv())
  eval(parse(text = examples$setup), envir = example_env)
  values <- lapply(expected_arguments, function(argument) {
    example <- examples$arguments[[argument]]
    expect_true(nzchar(example$prose), info = argument)
    expect_true(nzchar(example$code), info = argument)
    expect_true(nzchar(example$result), info = argument)
    suppressMessages(eval(parse(text = example$code), envir = example_env))
  })
  names(values) <- expected_arguments

  expect_s3_class(example_env$unsafe_report, "figspec_report")
  expect_s3_class(example_env$safer_report, "figspec_report")
  colour_pair <- function(report) {
    report[report$check == "Colour pairs", , drop = FALSE]
  }
  expect_equal(colour_pair(example_env$unsafe_report)$status, "fail")
  expect_match(colour_pair(example_env$unsafe_report)$actual, "red and green")
  expect_equal(colour_pair(example_env$safer_report)$status, "pass")
  expect_equal(
    sort(attr(example_env$safer_report, "colours")),
    sort(c("#000000", "#0072B2", "#E69F00"))
  )

  expect_equal(colour_pair(example_env$cell_press_report)$status, "fail")
  expect_equal(
    colour_pair(example_env$frontiers_report)$status,
    "unspecified"
  )
  expect_equal(colour_pair(example_env$project_report)$status, "fail")
  project_greyscale <- example_env$project_report[
    example_env$project_report$check == "Greyscale", , drop = FALSE
  ]
  expect_equal(project_greyscale$status, "fail")

  greyscale_row <- function(report) {
    report[report$check == "Greyscale", , drop = FALSE]
  }
  expect_equal(greyscale_row(example_env$standard_cutoff)$status, "fail")
  expect_match(greyscale_row(example_env$standard_cutoff)$actual, "1 pair")
  expect_equal(greyscale_row(example_env$more_strict)$status, "fail")
  expect_match(greyscale_row(example_env$more_strict)$actual, "2 pair")

  british <- colour_safety_check(example_env$safer_plot, "cell_press")
  american <- color_safety_check(example_env$safer_plot, "cell_press")
  expect_equal(american, british)

  output <- file.path(withr::local_tempdir(), "colour-safety-comparison.png")
  comparison <- patchwork::wrap_plots(
    example_env$unsafe_plot,
    example_env$safer_plot,
    ncol = 2
  )
  ggplot2::ggsave(
    output,
    comparison,
    device = ragg::agg_png,
    width = 180,
    height = 90,
    units = "mm",
    dpi = 150
  )
  expect_true(file.exists(output))
  expect_gt(file.info(output)$size, 10000)
})

test_that("figspec_palettes example lists and renders every shipped palette", {
  skip_if_not_installed("yaml")
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("ragg")

  examples_file <- options_examples_path()
  examples <- yaml::read_yaml(examples_file)$figspec_palettes
  expect_true(nzchar(examples$introduction))
  expect_true(nzchar(examples$setup))
  expect_true(nzchar(examples$example$prose))
  expect_true(nzchar(examples$example$code))
  expect_true(nzchar(examples$example$result))

  example_env <- new.env(parent = globalenv())
  eval(parse(text = examples$setup), envir = example_env)
  swatch_plot <- suppressMessages(eval(
    parse(text = examples$example$code),
    envir = example_env
  ))

  expect_s3_class(swatch_plot, "ggplot")
  expect_equal(nrow(example_env$available_palettes), 3L)
  expect_setequal(
    example_env$available_palettes$id,
    c("okabe_ito", "cividis", "viridis")
  )
  expect_equal(nrow(example_env$swatches), 24L)
  expect_equal(
    as.integer(table(example_env$swatches$palette)),
    rep(8L, 3)
  )
  for (palette_id in example_env$available_palettes$id) {
    display_name <- example_env$available_palettes$name[
      example_env$available_palettes$id == palette_id
    ]
    shown <- example_env$swatches$colour[
      example_env$swatches$palette == display_name
    ]
    expect_identical(shown, figspec_palette(palette_id, 8))
  }

  built <- ggplot2::ggplot_build(swatch_plot)
  expect_equal(nrow(built$data[[1]]), 24L)
  expect_setequal(
    toupper(built$data[[1]]$fill),
    toupper(example_env$swatches$colour)
  )

  output <- file.path(withr::local_tempdir(), "figspec-palette-swatches.png")
  ggplot2::ggsave(
    output,
    swatch_plot,
    device = ragg::agg_png,
    width = 150,
    height = 100,
    units = "mm",
    dpi = 150
  )
  expect_true(file.exists(output))
  # The palette swatch is intentionally simple and compresses efficiently.
  # A non-trivial rendered PNG is enough here; the built colours are checked
  # against every tile immediately above.
  expect_gt(file.info(output)$size, 5000)
})

test_that("figspec_palette examples apply requested colours to real data", {
  skip_if_not_installed("yaml")
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("ragg")

  examples_file <- options_examples_path()
  examples <- yaml::read_yaml(examples_file)$figspec_palette
  expected_arguments <- c("palette", "n")
  expect_setequal(names(examples$arguments), expected_arguments)

  example_env <- new.env(parent = globalenv())
  eval(parse(text = examples$setup), envir = example_env)
  plots <- lapply(expected_arguments, function(argument) {
    example <- examples$arguments[[argument]]
    expect_true(nzchar(example$prose), info = argument)
    expect_true(nzchar(example$code), info = argument)
    expect_true(nzchar(example$result), info = argument)
    suppressMessages(eval(parse(text = example$code), envir = example_env))
  })
  names(plots) <- expected_arguments

  expect_s3_class(plots$palette, "ggplot")
  expect_s3_class(plots$n, "ggplot")
  expect_equal(nrow(example_env$mpg_six_classes), 229L)
  expect_length(example_env$class_colours, 6L)
  expect_length(unique(example_env$class_colours), 6L)
  expect_identical(
    example_env$class_colours,
    figspec_palette("okabe_ito", 6)
  )
  expect_equal(example_env$number_of_bands, 6L)
  expect_length(example_env$band_colours, 6L)
  expect_length(unique(example_env$band_colours), 6L)
  expect_identical(
    example_env$band_colours,
    figspec_palette("cividis", 6)
  )
  expect_setequal(
    figspec:::plot_colours(plots$palette),
    example_env$class_colours
  )
  expect_setequal(
    figspec:::plot_colours(plots$n),
    example_env$band_colours
  )
  expect_error(
    figspec_palette("okabe_ito", 9),
    class = "figspec_unsupported"
  )

  outputs <- file.path(
    withr::local_tempdir(),
    c("qualitative-palette.png", "sequential-palette.png")
  )
  ggplot2::ggsave(
    outputs[[1]],
    plots$palette,
    device = ragg::agg_png,
    width = 150,
    height = 100,
    units = "mm",
    dpi = 150
  )
  ggplot2::ggsave(
    outputs[[2]],
    plots$n,
    device = ragg::agg_png,
    width = 150,
    height = 100,
    units = "mm",
    dpi = 150
  )
  expect_true(all(file.exists(outputs)))
  expect_true(all(file.info(outputs)$size > 10000))
})

test_that("scale_colour_figspec examples colour real points and labels", {
  skip_if_not_installed("yaml")
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("ragg")

  examples_file <- options_examples_path()
  examples <- yaml::read_yaml(examples_file)$scale_colour_figspec
  expected_arguments <- c("palette", "...")
  expect_setequal(names(examples$arguments), expected_arguments)

  example_env <- new.env(parent = globalenv())
  eval(parse(text = examples$setup), envir = example_env)
  plots <- lapply(expected_arguments, function(argument) {
    example <- examples$arguments[[argument]]
    expect_true(nzchar(example$prose), info = argument)
    expect_true(nzchar(example$code), info = argument)
    expect_true(nzchar(example$result), info = argument)
    suppressMessages(eval(parse(text = example$code), envir = example_env))
  })
  names(plots) <- expected_arguments

  expect_s3_class(plots$palette, "ggplot")
  expect_s3_class(plots[["..."]], "ggplot")
  expect_equal(nrow(example_env$mpg_six_classes), 229L)
  expect_setequal(
    figspec:::plot_colours(plots$palette),
    figspec_palette("okabe_ito", 6)
  )
  expect_setequal(
    figspec:::plot_colours(plots[["..."]]),
    figspec_palette("okabe_ito", 3)
  )
  labelled_scale <- ggplot2::ggplot_build(plots[["..."]])$plot$scales$get_scales("colour")
  expect_identical(labelled_scale$name, "Drive layout")
  expect_identical(labelled_scale$breaks, c("f", "r", "4"))
  expect_identical(
    labelled_scale$labels,
    c("Front-wheel drive", "Rear-wheel drive", "Four-wheel drive")
  )

  british <- scale_colour_figspec("okabe_ito")
  american <- scale_color_figspec("okabe_ito")
  expect_identical(class(american), class(british))
  expect_identical(american$aesthetics, british$aesthetics)
  expect_identical(american$palette(3), british$palette(3))

  outputs <- file.path(
    withr::local_tempdir(),
    c("colour-scale-classes.png", "colour-scale-labels.png")
  )
  for (i in seq_along(outputs)) {
    ggplot2::ggsave(
      outputs[[i]],
      plots[[i]],
      device = ragg::agg_png,
      width = 150,
      height = 100,
      units = "mm",
      dpi = 150
    )
  }
  expect_true(all(file.exists(outputs)))
  expect_true(all(file.info(outputs)$size > 10000))
})

test_that("scale_fill_figspec examples colour real bars and labels", {
  skip_if_not_installed("yaml")
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("ragg")

  examples_file <- options_examples_path()
  examples <- yaml::read_yaml(examples_file)$scale_fill_figspec
  expected_arguments <- c("palette", "...")
  expect_setequal(names(examples$arguments), expected_arguments)

  example_env <- new.env(parent = globalenv())
  eval(parse(text = examples$setup), envir = example_env)
  plots <- lapply(expected_arguments, function(argument) {
    example <- examples$arguments[[argument]]
    expect_true(nzchar(example$prose), info = argument)
    expect_true(nzchar(example$code), info = argument)
    expect_true(nzchar(example$result), info = argument)
    suppressMessages(eval(parse(text = example$code), envir = example_env))
  })
  names(plots) <- expected_arguments

  expect_s3_class(plots$palette, "ggplot")
  expect_s3_class(plots[["..."]], "ggplot")
  fill_colours <- function(plot) {
    unique(ggplot2::ggplot_build(plot)$data[[1]]$fill)
  }
  expect_setequal(
    fill_colours(plots$palette),
    figspec_palette("okabe_ito", 3)
  )
  expect_setequal(
    fill_colours(plots[["..."]]),
    figspec_palette("okabe_ito", 3)
  )
  labelled_scale <- ggplot2::ggplot_build(plots[["..."]])$plot$scales$get_scales("fill")
  expect_identical(labelled_scale$name, "Drive layout")
  expect_identical(labelled_scale$breaks, c("f", "r", "4"))
  expect_identical(
    labelled_scale$labels,
    c("Front-wheel drive", "Rear-wheel drive", "Four-wheel drive")
  )

  outputs <- file.path(
    withr::local_tempdir(),
    c("fill-scale-bars.png", "fill-scale-labels.png")
  )
  for (i in seq_along(outputs)) {
    ggplot2::ggsave(
      outputs[[i]],
      plots[[i]],
      device = ragg::agg_png,
      width = 150,
      height = 100,
      units = "mm",
      dpi = 150
    )
  }
  expect_true(all(file.exists(outputs)))
  expect_true(all(file.info(outputs)$size > 10000))
})

test_that("scale_shape_figspec examples use each tested shape family", {
  skip_if_not_installed("yaml")
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("patchwork")
  skip_if_not_installed("ragg")

  examples_file <- options_examples_path()
  examples <- yaml::read_yaml(examples_file)$scale_shape_figspec
  expected_arguments <- c("...", "style")
  expect_setequal(names(examples$arguments), expected_arguments)

  example_env <- new.env(parent = globalenv())
  eval(parse(text = examples$setup), envir = example_env)
  values <- lapply(expected_arguments, function(argument) {
    example <- examples$arguments[[argument]]
    expect_true(nzchar(example$prose), info = argument)
    expect_true(nzchar(example$code), info = argument)
    expect_true(nzchar(example$result), info = argument)
    suppressMessages(eval(parse(text = example$code), envir = example_env))
  })
  names(values) <- expected_arguments

  expect_s3_class(values[["..."]], "ggplot")
  expect_s3_class(values$style, "patchwork")
  plotted_shapes <- function(plot) {
    unique(ggplot2::ggplot_build(plot)$data[[1]]$shape)
  }
  expect_setequal(plotted_shapes(example_env$solid_plot), c(16, 17, 15))
  expect_setequal(plotted_shapes(example_env$hollow_plot), c(1, 2, 0))
  expect_setequal(plotted_shapes(example_env$filled_plot), c(21, 24, 22))
  expect_setequal(
    plotted_shapes(values[["..."]]),
    figspec_shapes(3, "solid")
  )

  labelled_scale <- ggplot2::ggplot_build(values[["..."]])$plot$scales$get_scales("shape")
  expect_identical(labelled_scale$name, "Drive layout")
  expect_identical(labelled_scale$breaks, c("f", "r", "4"))
  expect_identical(
    labelled_scale$labels,
    c("Front-wheel drive", "Rear-wheel drive", "Four-wheel drive")
  )
  expect_equal(labelled_scale$na.value, 4)

  filled_data <- ggplot2::ggplot_build(example_env$filled_plot)$data[[1]]
  expect_setequal(
    unique(filled_data$fill),
    figspec_palette("okabe_ito", 3)
  )
  expect_true(all(filled_data$colour == "#243642"))
  expect_true(all(filled_data$stroke == 0.8))

  outputs <- file.path(
    withr::local_tempdir(),
    c("shape-styles.png", "shape-labels.png")
  )
  ggplot2::ggsave(
    outputs[[1]],
    values$style,
    device = ragg::agg_png,
    width = 210,
    height = 90,
    units = "mm",
    dpi = 150
  )
  ggplot2::ggsave(
    outputs[[2]],
    values[["..."]],
    device = ragg::agg_png,
    width = 150,
    height = 100,
    units = "mm",
    dpi = 150
  )
  expect_true(all(file.exists(outputs)))
  expect_true(all(file.info(outputs)$size > 10000))
})

test_that("figspec_shapes examples return and render the requested codes", {
  skip_if_not_installed("yaml")
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("patchwork")
  skip_if_not_installed("ragg")

  examples_file <- options_examples_path()
  examples <- yaml::read_yaml(examples_file)$figspec_shapes
  expected_arguments <- c("n", "style")
  expect_setequal(names(examples$arguments), expected_arguments)

  example_env <- new.env(parent = globalenv())
  eval(parse(text = examples$setup), envir = example_env)
  values <- lapply(expected_arguments, function(argument) {
    example <- examples$arguments[[argument]]
    expect_true(nzchar(example$prose), info = argument)
    expect_true(nzchar(example$code), info = argument)
    expect_true(nzchar(example$result), info = argument)
    suppressMessages(eval(parse(text = example$code), envir = example_env))
  })
  names(values) <- expected_arguments

  expect_s3_class(values$n, "ggplot")
  expect_s3_class(values$style, "patchwork")
  expect_equal(example_env$number_of_drive_types, 3L)
  expect_identical(example_env$drive_shapes, c(16, 17, 15))
  expect_identical(example_env$solid_shapes, c(16, 17, 15))
  expect_identical(example_env$hollow_shapes, c(1, 2, 0))
  expect_identical(example_env$filled_shapes, c(21, 24, 22))

  plotted_shapes <- function(plot) {
    unique(ggplot2::ggplot_build(plot)$data[[1]]$shape)
  }
  expect_setequal(plotted_shapes(values$n), example_env$drive_shapes)
  expect_setequal(
    plotted_shapes(example_env$solid_plot),
    example_env$solid_shapes
  )
  expect_setequal(
    plotted_shapes(example_env$hollow_plot),
    example_env$hollow_shapes
  )
  expect_setequal(
    plotted_shapes(example_env$filled_plot),
    example_env$filled_shapes
  )
  expect_error(
    figspec_shapes(7, "solid"),
    class = "figspec_unsupported"
  )

  outputs <- file.path(
    withr::local_tempdir(),
    c("shape-count.png", "shape-family-comparison.png")
  )
  ggplot2::ggsave(
    outputs[[1]],
    values$n,
    device = ragg::agg_png,
    width = 150,
    height = 100,
    units = "mm",
    dpi = 150
  )
  ggplot2::ggsave(
    outputs[[2]],
    values$style,
    device = ragg::agg_png,
    width = 210,
    height = 90,
    units = "mm",
    dpi = 150
  )
  expect_true(all(file.exists(outputs)))
  expect_true(all(file.info(outputs)$size > 10000))
})

test_that("figspec_linetypes example adds redundant coding to real series", {
  skip_if_not_installed("yaml")
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("patchwork")
  skip_if_not_installed("colorspace")
  skip_if_not_installed("farver")
  skip_if_not_installed("ragg")

  examples_file <- options_examples_path()
  examples <- yaml::read_yaml(examples_file)$figspec_linetypes
  expect_setequal(names(examples$arguments), "n")

  example_env <- new.env(parent = globalenv())
  eval(parse(text = examples$setup), envir = example_env)
  example <- examples$arguments$n
  expect_true(nzchar(example$prose))
  expect_true(nzchar(example$code))
  expect_true(nzchar(example$result))
  value <- suppressMessages(eval(
    parse(text = example$code),
    envir = example_env
  ))

  expect_s3_class(value, "data.frame")
  expect_equal(nrow(example_env$economic_series), 2870L)
  expect_equal(example_env$number_of_series, 5L)
  expect_identical(
    example_env$line_patterns,
    c("solid", "dashed", "dotted", "dotdash", "longdash")
  )
  expect_s3_class(example_env$line_comparison, "patchwork")
  # ggplot2 stores its default solid line as numeric code 1.
  expect_setequal(figspec:::plot_linetypes(example_env$before), 1)
  expect_setequal(
    figspec:::plot_linetypes(example_env$after),
    example_env$line_patterns
  )
  expect_setequal(
    figspec:::plot_colours(example_env$before),
    figspec_palette("okabe_ito", 5)
  )
  expect_setequal(
    figspec:::plot_colours(example_env$after),
    figspec_palette("okabe_ito", 5)
  )

  redundant_row <- function(report) {
    report[report$check == "Redundant coding", , drop = FALSE]
  }
  expect_match(
    redundant_row(example_env$before_report)$actual,
    "colour is the only cue"
  )
  expect_match(
    redundant_row(example_env$after_report)$actual,
    "line types .*separate"
  )
  expect_error(
    figspec_linetypes(7),
    class = "figspec_unsupported"
  )

  output <- file.path(withr::local_tempdir(), "linetype-comparison.png")
  ggplot2::ggsave(
    output,
    example_env$line_comparison,
    device = ragg::agg_png,
    width = 210,
    height = 100,
    units = "mm",
    dpi = 150
  )
  expect_true(file.exists(output))
  expect_gt(file.info(output)$size, 10000)
})

test_that("spec_style_palette example uses a project palette and preserves absence", {
  skip_if_not_installed("yaml")
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("ragg")

  examples_file <- options_examples_path()
  examples <- yaml::read_yaml(examples_file)$spec_style_palette
  expect_setequal(names(examples$arguments), "spec")

  example_env <- new.env(parent = globalenv())
  eval(parse(text = examples$setup), envir = example_env)
  example <- examples$arguments$spec
  expect_true(nzchar(example$prose))
  expect_true(nzchar(example$code))
  expect_true(nzchar(example$result))
  house_style_plot <- NULL
  expect_message(
    house_style_plot <- suppressMessages(
      eval(parse(text = example$code), envir = example_env)
    ),
    NA
  )

  expect_s3_class(house_style_plot, "ggplot")
  expect_null(example_env$no_recorded_palette)
  expect_identical(
    unname(example_env$report_palette),
    c("#1D3557", "#2A9D8F", "#E76F51")
  )
  expect_identical(names(example_env$report_palette), c("4", "f", "r"))
  expect_setequal(
    figspec:::plot_colours(house_style_plot),
    unname(example_env$report_palette)
  )
  expect_setequal(
    figspec:::plot_shapes(house_style_plot)$shapes,
    figspec_shapes(3)
  )

  no_palette <- NULL
  expect_message(
    no_palette <- spec_style_palette("plos_one"),
    "No house-style palette is recorded"
  )
  expect_null(no_palette)

  output <- file.path(withr::local_tempdir(), "project-house-style-palette.png")
  ggplot2::ggsave(
    output,
    house_style_plot,
    device = ragg::agg_png,
    width = 150,
    height = 100,
    units = "mm",
    dpi = 150
  )
  expect_true(file.exists(output))
  expect_gt(file.info(output)$size, 10000)
})

test_that("spec_list example browses and filters the real bundled registry", {
  skip_if_not_installed("yaml")

  examples_file <- options_examples_path()
  examples <- yaml::read_yaml(examples_file)$spec_list
  expect_setequal(names(examples$arguments), "discipline")

  old_user_specs <- .figspec_cache$user_specs
  withr::defer(.figspec_cache$user_specs <- old_user_specs)
  .figspec_cache$user_specs <- NULL

  example_env <- new.env(parent = globalenv())
  eval(parse(text = examples$setup), envir = example_env)
  example <- examples$arguments$discipline
  expect_true(nzchar(example$prose))
  expect_true(nzchar(example$code))
  expect_true(nzchar(example$result))
  value <- suppressMessages(eval(
    parse(text = example$code),
    envir = example_env
  ))

  expect_s3_class(value, "data.frame")
  expect_equal(nrow(example_env$all_profiles), 29L)
  expect_identical(
    names(example_env$all_profiles),
    c(
      "id", "name", "publisher", "disciplines", "single_mm",
      "double_mm", "dpi_min", "font_min_pt", "max_file_mb",
      "table_requirements", "publication_stage", "verified_on", "origin"
    )
  )
  expect_setequal(
    example_env$physics_profiles$id,
    c("iop", "aps")
  )
  expect_setequal(
    example_env$health_profiles$id,
    c("sage", "bmj", "oup", "bmc", "jid")
  )
  expect_true(all(example_env$all_profiles$origin == "figspec"))
  expect_true(all(grepl("physics", example_env$physics_profiles$disciplines)))
  expect_true(all(grepl(
    "health|medicine",
    example_env$health_profiles$disciplines
  )))

  expect_error(
    spec_list(discipline = 1),
    class = "figspec_bad_input"
  )
  expect_error(
    spec_list(discipline = "physcis"),
    "Unknown discipline tag",
    class = "figspec_not_found"
  )
})

test_that("spec_get example retrieves and applies real specifications", {
  skip_if_not_installed("yaml")
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("ragg")

  examples_file <- options_examples_path()
  examples <- yaml::read_yaml(examples_file)$spec_get
  expect_setequal(names(examples$arguments), "spec")

  example_env <- new.env(parent = globalenv())
  eval(parse(text = examples$setup), envir = example_env)
  example <- examples$arguments$spec
  expect_true(nzchar(example$prose))
  expect_true(nzchar(example$code))
  expect_true(nzchar(example$result))
  project_report <- suppressMessages(eval(
    parse(text = example$code),
    envir = example_env
  ))

  expect_s3_class(example_env$publisher_spec, "figspec_spec")
  expect_identical(example_env$publisher_spec$id, "cell_press")
  expect_identical(example_env$publisher_spec$origin, "figspec")
  expect_match(example_env$publisher_spec$source_url, "^https://")
  expect_match(example_env$publisher_spec$verified_on, "^\\d{4}-\\d{2}-\\d{2}$")
  expect_identical(example_env$same_spec, example_env$publisher_spec)

  expect_s3_class(example_env$project_spec, "figspec_spec")
  expect_identical(example_env$project_spec$name, "Clinical research report")
  expect_equal(unname(unlist(example_env$project_spec$columns)), c(80, 160))
  expect_identical(example_env$project_spec$formats, c("png", "pdf"))
  expect_s3_class(example_env$project_plot, "ggplot")
  expect_s3_class(project_report, "figspec_report")
  core_checks <- project_report[
    project_report$check %in% c("Width", "Resolution", "File format", "Type size"),
    , drop = FALSE
  ]
  expect_true(nrow(core_checks) >= 4L)
  expect_true(all(core_checks$status == "pass"))

  output <- file.path(withr::local_tempdir(), "project-specification-plot.png")
  ggplot2::ggsave(
    output,
    example_env$project_plot,
    device = ragg::agg_png,
    width = 160,
    height = 95,
    units = "mm",
    dpi = 300
  )
  expect_true(file.exists(output))
  expect_gt(file.info(output)$size, 10000)
})

test_that("fig_width examples retrieve, convert, export and check a real width", {
  skip_if_not_installed("yaml")
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("ragg")

  examples_file <- options_examples_path()
  examples <- yaml::read_yaml(examples_file)$fig_width
  expect_setequal(names(examples$arguments), c("spec", "column", "units"))

  example_env <- new.env(parent = globalenv())
  eval(parse(text = examples$setup), envir = example_env)

  spec_example <- examples$arguments$spec
  expect_true(all(nzchar(unlist(spec_example))))
  project_width <- eval(parse(text = spec_example$code), envir = example_env)
  expect_equal(example_env$publisher_width, 85)
  expect_equal(project_width, 160)

  column_example <- examples$arguments$column
  expect_true(all(nzchar(unlist(column_example))))
  width_check <- suppressMessages(eval(
    parse(text = column_example$code),
    envir = example_env
  ))
  withr::defer(unlink(example_env$output_file))
  expect_true(file.exists(example_env$output_file))
  expect_gt(file.info(example_env$output_file)$size, 10000)
  expect_s3_class(example_env$saved_check, "figspec_report")
  expect_equal(nrow(width_check), 1L)
  expect_identical(width_check$status, "pass")
  saved_geometry <- attr(example_env$saved_file, "figspec_geometry")
  expect_s3_class(saved_geometry, "figspec_geometry")
  expect_equal(saved_geometry$canvas_width_mm, 85, tolerance = 0.1)

  units_example <- examples$arguments$units
  expect_true(all(nzchar(unlist(units_example))))
  equivalent_widths <- eval(parse(text = units_example$code), envir = example_env)
  expect_equal(unname(equivalent_widths), c(85, 8.5, 85 / 25.4))
})

test_that("fig_columns example lists real choices and uses one for export", {
  skip_if_not_installed("yaml")
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("ragg")

  examples_file <- options_examples_path()
  examples <- yaml::read_yaml(examples_file)$fig_columns
  expect_setequal(names(examples$arguments), "spec")

  example_env <- new.env(parent = globalenv())
  eval(parse(text = examples$setup), envir = example_env)
  example <- examples$arguments$spec
  expect_true(all(nzchar(unlist(example))))
  width_check <- suppressMessages(eval(
    parse(text = example$code),
    envir = example_env
  ))
  withr::defer(unlink(example_env$output_file))

  expect_equal(
    example_env$publisher_columns,
    c(single = 85, onehalf = 114, double = 174)
  )
  expect_equal(example_env$project_columns, c(half = 80, full = 160))
  expect_identical(example_env$selected_column, "onehalf")
  expect_true(file.exists(example_env$output_file))
  expect_gt(file.info(example_env$output_file)$size, 10000)
  expect_s3_class(example_env$saved_check, "figspec_report")
  expect_equal(nrow(width_check), 1L)
  expect_identical(width_check$status, "pass")
  expect_match(width_check$requirement, "114 mm", fixed = TRUE)
  saved_geometry <- attr(example_env$saved_file, "figspec_geometry")
  expect_s3_class(saved_geometry, "figspec_geometry")
  expect_equal(saved_geometry$canvas_width_mm, 114, tolerance = 0.1)
})

test_that("spec_register example registers, applies and verifies a specification", {
  skip_if_not_installed("yaml")
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("ragg")

  examples_file <- options_examples_path()
  examples <- yaml::read_yaml(examples_file)$spec_register
  expected_arguments <- c(
    "id", "name", "source_url", "verified_on", "requirements",
    "house_style", "..."
  )
  expect_setequal(names(examples$arguments), expected_arguments)

  old_user_specs <- .figspec_cache$user_specs
  withr::defer(.figspec_cache$user_specs <- old_user_specs)
  .figspec_cache$user_specs <- NULL

  example_env <- new.env(parent = globalenv())
  eval(parse(text = examples$setup), envir = example_env)
  expect_s3_class(example_env$registered_spec, "figspec_spec")
  expect_identical(example_env$registered_spec$origin, "user")

  values <- lapply(expected_arguments, function(argument) {
    example <- examples$arguments[[argument]]
    expect_true(nzchar(example$prose), info = argument)
    expect_true(nzchar(example$code), info = argument)
    expect_true(nzchar(example$result), info = argument)
    suppressMessages(eval(parse(text = example$code), envir = example_env))
  })
  names(values) <- expected_arguments
  withr::defer(unlink(example_env$output_file))

  expect_true(values$id)
  expect_identical(
    values$name,
    c(id = "research_methods_review", name = "Research Methods Review")
  )
  expect_identical(values$source_url, "internal:author-guidelines-v2")
  expect_identical(values$verified_on, as.character(Sys.Date()))

  core_report <- values$requirements
  expect_s3_class(example_env$registered_plot, "ggplot")
  expect_s3_class(example_env$saved_report, "figspec_report")
  expect_true(file.exists(example_env$output_file))
  expect_gt(file.info(example_env$output_file)$size, 10000)
  expect_equal(nrow(core_report), 4L)
  expect_true(all(core_report$status == "pass"))
  saved_geometry <- attr(example_env$saved_file, "figspec_geometry")
  expect_s3_class(saved_geometry, "figspec_geometry")
  expect_equal(saved_geometry$canvas_width_mm, 85, tolerance = 0.1)

  expect_identical(
    example_env$publication_colours,
    c("#1B4965", "#CA6702", "#5C677D")
  )
  expect_s3_class(values$house_style, "ggplot")
  expect_setequal(
    figspec:::plot_colours(values$house_style),
    example_env$publication_colours
  )

  profile_row <- values[["..."]]
  expect_equal(nrow(profile_row), 1L)
  expect_identical(profile_row$origin, "user")
  expect_identical(profile_row$publisher, "Example Research Society")
  expect_match(profile_row$disciplines, "health")
  expect_match(profile_row$disciplines, "statistics")
  expect_identical(profile_row$publication_stage, "all")
})

test_that("spec_save examples create, update and reload validated registries", {
  skip_if_not_installed("yaml")

  examples <- yaml::read_yaml(options_examples_path())$spec_save
  expected_arguments <- c(
    "spec", "path", "id", "source_url", "verified_on", "overwrite"
  )
  expect_setequal(names(examples$arguments), expected_arguments)

  old_user_specs <- .figspec_cache$user_specs
  withr::defer(.figspec_cache$user_specs <- old_user_specs)
  .figspec_cache$user_specs <- NULL

  example_env <- new.env(parent = globalenv())
  eval(parse(text = examples$setup), envir = example_env)
  withr::defer(unlink(example_env$spec_output_dir, recursive = TRUE))

  values <- lapply(expected_arguments, function(argument) {
    example <- examples$arguments[[argument]]
    expect_true(nzchar(example$prose), info = argument)
    expect_true(nzchar(example$code), info = argument)
    expect_true(nzchar(example$result), info = argument)
    suppressMessages(eval(parse(text = example$code), envir = example_env))
  })
  names(values) <- expected_arguments

  expect_identical(
    unname(values$spec),
    c("Research unit report", "160", "9")
  )
  expect_identical(unname(values$path[["exists"]]), "TRUE")
  expect_identical(unname(values$path[["valid"]]), "TRUE")
  expect_identical(
    values$id,
    c(id = "quarterly_report", name = "Research unit report")
  )
  expect_identical(values$source_url, "internal:methods-handbook-v3")
  expect_identical(
    values$verified_on,
    as.character(Sys.Date() - 30)
  )
  expect_identical(values$overwrite, c("annual_report", "conference_poster"))
})

test_that("spec_load example loads YAML and verifies a real export", {
  skip_if_not_installed("yaml")
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("ragg")

  examples_file <- options_examples_path()
  examples <- yaml::read_yaml(examples_file)$spec_load
  expect_setequal(names(examples$arguments), "path")

  old_user_specs <- .figspec_cache$user_specs
  withr::defer(.figspec_cache$user_specs <- old_user_specs)
  .figspec_cache$user_specs <- NULL

  example_env <- new.env(parent = globalenv())
  eval(parse(text = examples$setup), envir = example_env)
  withr::defer(unlink(c(example_env$registry_file, example_env$output_file)))
  expect_true(file.exists(example_env$registry_file))
  expect_gt(file.info(example_env$registry_file)$size, 500)

  example <- examples$arguments$path
  expect_true(all(nzchar(unlist(example))))
  core_report <- suppressMessages(eval(
    parse(text = example$code),
    envir = example_env
  ))

  expect_identical(example_env$loaded_ids, "research_unit_report")
  expect_s3_class(example_env$loaded_spec, "figspec_spec")
  expect_identical(example_env$loaded_spec$origin, "user")
  expect_equal(fig_width(example_env$loaded_spec, "full"), 160)
  expect_equal(nrow(ggplot2::economics), 574L)
  expect_s3_class(example_env$loaded_plot, "ggplot")
  expect_true(file.exists(example_env$output_file))
  expect_gt(file.info(example_env$output_file)$size, 10000)
  expect_s3_class(example_env$saved_report, "figspec_report")
  expect_equal(nrow(core_report), 4L)
  expect_true(all(core_report$status == "pass"))
  saved_geometry <- attr(example_env$saved_file, "figspec_geometry")
  expect_s3_class(saved_geometry, "figspec_geometry")
  expect_equal(saved_geometry$canvas_width_mm, 160, tolerance = 0.1)

  loaded_row <- spec_list()
  loaded_row <- loaded_row[loaded_row$id == "research_unit_report", ]
  expect_equal(nrow(loaded_row), 1L)
  expect_identical(loaded_row$origin, "user")
  expect_identical(loaded_row$publisher, "Example Research Unit")
})

test_that("submission_check examples review real plots, files and directories", {
  skip_if_not_installed("yaml")
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("ragg")

  examples_file <- options_examples_path()
  examples <- yaml::read_yaml(examples_file)$submission_check
  expected_arguments <- c(
    "x", "spec", "column", "dpi", "pattern", "recursive", "art_type",
    "asset_type"
  )
  expect_setequal(names(examples$arguments), expected_arguments)

  example_env <- new.env(parent = globalenv())
  eval(parse(text = examples$setup), envir = example_env)
  withr::defer(unlink(example_env$example_root, recursive = TRUE))

  values <- lapply(expected_arguments, function(argument) {
    example <- examples$arguments[[argument]]
    expect_true(nzchar(example$prose), info = argument)
    expect_true(nzchar(example$code), info = argument)
    expect_true(nzchar(example$result), info = argument)
    suppressMessages(eval(parse(text = example$code), envir = example_env))
  })
  names(values) <- expected_arguments

  expect_equal(nrow(ggplot2::mpg), 234L)
  expect_equal(nrow(ggplot2::economics), 574L)
  expect_equal(nrow(ggplot2::diamonds), 53940L)
  expect_s3_class(example_env$plot_review, "figspec_submission")
  expect_s3_class(example_env$file_review, "figspec_submission")
  expect_equal(nrow(example_env$plot_review), 3L)
  expect_equal(nrow(example_env$file_review), 3L)
  expect_true(attr(example_env$plot_review, "from_plots"))
  expect_false(attr(example_env$file_review, "from_plots"))
  expect_true(all(file.exists(example_env$saved_files)))
  expect_true(all(file.info(example_env$saved_files)$size > 10000))
  expect_identical(example_env$plot_review$column, unname(example_env$column_map))
  expect_identical(
    example_env$file_review$column,
    unname(example_env$file_column_map)
  )

  spec_values <- values$spec
  expect_s3_class(spec_values$against_specification, "figspec_submission")
  expect_s3_class(spec_values$inspection_only, "figspec_submission")
  for (report in attr(spec_values$inspection_only, "reports")) {
    expect_false(any(report$status %in% c("pass", "fail")))
  }

  expect_true(all(example_env$one_width_review$column == "double"))
  expect_identical(
    example_env$mapped_width_review$column,
    unname(example_env$column_map)
  )

  dpi_values <- values$dpi
  width_without_dpi <- dpi_values$without_dpi[
    dpi_values$without_dpi$check == "Width", , drop = FALSE
  ]
  width_with_dpi <- dpi_values$with_dpi[
    dpi_values$with_dpi$check == "Width", , drop = FALSE
  ]
  resolution_without_dpi <- dpi_values$without_dpi[
    dpi_values$without_dpi$check == "Resolution", , drop = FALSE
  ]
  resolution_with_dpi <- dpi_values$with_dpi[
    dpi_values$with_dpi$check == "Resolution", , drop = FALSE
  ]
  expect_identical(width_without_dpi$status, "unknown")
  expect_identical(resolution_without_dpi$status, "unknown")
  expect_identical(width_with_dpi$status, "pass")
  expect_identical(resolution_with_dpi$status, "pass")

  expect_s3_class(example_env$pattern_review, "figspec_submission")
  expect_identical(example_env$pattern_review$file, "vehicles.png")
  expect_equal(nrow(values$recursive$top_level_only), 1L)
  expect_equal(nrow(values$recursive$including_nested), 2L)

  resolution_rows <- values$art_type
  expect_identical(resolution_rows$status, c("pass", "fail"))
  expect_match(resolution_rows$requirement[[1]], "300 dpi")
  expect_match(resolution_rows$requirement[[2]], "1000 dpi")
})

test_that("submission_detail examples diagnose one real figure", {
  skip_if_not_installed("yaml")
  skip_if_not_installed("ggplot2")

  examples_file <- options_examples_path()
  examples <- yaml::read_yaml(examples_file)$submission_detail
  expected_arguments <- c("x", "file")
  expect_setequal(names(examples$arguments), expected_arguments)

  example_env <- new.env(parent = globalenv())
  suppressMessages(
    eval(parse(text = examples$setup), envir = example_env)
  )

  values <- lapply(expected_arguments, function(argument) {
    example <- examples$arguments[[argument]]
    expect_true(nzchar(example$prose), info = argument)
    expect_true(nzchar(example$code), info = argument)
    expect_true(nzchar(example$result), info = argument)
    suppressMessages(eval(parse(text = example$code), envir = example_env))
  })
  names(values) <- expected_arguments

  expect_equal(nrow(ggplot2::mpg), 234L)
  expect_s3_class(example_env$detail_review, "figspec_submission")
  expect_identical(example_env$detail_review$file, c("ready", "text_too_small"))
  expect_s3_class(values$x, "figspec_report")
  expect_true(any(values$x$status == "pass"))

  failed <- values$file
  expect_equal(nrow(failed), 1L)
  expect_identical(failed$check, "Type size")
  expect_identical(failed$status, "fail")
  expect_match(failed$requirement, "min 9 pt")
  expect_match(failed$actual, "7 pt")
})

test_that("fig_suggest_art_type examples classify a real colour plot", {
  skip_if_not_installed("yaml")
  skip_if_not_installed("ggplot2")

  examples <- yaml::read_yaml(options_examples_path())$fig_suggest_art_type
  expect_setequal(names(examples$arguments), c("plot", "spec"))

  example_env <- new.env(parent = globalenv())
  eval(parse(text = examples$setup), envir = example_env)
  values <- lapply(names(examples$arguments), function(argument) {
    example <- examples$arguments[[argument]]
    expect_true(nzchar(example$prose), info = argument)
    expect_true(nzchar(example$result), info = argument)
    suppressMessages(eval(parse(text = example$code), envir = example_env))
  })
  expect_identical(unlist(values, use.names = FALSE), c("colour", "colour"))
  expect_equal(nrow(ggplot2::mpg), 234L)
})

test_that("fig_refit examples write and inspect real figure sets", {
  skip_if_not_installed("yaml")
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("ragg")

  examples <- yaml::read_yaml(options_examples_path())$fig_refit
  expected_arguments <- c("plots", "spec", "output_dir", "column", "retheme", "format")
  expect_setequal(names(examples$arguments), expected_arguments)

  example_env <- new.env(parent = globalenv())
  eval(parse(text = examples$setup), envir = example_env)
  withr::defer(unlink(example_env$refit_root, recursive = TRUE))
  values <- lapply(expected_arguments, function(argument) {
    example <- examples$arguments[[argument]]
    expect_true(nzchar(example$prose), info = argument)
    expect_true(nzchar(example$result), info = argument)
    suppressMessages(eval(parse(text = example$code), envir = example_env))
  })
  names(values) <- expected_arguments

  expect_equal(nrow(ggplot2::mpg), 234L)
  expect_equal(nrow(ggplot2::economics), 574L)
  expect_equal(nrow(example_env$plot_set_review), 2L)
  expect_true(all(file.exists(file.path(
    example_env$refit_root,
    "plot-set",
    c("vehicles.png", "economy.png")
  ))))
  expect_identical(values$column$column, c("compact", "full"))
  expect_identical(values$retheme$status, c("pass", "fail"))
  expect_identical(values$format$file, "economy.png")
})

test_that("publication-asset lookup examples return recorded requirements", {
  skip_if_not_installed("yaml")

  all_examples <- yaml::read_yaml(options_examples_path())
  argument_by_section <- c(
    table_spec = "spec",
    media_spec = "spec",
    graphical_abstract_spec = "spec"
  )
  for (section in names(argument_by_section)) {
    examples <- all_examples[[section]]
    argument <- argument_by_section[[section]]
    expect_true(setequal(names(examples$arguments), argument), info = section)
    example_env <- new.env(parent = globalenv())
    eval(parse(text = examples$setup), envir = example_env)
    example <- examples$arguments[[argument]]
    expect_true(nzchar(example$prose), info = section)
    expect_true(nzchar(example$result), info = section)
    value <- suppressMessages(eval(parse(text = example$code), envir = example_env))
    expect_true(is.list(value), info = section)
    expect_true(length(value) == 2L, info = section)
  }

  table_values <- suppressMessages({
    e <- new.env(parent = globalenv())
    eval(parse(text = all_examples$table_spec$setup), e)
    eval(parse(text = all_examples$table_spec$arguments$spec$code), e)
  })
  expect_s3_class(table_values$publication, "figspec_table_spec")
  expect_identical(table_values$project$orientation, "portrait")

  media_values <- suppressMessages({
    e <- new.env(parent = globalenv())
    eval(parse(text = all_examples$media_spec$setup), e)
    eval(parse(text = all_examples$media_spec$arguments$spec$code), e)
  })
  expect_s3_class(media_values$publication, "figspec_media_spec")
  expect_identical(media_values$project$video_codec, "h264")

  abstract_values <- suppressMessages({
    e <- new.env(parent = globalenv())
    eval(parse(text = all_examples$graphical_abstract_spec$setup), e)
    eval(parse(text = all_examples$graphical_abstract_spec$arguments$spec$code), e)
  })
  expect_s3_class(abstract_values$publication, "figspec_abstract_spec")
  expect_equal(abstract_values$publication$width_mm, 80)
  expect_equal(abstract_values$project$width_mm, 120)
})

test_that("media_check examples inspect a real encoded video", {
  skip_if_not_installed("yaml")
  skip_if(!nzchar(Sys.which("ffmpeg")), "FFmpeg is required")
  skip_if(!nzchar(Sys.which("ffprobe")), "ffprobe is required")

  examples <- yaml::read_yaml(options_examples_path())$media_check
  expect_setequal(names(examples$arguments), c("path", "spec"))

  example_env <- new.env(parent = globalenv())
  eval(parse(text = examples$setup), envir = example_env)
  withr::defer(unlink(example_env$media_file))
  values <- lapply(names(examples$arguments), function(argument) {
    example <- examples$arguments[[argument]]
    expect_true(nzchar(example$prose), info = argument)
    expect_true(nzchar(example$result), info = argument)
    suppressMessages(eval(parse(text = example$code), envir = example_env))
  })
  names(values) <- names(examples$arguments)

  expect_gt(file.size(example_env$media_file), 1000)
  report <- values$path
  expect_s3_class(report, "figspec_report")
  expect_identical(report$status[report$check == "File validity"], "pass")
  expect_identical(report$status[report$check == "Format"], "pass")
  expect_identical(report$status[report$check == "Frame size"], "pass")
  expect_identical(report$status[report$check == "Video codec"], "pass")
  expect_identical(report$actual[report$check == "Frame size"], "640 x 360")
  expect_s3_class(values$spec$publication, "figspec_report")
})

test_that("table workflow examples execute with real data and files", {
  skip_if_not_installed("yaml")
  skip_if_not_installed("gt")

  all_examples <- yaml::read_yaml(options_examples_path())
  expected <- list(
    table_apply_spec = c("table", "spec"),
    table_save = c("filename", "table", "spec", "transform", "check", "..."),
    table_check = c("x", "spec")
  )

  for (topic in names(expected)) {
    examples <- all_examples[[topic]]
    expect_setequal(names(examples$arguments), expected[[topic]])
    example_env <- new.env(parent = globalenv())
    eval(parse(text = examples$setup), envir = example_env)
    for (argument in expected[[topic]]) {
      example <- examples$arguments[[argument]]
      expect_true(nzchar(example$prose), info = paste(topic, argument))
      expect_true(nzchar(example$result), info = paste(topic, argument))
      expect_silent(suppressMessages(
        eval(parse(text = example$code), envir = example_env)
      ))
    }
    if (identical(topic, "table_save")) {
      unlink(example_env$table_output_dir, recursive = TRUE)
    }
  }
})

test_that("R Markdown and Quarto option examples execute every argument", {
  skip_if_not_installed("yaml")
  skip_if_not_installed("knitr")

  all_examples <- yaml::read_yaml(options_examples_path())
  expected_arguments <- c("spec", "column", "width", "height", "units", "art_type")

  chunk_examples <- all_examples$figspec_knitr_options
  expect_setequal(names(chunk_examples$arguments), expected_arguments)
  chunk_env <- new.env(parent = globalenv())
  eval(parse(text = chunk_examples$setup), envir = chunk_env)
  chunk_values <- lapply(expected_arguments, function(argument) {
    example <- chunk_examples$arguments[[argument]]
    expect_true(nzchar(example$prose), info = paste("figspec_knitr_options", argument))
    expect_true(nzchar(example$result), info = paste("figspec_knitr_options", argument))
    suppressMessages(eval(parse(text = example$code), envir = chunk_env))
  })
  names(chunk_values) <- expected_arguments
  expect_equal(unname(chunk_values$column), c(85 / 25.4, 170 / 25.4), tolerance = 1e-6)
  expect_equal(unname(unlist(chunk_values$height)), c(170 / 25.4, 90 / 25.4), tolerance = 1e-6)
  expect_equal(unname(unlist(chunk_values$units)), c(16 / 2.54, 9 / 2.54), tolerance = 1e-6)
  expect_equal(chunk_values$width$fig.width, 12)
  expect_equal(chunk_values$width$fig.height, 6.75)
  expect_equal(unname(chunk_values$art_type), c(300, 600))

  setup_examples <- all_examples$figspec_knitr_setup
  expect_setequal(names(setup_examples$arguments), expected_arguments)
  setup_env <- new.env(parent = globalenv())
  eval(parse(text = setup_examples$setup), envir = setup_env)
  tracked <- c("fig.width", "fig.height", "dpi", "dev")
  before <- knitr::opts_chunk$get(tracked)
  withr::defer(do.call(knitr::opts_chunk$set, before))
  setup_values <- lapply(expected_arguments, function(argument) {
    example <- setup_examples$arguments[[argument]]
    expect_true(nzchar(example$prose), info = paste("figspec_knitr_setup", argument))
    expect_true(nzchar(example$result), info = paste("figspec_knitr_setup", argument))
    suppressMessages(eval(parse(text = example$code), envir = setup_env))
  })
  names(setup_values) <- expected_arguments
  expect_equal(unname(setup_values$column), c(85 / 25.4, 170 / 25.4), tolerance = 1e-6)
  expect_equal(unname(unlist(setup_values$height)), c(170 / 25.4, 90 / 25.4), tolerance = 1e-6)
  expect_equal(unname(unlist(setup_values$units)), c(12, 6.75))
  expect_equal(unname(unlist(setup_values$width)), c(10, 5.625, 192))
  expect_equal(unname(setup_values$art_type), c(300, 600))
})

test_that("registry maintenance examples use real registry data and YAML files", {
  skip_if_not_installed("yaml")

  all_examples <- yaml::read_yaml(options_examples_path())

  status_examples <- all_examples$registry_status
  expect_setequal(names(status_examples$arguments), c("max_age_days", "as_of"))
  status_env <- new.env(parent = globalenv())
  eval(parse(text = status_examples$setup), envir = status_env)
  status_values <- lapply(status_examples$arguments, function(example) {
    expect_true(nzchar(example$prose))
    expect_true(nzchar(example$result))
    suppressMessages(eval(parse(text = example$code), envir = status_env))
  })
  expect_true(all(vapply(status_values, is.data.frame, logical(1))))
  expect_equal(nrow(status_values[[1]]), nrow(spec_list()))

  stale_examples <- all_examples$registry_stale_entries
  expect_setequal(names(stale_examples$arguments), c("max_age_days", "as_of"))
  stale_env <- new.env(parent = globalenv())
  eval(parse(text = stale_examples$setup), envir = stale_env)
  stale_values <- lapply(stale_examples$arguments, function(example) {
    suppressMessages(eval(parse(text = example$code), envir = stale_env))
  })
  expect_true(all(vapply(stale_values, is.character, logical(1))))
  expect_gt(length(stale_values[[2]]), 0L)

  template_examples <- all_examples$registry_entry_template
  expect_setequal(names(template_examples$arguments), c("id", "name", "source_url"))
  template_env <- new.env(parent = globalenv())
  eval(parse(text = template_examples$setup), envir = template_env)
  template_values <- lapply(template_examples$arguments, function(example) {
    invisible(capture.output(
      value <- suppressMessages(eval(parse(text = example$code), envir = template_env))
    ))
    value
  })
  expect_true(all(vapply(template_values, function(x) is.character(x) && length(x) == 1L, logical(1))))
  expect_match(template_values[[1]], "example_research_report")
  expect_match(template_values[[3]], "https://example.org/author-guidance", fixed = TRUE)

  validation_examples <- all_examples$registry_validate_file
  expect_setequal(names(validation_examples$arguments), "path")
  validation_env <- new.env(parent = globalenv())
  eval(parse(text = validation_examples$setup), envir = validation_env)
  withr::defer(unlink(c(
    validation_env$valid_registry_file,
    validation_env$invalid_registry_file
  )))
  validation_values <- suppressMessages(
    eval(parse(text = validation_examples$arguments$path$code), envir = validation_env)
  )
  expect_identical(unname(validation_values), c(TRUE, FALSE))

  source_examples <- all_examples$registry_check_sources
  expect_setequal(names(source_examples$arguments), c("ids", "timeout"))
  expect_true(all(vapply(source_examples$arguments, function(example) {
    nzchar(example$prose) && nzchar(example$code) && nzchar(example$result)
  }, logical(1))))
})
