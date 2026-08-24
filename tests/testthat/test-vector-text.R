# Type size in a saved file. A raster's text is pixels and the point sizes have
# gone; a vector file still records the size each string was set at.

skip_if_no <- function(pkg) skip_if_not_installed(pkg)

vec_plot <- function(base_size = 11) {
  ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point() +
    ggplot2::theme_grey(base_size = base_size)
}

write_pdf <- function(base_size = 11) {
  f <- tempfile(fileext = ".pdf")
  grDevices::pdf(f, width = 3.3, height = 2.4)
  print(vec_plot(base_size)); grDevices::dev.off()
  f
}

test_that("a PDF gives up its type sizes", {
  skip_if_no("ggplot2"); skip_if_no("pdftools")
  f <- write_pdf(); on.exit(unlink(f))
  s <- vector_text_sizes(f)
  expect_s3_class(s, "data.frame")
  expect_true(all(s$size_pt > 0))
  # R's pdf() device rounds text to whole points, so a theme asking for 8.8 pt
  # writes 9. That is the figure a publisher receives, and the point of
  # reading the file rather than the object.
  expect_true(9 %in% round(s$size_pt))
})

test_that("an SVG gives up its type sizes, unrounded", {
  skip_if_no("ggplot2"); skip_if_no("svglite")
  f <- tempfile(fileext = ".svg"); on.exit(unlink(f))
  svglite::svglite(f, width = 3.3, height = 2.4)
  print(vec_plot()); grDevices::dev.off()
  s <- vector_text_sizes(f)
  expect_s3_class(s, "data.frame")
  # svglite does not quantise, so the theme's 8.8 pt survives intact.
  expect_true(any(abs(s$size_pt - 8.8) < 0.01))
})

test_that("an EPS gives up its type sizes", {
  skip_if_no("ggplot2")
  f <- tempfile(fileext = ".eps"); on.exit(unlink(f))
  grDevices::postscript(f, width = 3.3, height = 2.4, paper = "special",
                        horizontal = FALSE, onefile = FALSE)
  print(vec_plot()); grDevices::dev.off()
  s <- vector_text_sizes(f)
  expect_s3_class(s, "data.frame")
  expect_true(all(s$size_pt > 0))
})

test_that("a raster says it cannot tell rather than guessing", {
  skip_if_no("ggplot2")
  f <- tempfile(fileext = ".png"); on.exit(unlink(f))
  grDevices::png(f, width = 3.3, height = 2.4, units = "in", res = 300)
  print(vec_plot()); grDevices::dev.off()
  expect_null(vector_text_sizes(f))
})

test_that("an unreadable or empty file yields nothing, not an error", {
  f <- tempfile(fileext = ".svg"); on.exit(unlink(f))
  writeLines("<svg></svg>", f)
  expect_null(vector_text_sizes(f))
  expect_null(vector_text_sizes(tempfile(fileext = ".pdf")))
})

test_that("fig_check answers type size for a vector file and not for a raster", {
  skip_if_no("ggplot2"); skip_if_no("pdftools")
  pdf_f <- write_pdf(); on.exit(unlink(pdf_f), add = TRUE)
  png_f <- tempfile(fileext = ".png"); on.exit(unlink(png_f), add = TRUE)
  grDevices::png(png_f, width = 3.3, height = 2.4, units = "in", res = 300)
  print(vec_plot()); grDevices::dev.off()

  vec <- fig_check(pdf_f, "cell_press")
  ras <- fig_check(png_f, "cell_press")
  expect_true(vec$status[vec$check == "Type size"] %in% c("pass", "fail"))
  expect_equal(ras$status[ras$check == "Type size"], "unknown")
  expect_equal(ras$actual[ras$check == "Type size"], "could not determine")
})

test_that("the file is checked, not what the plot object intended", {
  skip_if_no("ggplot2"); skip_if_no("pdftools")
  # 5.2 pt in the object becomes 5 pt in the file, because the device rounds.
  # Against a 6 pt floor both fail, but the number reported must be the file's.
  f <- write_pdf(base_size = 6.5); on.exit(unlink(f))
  s <- vector_text_sizes(f)
  expect_true(all(abs(s$size_pt - round(s$size_pt)) < 1e-6))
})
