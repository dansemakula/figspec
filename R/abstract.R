# Graphical abstracts --------------------------------------------------------
#
# A graphical abstract, or table-of-contents image, is governed separately from
# the figures in an article: a much smaller canvas, sometimes a character limit
# on accompanying text, occasionally its own resolution. These are reported on
# their own and never folded into a figure report, because a figure that meets
# the article's requirements has not thereby met the abstract's.

#' Graphical abstract requirements for a journal
#'
#' Many journals ask for a graphical abstract, or table-of-contents entry, and
#' set separate rules for it: usually a much smaller canvas than a figure, and
#' sometimes a character limit on the accompanying text. These are not figure
#' requirements and are not checked by [fig_check()].
#'
#' @param journal Registry id, for example `"rsc"`.
#' @return A list of the stated requirements, or `NULL` with a message when the
#'   registry records none for that journal.
#' @examples
#' graphical_abstract_spec("rsc")
#' @export
graphical_abstract_spec <- function(journal) {
  spec <- journal_spec(journal)
  if (is.null(spec$graphical_abstract)) {
    msg_wrap("No graphical abstract requirements are recorded for '", spec$name,
            "'. See ", spec$source_url)
    return(invisible(NULL))
  }
  structure(
    c(spec$graphical_abstract,
      list(journal = spec$name, source_url = spec$source_url,
           verified_on = spec$verified_on)),
    class = c("figspec_abstract_spec", "list")
  )
}

#' @export
print.figspec_abstract_spec <- function(x, ...) {
  cli::cli_h1("{x$journal} - graphical abstract")
  line <- function(label, v, unit = "") {
    if (is.null(v)) return(invisible(NULL))
    cli::cli_li("{.strong {label}:} {paste(unlist(v), collapse = ', ')}{unit}")
  }
  cli::cli_ul()
  if (!is.null(x$width_mm) || !is.null(x$height_mm)) {
    line("Maximum size", paste0(x$width_mm %||% "?", " x ", x$height_mm %||% "?", " mm"))
  }
  line("Resolution", x$dpi_min, " dpi")
  line("Formats", toupper(unlist(x$formats %||% NULL)))
  line("Size in pixels", x$size_px)
  line("Text limit", x$max_characters, " characters")
  cli::cli_end()
  if (!is.null(x$source_quote)) {
    cli::cli_text("")
    cli::cli_text("{.emph {x$source_quote}}")
  }
  cli::cli_text("")
  cli::cli_text("{.strong Source:} {.url {x$source_url}} (verified {x$verified_on})")
  invisible(x)
}
