# Publication-hardening regression tests use real ggplot builds and graphics
# devices. Byte-level parser tests elsewhere supplement these; they do not
# replace these end-to-end cases.

skip_if_not_installed("ggplot2")

real_scatter <- function(n) {
  base <- if (n <= nrow(datasets::mtcars)) datasets::mtcars else ggplot2::diamonds
  d <- base[rep(seq_len(nrow(base)), length.out = n), , drop = FALSE]
  d$observation <- seq_len(n)
  x <- if ("wt" %in% names(d)) d$wt else d$carat
  y <- if ("mpg" %in% names(d)) d$mpg else d$price
  d$x_value <- x
  d$y_value <- y
  ggplot2::ggplot(d, ggplot2::aes(x_value, y_value, colour = observation)) +
    ggplot2::geom_point(alpha = 0.45)
}

test_that("continuous scales build and render across realistic data sizes", {
  for (n in c(32L, 10000L, 100000L)) {
    p <- real_scatter(n) + fig_apply_spec("cell_press")
    built <- ggplot2::ggplot_build(p)
    expect_equal(nrow(built$data[[1]]), n)
    expect_false(built$plot$scales$get_scales("colour")$is_discrete())

    out <- tempfile(fileext = ".png"); on.exit(unlink(out), add = TRUE)
    suppressWarnings(fig_save(out, p, width = 30, height = 20,
                              dpi = 96, check = FALSE))
    expect_true(isTRUE(inspect_file(out)$valid))
  }
})

test_that("the external large-data stress case renders a real plot", {
  skip_if(
    !identical(Sys.getenv("FIGSPEC_RUN_STRESS"), "true"),
    "set FIGSPEC_RUN_STRESS=true for the 250,000-row release stress test"
  )
  n <- 250000L
  p <- real_scatter(n) + fig_apply_spec("cell_press")
  built <- ggplot2::ggplot_build(p)
  expect_equal(nrow(built$data[[1]]), n)

  out <- tempfile(fileext = ".png")
  on.exit(unlink(out))
  suppressWarnings(fig_save(
    out, p, width = 85, height = 60, dpi = 150, check = FALSE
  ))
  expect_true(isTRUE(inspect_file(out)$valid))
})

test_that("a selected column is the only width that can pass", {
  skip_if_not_installed("ragg")
  out <- tempfile(fileext = ".tiff"); on.exit(unlink(out))
  p <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  suppressWarnings(fig_save(out, p, "cell_press", column = "double",
                            art_type = "colour", check = FALSE))
  expect_equal(fig_check(out, "cell_press", column = "double", art_type = "colour")$status[
    fig_check(out, "cell_press", column = "double", art_type = "colour")$check == "Width"], "pass")
  expect_equal(fig_check(out, "cell_press", column = "single", art_type = "colour")$status[
    fig_check(out, "cell_press", column = "single", art_type = "colour")$check == "Width"], "fail")
})

test_that("minimum, maximum, and strict resolution bounds are enforced", {
  spec <- list(name = "Range", dpi_min = 300, dpi_max = 600)
  p <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  expect_equal(fig_check(p, spec, dpi = 1200)$status[
    fig_check(p, spec, dpi = 1200)$check == "Resolution"], "fail")
  expect_true(meets_dpi(300, 300))
  expect_false(meets_dpi(300, 300, inclusive = FALSE))
  expect_true(meets_dpi(301, 300, inclusive = FALSE))
  expect_false(meets_resolution(601, 300, 600))
})

test_that("automatic art type uses the plot and the saved-file fallback is conservative", {
  p <- ggplot2::ggplot(ggplot2::economics, ggplot2::aes(date, unemploy)) +
    ggplot2::geom_line(colour = "black") + ggplot2::theme_void()
  expect_equal(infer_art_type(p), "line")
  r <- fig_check(p, "cell_press", dpi = 300)
  expect_equal(r$status[r$check == "Resolution"], "fail")

  out <- tempfile(fileext = ".png"); on.exit(unlink(out))
  grDevices::png(out, width = 1000, height = 700, res = 300)
  graphics::plot(datasets::cars)
  grDevices::dev.off()
  expect_equal(fig_check(out, "cell_press", dpi = 300)$status[
    fig_check(out, "cell_press", dpi = 300)$check == "Resolution"], "fail")
})

