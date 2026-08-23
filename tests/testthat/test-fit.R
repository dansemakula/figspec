grouped <- function() {
  ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl),
                                       shape = factor(cyl))) +
    ggplot2::geom_point()
}

test_that("one line builds a figure that meets the journal", {
  fitted <- grouped() + fit_journal("cell_press")
  r <- fig_check(fitted, "cell_press", column = "single")
  expect_equal(nrow(r[r$status == "fail", ]), 0)
  expect_equal(r[r$check == "Type size", ]$status, "pass")
  expect_equal(r[r$check == "Colour pairs", ]$status, "pass")
})

test_that("the palette follows what the journal does to a figure in print", {
  # The Royal Society reproduces figures in black and white by default, so the
  # colours have to stay apart in greyscale.
  grey_journal <- grouped() + fit_journal("royal_society")
  expect_equal(check_colour_safety(grey_journal, "royal_society")[
    check_colour_safety(grey_journal, "royal_society")$check == "Greyscale", ]$status,
    "pass")
  expect_setequal(plot_colours(grey_journal), figspec_palette("cividis", 3))

  # Elsewhere, Okabe-Ito, which is built for colour vision deficiency.
  expect_setequal(plot_colours(grouped() + fit_journal("cell_press")),
                  figspec_palette("okabe_ito", 3))
})

test_that("you can keep your own palette and take everything else", {
  own <- grouped() + ggplot2::scale_colour_grey() +
    fit_journal("cell_press", colour = FALSE)
  expect_false(any(figspec_palette("okabe_ito", 3) %in% plot_colours(own)))
  # The typography still arrives.
  expect_equal(fig_check(own, "cell_press")[
    fig_check(own, "cell_press")$check == "Type size", ]$status, "pass")
})

test_that("it composes onto a plot that maps neither colour nor shape", {
  plain <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  expect_silent(invisible(ggplot2::ggplot_build(plain + fit_journal("frontiers"))))
})

test_that("a house style rides along underneath the journal", {
  withr::defer(.figspec_cache$styles <- NULL)
  register_house_style("mine", ggplot2::theme_minimal() +
                         ggplot2::theme(panel.grid.minor = ggplot2::element_blank()))
  parts <- fit_journal("frontiers", style = "mine")
  th <- Filter(function(x) inherits(x, "theme"), parts)[[1]]
  expect_s3_class(th$panel.grid.minor, "element_blank")
})

test_that("the shape scale hands out shapes that stay legible", {
  p <- grouped() + scale_shape_figspec()
  built <- ggplot2::ggplot_build(p)$data[[1]]
  expect_setequal(unique(built$shape), figspec_shapes(3))
})

test_that("fit_journal returns components a plot can take with +", {
  parts <- fit_journal("plos_one")
  expect_type(parts, "list")
  expect_true(any(vapply(parts, function(x) inherits(x, "theme"), logical(1))))
  expect_true(any(vapply(parts, function(x) inherits(x, "Scale"), logical(1))))
})
