# Hostile and degenerate input.
#
# These are not the cases anyone means to produce. They are the ones that arrive
# anyway: a plot built before the data loaded, a figure written to a directory
# the user cannot write to, a path from a non-English filesystem, a facet
# variable with far more levels than expected.
#
# The standard applied throughout is that figspec must either answer or refuse.
# What it must never do is take the R session down, invent a measurement, or
# report success for something that did not happen.

hostile_plots <- function() {
  list(
    empty = ggplot2::ggplot(),
    no_aes = ggplot2::ggplot(mtcars) + ggplot2::geom_blank(),
    one_point = ggplot2::ggplot(mtcars[1, ], ggplot2::aes(wt, mpg)) +
      ggplot2::geom_point(),
    zero_rows = ggplot2::ggplot(mtcars[0, ], ggplot2::aes(wt, mpg)) +
      ggplot2::geom_point(),
    all_na = ggplot2::ggplot(data.frame(x = NA_real_, y = NA_real_),
                             ggplot2::aes(x, y)) + ggplot2::geom_point(),
    unicode = ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
      ggplot2::geom_point() +
      ggplot2::labs(title = "中文 éè مرحبا")
  )
}

test_that("no degenerate plot brings down a check", {
  skip_if_not_installed("ggplot2")
  for (nm in names(hostile_plots())) {
    r <- suppressWarnings(fig_check(hostile_plots()[[nm]], "cell_press"))
    expect_s3_class(r, "figspec_report")
    expect_gt(nrow(r), 0)
  }
})

test_that("a plot with nothing in it is never reported as meeting a rule it cannot", {
  skip_if_not_installed("ggplot2")
  r <- suppressWarnings(fig_check(ggplot2::ggplot(), "cell_press"))
  # An empty plot has no data colours, so no colour rule can be graded on it.
  colour_rows <- r[grepl("Colour pairs|Greyscale", r$check), ]
  expect_false(any(colour_rows$status == "pass"))
})

test_that("labels outside the Latin alphabet are handled, not mangled", {
  skip_if_not_installed("ggplot2")
  r <- suppressWarnings(fig_check(hostile_plots()$unicode, "cell_press"))
  expect_s3_class(r, "figspec_report")
  expect_true(any(r$status %in% c("pass", "fail")))
})

test_that("a great many panels is a number, not a failure to count", {
  skip_if_not_installed("ggplot2")
  d <- data.frame(x = rnorm(600), y = rnorm(600),
                  f = rep(paste0("p", seq_len(200)), each = 3))
  p <- ggplot2::ggplot(d, ggplot2::aes(x, y)) + ggplot2::geom_point() +
    ggplot2::facet_wrap(~f)
  expect_equal(count_parts(p), 200)
  r <- suppressWarnings(fig_check(p, "cell_press"))
  expect_s3_class(r, "figspec_report")
})

# Where files land ------------------------------------------------------------

test_that("a path containing spaces is saved to and read back", {
  skip_if_not_installed("ggplot2")
  d <- file.path(withr::local_tempdir(), "dir with spaces")
  dir.create(d, recursive = TRUE)
  out <- file.path(d, "my figure.png")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  suppressMessages(fig_save(out, p, width = 85, height = 60, units = "mm",
                            check = FALSE))
  expect_true(file.exists(out))
  expect_equal(inspect_file(out)$width_mm, 85, tolerance = 0.5)
})

test_that("a path outside the Latin alphabet is saved to and read back", {
  skip_if_not_installed("ggplot2")
  d <- file.path(withr::local_tempdir(), "dossier-éàü-中文")
  dir.create(d, recursive = TRUE)
  out <- file.path(d, "figüre-中.png")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  suppressMessages(fig_save(out, p, width = 85, height = 60, units = "mm",
                            check = FALSE))
  expect_true(file.exists(out))
  expect_s3_class(fig_check(out, "frontiers"), "figspec_report")
})

