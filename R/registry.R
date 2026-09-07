# Registry loading -----------------------------------------------------------
#
# The registry is a YAML file, inst/extdata/journals.yaml, holding one entry per
# publisher. This file reads it, checks it, and turns each entry into the flat
# list the rest of the package works with.
#
# Two structural rules are enforced here rather than trusted to the file:
#
#   provenance   an entry without a source_url and a verified_on is refused at
#                load time. A requirement whose origin cannot be produced is
#                not a requirement figspec is willing to grade against.
#   separation   requirements and house_style are different kinds of claim -
#                "the journal requires this" against "this resembles the
#                journal" - so a key from requirement_keys() appearing under
#                house_style is an error, not a preference.
#
# A user's own entries, added with spec_register() or spec_load(), are
# kept apart from the shipped ones in the cache and carry a different `origin`,
# so a report can always say whether a requirement came from figspec's registry
# or from the caller.

.figspec_cache <- new.env(parent = emptyenv())

# Path to the registry file inside the installed package.
registry_path <- function() {
  system.file("extdata", "journals.yaml", package = "figspec", mustWork = TRUE)
}

# Keys that describe a stated requirement. A house style must never contain
# one of these: that is the line between "the journal requires this" and
# "this resembles the journal".
requirement_keys <- function() {
  c("columns", "width_min_mm", "width_max_mm", "height_max_mm",
    "dpi_min", "dpi_max", "dpi_min_inclusive", "dpi_max_inclusive",
    "dpi_line_art", "dpi_bw", "dpi_combination",
    "formats", "font_families", "font_min_pt", "font_max_pt",
    "colour_mode", "max_file_mb", "min_line_pt", "max_line_pt",
    "panel_labels", "panel_labels_placement", "text_case", "text_no_final_stop",
    "avoid_colour_pairs", "print_greyscale", "axes_from_zero", "max_panels", "axis_lines_and_ticks",
    "avoid_coloured_text", "thousands_separator", "no_background_grid",
    "tiff_compression", "allow_alpha", "flattened", "max_pages")
}

# Turn one YAML entry into the flat list the package uses.
#
# Requirements are lifted to the top level so that spec$dpi_min reads directly,
# while house_style, tables, media and graphical_abstract stay nested because
# they are separate kinds of claim and must not be mistaken for requirements.
# `not_stated` is carried through unchanged: it is what lets graded() tell
# "the publisher does not state this" apart from "nobody has looked yet".
#
# @param j One entry as read from YAML.
# @param origin "figspec" for a shipped entry, or a label identifying where a
#   user-supplied entry came from.
# @return A flat named list, with NULL fields dropped.
flatten_entry <- function(j, origin = "figspec") {
  req <- j$requirements %||% list()
  out <- c(
    j[intersect(c("id", "name", "publisher", "disciplines", "publication_stage"), names(j))],
    req,
    list(
      source_url = j$source_url,
      verified_on = as.character(j$verified_on),
      sources = j$sources,
      house_style = j$house_style,
      tables = j$tables,
      tables_not_stated = j$tables_not_stated,
      media = j$media,
      graphical_abstract = j$graphical_abstract,
      not_stated = j$not_stated,
      notes = j$notes,
      origin = origin
    )
  )
  out[!vapply(out, is.null, logical(1))]
}

# The whole registry: shipped entries plus any the user has added.
#
# Reading and validating the YAML is not free, so the shipped entries are
# cached in .figspec_cache after the first call. User entries are held
# separately and appended on every call, so registering a journal takes effect
# immediately without re-reading the file.
#
# @param refresh TRUE to re-read and re-validate the file from disk.
# @return A named list of entries, keyed by id.
load_registry <- function(refresh = FALSE) {
  if (!refresh && !is.null(.figspec_cache$registry)) {
    return(c(.figspec_cache$registry, .figspec_cache$user_specs %||% list()))
  }
  raw <- yaml::read_yaml(registry_path(), eval.expr = FALSE)
  validate_registry(raw$journals)
  entries <- lapply(raw$journals, flatten_entry)
  names(entries) <- vapply(raw$journals, function(j) j$id, character(1))
  .figspec_cache$registry <- entries
  c(entries, .figspec_cache$user_specs %||% list())
}

