withr::defer(.figspec_cache$styles <- NULL, teardown_env())

test_that("a house style can be registered, listed and removed", {
  register_house_style("t1", ggplot2::theme_void(), "test style")
  expect_true("t1" %in% house_styles()$name)
  remove_house_style("t1")
  expect_false("t1" %in% house_styles()$name)
})

test_that("a style's visual choices survive, but its type sizes cannot break compliance", {
  register_house_style(
    "tiny",
    ggplot2::theme_minimal() +
      ggplot2::theme(panel.grid.minor = ggplot2::element_blank(),
                     axis.text = ggplot2::element_text(size = 5))
  )
  # PLOS ONE states 8-12 pt; the style asks for 5 pt.
  th <- suppressMessages(theme_journal("plos_one", style = "tiny"))
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point() + ggplot2::labs(title = "T") + th
  sizes <- collect_text_sizes(p)

  expect_gte(min(sizes$size_pt), 8)          # journal floor held
  expect_lte(max(sizes$size_pt), 12)         # journal ceiling held
  expect_s3_class(th$panel.grid.minor, "element_blank")  # style choice kept
})

test_that("overridden style elements are reported", {
  register_house_style("tiny2", ggplot2::theme_minimal() +
                         ggplot2::theme(axis.text = ggplot2::element_text(size = 4)))
  expect_message(theme_journal("plos_one", style = "tiny2"), "axis.text")
})

test_that("relative sizes are not mistaken for point sizes", {
  register_house_style("relative", ggplot2::theme_minimal())
  expect_silent(theme_journal("plos_one", style = "relative"))
})

test_that("styles accept themes and functions, and reject anything else", {
  expect_silent(register_house_style("obj", ggplot2::theme_void()))
  expect_silent(register_house_style("fn", function() ggplot2::theme_void()))
  expect_error(register_house_style("bad", "not a theme"), "ggplot2 theme")
  expect_error(theme_journal("plos_one", style = "nope"), "No house style")
})

test_that("styles round-trip through a file", {
  register_house_style("persisted", ggplot2::theme_void(), "keep me")
  f <- withr::local_tempfile(fileext = ".rds")
  save_house_styles(f)
  remove_house_style("persisted")
  expect_false("persisted" %in% house_styles()$name)
  load_house_styles(f)
  expect_true("persisted" %in% house_styles()$name)
})
