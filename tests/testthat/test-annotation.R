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

test_that("panels are counted correctly through every composition shape", {
  skip_if_not_installed("patchwork")
  p <- base_plot()
  # A patchwork keeps its most recent plot in its own slots. Where both
  # operands are patchworks that slot holds no plot, and counting it invents a
  # panel. This was a real off-by-one.
  expect_equal(count_parts(p | p), 2L)
  expect_equal(count_parts((p | p) / p), 3L)
  expect_equal(count_parts(p | p | p), 3L)
  expect_equal(count_parts((p | p) / (p | p)), 4L)
  expect_equal(count_parts((p | p | p) / (p | p | p)), 6L)
  expect_equal(count_parts(patchwork::wrap_plots(p, p, p, p, p, p)), 6L)
})

test_that("facets count as parts but not as labelled panels", {
  # A faceted plot is one object drawn as several panels. RSC limits the parts
  # a reader sees; Cell Press labels composed sub-figures. Different questions.
  faceted <- base_plot() + ggplot2::facet_wrap(~cyl)
  expect_equal(count_parts(faceted), 3L)
  expect_equal(count_panels(faceted), 1L)
})

test_that("RSC's four-part limit is enforced", {
  skip_if_not_installed("patchwork")
  p <- base_plot()
  within <- check_journal((p | p) / p, "rsc_books")
  expect_equal(within[within$check == "Panel count", ]$status, "pass")
  expect_equal(within[within$check == "Panel count", ]$actual, "3 parts")

  over <- check_journal((p | p | p) / (p | p | p), "rsc_books")
  expect_equal(over[over$check == "Panel count", ]$status, "fail")
  expect_equal(over[over$check == "Panel count", ]$actual, "6 parts")

  # A faceted plot with too many facets is also too many parts.
  expect_equal(check_journal(p + ggplot2::facet_wrap(~carb), "rsc_books")[
    check_journal(p + ggplot2::facet_wrap(~carb), "rsc_books")$check == "Panel count", ]$status,
    "fail")
})

test_that("journals that state no panel limit raise no panel-count check", {
  expect_false("Panel count" %in% check_journal(base_plot(), "plos_one")$check)
})

test_that("RSC's entry names its scope as books, not journals", {
  expect_match(journal_spec("rsc_books")$name, "books")
  expect_match(journal_spec("rsc_books")$notes, "not journals")
  expect_null(journal_spec("rsc_books")$print_greyscale)
})

test_that("Nature requires axis lines, which ggplot2's default theme omits", {
  p <- base_plot()
  # theme_grey draws tick marks but no axis line, using the panel border, so
  # this is a real requirement rather than a formality.
  expect_equal(missing_axis_furniture(p), "axis lines")
  r <- check_journal(p, "nature")
  expect_equal(r[r$check == "Axis furniture", ]$status, "fail")
  expect_match(r[r$check == "Axis furniture", ]$actual, "missing axis lines")
})

test_that("theme_journal satisfies the axis requirement rather than only reporting it", {
  fixed <- base_plot() + theme_journal("nature")
  expect_length(missing_axis_furniture(fixed), 0)
  expect_equal(check_journal(fixed, "nature")[
    check_journal(fixed, "nature")$check == "Axis furniture", ]$status, "pass")
})

test_that("both pieces of axis furniture are reported when both are missing", {
  bare <- base_plot() + ggplot2::theme_void()
  expect_setequal(missing_axis_furniture(bare), c("axis lines", "tick marks"))
})

test_that("coloured text fails Nature, and grey text does not", {
  base <- base_plot() + theme_journal("nature")
  expect_equal(check_journal(base, "nature")[
    check_journal(base, "nature")$check == "Text colour", ]$status, "pass")

  red <- base + ggplot2::theme(text = ggplot2::element_text(colour = "red"))
  expect_equal(check_journal(red, "nature")[
    check_journal(red, "nature")$check == "Text colour", ]$status, "fail")

  # A grey has equal channels, so it is not a hue.
  grey <- base + ggplot2::theme(text = ggplot2::element_text(colour = "grey30"))
  expect_equal(check_journal(grey, "nature")[
    check_journal(grey, "nature")$check == "Text colour", ]$status, "pass")
  expect_false(is_coloured("grey30"))
  expect_true(is_coloured("red"))
})

