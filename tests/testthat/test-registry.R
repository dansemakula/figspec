# Loading and validating the registry, and adding entries of your own.

test_that("every registry entry carries its provenance", {
  reg <- load_registry()
  expect_gt(length(reg), 0)
  for (j in reg) {
    expect_true(nzchar(j$source_url), info = j$id)
    expect_true(nzchar(as.character(j$verified_on)), info = j$id)
    expect_match(as.character(j$verified_on), "^\\d{4}-\\d{2}-\\d{2}$", info = j$id)
  }
})

test_that("registry validation rejects entries without provenance", {
  bad <- list(list(id = "x", name = "X"))
  expect_error(validate_registry(bad), class = "figspec_bad_registry")
  expect_error(validate_registry(bad), "[Pp]rovenance")
})

test_that("registry validation rejects duplicate ids", {
  dup <- list(
    list(id = "x", source_url = "u", verified_on = "2026-01-01"),
    list(id = "x", source_url = "u", verified_on = "2026-01-01")
  )
  expect_error(validate_registry(dup), class = "figspec_bad_registry")
  expect_error(validate_registry(dup), "Duplicate")
})

test_that("journals() returns one row per entry and filters by discipline", {
  all <- journals()
  expect_s3_class(all, "data.frame")
  expect_equal(nrow(all), length(load_registry()))
  phys <- journals(discipline = "physics")
  expect_true(nrow(phys) >= 1)
  expect_true(all(grepl("physics", phys$disciplines)))
  expect_lt(nrow(phys), nrow(all))
})

test_that("unknown journal ids fail with a usable message", {
  expect_error(journal_spec("plos_onee"), "plos_one")
  expect_error(journal_spec("not_a_journal"), class = "figspec_not_found")
  expect_error(journal_spec("not_a_journal"), "journals")
})

test_that("table requirements are surfaced when recorded and absent otherwise", {
  ts <- table_spec("nature")
  expect_s3_class(ts, "figspec_table_spec")
  expect_equal(ts$orientation, "portrait")
  expect_message(table_spec("jss"), "No table requirements")
})

test_that("Nature's figure widths match its formatting guide", {
  expect_equal(fig_width("nature", "single"), 90)
  expect_equal(fig_width("nature", "double"), 180)
})

test_that("a user can register their own journal", {
  withr::defer(.figspec_cache$user_journals <- NULL)
  register_journal(
    "my_report", "My report", "internal handbook", "2026-08-22",
    requirements = list(columns = list(single = 100, double = 170),
                        font_min_pt = 9)
  )
  expect_equal(fig_width("my_report", "double"), 170)
  expect_equal(journals()[journals()$id == "my_report", ]$origin, "user")
})

test_that("user journals still require provenance", {
  expect_error(
    register_journal("x", "X", NULL, NULL, requirements = list()),
    "[Pp]rovenance"
  )
})

test_that("a requirement smuggled into house_style is refused", {
  expect_error(
    register_journal("y", "Y", "u", "2026-08-22",
                     house_style = list(font_min_pt = 4)),
    class = "figspec_bad_registry"
  )
  expect_error(
    register_journal("y", "Y", "u", "2026-08-22",
                     house_style = list(font_min_pt = 4)),
    "taste, not a rule"
  )
})

test_that("shipped entries are marked as figspec's own", {
  expect_true(all(journals()$origin[journals()$id == "plos_one"] == "figspec"))
})
