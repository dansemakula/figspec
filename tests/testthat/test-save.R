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

test_that("column and width cannot both set the canvas", {
  # Both name the same dimension, so honouring one silently would mean
  # ignoring an instruction the caller gave explicitly.
  skip_if_not_installed("ggplot2")
  out <- tempfile(fileext = ".png"); on.exit(unlink(out))
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  err <- tryCatch(
    fig_save(out, p, journal = "frontiers", column = "single", width = 120),
    error = function(e) e)
  expect_s3_class(err, "figspec_error")
  expect_match(conditionMessage(err), "120")
})

test_that("a specification stating no resolution gets a default that is announced", {
  # A working number has to come from somewhere, but it must never be passed
  # off as the journal's requirement.
  skip_if_not_installed("ggplot2")
  out <- tempfile(fileext = ".png"); on.exit(unlink(out))
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  msg <- capture.output(
    suppressWarnings(fig_save(out, p, journal = list(name = "House", columns = list(single = 85)),
                              check = FALSE)),
    type = "message")
  expect_match(paste(msg, collapse = " "), "not a requirement")
})

# Font-failure recovery -------------------------------------------------------
#
# Some vector devices can only use the fonts R itself knows about. Handed a
# system font they cannot resolve, they raise "invalid font type" rather than
# falling back. fig_save() catches that, writes the figure in the default face
# and warns, because a figure that never arrives is worse than one whose
# typeface is wrong - but a silent substitution is how a paper comes back from
# production in the wrong font.
#
# Whether the error fires depends on the machine: where cairo is available the
# device resolves system fonts and there is nothing to recover from. The tests
# below assert the contract in both cases and note which one they took.

unresolvable_font_plot <- function() {
  ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point() +
    ggplot2::theme_grey(base_family = "NoSuchFontAtAll")
}

capture_warnings <- function(expr) {
  w <- character()
  withCallingHandlers(expr,
    warning = function(x) { w <<- c(w, conditionMessage(x)); invokeRestart("muffleWarning") })
  w
}

test_that("a font the device cannot resolve still produces a file", {
  skip_if_not_installed("ggplot2")
  out <- tempfile(fileext = ".pdf"); on.exit(unlink(out))
  capture_warnings(fig_save(out, unresolvable_font_plot(),
                            width = 85, height = 60, units = "mm", check = FALSE))
  expect_true(file.exists(out))
  expect_gt(file.size(out), 0)
})

test_that("the substitution is announced rather than made silently", {
  skip_if_not_installed("ggplot2")
  out <- tempfile(fileext = ".pdf"); on.exit(unlink(out))
  w <- capture_warnings(fig_save(out, unresolvable_font_plot(),
                                 width = 85, height = 60, units = "mm", check = FALSE))
  own <- grep("cannot render the font|default font", w, value = TRUE)
  skip_if(length(own) == 0,
          "this device resolves system fonts, so there is nothing to recover from")
  expect_match(own[1], "NoSuchFontAtAll")
  expect_match(own[1], "default font")
  # The warning has to be actionable, not just an apology.
  expect_match(own[1], "TIFF|PNG|install")
})

test_that("the recovered file is still the size that was asked for", {
  # The retry re-solves the geometry, so a figure saved through the recovery
  # path must not come out at some other width.
  skip_if_not_installed("ggplot2")
  out <- tempfile(fileext = ".pdf"); on.exit(unlink(out))
  capture_warnings(fig_save(out, unresolvable_font_plot(),
                            width = 85, height = 60, units = "mm", check = FALSE))
  info <- inspect_file(out)
  expect_equal(info$width_mm, 85, tolerance = 0.5)
  expect_equal(info$height_mm, 60, tolerance = 0.5)
})

test_that("an error that is not about fonts is not swallowed", {
  # The recovery matches on the font messages only. Any other failure has to
  # reach the caller rather than being retried and hidden.
  skip_if_not_installed("ggplot2")
  out <- file.path(tempfile(), "no", "such", "directory", "f.png")
  expect_error(
    suppressWarnings(fig_save(out, unresolvable_font_plot(),
                              width = 85, height = 60, units = "mm", check = FALSE))
  )
})
