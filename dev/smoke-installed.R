# Run from outside the source tree against a package installed from the built
# tarball. This catches undeclared reliance on development files, stale loaded
# objects and missing installed data.

repo <- Sys.getenv("FIGSPEC_REPO_ROOT")
library_root <- normalizePath(Sys.getenv("R_LIBS"), winslash = "/", mustWork = TRUE)

suppressPackageStartupMessages(library(figspec))
installed <- normalizePath(find.package("figspec"), winslash = "/", mustWork = TRUE)
stopifnot(startsWith(installed, paste0(library_root, "/")))

expected <- read.csv(
  file.path(
    repo, "tests", "testthat", "fixtures", "api-migration",
    "api-migration-map.csv"
  ),
  stringsAsFactors = FALSE
)$new_name
stopifnot(setequal(getNamespaceExports("figspec"), expected))

spec <- list(
  name = "Installed-package smoke specification",
  columns = list(single = 85),
  dpi_min = 96,
  formats = list("png"),
  font_min_pt = 8,
  tables = list(
    formats = "html",
    font_min_pt = 9,
    header_bold = TRUE,
    vertical_rules = FALSE
  )
)
spec_registry <- file.path(getwd(), "installed-smoke-specifications.yml")
spec_save(spec, spec_registry, id = "installed_smoke")
stopifnot(
  file.exists(spec_registry),
  isTRUE(suppressMessages(registry_validate_file(spec_registry))),
  identical(spec_load(spec_registry), "installed_smoke")
)
spec <- spec_get("installed_smoke")
plot <- ggplot2::ggplot(
  ggplot2::mpg,
  ggplot2::aes(displ, hwy, colour = class, shape = drv)
) +
  ggplot2::geom_point() +
  fig_apply_spec(spec)

sized <- fig_panel_size(plot, width = 55, height = 38)
geometry <- fig_geometry(sized)
stopifnot(abs(geometry$panel_width_mm - 55) < 0.1)

output <- file.path(getwd(), "installed-smoke.png")
saved <- suppressWarnings(fig_save(
  output,
  plot,
  spec = spec,
  column = "single",
  height = 60,
  dpi = 96,
  check = TRUE
))
stopifnot(file.exists(output), is.character(saved), length(saved) == 1L)
report <- attr(saved, "figspec_report")
stopifnot(
  inherits(report, "figspec_report"),
  identical(attr(report, "spec_name"), spec$name)
)

collection <- suppressWarnings(submission_check(
  list(first = plot, second = plot),
  spec = spec,
  column = "single",
  dpi = 96
))
stopifnot(inherits(collection, "figspec_submission"), nrow(collection) == 2L)

table_output <- file.path(getwd(), "installed-smoke-table.html")
saved_table <- suppressWarnings(table_save(
  table_output,
  ggplot2::mpg[1:20, c("manufacturer", "model", "displ", "hwy")],
  spec
))
table_report <- attr(saved_table, "figspec_table_report")
stopifnot(
  file.exists(table_output),
  file.size(table_output) > 1000,
  inherits(table_report, "figspec_table_report"),
  !any(table_report$status %in% c("fail", "invalid"))
)

mixed <- suppressWarnings(submission_check(
  list(figure = plot, table = head(ggplot2::mpg)),
  spec = spec,
  column = "single"
))
stopifnot(
  identical(mixed$asset, c("figure", "table")),
  inherits(submission_detail(mixed, "table"), "figspec_table_report")
)
stopifnot(
  identical(table_spec("nature")$spec_name, "Nature"),
  identical(media_spec("science")$spec_name, "Science"),
  identical(
    graphical_abstract_spec("rsc")$spec_name,
    "Royal Society of Chemistry journals"
  )
)

cat("Installed package works from an external consumer directory.\n")
