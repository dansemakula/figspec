table_project_spec <- function(format = c("html", "docx")) {
  list(
    name = "Research report",
    source_url = "internal:research-report",
    verified_on = "2026-09-06",
    tables = list(
      formats = format,
      orientation = "portrait",
      font_families = "Arial",
      font_min_pt = 9,
      header_bold = TRUE,
      vertical_rules = FALSE,
      horizontal_rules = "minimal",
      repeat_header = TRUE
    )
  )
}

test_that("data frames become styled gt tables with measurable evidence", {
  skip_if_not_installed("gt")
  table <- table_apply_spec(head(ggplot2::mpg), table_project_spec())
  expect_s3_class(table, "gt_tbl")
  evidence <- attr(table, "figspec_table_evidence")
  expect_identical(evidence$rows, 6L)
  expect_identical(evidence$columns, 11L)
  expect_identical(evidence$font_family, "Arial")
  expect_identical(evidence$font_size_pt, 9)
  expect_true(evidence$header_bold)
  expect_false(evidence$vertical_rules)
})

test_that("live table checking uses applied rather than assumed values", {
  skip_if_not_installed("gt")
  spec <- table_project_spec()
  plain <- table_check(head(ggplot2::mpg), spec)
  expect_true(any(plain$status == "unknown"))
  styled <- table_check(table_apply_spec(head(ggplot2::mpg), spec), spec)
  expect_false(any(styled$status == "fail"))
  expect_true(all(
    styled$status[styled$check %in% c(
      "Minimum type size", "Bold header", "Vertical rules",
      "Horizontal rules"
    )] == "pass"
  ))
})

test_that("a maximum-only type rule is applied at the permitted maximum", {
  skip_if_not_installed("gt")
  spec <- list(
    name = "Compact table",
    tables = list(font_max_pt = 8)
  )
  styled <- table_apply_spec(head(mtcars), spec)
  evidence <- attr(styled, "figspec_table_evidence")
  expect_identical(evidence$font_size_pt, 8)
  checked <- table_check(styled, spec)
  expect_identical(
    checked$status[checked$check == "Maximum type size"],
    "pass"
  )
})

test_that("HTML export writes, reopens and checks a real table", {
  skip_if_not_installed("gt")
  path <- file.path(withr::local_tempdir(), "table with spaces.html")
  withr::local_envvar(R_USER_CACHE_DIR = tempdir())
  saved <- suppressWarnings(table_save(
    path, ggplot2::mpg[1:25, ], table_project_spec("html")
  ))
  expect_true(file.exists(path))
  expect_gt(file.size(path), 1000)
  report <- attr(saved, "figspec_table_report")
  expect_s3_class(report, "figspec_table_report")
  expect_identical(
    report$status[report$check == "File format"],
    "pass"
  )
  expect_false(any(report$status %in% c("fail", "invalid")))
  info <- figspec:::inspect_table_file(path)
  expect_true(info$valid)
  expect_gte(info$rows, 26L)
})

test_that("HTML table export escapes code-like cell contents", {
  skip_if_not_installed("gt")
  path <- file.path(withr::local_tempdir(), "untrusted-cell-text.html")
  hostile_text <- "<script>document.body.innerHTML='changed'</script>"
  table_save(
    path,
    data.frame(label = hostile_text),
    check = FALSE
  )
  html <- paste(readLines(path, warn = FALSE), collapse = "\n")
  expect_false(grepl(hostile_text, html, fixed = TRUE))
  expect_true(grepl("&lt;script&gt;", html, fixed = TRUE))
})

test_that("DOCX export is a real editable table with page orientation", {
  skip_if_not_installed("gt")
  skip_if_not(rmarkdown::pandoc_available())
  path <- file.path(withr::local_tempdir(), "editable-table.docx")
  saved <- suppressWarnings(table_save(
    path, ggplot2::mpg[1:12, ], table_project_spec("docx")
  ))
  expect_gt(file.size(path), 1000)
  info <- figspec:::inspect_table_file(path)
  expect_true(info$valid)
  expect_true(info$editable)
  expect_identical(info$orientation, "portrait")
  report <- attr(saved, "figspec_table_report")
  expect_identical(
    report$status[report$check == "Editable output"],
    character()
  )
})

