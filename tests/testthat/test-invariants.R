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
