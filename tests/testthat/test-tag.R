skip_if_not_installed("ggplot2")

p1 <- function() ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
pf <- function() p1() + ggplot2::facet_wrap(~cyl)
label_row <- function(plot, journal = "cell_press") {
  r <- suppressWarnings(fig_check(plot, journal))
  r[r$check == "Panel labels", , drop = FALSE]
}

# The false pass this closes ---------------------------------------------

test_that("a faceted figure's panel labels are checked at all", {
  # Gating on compositions let every faceted figure past unexamined, which is
  # a silent pass on a requirement the journal does state.
  row <- label_row(pf())
  expect_equal(nrow(row), 1L)
  expect_equal(row$status, "fail")
  expect_match(row$actual, "3 panels, none labelled")
})

test_that("a single-panel plot is still not asked to have panel labels", {
  expect_equal(nrow(label_row(p1())), 0L)
})

test_that("an ordinary annotation is not mistaken for panel labels", {
  # One text label per panel is not enough: it has to be a tag sequence.
  # Reading "n=11" as a panel label would be a pass nobody earned.
  annotated <- pf() + ggplot2::geom_text(
    data = data.frame(cyl = c(4, 6, 8), lab = c("n=11", "n=7", "n=14")),
    ggplot2::aes(x = -Inf, y = Inf, label = lab), inherit.aes = FALSE
  )
  expect_equal(label_row(annotated)$status, "fail")
})

test_that("an incomplete tag sequence is not read as labelling", {
  partial <- pf() + ggplot2::geom_text(
    data = data.frame(cyl = c(4, 6, 8), lab = c("A", "B", "D")),
    ggplot2::aes(x = -Inf, y = Inf, label = lab), inherit.aes = FALSE
  )
  expect_equal(label_row(partial)$status, "fail")
})

test_that("labels applied by hand are recognised, brackets and all", {
  for (labs in list(c("(A)", "(B)", "(C)"), c("A.", "B.", "C."),
                    c("A", "B", "C"))) {
    by_hand <- pf() + ggplot2::geom_text(
      data = data.frame(cyl = c(4, 6, 8), lab = labs),
      ggplot2::aes(x = -Inf, y = Inf, label = lab), inherit.aes = FALSE
    )
    expect_equal(label_row(by_hand)$status, "pass")
  }
})

# tag_panels -------------------------------------------------------------

test_that("tag_panels satisfies the journal it was given", {
  expect_equal(label_row(tag_panels(pf(), "cell_press"))$status, "pass")
  expect_match(label_row(tag_panels(pf(), "cell_press"))$actual, "capital letters")
})

test_that("the style comes from the registry, not from a default", {
  # Cell Press states capitals, AGU states lower case. Labelling for one and
  # checking against the other must fail, or the registry is not driving it.
  expect_equal(label_row(tag_panels(pf(), "agu"), "agu")$status, "pass")
  expect_match(label_row(tag_panels(pf(), "agu"), "agu")$actual, "lower-case")
  expect_equal(label_row(tag_panels(pf(), "agu"), "cell_press")$status, "fail")
})

test_that("an explicit level overrides the journal", {
  tagged <- tag_panels(pf(), "cell_press", level = "1")
  expect_match(label_row(tagged, "cell_press")$actual, "numbers")
})

test_that("a journal that states nothing says so rather than passing a default", {
  expect_message(tag_panels(pf(), "plos_one"), "not a requirement of the journal")
})

test_that("every vocabulary produces a complete sequence", {
  expected <- list(A = "(A)", a = "(a)", `1` = "(1)", I = "(I)", i = "(i)")
  for (lv in names(expected)) {
    b <- ggplot2::ggplot_build(tag_panels(pf(), level = lv))
    labs <- b$data[[2]]$label
    expect_length(labs, 3L)
    expect_equal(labs[[1]], expected[[lv]])
  }
})

test_that("facet_grid is labelled across both variables, in draw order", {
  grid <- p1() + ggplot2::facet_grid(am ~ cyl)
  b <- ggplot2::ggplot_build(tag_panels(grid, level = "a"))
  expect_equal(b$data[[2]]$label, paste0("(", letters[1:6], ")"))
})

test_that("strips are removed by default and kept on request", {
  expect_s3_class(tag_panels(pf(), level = "a")$theme$strip.text, "element_blank")
  expect_false(inherits(tag_panels(pf(), level = "a", strips = TRUE)$theme$strip.text,
                        "element_blank"))
})

test_that("a composition is labelled through patchwork's own tags", {
  skip_if_not_installed("patchwork")
  comp <- patchwork::wrap_plots(p1(), p1(), p1())
  expect_equal(label_row(tag_panels(comp, "cell_press"))$status, "pass")
})

test_that("tag_panels refuses what it cannot label", {
  expect_error(tag_panels(p1(), "cell_press"), class = "figspec_bad_input")
  expect_error(tag_panels(pf(), level = "Z"), class = "figspec_bad_input")
  expect_error(tag_panels(42), class = "figspec_bad_input")
})

test_that("more panels than letters is refused, with the way out", {
  many <- ggplot2::ggplot(data.frame(x = 1, y = 1, g = factor(1:30)),
                          ggplot2::aes(x, y)) +
    ggplot2::geom_point() + ggplot2::facet_wrap(~g)
  err <- tryCatch(tag_panels(many, level = "A"), error = conditionMessage)
  expect_match(err, "more than the 26 letters")
  expect_match(err, 'level = "1"')
  expect_silent(tag_panels(many, level = "1"))
})

test_that("a labelled figure still saves and measures", {
  out <- tempfile(fileext = ".png"); on.exit(unlink(out))
  g <- attr(suppressWarnings(
    fig_save(out, tag_panels(pf(), "cell_press"), journal = "cell_press",
             panel_width = 22)
  ), "figspec_geometry")
  expect_true(file.exists(out))
  expect_equal(g$panels_across, 3L)
  expect_equal(g$panel_width_mm, 22, tolerance = 0.05)
})
