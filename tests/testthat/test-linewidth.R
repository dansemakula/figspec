test_that("points convert to ggplot2 linewidth and back", {
  # ggplot2 draws lwd = linewidth * .pt, and R's lwd unit is 1/96 inch, so
  # one linewidth unit renders at .pt / 96 * 72 points.
  expect_equal(ggplot_linewidth_to_pt(1), 72.27 / 25.4 * 0.75, tolerance = 1e-9)
  expect_equal(ggplot_linewidth_to_pt(pt_to_ggplot_linewidth(2)), 2, tolerance = 1e-9)
  expect_equal(figspec_linewidth("frontiers"), pt_to_ggplot_linewidth(2), tolerance = 1e-9)
})

test_that("a line drawn at the journal minimum measures at the journal minimum", {
  lw <- figspec_linewidth("frontiers")   # Frontiers states 2 pt
  p <- ggplot2::ggplot(ggplot2::economics, ggplot2::aes(date, unemploy)) +
    ggplot2::geom_line(linewidth = lw)
  expect_equal(max(plot_linewidths(p)), 2, tolerance = 1e-6)
})

test_that("line width is checked against the journal's stated range", {
  # Cell Press states 0.5 to 1.5 pt.
  too_thick <- ggplot2::ggplot(ggplot2::economics, ggplot2::aes(date, unemploy)) +
    ggplot2::geom_line(linewidth = pt_to_ggplot_linewidth(4))
  r <- fig_check(too_thick, "cell_press")
  expect_equal(r[r$check == "Line width", ]$status, "fail")

  ok <- ggplot2::ggplot(ggplot2::economics, ggplot2::aes(date, unemploy)) +
    ggplot2::geom_line(linewidth = pt_to_ggplot_linewidth(1))
  expect_equal(fig_check(ok, "cell_press")[
    fig_check(ok, "cell_press")$check == "Line width", ]$status, "pass")
})

test_that("colour mode is checked where the publisher states one", {
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  # Cell Press states RGB; R renders RGB.
  expect_equal(fig_check(p, "cell_press")[
    fig_check(p, "cell_press")$check == "Colour mode", ]$status, "pass")
  # Cambridge states CMYK, which R cannot produce.
  expect_equal(fig_check(p, "cambridge")[
    fig_check(p, "cambridge")$check == "Colour mode", ]$status, "fail")
})
