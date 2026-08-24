# Checking a set of figures together, from plot objects and from files.

make_files <- function(dir, journal, n = 2) {
  dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point() + theme_journal(journal)
  for (i in seq_len(n)) {
    suppressWarnings(suppressMessages(
      fig_save(file.path(dir, sprintf("figure_%d.tiff", i)), p,
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

# The plot-object path, and the printed report -------------------------------
#
# Everything above works from files. Plot objects are the better input, and
# they take a different route: type size and panel geometry survive, so panel
# spread can be reported and the summary records that it came from plots.

plot_set <- function() {
  base <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  list(
    short = base,
    long = ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg * 100000)) +
      ggplot2::geom_point()
  )
}

test_that("a list of plots is checked, one row per figure", {
  skip_if_not_installed("ggplot2")
  res <- suppressMessages(check_submission(plot_set(), "frontiers"))
  expect_s3_class(res, "figspec_submission")
  expect_equal(nrow(res), 2)
  expect_setequal(res$file, c("short", "long"))
})

test_that("panel width is measured for plots and reported as an observation", {
  skip_if_not_installed("ggplot2")
  res <- suppressMessages(check_submission(plot_set(), "frontiers"))
  expect_true("panel_mm" %in% names(res))
  expect_true(all(is.finite(res$panel_mm)))
  # The two figures differ only in the length of their y tick labels, so their
  # panels must differ even though both meet the same width requirement.
  expect_false(isTRUE(all.equal(res$panel_mm[1], res$panel_mm[2])))
})

test_that("differing panel widths are never counted as a failure", {
  # No publisher states a rule about panel consistency, so it can inform but
  # never condemn.
  skip_if_not_installed("ggplot2")
  res <- suppressMessages(check_submission(plot_set(), "frontiers"))
  reports <- attr(res, "reports")
  for (r in reports) {
    expect_false(any(grepl("panel", r$check, ignore.case = TRUE) &
                       r$status == "fail"))
  }
})

test_that("a set can be inspected with no specification at all", {
  skip_if_not_installed("ggplot2")
  res <- suppressMessages(check_submission(plot_set()))
  expect_equal(nrow(res), 2)
  for (r in attr(res, "reports")) {
    expect_false(any(r$status %in% c("pass", "fail")))
  }
})

test_that("the printed report names the journal and every figure", {
  skip_if_not_installed("ggplot2")
  res <- suppressMessages(check_submission(plot_set(), "frontiers"))
  out <- capture.output(print(res), type = "message")
  txt <- paste(out, collapse = " ")
  expect_match(txt, "Frontiers")
  expect_match(txt, "short")
  expect_match(txt, "long")
  expect_match(txt, "2 figures")
})

test_that("the printed report separates panel spread from pass and fail", {
  skip_if_not_installed("ggplot2")
  res <- suppressMessages(check_submission(plot_set(), "frontiers"))
  out <- capture.output(print(res), type = "message")
  txt <- paste(out, collapse = " ")
  expect_match(txt, "panel|plot area")
})

test_that("a report printed without a journal says so rather than naming one", {
  skip_if_not_installed("ggplot2")
  res <- suppressMessages(check_submission(plot_set()))
  out <- capture.output(print(res), type = "message")
  expect_match(paste(out, collapse = " "), "Submission check")
})

test_that("a failing figure is named in the printed report", {
  skip_if_not_installed("ggplot2")
  # Cell Press caps type at 8 pt; ggplot2's default base of 11 pt exceeds it.
  res <- suppressMessages(check_submission(plot_set(), "cell_press"))
  expect_true(any(res$result == "fail"))
  out <- capture.output(print(res), type = "message")
  expect_match(paste(out, collapse = " "), "failed")
})
