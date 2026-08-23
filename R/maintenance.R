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

# Link checking -----------------------------------------------------------

# A publisher that blocks robots refuses the request, not the page. Seven of
# the registry's 27 sources answer 403 to a scripted request while the page
# itself is perfectly alive, so a checker that reads 403 as a dead link reports
# seven false alarms for every true one and stops being worth running. These
# are the codes that mean "the server declined to serve *you*".
BLOCKED_CODES <- c(401L, 403L, 405L, 406L, 429L, 451L, 501L)
DEAD_CODES <- c(404L, 410L)

# Classify one response. `code` is NA when nothing came back at all.
source_verdict <- function(code) {
  if (is.na(code)) return("unreachable")
  if (code >= 200 && code < 300) return("ok")
  if (code %in% DEAD_CODES) return("dead")
  if (code %in% BLOCKED_CODES) return("blocked")
  if (code >= 500) return("server error")
  "unexpected"
}

# HEAD is cheap and enough for a status code, but some servers reject the
# method itself rather than the request, so a refusal is retried as a GET
# before it is believed.
fetch_status <- function(url, timeout) {
  probe <- function(nobody) {
    h <- curl::new_handle(followlocation = TRUE, nobody = nobody,
                          timeout = timeout, connecttimeout = timeout)
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

#' Are the pages the registry cites still there
#'
#' Every entry names the page it was read from, and a page can be taken down
#' without anything in the registry changing. This asks each source URL whether
#' it still resolves.
#'
#' A publisher that blocks robots is not a broken link. Seven of the sources in
#' the registry answer `403` to a scripted request while the page opens fine in
#' a browser, so those are reported as *blocked* and are not failures. Only
#' `404` and `410` are read as dead. The distinction is the whole point: a
#' checker that counted every refusal as a death would cry wolf seven times for
#' each real one.
#'
#' This reaches the network, so it is for maintainers rather than for use
#' inside anything that has to run offline.
#'
#' @param ids Entries to check. Defaults to all of them.
#' @param timeout Seconds to wait for each response.
#' @return A data frame with one row per entry: `id`, `url`, `http` (the status
#'   code, `NA` if nothing answered), `verdict`, and `final_url` where a
#'   redirect led somewhere else. Ordered worst first.
#' @seealso [registry_status()] for how old an entry is, [stale_entries()] for
#'   which are due a recheck.
#' @examplesIf interactive() && requireNamespace("curl", quietly = TRUE)
#' check_sources("plos_one")
#' @export
check_sources <- function(ids = NULL, timeout = 10) {
  if (!requireNamespace("curl", quietly = TRUE)) {
    figspec_abort(
      c("{.fn check_sources} needs the curl package.",
        ">" = 'Install it with {.code install.packages("curl")}.'),
      "needs_package", package = "curl")
  }
  reg <- load_registry()
  if (!is.null(ids)) {
    unknown <- setdiff(ids, names(reg))
    if (length(unknown)) {
      figspec_abort(
        c("No registry entr{?y/ies} named {.val {unknown}}.",
          "i" = "See {.fn journals} for what is recorded."),
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
  cli::cli_text(
    "{ok} answered, {nrow(blocked)} blocked the request{cli::qty(nrow(blocked))}{?/ (not a failure - the page is there, the robot is not welcome)}."
  )
  invisible(x)
}
