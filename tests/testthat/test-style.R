# House styles: registering, applying and removing them, and the rule that one
# may never contain a field fig_check() grades against.

withr::defer(.figspec_cache$styles <- NULL, teardown_env())

test_that("a house style can be registered, listed and removed", {
  style_register("t1", ggplot2::theme_void(), "test style")
  expect_true("t1" %in% style_list()$name)
  style_remove("t1")
  expect_false("t1" %in% style_list()$name)
})

test_that("removing a style cannot silently miss its target", {
  style_register("kept", ggplot2::theme_void(), "keep this style")
  expect_error(
    style_remove("missing"),
    "No house style named.*missing",
    class = "figspec_not_found"
  )
  expect_error(style_remove(character()), class = "figspec_bad_input")
  expect_error(style_remove("unsafe name"), class = "figspec_bad_input")
  expect_true("kept" %in% style_list()$name)
})

test_that("a style's visual choices survive, but its type sizes cannot break compliance", {
  style_register(
    "tiny",
    ggplot2::theme_minimal() +
      ggplot2::theme(panel.grid.minor = ggplot2::element_blank(),
                     axis.text = ggplot2::element_text(size = 5))
  )
  # PLOS ONE states 8-12 pt; the style asks for 5 pt.
  th <- suppressMessages(theme_spec("plos_one", style = "tiny"))
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point() + ggplot2::labs(title = "T") + th
  sizes <- collect_text_sizes(p)

  expect_gte(min(sizes$size_pt), 8)          # journal floor held
  expect_lte(max(sizes$size_pt), 12)         # journal ceiling held
  expect_s3_class(th$panel.grid.minor, "element_blank")  # style choice kept
})

test_that("overridden style elements are reported", {
  style_register("tiny2", ggplot2::theme_minimal() +
                         ggplot2::theme(axis.text = ggplot2::element_text(size = 4)))
  expect_message(theme_spec("plos_one", style = "tiny2"), "axis.text")
})

test_that("relative sizes are not mistaken for point sizes", {
  style_register("relative", ggplot2::theme_minimal())
  expect_silent(theme_spec("plos_one", style = "relative"))
})

test_that("styles accept themes and functions, and reject anything else", {
  expect_silent(style_register("obj", ggplot2::theme_void()))
  expect_silent(style_register("fn", function() ggplot2::theme_void()))
  expect_error(style_register("bad", "not a theme"), "ggplot2 theme")
  expect_error(theme_spec("plos_one", style = "nope"), "No house style")
})

test_that("style descriptions are optional single lines of text", {
  expect_silent(style_register(
    "described",
    ggplot2::theme_void(),
    "Used in research reports"
  ))
  expect_silent(style_register("undescribed", ggplot2::theme_void()))
  expect_error(
    style_register("numeric_description", ggplot2::theme_void(), 1),
    class = "figspec_bad_input"
  )
  expect_error(
    style_register(
      "multiline_description",
      ggplot2::theme_void(),
      "First line\nSecond line"
    ),
    class = "figspec_bad_input"
  )
})

test_that("styles round-trip through a file", {
  style_register("persisted", ggplot2::theme_void(), "keep me")
  f <- withr::local_tempfile(fileext = ".rds")
  style_save(f)
  style_remove("persisted")
  expect_false("persisted" %in% style_list()$name)
  style_load(f, allow_functions = TRUE)
  expect_true("persisted" %in% style_list()$name)
})

test_that("an empty style collection round-trips cleanly", {
  old_styles <- .figspec_cache$styles
  withr::defer(.figspec_cache$styles <- old_styles)
  .figspec_cache$styles <- NULL
  path <- file.path(withr::local_tempdir(), "empty-styles.rds")

  expect_identical(style_save(path), path)
  expect_true(file.size(path) > 0)
  expect_identical(style_load(path), character())
  expect_equal(nrow(style_list()), 0L)
})

test_that("style files enforce safe paths and bounded inputs", {
  root <- withr::local_tempdir()
  expect_error(style_save(character()), class = "figspec_bad_input")
  expect_error(style_save(NA_character_), class = "figspec_bad_input")
  expect_error(
    style_save(file.path(root, "styles.txt")),
    "must end in.*rds",
    class = "figspec_bad_input"
  )
  expect_error(
    style_save(file.path(root, "missing", "styles.rds")),
    class = "figspec_not_found"
  )
  directory <- file.path(root, "directory.rds")
  dir.create(directory)
  expect_error(style_save(directory), "directory", class = "figspec_bad_input")

  empty <- file.path(root, "empty.rds")
  file.create(empty)
  expect_error(style_load(empty), "empty", class = "figspec_bad_input")

  corrupt <- file.path(root, "corrupt.rds")
  writeLines("not an RDS file", corrupt)
  expect_error(
    style_load(corrupt),
    "Could not read styles",
    class = "figspec_bad_input"
  )

  oversized <- file.path(root, "oversized.rds")
  writeBin(raw(figspec:::STYLE_FILE_LIMIT + 1L), oversized)
  expect_error(
    style_load(oversized),
    "larger than 10 MB",
    class = "figspec_bad_input"
  )
})

