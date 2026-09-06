# Chunk options for R Markdown and Quarto, including that a value figspec
# substituted is announced rather than passed off as the journal's.

test_that("chunk options carry the journal's own size and resolution", {
  o <- figspec_knitr_options("plos_one", "single")
  expect_named(o, c("fig.width", "fig.height", "dpi", "dev"))
  # PLOS ONE states a 66.8 mm minimum width and 300 dpi.
  expect_equal(o$fig.width, 66.8 / 25.4, tolerance = 1e-6)
  expect_equal(o$dpi, 300)
  expect_equal(o$dev, "tiff")
})

test_that("chunk height follows an explicit request", {
  o <- figspec_knitr_options("frontiers", "double", height = 90, units = "mm")
  expect_equal(o$fig.height, 90 / 25.4, tolerance = 1e-6)
})

test_that("chunk height is validated before it reaches a graphics device", {
  expect_error(
    figspec_knitr_options("frontiers", "double", height = 0),
    class = "figspec_bad_size"
  )
  expect_error(
    figspec_knitr_options("frontiers", "double", height = c(80, 90)),
    class = "figspec_bad_size"
  )
})

test_that("a substituted default is announced, not passed off as a requirement", {
  # APS states a column width and a line minimum, but no resolution and no
  # file formats, so figspec has to supply both and must say so.
  expect_null(spec_get("aps")$dpi_min)
  expect_null(spec_get("aps")$formats)
  expect_message(
    figspec_knitr_options("aps", "single"),
    "not a recorded requirement"
  )
})

test_that("no message is emitted when the journal states the values", {
  expect_silent(figspec_knitr_options("plos_one", "single"))
})

test_that("the setup wrapper applies the options and returns the previous ones", {
  skip_if_not_installed("knitr")
  before <- knitr::opts_chunk$get(c("fig.width", "fig.height"))
  on.exit(do.call(knitr::opts_chunk$set, before), add = TRUE)

  old <- figspec_knitr_setup("cell_press", "single")
  now <- knitr::opts_chunk$get(c("fig.width", "fig.height", "dpi"))
  wanted <- figspec_knitr_options("cell_press", "single")

  expect_equal(now$fig.width, wanted$fig.width)
  expect_equal(now$dpi, wanted$dpi)
  expect_type(old, "list")
})

test_that("the setup wrapper reports a journal it does not know", {
  skip_if_not_installed("knitr")
  expect_error(figspec_knitr_setup("no_such_journal"), class = "figspec_not_found")
})

test_that("each format maps to a device knitr can actually use", {
  # The fallbacks matter: without ragg or svglite installed the chunk must
  # still name a device that exists rather than one that does not.
  expect_true(knitr_device("png") %in% c("ragg_png", "png"))
  expect_true(knitr_device("svg") %in% c("svglite", "svg"))
  expect_true(knitr_device("pdf") %in% c("cairo_pdf", "pdf"))
  expect_equal(knitr_device("tiff"), "tiff")
  expect_equal(knitr_device("tif"), "tiff")
  expect_equal(knitr_device("jpeg"), "jpeg")
  expect_equal(knitr_device("jpg"), "jpeg")
  expect_equal(knitr_device("eps"), "postscript")
  expect_equal(knitr_device("ps"), "postscript")
})

test_that("an unrecognised format falls back rather than failing the document", {
  # A chunk option is set at document build time, where an error would stop
  # the whole render for a format figspec simply has no mapping for.
  expect_equal(knitr_device("webp"), "png")
})

test_that("knitr produces a real file at the configured physical size", {
  skip_if_not_installed("knitr")
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("ragg")

  tracked <- c("fig.width", "fig.height", "dpi", "dev", "fig.path")
  before <- knitr::opts_chunk$get(tracked)
  withr::defer(do.call(knitr::opts_chunk$set, before))

  output_dir <- withr::local_tempdir()
  spec <- list(
    name = "Rendered report figure",
    formats = "png",
    dpi_min = 300
  )
  figspec_knitr_setup(
    spec,
    width = 85,
    height = 60,
    units = "mm",
    art_type = "colour"
  )
  knitr::opts_chunk$set(fig.path = paste0(output_dir, "/"))

  document <- c(
    "```{r real_plot}",
    "library(ggplot2)",
    "ggplot(mpg, aes(displ, hwy, colour = drv)) + geom_point()",
    "```"
  )
  knit_env <- new.env(parent = globalenv())
  suppressMessages(knitr::knit(text = document, quiet = TRUE, envir = knit_env))

  rendered <- file.path(output_dir, "real_plot-1.png")
  expect_true(file.exists(rendered))
  expect_gt(file.size(rendered), 10000)
  info <- inspect_file(rendered)
  expect_equal(info$width_mm, 85, tolerance = 0.2)
  expect_equal(info$height_mm, 60, tolerance = 0.2)
  expect_equal(info$dpi, 300, tolerance = 1)
})