# Enforce the registry contract: provenance is mandatory, ids unique.
validate_registry <- function(entries) {
  problems <- registry_problems(entries)
  if (length(problems)) {
    figspec_abort(
      c("Registry validation failed; provenance and requirement values must be trustworthy.",
        "x" = problems),
      "bad_registry", problems = problems)
  }
  invisible(TRUE)
}

#' Register a publication specification for this session
#'
#' Adds a specification that is not bundled with figspec, such as requirements
#' for an individual journal, conference or other publication. The entry lasts
#' for the current R session and can immediately be used with [fig_save()],
#' [fig_check()], [fig_apply_spec()] and the other specification-aware functions.
#' [spec_list()] marks it as user-supplied so it remains distinct from profiles
#' maintained by figspec.
#'
#' Every registered entry needs a source and a date. Use the public guidance
#' page when one exists. For a private manual or internal decision, use an
#' `internal:` identifier such as `"internal:figure-handbook-v3"`.
#'
#' @param id A short, unique identifier beginning with a lower-case letter and
#'   containing only lower-case letters, numbers and underscores. This is the
#'   value supplied to functions such as `fig_save(spec = "my_journal")`.
#' @param name The publication name shown in reports and registry listings.
#' @param source_url Where the requirements came from: an HTTP(S) page, a
#'   `file:` URI or an `internal:` identifier.
#' @param verified_on Date the source was last checked, as `"YYYY-MM-DD"` or a
#'   `Date`. Future and invalid dates are rejected.
#' @param requirements A named list containing only requirements stated by the
#'   source, such as `columns`, `dpi_min`, `formats`, `font_min_pt` or
#'   `min_line_pt`. Values are validated before the entry is registered.
#' @param house_style Optional named visual preferences, such as
#'   `list(palette = c("#1B4965", "#CA6702"))`. Requirements do not belong
#'   here and are rejected if included.
#' @param ... Optional registry information such as `publisher`, `disciplines`,
#'   `publication_stage`, `notes`, `tables`, `media` or
#'   `graphical_abstract`.
#' @return The registered specification, invisibly.
#' @seealso [spec_save()] to write a reusable YAML registry, [spec_load()] to
#'   load reusable entries and [registry_entry_template()] to create a registry
#'   template.
#' @examples
#' spec_register(
#'   id = "lab_report",
#'   name = "Our lab report format",
#'   source_url = "internal:handbook-v3",
#'   verified_on = "2026-08-22",
#'   requirements = list(columns = list(single = 100, double = 170),
#'                       font_min_pt = 9, formats = list("pdf"))
#' )
#' fig_width("lab_report", "double")
#' @export
spec_register <- function(id, name, source_url, verified_on,
                             requirements = list(), house_style = NULL, ...) {
  entry <- c(list(id = id, name = name, source_url = source_url,
                  verified_on = as.character(verified_on),
                  requirements = requirements, house_style = house_style),
             list(...))
  validate_registry(list(entry))
  load_registry()
  if (id %in% names(.figspec_cache$registry %||% list())) {
    figspec_abort(
      c(
        "A bundled specification already uses the id {.val {id}}.",
        "i" = "Choose a different id so the source of each specification remains clear."
      ),
      "conflict",
      id = id
    )
  }
  flat <- flatten_entry(entry, origin = "user")
  users <- .figspec_cache$user_specs %||% list()
  users[[id]] <- flat
  .figspec_cache$user_specs <- users
  invisible(structure(flat, class = c("figspec_spec", "list")))
}

