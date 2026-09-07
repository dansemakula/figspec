project_figure_spec <- function(formats = c("png", "pdf", "tiff"), dpi = 180) {
  list(
    name = "Research report",
    columns = list(full = 85),
    formats = formats,
    dpi_min = dpi,
    font_min_pt = 9,
    font_max_pt = 10,
    min_line_pt = 0.6,
    axis_lines_and_ticks = TRUE
  )
}

cleanup_chrome_temp_artifacts <- function() {
  patterns <- c(
    "com.google.Chrome.*",
    ".org.chromium.Chromium.*",
    "org.chromium.Chromium.*"
  )
  paths <- unique(unlist(lapply(
    patterns,
    function(pattern) Sys.glob(file.path(tempdir(), pattern))
  )))
  if (length(paths)) {
    unlink(paths, recursive = TRUE, force = TRUE)
  }
  invisible(paths)
}

skip_if_no_working_chrome <- function() {
  skip_if_not_installed("chromote")
  chrome <- tryCatch(chromote::find_chrome(), error = function(e) "")
  skip_if(!nzchar(chrome), "Chrome or Chromium is not available")
  withr::defer(cleanup_chrome_temp_artifacts())
  browser <- tryCatch(chromote::Chromote$new(), error = function(e) NULL)
  skip_if(is.null(browser), "Chrome or Chromium cannot start in this environment")
  browser$close()
  invisible(TRUE)
}

test_that("plotting systems are identified without guessing from output files", {
  expect_identical(figspec:::figure_system(function() plot(1:3)), "base")
  expect_identical(figspec:::figure_system(~plot(1:3)), "base")
  expect_identical(
    figspec:::figure_system(grid::textGrob("grid figure")), "grid"
  )

  skip_if_not_installed("lattice")
  trellis <- lattice::xyplot(mpg ~ wt, data = datasets::mtcars)
  expect_identical(figspec:::figure_system(trellis), "lattice")
})

test_that("a base drawing function is transformed, exported and verified", {
  skip_if_not_installed("ragg")
  observed <- new.env(parent = emptyenv())
  draw <- function() {
    observed$pointsize <- graphics::par("ps")
    observed$linewidth <- graphics::par("lwd")
    observed$palette <- grDevices::palette()
    graphics::plot(
      datasets::mtcars$wt, datasets::mtcars$mpg,
      col = as.integer(factor(datasets::mtcars$cyl)), pch = 19,
      xlab = "Weight", ylab = "Fuel economy"
    )
  }
  out <- file.path(withr::local_tempdir(), "base-real-data.png")
  saved <- fig_save(
    out, draw, spec = project_figure_spec("png", 180), column = "full",
    height = 60, check = FALSE
  )

  info <- figspec:::inspect_file(out)
  expect_equal(info$width_mm, 85, tolerance = 0.2)
  expect_equal(info$height_mm, 60, tolerance = 0.2)
  expect_equal(info$dpi, 180, tolerance = 1)
  expect_identical(attr(saved, "figspec_system"), "base")
  expect_identical(attr(saved, "figspec_transformation"), "defaults")
  expect_equal(observed$pointsize, 9)
  expect_equal(observed$linewidth, 0.8)
  expect_equal(
    unname(grDevices::col2rgb(observed$palette[[1]])),
    unname(grDevices::col2rgb("#000000"))
  )
})

test_that("a base formula keeps its data environment and exact canvas", {
  skip_if_not_installed("ragg")
  x <- datasets::airquality$Temp
  y <- datasets::airquality$Ozone
  out <- file.path(withr::local_tempdir(), "base-formula.png")
  saved <- fig_save(
    out, ~graphics::plot(x, y, pch = 19),
    width = 90, height = 65, dpi = 150, check = FALSE
  )
  info <- figspec:::inspect_file(out)
  expect_equal(info$width_mm, 90, tolerance = 0.2)
  expect_equal(info$height_mm, 65, tolerance = 0.2)
  expect_equal(info$dpi, 150, tolerance = 1)
  expect_identical(attr(saved, "figspec_system"), "base")
})

