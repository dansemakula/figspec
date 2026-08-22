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
  # Deliberately not asserting how much any one journal has been harvested:
  # that is a fact about today's registry, not about the code, and it changes
  # every time an entry is filled in. Nature already broke this test once by
  # improving. What must hold is the accounting.
  expect_true(all(st$stated >= 0 & st$confirmed_absent >= 0 & st$unharvested >= 0))
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
  # Word boundary matters: "1000-1200" contains "200" as a substring, so a
  # bare grepl("200", ...) matches the line-art figure rather than the 200 ppi
  # rendering figure it is meant to exclude.
  expect_false(grepl("\\b200 ppi", p$source_quote_dpi))
  expect_false(grepl("processed to display|HTML display", p$source_quote_dpi))
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

test_that("ACS point measurements convert at 72 points to the inch", {
  a <- journal_spec("acs")
  expect_equal(a$columns$single, round(240 * 25.4 / 72, 1))   # 240 pt = 3.33 in
  expect_equal(a$columns$double, round(504 * 25.4 / 72, 1))   # 504 pt = 7 in
  expect_equal(a$height_max_mm, round(660 * 25.4 / 72, 1))    # 660 pt = 9.167 in
  expect_equal(a$font_min_pt, 4.5)
  expect_equal(a$min_line_pt, 0.5)
  # "Helvetica or Arial fonts work well" is a suggestion, not a requirement.
  expect_null(a$font_families)
})

test_that("resolution stated by art type is checked by art type", {
  path <- withr::local_tempfile(fileext = ".png")
  grDevices::png(path, width = 84, height = 60, units = "mm", res = 300)
  plot(mtcars$wt, mtcars$mpg)
  grDevices::dev.off()

  # ACS: 300 colour, 600 grayscale, 1200 line art.
  expect_equal(check_journal(path, "acs", dpi = 300)[
    check_journal(path, "acs", dpi = 300)$check == "Resolution", ]$status, "pass")
  expect_equal(check_journal(path, "acs", dpi = 300, art_type = "line")[
    check_journal(path, "acs", dpi = 300, art_type = "line")$check == "Resolution", ]$status, "fail")
})

test_that("OUP records a line-width range, not just a floor", {
  o <- journal_spec("oup")
  expect_equal(o$min_line_pt, 0.25)
  expect_equal(o$max_line_pt, 1)

  too_thick <- ggplot2::ggplot(ggplot2::economics, ggplot2::aes(date, unemploy)) +
    ggplot2::geom_line(linewidth = pt_to_ggplot_linewidth(3))
  expect_equal(check_journal(too_thick, "oup")[
    check_journal(too_thick, "oup")$check == "Line width", ]$status, "fail")
})

test_that("entries carry the caveats that make them auditable", {
  # BMJ's source PDF may be a decade old and shows signs of adaptation.
  expect_match(journal_spec("bmj")$notes, "2017")
  # OUP calls its own document tips rather than strict rules.
  expect_match(journal_spec("oup")$notes, "tips rather than strict rules")
  # Neither publisher's proofing-pipeline resolution became a requirement.
  # Word boundary again: "1200dpi" contains "200" as a substring.
  expect_false(grepl("\\b200dpi", journal_spec("oup")$source_quote_dpi))
  expect_false(grepl("proof", journal_spec("oup")$source_quote_dpi, ignore.case = TRUE))
})

test_that("Nature's expanded entry enforces its own narrow type range", {
  n <- journal_spec("nature")
  expect_equal(n$font_min_pt, 5)
  expect_equal(n$font_max_pt, 7)
  expect_setequal(unlist(n$font_families), c("Arial", "Helvetica"))
  expect_equal(unlist(n$colour_mode), "RGB")
  # Corroborated across two Nature author pages harvested a day apart.
  expect_equal(n$columns$single, 90)
  expect_equal(n$columns$double, 180)
  expect_equal(n$height_max_mm, 170)

  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point() +
    ggplot2::labs(title = "Fuel economy")
  # ggplot2's defaults run 8.8-13.2 pt, well outside 5-7.
  expect_equal(check_journal(p, "nature")[
    check_journal(p, "nature")$check == "Type size", ]$status, "fail")
  fixed <- p + theme_journal("nature")
  expect_equal(check_journal(fixed, "nature")[
    check_journal(fixed, "nature")$check == "Type size", ]$status, "pass")
})

test_that("Nature forbids red with green, and says so imperatively", {
  # "avoid the use of red and green for contrast" is an instruction, unlike
  # AGU's "strongly encouraged", which is not recorded as a requirement.
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) +
    ggplot2::geom_point()
  expect_equal(check_journal(p, "nature")[
    check_journal(p, "nature")$check == "Colour pairs", ]$status, "fail")

  safe <- p + scale_colour_figspec("cividis")
  expect_equal(check_journal(safe, "nature")[
    check_journal(safe, "nature")$check == "Colour pairs", ]$status, "pass")

  expect_null(journal_spec("agu")$avoid_colour_pairs)
})

test_that("IEEE inch measurements convert, and the entry names its scope", {
  expect_equal(fig_width("ieee_magazines", "single"), round(3.5 * 25.4, 1))
  expect_equal(fig_width("ieee_magazines", "double"), round(7.16 * 25.4, 1))
  # This is IEEE's magazine guidance, not its journal guidance.
  expect_match(journal_spec("ieee_magazines")$name, "magazines")
  expect_match(journal_spec("ieee_magazines")$notes, "journals have a separate author centre")
})