# Read a user registry without allowing YAML expressions to execute.
#
# yaml::read_yaml() normally follows the global `yaml.eval.expr` option. A
# project should not become executable merely because that option was changed
# elsewhere in the R session, so registry reads always disable expressions.
read_registry_entries <- function(path) {
  if (!is.character(path) || length(path) != 1L ||
      is.na(path) || !nzchar(trimws(path))) {
    figspec_abort(
      "{.arg path} must be one non-empty file path.",
      "bad_input"
    )
  }
  if (!file.exists(path)) {
    figspec_abort("Registry file not found: {.file {path}}.", "not_found", path = path)
  }
  info <- file.info(path)
  if (isTRUE(info$isdir)) {
    figspec_abort("{.file {path}} is a directory, not a YAML file.", "bad_input")
  }
  if (!is.finite(info$size) || info$size < 1L) {
    figspec_abort("Registry file is empty: {.file {path}}.", "bad_registry")
  }
  if (info$size > 10 * 1024^2) {
    figspec_abort(
      c(
        "Registry file is larger than 10 MB: {.file {path}}.",
        "i" = "Split unusually large registries into smaller YAML files and load them separately."
      ),
      "bad_input"
    )
  }
  raw <- tryCatch(
    yaml::read_yaml(path, eval.expr = FALSE),
    error = function(e) e
  )
  if (inherits(raw, "error")) {
    figspec_abort(
      c(
        "Could not read registry YAML from {.file {path}}.",
        "x" = conditionMessage(raw)
      ),
      "bad_registry",
      path = path
    )
  }
  if (!is.list(raw)) {
    figspec_abort(
      "Registry YAML must contain a list of specification entries.",
      "bad_registry",
      path = path
    )
  }
  if (!is.null(raw$specifications) && !is.null(raw$journals)) {
    figspec_abort(
      "Registry YAML must use either {.field specifications} or the legacy {.field journals} collection, not both.",
      "bad_registry",
      path = path
    )
  }
  raw$specifications %||% raw$journals %||% raw
}

# Convert the flat specification used by the public API back into the nested
# representation stored in a registry file. Keeping this conversion here gives
# spec_save() one reviewed route for inline, registered and bundled profiles.
specification_registry_entry <- function(spec, id, source_url, verified_on) {
  resolved <- spec_get(spec)
  id <- id %||% resolved$id
  if (is.null(id)) {
    figspec_abort(
      c(
        "{.arg id} is required when the specification does not already have one.",
        "i" = "Use a short name such as {.val research_unit_report}."
      ),
      "bad_input"
    )
  }

  source_url <- source_url %||% resolved$source_url %||% paste0("internal:", id)
  verified_on <- verified_on %||% resolved$verified_on %||% Sys.Date()

  nested_requirements <- resolved$requirements %||% list()
  if (!is.list(nested_requirements)) {
    figspec_abort("{.field requirements} must be a named list.", "bad_input")
  }
  flat_requirement_names <- intersect(
    names(resolved),
    c(requirement_keys(), "max_series_recommended")
  )
  flat_requirement_names <- unique(c(
    flat_requirement_names,
    grep("^source_quote", names(resolved), value = TRUE)
  ))
  overlap <- intersect(names(nested_requirements), flat_requirement_names)
  if (length(overlap)) {
    figspec_abort(
      c(
        "The specification records the same requirement twice.",
        "x" = "Duplicated field{?s}: {.field {overlap}}.",
        "i" = "Keep each field either inside {.field requirements} or at the top level."
      ),
      "bad_input",
      fields = overlap
    )
  }
  requirements <- c(nested_requirements, resolved[flat_requirement_names])

  entry <- c(
    list(id = id, name = resolved$name),
    resolved[intersect(
      c(
        "publisher", "disciplines", "source_archive_url",
        "source_content_md5", "publication_stage"
      ),
      names(resolved)
    )],
    list(
      source_url = source_url,
      verified_on = as.character(verified_on),
      requirements = requirements
    ),
    resolved[intersect(
      c(
        "not_stated", "sources", "house_style", "tables",
        "tables_not_stated", "media", "graphical_abstract", "notes"
      ),
      names(resolved)
    )]
  )
  entry[!vapply(entry, is.null, logical(1))]
}

