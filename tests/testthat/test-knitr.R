# Chunk options for R Markdown and Quarto, including that a value figspec
# substituted is announced rather than passed off as the journal's.

test_that("chunk options carry the journal's own size and resolution", {
  o <- figspec_chunk_opts("plos_one", "single")
  expect_named(o, c("fig.width", "fig.height", "dpi", "dev"))
  # PLOS ONE states a 66.8 mm minimum width and 300 dpi.
  expect_equal(o$fig.width, 66.8 / 25.4, tolerance = 1e-6)
  expect_equal(o$dpi, 300)
  expect_equal(o$dev, "tiff")
})

test_that("chunk height follows an explicit request", {
  o <- figspec_chunk_opts("frontiers", "double", height = 90, units = "mm")
  expect_equal(o$fig.height, 90 / 25.4, tolerance = 1e-6)
})

test_that("a substituted default is announced, not passed off as a requirement", {
  # APS states a column width and a line minimum, but no resolution and no
  # file formats, so figspec has to supply both and must say so.
  expect_null(journal_spec("aps")$dpi_min)
  expect_null(journal_spec("aps")$formats)
  expect_message(figspec_chunk_opts("aps", "single"), "not a requirement")
})

test_that("no message is emitted when the journal states the values", {
  expect_silent(figspec_chunk_opts("plos_one", "single"))
})

test_that("the setup wrapper applies the options and returns the previous ones", {
  skip_if_not_installed("knitr")
  before <- knitr::opts_chunk$get(c("fig.width", "fig.height"))
  on.exit(do.call(knitr::opts_chunk$set, before), add = TRUE)

  old <- figspec_knitr_setup("cell_press", "single")
  now <- knitr::opts_chunk$get(c("fig.width", "fig.height", "dpi"))
  wanted <- figspec_chunk_opts("cell_press", "single")

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
