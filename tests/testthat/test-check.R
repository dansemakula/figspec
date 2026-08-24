# fig_check() itself: reading measurements out of a plot, and the four outcomes
# a row can carry.

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
  before <- fig_check(make_plot(), "plos_one")
  type_row <- before[before$check == "Type size", ]
  expect_equal(type_row$status, "fail")

  after <- fig_check(make_plot() + theme_journal("plos_one"), "plos_one")
  expect_equal(after[after$check == "Type size", ]$status, "pass")
})

test_that("a requirement the publisher does not state is never a pass", {
  r <- fig_check(make_plot(), "frontiers")
  # The harvest notes record Frontiers' file-size rule as confirmed absent.
  expect_equal(r[r$check == "File size", ]$status, "unspecified")
  # Height is different: Frontiers says figures should be no longer than one
  # page but gives no measurement, and nobody has resolved that into a number.
  # Claiming the publisher states nothing would be an assumption, so this
  # reports as unharvested rather than unspecified.
  expect_equal(r[r$check == "Height", ]$status, "unknown")
  expect_false(any(r$status == "unspecified" & r$requirement != "not specified by publisher"))
})

test_that("a requirement we cannot measure is unknown, not a pass", {
  r <- fig_check(make_plot(), "plos_one")
  expect_equal(r[r$check == "Resolution", ]$status, "unknown")
  expect_true(all(r$status %in% c("pass", "fail", "unspecified", "unknown")))
})

test_that("widths are checked against the journal's own columns", {
  p <- make_plot()
  ok <- fig_check(p, "cell_press", column = "single")
  expect_equal(ok[ok$check == "Width", ]$status, "pass")
  bad <- fig_check(p, "cell_press", width = 200, units = "mm")
  expect_equal(bad[bad$check == "Width", ]$status, "fail")
})

test_that("subsetting a report yields a plain data frame", {
  r <- fig_check(make_plot(), "frontiers")
  sub <- r[, c("check", "status")]
  expect_s3_class(sub, "data.frame")
  expect_false(inherits(sub, "figspec_report"))
  expect_null(attr(sub, "source_url"))
})

test_that("fig_check rejects inputs it cannot handle", {
  expect_error(fig_check(42, "frontiers"), "ggplot object or a path")
  expect_error(fig_check("no/such/file.tiff", "frontiers"), "File not found")
})

test_that("an unmeasurable width is unknown, never a failure", {
  path <- withr::local_tempfile(fileext = ".png")
  # Base R's png() does not record resolution in the file.
  grDevices::png(path, width = 85, height = 60, units = "mm", res = 300)
  plot(mtcars$wt, mtcars$mpg)
  grDevices::dev.off()

  r <- fig_check(path, "plos_one")
  expect_equal(r[r$check == "Width", ]$status, "unknown")
  expect_false(any(r$status == "fail" & r$check == "Width"))
})

test_that("supplying the resolution makes an unrecorded file measurable", {
  path <- withr::local_tempfile(fileext = ".png")
  grDevices::png(path, width = 85, height = 60, units = "mm", res = 300)
  plot(mtcars$wt, mtcars$mpg)
  grDevices::dev.off()

  r <- fig_check(path, "plos_one", dpi = 300)
  expect_equal(r[r$check == "Width", ]$status, "pass")
  expect_equal(r[r$check == "Resolution", ]$status, "pass")
})

test_that("resolution is judged against the rule for the stated art type", {
  path <- withr::local_tempfile(fileext = ".png")
  grDevices::png(path, width = 85, height = 60, units = "mm", res = 300)
  plot(mtcars$wt, mtcars$mpg)
  grDevices::dev.off()

  # Cell Press states 300 dpi for colour, 500 for black and white and 1000 for
  # line art. 300 dpi passes as colour art and fails as line art.
  expect_equal(fig_check(path, "cell_press", dpi = 300)[
    fig_check(path, "cell_press", dpi = 300)$check == "Resolution", ]$status, "pass")
  expect_equal(fig_check(path, "cell_press", dpi = 300, art_type = "line")[
    fig_check(path, "cell_press", dpi = 300, art_type = "line")$check == "Resolution", ]$status, "fail")
})

test_that("the other stated resolution thresholds are named, not hidden", {
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  r <- fig_check(p, "cell_press", dpi = 300)
  expect_match(r[r$check == "Resolution", ]$requirement, "line art 1000")
})

# The JPEG reader -------------------------------------------------------------
#
# JPEG is the trickiest raster format here to walk: a chain of segments where
# the dimensions live in a start-of-frame marker whose code varies, and the
# resolution in an optional JFIF header that may say it has no resolution at
# all. Both of those were read wrongly before these tests existed.

jpeg_fixture <- function(width, height, res = NA) {
  f <- tempfile(fileext = ".jpg")
  if (is.na(res)) {
    grDevices::jpeg(f, width = width, height = height, units = "px")
  } else {
    grDevices::jpeg(f, width = width, height = height, units = "px", res = res)
  }
  print(ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point())
  grDevices::dev.off()
  f
}

test_that("a JPEG gives up its dimensions the right way round", {
  # The frame header stores height before width. Reading them in the other
  # order returned the width as the height and a component count as the width.
  skip_if_not_installed("ggplot2")
  f <- jpeg_fixture(600, 400); on.exit(unlink(f))
  info <- read_jpeg_info(f)
  expect_equal(info$width_px, 600)
  expect_equal(info$height_px, 400)
})

test_that("a non-square JPEG is not read square", {
  skip_if_not_installed("ggplot2")
  f <- jpeg_fixture(320, 240); on.exit(unlink(f))
  info <- read_jpeg_info(f)
  expect_equal(info$width_px, 320)
  expect_equal(info$height_px, 240)
  expect_false(info$width_px == info$height_px)
})

