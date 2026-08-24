# Classifying what a figure puts on the page, which decides which of a
# publisher's resolution minimums applies.
#
# The rule under test throughout: line art means monochrome, so a coloured or
# grey plot must never be suggested as line art.

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

test_that("tone is classified the way publishers define it", {
  # Line art is monochrome: Springer's "Black and white graphic with no
  # shading", ACS's and IEEE's "black and white line art", and Taylor & Francis
  # and OUP both writing "monochrome". In prepress it is a one-bit image.
  bitonal <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point(colour = "black")
  expect_equal(classify_tone(bitonal), "bitonal")

  # ggplot2's default bar fill is #595959, a mid grey. That is grayscale art,
  # NOT line art, and it carries a lower resolution bar.
  expect_equal(classify_tone(bars()), "grayscale")

  coloured <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) +
    ggplot2::geom_point()
  expect_equal(classify_tone(coloured), "colour")
  expect_equal(classify_tone(raster_plot()), "continuous")
})

test_that("the suggestion follows the classification", {
  expect_equal(suppressMessages(suggest_art_type(
    ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
      ggplot2::geom_point(colour = "black"))), "line")
  expect_equal(suppressMessages(suggest_art_type(bars())), "bw")
  expect_equal(suppressMessages(suggest_art_type(raster_plot())), "combination")
  expect_equal(suppressMessages(suggest_art_type(
    ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) +
      ggplot2::geom_point())), "colour")
})

test_that("a coloured plot is never suggested as line art", {
  # Suggesting line art for a colour figure would push a user to 1200 dpi when
  # the journal asks 300, which is the opposite of the harm this helper exists
  # to prevent.
  coloured <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) +
    ggplot2::geom_point()
  expect_false(identical(suppressMessages(suggest_art_type(coloured)), "line"))
})

test_that("the art type genuinely changes the verdict", {
  path <- withr::local_tempfile(fileext = ".png")
  grDevices::png(path, width = 84, height = 60, units = "mm", res = 300)
  plot(1:3)
  grDevices::dev.off()
  # BMJ: 300 dpi generally, 1200 for line art. A bar chart is line art.
  expect_equal(fig_check(path, "bmj", dpi = 300, art_type = "colour")[
    fig_check(path, "bmj", dpi = 300, art_type = "colour")$check == "Resolution", ]$status,
    "pass")
  expect_equal(fig_check(path, "bmj", dpi = 300, art_type = "line")[
    fig_check(path, "bmj", dpi = 300, art_type = "line")$check == "Resolution", ]$status,
    "fail")
})

test_that("the line-art nudge fires only for genuinely bitonal plots", {
  bitonal <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point(colour = "black")
  r <- fig_check(bitonal, "bmj")
  expect_match(r[r$check == "Resolution", ]$requirement, "pure black and white")

  # A grey bar chart is grayscale art, so no line-art nudge. This is the case I
  # first got wrong: a default bar chart is not line art.
  expect_false(grepl("pure black and white",
                     fig_check(bars(), "bmj")[
                       fig_check(bars(), "bmj")$check == "Resolution", ]$requirement))

  # Choosing explicitly is taken at face value.
  r2 <- fig_check(bitonal, "bmj", art_type = "colour")
  expect_false(grepl("pure black and white", r2[r2$check == "Resolution", ]$requirement))

  # Nothing to say where the journal states no line-art rule.
  r4 <- fig_check(bitonal, "frontiers")
  expect_false(grepl("pure black and white", r4[r4$check == "Resolution", ]$requirement))
})

test_that("suggest_art_type refuses a file, which cannot be inspected this way", {
  expect_error(suggest_art_type("figure.tiff"), "ggplot object")
})

test_that("a journal's own resolution figures are shown alongside the suggestion", {
  # The suggestion is only useful next to what the journal actually asks for,
  # since the whole point is that different art types carry different bars.
  skip_if_not_installed("ggplot2")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point(colour = "black")
  out <- capture.output(suggest_art_type(p, "bmj"), type = "message")
  txt <- paste(out, collapse = " ")
  expect_match(txt, "BMJ")
  expect_match(txt, "300")
  expect_match(txt, "1200")
})

test_that("the publisher's own wording is quoted where the registry has it", {
  skip_if_not_installed("ggplot2")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point(colour = "black")
  out <- capture.output(suggest_art_type(p, "bmj"), type = "message")
  expect_match(paste(out, collapse = " "), "line art")
})

test_that("a journal stating only a general minimum lists just that", {
  skip_if_not_installed("ggplot2")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  out <- capture.output(suggest_art_type(p, "frontiers"), type = "message")
  txt <- paste(out, collapse = " ")
  expect_match(txt, "Frontiers")
  expect_match(txt, "300")
})

test_that("the suggestion is returned invisibly for use in a call", {
  skip_if_not_installed("ggplot2")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point(colour = "black")
  got <- suppressMessages(suggest_art_type(p, "bmj"))
  expect_equal(got, "line")
})
