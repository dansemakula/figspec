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

test_that("spec_load accepts the specifications key and rejects ambiguous collections", {
  path <- withr::local_tempfile(fileext = ".yml")
  entry <- list(
    id = "project_report",
    name = "Project report",
    source_url = "internal:project-report",
    verified_on = as.character(Sys.Date()),
    requirements = list(columns = list(full = 160))
  )
  yaml::write_yaml(list(specifications = list(entry)), path)
  expect_identical(read_registry_entries(path)[[1]]$id, "project_report")

  yaml::write_yaml(
    list(specifications = list(entry), journals = list(entry)),
    path
  )
  expect_error(
    read_registry_entries(path),
    "not both",
    class = "figspec_bad_registry"
  )
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

test_that("spec_save creates a reusable specification registry", {
  old_user_specs <- .figspec_cache$user_specs
  withr::defer(.figspec_cache$user_specs <- old_user_specs)
  .figspec_cache$user_specs <- NULL

  registry_file <- file.path(withr::local_tempdir(), "project-specifications.yml")
  report_spec <- list(
    name = "Research unit report",
    columns = list(full = 160),
    dpi_min = 300,
    formats = c("png", "pdf"),
    tables = list(
      formats = c("html", "docx"),
      font_min_pt = 9,
      header_bold = TRUE
    )
  )

  saved <- spec_save(
    report_spec,
    registry_file,
    id = "research_unit_report"
  )
  expect_identical(saved, registry_file)
  expect_true(file.exists(registry_file))
  expect_true(suppressMessages(registry_validate_file(registry_file)))

  raw <- yaml::read_yaml(registry_file, eval.expr = FALSE)
  expect_identical(raw$schema_version, 2L)
  expect_named(raw, c("schema_version", "specifications"))
  expect_length(raw$specifications, 1L)
  expect_identical(raw$specifications[[1]]$id, "research_unit_report")
  expect_identical(
    raw$specifications[[1]]$source_url,
    "internal:research_unit_report"
  )
  expect_identical(
    raw$specifications[[1]]$verified_on,
    as.character(Sys.Date())
  )
  expect_null(raw$specifications[[1]]$origin)
  expect_identical(raw$specifications[[1]]$requirements$dpi_min, 300)
  expect_identical(raw$specifications[[1]]$tables$font_min_pt, 9)

  loaded <- spec_load(registry_file)
  expect_identical(loaded, "research_unit_report")
  expect_equal(fig_width("research_unit_report", "full"), 160)
  expect_identical(table_spec("research_unit_report")$font_min_pt, 9)
})

test_that("spec_save appends safely and requires permission to replace an id", {
  registry_file <- file.path(withr::local_tempdir(), "team-specifications.yaml")
  spec_save(
    list(name = "First report", columns = list(full = 150)),
    registry_file,
    id = "first_report",
    source_url = "internal:first-report-v1",
    verified_on = "2026-09-01"
  )
  original_hash <- unname(tools::md5sum(registry_file))

  expect_error(
    spec_save(
      list(name = "Unapproved replacement", columns = list(full = 999)),
      registry_file,
      id = "first_report"
    ),
    "overwrite = TRUE",
    class = "figspec_conflict"
  )
  expect_identical(unname(tools::md5sum(registry_file)), original_hash)

  spec_save(
    list(name = "Second report", columns = list(full = 170)),
    registry_file,
    id = "second_report"
  )
  after_append <- read_registry_entries(registry_file)
  expect_identical(
    vapply(after_append, function(entry) entry$id, character(1)),
    c("first_report", "second_report")
  )

  spec_save(
    list(name = "First report, revised", columns = list(full = 155)),
    registry_file,
    id = "first_report",
    source_url = "internal:first-report-v2",
    overwrite = TRUE
  )
  after_replace <- read_registry_entries(registry_file)
  expect_length(after_replace, 2L)
  expect_identical(after_replace[[1]]$name, "First report, revised")
  expect_identical(after_replace[[1]]$requirements$columns$full, 155)
  expect_identical(after_replace[[2]]$name, "Second report")
})

test_that("spec_save refuses invalid inputs without damaging a file", {
  destination <- file.path(withr::local_tempdir(), "protected.yml")
  writeLines("this is not a registry", destination)
  original <- readBin(destination, "raw", n = file.info(destination)$size)

  expect_error(
    spec_save(
      list(name = "Report", columns = list(full = 160)),
      destination,
      id = "report"
    ),
    class = "figspec_bad_registry"
  )
  expect_identical(
    readBin(destination, "raw", n = file.info(destination)$size),
    original
  )

  invalid_destination <- file.path(withr::local_tempdir(), "invalid.yml")
  expect_error(
    spec_save(
      list(name = "Invalid", dpi_min = -300),
      invalid_destination,
      id = "invalid"
    ),
    "positive finite",
    class = "figspec_bad_registry"
  )
  expect_false(file.exists(invalid_destination))
  expect_error(
    spec_save(list(name = "Report"), tempfile(fileext = ".txt"), id = "report"),
    "yaml.*yml",
    class = "figspec_bad_input"
  )
  expect_error(
    spec_save(list(name = "Report"), tempfile(fileext = ".yml")),
    "id.*required",
    class = "figspec_bad_input"
  )
  expect_error(
    spec_save(
      list(name = "Report"), tempfile(fileext = ".yml"),
      id = "cell_press"
    ),
    "bundled specification",
    class = "figspec_conflict"
  )
})

test_that("spec_save and spec_load support a real figure and table workflow", {
  skip_if_not_installed("ragg")
  skip_if_not_installed("gt")

  old_user_specs <- .figspec_cache$user_specs
  withr::defer(.figspec_cache$user_specs <- old_user_specs)
  .figspec_cache$user_specs <- NULL

  work <- withr::local_tempdir()
  registry_file <- file.path(work, "analysis-specifications.yml")
  reusable_spec <- list(
    name = "Analysis report",
    columns = list(full = 160),
    dpi_min = 96,
    formats = "png",
    font_min_pt = 9,
    tables = list(
      formats = "html",
      font_min_pt = 9,
      header_bold = TRUE,
      vertical_rules = FALSE
    )
  )
  spec_save(reusable_spec, registry_file, id = "analysis_report")
  spec_load(registry_file)

  plot <- ggplot2::ggplot(
    ggplot2::mpg,
    ggplot2::aes(displ, hwy, colour = drv, shape = drv)
  ) +
    ggplot2::geom_point() +
    fig_apply_spec("analysis_report")
  figure_file <- file.path(work, "analysis-figure.png")
  saved_figure <- suppressWarnings(fig_save(
    figure_file,
    plot,
    spec = "analysis_report",
    column = "full",
    height = 90,
    dpi = 96
  ))
  figure_report <- attr(saved_figure, "figspec_report")

  table_file <- file.path(work, "analysis-table.html")
  saved_table <- suppressWarnings(table_save(
    table_file,
    ggplot2::mpg[1:30, c("manufacturer", "model", "displ", "hwy")],
    spec = "analysis_report"
  ))
  table_report <- attr(saved_table, "figspec_table_report")

  expect_true(file.size(figure_file) > 10000)
  expect_true(file.size(table_file) > 1000)
  expect_s3_class(figure_report, "figspec_report")
  expect_identical(
    figure_report$status[figure_report$check == "Width"],
    "pass"
  )
  expect_s3_class(table_report, "figspec_table_report")
  expect_false(any(table_report$status %in% c("fail", "invalid")))
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

test_that("a team project can reload shared files from relative paths", {
  skip_if_not_installed("ggplot2")
  old_user_specs <- .figspec_cache$user_specs
  old_styles <- .figspec_cache$styles
  withr::defer({
    .figspec_cache$user_specs <- old_user_specs
    .figspec_cache$styles <- old_styles
  })
  .figspec_cache$user_specs <- NULL
  .figspec_cache$styles <- NULL

  project <- withr::local_tempdir()
  config <- file.path(project, "config", "figspec")
  dir.create(config, recursive = TRUE)
  spec_path <- file.path(config, "specifications.yml")
  style_path <- file.path(config, "styles.rds")

  spec_save(
    list(name = "Team report", columns = list(full = 160)),
    spec_path,
    id = "team_report"
  )
  style_register("team_style", ggplot2::theme_minimal(), "Team theme")
  style_save(style_path)

  .figspec_cache$user_specs <- NULL
  .figspec_cache$styles <- NULL
  withr::local_dir(project)
  expect_identical(
    spec_load(file.path("config", "figspec", "specifications.yml")),
    "team_report"
  )
  expect_identical(
    style_load(file.path("config", "figspec", "styles.rds")),
    "team_style"
  )
  expect_equal(fig_width("team_report", "full"), 160)
  expect_s3_class(figspec:::resolve_style("team_style"), "theme")
})

test_that("shipped entries are marked as figspec's own", {
  expect_true(all(spec_list()$origin[spec_list()$id == "plos_one"] == "figspec"))
})