spec_save_destination <- function(path) {
  if (!is.character(path) || length(path) != 1L || is.na(path) ||
      !nzchar(trimws(path)) || grepl("[\r\n]", path)) {
    figspec_abort("{.arg path} must be one non-empty YAML file path.", "bad_input")
  }
  if (!tolower(tools::file_ext(path)) %in% c("yaml", "yml")) {
    figspec_abort(
      "{.arg path} must end in {.file .yaml} or {.file .yml}.",
      "bad_input",
      path = path
    )
  }
  expanded <- path.expand(path)
  parent <- dirname(expanded)
  if (!dir.exists(parent)) {
    figspec_abort(
      "The destination directory does not exist: {.file {parent}}.",
      "not_found",
      path = path
    )
  }
  if (file.exists(expanded) && isTRUE(file.info(expanded)$isdir)) {
    figspec_abort("{.file {path}} is a directory, not a YAML file.", "bad_input")
  }
  if (file.exists(expanded)) {
    link <- Sys.readlink(expanded)
    if (length(link) == 1L && !is.na(link) && nzchar(link)) {
      figspec_abort(
        "Refusing to replace the symbolic link {.file {path}}.",
        "bad_input",
        path = path
      )
    }
  }
  file.path(
    normalizePath(parent, winslash = "/", mustWork = TRUE),
    basename(expanded)
  )
}

promote_spec_file <- function(candidate, destination) {
  backup <- NULL
  if (file.exists(destination)) {
    backup <- tempfile(
      ".figspec-spec-backup-",
      tmpdir = dirname(destination),
      fileext = paste0(".", tools::file_ext(destination))
    )
    if (!file.rename(destination, backup)) {
      figspec_abort(
        "Could not protect the existing {.file {destination}} before replacement.",
        "bad_input",
        path = destination
      )
    }
  }

  placed <- file.rename(candidate, destination)
  restored <- TRUE
  if (!placed && !is.null(backup)) restored <- file.rename(backup, destination)
  if (!restored) {
    figspec_abort(
      c(
        "Could not save the specification or restore the previous file.",
        "i" = "The recoverable previous file remains at {.file {backup}}."
      ),
      "bad_input",
      path = destination,
      backup = backup
    )
  }
  if (!placed) {
    figspec_abort(
      "Could not atomically place {.file {destination}}.",
      "bad_input",
      path = destination
    )
  }
  if (!is.null(backup)) unlink(backup)
  invisible(destination)
}

