make_files <- function(dir, journal, n = 2) {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point() + theme_journal(journal)
  for (i in seq_len(n)) {
    suppressWarnings(suppressMessages(
      ggsave_journal(file.path(dir, sprintf("figure_%d.tiff", i)), p,
                     journal, check = FALSE)
    ))
  }
  dir
}

test_that("a whole directory is checked, one row per figure", {
  skip_if_not_installed("ragg")
  dir <- make_files(withr::local_tempdir(), "frontiers", n = 3)
  res <- check_submission(dir, "frontiers")
  expect_s3_class(res, "figspec_submission")
  expect_equal(nrow(res), 3)
  expect_true(all(res$result %in% c("pass", "pass, with gaps")))
})

test_that("per-file detail is retrievable", {
  skip_if_not_installed("ragg")
  dir <- make_files(withr::local_tempdir(), "frontiers", n = 1)
  res <- check_submission(dir, "frontiers")
  detail <- submission_detail(res, "figure_1.tiff")
  expect_s3_class(detail, "figspec_report")
  expect_error(submission_detail(res, "nope.tiff"), "No report")
})

test_that("column can be set per file", {
  skip_if_not_installed("ragg")
  dir <- make_files(withr::local_tempdir(), "frontiers", n = 2)
  res <- check_submission(dir, "frontiers",
                          column = c(figure_1.tiff = "single",
                                     figure_2.tiff = "double"))
  expect_equal(res$column, c("single", "double"))
})

test_that("an empty or missing target is an error, not a silent pass", {
  expect_error(check_submission(withr::local_tempdir(), "frontiers"), "No figure files")
  expect_error(check_submission("nope/fig.tiff", "frontiers"), "not found")
})

test_that("subsetting a submission yields a plain data frame", {
  skip_if_not_installed("ragg")
  dir <- make_files(withr::local_tempdir(), "frontiers", n = 1)
  res <- check_submission(dir, "frontiers")
  expect_false(inherits(res[, c("file", "result")], "figspec_submission"))
})