test_that("base vector text is transformed and independently read back", {
  skip_if_not_installed("pdftools")
  out <- file.path(withr::local_tempdir(), "base-type.pdf")
  spec <- project_figure_spec("pdf")
  suppressMessages(fig_save(
    out,
    function() graphics::plot(
      datasets::mtcars$wt, datasets::mtcars$mpg,
      main = "Fuel economy", xlab = "Weight", ylab = "Miles per gallon"
    ),
    spec = spec, column = "full", check = FALSE
  ))
  report <- fig_check(out, spec, column = "full")
  type <- report[report$check == "Type size", , drop = FALSE]
  expect_identical(type$status, "pass")
  expect_match(type$actual, "9 pt")
  expect_match(type$actual, "10 pt")
})

test_that("completed recorded plots are not falsely described as restyled", {
  skip_if_not_installed("ragg")
  grDevices::pdf(NULL)
  on.exit(if (grDevices::dev.cur() > 1L) grDevices::dev.off(), add = TRUE)
  grDevices::dev.control(displaylist = "enable")
  graphics::plot(datasets::mtcars$wt, datasets::mtcars$mpg)
  recorded <- grDevices::recordPlot()
  grDevices::dev.off()

  out <- file.path(withr::local_tempdir(), "recorded.png")
  saved <- NULL
  expect_warning(
    saved <- fig_save(
      out, recorded, spec = project_figure_spec("png", 150),
      column = "full", height = 60, check = FALSE
    ),
    "already contains a completed drawing"
  )
  expect_true(file.exists(out))
  expect_identical(attr(saved, "figspec_system"), "recordedplot")
  expect_identical(attr(saved, "figspec_transformation"), "unavailable")
})

test_that("lattice receives visual requirements before exact export", {
  skip_if_not_installed("lattice")
  skip_if_not_installed("ragg")
  plot <- lattice::xyplot(
    Sepal.Length ~ Sepal.Width,
    data = datasets::iris,
    groups = Species,
    auto.key = TRUE
  )
  spec <- project_figure_spec("png", 160)
  transformed <- figspec:::transform_figure(
    plot, spec_get(spec), "lattice"
  )
  expect_identical(attr(transformed, "figspec_transformation"), "full")
  expect_equal(transformed$par.settings$fontsize$text, 9)
  expect_length(transformed$par.settings$superpose.symbol$col, 8L)
  expect_equal(
    min(transformed$par.settings$superpose.line$lwd),
    0.8,
    tolerance = 1e-10
  )

  out <- file.path(withr::local_tempdir(), "lattice-real-data.png")
  saved <- fig_save(
    out, plot, spec = spec, column = "full", height = 60, check = FALSE
  )
  info <- figspec:::inspect_file(out)
  expect_equal(info$width_mm, 85, tolerance = 0.2)
  expect_equal(info$height_mm, 60, tolerance = 0.2)
  expect_equal(info$dpi, 160, tolerance = 1)
  expect_identical(attr(saved, "figspec_system"), "lattice")
})

test_that("grid grobs inherit specification defaults", {
  skip_if_not_installed("ragg")
  grob <- grid::grobTree(
    grid::rectGrob(gp = grid::gpar(fill = "#56B4E9")),
    grid::textGrob("Measured outcomes", y = 0.9),
    grid::pointsGrob(
      x = 0.1 + 0.8 * (datasets::mtcars$wt - min(datasets::mtcars$wt)) /
        diff(range(datasets::mtcars$wt)),
      y = 0.1 + 0.7 * (datasets::mtcars$mpg - min(datasets::mtcars$mpg)) /
        diff(range(datasets::mtcars$mpg))
    )
  )
  spec <- project_figure_spec("png", 140)
  transformed <- figspec:::transform_figure(grob, spec_get(spec), "grid")
  expect_identical(attr(transformed, "figspec_transformation"), "defaults")
  expect_equal(transformed$gp$fontsize, 9)
  expect_equal(transformed$gp$lwd, 0.8)

  out <- file.path(withr::local_tempdir(), "grid-real-data.png")
  saved <- fig_save(
    out, grob, spec = spec, column = "full", height = 60, check = FALSE
  )
  expect_true(file.exists(out))
  expect_identical(attr(saved, "figspec_system"), "grid")
})

