# Building to a specification ------------------------------------------------
#
# fit_journal() is the entry point for the case where the journal is known
# before the figure is drawn, which is the cheapest moment to satisfy it. It
# returns a list of ggplot2 components, so it composes with `+` like any scale
# or theme.
#
# Order matters and cannot be enforced from inside: a scale added after this
# one replaces the journal's, so it is documented as something to add last.
#
# The palette is chosen from the specification rather than fixed. Where a
# publisher reproduces figures in black and white, the default becomes cividis,
# which stays separable once desaturated; elsewhere it is Okabe-Ito, which
# stays separable under the common colour vision deficiencies. Neither is a
# journal requirement - no publisher states which colours to use - so both can
# be turned off without turning off anything the journal asked for.

#' Bring a journal's requirements into a plot as you build it
#'
#' Adds a journal's requirements to a plot the same way you would add a colour
#' scale, so the figure is built to specification from the start rather than
#' corrected afterwards. One line carries the journal's typography, its stated
#' line weights, its structural rules such as axis lines and tick marks, and
#' colours and shapes chosen to survive whatever that journal does to a figure
#' in production.
#'
#' Add it last. A scale added after this one replaces the journal's, which is
#' occasionally what you want and usually not.
#'
#' The palette follows the journal. Where a publisher reproduces figures in
#' black and white, `fit_journal()` reaches for cividis, which keeps its
#' colours apart in greyscale. Everywhere else it uses Okabe-Ito, built to stay
#' readable under the common forms of colour vision deficiency.
#'
#' Line widths inside a geom are set on the layer rather than the theme, so
#' pass [figspec_linewidth()] to any layer that draws lines.
#'
#' @param journal Registry id, for example `"cell_press"`.
#' @param colour Whether to set the colour and fill scales. Turn this off to
#'   keep a palette you have chosen yourself.
#' @param shapes Whether to set the shape scale.
#' @param style A house style registered with [register_house_style()], applied
#'   underneath the journal's requirements.
#' @param base_size Base type size in points, passed to [theme_journal()].
#' @param color American spelling of `colour`. Takes precedence when given.
#'   R's partial matching cannot cover this one, because `color` is not a
#'   prefix of `colour` - the spellings diverge at the fifth letter.
#' @return A list of ggplot2 components, to add to a plot with `+`.
#' @examples
#' library(ggplot2)
#'
#' ggplot(mtcars, aes(wt, mpg, colour = factor(cyl), shape = factor(cyl))) +
#'   geom_point() +
#'   fit_journal("cell_press")
#'
#' # Keep your own palette, take everything else.
#' ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) +
#'   geom_point() +
#'   scale_colour_viridis_d() +
#'   fit_journal("plos_one", colour = FALSE)
#' @export
fit_journal <- function(journal, colour = TRUE, shapes = TRUE,
                        style = NULL, base_size = NULL, color = NULL) {
  if (!is.null(color)) colour <- color
  spec <- journal_spec(journal)
  parts <- list(theme_journal(journal, style = style, base_size = base_size))

  if (isTRUE(colour)) {
    pal <- if (isTRUE(spec$print_greyscale)) "cividis" else "okabe_ito"
    parts <- c(parts, list(scale_colour_figspec(pal), scale_fill_figspec(pal)))
  }
  if (isTRUE(shapes)) {
    parts <- c(parts, list(scale_shape_figspec()))
  }
  parts
}

#' A discrete shape scale using shapes that stay legible at journal size
#'
#' @param ... Passed to [ggplot2::discrete_scale()].
#' @param style Passed to [figspec_shapes()].
#' @return A ggplot2 scale.
#' @examples
#' library(ggplot2)
#' ggplot(mtcars, aes(wt, mpg, shape = factor(cyl))) +
#'   geom_point() +
#'   scale_shape_figspec()
#' @export
scale_shape_figspec <- function(..., style = c("solid", "hollow", "filled")) {
  style <- match.arg(style)
  ggplot2::discrete_scale("shape", palette = function(n) figspec_shapes(n, style), ...)
}