#' Save a specification for reuse
#'
#' Writes a publication, project or organisational specification to a safe,
#' reusable YAML registry file. A new specification is appended when the file
#' already contains other entries. Replacing an entry with the same `id`
#' requires `overwrite = TRUE`.
#'
#' The complete registry is validated in a temporary file before the requested
#' path is changed. If writing or validation fails, an existing file is left
#' unchanged. The resulting file can be kept with a project, shared under
#' version control and loaded in any R session with [spec_load()].
#'
#' A specification created directly in R may not contain provenance fields. In
#' that case figspec records `internal:<id>` as its source and today's date as
#' the date the internal requirements were recorded. Supply `source_url` and
#' `verified_on` when the requirements came from a published or separately
#' maintained source.
#'
#' @param spec A registry id, a `figspec_spec`, or a named list containing at
#'   least a non-empty `name` and any figure, table, media or graphical-abstract
#'   requirements to save.
#' @param path Destination `.yaml` or `.yml` file. If it already contains a
#'   valid figspec registry, a new `id` is appended without removing the other
#'   entries.
#' @param id A short identifier beginning with a lower-case letter and
#'   containing only lower-case letters, numbers and underscores. It may be
#'   omitted when `spec` already contains an `id`.
#' @param source_url Where the requirements came from: an HTTP(S) page, a
#'   `file:` URI or an `internal:` identifier. When omitted, an existing value
#'   in `spec` is kept; otherwise `internal:<id>` is recorded.
#' @param verified_on Date the source or internal requirements were last
#'   checked, as `"YYYY-MM-DD"` or a `Date`. When omitted, an existing value in
#'   `spec` is kept; otherwise today's date is recorded.
#' @param overwrite Whether an entry with the same `id` may be replaced.
#'   Other entries in the file are always preserved.
#' @return `path`, invisibly.
#' @examples
#' report_spec <- list(
#'   name = "Research unit report",
#'   columns = list(full = 160),
#'   dpi_min = 300,
#'   formats = c("png", "pdf")
#' )
#' registry_file <- tempfile(fileext = ".yml")
#' spec_save(report_spec, registry_file, id = "research_unit_report")
#' spec_load(registry_file)
#' fig_width("research_unit_report", "full")
#' unlink(registry_file)
#' @seealso [spec_load()], [spec_register()], [registry_validate_file()]
#' @export
spec_save <- function(spec, path, id = NULL, source_url = NULL,
                      verified_on = NULL, overwrite = FALSE) {
  if (!is.logical(overwrite) || length(overwrite) != 1L || is.na(overwrite)) {
    figspec_abort("{.arg overwrite} must be TRUE or FALSE.", "bad_input")
  }
  destination <- spec_save_destination(path)
  entry <- specification_registry_entry(spec, id, source_url, verified_on)

  load_registry()
  if (entry$id %in% names(.figspec_cache$registry %||% list())) {
    figspec_abort(
      c(
        "A bundled specification already uses the id {.val {entry$id}}.",
        "i" = "Choose a different id for the saved copy."
      ),
      "conflict",
      id = entry$id
    )
  }

  entries <- list()
  if (file.exists(destination)) {
    entries <- read_registry_entries(destination)
    validate_registry(entries)
  }
  ids <- if (length(entries)) {
    vapply(entries, function(item) item$id, character(1))
  } else {
    character()
  }
  existing <- match(entry$id, ids)
  if (!is.na(existing) && !overwrite) {
    figspec_abort(
      c(
        "The registry already contains {.val {entry$id}}.",
        "i" = "Set {.code overwrite = TRUE} to replace that entry while preserving the others."
      ),
      "conflict",
      id = entry$id,
      path = path
    )
  }
  if (is.na(existing)) {
    entries[[length(entries) + 1L]] <- entry
  } else {
    entries[[existing]] <- entry
  }
  validate_registry(entries)

  candidate <- tempfile(
    ".figspec-spec-",
    tmpdir = dirname(destination),
    fileext = paste0(".", tools::file_ext(destination))
  )
  on.exit(if (file.exists(candidate)) unlink(candidate), add = TRUE)
  write_error <- tryCatch({
    yaml::write_yaml(
      list(schema_version = 2L, specifications = unname(entries)),
      candidate
    )
    NULL
  }, error = identity)
  if (inherits(write_error, "error")) {
    figspec_abort(
      c(
        "Could not write the specification registry.",
        "x" = conditionMessage(write_error)
      ),
      "bad_input",
      path = path
    )
  }

  written_entries <- read_registry_entries(candidate)
  validate_registry(written_entries)
  written_ids <- vapply(written_entries, function(item) item$id, character(1))
  if (!identical(written_ids, vapply(entries, function(item) item$id, character(1)))) {
    figspec_abort(
      "The written registry did not preserve its specification ids.",
      "bad_registry",
      path = path
    )
  }
  promote_spec_file(candidate, destination)
  invisible(path)
}

