# Registry maintenance ----------------------------------------------------
#
# Tools for keeping the journal registry honest, rather than for using it.
# Everything here is aimed at a maintainer or a contributor; none of it is
# needed to check or save a figure.
#
# The registry makes two promises, and each needs its own upkeep:
#
#   provenance  every entry names the page it was read from and the date.
#               registry_check_sources() asks whether those pages still resolve;
#               registry_status() and registry_stale_entries() report their age.
#   completeness a field is either stated, confirmed absent, or never read,
#               and those must not be conflated. registry_status() counts
#               each separately; registry_entry_template() prints a skeleton with
#               every field, so a contributor is told what to look for;
#               registry_validate_file() refuses a file that breaks either
#               promise.
#
# See the header of inst/extdata/journals.yaml for the recording rules those
# promises come from.

#' Review registry coverage and update dates
#'
#' Shows when each bundled specification was last checked and how its fields are
#' accounted for. A field may contain a stated requirement, be recorded as not
#' stated by the source, or remain to be reviewed. The result makes profiles
#' due for further work easy to identify and explains every missing value.
#'
#' @param max_age_days Age beyond which an entry is flagged for rechecking.
#'   Defaults to 365.
#' @param as_of One `Date` to measure against. Defaults to today.
#' @return A data frame with one row per entry, ordered oldest first.
#' @examples
#' registry_status()
#' registry_status(max_age_days = 30)
#' @export
registry_status <- function(max_age_days = 365, as_of = Sys.Date()) {
  if (!is.numeric(max_age_days) || length(max_age_days) != 1L ||
      is.na(max_age_days) || !is.finite(max_age_days) || max_age_days < 0) {
    figspec_abort("{.arg max_age_days} must be one finite number that is zero or greater.", "bad_input")
  }
  if (!inherits(as_of, "Date") || length(as_of) != 1L || is.na(as_of)) {
    figspec_abort("{.arg as_of} must be one non-missing Date.", "bad_input")
  }
  reg <- load_registry()
  fields <- requirement_keys()
  table_fields <- table_requirement_keys()
  out <- do.call(rbind, lapply(reg, function(j) {
    stated <- sum(vapply(fields, function(f) !is.null(j[[f]]), logical(1)))
    absent <- length(intersect(unlist(j$not_stated %||% list()), fields))
    stated_table_names <- intersect(
      names(j$tables %||% list()), c(table_fields, "format")
    )
    stated_table_names[stated_table_names == "format"] <- "formats"
    table_stated <- length(unique(stated_table_names))
    table_absent <- length(intersect(
      unlist(j$tables_not_stated %||% list()), table_fields
    ))
    age <- as.integer(as.Date(as_of) - as.Date(j$verified_on))
    data.frame(
      id = j$id,
      verified_on = as.character(j$verified_on),
      age_days = age,
      stale = age > max_age_days,
      stated = stated,
      confirmed_absent = absent,
      unharvested = length(fields) - stated - absent,
      table_stated = table_stated,
      table_confirmed_absent = table_absent,
      table_unreviewed = length(table_fields) - table_stated - table_absent,
      origin = j$origin %||% "figspec",
      stringsAsFactors = FALSE
    )
  }))
  rownames(out) <- NULL
  out[order(-out$age_days), , drop = FALSE]
}

