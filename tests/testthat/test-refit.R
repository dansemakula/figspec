# Re-exporting a set of figures against a different journal's specification.

test_that("a set of plots is re-exported to another journal's spec", {
  skip_if_not_installed("ragg")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  dir <- withr::local_tempdir()
  res <- suppressWarnings(suppressMessages(
    fig_refit(list(figure_1 = p, figure_2 = p), "frontiers", dir, column = "double")
  ))
  expect_equal(nrow(res), 2)
  expect_true(all(file.exists(file.path(dir, c("figure_1.tiff", "figure_2.tiff")))))
  # Frontiers' double column is 180 mm.
  info <- inspect_file(file.path(dir, "figure_1.tiff"))
  expect_equal(info$width_mm, 180, tolerance = 0.5)
})

test_that("refitting saved files is refused rather than faked", {
  dir <- withr::local_tempdir()
  expect_error(
    fig_refit(list(a = "some/file.tiff"), "frontiers", dir),
    "editable live figures"
  )
})

test_that("refit requires named plots", {
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  expect_error(fig_refit(list(p), "frontiers", withr::local_tempdir()), "named list")
})

test_that("refit validates paths, mappings and switches before writing", {
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  plots <- list(first = p, second = p)
  target <- withr::local_tempdir()

  expect_error(fig_refit(list(), "frontiers", target), class = "figspec_bad_input")
  expect_error(fig_refit(plots, "frontiers", character()), class = "figspec_bad_input")
  expect_error(fig_refit(plots, "frontiers", target, retheme = NA), class = "figspec_bad_input")
  expect_error(fig_refit(plots, "frontiers", target, format = "../png"), class = "figspec_bad_input")
  expect_error(
    fig_refit(
      plots,
      "frontiers",
      target,
      column = c(first = "single")
    ),
    "Missing plot names: second",
    class = "figspec_bad_input"
  )
  expect_error(
    fig_refit(
      plots,
      "frontiers",
      target,
      column = c(first = "single", second = "double", typo = "single")
    ),
    "Unknown plot names: typo",
    class = "figspec_bad_input"
  )
})

test_that("a named width mapping survives the file-export check", {
  skip_if_not_installed("ragg")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  target <- withr::local_tempdir()
  review <- suppressWarnings(suppressMessages(
    fig_refit(
      list(first = p, second = p),
      "frontiers",
      target,
      column = c(first = "single", second = "double"),
      format = "tiff"
    )
  ))
  expect_identical(review$column, c("single", "double"))
  expect_equal(inspect_file(file.path(target, "first.tiff"))$width_mm, 85, tolerance = 0.5)
  expect_equal(inspect_file(file.path(target, "second.tiff"))$width_mm, 180, tolerance = 0.5)
})

test_that("line width converts points to ggplot2 linewidth units", {
  # Frontiers states a two-point minimum. See test-linewidth.R for why the
  # conversion is not simply points to millimetres.
  expect_equal(spec_linewidth("frontiers"), 2 / (72.27 / 25.4 * 0.75),
               tolerance = 1e-9)
  expect_message(spec_linewidth("jss"), "no minimum line width")
})
