#' Figure width for a journal column
#'
#' Resolves the width a figure should be saved at. Column names come from the
#' journal itself rather than a fixed vocabulary: Science lays out in one, two
#' or three columns, most journals in one, one-and-a-half or two. Use
#' [fig_columns()] to see what a given journal offers.
#'
#' When a journal states a permitted range rather than named columns,
#' `"single"` returns the minimum width and `"double"` the maximum.
#'
#' @param journal Registry id, for example `"cell_press"`.
#' @param column Column name, for example `"single"`, `"double"` or, for
#'   Science, `"triple"`.
#' @param units Unit for the returned width: `"mm"`, `"cm"` or `"in"`.
#' @return A single numeric width, or an error if the journal does not state
#'   a width for that column.
#' @examples
#' fig_width("cell_press", "single")
#' fig_width("science", "triple")
#' fig_width("frontiers", "double", units = "in")
#' @export
fig_width <- function(journal, column = "single", units = c("mm", "cm", "in")) {
  units <- match.arg(units)
  spec <- journal_spec(journal)
  if (!is.character(column) || length(column) != 1L) {
    stop("`column` must be a single column name.", call. = FALSE)
  }

  if (!is.null(spec$columns)) {
    w <- spec$columns[[column]]
    if (is.null(w)) {
      stop(
        "'", spec$name, "' does not have a '", column, "' column. It states: ",
        paste0(names(spec$columns), " (", unlist(spec$columns), " mm)",
               collapse = ", "), ".",
        call. = FALSE
      )
    }
  } else {
    w <- switch(column,
      single = spec$width_min_mm,
      double = spec$width_max_mm,
      NULL
    )
    if (is.null(w)) {
      stop(
        "'", spec$name, "' does not state a ", column, "-column width. ",
        "Set the width explicitly, and see ", spec$source_url,
        call. = FALSE
      )
    }
  }
  convert_length(as.numeric(w), "mm", units)
}

#' The column widths a journal states
#'
#' @param journal Registry id.
#' @return A named numeric vector of widths in millimetres, or `NULL` when the
#'   journal states a range rather than named columns.
#' @examples
#' fig_columns("science")
#' fig_columns("cell_press")
#' @export
fig_columns <- function(journal) {
  spec <- journal_spec(journal)
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

#' Table requirements for a journal
#'
#' Journals also publish rules for tables, but those rules are mostly editorial
#' rather than numeric: orientation, how the title is set, where footnotes go.
#' `table_spec()` surfaces what the publisher states so you can follow it. It
#' deliberately does not try to check a table automatically, because almost
#' nothing in a table specification is mechanically checkable from an R object.
#'
#' @param journal Registry id, for example `"nature"`.
#' @return A list of the stated table requirements, or `NULL` with a message
#'   when the registry records none for that journal.
#' @examples
#' table_spec("nature")
#' @export
table_spec <- function(journal) {
  spec <- journal_spec(journal)
  if (is.null(spec$tables)) {
    msg_wrap("No table requirements are recorded for '", spec$name,
            "'. See ", spec$source_url)
    return(invisible(NULL))
  }
  structure(
    c(spec$tables, list(journal = spec$name, source_url = spec$source_url,
                        verified_on = spec$verified_on)),
    class = c("figspec_table_spec", "list")
  )
}

#' @export
print.figspec_table_spec <- function(x, ...) {
  cli::cli_h1("{x$journal} - tables")
  for (nm in setdiff(names(x), c("journal", "source_url", "verified_on", "source_quote"))) {
    cli::cli_li("{.strong {nm}:} {trimws(as.character(x[[nm]]))}")
  }
  if (!is.null(x$source_quote)) {
    cli::cli_text("")
    cli::cli_text("{.emph Publisher's wording: {x$source_quote}}")
  }
  cli::cli_text("")
  cli::cli_text("{.strong Source:} {.url {x$source_url}} (verified {x$verified_on})")
  invisible(x)
}