#' Load specifications from a YAML registry
#'
#' Reads a YAML registry maintained by a publication, project or organisation
#' and adds its specifications to the current R session. Each entry then works
#' with the same building, exporting and verification functions as a bundled
#' profile. [spec_list()] marks loaded entries as user-supplied.
#'
#' Keep the YAML file with the project or in a shared version-controlled
#' repository. When requirements change, edit the file and call
#' `spec_load()` again; entries with the same user-defined id are updated for
#' the current session. Bundled profile ids remain reserved, keeping loaded
#' specifications clearly separated from package-maintained records.
#'
#' Registry YAML is treated as data: YAML expression evaluation is disabled
#' regardless of the user's global `yaml.eval.expr` option. The complete file
#' is validated first, and its entries are added to the session together only
#' after every one passes.
#'
#' @param path Path to a non-empty YAML registry file. The file may contain a
#'   top-level `specifications:` list written by [spec_save()], the legacy
#'   `journals:` list used by figspec's bundled registry, or be the list of
#'   entries itself.
#' @return A character vector containing the loaded ids, invisibly.
#' @seealso [spec_save()] to write reusable entries, [spec_register()] to add
#'   one entry directly in R and [registry_validate_file()] to check a file
#'   without loading it.
#' @examples
#' # spec_load("my-journals.yaml")
#' @export
spec_load <- function(path) {
  entries <- read_registry_entries(path)
  validate_registry(entries)
  load_registry()
  ids <- vapply(entries, function(j) j$id, character(1))
  conflicts <- intersect(ids, names(.figspec_cache$registry %||% list()))
  if (length(conflicts)) {
    figspec_abort(
      c(
        "A loaded specification cannot replace a bundled profile.",
        "x" = "Conflicting ids: {.val {conflicts}}.",
        "i" = "Rename the user-supplied entries before loading the file."
      ),
      "conflict",
      id = conflicts
    )
  }
  users <- .figspec_cache$user_specs %||% list()
  for (j in entries) users[[j$id]] <- flatten_entry(j, origin = "user")
  .figspec_cache$user_specs <- users
  invisible(ids)
}

#' Browse available specification profiles
#'
#' Lists the publication profiles available to figspec, including profiles
#' bundled with the package and any loaded for the current session. Most
#' bundled profiles describe guidance that applies across a publisher's journal
#' portfolio; others record the requirements of an individual journal or
#' publication type. A row in this table can therefore represent many journals.
#'
#' The table includes commonly needed figure requirements and the date each
#' source was last checked. `NA` marks a value that is not recorded as a stated
#' requirement; use [spec_get()] or [registry_status()] to see whether its
#' source was silent or the field is awaiting review.
#'
#' @param discipline An optional character vector of discipline tags, such as
#'   `"physics"` or `c("health", "medicine")`. Matching is case-insensitive,
#'   and a profile is included when it has at least one requested tag.
#' @return A data frame with one row per specification profile.
#' @examples
#' spec_list()
#' spec_list(discipline = "physics")
#' @export
spec_list <- function(discipline = NULL) {
  reg <- load_registry()
  if (!is.null(discipline)) {
    if (!is.character(discipline) || !length(discipline) ||
        anyNA(discipline) || any(!nzchar(trimws(discipline)))) {
      figspec_abort(
        "{.arg discipline} must be a character vector of one or more non-empty tags, or NULL.",
        "bad_input"
      )
    }
    discipline <- trimws(discipline)
    available <- sort(unique(tolower(unlist(lapply(
      reg,
      function(j) j$disciplines %||% character(0)
    )))))
    unknown <- setdiff(tolower(discipline), available)
    if (length(unknown)) {
      figspec_abort(
        c(
          "Unknown discipline tag{?s}: {.val {unknown}}.",
          "i" = "Available tags include {.val {available}}."
        ),
        "not_found",
        discipline = unknown
      )
    }
  }
  out <- do.call(rbind, lapply(reg, function(j) {
    cols <- j$columns
    data.frame(
      id = j$id,
      name = j$name,
      publisher = j$publisher %||% NA_character_,
      disciplines = paste(j$disciplines %||% character(0), collapse = ", "),
      single_mm = as.numeric(cols$single %||% j$width_min_mm %||% NA_real_),
      double_mm = as.numeric(cols$double %||% j$width_max_mm %||% NA_real_),
      dpi_min = as.numeric(j$dpi_min %||% NA_real_),
      font_min_pt = as.numeric(j$font_min_pt %||% NA_real_),
      max_file_mb = as.numeric(j$max_file_mb %||% NA_real_),
      table_requirements = !is.null(j$tables),
      publication_stage = j$publication_stage %||% NA_character_,
      verified_on = as.character(j$verified_on),
      origin = j$origin %||% "figspec",
      stringsAsFactors = FALSE
    )
  }))
  rownames(out) <- NULL
  if (!is.null(discipline)) {
    keep <- vapply(reg, function(j) {
      any(tolower(discipline) %in% tolower(j$disciplines %||% character(0)))
    }, logical(1))
    out <- out[keep, , drop = FALSE]
    rownames(out) <- NULL
  }
  out
}

