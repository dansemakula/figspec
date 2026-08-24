# Behaviour when an optional package is not installed.
#
# figspec has eleven hard dependencies and twelve optional ones. Everything in
# Suggests must be genuinely optional: without it the package does less, but it
# does not fail, and it never quietly reports a check as passed that it could
# not actually run.
#
# Absence is simulated by replacing has_package(), which is why that binding
# exists in figspec's namespace rather than calling requireNamespace() directly
# at each site - base and namespace environments are locked, so a package that
# is installed cannot otherwise be hidden from itself.

without <- function(...) {
  gone <- c(...)
  testthat::local_mocked_bindings(
    has_package = function(pkg) !(pkg %in% gone) && requireNamespace(pkg, quietly = TRUE),
    .env = parent.frame()
  )
}

demo_plot <- function() {
  ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) +
    ggplot2::geom_point()
}

test_that("a check still runs with every optional package absent", {
  skip_if_not_installed("ggplot2")
  without("ragg", "svglite", "colorspace", "pdftools", "patchwork", "systemfonts")
  r <- fig_check(demo_plot(), "cell_press")
  expect_s3_class(r, "figspec_report")
  expect_true(any(r$status %in% c("pass", "fail")))
})

test_that("a figure still saves with every optional package absent", {
  skip_if_not_installed("ggplot2")
  without("ragg", "svglite", "colorspace", "pdftools", "systemfonts")
  out <- tempfile(fileext = ".png"); on.exit(unlink(out))
  suppressWarnings(suppressMessages(
    fig_save(out, demo_plot(), width = 85, height = 60, units = "mm", check = FALSE)))
  expect_true(file.exists(out))
  expect_gt(file.size(out), 0)
})

test_that("without colorspace the colour-vision check says so, and passes nothing", {
  # The one that matters most: a check that cannot run must never look like a
  # check that succeeded.
  skip_if_not_installed("ggplot2")
  without("colorspace")
  r <- check_colour_safety(demo_plot(), "cell_press")
  cvd <- r[r$check == "Colour vision", ]
  expect_equal(nrow(cvd), 1)
  expect_false(cvd$status == "pass")
  expect_match(cvd$actual, "colorspace")
})

test_that("without colorspace the greyscale check still runs on the fallback", {
  # Desaturation has a WCAG-luminance fallback, so this one degrades in
  # accuracy rather than disappearing.
  skip_if_not_installed("ggplot2")
  without("colorspace")
  grey <- to_greyscale(c("#E69F00", "#56B4E9", "#009E73"))
  expect_length(grey, 3)
  expect_true(all(grepl("^#", grey)))
})

test_that("without pdftools a PDF's type sizes are unknown, not guessed", {
  skip_if_not_installed("ggplot2")
  f <- tempfile(fileext = ".pdf"); on.exit(unlink(f))
  grDevices::pdf(f, width = 3.3, height = 2.4)
  print(demo_plot()); grDevices::dev.off()

  without("pdftools")
  expect_null(vector_text_sizes(f))
  r <- fig_check(f, "cell_press")
  expect_equal(r$status[r$check == "Type size"], "unknown")
  expect_equal(r$actual[r$check == "Type size"], "could not determine")
})

test_that("without ragg a raster is still written, by the base device", {
  skip_if_not_installed("ggplot2")
  without("ragg")
  out <- tempfile(fileext = ".png"); on.exit(unlink(out))
  suppressWarnings(suppressMessages(
    fig_save(out, demo_plot(), width = 85, height = 60, units = "mm", check = FALSE)))
  expect_true(file.exists(out))
  expect_equal(inspect_file(out)$format, "png")
})

test_that("without svglite an SVG still comes out of the base device", {
  skip_if_not_installed("ggplot2")
  without("svglite")
  out <- tempfile(fileext = ".svg"); on.exit(unlink(out))
  suppressWarnings(suppressMessages(
    fig_save(out, demo_plot(), width = 85, height = 60, units = "mm", check = FALSE)))
  expect_true(file.exists(out))
})

test_that("the knitr device falls back to one that exists", {
  without("ragg", "svglite")
  expect_equal(knitr_device("png"), "png")
  expect_equal(knitr_device("svg"), "svg")
})

test_that("without knitr the setup helper refuses rather than half-working", {
  without("knitr")
  expect_error(figspec_knitr_setup("cell_press"), class = "figspec_needs_package")
})

test_that("without curl the source checker refuses rather than reporting nothing", {
  # Reporting an empty result would read as "every source is fine".
  without("curl")
  expect_error(check_sources(), class = "figspec_needs_package")
})

test_that("every needs_package error names the package and how to get it", {
  without("knitr", "curl")
  for (call in list(function() figspec_knitr_setup("cell_press"),
                    function() check_sources())) {
    err <- tryCatch(call(), error = function(e) e)
    expect_s3_class(err, "figspec_needs_package")
    expect_match(conditionMessage(err), "install.packages")
  }
})
