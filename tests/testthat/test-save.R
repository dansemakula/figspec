plot_for_save <- function(journal) {
  ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point() +
    theme_journal(journal)
}

test_that("a saved TIFF comes back at the journal's width and resolution", {
  skip_if_not_installed("ragg")
  path <- withr::local_tempfile(fileext = ".tiff")
  suppressWarnings(ggsave_journal(path, plot_for_save("plos_one"), "plos_one",
                                  column = "single", check = FALSE))
  expect_true(file.exists(path))

  info <- inspect_file(path)
  # PLOS ONE states a 66.8 mm minimum width and 300 dpi minimum.
  expect_equal(info$width_mm, 66.8, tolerance = 0.5)
  expect_equal(info$dpi, 300, tolerance = 1)
})

test_that("the saved file passes the checks it is measurable against", {
  skip_if_not_installed("ragg")
  path <- withr::local_tempfile(fileext = ".tiff")
  suppressWarnings(ggsave_journal(path, plot_for_save("frontiers"), "frontiers",
                                  column = "double", check = FALSE))
  r <- check_journal(path, "frontiers", column = "double")
  expect_false(any(r$status == "fail"))
  expect_equal(r[r$check == "Width", ]$status, "pass")
  expect_equal(r[r$check == "Resolution", ]$status, "pass")
  expect_equal(r[r$check == "File format", ]$status, "pass")
})

test_that("saving in a format the journal does not accept warns", {
  skip_if_not_installed("ragg")
  path <- withr::local_tempfile(fileext = ".png")
  # PLOS ONE accepts TIFF or EPS only.
  expect_warning(
    ggsave_journal(path, plot_for_save("plos_one"), "plos_one", check = FALSE),
    "accepted formats"
  )
})

test_that("a missing extension takes the journal's first accepted format", {
  skip_if_not_installed("ragg")
  dir <- withr::local_tempdir()
  stem <- file.path(dir, "figure_1")
  suppressWarnings(ggsave_journal(stem, plot_for_save("plos_one"), "plos_one",
                                  check = FALSE))
  expect_true(file.exists(paste0(stem, ".tiff")))
})

test_that("a height beyond the journal maximum warns", {
  skip_if_not_installed("ragg")
  path <- withr::local_tempfile(fileext = ".tiff")
  expect_warning(
    ggsave_journal(path, plot_for_save("plos_one"), "plos_one",
                   height = 300, units = "mm", check = FALSE),
    "exceeds"
  )
})

test_that("vector formats are reported as resolution independent", {
  path <- withr::local_tempfile(fileext = ".pdf")
  ggplot2::ggsave(path, ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
                    ggplot2::geom_point(), width = 85, height = 60, units = "mm")
  r <- check_journal(path, "cell_press", column = "single")
  expect_equal(r[r$check == "Resolution", ]$status, "pass")
  expect_equal(r[r$check == "Width", ]$status, "pass")
})
