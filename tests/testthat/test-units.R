test_that("length conversion round-trips", {
  expect_equal(convert_length(25.4, "mm", "in"), 1)
  expect_equal(convert_length(1, "in", "mm"), 25.4)
  expect_equal(convert_length(10, "mm", "cm"), 1)
  expect_equal(convert_length(convert_length(85, "mm", "in"), "in", "mm"), 85)
})

test_that("pixel conversion requires a resolution", {
  expect_error(convert_length(300, "px", "mm"), "dpi")
  expect_equal(convert_length(300, "px", "in", dpi = 300), 1)
})

test_that("fig_width reads the registry rather than guessing", {
  # Cell Press states 8.5 / 11.4 / 17.4 cm.
  expect_equal(fig_width("cell_press", "single"), 85)
  expect_equal(fig_width("cell_press", "onehalf"), 114)
  expect_equal(fig_width("cell_press", "double"), 174)
  expect_equal(fig_width("cell_press", "single", "in"), 85 / 25.4)
})

test_that("fig_width errors rather than inventing a width", {
  # JSS states no figure widths at all.
  expect_error(fig_width("jss", "single"), "does not state")
})
