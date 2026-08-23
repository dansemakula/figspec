# Palettes ----------------------------------------------------------------

# Palettes shipped with figspec are chosen for a property that can be tested,
# and each names where it comes from. None of them is a journal requirement:
# no publisher in the registry states which colours to use. They are here
# because they survive the checks in check_colour_safety().
figspec_palette_registry <- function() {
  list(
    okabe_ito = list(
      name = "Okabe-Ito",
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
      colours = viridisLite::cividis(5),
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
      colours = viridisLite::viridis(5),
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

#' Colour palettes that survive print and colour-blind readers
#'
#' Lists the palettes figspec ships. None is a journal requirement: no
#' publisher in the registry states which colours to use. They are provided
#' because they pass the checks in [check_colour_safety()], and each records
#' where it came from.
#'
#' @return A data frame of palette names, sizes and sources.
#' @examples
#' figspec_palettes()
#' @export
figspec_palettes <- function() {
  reg <- figspec_palette_registry()
  out <- do.call(rbind, lapply(names(reg), function(id) {
    p <- reg[[id]]
    data.frame(id = id, name = p$name, n = length(p$colours),
               source = p$source, stringsAsFactors = FALSE)
  }))
  rownames(out) <- NULL
  out
}

#' The colours in a figspec palette
#'
#' @param palette Palette id, from [figspec_palettes()].
#' @param n Number of colours to return. Defaults to all of them.
#' @return A character vector of hex colours.
#' @examples
#' figspec_palette("okabe_ito", 3)
#' @export
figspec_palette <- function(palette = "okabe_ito", n = NULL) {
  reg <- figspec_palette_registry()
  if (!palette %in% names(reg)) {
    figspec_abort(
      c("Unknown palette {.val {palette}}.",
        "i" = "Available: {.val {names(reg)}}."),
      "not_found", palette = palette)
  }
  cols <- reg[[palette]]$colours
  if (is.null(n)) return(cols)
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

#' Discrete colour and fill scales using a figspec palette
#'
#' @param palette Palette id, from [figspec_palettes()].
#' @param ... Passed to [ggplot2::discrete_scale()].
#' @return A ggplot2 scale.
#' @examples
#' library(ggplot2)
#' ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) +
#'   geom_point() +
#'   scale_colour_figspec()
#' @export
scale_colour_figspec <- function(palette = "okabe_ito", ...) {
  ggplot2::discrete_scale("colour", palette = function(n) figspec_palette(palette, n), ...)
}

#' @rdname scale_colour_figspec
#' @export
scale_color_figspec <- scale_colour_figspec

#' @rdname scale_colour_figspec
#' @export
scale_fill_figspec <- function(palette = "okabe_ito", ...) {
  ggplot2::discrete_scale("fill", palette = function(n) figspec_palette(palette, n), ...)
}

#' The palette recorded for a journal's house style
#'
#' Some registry entries record what a journal's figures tend to look like.
#' That is taste, not a rule: it lives in the entry's `house_style` block, it
#' is never checked, and using it does not make a figure compliant.
#'
#' @param journal Registry id.
#' @return A character vector of colours, or `NULL` if the entry records none.
#' @examples
#' journal_palette("plos_one")
#' @export
journal_palette <- function(journal) {
  spec <- journal_spec(journal)
  pal <- spec$house_style$palette
  if (is.null(pal)) {
    msg_wrap(
      "No house-style palette is recorded for '", spec$name,
      "'. figspec does not invent one: no publisher in the registry states ",
      "which colours to use. See figspec_palettes() for palettes chosen to ",
      "survive print and colour-blind readers."
    )
    return(invisible(NULL))
  }
  unlist(pal)
}