#' Retrieve or create a specification
#'
#' Retrieves a bundled publisher or journal profile by its registry id, or
#' converts a named list maintained by your project or organisation into a
#' `figspec_spec`. The resulting object can be passed to [fig_check()],
#' [fig_save()] and the other specification-aware functions.
#'
#' @param spec The specification to use: a registry id such as
#'   `"plos_one"`, an existing `figspec_spec`, or a named list containing at
#'   least a non-empty `name`. Use [spec_list()] to browse the available registry
#'   ids. Project, report and organisational specifications are accepted in the
#'   same form as publication profiles.
#' @return An object of class `figspec_spec`. An existing specification object
#'   is returned unchanged.
#' @examples
#' spec_get("frontiers")
#'
#' report_spec <- spec_get(list(
#'   name = "Quarterly research report",
#'   columns = list(full = 160),
#'   formats = c("png", "pdf"),
#'   dpi_min = 300,
#'   font_min_pt = 9
#' ))
#' report_spec
#' @export
spec_get <- function(spec) {
  # A specification does not have to come from the registry. Passing one back
  # in unchanged is what lets a house style, an internal format loaded with
  # spec_load(), or a hand-written list be checked and exported against on
  # the same footing as a published journal.
  if (inherits(spec, "figspec_spec")) return(spec)
  if (is.list(spec)) {
    field_names <- names(spec)
    if (is.null(field_names) || anyNA(field_names) ||
        any(!nzchar(field_names)) || anyDuplicated(field_names)) {
      figspec_abort(
        "A specification list must have unique, non-empty names for every field.",
        "bad_input"
      )
    }
    if (!is.character(spec$name) || length(spec$name) != 1L ||
        is.na(spec$name) || !nzchar(trimws(spec$name))) {
      figspec_abort(
        "A specification list must contain one non-empty character {.field name}.",
        "bad_input"
      )
    }
    return(structure(spec, class = c("figspec_spec", "list")))
  }
  reg <- load_registry()
  if (!is.character(spec) || length(spec) != 1L ||
      is.na(spec) || !nzchar(spec)) {
    figspec_abort(
      c("{.arg spec} must be a registry id, a specification from
         {.fn spec_get}, or a named list of requirements.",
        "x" = "You gave {.cls {class(spec)}}."),
      "bad_input")
  }
  if (!spec %in% names(reg)) {
    close <- agrep(spec, names(reg), value = TRUE, max.distance = 0.4)
    figspec_abort(
      c("Unknown specification id: {.val {spec}}.",
        if (length(close)) {
          c("i" = "Did you mean {.val {close}}?")
        } else {
          c(">" = "See {.fn spec_list} for the ids on record.")
        }),
      "not_found", spec = spec, suggestions = close)
  }
  structure(reg[[spec]], class = c("figspec_spec", "list"))
}
