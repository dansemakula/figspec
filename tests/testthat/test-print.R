# Printed reports have to fit the console they are printed into. cli's alerts
# do not wrap, so long requirement text used to run off the side of the screen
# and off the side of a rendered vignette.

test_that("a row that fits stays on one line with its columns aligned", {
  r <- report_row("Width", "85 mm", "single 85 mm", width = 80, lab_w = 12)
  expect_length(r$rest, 0)
  expect_match(r$head, "^Width +85 mm +requires: single 85 mm$")
})

test_that("a row that does not fit carries its requirement underneath", {
  long <- "min 300 dpi for colour; also states black and white 500, line art 1000 dpi"
  r <- report_row("Resolution", "could not determine", long, width = 80, lab_w = 12)
  expect_gt(length(r$rest), 0)
  expect_true(all(nchar(c(r$head, r$rest)) + 2L <= 80L))
  expect_match(r$rest[1], "^ +requires: ")
})

test_that("continuation lines align under the actual column", {
  r <- report_row("Resolution", "could not determine",
                  strrep("word ", 30), width = 80, lab_w = 12)
  indent <- nchar(sub("[^ ].*$", "", r$rest[1]))
  expect_equal(indent, 2L + 12L + 1L)
})

test_that("an actual value too long for the line is wrapped too", {
  actual <- "3 pair(s) merge in greyscale: #00BA38/#F8766D, #00BA38/#619CFF, #F8766D/#619CFF"
  r <- report_row("Greyscale", actual, "not specified by publisher",
                  width = 80, lab_w = 12)
  expect_true(all(nchar(c(r$head, r$rest)) + 2L <= 80L))
  expect_match(paste(c(r$head, r$rest), collapse = " "), "#F8766D/#619CFF", fixed = TRUE)
})

test_that("a narrow console still produces something printable", {
  r <- report_row("Type size", "smallest 8.8 pt, largest 13.2 pt",
                  "min 6 pt, max 8 pt", width = 50, lab_w = 12)
  expect_true(all(nchar(c(r$head, r$rest)) > 0))
})

test_that("no printed report line exceeds the console width, URLs aside", {
  skip_if_not_installed("ggplot2")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) +
    ggplot2::geom_point() +
    ggplot2::labs(title = "Fuel economy", colour = "Cylinders")
  withr::with_options(list(width = 80, cli.width = 80), {
    for (j in journals()$id) {
      out <- capture.output(print(fig_check(p, j)), type = "message")
      # A bare URL is one unbreakable token; wrapping it would break the link.
      out <- out[!grepl("https?://", out)]
      expect_true(all(nchar(out) <= 80),
                  info = paste(j, ":", paste(out[nchar(out) > 80], collapse = " | ")))
    }
  })
})

test_that("braces in registry text are not read as cli templates", {
  # cli_alert_*(x) treats x as a glue template, so a brace in the data would
  # be evaluated. The report passes its text as a value instead.
  r <- report_row("Font", "could not determine", "Arial {or} Helvetica",
                  width = 200, lab_w = 12)
  expect_no_error(cli::cli_alert_info("{r$head}"))
})

test_that("long prose alerts wrap instead of running off the screen", {
  withr::with_options(list(width = 60, cli.width = 60), {
    out <- capture.output(
      alert_wrap(strrep("sentence ", 30), "info"), type = "message")
    expect_gt(length(out), 1)
    expect_true(all(nchar(out) <= 60))
  })
})

test_that("messages fold to the console width", {
  withr::with_options(list(width = 60), {
    out <- capture.output(
      msg_wrap("A sentence ", strrep("long enough to need folding ", 6)),
      type = "message")
    expect_gt(length(out), 1)
    expect_true(all(nchar(out) <= 60))
  })
})