test_that("a JFIF density with no units is not reported as a resolution", {
  # Units 0 means the density pair is an aspect ratio and carries no physical
  # size. R's own jpeg() device writes exactly that, with the numbers 72 and
  # 72, so treating it as dpi reported 72 dpi as a fact and failed the figure
  # against every journal asking for 300.
  skip_if_not_installed("ggplot2")
  f <- jpeg_fixture(600, 400); on.exit(unlink(f))
  expect_null(read_jpeg_info(f)$dpi)
})

test_that("a file that is not a JPEG is refused rather than misread", {
  f <- tempfile(fileext = ".jpeg"); on.exit(unlink(f))
  writeBin(charToRaw("this is plainly not a jpeg"), f)
  expect_null(read_jpeg_info(f))
})

test_that("a JPEG with no recorded resolution is unknown, not assumed", {
  skip_if_not_installed("ggplot2")
  f <- jpeg_fixture(1004, 709); on.exit(unlink(f))
  r <- fig_check(f, "frontiers")
  expect_equal(r$status[r$check == "Resolution"], "unknown")
  expect_false(r$status[r$check == "Resolution"] == "fail")
})

test_that("a JPEG resolution given by the caller is used", {
  # Because the file records none, dpi has to be supplied for the geometry to
  # mean anything - which is what the dpi argument is for.
  skip_if_not_installed("ggplot2")
  f <- jpeg_fixture(1004, 709); on.exit(unlink(f))
  r <- fig_check(f, "frontiers", dpi = 300)
  expect_equal(r$status[r$check == "Resolution"], "pass")
  expect_equal(r$status[r$check == "Width"], "pass")
})

test_that("a JPEG is judged against the format list, not assumed acceptable", {
  skip_if_not_installed("ggplot2")
  f <- jpeg_fixture(400, 300); on.exit(unlink(f))
  # PLOS ONE accepts TIFF and EPS only.
  r <- fig_check(f, "plos_one", dpi = 300)
  expect_equal(r$status[r$check == "File format"], "fail")
})

# Resolution round-tripping ---------------------------------------------------

test_that("a resolution meets a requirement it equals", {
  expect_true(meets_dpi(300, 300))
  expect_true(meets_dpi(600, 300))
  expect_false(meets_dpi(299, 300))
  expect_false(meets_dpi(150, 300))
})

test_that("a resolution is not failed by the file format's own rounding", {
  # PNG stores pixels per metre as an integer. 300 dpi is 11811.02 of them,
  # stored as 11811, which reads back as 299.9994 dpi.
  expect_true(meets_dpi(299.9994, 300))
  expect_true(meets_dpi(600 - 0.0006, 600))
})

test_that("a figure figspec saved at the requirement passes its own check", {
  # The round trip that matters: fig_save() writes at the journal's minimum,
  # fig_check() reads the file back, and the two must agree. They did not,
  # because the stored resolution comes back a fraction short of what was
  # asked for and the comparison was exact.
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("ragg")
  out <- tempfile(fileext = ".png"); on.exit(unlink(out))
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  suppressWarnings(suppressMessages(
    fig_save(out, p, journal = "cell_press", column = "single", check = FALSE)))

  r <- fig_check(out, "cell_press", column = "single")
  expect_equal(r$status[r$check == "Resolution"], "pass")
  expect_equal(r$status[r$check == "Width"], "pass")
})

test_that("the reported resolution and the verdict agree", {
  # The visible absurdity of the bug: the row read "300 dpi" and "fail" at the
  # same time, because the number shown was rounded and the test was not.
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("ragg")
  out <- tempfile(fileext = ".png"); on.exit(unlink(out))
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  suppressWarnings(suppressMessages(
    fig_save(out, p, journal = "frontiers", column = "single", check = FALSE)))
  r <- fig_check(out, "frontiers", column = "single")
  row <- r[r$check == "Resolution", ]
  shown <- as.numeric(sub(" dpi$", "", row$actual))
  expect_equal(row$status == "pass", shown >= 300)
})

# Unreadable files ------------------------------------------------------------

test_that("a file that cannot be read says so", {
  f <- tempfile(fileext = ".png"); on.exit(unlink(f))
  set.seed(1); writeBin(as.raw(sample(0:255, 3000, TRUE)), f)
  expect_warning(fig_check(f, "cell_press"), class = "figspec_unreadable_file")
})

test_that("a readable file is not accused of being unreadable", {
  skip_if_not_installed("ggplot2")
  f <- tempfile(fileext = ".png"); on.exit(unlink(f))
  grDevices::png(f, width = 800, height = 600)
  print(ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point())
  grDevices::dev.off()
  expect_no_warning(fig_check(f, "cell_press"))
})

test_that("a vector format with no dimensions to read is left alone", {
  # EPS and SVG carry no page box for figspec to find, so silence there is
  # normal rather than a sign of corruption.
  f <- tempfile(fileext = ".eps"); on.exit(unlink(f))
  writeLines("%!PS-Adobe-3.0 EPSF-3.0", f)
  expect_no_warning(fig_check(f, "cell_press"))
})

test_that("an unreadable file still reports what is knowable about it", {
  f <- tempfile(fileext = ".png"); on.exit(unlink(f))
  set.seed(1); writeBin(as.raw(sample(0:255, 3000, TRUE)), f)
  r <- suppressWarnings(fig_check(f, "cell_press"))
  # Format and size come from the file system, not from reading the image.
  expect_equal(r$status[r$check == "File format"], "fail")
  expect_equal(r$status[r$check == "File size"], "pass")
  # Nothing that depends on reading the image may be graded.
  expect_equal(r$status[r$check == "Width"], "unknown")
  expect_equal(r$status[r$check == "Resolution"], "unknown")
})
