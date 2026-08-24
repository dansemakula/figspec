# figspec_preview(): the size it resolves, and its behaviour where no graphics
# window can be opened.
#
# Both halves are tested. The non-interactive branch is straightforward. The
# interactive branch is reached by mocking interactive(), which lets the real
# device be opened and measured: dev.new() falls back to a file device where
# there is no display, and it still reports its size, which is the thing worth
# asserting - that the window is the journal's stated column width and not
# something approximate.

p_small <- function() {
  ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
}

test_that("a non-interactive session is told the size rather than shown it", {
  skip_if_not_installed("ggplot2")
  msg <- capture.output(figspec_preview(p_small(), "cell_press", "single"),
                        type = "message")
  txt <- paste(msg, collapse = " ")
  expect_match(txt, "non-interactive")
  # Cell Press's single column is 85 mm, and the default height is three
  # quarters of the width.
  expect_match(txt, "85")
  expect_match(txt, "63.8|63.75")
})

test_that("the plot is returned unchanged, so it can be piped through", {
  skip_if_not_installed("ggplot2")
  p <- p_small()
  out <- suppressMessages(figspec_preview(p, "cell_press", "single"))
  expect_identical(out, p)
})

test_that("an explicit height is used instead of the default proportion", {
  skip_if_not_installed("ggplot2")
  msg <- capture.output(
    figspec_preview(p_small(), "cell_press", "single", height = 40),
    type = "message")
  expect_match(paste(msg, collapse = " "), "40")
})

test_that("a height given in other units is converted before it is reported", {
  skip_if_not_installed("ggplot2")
  msg <- capture.output(
    figspec_preview(p_small(), "cell_press", "single", height = 4, units = "cm"),
    type = "message")
  # 4 cm is 40 mm, and the message speaks millimetres.
  expect_match(paste(msg, collapse = " "), "40")
})

test_that("the column has to be one the journal states", {
  skip_if_not_installed("ggplot2")
  expect_error(
    suppressMessages(figspec_preview(p_small(), "cell_press", "quadruple")),
    class = "figspec_error"
  )
})

test_that("a journal that is not in the registry is an error, not a guess", {
  skip_if_not_installed("ggplot2")
  expect_error(
    suppressMessages(figspec_preview(p_small(), "no_such_journal")),
    class = "figspec_not_found"
  )
})

# The interactive branch ------------------------------------------------------

test_that("the device opened is exactly the journal's column width", {
  skip_if_not_installed("ggplot2")
  # dev.new() writes into the working directory where it falls back to a file
  # device, so keep that inside the temp directory.
  withr::local_dir(withr::local_tempdir())
  testthat::local_mocked_bindings(is_interactive = function() TRUE)
  on.exit(while (grDevices::dev.cur() > 1L) grDevices::dev.off(), add = TRUE)

  suppressMessages(figspec_preview(p_small(), "cell_press", "single"))
  size <- grDevices::dev.size("in")

  # Cell Press single column is 85 mm, default height three quarters of it.
  expect_equal(size[1], 85 / 25.4, tolerance = 1e-3)
  expect_equal(size[2], 63.75 / 25.4, tolerance = 1e-3)
})

test_that("a different column opens a different device", {
  skip_if_not_installed("ggplot2")
  withr::local_dir(withr::local_tempdir())
  testthat::local_mocked_bindings(is_interactive = function() TRUE)
  on.exit(while (grDevices::dev.cur() > 1L) grDevices::dev.off(), add = TRUE)

  suppressMessages(figspec_preview(p_small(), "cell_press", "double"))
  expect_equal(grDevices::dev.size("in")[1], 174 / 25.4, tolerance = 1e-3)
})

test_that("an explicit height reaches the device, not just the message", {
  skip_if_not_installed("ggplot2")
  withr::local_dir(withr::local_tempdir())
  testthat::local_mocked_bindings(is_interactive = function() TRUE)
  on.exit(while (grDevices::dev.cur() > 1L) grDevices::dev.off(), add = TRUE)

  suppressMessages(figspec_preview(p_small(), "cell_press", "single", height = 40))
  expect_equal(grDevices::dev.size("in")[2], 40 / 25.4, tolerance = 1e-3)
})

test_that("the interactive run says which journal and column it is showing", {
  skip_if_not_installed("ggplot2")
  withr::local_dir(withr::local_tempdir())
  testthat::local_mocked_bindings(is_interactive = function() TRUE)
  on.exit(while (grDevices::dev.cur() > 1L) grDevices::dev.off(), add = TRUE)

  msg <- capture.output(figspec_preview(p_small(), "cell_press", "single"),
                        type = "message")
  txt <- paste(msg, collapse = " ")
  expect_match(txt, "Cell Press")
  expect_match(txt, "single")
  expect_match(txt, "published size")
})
