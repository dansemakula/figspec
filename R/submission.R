# Checking a set of figures together ----------------------------------------
#
# submission_check() runs fig_check() over several figures and reduces each
# report to a single row, so a set can be read at a glance.
#
# It accepts three shapes of input, because people arrive with different ones:
# a named list of plot objects, a directory to scan, or an explicit vector of
# file paths. Plots are worth more than files, for the reason set out in
# R/check.R - a saved raster has lost its type sizes and its colour mapping -
# so the summary records which it was given.
#
# One thing here is not a compliance check at all. Given plot objects, the
# panel width of each figure is measured and the spread across the set is
# reported. No publisher states a rule about it, so it can never be a failure;
# it is printed apart from the pass and fail lines because a set of figures
# that each meet the width requirement can still look uneven on the page, and
# that is usually what an author is actually trying to fix.
#
# The per-figure reports are kept whole in the "reports" attribute, so
# submission_detail() can show the full finding for any one file.

#' Review a set of figures together
#'
#' Runs [fig_check()] over every figure in a collection and returns one summary
#' row per figure. Use it to review the figures for a manuscript, report,
#' presentation or other project in one place, while retaining the full check
#' report for each item.
#'
#' Check plot objects before export and the written files afterwards when you
#' can. The plot objects preserve typography, colour mappings and panel
#' geometry. The files provide the actual dimensions, resolution, format,
#' validity and file size. Raster files cannot preserve editable type-size
#' information, so the two checks answer complementary questions.
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
#' @param x A non-empty list containing only plots, a directory path, or a
#'   character vector of figure-file paths. Plot names and file basenames are
#'   used in the summary.
#' @param spec The specification to use: a registry id, a `figspec_spec`, a
#'   named list of requirements, or `NULL` to inspect without assigning pass or
#'   fail results.
#' @param column Which named width each figure targets. Supply one non-empty
#'   name for the whole set, or a uniquely named character vector covering
#'   every figure name in `x`.
#' @param dpi The shared resolution of files that do not record it themselves.
#'   It is also the intended export resolution when `x` contains live plots.
#' @param pattern Regular expression selecting files when `x` is a directory.
#'   Defaults to common figure extensions.
#' @param recursive Whether a directory scan should include subdirectories.
#'   Must be one `TRUE` or `FALSE` value.
#' @param art_type Resolution category passed to [fig_check()]. `"auto"` uses
#'   the content of a live plot; for saved files, where that evidence has been
#'   lost, it applies the strictest recorded threshold. Explicit choices are
#'   `"colour"`, `"bw"`, `"line"` and `"combination"`.
#' @return An object of class `figspec_submission`: a data frame with one row
#'   per figure. The full per-requirement reports are kept in the `"reports"`
#'   attribute.
#' @examples
#' library(ggplot2)
#' figs <- list(
#'   vehicles = ggplot(ggplot2::mpg, aes(displ, hwy)) + geom_point(),
#'   economy = ggplot(ggplot2::economics, aes(date, unemploy)) +
#'     geom_line() + labs(y = "Number of unemployed people")
#' )
#' figs$vehicles
#' figs$economy
#' submission_check(figs, "frontiers")
#' @export
submission_check <- function(x, spec = NULL,
                             column = NULL, dpi = NULL,
                             pattern = "\\.(tiff?|png|jpe?g|pdf|eps|ps|svg)$",
                             recursive = FALSE,
                             art_type = c("auto", "colour", "bw", "line", "combination")) {
  if (!is.character(pattern) || length(pattern) != 1L ||
      is.na(pattern) || !nzchar(pattern)) {
    figspec_abort("{.arg pattern} must be one non-empty regular expression.", "bad_input")
  }
  valid_pattern <- tryCatch({
    suppressWarnings(grepl(pattern, ""))
    TRUE
  }, error = function(e) FALSE)
  if (!valid_pattern) {
    figspec_abort("{.arg pattern} is not a valid regular expression.", "bad_input")
  }
  if (!is.logical(recursive) || length(recursive) != 1L || is.na(recursive)) {
    figspec_abort("{.arg recursive} must be one TRUE or FALSE value.", "bad_input")
  }
  check_dpi(dpi)
  art_type <- british_spelling(art_type)
  art_type <- match.arg(art_type)
  is_plots <- is.list(x) && !is.data.frame(x) &&
    all(vapply(x, function(e) is_ggplot_object(e) || inherits(e, "gtable"),
               logical(1)))

  if (is_plots) {
    if (!length(x)) figspec_abort("{.arg x} is empty: there are no figures to check.", "bad_input")
    items <- x
    labels <- names(x) %||% paste0("figure_", seq_along(x))
    missing_labels <- is.na(labels) | !nzchar(trimws(labels))
    labels[missing_labels] <- paste0("figure_", which(missing_labels))
    labels <- make.unique(labels, sep = "__")
  } else {
    if (is.list(x) && !is.data.frame(x)) {
      figspec_abort(
        c(
          "When {.arg x} is a list, every item must be a plot or supported gtable.",
          "i" = "Pass file paths as a character vector instead of a list."
        ),
        "bad_input"
      )
    }
    if (!is.character(x) || !length(x) || anyNA(x) ||
        any(!nzchar(trimws(x)))) {
      figspec_abort(
        "{.arg x} must be a non-empty plot list, directory path, or character vector of file paths.",
        "bad_input"
      )
    }
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
    directories <- files[dir.exists(files)]
    if (length(directories)) {
      figspec_abort(
        c(
          "A character vector of files cannot contain directories.",
          "i" = "Supply one directory path to scan it, or list the figure files explicitly."
        ),
        "bad_input",
        paths = directories
      )
    }
    items <- as.list(files)
    labels <- make.unique(basename(files), sep = "__")
  }

  spec_for_column <- if (is.null(spec)) NULL else spec_get(spec)
  if (!is.null(column)) {
    if (is.null(spec)) {
      figspec_abort(
        c(
          "{.arg column} cannot be used without a specification.",
          "i" = "Supply {.arg spec}, or leave {.arg column} as NULL for an inspection-only review."
        ),
        "bad_input"
      )
    }
    if (!is.character(column) || !length(column) || anyNA(column) ||
        any(!nzchar(trimws(column)))) {
      figspec_abort("{.arg column} must contain non-empty width names.", "bad_input")
    }
    mapped <- !(length(column) == 1L && is.null(names(column)))
    if (mapped) {
      column_names <- names(column)
      if (is.null(column_names) || anyNA(column_names) ||
          any(!nzchar(trimws(column_names))) || anyDuplicated(column_names)) {
        figspec_abort(
          "A per-figure {.arg column} vector must have unique, non-empty names.",
          "bad_input"
        )
      }
      missing_columns <- setdiff(labels, column_names)
      extra_columns <- setdiff(column_names, labels)
      if (length(missing_columns) || length(extra_columns)) {
        details <- c(
          if (length(missing_columns)) {
            paste0("Missing figure names: ", paste(missing_columns, collapse = ", "), ".")
          },
          if (length(extra_columns)) {
            paste0("Unknown figure names: ", paste(extra_columns, collapse = ", "), ".")
          }
        )
        figspec_abort(
          c(
            "The names in {.arg column} must match the figure names exactly.",
            "x" = details
          ),
          "bad_input"
        )
      }
    }
  }
  col_for <- function(nm) {
    if (is.null(column)) return(default_column(spec_for_column) %||% NA_character_)
    if (length(column) == 1L && is.null(names(column))) return(column)
    unname(column[[nm]])
  }

  reports <- Map(function(it, nm) {
    fig_check(it, spec, column = col_for(nm), dpi = dpi, art_type = art_type)
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
        canvas <- if (is.null(spec)) NA_real_ else {
          fig_width(spec, col_for(labels[[i]]), "mm")
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
    invalid <- any(r$status == "invalid")
    open <- sum(r$status == "unknown")
    absent <- sum(r$status == "unspecified")
    data.frame(
      file = nm,
      column = col_for(nm),
      result = if (invalid) "invalid" else if (length(fails)) "fail" else if (open > 0) "incomplete" else "pass",
      failed = if (length(fails)) paste(fails, collapse = ", ") else "",
      unresolved = open,
      unspecified = absent,
      panel_mm = round(panel_mm, 2),
      stringsAsFactors = FALSE
    )
  }
  out <- do.call(rbind, Map(summarise_one, reports, labels, panels))
  rownames(out) <- NULL

  resolved <- if (is.null(spec)) NULL else spec_get(spec)
  structure(
    out,
    reports = reports,
    spec_name = if (is.null(resolved)) NULL else resolved$name,
    source_url = if (is.null(resolved)) NULL else resolved$source_url,
    verified_on = if (is.null(resolved)) NULL else resolved$verified_on,
    from_plots = is_plots,
    class = c("figspec_submission", "data.frame")
  )
}

# Subsetting a submission yields a plain data frame, for the same reason as
# `[.figspec_report`: the attributes describe the whole check, and a selection
# of rows is no longer that check.
#
#' @export
`[.figspec_submission` <- function(x, ...) {
  out <- NextMethod()
  if (is.data.frame(out)) {
    attributes(out)[c("reports", "spec_name", "source_url", "verified_on",
                      "from_plots")] <- NULL
    class(out) <- "data.frame"
  }
  out
}

#' @export
print.figspec_submission <- function(x, ...) {
  jn <- attr(x, "spec_name")
  cli::cli_h1(if (is.null(jn)) "Submission check" else "Submission check - {jn}")
  cli::cli_text("{nrow(x)} figure{?s} checked")
  cli::cli_text("")
  for (i in seq_len(nrow(x))) {
    r <- x[i, ]
    label <- paste0(format(r$file, width = 26), " ", r$column)
    if (r$result == "invalid") {
      cli::cli_alert_danger("{label}  invalid or unreadable input")
    } else if (r$result == "fail") {
      cli::cli_alert_danger("{label}  failed: {r$failed}")
    } else if (r$result == "incomplete") {
      cli::cli_alert_warning("{label}  incomplete ({r$unresolved} recorded requirement(s) not judged)")
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
  n_invalid <- sum(x$result == "invalid")
  if (n_invalid > 0) {
    cli::cli_alert_danger("{n_invalid} input{?s} invalid; no compliance conclusion is possible.")
  } else if (n_fail == 0 && !any(x$result == "incomplete")) {
    cli::cli_alert_success("No figure breaches a requirement on record.")
  } else if (n_fail == 0) {
    cli::cli_alert_warning("No failures found, but at least one figure is not fully assessed.")
  } else {
    cli::cli_alert_danger("{n_fail} figure{?s} would fail this specification.")
  }
  if (any(x$unresolved > 0)) {
    # Told to check plots, the advice to check plots is noise, and the reason
    # for the gaps is different: the registry, not the file format.
    cli::cli_alert_info(if (isTRUE(attr(x, "from_plots"))) {
      "Some requirements are not on record in this specification, so they were not judged."
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

#' Open the full report for one figure
#'
#' [submission_check()] gives one summary row for each figure. This function
#' retrieves the underlying [fig_check()] report for the figure you select, so
#' you can see every requirement, the measured value and the reason for any
#' failure or unresolved result.
#'
#' @param x The complete `figspec_submission` object returned by
#'   [submission_check()].
#' @param file Exactly one figure name from the `file` column of `x`. For live
#'   plots this is the list name; for saved figures it is the file name shown
#'   in the submission summary.
#' @return The `figspec_report` for that file.
#' @examples
#' library(ggplot2)
#' figures <- list(
#'   vehicles = ggplot(ggplot2::mpg, aes(displ, hwy)) + geom_point(),
#'   economy = ggplot(ggplot2::economics, aes(date, unemploy)) + geom_line()
#' )
#' review <- submission_check(figures, "frontiers")
#' submission_detail(review, "vehicles")
#' @export
submission_detail <- function(x, file) {
  if (!inherits(x, "figspec_submission")) {
    figspec_abort(
      "{.arg x} must be the complete result returned by {.fn submission_check}.",
      "bad_input"
    )
  }
  if (!is.character(file) || length(file) != 1L || is.na(file) ||
      !nzchar(trimws(file))) {
    figspec_abort(
      "{.arg file} must be one non-empty figure name from {.code x$file}.",
      "bad_input"
    )
  }
  reports <- attr(x, "reports")
  if (is.null(reports) || !length(reports)) {
    figspec_abort(
      "{.arg x} does not contain the per-figure reports from {.fn submission_check}.",
      "bad_input"
    )
  }
  if (!file %in% names(reports)) {
    figspec_abort(
      c("No report for {.val {file}}.",
        "i" = "Available: {.val {names(reports)}}."),
      "not_found", file = file)
  }
  reports[[file]]
}
