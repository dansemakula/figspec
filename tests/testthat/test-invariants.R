# The integrity rules the whole package rests on, checked across every entry
# in the registry rather than trusted at each call site.

variant_plots <- function() {
  base <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg))
  list(
    plain = base + ggplot2::geom_point(),
    coloured = ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) +
      ggplot2::geom_point(),
    hollow = base + ggplot2::geom_point(shape = 1),
    lines = ggplot2::ggplot(ggplot2::economics, ggplot2::aes(date, unemploy)) +
      ggplot2::geom_line(),
    titled = base + ggplot2::geom_point() +
      ggplot2::labs(title = "Fuel Economy By Cylinder.", y = "Miles Per Gallon")
  )
}

test_that("a requirement the publisher never stated is never passed or failed", {
  for (id in journals()$id) {
    for (nm in names(variant_plots())) {
      r <- suppressMessages(check_journal(variant_plots()[[nm]], id))
      offenders <- r[r$requirement == "not specified by publisher" &
                       r$status %in% c("pass", "fail"), ]
      expect_equal(
        nrow(offenders), 0,
        info = paste0(id, " / ", nm, ": ",
                      paste(offenders$check, collapse = ", "))
      )
    }
  }
})

test_that("every status is one of the four defined outcomes", {
  for (id in journals()$id) {
    r <- suppressMessages(check_journal(variant_plots()$coloured, id))
    expect_true(all(r$status %in% c("pass", "fail", "unspecified", "unknown")),
                info = id)
  }
})

test_that("new_row() refuses to grade an unstated requirement", {
  # Even when a call site computes a verdict, an unstated requirement wins.
  row <- new_row("Test", "not specified by publisher", "something", "pass")
  expect_equal(row$status, "unspecified")
  row2 <- new_row("Test", "not specified by publisher", "something", "fail")
  expect_equal(row2$status, "unspecified")
  # A stated requirement grades normally.
  row3 <- new_row("Test", "min 8 pt", "6 pt", "fail")
  expect_equal(row3$status, "fail")
})

test_that("a vector file does not pass a resolution rule that does not exist", {
  f <- withr::local_tempfile(fileext = ".pdf")
  ggplot2::ggsave(f, variant_plots()$plain, width = 85, height = 60, units = "mm")
  # Royal Society states no minimum resolution.
  r <- check_journal(f, "royal_society")
  expect_equal(r[r$check == "Resolution", ]$status, "unspecified")
  # Cell Press does state one, so a vector file passes it.
  r2 <- check_journal(f, "cell_press")
  expect_equal(r2[r2$check == "Resolution", ]$status, "pass")
})

test_that("every registry entry still carries its provenance", {
  for (j in load_registry()) {
    expect_true(nzchar(j$source_url), info = j$id)
    expect_match(as.character(j$verified_on), "^\\d{4}-\\d{2}-\\d{2}$", info = j$id)
  }
})

test_that("no recorded resolution quote is a publisher's own rendering pipeline", {
  # Several publishers describe how THEY render articles (PNAS at 200 ppi, OUP
  # proofs at 200 dpi). Those are not author requirements and must never end up
  # in a recorded quote.
  for (j in load_registry()) {
    q <- j$source_quote_dpi
    if (is.null(q)) next
    expect_false(grepl("proof|processed to display|HTML display", q, ignore.case = TRUE),
                 info = j$id)
    expect_false(grepl("\\b200\\s*(dpi|ppi)", q, ignore.case = TRUE), info = j$id)
  }
})

# The registry's policy for hedged wording, pinned across every case that
# prompted it. See RECORDING HEDGED WORDING in inst/extdata/journals.yaml.

test_that("a hedge about the document does not downgrade a rule inside it", {
  # OUP calls its whole guide "tips rather than strict rules" and still states
  # "at least 300dpi". Confirmed by the maintainer: graded.
  expect_equal(journal_spec("oup")$dpi_min, 300)
  expect_match(journal_spec("oup")$notes, "tips rather than strict rules")

  path <- withr::local_tempfile(fileext = ".png")
  grDevices::png(path, width = 84, height = 60, units = "mm", res = 150)
  plot(mtcars$wt, mtcars$mpg)
  grDevices::dev.off()
  r <- check_journal(path, "oup", dpi = 150)
  expect_equal(r[r$check == "Resolution", ]$status, "fail")
})

test_that("a hedge about achievability does not downgrade a rule", {
  # Elsevier calls its lettering target "a rule-of-thumb rather than a strict
  # rule" and still says "no smaller than 6 pt".
  expect_equal(journal_spec("elsevier")$font_min_pt, 6)
  expect_match(journal_spec("elsevier")$notes, "rule-of-thumb")
})

test_that("a rule whose main verb is a recommendation is never graded", {
  # Sage: "We recommend having no more than 7 series".
  s <- journal_spec("sage")
  expect_equal(s$max_series_recommended, 7)
  expect_false("max_series_recommended" %in% requirement_keys())

  many <- data.frame(x = rep(1:5, 10), y = rep(1:10, each = 5),
                     g = factor(rep(LETTERS[1:10], each = 5)))
  p <- ggplot2::ggplot(many, ggplot2::aes(x, y, colour = g)) + ggplot2::geom_line()
  row <- check_journal(p, "sage")[check_journal(p, "sage")$check == "Series count", ]
  expect_equal(row$status, "unspecified")
  expect_match(row$actual, "above the 7 recommended")
})

test_that("softened wording around a directive verb is still graded", {
  # MDPI: "should be ... preferably no less than 600 dpi". The verb is should.
  expect_equal(journal_spec("mdpi")$dpi_min, 600)
  # Springer: "usually about 2-3 mm (8-12 pt)".
  expect_equal(journal_spec("springer")$font_min_pt, 8)
})

test_that("a list is recorded only where the publisher closes it", {
  # PLOS closes its set: "Use only Arial, Times, or Symbol font".
  expect_setequal(unlist(journal_spec("plos_one")$font_families),
                  c("Arial", "Times", "Symbol"))
  # ACS says they "work well"; Springer that it "is best to use" them. Neither
  # excludes anything, so neither is recorded.
  expect_null(journal_spec("acs")$font_families)
  expect_null(journal_spec("springer")$font_families)
})

test_that("an advisory field never appears among the graded requirement keys", {
  advisory <- c("max_series_recommended")
  expect_length(intersect(advisory, requirement_keys()), 0)
})

test_that("the README lists every journal in the registry", {
  skip_if_not(file.exists("../../README.md"), "README not available in this check")
  readme <- readLines("../../README.md", warn = FALSE)
  ids <- names(load_registry())
  # The table is generated by data-raw/make-journal-table.R. If an entry is
  # added and the table is not regenerated, the README quietly understates what
  # the package covers.
  for (id in ids) {
    expect_true(any(grepl(paste0("`", id, "`"), readme, fixed = TRUE)),
                info = paste("missing from README table:", id))
  }
})