test_that("non-gtable systems reject panel claims they cannot guarantee", {
  expect_error(
    fig_save(
      tempfile(fileext = ".png"),
      function() graphics::plot(1:3),
      panel_width = 60,
      check = FALSE
    ),
    class = "figspec_unsupported"
  )
})

test_that("fig_check renders lattice input and verifies the resulting file", {
  skip_if_not_installed("lattice")
  skip_if_not_installed("ragg")
  spec <- project_figure_spec("png", 150)
  report <- fig_check(
    lattice::xyplot(mpg ~ wt, data = datasets::mtcars),
    spec = spec, column = "full", height = 60,
    dpi = 150, format = "png"
  )
  expect_identical(attr(report, "input"), "lattice plot rendered for inspection")
  expect_identical(report$status[report$check == "Width"], "pass")
  expect_identical(report$status[report$check == "Resolution"], "pass")
  expect_identical(report$status[report$check == "File format"], "pass")
  expect_identical(report$status[report$check == "Type size"], "unknown")
})

test_that("one submission can contain base and lattice figures", {
  skip_if_not_installed("lattice")
  skip_if_not_installed("ragg")
  spec <- project_figure_spec("png", 150)
  figures <- list(
    base = function() graphics::plot(
      datasets::mtcars$wt, datasets::mtcars$mpg,
      xlab = "Weight", ylab = "Fuel economy"
    ),
    lattice = lattice::xyplot(
      Sepal.Length ~ Sepal.Width,
      data = datasets::iris,
      groups = Species
    )
  )
  review <- suppressWarnings(submission_check(
    figures, spec, column = "full", dpi = 150
  ))
  expect_s3_class(review, "figspec_submission")
  expect_identical(review$file, c("base", "lattice"))
  expect_true(all(is.na(review$panel_mm)))
  expect_true(all(review$result %in% c("pass", "incomplete")))
  inputs <- vapply(attr(review, "reports"), attr, "", which = "input")
  expect_match(inputs[["base"]], "base R")
  expect_match(inputs[["lattice"]], "lattice")
})

test_that("base and lattice figures can be re-exported as a set", {
  skip_if_not_installed("lattice")
  skip_if_not_installed("ragg")
  figures <- list(
    base = function() graphics::plot(
      datasets::airquality$Temp, datasets::airquality$Ozone,
      xlab = "Temperature", ylab = "Ozone"
    ),
    lattice = lattice::xyplot(
      mpg ~ wt, data = datasets::mtcars, groups = cyl
    )
  )
  out <- withr::local_tempdir()
  review <- suppressWarnings(fig_refit(
    figures, project_figure_spec("png", 150), out,
    column = "full", format = "png"
  ))
  expect_equal(nrow(review), 2L)
  expect_true(all(file.exists(file.path(out, c("base.png", "lattice.png")))))
  widths <- vapply(
    file.path(out, c("base.png", "lattice.png")),
    function(path) figspec:::inspect_file(path)$width_mm,
    numeric(1)
  )
  expect_equal(unname(widths), c(85, 85), tolerance = 0.2)
})

