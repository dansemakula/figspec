# Palettes ----------------------------------------------------------------

# Palettes shipped with figspec are chosen for a property that can be tested,
# and each names where it comes from. None of them is a journal requirement:
# no publisher in the registry states which colours to use. They are here
# because they survive the checks in colour_safety_check().
figspec_palette_registry <- function() {
  list(
    okabe_ito = list(
      name = "Okabe-Ito",
      type = "qualitative",
      colours = c("#000000", "#E69F00", "#56B4E9", "#009E73",
                  "#F0E442", "#0072B2", "#D55E00", "#CC79A7"),
      source = "Okabe & Ito (2008), Color Universal Design",
      url = "https://jfly.uni-koeln.de/color/",
      note = paste(
        "Built to stay distinguishable under the common forms of colour vision",
        "deficiency. It is NOT greyscale-safe: two of its colours sit at",
        "almost the same lightness, so use cividis where a journal prints in",
        "black and white."
      )
    ),
    cividis = list(
      name = "Cividis",
      type = "sequential",
      colours = viridisLite::cividis(5),
      generator = viridisLite::cividis,
      source = "Nunez, Anderton & Renslow (2018), PLOS ONE 13(7): e0199239",
      url = "https://doi.org/10.1371/journal.pone.0199239",
      note = paste(
        "Safe under colour vision deficiency and monotonic in lightness, so it",
        "also survives reproduction in black and white. Use this one when a",
        "journal prints in greyscale."
      )
    ),
    viridis = list(
      name = "Viridis",
      type = "sequential",
      colours = viridisLite::viridis(5),
      generator = viridisLite::viridis,
      source = "Smith & van der Walt (2015), matplotlib",
      url = "https://bids.github.io/colormap/",
      note = paste(
        "Perceptually uniform and monotonic in lightness, so it survives",
        "greyscale reproduction. Being a ramp, it suits ordered categories",
        "better than unordered ones."
      )
    )
  )
}

#' List the colour palettes included with figspec
#'
#' Shows the palettes available through [figspec_palette()] and the figspec
#' colour scales. The catalogue explains whether each palette is intended for
#' separate categories or ordered values, how many colours it can provide, and
#' when it is most useful. Each palette also records its published source.
#'
#' These palettes are optional design tools, not requirements taken from a
#' publication. Each was selected for documented accessibility or perceptual
#' properties, but not every palette suits every output. In particular,
#' Okabe-Ito distinguishes categories for readers with common forms of
#' colour-vision deficiency but is not intended for greyscale reproduction;
#' Cividis and Viridis use an ordered lightness ramp that remains legible in
#' greyscale.
#'
#' @return A data frame containing the palette id, display name, type, maximum
#'   number of colours, recommended use, source and source URL. An infinite
#'   maximum means that the sequential palette can generate any requested
#'   number of colours.
#' @examples
#' figspec_palettes()
#' @export
figspec_palettes <- function() {
  reg <- figspec_palette_registry()
  out <- do.call(rbind, lapply(names(reg), function(id) {
    p <- reg[[id]]
    data.frame(
      id = id,
      name = p$name,
      type = p$type,
      n = if (is.null(p$generator)) length(p$colours) else Inf,
      guidance = p$note,
      source = p$source,
      source_url = p$url,
      stringsAsFactors = FALSE
    )
  }))
  rownames(out) <- NULL
  out
}

#' Get colours from a figspec palette
#'
#' Returns a vector of hexadecimal colours that can be passed to a ggplot2
#' manual scale or used anywhere else R accepts colours. Use
#' [figspec_palettes()] to compare the available palettes and their recommended
#' uses.
#'
#' @param palette The id of the palette to use, as listed by
#'   [figspec_palettes()].
#' @param n The number of colours to return. When omitted, a sequential palette
#'   returns five colours and a fixed palette returns all of its colours.
#'   Cividis and Viridis can generate any requested number. A fixed palette
#'   reports its capacity when more colours are requested, allowing you to
#'   choose a suitable alternative.
#' @return A character vector of hex colours.
#' @examples
#' library(ggplot2)
#' colours <- figspec_palette("okabe_ito", 7)
#' ggplot(ggplot2::mpg, aes(displ, hwy, colour = class)) +
#'   geom_point() +
#'   scale_colour_manual(values = colours)
#' @export
figspec_palette <- function(palette = "okabe_ito", n = NULL) {
  if (!is.null(n) && (!is.numeric(n) || length(n) != 1L || !is.finite(n) ||
                      n < 1 || n != floor(n))) {
    figspec_abort("{.arg n} must be one positive whole number or NULL.", "bad_input")
  }
  reg <- figspec_palette_registry()
  if (!palette %in% names(reg)) {
    figspec_abort(
      c("Unknown palette {.val {palette}}.",
        "i" = "Available: {.val {names(reg)}}."),
      "not_found", palette = palette)
  }
  entry <- reg[[palette]]
  cols <- entry$colours
  if (is.null(n)) return(cols)
  if (!is.null(entry$generator)) return(entry$generator(n))
  if (n > length(cols)) {
    figspec_abort(
      c("Palette {.val {palette}} has {length(cols)} colours, and {n} were asked for.",
        "i" = "Recycling would put the same colour on two series, which a
               reader cannot tell apart.",
        ">" = "Pick a palette with more colours, or split the figure."),
      "unsupported", palette = palette, available = length(cols), requested = n)
  }
  cols[seq_len(n)]
}