test_that("fig_save transforms by default and can verify without transforming", {
  skip_if_not_installed("ragg")
  p <- ggplot2::ggplot(datasets::mtcars,
                       ggplot2::aes(wt, mpg, colour = factor(cyl))) +
    ggplot2::geom_point() + ggplot2::labs(title = "Fuel economy")
  transformed_out <- tempfile(fileext = ".tiff")
  unchanged_out <- tempfile(fileext = ".tiff")
  on.exit(unlink(c(transformed_out, unchanged_out)))

  transformed <- suppressWarnings(fig_save(
    transformed_out, p, "cell_press", column = "single",
    art_type = "colour", check = TRUE
  ))
  transformed_report <- attr(transformed, "figspec_report")
  expect_s3_class(transformed_report, "figspec_report")
  expect_equal(
    transformed_report$status[transformed_report$check == "Type size"],
    "pass"
  )
  expect_equal(
    transformed_report$status[transformed_report$check == "Colour pairs"],
    "pass"
  )

  unchanged <- suppressWarnings(fig_save(
    unchanged_out, p, "cell_press", column = "single",
    art_type = "colour", transform = FALSE, check = TRUE
  ))
  unchanged_report <- attr(unchanged, "figspec_report")
  expect_s3_class(unchanged_report, "figspec_report")
  expect_equal(
    unchanged_report$status[unchanged_report$check == "Type size"],
    "fail"
  )
  expect_equal(
    unchanged_report$status[unchanged_report$check == "Colour pairs"],
    "fail"
  )
})

test_that("PLOS TIFF export satisfies format-specific requirements", {
  skip_if_not_installed("ragg")
  p <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point() + theme_spec("plos_one")
  out <- tempfile(fileext = ".tiff"); on.exit(unlink(out))
  suppressWarnings(fig_save(out, p, "plos_one", column = "single",
                            art_type = "colour", check = FALSE))
  info <- inspect_file(out)
  expect_equal(info$compression, "lzw")
  expect_false(info$has_alpha)
  expect_true(info$flattened)
  expect_equal(info$pages, 1L)
  expect_equal(info$dpi, 300, tolerance = 1)

  exiftool <- Sys.which("exiftool")
  if (nzchar(exiftool)) {
    independent <- system2(exiftool,
      c("-s3", "-Compression", "-ExtraSamples", "-XResolution", shQuote(out)),
      stdout = TRUE, stderr = TRUE)
    expect_true(any(grepl("LZW", independent, ignore.case = TRUE)))
    expect_true(any(grepl("300", independent)))
    expect_false(any(grepl("alpha", independent, ignore.case = TRUE)))
  }
})

for (round_trip_format in c("png", "jpeg", "tiff", "svg", "pdf", "eps")) {
  local({
    ext <- round_trip_format
    test_that(paste("a real plot round-trips through", toupper(ext)), {
      if (ext == "svg") skip_if_not_installed("svglite")
      if (ext %in% c("png", "tiff")) skip_if_not_installed("ragg")

      p <- ggplot2::ggplot(
        ggplot2::diamonds[seq_len(2000), ],
        ggplot2::aes(carat, price, colour = cut)
      ) +
        ggplot2::geom_point(alpha = 0.5) +
        ggplot2::labs(x = "Carat", y = "Price", colour = "Cut")
      spec <- list(
        name = "Integration format", columns = list(single = 85),
        dpi_min = 96,
        formats = list("png", "jpeg", "tiff", "svg", "pdf", "eps")
      )
      out <- tempfile(fileext = paste0(".", ext))
      on.exit(unlink(out))
      saved <- suppressWarnings(fig_save(
        out, p, spec, column = "single", dpi = 96,
        art_type = "colour", check = TRUE
      ))
      info <- inspect_file(out)
      expect_true(isTRUE(info$valid), info = ext)
      expect_equal(info$width_mm, 85, tolerance = 0.6, info = ext)
      report <- attr(saved, "figspec_report")
      expect_equal(
        report$status[report$check == "File format"], "pass", info = ext
      )
    })
  })
}

test_that("CMYK vector export is real and RGB raster substitution is refused", {
  p <- ggplot2::ggplot(datasets::iris,
                       ggplot2::aes(Sepal.Length, Petal.Length, colour = Species)) +
    ggplot2::geom_point() + theme_spec("cambridge")
  out <- tempfile(fileext = ".eps"); on.exit(unlink(out), add = TRUE)
  saved <- suppressWarnings(fig_save(out, p, "cambridge", width = 85,
                                     art_type = "colour", check = TRUE))
  info <- inspect_file(out)
  expect_true(info$valid)
  expect_equal(info$colour_mode, "CMYK")
  report <- attr(saved, "figspec_report")
  expect_equal(report$status[report$check == "Colour mode"], "pass")

  bad <- tempfile(fileext = ".tiff"); on.exit(unlink(bad), add = TRUE)
  expect_error(fig_save(bad, p, "cambridge", width = 85, check = FALSE),
               class = "figspec_unsupported")
  expect_false(file.exists(bad))
})

