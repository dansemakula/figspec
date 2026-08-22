bars <- function() ggplot2::ggplot(mtcars, ggplot2::aes(factor(cyl))) + ggplot2::geom_bar()
raster_plot <- function() {
  ggplot2::ggplot(ggplot2::faithfuld, ggplot2::aes(waiting, eruptions, fill = density)) +
    ggplot2::geom_raster()
}

test_that("continuous-tone layers are told apart from lines and flat fills", {
  expect_false(plot_has_raster(bars()))
  expect_true(plot_has_raster(raster_plot()))
  expect_true(plot_has_raster(
    ggplot2::ggplot(mtcars, ggplot2::aes(factor(cyl), factor(gear), fill = mpg)) +
      ggplot2::geom_tile()))
})

test_that("greyscale is distinguished from colour", {
  expect_true(plot_is_greyscale(bars()))
  expect_false(plot_is_greyscale(
    ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) +
      ggplot2::geom_point()))
})

test_that("the suggestion follows what the plot contains", {
  expect_equal(suppressMessages(suggest_art_type(bars())), "line")
  expect_equal(suppressMessages(suggest_art_type(raster_plot())), "combination")
  # A coloured vector plot is still line art in the sense PNAS means, but the
  # explanation must name the disagreement rather than hide it.
  coloured <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) +
    ggplot2::geom_point()
  expect_equal(suppressMessages(suggest_art_type(coloured)), "line")
})

test_that("the art type genuinely changes the verdict", {
  path <- withr::local_tempfile(fileext = ".png")
  grDevices::png(path, width = 84, height = 60, units = "mm", res = 300)
  plot(1:3)
  grDevices::dev.off()
  # BMJ: 300 dpi generally, 1200 for line art. A bar chart is line art.
  expect_equal(check_journal(path, "bmj", dpi = 300, art_type = "colour")[
    check_journal(path, "bmj", dpi = 300, art_type = "colour")$check == "Resolution", ]$status,
    "pass")
  expect_equal(check_journal(path, "bmj", dpi = 300, art_type = "line")[
    check_journal(path, "bmj", dpi = 300, art_type = "line")$check == "Resolution", ]$status,
    "fail")
})

test_that("a lenient default warns rather than passing silently", {
  # Not choosing an art type checks against the general minimum, which for a
  # plot that looks like line art can be a quarter of what the journal asks.
  r <- check_journal(bars(), "bmj")
  expect_match(r[r$check == "Resolution", ]$requirement, "looks like line art")

  # Choosing explicitly is taken at face value: no second-guessing.
  r2 <- check_journal(bars(), "bmj", art_type = "colour")
  expect_false(grepl("looks like line art", r2[r2$check == "Resolution", ]$requirement))

  # A continuous-tone plot is not line art, so no warning.
  r3 <- check_journal(raster_plot(), "bmj")
  expect_false(grepl("looks like line art", r3[r3$check == "Resolution", ]$requirement))

  # Nothing to warn about where the journal states no line-art rule.
  r4 <- check_journal(bars(), "frontiers")
  expect_false(grepl("looks like line art", r4[r4$check == "Resolution", ]$requirement))
})

test_that("suggest_art_type refuses a file, which cannot be inspected this way", {
  expect_error(suggest_art_type("figure.tiff"), "ggplot object")
})
