scatter <- function(cols = NULL) {
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) +
    ggplot2::geom_point()
  if (!is.null(cols)) p <- p + ggplot2::scale_colour_manual(values = cols)
  p
}

# Okabe-Ito: designed to stay separable under colour vision deficiency.
SAFE <- c("#000000", "#0072B2", "#E69F00")

test_that("data colours are read from the built plot", {
  cols <- plot_colours(scatter(SAFE))
  expect_setequal(cols, SAFE)
})

test_that("a fill the layer never draws is not counted as a figure colour", {
  p <- scatter(SAFE) +
    ggplot2::geom_smooth(se = FALSE, method = "lm", formula = y ~ x)
  # geom_smooth keeps a ribbon fill in the built data even when se = FALSE.
  expect_false("#999999FF" %in% plot_colours(p))
  expect_setequal(plot_colours(p), SAFE)
})

test_that("red and green together fails a journal that forbids it", {
  # Cell Press states red and green should not be used together, and
  # ggplot2's default three-colour palette is red, green and blue.
  r <- check_colour_safety(scatter(), "cell_press")
  expect_equal(r[r$check == "Colour pairs", ]$status, "fail")
})

test_that("a palette without a red/green pairing passes", {
  r <- check_colour_safety(scatter(SAFE), "cell_press")
  expect_equal(r[r$check == "Colour pairs", ]$status, "pass")
})

test_that("red/green is unspecified for a journal that does not state it", {
  r <- check_colour_safety(scatter(), "frontiers")
  expect_equal(r[r$check == "Colour pairs", ]$status, "unspecified")
})

test_that("greyscale merging fails a journal that prints in black and white", {
  # Three hues at deliberately similar lightness.
  same_light <- c("#D55E00", "#009E73", "#0072B2")
  r <- check_colour_safety(scatter(same_light), "royal_society")
  expect_true(r[r$check == "Greyscale", ]$status %in% c("pass", "fail"))

  merged <- check_colour_safety(scatter(c("#777777", "#7A7A7A", "#757575")),
                                "royal_society")
  expect_equal(merged[merged$check == "Greyscale", ]$status, "fail")
})

test_that("greyscale is only a requirement where the publisher states it", {
  r <- check_colour_safety(scatter(c("#777777", "#7A7A7A", "#757575")), "frontiers")
  expect_equal(r[r$check == "Greyscale", ]$status, "unspecified")
})

test_that("colour vision deficiency is reported but never as a requirement", {
  skip_if_not_installed("colorspace")
  r <- check_colour_safety(scatter(SAFE), "cell_press")
  row <- r[r$check == "Colour vision", ]
  expect_equal(row$status, "unspecified")
  expect_match(row$actual, "separable under")
})

test_that("colour checks refuse a saved file rather than guessing", {
  expect_error(check_colour_safety("fig.tiff", "cell_press"), "ggplot object")
})

test_that("a recommended series maximum is reported but never graded", {
  many <- data.frame(x = rep(1:5, 10), y = rep(1:10, each = 5),
                     g = factor(rep(LETTERS[1:10], each = 5)))
  p <- ggplot2::ggplot(many, ggplot2::aes(x, y, colour = g)) + ggplot2::geom_line()

  # Sage recommends no more than 7 series. Ten exceeds it, but "recommend" is
  # not "require", so this must never be a failure.
  r <- check_journal(p, "sage")
  row <- r[r$check == "Series count", ]
  expect_equal(row$status, "unspecified")
  expect_match(row$actual, "10 series, above the 7 recommended")
  expect_match(row$requirement, "not required")

  few <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) +
    ggplot2::geom_point()
  expect_match(check_journal(few, "sage")[
    check_journal(few, "sage")$check == "Series count", ]$actual, "within the 7")
})

test_that("series count is not reported where no publisher names a limit", {
  # A bare count is a measurement, not a finding. Every other advisory row
  # reports something the reader can act on; this one would not.
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) +
    ggplot2::geom_point()
  expect_false("Series count" %in% check_journal(p, "plos_one")$check)
  expect_true("Series count" %in% check_journal(p, "sage")$check)
})

test_that("too many series still surfaces where no limit is stated", {
  skip_if_not_installed("colorspace")
  many <- data.frame(x = rep(1:5, 12), y = rep(1:12, each = 5),
                     g = factor(rep(LETTERS[1:12], each = 5)))
  p <- ggplot2::ggplot(many, ggplot2::aes(x, y, colour = g)) + ggplot2::geom_line()
  # PLOS ONE names no series limit, but an over-crowded figure still shows up
  # through colours that stop being separable.
  r <- check_colour_safety(p, "plos_one")
  expect_match(r[r$check == "Greyscale", ]$actual, "merge in greyscale")
  expect_match(r[r$check == "Colour vision", ]$actual, "merge under")
})

test_that("an ungrouped plot raises no series check", {
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  expect_false("Series count" %in% check_journal(p, "sage")$check)
})

test_that("Sage's stated rules are recorded and its loose ones are not", {
  s <- journal_spec("sage")
  expect_equal(s$dpi_min, 300)
  expect_equal(s$dpi_line_art, 800)
  expect_true(isTRUE(s$print_greyscale))
  # "sans serif is usually the default" is too loose to be a font list.
  expect_null(s$font_families)
  # Sage gives no dimensions, only "match or exceed the dimensions of the journal".
  expect_null(s$columns)
  expect_true("columns" %in% unlist(s$not_stated))
})

test_that("a long list of merged pairs is summarised, not dumped", {
  many <- data.frame(x = rep(1:5, 12), y = rep(1:12, each = 5),
                     g = factor(rep(LETTERS[1:12], each = 5)))
  p <- ggplot2::ggplot(many, ggplot2::aes(x, y, colour = g)) + ggplot2::geom_line()
  r <- check_colour_safety(p, "royal_society")
  msg <- r[r$check == "Greyscale", ]$actual
  expect_match(msg, "^\\d+ pair\\(s\\) merge in greyscale")
  expect_match(msg, "more$")
  expect_lt(nchar(msg), 160)
})

test_that("a short list of merged pairs is shown in full", {
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) +
    ggplot2::geom_point()
  msg <- check_colour_safety(p, "royal_society")[
    check_colour_safety(p, "royal_society")$check == "Greyscale", ]$actual
  expect_false(grepl("more$", msg))
})

test_that("the American spelling reaches the same function", {
  expect_identical(check_color_safety, check_colour_safety)
  expect_identical(scale_color_figspec, scale_colour_figspec)
})

test_that("colour arguments answer to the American spelling", {
  # `color` is an unambiguous prefix of `colour`, so R's partial matching
  # carries it through. This is worth a test because adding another argument
  # starting "colo" would silently break it.
  skip_if_not_installed("ggplot2")
  expect_no_error(fit_journal("plos_one", color = FALSE))
  expect_equal(
    length(fit_journal("plos_one", color = FALSE)),
    length(fit_journal("plos_one", colour = FALSE))
  )
})