test_that("Plotly traces receive accessible colours, shapes and line weights", {
  skip_if_not_installed("plotly")
  plot <- plotly::plot_ly(
    data = ggplot2::mpg,
    x = ~displ, y = ~hwy,
    color = ~drv, symbol = ~drv,
    type = "scatter", mode = "markers"
  )
  transformed <- suppressMessages(figspec:::transform_figure(
    plot, spec_get(project_figure_spec()), "plotly"
  ))
  colours <- vapply(
    transformed$x$data, function(trace) trace$marker$color,
    character(1)
  )
  symbols <- vapply(
    transformed$x$data, function(trace) trace$marker$symbol,
    character(1)
  )
  expect_gte(length(unique(colours)), 3L)
  expect_gte(length(unique(symbols)), 3L)
  expect_true(all(vapply(
    transformed$x$data,
    function(trace) trace$marker$line$width >= 0.6 * 96 / 72,
    logical(1)
  )))
  expect_identical(attr(transformed, "figspec_transformation"), "full")
})

test_that("Plotly exports a real exact-size PNG through the local renderer", {
  skip_if_not_installed("plotly")
  skip_if_not_installed("htmlwidgets")
  skip_if_not_installed("webshot2")
  skip_if_no_working_chrome()
  withr::defer(cleanup_chrome_temp_artifacts())

  plot <- plotly::plot_ly(
    data = ggplot2::mpg,
    x = ~displ, y = ~hwy, color = ~drv,
    type = "scatter", mode = "markers"
  )
  out <- file.path(withr::local_tempdir(), "plotly-real-data.png")
  saved <- suppressMessages(fig_save(
    out, plot, spec = project_figure_spec("png", 144),
    column = "full", height = 60, check = FALSE
  ))
  info <- figspec:::inspect_file(out)
  expect_equal(info$width_mm, 85, tolerance = 0.2)
  expect_equal(info$height_mm, 60, tolerance = 0.2)
  expect_equal(info$dpi, 144, tolerance = 1)
  expect_identical(attr(saved, "figspec_system"), "plotly")
  expect_identical(attr(saved, "figspec_transformation"), "full")
})

test_that("Plotly exports TIFF with exact density and compression", {
  skip_if_not_installed("plotly")
  skip_if_not_installed("htmlwidgets")
  skip_if_not_installed("webshot2")
  skip_if_not_installed("magick")
  skip_if_no_working_chrome()
  withr::defer(cleanup_chrome_temp_artifacts())

  spec <- project_figure_spec("tiff", 120)
  spec$tiff_compression <- "lzw"
  plot <- plotly::plot_ly(
    data = datasets::mtcars,
    x = ~wt, y = ~mpg,
    type = "scatter", mode = "lines+markers"
  )
  out <- file.path(withr::local_tempdir(), "plotly-real-data.tiff")
  suppressMessages(fig_save(
    out, plot, spec = spec, column = "full", height = 60, check = FALSE
  ))
  info <- figspec:::inspect_file(out)
  expect_equal(info$width_mm, 85, tolerance = 0.3)
  expect_equal(info$height_mm, 60, tolerance = 0.3)
  expect_equal(info$dpi, 120, tolerance = 1)
  expect_identical(info$compression, "lzw")
})

test_that("base adapter handles a 250,000-row stress figure", {
  skip_if_not(identical(Sys.getenv("FIGSPEC_RUN_STRESS"), "true"))
  skip_if_not_installed("ragg")
  set.seed(20260906)
  large <- data.frame(x = stats::rnorm(250000), y = stats::rnorm(250000))
  out <- file.path(withr::local_tempdir(), "base-250k.png")
  fig_save(
    out,
    function() graphics::plot(
      large$x, large$y, pch = ".", col = "#1A7391",
      xlab = "Exposure", ylab = "Outcome"
    ),
    width = 120, height = 80, dpi = 150, check = FALSE
  )
  info <- figspec:::inspect_file(out)
  expect_equal(info$width_mm, 120, tolerance = 0.2)
  expect_equal(info$height_mm, 80, tolerance = 0.2)
  expect_gt(file.size(out), 1000)
})
