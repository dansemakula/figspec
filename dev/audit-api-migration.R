# Verify that the public namespace and authored files agree with the staged
# API migration manifests. Run from the package root after every rename family.

args <- commandArgs(trailingOnly = TRUE)
final <- "--final" %in% args
contract_dir <- "tests/testthat/fixtures/api-migration"
map <- read.csv(file.path(contract_dir, "api-migration-map.csv"), stringsAsFactors = FALSE, check.names = FALSE)
surfaces <- read.csv(file.path(contract_dir, "api-surface-map.csv"), stringsAsFactors = FALSE, check.names = FALSE)

failures <- character()
check <- function(condition, message) {
  if (!isTRUE(condition)) failures <<- c(failures, message)
}

check(
  identical(
    names(map),
    c("old_name", "new_name", "family", "name_state", "signature_state")
  ),
  "migration manifest columns have changed"
)
check(nrow(map) == 51L, sprintf("manifest has %d rows instead of 51", nrow(map)))
check(!anyDuplicated(map$old_name), "manifest contains duplicate old names")
check(!anyDuplicated(map$new_name), "manifest contains duplicate new names")
check(
  all(map$name_state %in% c("keep", "planned", "migrated")),
  "manifest contains an invalid name state"
)
check(
  all(map$signature_state %in% c("keep", "planned", "migrated")),
  "manifest contains an invalid signature state"
)
check(
  all((map$old_name == map$new_name) == (map$name_state == "keep")),
  "kept names and unchanged names do not correspond"
)

map_identity <- tempfile()
on.exit(unlink(map_identity), add = TRUE)
writeLines(paste(map$old_name, map$new_name, map$family, sep = "|"), map_identity)
check(
  identical(unname(tools::md5sum(map_identity)), "43da1c0224143e8e6722eedcfd1b7ede"),
  "old/new/family columns changed after the naming map was frozen"
)

expected_surfaces <- c(
  "fit_config", "report_attributes", "merged_report_attributes",
  "colour_report_attributes", "submission_attributes", "submission_columns",
  "table_report_attributes", "spec_list_columns", "registry_status_columns",
  "table_report_columns", "table_status_values", "submission_result_values",
  "table_registry_fields", "asset_spec_name_field",
  "table_spec_fields",
  "media_spec_fields", "abstract_spec_fields", "column_condition_classes",
  "column_condition_fields", "report_subset_behavior", "report_print_behavior"
)
check(
  identical(names(surfaces), c("surface", "state")),
  "surface migration manifest columns have changed"
)
check(
  identical(sort(surfaces$surface), sort(expected_surfaces)),
  "surface migration manifest entries have changed"
)
check(!anyDuplicated(surfaces$surface), "surface manifest contains duplicates")
check(
  all(surfaces$state %in% c("keep", "planned", "migrated")),
  "surface manifest contains an invalid state"
)
surface_identity <- tempfile()
on.exit(unlink(surface_identity), add = TRUE)
writeLines(surfaces$surface, surface_identity)
check(
  identical(unname(tools::md5sum(surface_identity)), "8cc7238ae430571a1db7e1236e101b71"),
  "surface names changed after the surface map was frozen"
)

contract_env <- new.env(parent = baseenv())
contract_files <- file.path(
  contract_dir,
  c("api-current-contract.R", "api-final-contract.R")
)
approved_contract_md5 <- c(
  "9e2c535d3cda348a35ef2550fa4c2734",
  "a09ca7d6e13e99ac1c479373f7c1df1a"
)
check(
  identical(unname(tools::md5sum(contract_files)), approved_contract_md5),
  "immutable current/final API contract contents changed after approval"
)
sys.source(contract_files[[1]], contract_env)
sys.source(contract_files[[2]], contract_env)
old_contract <- contract_env$figspec_current_api_contract
final_contract <- contract_env$figspec_final_api_contract
check(
  identical(sort(names(old_contract)), sort(names(final_contract))),
  "old and final contracts describe different public surfaces"
)
check(
  identical(sort(names(final_contract$exports)), sort(map$new_name)),
  "final API contract and migration map have different function names"
)
check(
  identical(sort(names(old_contract$exports)), sort(map$old_name)),
  "old API contract and migration map have different function names"
)
for (surface in surfaces$surface[surfaces$state == "keep"]) {
  check(
    identical(old_contract[[surface]], final_contract[[surface]]),
    paste0("surface marked keep differs between contracts: ", surface)
  )
}