test_that("RTF and TeX exports are structurally inspected", {
  skip_if_not_installed("gt")
  out_dir <- withr::local_tempdir()
  for (extension in c("rtf", "tex", "latex")) {
    path <- file.path(out_dir, paste0("table.", extension))
    spec <- table_project_spec(extension)
    saved <- suppressWarnings(table_save(path, head(ggplot2::mpg), spec))
    expect_true(file.exists(path), info = extension)
    info <- figspec:::inspect_table_file(path)
    expect_true(info$valid, info = extension)
    expect_true(info$editable, info = extension)
    expect_gte(info$rows, 6L)
    expect_s3_class(
      attr(saved, "figspec_table_report"),
      "figspec_table_report"
    )
  }
})

test_that("grid tables produce real vector and raster outputs", {
  skip_if_not_installed("gridExtra")
  grob <- gridExtra::tableGrob(ggplot2::mpg[1:8, 1:5])
  out_dir <- withr::local_tempdir()
  for (extension in c("pdf", "png", "jpeg")) {
    path <- file.path(out_dir, paste0("grid-table.", extension))
    suppressWarnings(table_save(
      path, grob, spec = NULL, transform = FALSE
    ))
    info <- figspec:::inspect_table_file(path)
    expect_true(info$valid, info = extension)
    expect_gt(file.size(path), 500)
  }
})

test_that("grid table typography and headers are changed before export", {
  skip_if_not_installed("gridExtra")
  grob <- gridExtra::tableGrob(ggplot2::mpg[1:5, 1:4])
  styled <- table_apply_spec(grob, table_project_spec("pdf"))
  evidence <- attr(styled, "figspec_table_evidence")
  expect_identical(evidence$font_family, "Arial")
  expect_identical(evidence$font_size_pt, 9)
  expect_true(evidence$header_bold)
  text_grobs <- styled$grobs[vapply(styled$grobs, inherits, logical(1), "text")]
  expect_true(all(vapply(
    text_grobs,
    function(g) identical(g$gp$fontfamily, "Arial") &&
      identical(g$gp$fontsize, 9),
    logical(1)
  )))
  header <- styled$layout$name == "colhead-fg"
  expect_true(all(vapply(
    styled$grobs[header],
    function(g) identical(g$gp$font, 2L),
    logical(1)
  )))
})

test_that("flextable, kable and grid objects use their own exporters", {
  skip_if_not_installed("flextable")
  skip_if_not_installed("kableExtra")
  skip_if_not_installed("gridExtra")
  spec <- table_project_spec("html")
  out_dir <- withr::local_tempdir()

  ft <- flextable::flextable(ggplot2::mpg[1:8, 1:5])
  ft <- table_apply_spec(ft, spec)
  expect_s3_class(ft, "flextable")
  ft_path <- file.path(out_dir, "flextable.html")
  suppressWarnings(table_save(ft_path, ft, spec, transform = FALSE))
  expect_true(figspec:::inspect_table_file(ft_path)$valid)

  kb <- knitr::kable(ggplot2::mpg[1:8, 1:5], format = "html")
  kb <- table_apply_spec(kb, spec)
  expect_s3_class(kb, "knitr_kable")
  kb_path <- file.path(out_dir, "kable.html")
  suppressWarnings(table_save(kb_path, kb, spec, transform = FALSE))
  expect_true(figspec:::inspect_table_file(kb_path)$valid)

  grob <- gridExtra::tableGrob(ggplot2::mpg[1:5, 1:4])
  grid_path <- file.path(out_dir, "grid-table.png")
  suppressWarnings(table_save(
    grid_path, grob, spec = NULL, transform = FALSE
  ))
  expect_true(figspec:::inspect_table_file(grid_path)$valid)
})

test_that("mixed submissions classify live figures and tables", {
  skip_if_not_installed("gt")
  plot <- ggplot2::ggplot(
    ggplot2::mpg,
    ggplot2::aes(displ, hwy)
  ) + ggplot2::geom_point()
  review <- suppressWarnings(suppressMessages(submission_check(
    list(figure = plot, summary = head(ggplot2::mpg)),
    spec = "nature",
    column = "single"
  )))
  expect_identical(review$asset, c("figure", "table"))
  expect_identical(review$column, c("single", NA_character_))
  expect_s3_class(submission_detail(review, "summary"), "figspec_table_report")
})

