#' Check a whole set of figures against one journal
#'
#' A submission is a set of figures, and they all have to pass. This runs
#' [check_journal()] over every figure and returns one row per file, so the
#' result is something you can read at a glance or hand to a co-author.
#'
#' Files are checked as files, which means geometry, format, resolution and
#' file size can be judged but type size cannot: point sizes do not survive
#' into a raster file. Check the plot objects with [check_journal()] before
#' saving if you need type size verified.
#'
#' @param path A directory, or a character vector of file paths.
#' @param journal Registry id, for example `"plos_one"`.
#' @param column Which column width the figures target. Either one value for
#'   all files, or a named character vector mapping file name to column.
#' @param dpi Resolution the files were written at. Useful for files that do
#'   not record it, such as those from base R's `png()` device.
#' @param pattern Regular expression selecting files when `path` is a
#'   directory. Defaults to common figure extensions.
#' @param recursive Whether to descend into subdirectories.
#' @return An object of class `figspec_submission`: a data frame with one row
#'   per file. The full per-requirement reports are kept in the `"reports"`
#'   attribute.
#' @examples
#' library(ggplot2)
#' dir <- file.path(tempdir(), "figs")
#' dir.create(dir, showWarnings = FALSE)
#' p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + theme_journal("frontiers")
#' suppressWarnings(
#'   ggsave_journal(file.path(dir, "figure_1.tiff"), p, "frontiers", check = FALSE)
#' )
#' check_submission(dir, "frontiers")
#' unlink(dir, recursive = TRUE)
#' @export
check_submission <- function(path, journal,
                             column = "single", dpi = NULL,
                             pattern = "\\.(tiff?|png|jpe?g|pdf|eps|ps|svg)$",
                             recursive = FALSE) {
  files <- if (length(path) == 1L && dir.exists(path)) {
    list.files(path, pattern = pattern, full.names = TRUE,
               recursive = recursive, ignore.case = TRUE)
  } else {
    path
  }
  if (!length(files)) {
    stop("No figure files found to check.", call. = FALSE)
  }
  missing <- files[!file.exists(files)]
  if (length(missing)) {
    stop("File(s) not found: ", paste(basename(missing), collapse = ", "),
         call. = FALSE)
  }

  col_for <- function(f) {
    if (length(column) == 1L && is.null(names(column))) return(column)
    hit <- column[[basename(f)]]
    if (is.null(hit)) "single" else hit
  }

  reports <- lapply(files, function(f) {
    check_journal(f, journal, column = col_for(f), dpi = dpi)
  })
  names(reports) <- basename(files)

  summarise_one <- function(r, f) {
    fails <- r$check[r$status == "fail"]
    open <- sum(r$status %in% c("unknown", "unspecified"))
    data.frame(
      file = basename(f),
      column = col_for(f),
      result = if (length(fails)) "fail" else if (open > 0) "pass, with gaps" else "pass",
      failed = if (length(fails)) paste(fails, collapse = ", ") else "",
      unresolved = open,
      stringsAsFactors = FALSE
    )
  }
  out <- do.call(rbind, Map(summarise_one, reports, files))
  rownames(out) <- NULL

  spec <- journal_spec(journal)
  structure(
    out,
    reports = reports,
    journal = spec$name,
    source_url = spec$source_url,
    verified_on = spec$verified_on,
    class = c("figspec_submission", "data.frame")
  )
}

#' @export
`[.figspec_submission` <- function(x, ...) {
  out <- NextMethod()
  if (is.data.frame(out)) {
    attributes(out)[c("reports", "journal", "source_url", "verified_on")] <- NULL
    class(out) <- "data.frame"
  }
  out
}

#' @export
print.figspec_submission <- function(x, ...) {
  cli::cli_h1("Submission check - {attr(x, 'journal')}")
  cli::cli_text("{nrow(x)} figure{?s} checked")
  cli::cli_text("")
  for (i in seq_len(nrow(x))) {
    r <- x[i, ]
    label <- paste0(format(r$file, width = 26), " ", r$column)
    if (r$result == "fail") {
      cli::cli_alert_danger("{label}  failed: {r$failed}")
    } else if (r$result == "pass, with gaps") {
      cli::cli_alert_success("{label}  no failures ({r$unresolved} not judged)")
    } else {
      cli::cli_alert_success("{label}  all requirements met")
    }
  }
  cli::cli_text("")
  n_fail <- sum(x$result == "fail")
  if (n_fail == 0) {
    cli::cli_alert_success("No figure breaches a requirement on record.")
  } else {
    cli::cli_alert_danger("{n_fail} figure{?s} would fail this journal.")
  }
  if (any(x$unresolved > 0)) {
    cli::cli_alert_info(
      "Some requirements cannot be judged from a saved file - type size in particular. Check the plot objects before saving."
    )
  }
  cli::cli_text("{.strong Source:} {.url {attr(x, 'source_url')}} (verified {attr(x, 'verified_on')})")
  invisible(x)
}

#' The full report for one file in a submission check
#'
#' @param x A `figspec_submission` object.
#' @param file File name, as shown in the submission table.
#' @return The `figspec_report` for that file.
#' @examples
#' # See check_submission() for a worked example.
#' @export
submission_detail <- function(x, file) {
  reports <- attr(x, "reports")
  if (is.null(reports) || !file %in% names(reports)) {
    stop("No report for '", file, "'. Available: ",
         paste(names(reports), collapse = ", "), call. = FALSE)
  }
  reports[[file]]
}
