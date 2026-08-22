# Art type ----------------------------------------------------------------

# Layers that put continuous tone on the page rather than lines and flat fills.
RASTER_GEOMS <- c("GeomRaster", "GeomTile", "GeomRasterAnn", "GeomBin2d", "GeomHex")

plot_has_raster <- function(plot) {
  ls <- tryCatch(plot$layers, error = function(e) NULL)
  if (is.null(ls) || !length(ls)) return(FALSE)
  any(vapply(ls, function(l) any(class(l$geom) %in% RASTER_GEOMS), logical(1)))
}

plot_is_greyscale <- function(plot) {
  cols <- plot_colours(plot)
  if (!length(cols)) return(TRUE)
  all(vapply(cols, function(c) {
    m <- tryCatch(grDevices::col2rgb(c), error = function(e) NULL)
    !is.null(m) && m[1] == m[2] && m[2] == m[3]
  }, logical(1)))
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
#' @return The suggested `art_type` for [check_journal()], invisibly.
#' @examples
#' library(ggplot2)
#' suggest_art_type(ggplot(mtcars, aes(factor(cyl))) + geom_bar(), "bmj")
#' @export
suggest_art_type <- function(plot, journal = NULL) {
  if (!is_ggplot_object(plot)) {
    stop("`plot` must be a ggplot object.", call. = FALSE)
  }
  raster <- plot_has_raster(plot)
  grey <- plot_is_greyscale(plot)

  suggestion <- if (raster) "combination" else "line"

  cli::cli_h1("Which resolution rule applies")
  if (raster) {
    cli::cli_alert_info(
      "This plot draws continuous tone, so it is not pure line art. Publishers call an image carrying lettering {.strong combination art}."
    )
  } else if (grey) {
    cli::cli_alert_info(
      "This plot is lines, flat fills and text, with no colour and no continuous tone. That is {.strong line art} on every definition in the registry."
    )
  } else {
    cli::cli_alert_info(
      "This plot is lines, flat fills and text, in colour. Publishers disagree about this case: PNAS gives {.emph line art, e.g., bar graphs} regardless of colour, while Springer defines line art as a {.emph Black and white graphic with no shading}, which would make this combination art."
    )
  }

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
    'Suggested: check_journal(plot, journal, art_type = "{suggestion}")'
  )
  cli::cli_alert_info(
    "This is a suggestion from what the plot contains, not a rule. Where publishers disagree, the stricter reading costs file size; the looser one risks a figure below the resolution the journal asked for."
  )
  invisible(suggestion)
}
