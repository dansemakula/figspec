# Reading values out of a specification: column widths, the columns a journal
# offers, and the printed form of a specification.
#
# The behaviour under test throughout is that a question the specification
# cannot answer is answered by saying so, never by substituting a plausible
# number.

test_that("a named column resolves to the width the publisher states", {
  expect_equal(fig_width("cell_press", "single", "mm"), 85)
  expect_equal(fig_width("cell_press", "double", "mm"), 174)
})

test_that("width converts to the unit asked for", {
  mm <- fig_width("cell_press", "single", "mm")
  expect_equal(fig_width("cell_press", "single", "in"), mm / 25.4)
  expect_equal(fig_width("cell_press", "single", "cm"), mm / 10)
})

test_that("every column a journal offers is listed, in order", {
  cols <- fig_columns("cell_press")
  expect_named(cols, c("single", "onehalf", "double"))
  expect_true(all(diff(unname(cols)) > 0))
})

test_that("a column the journal does not state names the ones it does", {
  # PNAS uses its own vocabulary rather than single and double, so asking for
  # a "double" column must not silently return some other width.
  err <- tryCatch(fig_width("pnas", "double"), error = function(e) e)
  expect_s3_class(err, "figspec_not_found")
  msg <- conditionMessage(err)
  expect_match(msg, "small|medium|large")
})

test_that("a journal stating a range rather than columns says so", {
  # Taylor & Francis gives a minimum and a maximum, so there is no named
  # column to return and NULL is the honest answer.
  expect_message(out <- fig_columns("taylor_francis"), "range")
  expect_null(out)
})

test_that("a specification prints its provenance", {
  out <- capture.output(print(journal_spec("cell_press")), type = "message")
  txt <- paste(out, collapse = " ")
  expect_match(txt, "Cell Press")
  expect_match(txt, "cell.com")
  expect_match(txt, "2026")
})

test_that("table requirements print where a journal states them", {
  out <- capture.output(print(table_spec("nature")), type = "message")
  expect_gt(length(out), 1)
})

test_that("a journal with no table requirements says so rather than printing nothing", {
  expect_message(out <- table_spec("cell_press"), "table")
  expect_null(out)
})