active_name <- ifelse(map$name_state == "migrated", map$new_name, map$old_name)
check(!anyDuplicated(active_name), "the active migration stage has duplicate names")

suppressMessages(pkgload::load_all(".", quiet = TRUE))
exports <- sort(getNamespaceExports("figspec"))
missing_exports <- setdiff(active_name, exports)
extra_exports <- setdiff(exports, active_name)
check(!length(missing_exports), paste("missing expected exports:", paste(missing_exports, collapse = ", ")))
check(!length(extra_exports), paste("unexpected exports:", paste(extra_exports, collapse = ", ")))

for (i in seq_len(nrow(map))) {
  old <- map$old_name[[i]]
  new <- map$new_name[[i]]
  active <- active_name[[i]]
  expected_formals <- if (map$signature_state[[i]] == "migrated") {
    final_contract$exports[[new]]
  } else {
    old_contract$exports[[old]]
  }
  if (map$signature_state[[i]] == "keep") {
    check(
      identical(old_contract$exports[[old]], final_contract$exports[[new]]),
      paste0("signature marked keep differs between contracts for ", old, "()")
    )
  }
  if (active %in% exports) {
    check(
      identical(formals(getExportedValue("figspec", active)), expected_formals),
      paste0("active signature differs for ", active, "()")
    )
  }
}

registered <- getNamespaceInfo(asNamespace("figspec"), "S3methods")
registered <- apply(registered[, 1:2, drop = FALSE], 1, paste, collapse = ".")
check(
  identical(sort(registered), sort(final_contract$s3)),
  "S3 registration set differs from the approved contract"
)

# These files deliberately preserve both sides of the migration. The first
# public release has no user-facing compatibility period, so release notes are
# scanned like every other authored page and must use the shipped API.
authored <- c(
  list.files("R", recursive = TRUE, full.names = TRUE),
  list.files("tests", recursive = TRUE, full.names = TRUE),
  list.files("vignettes", recursive = TRUE, full.names = TRUE),
  list.files("data-raw", recursive = TRUE, full.names = TRUE),
  list.files("inst", recursive = TRUE, full.names = TRUE),
  list.files(".github", recursive = TRUE, full.names = TRUE),
  list.files("dev", recursive = TRUE, full.names = TRUE),
  "DESCRIPTION", "_pkgdown.yml", ".Rbuildignore", "README.md",
  "CONTRIBUTING.md", "cran-comments.md", "NEWS.md"
)
authored <- authored[file.exists(authored) & !dir.exists(authored)]
# The source trees can contain binary artefacts created by real rendering
# tests (for example, Rplots.pdf).  Restrict identifier scanning to authored
# text formats so binary bytes cannot be mistaken for stale API names or emit
# invalid-encoding warnings.
text_extensions <- c(
  "r", "rmd", "qmd", "md", "txt", "csv", "tsv", "yml", "yaml", "json",
  "sh", "toml", "dcf"
)
top_level_text <- c(
  "DESCRIPTION", "NAMESPACE", "_pkgdown.yml", ".Rbuildignore",
  ".gitignore", "cran-comments.md"
)
authored <- authored[
  tolower(tools::file_ext(authored)) %in% text_extensions |
    basename(authored) %in% top_level_text
]
old_name_allowlist <- c(
  "tests/testthat/test-api-contract.R", "dev/api-naming.md",
  "dev/api-migration-adversarial-review.md", "dev/audit-api-migration.R",
  "dev/validate-site.R",
  "dev/site-redirects.csv",
  file.path(contract_dir, c(
    "api-migration-map.csv", "api-surface-map.csv",
    "api-current-contract.R", "api-final-contract.R"
  ))
)
scanned_authored <- setdiff(authored, old_name_allowlist)

