#' Re-export a set of figures for a different journal
#'
#' Papers get rejected and resubmitted, and the new journal has different
#' widths, formats and type limits. This takes the plot objects you already
#' have and writes the whole set to another journal's specification.
#'
#' It works from plot objects, not from saved files, and that is deliberate.
#' Type size cannot be recovered from a saved raster, and rescaling one only
#' degrades it, so re-fitting a finished TIFF cannot produce a compliant
#' figure. Keep your plots in a list and this stays a one-line operation.
#'
#' @param plots A named list of plot objects. Names become file stems.
#' @param journal Registry id of the journal to fit to.
#' @param outdir Directory to write into. Created if it does not exist.
#' @param column Which column width to use, either one value for all plots or
#'   a named vector mapping plot name to column.
#' @param retheme Whether to apply [theme_journal()] to each plot so its
#'   typography matches the new journal. Defaults to `TRUE`.
#' @param format File format. Defaults to the journal's first accepted format.
#' @return A [check_submission()] report for the files written.
#' @examples
#' library(ggplot2)
#' p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
#' dir <- file.path(tempdir(), "refit")
#' res <- suppressWarnings(
#'   refit_journal(list(figure_1 = p), "frontiers", dir)
#' )
#' unlink(dir, recursive = TRUE)
#' @export
refit_journal <- function(plots, journal, outdir,
                          column = "single", retheme = TRUE, format = NULL) {
  if (!is.list(plots) || is.null(names(plots)) || any(!nzchar(names(plots)))) {
    stop("`plots` must be a named list of plot objects.", call. = FALSE)
  }
  if (!all(vapply(plots, is_ggplot_object, logical(1)))) {
    stop(
      "`refit_journal()` works on plot objects, not saved files. Type size ",
      "cannot be recovered from a saved figure, so a re-fitted file could ",
      "not be trusted.",
      call. = FALSE
    )
  }
  dir.create(outdir, recursive = TRUE, showWarnings = FALSE)
  spec <- journal_spec(journal)
  fmt <- if (is.null(format)) default_format(spec) else tolower(format)

  col_for <- function(nm) {
    if (length(column) == 1L && is.null(names(column))) return(column)
    hit <- column[[nm]]
    if (is.null(hit)) "single" else hit
  }

  written <- character(0)
  for (nm in names(plots)) {
    p <- plots[[nm]]
    if (isTRUE(retheme)) p <- p + theme_journal(journal)
    dest <- file.path(outdir, paste0(nm, ".", fmt))
    ggsave_journal(dest, p, journal = journal, column = col_for(nm), check = FALSE)
    written <- c(written, dest)
  }
  check_submission(written, journal, column = column)
}
