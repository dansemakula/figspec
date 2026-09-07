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

#' Create figure settings for R Markdown or Quarto
#'
#' Figures created inside an R Markdown or Quarto code chunk do not pass through
#' [fig_save()]. This function translates a publication, project or
#' organisational specification into the width, height, resolution and graphics
#' device settings understood by knitr.
#'
#' @param spec The specification to use: a registry id such as `"plos_one"`,
#'   a `figspec_spec`, or a named list of requirements.
#' @param column Which named width in the specification to use. Leave it `NULL`
#'   when supplying `width` explicitly.
#' @param width Explicit figure width for specifications that do not publish
#'   named columns.
#' @param height Figure height. Defaults to three quarters of the width when no
#'   height is recorded; supply an explicit value when the specification or
#'   layout requires one.
#' @param units Units for `width` and `height`.
#' @param art_type Resolution category. With no plot available, `"auto"`
#'   conservatively uses the strictest rule the journal states.
#' @return A named list suitable for `knitr::opts_chunk$set()`.
#' @examples
#' figspec_knitr_options("plos_one", "single")
#'
#' # A report format maintained by your own team.
#' report_spec <- list(
#'   name = "Landscape report figure",
#'   columns = list(full = 180),
#'   formats = "png",
#'   dpi_min = 300
#' )
#' figspec_knitr_options(report_spec, "full", height = 100, units = "mm")
#'
#' # In a setup chunk:
#' # do.call(knitr::opts_chunk$set, figspec_knitr_options("plos_one"))
#' @export
figspec_knitr_options <- function(spec, column = NULL, width = NULL,
                                  height = NULL, units = c("mm", "cm", "in"),
                                  art_type = c("auto", "colour", "bw", "line", "combination")) {
  units <- match.arg(units)
  art_type <- british_spelling(art_type)
  art_type <- match.arg(art_type)
  resolved <- spec_get(spec)

  if (!is.null(column) && !is.null(width)) {
    figspec_abort("{.arg column} and {.arg width} cannot both set chunk width.",
                  "size_conflict")
  }
  if (is.null(width)) {
    if (is.null(column)) column <- default_column(resolved)
    if (is.null(column)) {
      figspec_abort(
        c("{resolved$name} has no named column widths on record.",
          ">" = "Supply {.arg width} explicitly."),
        "missing_arg")
    }
    width_mm <- fig_width(resolved, column, "mm")
  } else {
    check_size(width, "width", units)
    width_mm <- convert_length(width, units, "mm")
  }
  if (!is.null(height)) check_size(height, "height", units)
  height_mm <- if (is.null(height)) width_mm * 0.75 else convert_length(height, units, "mm")

  fmt <- if (is.null(resolved$formats)) {
    default_note(resolved, "formats", "PNG", "which file formats it accepts")
    "png"
  } else {
    default_format(resolved)
  }
  if (identical(art_type, "auto")) art_type <- strictest_art_type(resolved)
  res <- resolution_for_art_type(resolved, art_type)
  if (is.null(res)) {
    default_note(resolved, "dpi_min", "300 dpi", "a minimum resolution")
    res <- 300
  }
  list(
    # knitr expects inches.
    fig.width = convert_length(width_mm, "mm", "in"),
    fig.height = convert_length(height_mm, "mm", "in"),
    dpi = res,
    dev = knitr_device(fmt)
  )
}

#' Apply figure settings to R Markdown or Quarto
#'
#' Applies the settings returned by [figspec_knitr_options()] to knitr's current
#' chunk configuration. Call it once in a document's setup chunk so later
#' figures use the chosen dimensions, resolution and output format by default.
#'
#' @inheritParams figspec_knitr_options
#' @return The previous chunk options, invisibly.
#' @examples
#' # In a setup chunk:
#' # figspec_knitr_setup("frontiers", "double")
#' @export
figspec_knitr_setup <- function(spec, column = NULL, width = NULL,
                                height = NULL, units = c("mm", "cm", "in"),
                                art_type = c("auto", "colour", "bw", "line", "combination")) {
  if (!has_package("knitr")) {
    figspec_abort(
      c("{.fn figspec_knitr_setup} needs the knitr package.",
        ">" = 'Install it with {.code install.packages("knitr")}.'),
      "needs_package", package = "knitr")
  }
  opts <- figspec_knitr_options(
    spec = spec, column = column, width = width, height = height,
    units = units, art_type = art_type
  )
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
