test_that("stroke converts to points and back", {
  expect_equal(stroke_to_pt(pt_to_stroke(2)), 2, tolerance = 1e-9)
  # ggplot2's default stroke of 0.5 renders at about 0.71 pt.
  expect_equal(stroke_to_pt(0.5), 0.5 * 3.779528 * 0.375, tolerance = 1e-9)
})

test_that("hollow, solid and filled shapes are told apart", {
  expect_true(all(shape_is_hollow(c(0, 1, 2, 14))))
  expect_false(any(shape_is_hollow(c(15, 16, 21, 25))))
  expect_true(all(shape_takes_fill(21:25)))
  expect_false(any(shape_takes_fill(c(1, 16))))
})

test_that("a hollow point's outline is checked against the line-width rule", {
  # Frontiers states a 2 pt minimum; ggplot2's default stroke is far thinner.
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point(shape = 1)
  r <- fig_check(p, "frontiers")
  expect_equal(r[r$check == "Point outline", ]$status, "fail")
})

test_that("solid shapes raise no outline check", {
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point(shape = 16)
  r <- fig_check(p, "frontiers")
  expect_false("Point outline" %in% r$check)
})

test_that("shape coding rescues a palette that merges in greyscale", {
  skip_if_not_installed("colorspace")
  cols <- figspec_palette("okabe_ito", 3)
  shaped <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl),
                                                 shape = factor(cyl))) +
    ggplot2::geom_point() +
    ggplot2::scale_colour_manual(values = cols) +
    ggplot2::scale_shape_manual(values = figspec_shapes(3))
  r <- check_colour_safety(shaped, "royal_society")
  expect_equal(r[r$check == "Redundant coding", ]$status, "unspecified")

  unshaped <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) +
    ggplot2::geom_point() + ggplot2::scale_colour_manual(values = cols)
  r2 <- check_colour_safety(unshaped, "royal_society")
  expect_match(r2[r2$check == "Redundant coding", ]$actual, "only cue")
})

test_that("more shapes than stay distinct is an error, not a silent recycle", {
  expect_error(figspec_shapes(10), class = "figspec_unsupported")
  expect_error(figspec_linetypes(10), class = "figspec_unsupported")
  expect_error(figspec_shapes(10), "stay reliably distinct")
  expect_equal(figspec_shapes(3), c(16, 17, 15))
  expect_equal(figspec_linetypes(3), c("solid", "dashed", "dotted"))
})
