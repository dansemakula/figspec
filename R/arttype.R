# Art type -------------------------------------------------------------------
#
# Publishers set different resolution minimums for different kinds of artwork,
# and the difference is large: a journal asking 300 dpi of a photograph may ask
# 1200 dpi of line art. So "what resolution does this figure need" cannot be
# answered without first deciding what kind of artwork it is.
#
# The trap is that "line art" does not mean a plot with lines in it. In
# prepress it means a purely monochrome image - one bit per pixel, no grey -
# which is why it carries the highest bar: hard black-and-white edges alias
# badly when sampled too coarsely. Five publishers in the registry define it
# that way in their own words. A coloured line chart is colour art, and
# ggplot2's default bar fill is a mid grey, which makes a default bar chart
# greyscale art rather than line art.
#
# Getting this backwards in either direction costs something real: calling a
# colour figure line art demands a file four times larger than necessary, and
# calling line art a colour figure ships it below the resolution the journal
# asked for. suggest_art_type() therefore reports what it found and says
# plainly that it is a suggestion, and fig_check() never changes its own
# verdict on the strength of it.

# Layers that put continuous tone on the page rather than lines and flat fills.
RASTER_GEOMS <- c("GeomRaster", "GeomTile", "GeomRasterAnn", "GeomBin2d", "GeomHex")

plot_has_raster <- function(plot) {
  ls <- tryCatch(plot$layers, error = function(e) NULL)
  if (is.null(ls) || !length(ls)) return(FALSE)
  any(vapply(ls, function(l) any(class(l$geom) %in% RASTER_GEOMS), logical(1)))
}

# Classify what a plot puts on the page, in the terms publishers use.
#
#   bitonal    pure black and white, no grey. This is line art in the prepress
#              sense: a 1-bit image whose sharp edges alias badly at low
#              resolution, which is why publishers ask 1200 dpi for it.
#   grayscale  greys present but no hue. Continuous tone, so a lower bar.
#   colour     any hue present.
#   continuous a raster layer: photographs, heatmaps, density surfaces.
#
# Five publishers in the registry define line art as monochrome: Springer's
# "Black and white graphic with no shading", ACS's "Black and white line art",
# IEEE's "black and white line art", and Taylor & Francis and OUP both writing
# "monochrome". A coloured chart is not line art on any of those definitions.
classify_tone <- function(plot) {
  if (plot_has_raster(plot)) return("continuous")
  cols <- plot_colours(plot)
  if (!length(cols)) return("bitonal")
  m <- vapply(cols, function(c) {
    v <- tryCatch(grDevices::col2rgb(c), error = function(e) NULL)
    if (is.null(v)) return(c(NA_real_, NA_real_, NA_real_))
    as.numeric(v[, 1])
  }, numeric(3))
  m <- m[, !apply(is.na(m), 2, any), drop = FALSE]
  if (!ncol(m)) return("bitonal")
  grey <- apply(m, 2, function(v) v[1] == v[2] && v[2] == v[3])
  if (any(!grey)) return("colour")
  # All grey. Pure black and white is line art; anything in between is not.
  levels <- m[1, ]
  if (all(levels %in% c(0, 255))) "bitonal" else "grayscale"
}

plot_is_greyscale <- function(plot) {
  classify_tone(plot) %in% c("bitonal", "grayscale")
}

#' Which resolution rule applies to this figure
#'
#' Publishers set different resolutions for different kinds of artwork, and the
#' gap is large: a general minimum of 300 dpi against 600 to 1200 dpi for line
#' art. Which one applies to a statistical plot is not obvious, and getting it
#' wrong is expensive in one direction.
#'
#' Most R plots are line art. PNAS says so explicitly, giving "line art, e.g.,
#' bar graphs". A plot made of lines, flat fills and text is line art in that
#' sense, whatever colour it is. Springer defines line art more narrowly, as a
#' "Black and white graphic with no shading", which would place a coloured plot
#' in combination art instead. Publishers genuinely disagree, so this reports
#' what the plot contains and leaves the decision to you.
#'
#' @param plot A ggplot object.
#' @param journal Optional registry id. When given, the journal's own
#'   thresholds are shown alongside the suggestion.
#' @return The suggested `art_type` for [fig_check()], invisibly.
#' @examples
#' library(ggplot2)
#' suggest_art_type(ggplot(mtcars, aes(factor(cyl))) + geom_bar(), "bmj")
#' @export
suggest_art_type <- function(plot, journal = NULL) {
  if (!is_ggplot_object(plot)) {
    figspec_abort("{.arg plot} must be a ggplot object.", "bad_input")
  }
  tone <- classify_tone(plot)
  suggestion <- switch(tone,
    bitonal = "line", grayscale = "bw", colour = "colour", continuous = "combination")

  cli::cli_h1("Which resolution rule applies")
  switch(tone,
    bitonal = alert_wrap(
      "This plot is pure black and white with no grey. That is {.strong line art} in the sense publishers mean, and it carries the highest resolution bar: sharp one-bit edges alias badly when sampled too coarsely."
    ),
    grayscale = alert_wrap(
      "This plot uses grey but no colour, so it is {.strong grayscale art}, not line art. ggplot2's default bar fill is a mid grey, so a default bar chart lands here rather than in line art."
    ),
    colour = alert_wrap(
      "This plot uses colour, so it is not line art: five publishers in the registry define line art as black and white or monochrome. Treat it as {.strong colour art}. Springer would call a colour diagram {.strong combination art}, which is a higher bar, so check its wording if you are submitting there."
    ),
    continuous = alert_wrap(
      "This plot draws continuous tone. An image carrying lettering is {.strong combination art}; a photograph without lettering is a halftone."
    ))

  if (!is.null(journal)) {
    spec <- journal_spec(journal)
    cli::cli_text("")
    cli::cli_text("{.strong {spec$name}} states:")
    cli::cli_ul()
    show <- function(label, v) if (!is.null(v)) cli::cli_li("{label}: {v} dpi")
    show("general minimum", spec$dpi_min)
    show("line art", spec$dpi_line_art)
    show("combination art", spec$dpi_combination)
    show("black and white", spec$dpi_bw)
    cli::cli_end()
    if (!is.null(spec$source_quote_dpi)) {
      cli::cli_text("{.emph {spec$source_quote_dpi}}")
    }
  }

  cli::cli_text("")
  cli::cli_alert_success(
    'Suggested: fig_check(plot, journal, art_type = "{suggestion}")'
  )
  alert_wrap(
    "This is a suggestion from what the plot contains, not a rule. Where publishers disagree, the stricter reading costs file size; the looser one risks a figure below the resolution the journal asked for."
  )
  invisible(suggestion)
}