test_that("mixed submissions reopen real figure and table files", {
  skip_if_not_installed("gt")
  skip_if_not_installed("ragg")
  out_dir <- withr::local_tempdir()
  figure_path <- file.path(out_dir, "fuel-economy.png")
  table_path <- file.path(out_dir, "vehicle-summary.html")
  plot <- ggplot2::ggplot(
    ggplot2::mpg,
    ggplot2::aes(displ, hwy, colour = drv)
  ) + ggplot2::geom_point()
  suppressWarnings(fig_save(
    figure_path, plot, width = 85, height = 65, units = "mm",
    dpi = 300, check = FALSE
  ))
  spec <- table_project_spec("html")
  spec$columns <- list(single = 85)
  spec$formats <- "png"
  spec$dpi_min <- 300
  suppressWarnings(table_save(table_path, head(ggplot2::mpg), spec))

  review <- suppressMessages(submission_check(
    c(figure_path, table_path), spec, column = "single"
  ))
  expect_identical(review$asset, c("figure", "table"))
  expect_true(all(review$result != "invalid"))
  expect_s3_class(
    submission_detail(review, basename(table_path)),
    "figspec_table_report"
  )
})

test_that("ambiguous vector files can be identified as tables", {
  skip_if_not_installed("gridExtra")
  path <- file.path(withr::local_tempdir(), "summary.pdf")
  grob <- gridExtra::tableGrob(head(mtcars, 4))
  suppressWarnings(table_save(path, grob, check = FALSE))
  review <- submission_check(path, asset_type = "table")
  expect_identical(review$asset, "table")
  expect_identical(review$result, "inspection")
})

test_that("large real tables remain inspectable without changing row counts", {
  skip_if_not_installed("gt")
  large <- ggplot2::mpg[rep(seq_len(nrow(ggplot2::mpg)), length.out = 50000), ]
  styled <- table_apply_spec(large, table_project_spec("html"))
  evidence <- attr(styled, "figspec_table_evidence")
  expect_identical(evidence$rows, 50000L)
  report <- table_check(styled, table_project_spec("html"))
  expect_false(any(report$status == "invalid"))
})

test_that("a medium real table survives an HTML round trip", {
  skip_if_not_installed("gt")
  medium <- ggplot2::mpg[
    rep(seq_len(nrow(ggplot2::mpg)), length.out = 5000),
  ]
  path <- file.path(withr::local_tempdir(), "medium-table.html")
  saved <- suppressWarnings(table_save(
    path, medium, table_project_spec("html")
  ))
  info <- figspec:::inspect_table_file(path)
  expect_true(info$valid)
  expect_gte(info$rows, 5001L)
  expect_false(any(
    attr(saved, "figspec_table_report")$status == "invalid"
  ))
})

test_that("unsafe, corrupt and unsupported table inputs fail closed", {
  expect_error(table_check(42), class = "figspec_unsupported")
  expect_error(table_save("table.csv", head(mtcars)), class = "figspec_unsupported")
  expect_error(
    table_apply_spec(head(mtcars), list(name = "No table rules")),
    class = "figspec_not_found"
  )
  expect_error(
    table_apply_spec(
      head(mtcars),
      list(name = "Bad table rules", tables = list(orientation = "diagonal"))
    ),
    class = "figspec_bad_input"
  )
  corrupt <- withr::local_tempfile(fileext = ".docx")
  writeLines("not a Word file", corrupt)
  report <- table_check(corrupt)
  expect_identical(report$status[[1]], "invalid")
  expect_identical(report$actual[[1]], "invalid")

  oversized <- withr::local_tempfile(fileext = ".html")
  writeBin(raw(figspec:::TABLE_TEXT_LIMIT + 1L), oversized)
  bounded <- table_check(oversized)
  expect_identical(bounded$status[[1]], "invalid")
})

test_that("a renderer failure cannot replace an existing table", {
  skip_if_not_installed("gt")
  path <- file.path(withr::local_tempdir(), "existing.html")
  writeLines("keep this file", path)
  expect_error(
    table_save(path, head(mtcars), check = FALSE, unknown_argument = TRUE)
  )
  expect_identical(readLines(path), "keep this file")
  leftovers <- list.files(dirname(path), pattern = "figspec-table")
  expect_length(leftovers, 0)
})