#' Apply a figspec palette to point and line colours
#'
#' Adds a discrete ggplot2 colour scale using one of the palettes listed by
#' [figspec_palettes()]. Use this scale when a variable is represented by the
#' colour of points, lines or outlines. The American spelling
#' `scale_color_figspec()` is an exact alias.
#'
#' @param palette The id of the figspec palette to use. See
#'   [figspec_palettes()] for the available choices and their recommended uses.
#' @param ... Additional settings for the discrete scale, such as its legend
#'   title, labels, limits, missing-value colour or guide. These are passed to
#'   [ggplot2::discrete_scale()].
#' @return A discrete ggplot2 colour scale to add to a plot.
#' @examples
#' library(ggplot2)
#' ggplot(ggplot2::mpg, aes(displ, hwy, colour = class)) +
#'   geom_point() +
#'   scale_colour_figspec()
#' @export
scale_colour_figspec <- function(palette = "okabe_ito", ...) {
  ggplot2::discrete_scale("colour", palette = function(n) figspec_palette(palette, n), ...)
}

#' @rdname scale_colour_figspec
#' @export
scale_color_figspec <- scale_colour_figspec

#' Apply a figspec palette to filled areas
#'
#' Adds a discrete ggplot2 fill scale using one of the palettes listed by
#' [figspec_palettes()]. Use it for bars, boxes, areas and filled point shapes;
#' use [scale_colour_figspec()] for point, line and outline colours.
#'
#' @param palette The id of the figspec palette to use. See
#'   [figspec_palettes()] for the available choices and their recommended uses.
#' @param ... Additional settings for the discrete scale, such as its legend
#'   title, labels, limits, missing-value colour or guide. These are passed to
#'   [ggplot2::discrete_scale()].
#' @return A discrete ggplot2 fill scale to add to a plot.
#' @examples
#' library(ggplot2)
#' ggplot(ggplot2::mpg, aes(class, fill = drv)) +
#'   geom_bar() +
#'   scale_fill_figspec()
#' @export
scale_fill_figspec <- function(palette = "okabe_ito", ...) {
  ggplot2::discrete_scale("fill", palette = function(n) figspec_palette(palette, n), ...)
}

#' Retrieve a recorded house-style palette
#'
#' Retrieves the optional palette stored in the `house_style` section of a
#' registry or user-supplied specification. This can represent the visual
#' identity of a publication, project or organisation.
#'
#' A house-style palette is a design preference, so [fig_check()] keeps it
#' separate from pass-or-fail requirements. When no palette is recorded,
#' figspec reports that fact and returns `NULL`, leaving the plotting system's
#' existing colours in place.
#'
#' @param spec The specification whose house-style palette should be
#'   retrieved. Supply a registry id, a `figspec_spec`, or a named list. It may
#'   describe a publication, project or organisation.
#' @return A character vector of recorded R colours, preserving any names, or
#'   `NULL` when the specification contains no house-style palette.
#' @examples
#' spec_style_palette("plos_one")
#' @export
spec_style_palette <- function(spec) {
  resolved <- spec_get(spec)
  pal <- resolved$house_style$palette
  if (is.null(pal)) {
    msg_wrap(
      "No house-style palette is recorded for '", resolved$name,
      "'. The plotting system will keep its current colours. See ",
      "figspec_palettes() when you want to choose an optional palette, with ",
      "guidance on where each works best."
    )
    return(invisible(NULL))
  }
  pal <- unlist(pal)
  valid <- is.character(pal) && length(pal) > 0L &&
    !anyNA(pal) && all(nzchar(pal))
  if (valid) {
    valid <- tryCatch({
      grDevices::col2rgb(pal)
      TRUE
    }, error = function(e) FALSE)
  }
  if (!valid) {
    figspec_abort(
      c(
        "The house-style palette recorded for {.val {resolved$name}} contains an invalid R colour.",
        "i" = "Use colour names such as 'navy' or hexadecimal values such as '#1D3557'."
      ),
      "bad_input"
    )
  }
  pal
}