migrated <- map[map$name_state == "migrated" & map$old_name != map$new_name, ]
for (i in seq_len(nrow(migrated))) {
  old <- migrated$old_name[[i]]
  # Most former names are distinctive identifiers, so a token-boundary scan is
  # appropriate. `journals` is also an ordinary English plural and the name of
  # the registry's stable YAML collection. For that one name, detect executable
  # or documentation identifier forms without rejecting prose, `journals.yaml`,
  # article filenames, or `journals:` data keys.
  patterns <- if (identical(old, "journals")) {
    c(
      "\\bjournals\\s*(?:<-\\s*function|\\()",
      "\\.fn\\s+journals\\b",
      "figspec(?:::|:::)journals\\b",
      "export\\(journals\\)",
      "[\"']journals[\"']"
    )
  } else {
    paste0("(?<![[:alnum:]_.])", old, "(?![[:alnum:]_.])")
  }
  hits <- scanned_authored[vapply(scanned_authored, function(path) {
    lines <- readLines(path, warn = FALSE)
    any(vapply(patterns, function(pattern) any(grepl(pattern, lines, perl = TRUE)), logical(1)))
  }, logical(1))]
  check(!length(hits), paste0("former name ", old, " remains in: ", paste(hits, collapse = ", ")))
  filename_hits <- if (identical(old, "journals")) {
    character()
  } else {
    scanned_authored[grepl(old, basename(scanned_authored), fixed = TRUE)]
  }
  check(
    !length(filename_hits),
    paste0("former name ", old, " remains in filename(s): ", paste(filename_hits, collapse = ", "))
  )
}

