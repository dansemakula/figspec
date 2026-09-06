# The immutable old and final contracts are combined according to migration
# state. This test therefore remains valid before, during and after the rename.

contract_env <- new.env(parent = baseenv())
sys.source(testthat::test_path("fixtures", "api-migration", "api-current-contract.R"), contract_env)
sys.source(testthat::test_path("fixtures", "api-migration", "api-final-contract.R"), contract_env)
old_contract <- contract_env$figspec_current_api_contract
final_contract <- contract_env$figspec_final_api_contract
api_map <- read.csv(
  testthat::test_path("fixtures", "api-migration", "api-migration-map.csv"),
  stringsAsFactors = FALSE
)
surface_map <- read.csv(
  testthat::test_path("fixtures", "api-migration", "api-surface-map.csv"),
  stringsAsFactors = FALSE
)

active_name <- function(old) {
  row <- api_map[api_map$old_name == old, , drop = FALSE]
  stopifnot(nrow(row) == 1L)
  if (row$name_state == "migrated") row$new_name else row$old_name
}

active_function <- function(old) getExportedValue("figspec", active_name(old))

active_argument <- function(old, before, after) {
  row <- api_map[api_map$old_name == old, , drop = FALSE]
  if (row$signature_state == "migrated") after else before
}

surface_expected <- function(name) {
  state <- surface_map$state[match(name, surface_map$surface)]
  stopifnot(length(state) == 1L, !is.na(state))
  if (state == "migrated") final_contract[[name]] else old_contract[[name]]
}

test_that("the active public API has the manifest-selected names and signatures", {
  expected <- vector("list", nrow(api_map))
  names(expected) <- vapply(api_map$old_name, active_name, character(1))
  for (i in seq_len(nrow(api_map))) {
    old <- api_map$old_name[[i]]
    new <- api_map$new_name[[i]]
    if (api_map$signature_state[[i]] == "migrated") {
      expected[active_name(old)] <- list(final_contract$exports[[new]])
    } else {
      expected[active_name(old)] <- list(old_contract$exports[[old]])
    }
    if (api_map$signature_state[[i]] == "keep") {
      expect_identical(old_contract$exports[[old]], final_contract$exports[[new]], info = old)
    }
  }

  expect_identical(sort(getNamespaceExports("figspec")), sort(names(expected)))
  for (name in names(expected)) {
    expect_identical(
      formals(getExportedValue("figspec", name)),
      expected[[name]],
      info = name
    )
  }
})

test_that("S3 registrations remain available", {
  registered <- getNamespaceInfo(asNamespace("figspec"), "S3methods")
  actual <- apply(registered[, 1:2, drop = FALSE], 1, paste, collapse = ".")
  expect_identical(sort(actual), sort(final_contract$s3))
})

test_that("documented spelling aliases remain exact aliases", {
  expect_identical(
    active_function("check_color_safety"),
    active_function("check_colour_safety")
  )
  expect_identical(
    active_function("scale_color_figspec"),
    active_function("scale_colour_figspec")
  )
})

test_that("public result metadata follows the active surface contract", {
  plot <- ggplot2::ggplot(
    ggplot2::mpg,
    ggplot2::aes(displ, hwy)
  ) + ggplot2::geom_point()

  fit <- do.call(active_function("fit_journal"), list("nature"))
  expect_identical(names(attr(fit, "config")), surface_expected("fit_config"))

  spec_arg <- active_argument("fig_check", "journal", "spec")
  report_args <- list(
    x = plot, column = "single", height = 60, dpi = 300, format = "png"
  )
  report_args[[spec_arg]] <- "nature"
  report <- suppressWarnings(suppressMessages(
    do.call(active_function("fig_check"), report_args)
  ))
  expect_identical(names(report), c("check", "requirement", "actual", "status"))
  expect_identical(names(attributes(report)), surface_expected("report_attributes"))

  merged <- figspec:::merge_figspec_reports(report, report)
  expect_identical(
    names(attributes(merged)),
    surface_expected("merged_report_attributes")
  )

  colour_args <- list(plot + ggplot2::aes(colour = factor(cyl)))
  colour_args[[active_argument("check_colour_safety", "journal", "spec")]] <- "nature"
  colour_report <- do.call(active_function("check_colour_safety"), colour_args)
  expect_identical(
    names(attributes(colour_report)),
    surface_expected("colour_report_attributes")
  )

  submission_args <- list(
    x = list(first = plot, second = plot), column = "single", dpi = 300
  )
  submission_args[[active_argument("check_submission", "journal", "spec")]] <- "cell_press"
  submission <- suppressWarnings(suppressMessages(
    do.call(active_function("check_submission"), submission_args)
  ))
  expect_identical(
    names(submission),
    surface_expected("submission_columns")
  )
  expect_identical(
    names(attributes(submission)),
    surface_expected("submission_attributes")
  )

  table <- do.call(active_function("table_spec"), list("nature"))
  media <- do.call(active_function("media_spec"), list("science"))
  abstract <- do.call(active_function("graphical_abstract_spec"), list("rsc"))
  expect_identical(names(table), surface_expected("table_spec_fields"))
  expect_identical(names(media), surface_expected("media_spec_fields"))
  expect_identical(names(abstract), surface_expected("abstract_spec_fields"))
  asset_name_field <- surface_expected("asset_spec_name_field")
  expect_true(asset_name_field %in% names(table))
  expect_true(asset_name_field %in% names(media))
  expect_true(asset_name_field %in% names(abstract))

  table_report <- table_check(
    table_apply_spec(head(datasets::mtcars), "nature"),
    "nature"
  )
  expect_identical(
    names(attributes(table_report)),
    surface_expected("table_report_attributes")
  )
  expect_identical(names(table_report), surface_expected("table_report_columns"))
  expect_true(all(table_report$status %in% surface_expected("table_status_values")))
  expect_identical(names(spec_list()), surface_expected("spec_list_columns"))
  expect_identical(
    names(registry_status()),
    surface_expected("registry_status_columns")
  )
  expect_identical(
    figspec:::table_requirement_keys(),
    surface_expected("table_registry_fields")
  )
  inspection <- submission_check(list(item = plot))
  expect_true(all(c(submission$result, inspection$result) %in%
    surface_expected("submission_result_values")))

  subset_behavior <- surface_expected("report_subset_behavior")
  subset <- report[report$status == "fail", , drop = FALSE]
  expect_identical(class(subset), subset_behavior$class)
  expect_null(attr(subset, subset_behavior$removed_attribute, exact = TRUE))

  printed <- capture.output(print(report), type = "message")
  expect_true(any(grepl(
    surface_expected("report_print_behavior")$profile_label,
    printed,
    fixed = TRUE
  )))
})

test_that("public condition classes and fields follow the active contract", {
  plot <- ggplot2::ggplot(
    datasets::mtcars,
    ggplot2::aes(wt, mpg)
  ) + ggplot2::geom_point()
  error <- tryCatch(
    do.call(
      active_function("fig_panel_width"),
      list(plots = list(plot), column = "single")
    ),
    error = identity
  )
  expect_identical(class(error), surface_expected("column_condition_classes"))
  expect_identical(names(error), surface_expected("column_condition_fields"))
  expect_identical(error$column, "single")
})
