# Re-exporting a set of figures against a different journal's specification.

test_that("a set of plots is re-exported to another journal's spec", {
  skip_if_not_installed("ragg")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  dir <- withr::local_tempdir()
  res <- suppressWarnings(suppressMessages(
    refit_journal(list(figure_1 = p, figure_2 = p), "frontiers", dir, column = "double")
  ))
  expect_equal(nrow(res), 2)
  expect_true(all(file.exists(file.path(dir, c("figure_1.tiff", "figure_2.tiff")))))
  # Frontiers' double column is 180 mm.
  info <- inspect_file(file.path(dir, "figure_1.tiff"))
  expect_equal(info$width_mm, 180, tolerance = 0.5)
})

test_that("refitting saved files is refused rather than faked", {
  dir <- withr::local_tempdir()
  expect_error(
    refit_journal(list(a = "some/file.tiff"), "frontiers", dir),
    "plot objects, not saved files"
  )
})

test_that("refit requires named plots", {
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  expect_error(refit_journal(list(p), "frontiers", withr::local_tempdir()), "named list")
})

test_that("line width converts points to ggplot2 linewidth units", {
  # Frontiers states a two-point minimum. See test-linewidth.R for why the
  # conversion is not simply points to millimetres.
  expect_equal(figspec_linewidth("frontiers"), 2 / (72.27 / 25.4 * 0.75),
               tolerance = 1e-9)
  expect_message(figspec_linewidth("jss"), "no minimum line width")
})
