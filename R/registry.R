# Registry loading -------------------------------------------------------

.figspec_cache <- new.env(parent = emptyenv())

registry_path <- function() {
  system.file("extdata", "journals.yaml", package = "figspec", mustWork = TRUE)
}

# Keys that describe a stated requirement. A house style must never contain
# one of these: that is the line between "the journal requires this" and
# "this resembles the journal".
requirement_keys <- function() {
  c("columns", "width_min_mm", "width_max_mm", "height_max_mm",
    "dpi_min", "dpi_max", "dpi_line_art", "dpi_bw", "dpi_combination",
    "formats", "font_families", "font_min_pt", "font_max_pt",
    "colour_mode", "max_file_mb", "min_line_pt", "max_line_pt",
    "panel_labels", "text_case", "text_no_final_stop",
    "avoid_colour_pairs", "print_greyscale", "axes_from_zero", "max_panels", "axis_lines_and_ticks",
    "avoid_coloured_text", "thousands_separator", "no_background_grid")
}

# Flatten one registry entry: requirements are lifted to the top level for
# convenience, while house_style is kept separate and clearly labelled.
flatten_entry <- function(j, origin = "figspec") {
  req <- j$requirements %||% list()
  out <- c(
    j[intersect(c("id", "name", "publisher", "disciplines"), names(j))],
    req,
    list(
      source_url = j$source_url,
      verified_on = as.character(j$verified_on),
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

load_registry <- function(refresh = FALSE) {
  if (!refresh && !is.null(.figspec_cache$registry)) {
    return(c(.figspec_cache$registry, .figspec_cache$user_journals %||% list()))
  }
  raw <- yaml::read_yaml(registry_path())
  validate_registry(raw$journals)
  entries <- lapply(raw$journals, flatten_entry)
  names(entries) <- vapply(raw$journals, function(j) j$id, character(1))
  .figspec_cache$registry <- entries
  c(entries, .figspec_cache$user_journals %||% list())
}

# Enforce the registry contract: provenance is mandatory, ids unique.
validate_registry <- function(entries) {
  ids <- vapply(entries, function(j) j$id %||% NA_character_, character(1))
  if (anyNA(ids)) {
    stop("Every registry entry must have an `id`.", call. = FALSE)
  }
  if (anyDuplicated(ids)) {
    stop(
      "Duplicate registry ids: ",
      paste(unique(ids[duplicated(ids)]), collapse = ", "),
      call. = FALSE
    )
  }
  for (j in entries) {
    if (is.null(j$source_url) || is.null(j$verified_on)) {
      stop(
        "Registry entry '", j$id,
        "' is missing `source_url` or `verified_on`. ",
        "Entries without provenance are not permitted.",
        call. = FALSE
      )
    }
    contradiction <- intersect(unlist(j$not_stated %||% list()),
                               names(j$requirements %||% list()))
    if (length(contradiction)) {
      stop(
        "Registry entry '", j$id, "' lists ",
        paste(contradiction, collapse = ", "),
        " in `not_stated` while also giving a value for it in `requirements`. ",
        "A field cannot both be absent from the publisher's guidelines and ",
        "taken from them.",
        call. = FALSE
      )
    }
    leaked <- intersect(names(j$house_style %||% list()), requirement_keys())
    if (length(leaked)) {
      stop(
        "Registry entry '", j$id, "' puts requirement field(s) (",
        paste(leaked, collapse = ", "), ") inside `house_style`. ",
        "A house style is taste, not a rule, and is never checked. ",
        "Move these to `requirements:` or remove them.",
        call. = FALSE
      )
    }
  }
  invisible(TRUE)
}

#' Add your own journal to the registry
#'
#' Registers a journal for the current session, for a journal figspec does not
#' ship yet or for an internal report format of your own. Registered journals
#' behave exactly like shipped ones, but [journals()] marks them as
#' user-supplied so it stays obvious which entries figspec stands behind.
#'
#' Provenance is required here too. If the requirements came from you rather
#' than a publisher, say so in `source_url`.
#'
#' @param id Short identifier, used everywhere a journal is named.
#' @param name Human-readable journal name.
#' @param source_url Where the requirements came from.
#' @param verified_on Date the source was read, as `"YYYY-MM-DD"`.
#' @param requirements Named list of stated requirements. See the shipped
#'   registry for the field names.
#' @param house_style Optional named list of purely visual preferences. May
#'   not contain requirement fields.
#' @param ... Further entry fields such as `publisher` or `disciplines`.
#' @return The registered specification, invisibly.
#' @examples
#' register_journal(
#'   id = "lab_report",
#'   name = "Our lab report format",
#'   source_url = "internal handbook v3",
#'   verified_on = "2026-08-22",
#'   requirements = list(columns = list(single = 100, double = 170),
#'                       font_min_pt = 9, formats = list("pdf"))
#' )
#' fig_width("lab_report", "double")
#' @export
register_journal <- function(id, name, source_url, verified_on,
                             requirements = list(), house_style = NULL, ...) {
  entry <- c(list(id = id, name = name, source_url = source_url,
                  verified_on = as.character(verified_on),
                  requirements = requirements, house_style = house_style),
             list(...))
  validate_registry(list(entry))
  flat <- flatten_entry(entry, origin = "user")
  users <- .figspec_cache$user_journals %||% list()
  users[[id]] <- flat
  .figspec_cache$user_journals <- users
  invisible(structure(flat, class = c("figspec_spec", "list")))
}

#' Load journal entries from your own registry file
#'
#' Reads a YAML file in the same shape as the shipped registry and adds every
#' entry for the current session. Use this to keep an institutional set of
#' journals under version control alongside your papers.
#'
#' @param path Path to a YAML file.
#' @return The ids loaded, invisibly.
#' @examples
#' # load_journals("my-journals.yaml")
#' @export
load_journals <- function(path) {
  raw <- yaml::read_yaml(path)
  entries <- raw$journals %||% raw
  validate_registry(entries)
  users <- .figspec_cache$user_journals %||% list()
  for (j in entries) users[[j$id]] <- flatten_entry(j, origin = "user")
  .figspec_cache$user_journals <- users
  invisible(vapply(entries, function(j) j$id, character(1)))
}

#' List the journals in the registry
#'
#' Returns one row per registry entry, with the figure requirements that are
#' most often needed at a glance. Requirements a publisher does not state are
#' returned as `NA`, which means *unspecified*, not *unlimited*.
#'
#' @param discipline Optional character vector. Keep only entries tagged with
#'   at least one of these disciplines, for example `"physics"`.
#' @return A data frame with one row per journal.
#' @examples
#' journals()
#' journals(discipline = "physics")
#' @export
journals <- function(discipline = NULL) {
  reg <- load_registry()
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

#' Look up one journal's figure specification
#'
#' @param journal Registry id, for example `"plos_one"`. Use [journals()] to
#'   see the available ids.
#' @return An object of class `figspec_spec`.
#' @examples
#' journal_spec("frontiers")
#' @export
journal_spec <- function(journal) {
  reg <- load_registry()
  if (!is.character(journal) || length(journal) != 1L) {
    stop("`journal` must be a single registry id.", call. = FALSE)
  }
  if (!journal %in% names(reg)) {
    close <- agrep(journal, names(reg), value = TRUE, max.distance = 0.4)
    msg <- paste0("Unknown journal id: '", journal, "'.")
    if (length(close)) {
      msg <- paste0(msg, " Did you mean: ", paste(close, collapse = ", "), "?")
    } else {
      msg <- paste0(msg, " See journals() for available ids.")
    }
    stop(msg, call. = FALSE)
  }
  structure(reg[[journal]], class = c("figspec_spec", "list"))
}