#' Find specifications due for review
#'
#' @inheritParams registry_status
#' @return The ids that are older than `max_age_days`, invisibly, after
#'   reporting them.
#' @examples
#' registry_stale_entries(max_age_days = 0)
#' @export
registry_stale_entries <- function(max_age_days = 365, as_of = Sys.Date()) {
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

#' Create a registry-entry template
#'
#' Prints a YAML template containing every field figspec understands. Fill in
#' the requirements stated by the source, list reviewed but unstated fields
#' under `not_stated`, and leave unreviewed fields in place. figspec can then
#' report the review status of every field accurately.
#'
#' @param id Short identifier beginning with a lower-case letter and containing
#'   only lower-case letters, numbers and underscores.
#' @param name Publication, publisher, project or organisation name.
#' @param source_url Page or internal record from which the requirements will
#'   be taken. HTTP(S), `file:` and `internal:` addresses are accepted.
#' @return The template, invisibly, as a character string.
#' @examples
#' registry_entry_template("plos_biology", "PLOS Biology",
#'                   "https://journals.plos.org/plosbiology/s/figures")
#' @export
registry_entry_template <- function(id, name, source_url) {
  if (!is.character(id) || length(id) != 1L || is.na(id) ||
      !grepl("^[a-z][a-z0-9_]*$", id)) {
    figspec_abort(
      "{.arg id} must begin with a lower-case letter and contain only lower-case letters, numbers and underscores.",
      "bad_input"
    )
  }
  if (!is.character(name) || length(name) != 1L || is.na(name) ||
      !nzchar(trimws(name)) || grepl("\n", name, fixed = TRUE) ||
      grepl("\r", name, fixed = TRUE)) {
    figspec_abort("{.arg name} must be one non-empty line of text.", "bad_input")
  }
  if (!is.character(source_url) || length(source_url) != 1L ||
      is.na(source_url) || !nzchar(trimws(source_url)) ||
      grepl("\n", source_url, fixed = TRUE) ||
      grepl("\r", source_url, fixed = TRUE) ||
      !grepl("^(https?://|file:|internal:)", source_url, ignore.case = TRUE)) {
    figspec_abort(
      "{.arg source_url} must be one HTTP(S), file:, or internal: address.",
      "bad_input"
    )
  }
  yaml_scalar <- function(x) paste0("'", gsub("'", "''", x, fixed = TRUE), "'")
  tmpl <- paste0(
    "- id: ", id, "\n",
    "  name: ", yaml_scalar(name), "\n",
    "  publisher: \n",
    "  disciplines: [ ]\n",
    "  source_url: ", yaml_scalar(source_url), "\n",
    "  verified_on: '", format(Sys.Date()), "'\n",
    "  requirements:\n",
    "    # Fill in ONLY what the page states. Quote the wording for any number.\n",
    "    # columns: {single: , onehalf: , double: }\n",
    "    # width_min_mm: \n    # width_max_mm: \n    # height_max_mm: \n",
    "    # dpi_min: \n    # dpi_max: \n    # dpi_min_inclusive: \n    # dpi_max_inclusive: \n",
    "    # dpi_line_art: \n    # dpi_bw: \n    # dpi_combination: \n",
    "    # formats: [ ]\n    # colour_mode: [ ]\n    # max_file_mb: \n",
    "    # font_families: [ ]\n    # font_min_pt: \n    # font_max_pt: \n",
    "    # min_line_pt: \n    # max_line_pt: \n",
    "    # tiff_compression: \n    # allow_alpha: \n    # flattened: \n    # max_pages: \n",
    "    # avoid_colour_pairs: [[red, green]]\n    # print_greyscale: \n",
    "    # panel_labels: uppercase\n    # panel_labels_placement: inside_panel\n",
    "    # max_panels: \n    # text_case: sentence\n    # text_no_final_stop: \n",
    "    # axes_from_zero: \n    # axis_lines_and_ticks: \n",
    "    # avoid_coloured_text: \n    # thousands_separator: \n    # no_background_grid: \n",
    "  not_stated:\n",
    "    # Fields you READ the page for and confirmed are absent. Do not list a\n",
    "    # field you simply did not check: leave it out and it reports as\n",
    "    # \"not yet harvested\", which is true.\n",
    "  # tables:\n",
    "    # formats: [html, docx]\n    # editable: \n",
    "    # orientation: portrait\n    # width_max_mm: \n",
    "    # font_families: [ ]\n    # font_min_pt: \n    # font_max_pt: \n",
    "    # title_style: \n    # title_position: above\n",
    "    # header_bold: \n    # vertical_rules: \n",
    "    # horizontal_rules: minimal\n    # decimal_alignment: \n",
    "    # footnotes: \n    # abbreviations: \n",
    "    # repeat_header: \n    # split_rows: \n",
    "  tables_not_stated:\n",
    "    # Table fields you checked and confirmed are absent.\n",
    "  # media: {video_formats: [ ], frame_max: {width: , height: }, max_file_mb: }\n",
    "  # notes: >\n"
  )
  cat(tmpl)
  invisible(tmpl)
}

#' Check a registry file before loading it
#'
#' Runs the same checks as [spec_load()] and returns the complete set of
#' problems in one report, making the file easier to correct in a single pass.
#'
#' @param path Path to a YAML file in registry format.
#' @return `TRUE` invisibly if the file is valid; otherwise the problems are
#'   reported and `FALSE` is returned invisibly.
#' @examples
#' # registry_validate_file("my-journals.yaml")
#' @export
registry_validate_file <- function(path) {
  entries <- read_registry_entries(path)
  problems <- registry_problems(entries)
  if (!length(problems)) {
    cli::cli_alert_success("{length(entries)} entr{?y/ies}, no problems found.")
    return(invisible(TRUE))
  }
  cli::cli_alert_danger("{length(problems)} problem{?s} found:")
  for (p in problems) cli::cli_li(p)
  invisible(FALSE)
}

# Link checking -----------------------------------------------------------

# HTTP status codes, split by what they say about the *page* rather than about
# the request. Most academic publishers sit behind bot protection and refuse a
# scripted request outright, so these two groups must not be merged: a refusal
# says nothing about whether the page is still there.
#
#   BLOCKED  the server declined to serve this client. The page is presumed
#            fine; a browser usually opens it without trouble.
#   DEAD     the server says the resource is gone. This is the only group
#            that counts as a broken link.
#
# Codes outside both groups are reported under their own headings rather than
# forced into one of these, so an unexpected response is visible as unexpected.
BLOCKED_CODES <- c(401L, 403L, 405L, 406L, 429L, 451L, 501L)
DEAD_CODES <- c(404L, 410L)

# Reduce one HTTP status code to the verdict reported to the user.
#
# @param code Integer status code, or NA when no response arrived at all.
# @return One of "ok", "dead", "blocked", "server error", "unreachable" or
#   "unexpected".
source_verdict <- function(code) {
  if (is.na(code)) return("unreachable")
  if (code >= 200 && code < 300) return("ok")
  if (code %in% DEAD_CODES) return("dead")
  if (code %in% BLOCKED_CODES) return("blocked")
  if (code >= 500) return("server error")
  "unexpected"
}

# Request one URL and report how it answered.
#
# HEAD is used first because a status code is all that is wanted and HEAD does
# not transfer the body. Some servers reject the method itself rather than the
# caller, which is indistinguishable from a block by status code alone, so a
# refusal is retried as a GET before it is believed.
#
# @param url The address to request.
# @param timeout Seconds to allow for connection and for the whole transfer.
# @return A list of `code` (integer status, NA if nothing arrived) and `final`
#   (the URL landed on after redirects, NA if nothing arrived).
fetch_status <- function(url, timeout) {
  probe <- function(nobody) {
    h <- curl::new_handle(followlocation = TRUE, nobody = nobody,
                          timeout = timeout, connecttimeout = timeout,
                          maxfilesize_large = 1024 * 1024,
                          useragent = "figspec source validator")
    tryCatch({
      r <- curl::curl_fetch_memory(url, handle = h)
      list(code = as.integer(r$status_code), final = r$url)
    }, error = function(e) list(code = NA_integer_, final = NA_character_))
  }
  res <- probe(nobody = TRUE)
  if (!is.na(res$code) && res$code %in% BLOCKED_CODES) {
    got <- probe(nobody = FALSE)
    if (!is.na(got$code)) res <- got
  }
  res
}

#' Check whether registry source pages still respond
#'
#' Every entry names the page it was read from, and a page can be taken down
#' without anything in the registry changing. This asks each source URL whether
#' it still resolves.
#'
#' A publisher that blocks robots is not a broken link. Most academic
#' publishers sit behind bot protection and answer a scripted request with
#' `403` while the page opens normally in a browser, so those are reported as
#' *blocked* and are not failures. Only `404` and `410` are read as dead.
#'
#' Run this during registry maintenance when an internet connection is
#' available. Offline package checks can use [registry_status()] to review the
#' stored sources and dates.
#'
#' @param ids Character vector of registry ids to check. Defaults to all of
#'   them.
#' @param timeout One positive number giving the seconds allowed for each
#'   response.
#' @return A data frame with one row per entry: `id`, `url`, `http` (the status
#'   code, `NA` if nothing answered), `verdict`, and `final_url` where a
#'   redirect led somewhere else. Ordered worst first.
#' @seealso [registry_status()] for how old an entry is, [registry_stale_entries()] for
#'   which are due a recheck.
#' @examples
#' # Reaches the network, so it is not run here.
#' \dontrun{
#' registry_check_sources()
#' registry_check_sources("plos_one")
#' }
#' @export
registry_check_sources <- function(ids = NULL, timeout = 10) {
  if (!has_package("curl")) {
    figspec_abort(
      c("{.fn registry_check_sources} needs the curl package.",
        ">" = 'Install it with {.code install.packages("curl")}.'),
      "needs_package", package = "curl")
  }
  if (!is.null(ids) &&
      (!is.character(ids) || !length(ids) || anyNA(ids) ||
       any(!nzchar(trimws(ids))) || anyDuplicated(ids))) {
    figspec_abort(
      "{.arg ids} must contain unique, non-empty registry ids.",
      "bad_input"
    )
  }
  if (!is.numeric(timeout) || length(timeout) != 1L || is.na(timeout) ||
      !is.finite(timeout) || timeout <= 0) {
    figspec_abort("{.arg timeout} must be one positive finite number of seconds.", "bad_input")
  }
  reg <- load_registry()
  if (!is.null(ids)) {
    unknown <- setdiff(ids, names(reg))
    if (length(unknown)) {
      figspec_abort(
        c("No registry entr{?y/ies} named {.val {unknown}}.",
          "i" = "See {.fn spec_list} for what is recorded."),
        "not_found", ids = unknown)
    }
    reg <- reg[ids]
  }

  rows <- lapply(reg, function(j) {
    res <- fetch_status(j$source_url, timeout)
    final <- if (!is.na(res$final) && !identical(res$final, j$source_url)) {
      res$final
    } else {
      NA_character_
    }
    data.frame(id = j$id, url = j$source_url, http = res$code,
               verdict = source_verdict(res$code), final_url = final,
               stringsAsFactors = FALSE)
  })
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  # Worst first, so the thing that needs doing is at the top.
  rank <- match(out$verdict,
                c("dead", "unreachable", "server error", "unexpected",
                  "blocked", "ok"))
  out <- out[order(rank, out$id), , drop = FALSE]
  rownames(out) <- NULL
  structure(out, class = c("figspec_sources", "data.frame"))
}

#' @export
print.figspec_sources <- function(x, ...) {
  cli::cli_h1("Registry sources")
  dead <- x[x$verdict == "dead", , drop = FALSE]
  other <- x[!x$verdict %in% c("ok", "blocked", "dead"), , drop = FALSE]
  blocked <- x[x$verdict == "blocked", , drop = FALSE]
  ok <- sum(x$verdict == "ok")

  if (nrow(dead)) {
    cli::cli_alert_danger("{nrow(dead)} source{?s} {?is/are} gone:")
    for (i in seq_len(nrow(dead))) {
      cli::cli_li("{dead$id[i]} - {dead$http[i]} {.url {dead$url[i]}}")
    }
  }
  if (nrow(other)) {
    cli::cli_alert_warning("{nrow(other)} source{?s} did not answer cleanly:")
    for (i in seq_len(nrow(other))) {
      cli::cli_li("{other$id[i]} - {other$verdict[i]} {.url {other$url[i]}}")
    }
  }
  moved <- x[!is.na(x$final_url), , drop = FALSE]
  if (nrow(moved)) {
    cli::cli_alert_info("{nrow(moved)} source{?s} redirected:")
    for (i in seq_len(nrow(moved))) {
      cli::cli_li("{moved$id[i]} - now {.url {moved$final_url[i]}}")
    }
  }
  if (!nrow(dead) && !nrow(other)) {
    cli::cli_alert_success("No source is gone.")
  }
  cli::cli_text("")
  cli::cli_text("{ok} source{?s} answered successfully.")
  if (nrow(blocked)) {
    cli::cli_text(
      "{nrow(blocked)} source{?s} blocked the automated request. Open the affected pages in a browser to complete the link check."
    )
  }
  invisible(x)
}
