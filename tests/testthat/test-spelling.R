# figspec is written in British English. An American speller typing `color`
# gets no help from R: `color` is not a prefix of `colour` - the spellings
# diverge at the fifth letter - so neither partial argument matching nor
# match.arg() reaches it. Every surface a caller can type has to be covered
# deliberately, and these tests are what keeps that true as the API grows.

# Every British/American pair that could plausibly appear in an R API name.
SPELLING_PAIRS <- list(
  c("colour", "color"), c("grey", "gray"), c("centre", "center"),
  c("licence", "license"), c("catalogue", "catalog"),
  c("analyse", "analyze"), c("normalise", "normalize"),
  c("summarise", "summarize"), c("behaviour", "behavior"),
  c("labelled", "labeled"), c("modelling", "modeling"),
  c("neighbour", "neighbor"), c("standardise", "standardize")
)

exported <- function() sort(getNamespaceExports("figspec"))

test_that("the sweep below actually has something to inspect", {
  # A loop over an empty set passes without testing anything. If a rename ever
  # empties these, the sweeps above stop guarding and this says so.
  n_names <- sum(vapply(SPELLING_PAIRS, function(p)
    length(grep(p[1], exported(), fixed = TRUE)), integer(1)))
  n_args <- sum(vapply(exported(), function(nm) {
    f <- get(nm, envir = asNamespace("figspec"))
    if (!is.function(f)) return(0L)
    sum(vapply(SPELLING_PAIRS, function(p)
      length(grep(p[1], names(formals(f)), fixed = TRUE)), integer(1)))
  }, integer(1)))
  expect_gt(n_names, 0)
  expect_gt(n_args, 0)
})

test_that("every exported name with a British spelling has an American twin", {
  for (pair in SPELLING_PAIRS) {
    for (nm in grep(pair[1], exported(), value = TRUE, fixed = TRUE)) {
      twin <- sub(pair[1], pair[2], nm, fixed = TRUE)
      expect_true(twin %in% exported(),
                  info = paste0(nm, " has no ", twin))
    }
  }
})

test_that("an American twin points at the same function, not a copy", {
  for (pair in SPELLING_PAIRS) {
    for (nm in grep(pair[1], exported(), value = TRUE, fixed = TRUE)) {
      twin <- sub(pair[1], pair[2], nm, fixed = TRUE)
      if (!twin %in% exported()) next
      expect_identical(get(nm, envir = asNamespace("figspec")),
                       get(twin, envir = asNamespace("figspec")),
                       info = paste(nm, "and", twin, "have drifted apart"))
    }
  }
})

test_that("every argument with a British spelling has an American twin", {
  for (nm in exported()) {
    f <- get(nm, envir = asNamespace("figspec"))
    if (!is.function(f)) next
    args <- names(formals(f))
    for (pair in SPELLING_PAIRS) {
      for (a in grep(pair[1], args, value = TRUE, fixed = TRUE)) {
        twin <- sub(pair[1], pair[2], a, fixed = TRUE)
        expect_true(twin %in% args,
                    info = paste0(nm, "(", a, ") has no ", twin))
      }
    }
  }
})

test_that("every documented option value with a British spelling accepts both", {
  # Values a caller types are as much an API as argument names. Any new
  # choice-set carrying a British spelling should be added to this test and
  # routed through british_spelling().
  skip_if_not_installed("ggplot2")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  expect_identical(
    check_journal(p, "cell_press", art_type = "color"),
    check_journal(p, "cell_press", art_type = "colour")
  )
})

test_that("a value with no British spelling is untouched", {
  expect_identical(british_spelling(c("bw", "line", "combination")),
                   c("bw", "line", "combination"))
  expect_identical(british_spelling("colour"), "colour")
  expect_identical(british_spelling("color"), "colour")
  expect_identical(british_spelling(42), 42)
})

test_that("a genuine typo is still an error, not silently corrected", {
  skip_if_not_installed("ggplot2")
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
  expect_error(check_journal(p, "cell_press", art_type = "colr"))
})

test_that("colour arguments answer to the American spelling", {
  skip_if_not_installed("ggplot2")
  expect_no_error(fit_journal("plos_one", color = FALSE))
  expect_equal(length(fit_journal("plos_one", color = FALSE)),
               length(fit_journal("plos_one", colour = FALSE)))
})
