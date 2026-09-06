# Moving a set of figures between journals -----------------------------------
#
# Papers are rejected and resubmitted, and the requirements of the next journal
# are not the requirements of the last. The conflicts are real rather than
# cosmetic: Cell Press asks for type between 6 and 8 pt and PLOS ONE between 8
# and 12, so a figure built for one is out of range for the other by
# construction and cannot satisfy both.
#
# This re-exports editable figure objects against a new specification. It needs
# the live figures, not finished files, because type, colour and line settings
# have already been flattened in a saved raster.

#' Re-export a figure set for a new specification
#'
#' A figure set may need to move to a different journal, report template or
#' organisational standard. This takes the editable figures you already
#' have and exports the whole set against the new specification.
#'
#' It works from live figure objects, not from saved files, and that is
#' deliberate.
#' Type size cannot be recovered from a saved raster, and rescaling one only
#' degrades it, so re-fitting a finished TIFF cannot produce a compliant
#' figure. Keep your plots in a list and this stays a one-line operation.
#'
#' @param plots A non-empty named list of editable figures. Supported inputs
#'   include ggplot2 and patchwork objects, lattice and Plotly plots, grid
#'   grobs, and base-graphics code wrapped in functions or one-sided formulas.
#'   Names become file stems and must be unique and safe to use as file names.
#' @param spec The new specification: a registry id, a `figspec_spec`, or a
#'   named list of requirements.
#' @param output_dir One directory to write into. It is created if necessary.
#' @param column Which column width to use, either one value for all plots or
#'   a uniquely named vector mapping every plot name to a width.
#' @param retheme Whether to apply the requirements exposed by each plotting
#'   system before export. Must be one `TRUE` or `FALSE`.
#' @param format File extension without a dot. Defaults to the first writable
#'   format accepted by the specification.
#' @return A [submission_check()] report for the files written.
#' @examples
#' library(ggplot2)
#' p <- ggplot(ggplot2::mpg, aes(displ, hwy, colour = class)) + geom_point()
#' p
#' dir <- file.path(tempdir(), "refit")
#' res <- suppressWarnings(
#'   fig_refit(list(figure_1 = p), "frontiers", dir)
#' )
#' res
#' unlink(dir, recursive = TRUE)
#' @export
fig_refit <- function(plots, spec, output_dir,
                          column = NULL, retheme = TRUE, format = NULL) {
  if (!is.list(plots) || !length(plots) || is.null(names(plots)) ||
      anyNA(names(plots)) || any(!nzchar(trimws(names(plots))))) {
    figspec_abort(
      c("{.arg plots} must be a named list of plot objects.",
        "i" = "The names become the file names, so every element needs one."),
      "bad_input")
  }
  systems <- vapply(
    plots,
    function(x) figure_system_or_null(x) %||% "",
    character(1)
  )
  if (any(!nzchar(systems)) || any(!vapply(systems, transform_capable_system, logical(1)))) {
    bad <- names(plots)[!nzchar(systems) |
      !vapply(systems, transform_capable_system, logical(1))]
    figspec_abort(
      c("{.fn fig_refit} needs editable live figures, not completed files or drawings.",
        "x" = "Not editable through figspec: {.val {bad}}.",
        "i" = "Use ggplot2, patchwork, lattice, Plotly, a grid grob, or base-graphics code wrapped in a function or one-sided formula."),
      "bad_input", names = bad)
  }
  stems <- names(plots)
  unsafe <- !grepl("^[A-Za-z0-9][A-Za-z0-9_.-]*$", stems) |
    stems %in% c(".", "..") | grepl("[\\/\\\\]", stems)
  if (any(unsafe)) {
    figspec_abort(
      c("Plot names must be safe file names.",
        "x" = "Unsafe: {.val {stems[unsafe]}}.",
        "i" = "Directory separators, traversal names, and control characters are not allowed."),
      "bad_input", names = stems[unsafe])
  }
  if (anyDuplicated(tolower(stems))) {
    figspec_abort("Plot names must be unique even on case-insensitive filesystems.", "bad_input")
  }
  if (!is.character(output_dir) || length(output_dir) != 1L || is.na(output_dir) ||
      !nzchar(trimws(output_dir))) {
    figspec_abort("{.arg output_dir} must be one non-empty directory path.", "bad_input")
  }
  if (file.exists(output_dir) && !dir.exists(output_dir)) {
    figspec_abort("{.arg output_dir} points to a file, not a directory: {.file {output_dir}}.", "bad_input")
  }
  if (!is.logical(retheme) || length(retheme) != 1L || is.na(retheme)) {
    figspec_abort("{.arg retheme} must be one TRUE or FALSE value.", "bad_input")
  }
  spec <- spec_get(spec)
  if (is.null(column)) column <- default_column(spec)
  if (!is.null(column)) {
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
          "A per-plot {.arg column} vector must have unique, non-empty names.",
          "bad_input"
        )
      }
      missing_columns <- setdiff(stems, column_names)
      extra_columns <- setdiff(column_names, stems)
      if (length(missing_columns) || length(extra_columns)) {
        details <- c(
          if (length(missing_columns)) paste0("Missing plot names: ", paste(missing_columns, collapse = ", "), "."),
          if (length(extra_columns)) paste0("Unknown plot names: ", paste(extra_columns, collapse = ", "), ".")
        )
        figspec_abort(
          c("The names in {.arg column} must match the plot names exactly.", "x" = details),
          "bad_input"
        )
      }
    }
  }
  if (!is.null(format) &&
      (!is.character(format) || length(format) != 1L || is.na(format) ||
       !grepl("^[A-Za-z0-9]+$", format))) {
    figspec_abort(
      "{.arg format} must be one file extension without a leading dot.",
      "bad_input"
    )
  }
  fmt <- if (is.null(format)) default_format(spec) else tolower(format)
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  if (!dir.exists(output_dir)) {
    figspec_abort("Could not create {.arg output_dir}: {.file {output_dir}}.", "bad_input")
  }

  col_for <- function(nm) {
    if (is.null(column)) return(NULL)
    if (length(column) == 1L && is.null(names(column))) return(column)
    unname(column[[nm]])
  }

  written <- character(0)
  merged_reports <- list()
  for (nm in names(plots)) {
    p <- plots[[nm]]
    dest <- file.path(output_dir, paste0(nm, ".", fmt))
    tmp <- tempfile(pattern = paste0(".", nm, "-"), tmpdir = output_dir,
                    fileext = paste0(".", fmt))
    on.exit(unlink(tmp), add = TRUE)
    saved <- fig_save(
      tmp, p, spec = spec, column = col_for(nm),
      transform = retheme, check = TRUE
    )
    if (!file.rename(tmp, dest)) {
      figspec_abort("Could not atomically place {.file {dest}}.", "bad_input")
    }
    written <- c(written, dest)
    merged_reports[[basename(dest)]] <- attr(saved, "figspec_report")
  }
  check_column <- if (is.null(column) ||
                      (length(column) == 1L && is.null(names(column)))) {
    column
  } else {
    stats::setNames(unname(column[stems]), basename(written))
  }
  out <- submission_check(written, spec, column = check_column)
  attr(out, "reports") <- merged_reports
  for (i in seq_len(nrow(out))) {
    r <- merged_reports[[out$file[[i]]]]
    fails <- r$check[r$status == "fail"]
    out$result[[i]] <- if (any(r$status == "invalid")) {
      "invalid"
    } else if (length(fails)) {
      "fail"
    } else if (any(r$status == "unknown")) {
      "incomplete"
    } else "pass"
    out$failed[[i]] <- paste(fails, collapse = ", ")
    out$unresolved[[i]] <- sum(r$status == "unknown")
    out$unspecified[[i]] <- sum(r$status == "unspecified")
  }
  out
}
