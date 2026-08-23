#' Check a whole set of figures together
#'
#' A submission is a set of figures that have to pass as a set. This runs
#' [fig_check()] over every one and returns a row each, so the result is
#' something you can read at a glance or hand to a co-author.
#'
#' Give it plot objects rather than files where you can. A written file has
#' lost the information that only the plot carries: type size and panel
#' geometry do not survive into a raster. From files, geometry, format,
#' resolution and file size can still be judged.
#'
#' # Panel consistency
#'
#' Given plot objects, this also reports the plot area of each figure. Figures
#' that meet the same width requirement still have different plot areas when
#' their axis labels differ in length, and on the page that is what makes a set
#' look uneven. No publisher states a rule about it, so it is never reported as
#' a failure — it is an observation about your own figures, and [fig_save()]
#' with a shared `panel_width` from [fig_panel_width()] is the fix.
#'
#' @param x A list of plots; or a directory; or a character vector of file
#'   paths.
#' @param journal Registry id, for example `"plos_one"`; a specification from
#'   [journal_spec()]; or `NULL` to inspect the figures without judging them.
#' @param column Which column width the figures target. Either one value for
#'   all, or a named character vector mapping name to column.
#' @param dpi Resolution the files were written at. Useful for files that do
#'   not record it, such as those from base R's `png()` device.
#' @param pattern Regular expression selecting files when `x` is a directory.
#'   Defaults to common figure extensions.
#' @param recursive Whether to descend into subdirectories.
#' @return An object of class `figspec_submission`: a data frame with one row
#'   per figure. The full per-requirement reports are kept in the `"reports"`
#'   attribute.
#' @examples
#' library(ggplot2)
#' figs <- list(
#'   fig1 = ggplot(mtcars, aes(wt, mpg)) + geom_point(),
#'   fig2 = ggplot(mtcars, aes(wt, mpg * 100000)) + geom_point()
#' )
#' check_submission(figs, "frontiers")
#' @export
check_submission <- function(x, journal = NULL,
                             column = "single", dpi = NULL,
                             pattern = "\\.(tiff?|png|jpe?g|pdf|eps|ps|svg)$",
                             recursive = FALSE) {
  is_plots <- is.list(x) && !is.data.frame(x) &&
    all(vapply(x, function(e) is_ggplot_object(e) || inherits(e, "gtable"),
               logical(1)))

  if (is_plots) {
    if (!length(x)) figspec_abort("{.arg x} is empty: there are no figures to check.", "bad_input")
    items <- x
    labels <- names(x) %||% paste0("figure_", seq_along(x))
    labels[!nzchar(labels)] <- paste0("figure_", which(!nzchar(labels)))
  } else {
    files <- if (is.character(x) && length(x) == 1L && dir.exists(x)) {
      list.files(x, pattern = pattern, full.names = TRUE,
                 recursive = recursive, ignore.case = TRUE)
    } else {
      x
    }
    if (!length(files)) figspec_abort(
      c("No figure files found to check.",
        "i" = "Looked for files matching {.val {pattern}}.",
        ">" = "Widen {.arg pattern}, or set {.code recursive = TRUE} to look in
               subdirectories."),
      "not_found")
    missing <- files[!file.exists(files)]
    if (length(missing)) {
      figspec_abort(
        "{cli::qty(missing)}File{?s} not found: {.file {basename(missing)}}.",
        "not_found", paths = missing)
    }
    items <- as.list(files)
    labels <- basename(files)
  }

  col_for <- function(nm) {
    if (length(column) == 1L && is.null(names(column))) return(column)
    hit <- column[[nm]]
    if (is.null(hit)) "single" else hit
  }

  reports <- Map(function(it, nm) {
    fig_check(it, journal, column = col_for(nm), dpi = dpi)
  }, items, labels)
  names(reports) <- labels

  # Panel geometry is only recoverable from a plot object. Reporting NA from
  # files is honest; guessing from pixel dimensions would not be.
  panels <- if (is_plots) {
    vapply(seq_along(items), function(i) {
      tryCatch({
        g <- fig_geometry(items[[i]])
        # A plot already sized by fig_panel_size() reports its own panel. One
        # that has not been sized has no panel width until a canvas is chosen,
        # so take the canvas from the specification and work it out.
        if (!is.na(g$panel_width_mm)) return(g$panel_width_mm)
        canvas <- if (is.null(journal)) NA_real_ else {
          fig_width(journal, col_for(labels[[i]]), "mm")
        }
        if (is.na(canvas)) return(NA_real_)
        n <- max(count_panel_tracks(as_plot_gtable(items[[i]]), "width"), 1)
        (canvas - g$decoration_width_mm) / n
      }, error = function(e) NA_real_)
    }, numeric(1))
  } else {
    rep(NA_real_, length(items))
  }

  summarise_one <- function(r, nm, panel_mm) {
    fails <- r$check[r$status == "fail"]
    open <- sum(r$status %in% c("unknown", "unspecified"))
    data.frame(
      file = nm,
      column = col_for(nm),
      result = if (length(fails)) "fail" else if (open > 0) "pass, with gaps" else "pass",
      failed = if (length(fails)) paste(fails, collapse = ", ") else "",
      unresolved = open,
      panel_mm = round(panel_mm, 2),
      stringsAsFactors = FALSE
    )
  }
  out <- do.call(rbind, Map(summarise_one, reports, labels, panels))
  rownames(out) <- NULL

  spec <- if (is.null(journal)) NULL else journal_spec(journal)
  structure(
    out,
    reports = reports,
    journal = if (is.null(spec)) NULL else spec$name,
    source_url = if (is.null(spec)) NULL else spec$source_url,
    verified_on = if (is.null(spec)) NULL else spec$verified_on,
    from_plots = is_plots,
    class = c("figspec_submission", "data.frame")
  )
}

#' @export
`[.figspec_submission` <- function(x, ...) {
  out <- NextMethod()
  if (is.data.frame(out)) {
    attributes(out)[c("reports", "journal", "source_url", "verified_on",
                      "from_plots")] <- NULL
    class(out) <- "data.frame"
  }
  out
}

#' @export
print.figspec_submission <- function(x, ...) {
  jn <- attr(x, "journal")
  cli::cli_h1(if (is.null(jn)) "Submission check" else "Submission check - {jn}")
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
  # Panel spread is a fact about this set of figures, not a requirement any
  # publisher states. It is printed apart from the pass/fail lines and never
  # counted among them, because a green tick against an invented rule is the
  # same error as inventing the rule.
  if (isTRUE(attr(x, "from_plots")) && nrow(x) > 1L && !all(is.na(x$panel_mm))) {
    spread <- diff(range(x$panel_mm, na.rm = TRUE))
    cli::cli_text("")
    if (spread > 0.5) {
      widest <- x$file[which.max(x$panel_mm)]
      tightest <- x$file[which.min(x$panel_mm)]
      cli::cli_alert_info(paste0(
        "Plot areas differ by {round(spread, 1)} mm across this set ",
        "({tightest} {round(min(x$panel_mm, na.rm = TRUE), 1)} mm, ",
        "{widest} {round(max(x$panel_mm, na.rm = TRUE), 1)} mm). ",
        "No publisher requires them to match, so this is not a failure. ",
        "To make them match, pass fig_panel_width() to fig_save()."
      ))
    } else {
      cli::cli_alert_success(paste0(
        "Plot areas match across this set ",
        "({round(stats::median(x$panel_mm, na.rm = TRUE), 1)} mm)."
      ))
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
    # Told to check plots, the advice to check plots is noise, and the reason
    # for the gaps is different: the registry, not the file format.
    cli::cli_alert_info(if (isTRUE(attr(x, "from_plots"))) {
      "Some requirements are not on record for this journal, so they were not judged."
    } else {
      "Some requirements cannot be judged from a saved file - type size in particular. Check the plot objects before saving."
    })
  }
  src <- attr(x, "source_url")
  if (!is.null(src) && nzchar(src)) {
    seen <- attr(x, "verified_on")
    cli::cli_text(
      "{.strong Source:} {.url {src}}",
      if (!is.null(seen) && nzchar(seen)) " (verified {seen})" else ""
    )
  }
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
    figspec_abort(
      c("No report for {.val {file}}.",
        "i" = "Available: {.val {names(reports)}}."),
      "not_found", file = file)
  }
  reports[[file]]
}
