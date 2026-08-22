test_that("a confirmed-absent field and an unharvested field are told apart", {
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()

  # Frontiers: the harvest notes record file size as NOT STATED.
  fr <- check_journal(p, "frontiers")
  expect_equal(fr[fr$check == "File size", ]$requirement, "not specified by publisher")
  expect_equal(fr[fr$check == "File size", ]$status, "unspecified")

  # Nature: nobody has harvested its file-size rule. That is a fact about the
  # registry, not about Nature.
  na <- check_journal(p, "nature")
  expect_equal(na[na$check == "File size", ]$requirement, "not yet harvested for this journal")
  expect_equal(na[na$check == "File size", ]$status, "unknown")
})

test_that("an unharvested requirement is never passed or failed", {
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) +
    ggplot2::geom_point()
  for (id in journals()$id) {
    r <- suppressMessages(check_journal(p, id))
    bad <- r[r$requirement == "not yet harvested for this journal" &
               r$status %in% c("pass", "fail"), ]
    expect_equal(nrow(bad), 0, info = paste(id, paste(bad$check, collapse = ", ")))
  }
})

test_that("new_row refuses to grade an unharvested requirement", {
  expect_equal(new_row("T", "not yet harvested for this journal", "x", "pass")$status,
               "unknown")
})

test_that("a field cannot be both stated and confirmed absent", {
  expect_error(
    register_journal("clash", "Clash", "u", "2026-08-22",
                     requirements = list(dpi_min = 300),
                     not_stated = list("dpi_min")),
    "cannot both be absent"
  )
})

test_that("registry_status reports age and how much is harvested", {
  st <- registry_status(as_of = as.Date("2026-08-22"))
  expect_true(all(c("id","age_days","stale","stated","confirmed_absent","unharvested")
                  %in% names(st)))
  expect_equal(nrow(st), length(load_registry()))
  # Nature was harvested from the formatting guide only, so most fields are open.
  nat <- st[st$id == "nature", ]
  expect_gt(nat$unharvested, nat$stated)
  # Every field is accounted for in exactly one of the three states.
  expect_true(all(st$stated + st$confirmed_absent + st$unharvested ==
                    length(requirement_keys())))
})

test_that("stale entries are surfaced rather than left to rot", {
  expect_message(stale_entries(max_age_days = 0), "due a recheck")
  expect_message(stale_entries(max_age_days = 100000), "No registry entry is older")
})

test_that("a contributor file is validated before it is trusted", {
  good <- withr::local_tempfile(fileext = ".yaml")
  writeLines(c("journals:",
               "- id: good_one",
               "  name: Good",
               "  source_url: https://example.org/guide",
               "  verified_on: '2026-08-22'",
               "  requirements:",
               "    dpi_min: 300"), good)
  expect_true(validate_registry_file(good))

  bad <- withr::local_tempfile(fileext = ".yaml")
  writeLines(c("journals:",
               "- id: bad_one",
               "  name: Bad",
               "  verified_on: 'last Tuesday'",
               "  requirements:",
               "    made_up_field: 3",
               "  house_style:",
               "    font_min_pt: 4"), bad)
  expect_message(res <- validate_registry_file(bad), "problem")
  expect_false(res)
})

test_that("the skeleton names every field a contributor must consider", {
  tmpl <- capture.output(new_journal_entry("x", "X", "https://example.org"))
  joined <- paste(tmpl, collapse = "\n")
  for (f in c("columns", "dpi_min", "formats", "font_min_pt", "colour_mode",
              "min_line_pt", "not_stated")) {
    expect_match(joined, f, fixed = TRUE)
  }
  expect_match(joined, "not yet harvested", fixed = TRUE)
})

test_that("printing a spec distinguishes confirmed-absent from unharvested", {
  # IOP's resolution rule was read and confirmed absent.
  # cli writes to the message stream, not stdout.
  iop <- capture.output(print(journal_spec("iop")), type = "message")
  res_line <- grep("Minimum resolution", iop, value = TRUE)
  expect_match(res_line, "not specified by publisher")

  # APS was harvested only for width and line weight; nobody read its
  # resolution rule, so the printout must not speak for the publisher.
  aps <- capture.output(print(journal_spec("aps")), type = "message")
  expect_match(grep("Minimum resolution", aps, value = TRUE), "not yet harvested")
})

test_that("an entry sourced from an archive records the snapshot date", {
  aps <- journal_spec("aps")
  # The live page 403s; the value came from a 2026-04-04 snapshot, and
  # verified_on must say so rather than claiming today.
  expect_equal(as.character(aps$verified_on), "2026-04-04")
  expect_match(aps$notes, "Internet Archive")
  expect_true(as.Date(aps$verified_on) < Sys.Date())
})

test_that("APS records only what its page unambiguously states", {
  aps <- journal_spec("aps")
  expect_equal(aps$columns$single, 85)      # "8.5 cm"
  expect_equal(aps$min_line_pt, 0.5)        # "0.18 mm (0.5 point)"
  # 2 mm capital-letter height is not font size, so it is not recorded as one.
  expect_null(aps$font_min_pt)
  # 600 dpi applies to scans, not figures generally.
  expect_null(aps$dpi_min)
})

test_that("PNAS records only what is required of the author", {
  p <- journal_spec("pnas")
  expect_equal(unlist(p$columns), c(small = 90, medium = 110, large = 180))
  expect_equal(p$font_min_pt, 6)
  expect_equal(p$font_max_pt, 12)

  # PNAS's submission page says article PDFs are processed to display images
  # at 200 ppi and HTML at 300 ppi. That describes PNAS's own rendering, not a
  # rule for the author, and it is NOT where dpi_min comes from. The recorded
  # resolutions come from the separate Digital Art Guidelines, whose raster and
  # vector columns state the same figures.
  expect_equal(p$dpi_min, 300)
  expect_false(grepl("200", p$source_quote_dpi))
  expect_match(p$source_quote_dpi, "no type or lettering")

  r <- check_journal(ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
                       ggplot2::geom_point(), "pnas", column = "medium")
  expect_match(r[r$check == "Resolution", ]$requirement, "min 300 dpi")
})

test_that("PNAS's named sizes work like any other column vocabulary", {
  expect_equal(fig_width("pnas", "medium"), 110)
  expect_equal(fig_width("pnas", "large", "cm"), 18)
  expect_error(fig_width("pnas", "double"), "does not have a 'double' column")
})

test_that("a default ggplot title breaches PNAS's 12 pt ceiling", {
  # ggplot2's default title is rel(1.2) of an 11 pt base = 13.2 pt.
  titled <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) +
    ggplot2::geom_point() + ggplot2::labs(title = "Fuel economy")
  r <- check_journal(titled, "pnas", column = "medium")
  expect_equal(r[r$check == "Type size", ]$status, "fail")

  fixed <- titled + theme_journal("pnas")
  expect_equal(check_journal(fixed, "pnas", column = "medium")[
    check_journal(fixed, "pnas", column = "medium")$check == "Type size", ]$status, "pass")
})