test_that("a write that cannot happen is an error, not a warning and no file", {
  # The failure mode that matters: returning quietly having written nothing
  # would leave an author submitting a figure that does not exist.
  skip_if_not_installed("ggplot2")
  skip_on_os("windows")
  d <- file.path(withr::local_tempdir(), "readonly")
  dir.create(d)
  Sys.chmod(d, "0555")
  on.exit(Sys.chmod(d, "0755"), add = TRUE)
  out <- file.path(d, "f.png")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()

  expect_error(
    suppressWarnings(fig_save(out, p, width = 85, height = 60, units = "mm",
                              check = FALSE)),
    class = "figspec_error"
  )
  expect_false(file.exists(out))
})

test_that("a directory that does not exist is refused rather than created", {
  skip_if_not_installed("ggplot2")
  out <- file.path(withr::local_tempdir(), "no", "such", "place", "f.png")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  expect_error(suppressWarnings(
    fig_save(out, p, width = 85, height = 60, units = "mm", check = FALSE)))
  expect_false(file.exists(out))
})

# Sizes that would take the session down --------------------------------------

test_that("no size a graphics device would abort on ever reaches one", {
  skip_if_not_installed("ggplot2")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  out <- tempfile(fileext = ".png"); on.exit(unlink(out))
  for (bad in list(0, -5, NA_real_, Inf, -Inf, NaN)) {
    expect_error(fig_save(out, p, width = bad, height = 50, units = "mm",
                          check = FALSE),
                 class = "figspec_bad_size")
    expect_error(fig_save(out, p, width = 85, height = bad, units = "mm",
                          check = FALSE),
                 class = "figspec_bad_size")
  }
})

test_that("no resolution a device would abort on ever reaches one", {
  skip_if_not_installed("ggplot2")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  out <- tempfile(fileext = ".png"); on.exit(unlink(out))
  for (bad in list(0, -300, NA_real_, Inf)) {
    expect_error(fig_save(out, p, width = 85, height = 60, units = "mm",
                          dpi = bad, check = FALSE),
                 class = "figspec_bad_size")
  }
})

test_that("a panel that cannot fit its canvas is refused, naming both", {
  skip_if_not_installed("ggplot2")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  out <- tempfile(fileext = ".png"); on.exit(unlink(out))
  err <- tryCatch(
    fig_save(out, p, width = 50, height = 50, units = "mm",
             panel_width = 200, check = FALSE),
    error = function(e) e)
  expect_s3_class(err, "figspec_size_conflict")
  expect_match(conditionMessage(err), "200")
})

# Files that are not what they claim ------------------------------------------

corrupt_file <- function(ext, bytes = NULL) {
  f <- tempfile(fileext = ext)
  if (is.null(bytes)) { set.seed(1); bytes <- as.raw(sample(0:255, 2000, TRUE)) }
  writeBin(bytes, f)
  f
}

test_that("no header reader claims a measurement from bytes it cannot read", {
  for (ext in c(".png", ".tiff", ".jpg", ".pdf")) {
    info <- inspect_file(corrupt_file(ext))
    measured <- info[setdiff(names(info), c("format", "size_mb"))]
    expect_length(measured, 0)
  }
})

test_that("an empty file is read as empty rather than as anything", {
  for (ext in c(".png", ".tiff", ".jpg", ".pdf")) {
    info <- inspect_file(corrupt_file(ext, raw(0)))
    expect_length(info[setdiff(names(info), c("format", "size_mb"))], 0)
  }
})

test_that("a truncated but valid header yields nothing rather than half a size", {
  png_sig <- as.raw(c(137, 80, 78, 71, 13, 10, 26, 10))
  expect_length(read_png_info(corrupt_file(".png", png_sig)), 0)
  expect_null(read_tiff_info(corrupt_file(".tiff", charToRaw("II"))))
  expect_null(read_jpeg_info(corrupt_file(".jpg", as.raw(c(255, 216)))))
})

test_that("an extension that lies about the contents is not believed", {
  png_sig <- as.raw(c(137, 80, 78, 71, 13, 10, 26, 10))
  for (ext in c(".tiff", ".jpg")) {
    info <- inspect_file(corrupt_file(ext, png_sig))
    expect_length(info[setdiff(names(info), c("format", "size_mb"))], 0)
  }
})
