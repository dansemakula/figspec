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

test_that("no verdict is claimed where the publisher states no text rule", {
  # Title Case with a full stop, checked against a journal that says nothing.
  bad <- base_plot() + ggplot2::labs(title = "Fuel Economy By Cylinder Count.")
  r <- check_journal(bad, "cell_press")
  row <- r[r$check == "Text case", ]
  expect_equal(row$status, "unspecified")
  expect_match(row$actual, "not checked")
  expect_false(grepl("follow sentence case", row$actual))
})

test_that("axes that exclude zero are found, with log axes exempt", {
  scatter <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  expect_setequal(axes_missing_zero(scatter), c("x", "y"))

  # A bar chart's count axis starts at zero.
  bars <- ggplot2::ggplot(mtcars, ggplot2::aes(factor(cyl))) + ggplot2::geom_bar()
  expect_length(axes_missing_zero(bars), 0)

  # Zero is not on a log scale, so a log axis cannot be asked to reach it.
  logged <- scatter + ggplot2::scale_y_log10()
  expect_equal(axes_missing_zero(logged), "x")

  expect_length(axes_missing_zero(scatter + ggplot2::expand_limits(x = 0, y = 0)), 0)
})

test_that("a discrete axis is not asked to reach zero", {
  # A factor axis is not numeric, so the rule cannot apply to it.
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(factor(cyl), mpg)) + ggplot2::geom_col()
  expect_false("x" %in% axes_missing_zero(p))
})

test_that("PNAS states the axis rule and is checked against it", {
  scatter <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  r <- check_journal(scatter, "pnas", column = "medium")
  row <- r[r$check == "Axis origin", ]
  expect_equal(row$status, "fail")
  expect_match(row$actual, "does not reach zero")

  fixed <- scatter + ggplot2::expand_limits(x = 0, y = 0)
  expect_equal(check_journal(fixed, "pnas", column = "medium")[
    check_journal(fixed, "pnas", column = "medium")$check == "Axis origin", ]$status, "pass")
})

test_that("journals that state no axis rule raise no axis check", {
  scatter <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  expect_false("Axis origin" %in% check_journal(scatter, "plos_one")$check)
  expect_false("Axis origin" %in% check_journal(scatter, "cell_press")$check)
})

test_that("PNAS resolution now comes from the Digital Art Guidelines", {
  p <- journal_spec("pnas")
  expect_equal(p$dpi_min, 300)          # images with no type
  expect_equal(p$dpi_combination, 600)  # images with type, floor of 600-900
  expect_equal(p$dpi_line_art, 1000)    # floor of 1000-1200
  expect_equal(unlist(p$colour_mode), "RGB")
})
