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
#' @seealso [spec_load()] to load reusable entries from YAML and
#'   [registry_entry_template()] to create a registry template.
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
  raw$journals %||% raw
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
#' `spec_load()` again; entries with the same user-defined id are updated
#' for the current session. A loaded file cannot replace a profile bundled with
#' figspec.
#'
#' Registry YAML is treated as data: YAML expression evaluation is disabled
#' regardless of the user's global `yaml.eval.expr` option. The complete file
#' is validated before any entry is added, so an invalid entry cannot leave a
#' partly updated session.
#'
#' @param path Path to a non-empty YAML registry file. The file may contain a
#'   top-level `journals:` list, like figspec's bundled registry, or be the list
#'   of entries itself.
#' @return A character vector containing the loaded ids, invisibly.
#' @seealso [spec_register()] to add one entry directly in R and
#'   [registry_validate_file()] to check a file without loading it.
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
#' source was last checked. A requirement shown as `NA` was not recorded as a
#' stated value; it must not be interpreted as having no limit.
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
#'   ids. The specification does not have to describe a journal.
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
