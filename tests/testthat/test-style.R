# House styles: registering, applying and removing them, and the rule that one
# may never contain a field fig_check() grades against.

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

test_that("a style can be given as a name, a theme, or a function", {
  skip_if_not_installed("ggplot2")
  on.exit(suppressMessages(try(remove_house_style("lab"), silent = TRUE)), add = TRUE)
  register_house_style("lab", ggplot2::theme_minimal())

  expect_s3_class(resolve_style("lab"), "theme")
  expect_s3_class(resolve_style(ggplot2::theme_bw()), "theme")
  expect_s3_class(resolve_style(function() ggplot2::theme_void()), "theme")
  expect_null(resolve_style(NULL))
})

test_that("a style registered as a function is called when it is resolved", {
  # Registering a function rather than a theme lets a style pick up options
  # set after registration, so it must not be evaluated until it is used.
  skip_if_not_installed("ggplot2")
  on.exit(suppressMessages(try(remove_house_style("lazy"), silent = TRUE)), add = TRUE)
  calls <- 0
  register_house_style("lazy", function() { calls <<- calls + 1; ggplot2::theme_bw() })
  expect_equal(calls, 0)
  resolve_style("lazy")
  expect_equal(calls, 1)
})

test_that("an unregistered style names the ones that are registered", {
  skip_if_not_installed("ggplot2")
  on.exit(suppressMessages(try(remove_house_style("known"), silent = TRUE)), add = TRUE)
  register_house_style("known", ggplot2::theme_bw())
  err <- tryCatch(resolve_style("missing"), error = function(e) e)
  expect_s3_class(err, "figspec_not_found")
  expect_match(conditionMessage(err), "known")
})

test_that("a style of the wrong kind is refused with what was given", {
  err <- tryCatch(resolve_style(42), error = function(e) e)
  expect_s3_class(err, "figspec_bad_input")
  expect_match(conditionMessage(err), "numeric")
})

test_that("the journal's type sizes displace a style's, and the caller is told", {
  skip_if_not_installed("ggplot2")
  on.exit(suppressMessages(try(remove_house_style("big"), silent = TRUE)), add = TRUE)
  # A style asking for 20 pt text cannot stand against PLOS ONE's 8 to 12.
  register_house_style("big", ggplot2::theme_grey(base_size = 20))
  msg <- capture.output(theme_journal("plos_one", style = "big"), type = "message")
  expect_match(paste(msg, collapse = " "), "override|overrides")
})