if (final) {
  remaining_names <- map$old_name[map$name_state == "planned"]
  remaining_signatures <- map$old_name[map$signature_state == "planned"]
  remaining_surfaces <- surfaces$surface[surfaces$state == "planned"]
  check(!length(remaining_names), paste("final audit still has planned names:", paste(remaining_names, collapse = ", ")))
  check(!length(remaining_signatures), paste("final audit still has planned signatures:", paste(remaining_signatures, collapse = ", ")))
  check(!length(remaining_surfaces), paste("final audit still has planned surfaces:", paste(remaining_surfaces, collapse = ", ")))

  final_runtime_ready <- !length(remaining_names) &&
    !length(remaining_signatures) && !length(remaining_surfaces) &&
    all(names(final_contract$exports) %in% exports)
  if (final_runtime_ready) for (alias in names(final_contract$exact_aliases)) {
    canonical <- final_contract$exact_aliases[[alias]]
    if (alias %in% exports && canonical %in% exports) {
      check(
        identical(getExportedValue("figspec", alias), getExportedValue("figspec", canonical)),
        paste0(alias, "() is not an exact alias of ", canonical, "()")
      )
    }
  }

  if (final_runtime_ready) {
    plot <- ggplot2::ggplot(ggplot2::mpg, ggplot2::aes(displ, hwy)) + ggplot2::geom_point()
    fit <- fig_apply_spec("nature")
    check(identical(names(attr(fit, "config")), final_contract$fit_config), "final fit config differs")
    report <- suppressWarnings(suppressMessages(fig_check(
      plot, spec = "nature", column = "single", height = 60, dpi = 300, format = "png"
    )))
    check(identical(names(attributes(report)), final_contract$report_attributes), "final report attributes differ")
    merged <- figspec:::merge_figspec_reports(report, report)
    check(identical(names(attributes(merged)), final_contract$merged_report_attributes), "final merged-report attributes differ")
    colour <- colour_safety_check(plot + ggplot2::aes(colour = factor(cyl)), spec = "nature")
    check(identical(names(attributes(colour)), final_contract$colour_report_attributes), "final colour-report attributes differ")
    submission <- suppressWarnings(suppressMessages(submission_check(
      list(first = plot, second = plot), spec = "cell_press", column = "single", dpi = 300
    )))
    check(identical(names(submission), final_contract$submission_columns), "final submission columns differ")
    check(identical(names(attributes(submission)), final_contract$submission_attributes), "final submission attributes differ")
    table <- table_spec(spec = "nature")
    media <- media_spec(spec = "science")
    abstract <- graphical_abstract_spec(spec = "rsc")
    check(identical(names(table), final_contract$table_spec_fields), "final table fields differ")
    check(identical(names(media), final_contract$media_spec_fields), "final media fields differ")
    check(identical(names(abstract), final_contract$abstract_spec_fields), "final abstract fields differ")
    check(
      final_contract$asset_spec_name_field %in% names(table) &&
        final_contract$asset_spec_name_field %in% names(media) &&
        final_contract$asset_spec_name_field %in% names(abstract),
      "final asset specification-name field is absent"
    )
    table_report <- table_check(
      table_apply_spec(head(ggplot2::mpg), "nature"),
      "nature"
    )
    check(
      identical(
        names(attributes(table_report)),
        final_contract$table_report_attributes
      ),
      "final table-report attributes differ"
    )
    check(
      identical(names(table_report), final_contract$table_report_columns),
      "final table-report columns differ"
    )
    check(
      all(table_report$status %in% final_contract$table_status_values),
      "final table report contains an unapproved status"
    )
    check(
      identical(names(spec_list()), final_contract$spec_list_columns),
      "final specification-list columns differ"
    )
    check(
      identical(names(registry_status()), final_contract$registry_status_columns),
      "final registry-status columns differ"
    )
    check(
      identical(table_requirement_keys(), final_contract$table_registry_fields),
      "final table registry schema differs"
    )
    inspection <- submission_check(list(item = plot))
    check(
      all(c(submission$result, inspection$result) %in%
            final_contract$submission_result_values),
      "final submission contains an unapproved result"
    )
    subset <- report[report$status == "fail", , drop = FALSE]
    check(identical(class(subset), final_contract$report_subset_behavior$class), "final report subset class differs")
    check(
      is.null(attr(subset, final_contract$report_subset_behavior$removed_attribute, exact = TRUE)),
      "final report subset retains specification metadata"
    )
    printed <- capture.output(print(report), type = "message")
    check(
      any(grepl(final_contract$report_print_behavior$profile_label, printed, fixed = TRUE)),
      "final report print output omits the profile label"
    )
    condition <- tryCatch(
      fig_panel_width(list(plot), column = "single"),
      error = identity
    )
    check(identical(class(condition), final_contract$column_condition_classes), "final condition classes differ")
    check(identical(names(condition), final_contract$column_condition_fields), "final condition fields differ")
  }

  generated_reference <- sub(
    "[.]html$", "",
    basename(list.files("docs/reference", pattern = "[.]html$", full.names = TRUE))
  )
  obsolete_pages <- intersect(map$old_name[map$old_name != map$new_name], generated_reference)
  check(!length(obsolete_pages), paste("former canonical reference pages remain:", paste(obsolete_pages, collapse = ", ")))
  if (file.exists("docs/sitemap.xml")) {
    sitemap <- readLines("docs/sitemap.xml", warn = FALSE)
    changed_old <- map$old_name[map$old_name != map$new_name]
    old_urls <- changed_old[vapply(
      changed_old,
      function(old) any(grepl(paste0("/reference/", old, "[.]html"), sitemap)),
      logical(1)
    )]
    check(!length(old_urls), paste("sitemap retains former canonical URLs:", paste(old_urls, collapse = ", ")))
  }
}

cat(sprintf(
  paste0(
    "API migration state: %d kept, %d planned, %d migrated names; ",
    "%d planned signatures; %d planned public-data surfaces; %d active exports.\n"
  ),
  sum(map$name_state == "keep"), sum(map$name_state == "planned"),
  sum(map$name_state == "migrated"), sum(map$signature_state == "planned"),
  sum(surfaces$state == "planned"), length(exports)
))

if (length(failures)) {
  cat(paste0("- ", failures, collapse = "\n"), "\n")
  quit(status = 1L)
}
cat("API migration manifests, contracts and package state agree.\n")
