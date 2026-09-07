# Looking a specification up -------------------------------------------------
#
# Reading values out of a specification, for callers who want the number rather
# than a verdict: how wide a column is, which columns exist, what the tables or
# the graphical abstract require.
#
# Two things recur here and are worth knowing before reading any of it.
#
# Column names are not universal. Most publishers name a single and a double
# column, some add a one-and-a-half, and a few - PNAS among them - use their
# own vocabulary entirely, "small", "medium" and "large". So a request for a
# column that does not exist is answered by naming the ones that do, rather
# than by falling back to a width the publisher never stated.
#
# Some publishers give a range instead of named columns. Those entries have no
# `columns` at all, only a minimum and a maximum, and asking for a column from
# one is a question it cannot answer.

default_column <- function(spec) {
  if (!is.null(spec$columns) && length(spec$columns)) return(names(spec$columns)[[1]])
  if (!is.null(spec$width_min_mm)) return("single")
  NULL
}

#' Look up a figure width
#'
#' Returns a named figure width from a publication, project or organisational
#' specification. The specification defines both the available names and their
#' widths: for example, Cell Press records `"single"`, `"onehalf"` and
#' `"double"`, while Science also records `"triple"`. Use [fig_columns()] to
#' see the names available in a specification.
#'
#' When a specification records a permitted range instead of named widths,
#' `"single"` returns the minimum and `"double"` returns the maximum.
#'
#' @param spec The specification to use: a registry id such as
#'   `"cell_press"`, a `figspec_spec`, or a named list of requirements.
#' @param column Name of the required width, such as `"single"`, `"double"`
#'   or `"triple"`. The available names come from the specification.
#' @param units Unit for the returned width: `"mm"`, `"cm"` or `"in"`.
#' @return A single numeric width in the requested unit. An error is raised if
#'   the specification does not contain the requested width.
#' @examples
#' fig_width("cell_press", "single")
#' fig_width("science", "triple")
#' fig_width("frontiers", "double", units = "in")
#'
#' report_spec <- spec_get(list(
#'   name = "Research report",
#'   columns = list(half = 80, full = 160)
#' ))
#' fig_width(report_spec, "full")
#' @export
fig_width <- function(spec, column = "single", units = c("mm", "cm", "in")) {
  units <- match.arg(units)
  spec <- spec_get(spec)
  if (!is.character(column) || length(column) != 1L ||
      is.na(column) || !nzchar(column)) {
    figspec_abort(
      c("{.arg column} must be one non-empty width name.",
        "x" = if (length(column) != 1L) {
          "You gave {length(column)} value{?s}."
        } else if (!is.character(column)) {
          "You gave {.cls {class(column)}}."
        } else {
          "You gave a missing or empty name."
        }),
      "bad_input")
  }

  if (!is.null(spec$columns)) {
    w <- spec$columns[[column]]
    if (is.null(w)) {
      stated <- paste0(names(spec$columns), " (", unlist(spec$columns), " mm)")
      figspec_abort(
        c("{spec$name} does not have a {.val {column}} column.",
          "i" = "It states: {stated}."),
        "not_found", column = column, available = names(spec$columns))
    }
  } else {
    w <- switch(column,
      single = spec$width_min_mm,
      double = spec$width_max_mm,
      NULL
    )
    if (is.null(w)) {
      figspec_abort(
        c("{spec$name} does not state a {column}-column width.",
          "i" = "It gives a width range rather than named columns.",
          ">" = "Set the width explicitly, and see {.url {spec$source_url}}."),
        "not_found", column = column)
    }
  }
  convert_length(as.numeric(w), "mm", units)
}

#' List the available figure widths
#'
#' Lists the named widths recorded in a publication, project or organisational
#' specification. The returned names can be supplied to the `column` argument
#' of [fig_width()], [fig_save()] and other figspec functions.
#'
#' Some sources state only a permitted width range. In that case there are no
#' named choices to list, so the function explains the range and returns
#' `NULL`.
#'
#' @param spec The specification to inspect: a registry id, a
#'   `figspec_spec`, or a named list of requirements.
#' @return A named numeric vector of widths in millimetres, or `NULL` when the
#'   specification records a range instead of named widths.
#' @examples
#' fig_columns("science")
#' fig_columns("cell_press")
#'
#' report_spec <- list(
#'   name = "Research report",
#'   columns = list(half = 80, full = 160)
#' )
#' fig_columns(report_spec)
#' @export
fig_columns <- function(spec) {
  spec <- spec_get(spec)
  if (is.null(spec$columns)) {
    msg_wrap(
      "'", spec$name, "' states a width range rather than named columns: ",
      spec$width_min_mm %||% "?", " to ", spec$width_max_mm %||% "?", " mm."
    )
    return(invisible(NULL))
  }
  stats::setNames(as.numeric(unlist(spec$columns)), names(spec$columns))
}

