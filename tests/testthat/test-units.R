# Length conversion between millimetres, centimetres, inches and pixels.

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

test_that("every unit pair converts in both directions", {
  units <- c("mm", "cm", "in")
  for (from in units) {
    for (to in units) {
      v <- convert_length(100, from, to)
      expect_equal(convert_length(v, to, from), 100, tolerance = 1e-9,
                   info = paste(from, "->", to))
    }
  }
})

test_that("pixels convert against a stated resolution", {
  # 300 px at 300 dpi is one inch, which is 25.4 mm.
  expect_equal(convert_length(300, "px", "mm", dpi = 300), 25.4)
  expect_equal(convert_length(25.4, "mm", "px", dpi = 300), 300)
  expect_equal(convert_length(1, "in", "px", dpi = 72), 72)
})

test_that("an unsupported unit is refused rather than silently ignored", {
  expect_error(convert_length(10, "furlong", "mm"), class = "figspec_unsupported")
  expect_error(convert_length(10, "mm", "furlong"), class = "figspec_unsupported")
})

test_that("converting pixels without a resolution is a missing argument", {
  expect_error(convert_length(300, "px", "mm"), class = "figspec_missing_arg")
  expect_error(convert_length(10, "mm", "px"), class = "figspec_missing_arg")
})

test_that("conversion is vectorised", {
  expect_equal(convert_length(c(10, 20, 30), "mm", "cm"), c(1, 2, 3))
})

test_that("numbers are formatted without inventing precision", {
  # fmt_num rounds and drops trailing zeros, so a report reads "85" rather
  # than "85.00", while keeping a genuine fraction. It pads to a common width
  # so that a column of numbers lines up in a printed report.
  expect_equal(trimws(fmt_num(85)), "85")
  expect_equal(trimws(fmt_num(85.0)), "85")
  expect_equal(trimws(fmt_num(8.8)), "8.8")
  expect_equal(trimws(fmt_num(0.706, 3)), "0.706")
  expect_equal(trimws(fmt_num(85.04)), "85")
})

test_that("mm() is fmt_num without the padding, for use inside a sentence", {
  # A report column wants the padding; an error message does not.
  expect_equal(mm(8.8), "8.8")
  expect_equal(mm(85), "85")
  expect_false(grepl("^ ", mm(8.8)))
})

test_that("a missing or empty number formats as NA rather than erroring", {
  expect_true(is.na(fmt_num(NULL)))
  expect_true(is.na(fmt_num(numeric(0))))
})