test_that("a widthless journal uses the documented device-size default", {
  p <- ggplot2::ggplot(datasets::iris,
                       ggplot2::aes(Sepal.Length, Petal.Length)) + ggplot2::geom_point()
  spec <- list(name = "No width", formats = list("pdf"))
  out <- tempfile(fileext = ".pdf"); on.exit(unlink(out), add = TRUE)
  suppressWarnings(fig_save(out, p, spec, check = FALSE))
  expect_equal(inspect_file(out)$width_mm, 7 * 25.4, tolerance = 0.6)
})

test_that("real vector dimensions are recovered and embedded rasters are not certified", {
  skip_if_not_installed("svglite")
  p <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  svg <- tempfile(fileext = ".svg"); on.exit(unlink(svg), add = TRUE)
  ggplot2::ggsave(svg, p, width = 85, height = 60, units = "mm")
  expect_equal(inspect_file(svg)$width_mm, 85, tolerance = 0.2)

  pdf <- tempfile(fileext = ".pdf"); on.exit(unlink(pdf), add = TRUE)
  raster <- as.raster(grDevices::terrain.colors(64)[matrix(seq_len(64), 8)])
  rp <- p + ggplot2::annotation_raster(raster, -Inf, Inf, -Inf, Inf)
  ggplot2::ggsave(pdf, rp, width = 85, height = 60, units = "mm")
  r <- fig_check(pdf, "cell_press", column = "single", art_type = "line")
  expect_equal(r$status[r$check == "Resolution"], "unknown")
  expect_match(r$actual[r$check == "Resolution"], "includes raster")
})

test_that("invalid files and dimension-changing scale never receive compliance", {
  bad <- tempfile(fileext = ".svg"); on.exit(unlink(bad), add = TRUE)
  writeLines("this is not SVG", bad)
  r <- suppressWarnings(fig_check(bad, list(name = "SVG", formats = list("svg"), dpi_min = 300)))
  expect_true(any(r$status == "invalid"))
  expect_false(any(r$status == "pass"))

  out <- tempfile(fileext = ".png"); on.exit(unlink(out), add = TRUE)
  p <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  expect_error(fig_save(out, p, width = 85, scale = 2), class = "figspec_size_conflict")
})

test_that("all free-scale facets are inspected for zero", {
  d <- data.frame(x = rep(1:5, 2), y = c(0:4, 100:104), panel = rep(c("near", "far"), each = 5))
  p <- ggplot2::ggplot(d, ggplot2::aes(x, y)) + ggplot2::geom_line() +
    ggplot2::facet_wrap(~panel, scales = "free_y")
  missing <- axes_missing_zero(p)
  expect_true(any(grepl("panel 1 y", missing)))
  expect_equal(fig_check(p, "pnas", column = "small")$status[
    fig_check(p, "pnas", column = "small")$check == "Axis origin"], "fail")
})

test_that("registry schema rejects values that could create false passes", {
  base <- list(id = "bad", name = "Bad", source_url = "internal:test",
               verified_on = as.character(Sys.Date()), requirements = list())
  cases <- list(
    within(base, requirements <- list(dpi_min = -1)),
    within(base, requirements <- list(font_min_pt = 12, font_max_pt = 8)),
    within(base, requirements <- list(unknown_rule = 1)),
    within(base, typo_field <- 1),
    within(base, requirements <- list(avoid_colour_pairs = list("red"))),
    within(base, media <- list(frame_max = list(width = -1, height = 1080))),
    within(base, source_url <- "not a url"),
    within(base, verified_on <- "2026-99-99")
  )
  for (entry in cases) expect_error(validate_registry(list(entry)), class = "figspec_bad_registry")
})

test_that("refit filenames cannot escape their output directory", {
  p <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  expect_error(fig_refit(list("../escaped" = p), "frontiers", tempfile()),
               class = "figspec_bad_input")
})

test_that("Frontiers faceted labels are not embedded contrary to its guidance", {
  p <- ggplot2::ggplot(datasets::mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point() + ggplot2::facet_wrap(~cyl)
  expect_error(fig_tag_panels(p, "frontiers"), class = "figspec_unsupported")
})
