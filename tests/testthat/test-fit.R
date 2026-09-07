# fig_apply_spec(): that one line added to a plot carries the journal's
# typography, scales and structural rules, and composes cleanly.

grouped <- function() {
  ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl),
                                       shape = factor(cyl))) +
    ggplot2::geom_point()
}

test_that("one line builds a figure that meets the journal", {
  fitted <- grouped() + fig_apply_spec("cell_press")
  r <- fig_check(fitted, "cell_press", column = "single")
  expect_equal(nrow(r[r$status == "fail", ]), 0)
  expect_equal(r[r$check == "Type size", ]$status, "pass")
  expect_equal(r[r$check == "Colour pairs", ]$status, "pass")
})

test_that("the palette follows what the journal does to a figure in print", {
  # The Royal Society reproduces figures in black and white by default, so the
  # colours have to stay apart in greyscale.
  grey_journal <- grouped() + fig_apply_spec("royal_society")
  expect_equal(colour_safety_check(grey_journal, "royal_society")[
    colour_safety_check(grey_journal, "royal_society")$check == "Greyscale", ]$status,
    "pass")
  expect_setequal(plot_colours(grey_journal), figspec_palette("cividis", 3))

  # Elsewhere, Okabe-Ito, which is built for colour vision deficiency.
  expect_setequal(plot_colours(grouped() + fig_apply_spec("cell_press")),
                  figspec_palette("okabe_ito", 3))
})

test_that("you can keep your own palette and take everything else", {
  own <- grouped() + ggplot2::scale_colour_grey() +
    fig_apply_spec("cell_press", colour = FALSE)
  expect_false(any(figspec_palette("okabe_ito", 3) %in% plot_colours(own)))
  # The typography still arrives.
  expect_equal(fig_check(own, "cell_press")[
    fig_check(own, "cell_press")$check == "Type size", ]$status, "pass")
})

test_that("a specification's house-style palette reaches ggplot2", {
  report_spec <- list(
    name = "Research report",
    house_style = list(
      palette = c("#76549A", "#D99000", "#2B78A6")
    )
  )
  fitted <- grouped() + fig_apply_spec(report_spec)
  expect_setequal(
    plot_colours(fitted),
    report_spec$house_style$palette
  )
})

test_that("a house-style palette is never silently recycled", {
  short_spec <- list(
    name = "Research report",
    house_style = list(palette = c("#76549A", "#2B78A6"))
  )
  expect_error(
    ggplot2::ggplot_build(grouped() + fig_apply_spec(short_spec)),
    "plot needs 3",
    class = "figspec_unsupported"
  )
})

test_that("it composes onto a plot that maps neither colour nor shape", {
  plain <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  expect_silent(invisible(ggplot2::ggplot_build(plain + fig_apply_spec("frontiers"))))
})

test_that("a house style rides along underneath the journal", {
  withr::defer(.figspec_cache$styles <- NULL)
  style_register("mine", ggplot2::theme_minimal() +
                         ggplot2::theme(panel.grid.minor = ggplot2::element_blank()))
  parts <- fig_apply_spec("frontiers", style = "mine")
  th <- Filter(function(x) inherits(x, "theme"), parts)[[1]]
  expect_s3_class(th$panel.grid.minor, "element_blank")
})

test_that("the shape scale hands out shapes that stay legible", {
  p <- grouped() + scale_shape_figspec()
  built <- ggplot2::ggplot_build(p)$data[[1]]
  expect_setequal(unique(built$shape), figspec_shapes(3))
})

test_that("fig_apply_spec returns components a plot can take with +", {
  parts <- fig_apply_spec("plos_one")
  expect_type(parts, "list")
  expect_true(any(vapply(parts, function(x) inherits(x, "theme"), logical(1))))
  expect_true(any(vapply(parts, function(x) inherits(x, "Scale"), logical(1))))
})

test_that("a project specification handles a realistic number of groups", {
  report_spec <- list(
    name = "Quarterly research report",
    font_min_pt = 9,
    min_line_pt = 0.5,
    print_greyscale = TRUE
  )
  p <- ggplot2::ggplot(
    ggplot2::mpg,
    ggplot2::aes(displ, hwy, colour = class)
  ) + ggplot2::geom_point() + fig_apply_spec(report_spec)

  expect_silent(built <- ggplot2::ggplot_build(p))
  expect_length(unique(built$data[[1]]$colour), 7)
})
