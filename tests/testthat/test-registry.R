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

test_that("spec_list() returns one row per entry and filters by discipline", {
  all <- spec_list()
  expect_s3_class(all, "data.frame")
  expect_equal(nrow(all), length(load_registry()))
  phys <- spec_list(discipline = "physics")
  expect_true(nrow(phys) >= 1)
  expect_true(all(grepl("physics", phys$disciplines)))
  expect_lt(nrow(phys), nrow(all))
})

test_that("unknown journal ids fail with a usable message", {
  expect_error(spec_get("plos_onee"), "plos_one")
  expect_error(spec_get("not_a_journal"), class = "figspec_not_found")
  expect_error(spec_get("not_a_journal"), "spec_list")
})

test_that("inline specifications and registry ids are validated at entry", {
  expect_error(spec_get(NA_character_), class = "figspec_bad_input")
  expect_error(spec_get(""), class = "figspec_bad_input")
  expect_error(
    spec_get(list(columns = list(single = 80))),
    "non-empty character.*name",
    class = "figspec_bad_input"
  )
  expect_error(
    spec_get(structure(list("Report", 300), names = c("name", "name"))),
    "unique",
    class = "figspec_bad_input"
  )
  expect_error(
    spec_get(list("Report", 300)),
    "unique, non-empty names",
    class = "figspec_bad_input"
  )
})

test_that("table requirements are surfaced when recorded and absent otherwise", {
  ts <- table_spec("nature")
  expect_s3_class(ts, "figspec_table_spec")
  expect_equal(ts$orientation, "portrait")
  expect_message(table_spec("jss"), "No table requirements")
})

test_that("Nature's figure widths match its formatting guide", {
  expect_equal(fig_width("nature", "single"), 89)
  expect_equal(fig_width("nature", "double"), 183)
})

test_that("a user can register their own journal", {
  withr::defer(.figspec_cache$user_specs <- NULL)
  spec_register(
    "my_report", "My report", "internal:handbook", "2026-08-22",
    requirements = list(columns = list(single = 100, double = 170),
                        font_min_pt = 9)
  )
  expect_equal(fig_width("my_report", "double"), 170)
  expect_equal(spec_list()[spec_list()$id == "my_report", ]$origin, "user")
})

test_that("a user entry cannot hide a bundled specification", {
  withr::defer(.figspec_cache$user_specs <- NULL)
  expect_error(
    spec_register(
      "cell_press", "Replacement", "internal:test", Sys.Date(),
      requirements = list(columns = list(single = 100))
    ),
    "bundled specification already uses",
    class = "figspec_conflict"
  )
  expect_identical(spec_get("cell_press")$origin, "figspec")
})

test_that("user journals still require provenance", {
  expect_error(
    spec_register("x", "X", NULL, NULL, requirements = list()),
    "[Pp]rovenance"
  )
})

test_that("a requirement smuggled into house_style is refused", {
  expect_error(
    spec_register("y", "Y", "internal:test", "2026-08-22",
                     house_style = list(font_min_pt = 4)),
    class = "figspec_bad_registry"
  )
  expect_error(
    spec_register("y", "Y", "internal:test", "2026-08-22",
                     house_style = list(font_min_pt = 4)),
    "taste, not a rule"
  )
})

test_that("registered house-style palettes are validated at entry", {
  withr::defer(.figspec_cache$user_specs <- NULL)
  expect_error(
    spec_register(
      "bad_style", "Bad style", "internal:test", Sys.Date(),
      house_style = "navy"
    ),
    "named list",
    class = "figspec_bad_registry"
  )
  expect_error(
    spec_register(
      "bad_palette", "Bad palette", "internal:test", Sys.Date(),
      house_style = list(palette = c("#0072B2", "not-a-colour"))
    ),
    "valid R colours",
    class = "figspec_bad_registry"
  )
})

test_that("spec_load validates paths and malformed YAML", {
  expect_error(spec_load(character()), class = "figspec_bad_input")
  expect_error(spec_load(NA_character_), class = "figspec_bad_input")
  expect_error(
    spec_load(file.path(tempdir(), "missing-registry.yml")),
    class = "figspec_not_found"
  )
  expect_error(spec_load(tempdir()), "directory", class = "figspec_bad_input")

  malformed <- withr::local_tempfile(fileext = ".yml")
  writeLines("journals: [this is: not valid", malformed)
  expect_error(spec_load(malformed), class = "figspec_bad_registry")
})

test_that("spec_load is atomic and cannot replace bundled profiles", {
  old_user_specs <- .figspec_cache$user_specs
  withr::defer(.figspec_cache$user_specs <- old_user_specs)
  .figspec_cache$user_specs <- NULL

  registry_file <- withr::local_tempfile(fileext = ".yml")
  yaml::write_yaml(
    list(journals = list(
      list(
        id = "new_report",
        name = "New report",
        source_url = "internal:test",
        verified_on = as.character(Sys.Date()),
        requirements = list(columns = list(full = 160))
      ),
      list(
        id = "cell_press",
        name = "Replacement",
        source_url = "internal:test",
        verified_on = as.character(Sys.Date()),
        requirements = list(columns = list(single = 100))
      )
    )),
    registry_file
  )

  expect_error(
    spec_load(registry_file),
    "cannot replace a bundled profile",
    class = "figspec_conflict"
  )
  expect_null(.figspec_cache$user_specs)
  expect_identical(spec_get("cell_press")$origin, "figspec")
})

test_that("registry YAML expressions are never evaluated", {
  old_option <- getOption("yaml.eval.expr")
  withr::defer(options(yaml.eval.expr = old_option))
  options(yaml.eval.expr = TRUE)

  registry_file <- withr::local_tempfile(fileext = ".yml")
  marker <- withr::local_tempfile()
  unlink(marker)
  expression <- paste0(
    "journals: !expr writeLines('executed', '",
    gsub("'", "\\\\'", marker),
    "')"
  )
  writeLines(expression, registry_file)

  expect_error(spec_load(registry_file), class = "figspec_bad_registry")
  expect_false(file.exists(marker))
})

test_that("shipped entries are marked as figspec's own", {
  expect_true(all(spec_list()$origin[spec_list()$id == "plos_one"] == "figspec"))
})
