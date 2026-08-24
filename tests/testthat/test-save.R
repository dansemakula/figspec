# fig_save(): format selection, device choice, and the check performed on the
# file after it is written.

plot_for_save <- function(journal) {
  ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point() +
    theme_journal(journal)
}

test_that("a saved TIFF comes back at the journal's width and resolution", {
  skip_if_not_installed("ragg")
  path <- withr::local_tempfile(fileext = ".tiff")
  suppressWarnings(fig_save(path, plot_for_save("plos_one"), journal = "plos_one",
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
  suppressWarnings(fig_save(path, plot_for_save("frontiers"), journal = "frontiers",
                                  column = "double", check = FALSE))
  r <- fig_check(path, "frontiers", column = "double")
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
    fig_save(path, plot_for_save("plos_one"), journal = "plos_one", check = FALSE),
    "accepted formats"
  )
})

test_that("a missing extension takes the journal's first accepted format", {
  skip_if_not_installed("ragg")
  dir <- withr::local_tempdir()
  stem <- file.path(dir, "figure_1")
  suppressWarnings(fig_save(stem, plot_for_save("plos_one"), journal = "plos_one",
                                  check = FALSE))
  expect_true(file.exists(paste0(stem, ".tiff")))
})

test_that("a height beyond the journal maximum warns", {
  skip_if_not_installed("ragg")
  path <- withr::local_tempfile(fileext = ".tiff")
  expect_warning(
    fig_save(path, plot_for_save("plos_one"), journal = "plos_one",
                   height = 300, units = "mm", check = FALSE),
    "exceeds"
  )
})

test_that("vector formats are reported as resolution independent", {
  path <- withr::local_tempfile(fileext = ".pdf")
  ggplot2::ggsave(path, ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
                    ggplot2::geom_point(), width = 85, height = 60, units = "mm")
  r <- fig_check(path, "cell_press", column = "single")
  expect_equal(r[r$check == "Resolution", ]$status, "pass")
  expect_equal(r[r$check == "Width", ]$status, "pass")
})

test_that("a default format is one R can actually write", {
  # Nature lists .ai first, which is Adobe Illustrator. R has no device for it,
  # so taking the first listed format produced "Unknown graphics device".
  fmts <- tolower(unlist(journal_spec("nature")$formats))
  expect_equal(fmts[[1]], "ai")
  expect_equal(default_format(journal_spec("nature")), "eps")

  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  dir <- withr::local_tempdir()
  suppressWarnings(suppressMessages(
    fig_save(file.path(dir, "no_extension"), p, "nature", check = FALSE)
  ))
  expect_true(file.exists(file.path(dir, "no_extension.eps")))
})

test_that("refit_journal picks a writable format too", {
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  dir <- withr::local_tempdir()
  res <- suppressWarnings(suppressMessages(refit_journal(list(fig1 = p), "nature", dir)))
  expect_equal(res$file, "fig1.eps")
})

test_that("a journal listing only unwritable formats fails with a usable message", {
  withr::defer(.figspec_cache$user_journals <- NULL)
  register_journal("only_ai", "Only AI", "handbook", "2026-08-22",
                   requirements = list(columns = list(single = 90),
                                       formats = list("ai", "psd")))
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  expect_error(
    fig_save(file.path(withr::local_tempdir(), "x"), p, "only_ai"),
    "none of which R can write"
  )
})
