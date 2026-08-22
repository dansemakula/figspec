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
  # Nature's formatting guide states neither formats nor a resolution.
  expect_message(figspec_chunk_opts("nature", "single"), "not a requirement")
})

test_that("no message is emitted when the journal states the values", {
  expect_silent(figspec_chunk_opts("plos_one", "single"))
})
