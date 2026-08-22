base_plot <- function() {
  ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
}

test_that("panels are counted through a nested composition", {
  skip_if_not_installed("patchwork")
  p <- base_plot()
  expect_equal(count_panels(p), 1L)
  expect_equal(count_panels(patchwork::wrap_plots(p, p)), 2L)
  expect_equal(count_panels((p | p) / p), 3L)
})

test_that("Cell Press requires capital-letter panel labels", {
  skip_if_not_installed("patchwork")
  p <- base_plot()
  comp <- (p | p) / p

  unlabelled <- check_journal(comp, "cell_press")
  expect_equal(unlabelled[unlabelled$check == "Panel labels", ]$status, "fail")

  capitals <- check_journal(comp + patchwork::plot_annotation(tag_levels = "A"),
                            "cell_press")
  expect_equal(capitals[capitals$check == "Panel labels", ]$status, "pass")

  numbers <- check_journal(comp + patchwork::plot_annotation(tag_levels = "1"),
                           "cell_press")
  expect_equal(numbers[numbers$check == "Panel labels", ]$status, "fail")
})

test_that("a single-panel figure raises no panel-label check", {
  r <- check_journal(base_plot(), "cell_press")
  expect_false("Panel labels" %in% r$check)
})

test_that("Nature's sentence-case rule catches full stops and Title Case", {
  bad <- base_plot() + ggplot2::labs(title = "Fuel economy.",
                                     y = "Miles Per Gallon")
  r <- check_journal(bad, "nature")
  row <- r[r$check == "Text case", ]
  expect_equal(row$status, "fail")
  expect_match(row$actual, "full stop")
  expect_match(row$actual, "Title Case")
})

test_that("clean sentence case passes", {
  good <- base_plot() + ggplot2::labs(title = "Fuel economy",
                                      x = "Weight (1000 lbs)",
                                      y = "Miles per gallon")
  r <- check_journal(good, "nature")
  expect_equal(r[r$check == "Text case", ]$status, "pass")
})

test_that("acronyms and short words are not mistaken for Title Case", {
  expect_false(is_title_case("Body mass index (BMI)"))
  expect_false(is_title_case("CO2 emissions per capita"))
  expect_false(is_title_case("Weight (1000 lbs)"))
  expect_true(is_title_case("Miles Per Gallon"))
  expect_true(is_title_case("Body Mass Index"))
})

test_that("a journal that states no text rule reports unspecified", {
  bad <- base_plot() + ggplot2::labs(title = "Fuel economy.")
  r <- check_journal(bad, "frontiers")
  expect_equal(r[r$check == "Text case", ]$status, "unspecified")
})

test_that("ellipsis is not treated as a final full stop", {
  expect_false(has_final_stop("Loading..."))
  expect_true(has_final_stop("A sentence."))
})
