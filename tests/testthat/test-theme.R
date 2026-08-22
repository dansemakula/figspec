test_that("theme_journal holds the journal's type floor across all elements", {
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point() +
    ggplot2::labs(title = "T", subtitle = "S", caption = "C") +
    ggplot2::facet_wrap(~cyl) +
    theme_journal("frontiers")
  sizes <- collect_text_sizes(p)
  # Frontiers states a floor of 8 pt.
  expect_gte(min(sizes$size_pt), 8)
})

test_that("theme_journal respects a stated ceiling", {
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point() +
    ggplot2::labs(title = "A title") +
    theme_journal("plos_one")
  sizes <- collect_text_sizes(p)
  expect_lte(max(sizes$size_pt), 12)
  expect_gte(min(sizes$size_pt), 8)
})

test_that("a base_size under the journal minimum warns", {
  expect_warning(theme_journal("frontiers", base_size = 5), "below")
})

test_that("theme_journal builds on a supplied base theme", {
  th <- theme_journal("frontiers", base = ggplot2::theme_minimal())
  expect_s3_class(th, "theme")
})