test_that("journals stating no axis or text-colour rule raise no such checks", {
  p <- base_plot()
  r <- check_journal(p, "plos_one")
  expect_false("Axis furniture" %in% r$check)
  expect_false("Text colour" %in% r$check)
})

test_that("Nature labels panels in lower case, like AGU and unlike Cell Press", {
  skip_if_not_installed("patchwork")
  p <- base_plot(); comp <- (p | p) / p
  lower <- check_journal(comp + patchwork::plot_annotation(tag_levels = "a"), "nature")
  expect_equal(lower[lower$check == "Panel labels", ]$status, "pass")
  upper <- check_journal(comp + patchwork::plot_annotation(tag_levels = "A"), "nature")
  expect_equal(upper[upper$check == "Panel labels", ]$status, "fail")
})

test_that("a comma thousands separator fails the Royal Society's number rule", {
  d <- data.frame(x = c(1e3, 5e6, 1e7), y = c(1, 2, 3))
  base <- ggplot2::ggplot(d, ggplot2::aes(x, y)) + ggplot2::geom_point()

  commas <- base + ggplot2::scale_x_continuous(labels = scales::comma)
  expect_gt(length(labels_with_comma_thousands(commas)), 0)
  r <- check_journal(commas, "royal_society")
  expect_equal(r[r$check == "Number format", ]$status, "fail")
  expect_match(r[r$check == "Number format", ]$actual, "comma used")

  spaced <- base + ggplot2::scale_x_continuous(
    labels = function(v) format(v, big.mark = " ", scientific = FALSE))
  expect_length(labels_with_comma_thousands(spaced), 0)
  expect_equal(check_journal(spaced, "royal_society")[
    check_journal(spaced, "royal_society")$check == "Number format", ]$status, "pass")
})

test_that("a decimal is not mistaken for a thousands separator", {
  # The pattern requires exactly three digits after the comma, so a decimal
  # comma or a short number does not match.
  expect_false(grepl("[0-9],[0-9]{3}", "1,5"))
  expect_false(grepl("[0-9],[0-9]{3}", "0,25"))
  expect_true(grepl("[0-9],[0-9]{3}", "10,000"))
})

test_that("only journals stating a number rule are checked against one", {
  d <- data.frame(x = c(1e3, 5e6, 1e7), y = c(1, 2, 3))
  commas <- ggplot2::ggplot(d, ggplot2::aes(x, y)) + ggplot2::geom_point() +
    ggplot2::scale_x_continuous(labels = scales::comma)
  expect_false("Number format" %in% check_journal(commas, "plos_one")$check)
})

test_that("Nature and the Royal Society require opposite panel-label styling", {
  # Both want lower-case letters, but Nature specifies upright and the Royal
  # Society italicised. figspec reads the tag level, not the styling, so both
  # record lowercase and neither italic rule is checked. The conflict is real
  # and is recorded in the entries.
  expect_equal(journal_spec("nature")$panel_labels, "lowercase")
  expect_equal(journal_spec("royal_society")$panel_labels, "lowercase")
  expect_match(journal_spec("nature")$source_quote_panel_labels, "upright \\(not italic\\)")
  expect_match(journal_spec("royal_society")$source_quote_panel_labels, "italicized")
  expect_match(journal_spec("royal_society")$notes, "conflict|Nature requires")
})

test_that("the Royal Society requires tables as editable text", {
  ts <- table_spec("royal_society")
  expect_equal(ts$format, "editable")
  expect_match(ts$source_quote, "editable format")
})
