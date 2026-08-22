make_plot <- function() {
  ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point() +
    ggplot2::labs(title = "Fuel economy")
}

test_that("text sizes are read out of a built plot", {
  sizes <- collect_text_sizes(make_plot())
  expect_gt(nrow(sizes), 0)
  # ggplot2's default base size is 11 pt, with axis text at rel(0.8) = 8.8 pt
  # and the title at rel(1.2) = 13.2 pt.
  expect_equal(min(sizes$size_pt), 8.8, tolerance = 1e-6)
  expect_equal(max(sizes$size_pt), 13.2, tolerance = 1e-6)
})

test_that("a default plot breaches a journal ceiling and the theme repairs it", {
  # PLOS ONE states 8-12 pt; a default ggplot title is 13.2 pt.
  before <- check_journal(make_plot(), "plos_one")
  type_row <- before[before$check == "Type size", ]
  expect_equal(type_row$status, "fail")

  after <- check_journal(make_plot() + theme_journal("plos_one"), "plos_one")
  expect_equal(after[after$check == "Type size", ]$status, "pass")
})

test_that("a requirement the publisher does not state is never a pass", {
  # Frontiers states no maximum file size and no height limit.
  r <- check_journal(make_plot(), "frontiers")
  expect_equal(r[r$check == "File size", ]$status, "unspecified")
  expect_equal(r[r$check == "Height", ]$status, "unspecified")
  expect_false(any(r$status == "unspecified" & r$requirement != "not specified by publisher"))
})

test_that("a requirement we cannot measure is unknown, not a pass", {
  r <- check_journal(make_plot(), "plos_one")
  expect_equal(r[r$check == "Resolution", ]$status, "unknown")
  expect_true(all(r$status %in% c("pass", "fail", "unspecified", "unknown")))
})

test_that("widths are checked against the journal's own columns", {
  p <- make_plot()
  ok <- check_journal(p, "cell_press", column = "single")
  expect_equal(ok[ok$check == "Width", ]$status, "pass")
  bad <- check_journal(p, "cell_press", width = 200, units = "mm")
  expect_equal(bad[bad$check == "Width", ]$status, "fail")
})

test_that("subsetting a report yields a plain data frame", {
  r <- check_journal(make_plot(), "frontiers")
  sub <- r[, c("check", "status")]
  expect_s3_class(sub, "data.frame")
  expect_false(inherits(sub, "figspec_report"))
  expect_null(attr(sub, "source_url"))
})

test_that("check_journal rejects inputs it cannot handle", {
  expect_error(check_journal(42, "frontiers"), "ggplot object or a path")
  expect_error(check_journal("no/such/file.tiff", "frontiers"), "File not found")
})

test_that("an unmeasurable width is unknown, never a failure", {
  path <- withr::local_tempfile(fileext = ".png")
  # Base R's png() does not record resolution in the file.
  grDevices::png(path, width = 85, height = 60, units = "mm", res = 300)
  plot(mtcars$wt, mtcars$mpg)
  grDevices::dev.off()

  r <- check_journal(path, "plos_one")
  expect_equal(r[r$check == "Width", ]$status, "unknown")
  expect_false(any(r$status == "fail" & r$check == "Width"))
})

test_that("supplying the resolution makes an unrecorded file measurable", {
  path <- withr::local_tempfile(fileext = ".png")
  grDevices::png(path, width = 85, height = 60, units = "mm", res = 300)
  plot(mtcars$wt, mtcars$mpg)
  grDevices::dev.off()

  r <- check_journal(path, "plos_one", dpi = 300)
  expect_equal(r[r$check == "Width", ]$status, "pass")
  expect_equal(r[r$check == "Resolution", ]$status, "pass")
})
