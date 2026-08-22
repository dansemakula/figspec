# Registry maintenance ----------------------------------------------------

#' How current is each registry entry, and how complete
#'
#' Author guidelines change, and an entry read two years ago reads exactly like
#' one read yesterday unless something says otherwise. This reports the age of
#' every entry and how much of it has actually been harvested, so a registry
#' that is quietly going stale is visible rather than merely wrong.
#'
#' @param max_age_days Age beyond which an entry is flagged for rechecking.
#'   Defaults to 365.
#' @param as_of Date to measure against. Defaults to today.
#' @return A data frame with one row per entry, ordered oldest first.
#' @examples
#' registry_status()
#' registry_status(max_age_days = 30)
#' @export
registry_status <- function(max_age_days = 365, as_of = Sys.Date()) {
  reg <- load_registry()
  fields <- requirement_keys()
  out <- do.call(rbind, lapply(reg, function(j) {
    stated <- sum(vapply(fields, function(f) !is.null(j[[f]]), logical(1)))
    absent <- length(intersect(unlist(j$not_stated %||% list()), fields))
    age <- as.integer(as.Date(as_of) - as.Date(j$verified_on))
    data.frame(
      id = j$id,
      verified_on = as.character(j$verified_on),
      age_days = age,
      stale = age > max_age_days,
      stated = stated,
      confirmed_absent = absent,
      unharvested = length(fields) - stated - absent,
      origin = j$origin %||% "figspec",
      stringsAsFactors = FALSE
    )
  }))
  rownames(out) <- NULL
  out[order(-out$age_days), , drop = FALSE]
}

#' Entries that need rechecking
#'
#' @inheritParams registry_status
#' @return The ids that are older than `max_age_days`, invisibly, after
#'   reporting them.
#' @examples
#' stale_entries(max_age_days = 0)
#' @export
stale_entries <- function(max_age_days = 365, as_of = Sys.Date()) {
  st <- registry_status(max_age_days, as_of)
  old <- st[st$stale, , drop = FALSE]
  if (!nrow(old)) {
    cli::cli_alert_success(
      "No registry entry is older than {max_age_days} day{?s}."
    )
    return(invisible(character(0)))
  }
  cli::cli_alert_warning(
    "{nrow(old)} entr{?y/ies} older than {max_age_days} day{?s} and due a recheck:"
  )
  for (i in seq_len(nrow(old))) {
    cli::cli_li("{old$id[i]} - read {old$age_days[i]} days ago ({old$verified_on[i]})")
  }
  invisible(old$id)
}

#' A skeleton for a new registry entry
#'
#' Prints a YAML template with every field figspec understands, so a
#' contributor is told what to look for rather than having to guess the schema.
#' Fill in what the publisher states, list the rest under `not_stated`, and
#' delete nothing: a field left in neither place is reported to users as not
#' yet harvested, which is the honest default.
#'
#' @param id Short identifier for the entry.
#' @param name Journal or publisher name.
#' @param source_url The author-guidelines page the values will come from.
#' @return The template, invisibly, as a character string.
#' @examples
#' new_journal_entry("plos_biology", "PLOS Biology",
#'                   "https://journals.plos.org/plosbiology/s/figures")
#' @export
new_journal_entry <- function(id, name, source_url) {
  tmpl <- paste0(
    "- id: ", id, "\n",
    "  name: ", name, "\n",
    "  publisher: \n",
    "  disciplines: [ ]\n",
    "  source_url: ", source_url, "\n",
    "  verified_on: '", format(Sys.Date()), "'\n",
    "  requirements:\n",
    "    # Fill in ONLY what the page states. Quote the wording for any number.\n",
    "    # columns: {single: , onehalf: , double: }\n",
    "    # width_min_mm: \n    # width_max_mm: \n    # height_max_mm: \n",
    "    # dpi_min: \n    # dpi_line_art: \n    # dpi_bw: \n    # dpi_combination: \n",
    "    # formats: [ ]\n    # colour_mode: [ ]\n    # max_file_mb: \n",
    "    # font_families: [ ]\n    # font_min_pt: \n    # font_max_pt: \n",
    "    # min_line_pt: \n    # max_line_pt: \n",
    "    # avoid_colour_pairs: [[red, green]]\n    # print_greyscale: \n",
    "    # panel_labels: uppercase\n    # text_case: sentence\n",
    "  not_stated:\n",
    "    # Fields you READ the page for and confirmed are absent. Do not list a\n",
    "    # field you simply did not check: leave it out and it reports as\n",
    "    # \"not yet harvested\", which is true.\n",
    "  # media: {video_formats: [ ], frame_max: {width: , height: }, max_file_mb: }\n",
    "  # tables: {orientation: , title_style: }\n",
    "  # notes: >\n"
  )
  cat(tmpl)
  invisible(tmpl)
}

#' Validate a registry file before loading it
#'
#' Runs the same checks [load_journals()] runs, but reports everything wrong
#' rather than stopping at the first problem.
#'
#' @param path Path to a YAML file in registry format.
#' @return `TRUE` invisibly if the file is valid; otherwise the problems are
#'   reported and `FALSE` is returned invisibly.
#' @examples
#' # validate_registry_file("my-journals.yaml")
#' @export
validate_registry_file <- function(path) {
  raw <- yaml::read_yaml(path)
  entries <- raw$journals %||% raw
  problems <- character(0)
  for (j in entries) {
    id <- j$id %||% "<missing id>"
    if (is.null(j$id)) problems <- c(problems, "an entry has no `id`")
    if (is.null(j$source_url)) problems <- c(problems, paste0(id, ": no `source_url`"))
    if (is.null(j$verified_on)) {
      problems <- c(problems, paste0(id, ": no `verified_on`"))
    } else if (!grepl("^\\d{4}-\\d{2}-\\d{2}$", as.character(j$verified_on))) {
      problems <- c(problems, paste0(id, ": `verified_on` is not YYYY-MM-DD"))
    }
    leaked <- intersect(names(j$house_style %||% list()), requirement_keys())
    if (length(leaked)) {
      problems <- c(problems, paste0(id, ": requirement field(s) in `house_style`: ",
                                     paste(leaked, collapse = ", ")))
    }
    clash <- intersect(unlist(j$not_stated %||% list()),
                       names(j$requirements %||% list()))
    if (length(clash)) {
      problems <- c(problems, paste0(id, ": field(s) in both `requirements` and `not_stated`: ",
                                     paste(clash, collapse = ", ")))
    }
    unknown <- setdiff(names(j$requirements %||% list()),
                       c(requirement_keys(), "max_series_recommended",
                         grep("^source_quote", names(j$requirements %||% list()), value = TRUE)))
    if (length(unknown)) {
      problems <- c(problems, paste0(id, ": unrecognised requirement field(s): ",
                                     paste(unknown, collapse = ", ")))
    }
  }
  if (!length(problems)) {
    cli::cli_alert_success("{length(entries)} entr{?y/ies}, no problems found.")
    return(invisible(TRUE))
  }
  cli::cli_alert_danger("{length(problems)} problem{?s} found:")
  for (p in problems) cli::cli_li(p)
  invisible(FALSE)
}
