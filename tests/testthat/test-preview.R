# figspec_preview(): the size it resolves, and its behaviour where no graphics
# window can be opened.
#
# The interactive branch opens a device and cannot be exercised here, so what
# is tested is the arithmetic that decides the size and the refusal to pretend
# it did anything in a script.

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
