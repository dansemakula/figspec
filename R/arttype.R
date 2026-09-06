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
# asked for. fig_suggest_art_type() therefore reports what it found and says
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

# Silent counterpart to fig_suggest_art_type(), used where an API must choose a
# safe resolution without printing an advisory essay as a side effect.
infer_art_type <- function(plot) {
  switch(classify_tone(plot),
    bitonal = "line",
    grayscale = "bw",
    colour = "colour",
    continuous = "combination"
  )
}

strictest_art_type <- function(spec) {
  vals <- c(
    colour = as.numeric(spec$dpi_min %||% NA_real_),
    bw = as.numeric(spec$dpi_bw %||% spec$dpi_min %||% NA_real_),
    line = as.numeric(spec$dpi_line_art %||% spec$dpi_min %||% NA_real_),
    combination = as.numeric(spec$dpi_combination %||% spec$dpi_min %||% NA_real_)
  )
  if (all(is.na(vals))) return("colour")
  names(vals)[which.max(replace(vals, is.na(vals), -Inf))]
}

resolution_for_art_type <- function(spec, art_type) {
  minimum <- switch(art_type,
    colour = spec$dpi_min,
    bw = spec$dpi_bw %||% spec$dpi_min,
    line = spec$dpi_line_art %||% spec$dpi_min,
    combination = spec$dpi_combination %||% spec$dpi_min
  )
  if (is.null(minimum)) return(NULL)
  minimum <- as.numeric(minimum)
  if (!isTRUE(spec$dpi_min_inclusive %||% TRUE)) minimum <- floor(minimum) + 1
  minimum
}

#' Choose a resolution category for a figure
#'
#' Specifications often set different resolutions for colour, greyscale, line
#' and combination artwork. This function examines what a ggplot draws and
#' suggests the corresponding `art_type` value for [fig_check()] or
#' [fig_save()]. It also shows the recorded thresholds when you supply a
#' publication or project specification.
#'
#' The suggestion describes the plot's visible content; it does not rewrite or
#' overrule the source's terminology. For example, some publishers reserve
#' "line art" for pure black-and-white artwork, while others use the term more
#' broadly. Read the displayed thresholds and source guidance before choosing a
#' lower resolution for final delivery.
#'
#' @param plot A ggplot object.
#' @param spec Optional specification: a registry id, a `figspec_spec`, or a
#'   named list of requirements. When supplied, its resolution thresholds are
#'   shown alongside the suggestion.
#' @return The suggested `art_type` value for [fig_check()] or [fig_save()],
#'   invisibly.
#' @examples
#' library(ggplot2)
#' bars <- ggplot(ggplot2::mpg, aes(class)) + geom_bar()
#' bars
#' fig_suggest_art_type(bars, "bmj")
#' @export
fig_suggest_art_type <- function(plot, spec = NULL) {
  if (!is_ggplot_object(plot)) {
    figspec_abort("{.arg plot} must be a ggplot object.", "bad_input")
  }
  tone <- classify_tone(plot)
  suggestion <- infer_art_type(plot)

  cli::cli_h1("Choose a resolution category")
  switch(tone,
    bitonal = alert_wrap(
      "This plot uses only black and white, with no grey. Publishers classify this as {.strong line art} and usually require the highest resolution because sharp edges show pixelation easily."
    ),
    grayscale = alert_wrap(
      "This plot uses grey but no colour, so it is {.strong grayscale art}, not line art. For example, ggplot2's default bar fill is a mid grey, so a default bar chart belongs in this category."
    ),
    colour = alert_wrap(
      "This plot uses colour, so it is not line art: five publishers in the registry define line art as black and white or monochrome. Treat it as {.strong colour art}. Springer classifies a colour diagram as {.strong combination art} and requires a higher resolution, so check its guidance if you are submitting there."
    ),
    continuous = alert_wrap(
      "This plot draws continuous tone. An image carrying lettering is {.strong combination art}; a photograph without lettering is a halftone."
    ))

  if (!is.null(spec)) {
    resolved <- spec_get(spec)
    cli::cli_text("")
    cli::cli_text("Requirements from {.strong {resolved$name}}:")
    cli::cli_ul()
    show <- function(label, v) if (!is.null(v)) cli::cli_li("{label}: {v} dpi")
    show("general minimum", resolved$dpi_min)
    show("line art", resolved$dpi_line_art)
    show("combination art", resolved$dpi_combination)
    show("black and white", resolved$dpi_bw)
    cli::cli_end()
    if (!is.null(resolved$source_quote_dpi)) {
      cli::cli_text("{.emph {resolved$source_quote_dpi}}")
    }
  }

  cli::cli_text("")
  cli::cli_alert_success(
    'Suggested: fig_check(plot, spec, art_type = "{suggestion}")'
  )
  alert_wrap(
    "This recommendation is based on what the plot contains. If publisher guidance is unclear, using a higher resolution increases the file size, while using a lower resolution may fall below the requirement. Check the linked guidance before submission."
  )
  invisible(suggestion)
}
