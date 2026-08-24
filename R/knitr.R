# R Markdown and Quarto ------------------------------------------------------
#
# A large share of academic figures never pass through a save call at all: they
# come out of a knitr chunk at whatever fig.width happens to be, which means
# the usual advice to save at the journal's width never reaches them.
#
# These translate a specification into the chunk options that make knitr emit
# figures at the right size, resolution and format. knitr takes its dimensions
# in inches, so millimetres are converted here; the device is chosen the same
# way as in R/save.R, preferring ragg where it is installed because it renders
# text more accurately and records the resolution in the file.

#' Chunk options that produce journal-compliant figures in R Markdown or Quarto
#'
#' A large share of academic figures never pass through [ggplot2::ggsave()] at
#' all: they are produced by a knitr chunk, at whatever size `fig.width` and
#' `fig.height` happen to be. This returns the chunk options that make knitr
#' emit figures at the journal's size, resolution and format.
#'
#' @param journal Registry id, for example `"plos_one"`.
#' @param column Which column width to size to.
#' @param height Figure height. Defaults to three quarters of the width, which
#'   is a convenience rather than a journal requirement.
#' @param units Units for `height`.
#' @return A named list suitable for [knitr::opts_chunk]`$set()`.
#' @examples
#' figspec_chunk_opts("plos_one", "single")
#'
#' # In a setup chunk:
#' # do.call(knitr::opts_chunk$set, figspec_chunk_opts("plos_one"))
#' @export
figspec_chunk_opts <- function(journal, column = "single",
                               height = NULL, units = c("mm", "cm", "in")) {
  units <- match.arg(units)
  spec <- journal_spec(journal)

  width_mm <- fig_width(journal, column, "mm")
  height_mm <- if (is.null(height)) width_mm * 0.75 else convert_length(height, units, "mm")

  fmt <- if (is.null(spec$formats)) {
    default_note(spec, "formats", "PNG", "which file formats it accepts")
    "png"
  } else {
    tolower(unlist(spec$formats)[[1]])
  }
  res <- if (is.null(spec$dpi_min)) {
    default_note(spec, "dpi_min", "300 dpi", "a minimum resolution")
    300
  } else {
    as.numeric(spec$dpi_min)
  }
  list(
    # knitr expects inches.
    fig.width = convert_length(width_mm, "mm", "in"),
    fig.height = convert_length(height_mm, "mm", "in"),
    dpi = res,
    dev = knitr_device(fmt)
  )
}

#' Set knitr chunk options for a journal
#'
#' Convenience wrapper that applies [figspec_chunk_opts()] to the current
#' document. Call it from a setup chunk.
#'
#' @inheritParams figspec_chunk_opts
#' @return The previous chunk options, invisibly.
#' @examples
#' # In a setup chunk:
#' # figspec_knitr_setup("frontiers", "double")
#' @export
figspec_knitr_setup <- function(journal, column = "single",
                                height = NULL, units = c("mm", "cm", "in")) {
  if (!has_package("knitr")) {
    figspec_abort(
      c("{.fn figspec_knitr_setup} needs the knitr package.",
        ">" = 'Install it with {.code install.packages("knitr")}.'),
      "needs_package", package = "knitr")
  }
  opts <- figspec_chunk_opts(journal, column, height, units)
  invisible(do.call(knitr::opts_chunk$set, opts))
}

# Map a file format to the knitr `dev` name that renders it best here.
knitr_device <- function(fmt) {
  switch(fmt,
    png = if (has_package("ragg")) "ragg_png" else "png",
    tiff = ,
    tif = "tiff",
    jpeg = ,
    jpg = "jpeg",
    svg = if (has_package("svglite")) "svglite" else "svg",
    eps = ,
    ps = "postscript",
    pdf = if (cairo_ok()) "cairo_pdf" else "pdf",
    "png"
  )
}