#' @export
print.figspec_spec <- function(x, ...) {
  cli::cli_h1(x$name)
  if (!is.null(x$publisher)) cli::cli_text("{.strong Publisher:} {x$publisher}")
  if (length(x$disciplines)) {
    cli::cli_text("{.strong Disciplines:} {paste(x$disciplines, collapse = ', ')}")
  }
  if (!is.null(x$publication_stage)) {
    cli::cli_text("{.strong Applies at:} {x$publication_stage} submission")
  }
  cli::cli_text("")

  absent <- unlist(x$not_stated %||% list())
  # A blank field is either confirmed absent or simply not yet harvested, and
  # the printout must not turn the second into a claim about the publisher.
  line <- function(label, value, unit = "", field = NULL) {
    if (is.null(value) || !length(value)) {
      if (!is.null(field) && all(field %in% absent)) {
        cli::cli_li("{.strong {label}:} {.emph not specified by publisher}")
      } else {
        cli::cli_li("{.strong {label}:} {.emph not yet harvested}")
      }
    } else {
      cli::cli_li("{.strong {label}:} {paste(value, collapse = ', ')}{unit}")
    }
  }

  cli::cli_ul()
  if (!is.null(x$columns)) {
    widths <- paste0(names(x$columns), " ", unlist(x$columns), " mm")
    line("Column widths", paste(widths, collapse = " | "))
  } else {
    line("Width range", if (!is.null(x$width_min_mm)) {
      paste0(x$width_min_mm, "-", x$width_max_mm %||% "?")
    }, " mm", "columns")
  }
  line("Max height", x$height_max_mm, " mm", "height_max_mm")
  line("Minimum resolution", x$dpi_min, " dpi", "dpi_min")
  line("Line-art resolution", x$dpi_line_art, " dpi", "dpi_line_art")
  line("File formats", toupper(x$formats %||% NULL), "", "formats")
  line("Fonts", x$font_families, "", "font_families")
  line("Type size", if (!is.null(x$font_min_pt)) {
    paste0(x$font_min_pt, if (!is.null(x$font_max_pt)) paste0("-", x$font_max_pt))
  }, " pt", "font_min_pt")
  line("Colour mode", x$colour_mode, "", "colour_mode")
  line("Max file size", x$max_file_mb, " MB", "max_file_mb")
  cli::cli_end()

  if (!is.null(x$notes)) {
    cli::cli_text("")
    cli::cli_text("{.emph {trimws(x$notes)}}")
  }
  cli::cli_text("")
  cli::cli_text("{.strong Source:} {.url {x$source_url}}")
  cli::cli_text("{.strong Verified:} {x$verified_on}")
  invisible(x)
}

#' Look up table requirements
#'
#' Publications, organisations and projects may set separate requirements for
#' tables, including orientation, titles, notes and permitted file types.
#' `table_spec()` returns the recorded instructions used by
#' [table_apply_spec()], [table_save()] and [table_check()]. Rules that require
#' editorial judgement remain visible but are not claimed as verified.
#'
#' @param spec A registry id such as `"nature"`, a `figspec_spec`, or a
#'   named list containing table requirements.
#' @return A list of the stated table requirements, or `NULL` with a message
#'   when the selected specification records none.
#' @examples
#' table_spec("nature")
#' @export
table_spec <- function(spec) {
  spec <- spec_get(spec)
  if (is.null(spec$tables)) {
    msg_wrap("No table requirements are recorded for '", spec$name,
            "'. See ", spec$source_url)
    return(invisible(NULL))
  }
  structure(
    c(spec$tables, list(spec_name = spec$name, source_url = spec$source_url,
                        verified_on = spec$verified_on)),
    class = c("figspec_table_spec", "list")
  )
}

#' @export
print.figspec_table_spec <- function(x, ...) {
  cli::cli_h1("{x$spec_name} - tables")
  for (nm in setdiff(names(x), c("spec_name", "source_url", "verified_on", "source_quote"))) {
    label <- gsub("_", " ", nm, fixed = TRUE)
    label <- paste0(toupper(substr(label, 1, 1)), substr(label, 2, nchar(label)))
    cli::cli_li("{.strong {label}:} {trimws(as.character(x[[nm]]))}")
  }
  if (!is.null(x$source_quote)) {
    cli::cli_text("")
    cli::cli_text("{.emph Publisher's wording: {x$source_quote}}")
  }
  cli::cli_text("")
  cli::cli_text("{.strong Source:} {.url {x$source_url}} (verified {x$verified_on})")
  invisible(x)
}