test_that("a directory can never be replaced by a table file", {
  skip_if_not_installed("gt")
  target <- file.path(withr::local_tempdir(), "existing.html")
  dir.create(target)
  expect_error(
    table_save(target, head(mtcars), check = FALSE),
    class = "figspec_bad_input"
  )
  expect_true(dir.exists(target))
})

test_that("unsupported table-system and format combinations fail before writing", {
  skip_if_not_installed("gt")
  path <- file.path(withr::local_tempdir(), "unsupported-table.jpeg")
  table <- gt::gt(head(mtcars))
  expect_error(
    table_save(path, table, check = FALSE),
    class = "figspec_unsupported"
  )
  expect_false(file.exists(path))
})

test_that("exporter arguments cannot bypass the transactional destination", {
  skip_if_not_installed("gt")
  root <- withr::local_tempdir()
  destination <- file.path(root, "requested.html")
  redirected <- file.path(root, "redirected")
  dir.create(redirected)
  expect_error(
    table_save(
      destination, gt::gt(head(mtcars)), check = FALSE,
      path = redirected
    ),
    class = "figspec_bad_input"
  )
  expect_false(file.exists(destination))
  expect_length(list.files(redirected, all.files = TRUE, no.. = TRUE), 0)
})

test_that("grid table exporters accept explicit canvas settings safely", {
  skip_if_not_installed("gridExtra")
  skip_if_not_installed("ragg")
  path <- file.path(withr::local_tempdir(), "sized-grid-table.png")
  table_save(
    path,
    gridExtra::tableGrob(head(mtcars, 4)),
    check = FALSE,
    width = 120,
    height = 70,
    dpi = 180
  )
  info <- figspec:::inspect_table_file(path)
  expect_equal(info$width_mm, 120, tolerance = 0.2)
  expect_equal(info$height_mm, 70, tolerance = 0.2)
})

test_that("table registry fields are validated by type and vocabulary", {
  entry <- yaml::read_yaml(
    system.file("extdata", "journals.yaml", package = "figspec"),
    eval.expr = FALSE
  )$journals[[1]]
  entry$id <- "table_test"
  entry$name <- "Table test"
  entry$source_url <- "internal:table-test"
  entry$verified_on <- "2026-09-06"
  entry$sources <- NULL
  entry$requirements <- list()
  entry$not_stated <- list()
  entry$tables <- list(
    formats = c("html", "docx"),
    orientation = "portrait",
    font_min_pt = 9,
    header_bold = TRUE,
    vertical_rules = FALSE,
    horizontal_rules = "minimal"
  )
  expect_silent(figspec:::validate_registry(list(entry)))
  entry$tables$orientation <- "diagonal"
  expect_error(
    figspec:::validate_registry(list(entry)),
    class = "figspec_bad_registry"
  )

  entry$tables$orientation <- "portrait"
  entry$tables$formats <- c("html", "HTML")
  expect_error(
    figspec:::validate_registry(list(entry)),
    class = "figspec_bad_registry"
  )

  entry$tables$formats <- "html"
  entry$tables$format <- "docx"
  expect_error(
    figspec:::validate_registry(list(entry)),
    class = "figspec_bad_registry"
  )

  entry$tables$formats <- NULL
  entry$tables$format <- 1
  expect_error(
    figspec:::validate_registry(list(entry)),
    class = "figspec_bad_registry"
  )
})

test_that("confirmed absent table fields are not reported as unreviewed", {
  skip_if_not_installed("gt")
  spec <- list(
    name = "Reviewed table rules",
    source_url = "internal:reviewed-table-rules",
    verified_on = "2026-09-06",
    tables = list(formats = "html"),
    tables_not_stated = "font_min_pt"
  )
  checked <- table_check(head(mtcars), spec)
  font_row <- figspec:::table_check_row(
    "Minimum type size", NULL, NULL, FALSE, spec, "tables.font_min_pt"
  )
  expect_identical(font_row$status, "unspecified")
  expect_match(font_row$requirement, "not specified")
  expect_false(any(checked$status == "fail"))
})
