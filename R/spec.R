#' Figure width for a journal column
#'
#' Resolves the width a figure should be saved at. Journals state widths either
#' as named columns (single, one-and-a-half, double) or as an allowed range.
#' When a journal states only a range, `column = "single"` returns the minimum
#' and `column = "double"` the maximum.
#'
#' @param journal Registry id, for example `"cell_press"`.
#' @param column One of `"single"`, `"onehalf"` or `"double"`.
#' @param units Unit for the returned width: `"mm"`, `"cm"` or `"in"`.
#' @return A single numeric width, or an error if the journal does not state
#'   a width for that column.
#' @examples
#' fig_width("cell_press", "single")
#' fig_width("frontiers", "double", units = "in")
#' @export
fig_width <- function(journal, column = c("single", "onehalf", "double"),
                      units = c("mm", "cm", "in")) {
  column <- match.arg(column)
  units <- match.arg(units)
  spec <- journal_spec(journal)

  w <- spec$columns[[column]]
  if (is.null(w)) {
    w <- switch(column,
      single = spec$width_min_mm,
      double = spec$width_max_mm %||% spec$columns$double,
      onehalf = NULL
    )
  }
  if (is.null(w)) {
    stop(
      "'", spec$name, "' does not state a ", column, "-column width. ",
      "Set the width explicitly, and see ", spec$source_url,
      call. = FALSE
    )
  }
  convert_length(as.numeric(w), "mm", units)
}

#' @export
print.figspec_spec <- function(x, ...) {
  cli::cli_h1(x$name)
  if (!is.null(x$publisher)) cli::cli_text("{.strong Publisher:} {x$publisher}")
  if (length(x$disciplines)) {
    cli::cli_text("{.strong Disciplines:} {paste(x$disciplines, collapse = ', ')}")
  }
  cli::cli_text("")

  line <- function(label, value, unit = "") {
    if (is.null(value) || !length(value)) {
      cli::cli_li("{.strong {label}:} {.emph not specified by publisher}")
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
    }, " mm")
  }
  line("Max height", x$height_max_mm, " mm")
  line("Minimum resolution", x$dpi_min, " dpi")
  line("Line-art resolution", x$dpi_line_art, " dpi")
  line("File formats", toupper(x$formats %||% NULL))
  line("Fonts", x$font_families)
  line("Type size", if (!is.null(x$font_min_pt)) {
    paste0(x$font_min_pt, if (!is.null(x$font_max_pt)) paste0("-", x$font_max_pt))
  }, " pt")
  line("Colour mode", x$colour_mode)
  line("Max file size", x$max_file_mb, " MB")
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
    message("No table requirements are recorded for '", spec$name,
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
