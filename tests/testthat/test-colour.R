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
