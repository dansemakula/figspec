# The shipped palettes: their contents, their sources, and that no journal
# palette is invented where a publisher states none.

pal_plot <- function(cols) {
  n <- length(cols)
  ggplot2::ggplot(data.frame(x = seq_len(n), y = seq_len(n), g = factor(seq_len(n))),
                  ggplot2::aes(x, y, colour = g)) +
    ggplot2::geom_point() +
    ggplot2::scale_colour_manual(values = cols)
}

test_that("shipped palettes are listed with their sources", {
  p <- figspec_palettes()
  expect_identical(
    names(p),
    c("id", "name", "type", "n", "guidance", "source", "source_url")
  )
  expect_true(all(c("okabe_ito", "cividis", "viridis") %in% p$id))
  expect_identical(p$type, c("qualitative", "sequential", "sequential"))
  expect_true(all(nzchar(p$guidance)))
  expect_true(all(nzchar(p$source)))
  expect_true(all(grepl("^https://", p$source_url)))
})

test_that("cividis is safe in greyscale AND under colour vision deficiency", {
  skip_if_not_installed("colorspace")
  # This is the claim the package makes for cividis, so it is tested, not asserted.
  r <- colour_safety_check(pal_plot(figspec_palette("cividis", 5)), "royal_society")
  expect_equal(r[r$check == "Greyscale", ]$status, "pass")
  expect_match(r[r$check == "Colour vision", ]$actual, "separable under")
})

test_that("Okabe-Ito is colour-vision safe but NOT greyscale safe", {
  skip_if_not_installed("colorspace")
  # Two of its colours sit at almost the same lightness. The documentation
  # says so; this pins it.
  r <- colour_safety_check(pal_plot(figspec_palette("okabe_ito", 5)), "royal_society")
  expect_match(r[r$check == "Colour vision", ]$actual, "separable under")
  expect_equal(r[r$check == "Greyscale", ]$status, "fail")
})

test_that("fixed palettes do not recycle colours to fill a request", {
  expect_error(figspec_palette("okabe_ito", 20), class = "figspec_unsupported")
  expect_error(figspec_palette("okabe_ito", 20), "Pick a palette with more")
  expect_error(figspec_palette("nope"), class = "figspec_not_found")
  expect_error(figspec_palette("nope"), "Unknown palette")
})

test_that("sequential palettes expand to the data", {
  expect_length(figspec_palette("cividis", 7), 7)
  expect_length(unique(figspec_palette("cividis", 7)), 7)
  expect_length(figspec_palette("viridis", 20), 20)
  expect_equal(figspec_palettes()$n[figspec_palettes()$id == "cividis"], Inf)
})

test_that("scales apply the palette", {
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) +
    ggplot2::geom_point() + scale_colour_figspec("cividis")
  expect_setequal(plot_colours(p), figspec_palette("cividis", 3))

  seven_groups <- ggplot2::ggplot(
    ggplot2::mpg,
    ggplot2::aes(displ, hwy, colour = class)
  ) + ggplot2::geom_point() + scale_colour_figspec("cividis")
  expect_setequal(plot_colours(seven_groups), figspec_palette("cividis", 7))
})

test_that("no journal palette is invented", {
  # Messages fold at the console width, so a phrase can straddle a line break.
  # This test is about what is said, not where it wraps.
  withr::with_options(
    list(width = 200),
    expect_message(
      spec_style_palette("plos_one"),
      "will keep its current colours"
    )
  )
})

test_that("invalid recorded house-style colours are refused", {
  bad_spec <- list(
    name = "Broken project style",
    house_style = list(palette = c("#0072B2", "not-a-colour"))
  )
  expect_error(
    spec_style_palette(bad_spec),
    "invalid R colour",
    class = "figspec_bad_input"
  )
})