test_that("style files refuse symbolic links without changing their targets", {
  root <- withr::local_tempdir()
  target <- file.path(root, "target.rds")
  saveRDS(list(), target)
  original <- readBin(target, "raw", n = file.size(target))
  link <- file.path(root, "linked-styles.rds")
  made <- file.symlink(target, link)
  skip_if_not(made, "symbolic links are unavailable on this platform")

  expect_error(style_load(link), "symbolic link", class = "figspec_bad_input")
  expect_error(style_save(link), "symbolic link", class = "figspec_bad_input")
  expect_identical(readBin(target, "raw", n = file.size(target)), original)
})

test_that("malformed style files cannot partly change the session", {
  old_styles <- .figspec_cache$styles
  withr::defer(.figspec_cache$styles <- old_styles)
  .figspec_cache$styles <- NULL
  style_register("already_present", ggplot2::theme_void())
  before <- .figspec_cache$styles
  path <- file.path(withr::local_tempdir(), "malformed-styles.rds")
  saveRDS(
    list(
      valid_first = list(
        name = "valid_first",
        theme = ggplot2::theme_minimal(),
        description = "valid"
      ),
      invalid_second = list(
        name = "wrong_name",
        theme = ggplot2::theme_void(),
        description = "invalid"
      )
    ),
    path
  )

  expect_error(style_load(path), class = "figspec_bad_input")
  expect_identical(.figspec_cache$styles, before)
  expect_false("valid_first" %in% style_list()$name)

  duplicate <- list(
    same = list(name = "same", theme = ggplot2::theme_void(), description = "a"),
    same = list(name = "same", theme = ggplot2::theme_void(), description = "b")
  )
  saveRDS(duplicate, path)
  expect_error(style_load(path), "unique", class = "figspec_bad_input")
  expect_identical(.figspec_cache$styles, before)
})

test_that("style loading requires an explicit logical code permission", {
  path <- file.path(withr::local_tempdir(), "ordinary-style.rds")
  saveRDS(
    list(ordinary = list(
      name = "ordinary",
      theme = ggplot2::theme_void(),
      description = "ordinary theme"
    )),
    path
  )
  for (value in list(NA, 1, "yes", logical())) {
    expect_error(
      style_load(path, allow_functions = value),
      class = "figspec_bad_input"
    )
  }
})

test_that("saved theme functions require explicit permission to load", {
  style_register("stored_function", function() ggplot2::theme_minimal())
  f <- withr::local_tempfile(fileext = ".rds")
  style_save(f)
  style_remove("stored_function")

  expect_error(
    style_load(f),
    "executable R code",
    class = "figspec_bad_input"
  )
  expect_false("stored_function" %in% style_list()$name)

  loaded <- style_load(f, allow_functions = TRUE)
  expect_true("stored_function" %in% loaded)
  expect_s3_class(resolve_style("stored_function"), "theme")
})

test_that("a style can be given as a name, a theme, or a function", {
  skip_if_not_installed("ggplot2")
  on.exit(suppressMessages(try(style_remove("lab"), silent = TRUE)), add = TRUE)
  style_register("lab", ggplot2::theme_minimal())

  expect_s3_class(resolve_style("lab"), "theme")
  expect_s3_class(resolve_style(ggplot2::theme_bw()), "theme")
  expect_s3_class(resolve_style(function() ggplot2::theme_void()), "theme")
  expect_null(resolve_style(NULL))
})

test_that("a style registered as a function is called when it is resolved", {
  # Registering a function rather than a theme lets a style pick up options
  # set after registration, so it must not be evaluated until it is used.
  skip_if_not_installed("ggplot2")
  on.exit(suppressMessages(try(style_remove("lazy"), silent = TRUE)), add = TRUE)
  calls <- 0
  style_register("lazy", function() { calls <<- calls + 1; ggplot2::theme_bw() })
  expect_equal(calls, 1)
  resolve_style("lazy")
  expect_equal(calls, 2)
})

test_that("an unregistered style names the ones that are registered", {
  skip_if_not_installed("ggplot2")
  on.exit(suppressMessages(try(style_remove("known"), silent = TRUE)), add = TRUE)
  style_register("known", ggplot2::theme_bw())
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
  on.exit(suppressMessages(try(style_remove("big"), silent = TRUE)), add = TRUE)
  # A style asking for 20 pt text cannot stand against PLOS ONE's 8 to 12.
  style_register("big", ggplot2::theme_grey(base_size = 20))
  msg <- capture.output(theme_spec("plos_one", style = "big"), type = "message")
  expect_match(paste(msg, collapse = " "), "override|overrides")
})
