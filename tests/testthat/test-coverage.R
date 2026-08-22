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
