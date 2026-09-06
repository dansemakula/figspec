# Building to a specification ------------------------------------------------
#
# fig_apply_spec() is the entry point for the case where the journal is known
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

#' Apply a specification while building a plot
#'
#' Adds a figure specification to a plot the same way you would add a colour
#' scale, so the figure is built to its requirements from the start rather than
#' corrected afterwards. The specification may be an included publisher or
#' journal profile, one loaded by your team, or a named list supplied directly
#' in R. One line applies its typography, stated line weights and structural
#' rules, together with colours and shapes chosen to remain distinguishable.
#'
#' Add it last. A scale added after this one replaces the journal's, which is
#' occasionally what you want and usually not.
#'
#' The palette follows the journal. Where a publisher reproduces figures in
#' black and white, `fig_apply_spec()` reaches for cividis, which keeps its
#' colours apart in greyscale. Everywhere else it uses Okabe-Ito, built to stay
#' readable under the common forms of colour vision deficiency.
#'
#' Line widths inside a geom are set on the layer rather than the theme, so
#' pass [spec_linewidth()] to any layer that draws lines.
#'
#' @param spec A registry id such as `"cell_press"`, a `figspec_spec`, or a
#'   named list of requirements. The specification does not have to describe a
#'   journal.
#' @param colour Whether to set the colour and fill scales. Turn this off to
#'   keep a palette you have chosen yourself.
#' @param shapes Whether to set the shape scale.
#' @param style A house style registered with [style_register()], applied
#'   underneath the journal's requirements.
#' @param base_size Base type size in points, passed to [theme_spec()].
#' @param color American spelling of `colour`. Takes precedence when given.
#'   R's partial matching cannot cover this one, because `color` is not a
#'   prefix of `colour` - the spellings diverge at the fifth letter.
#' @return A list of ggplot2 components, to add to a plot with `+`.
#' @seealso [spec_get()] for supplying a registry or project specification,
#'   [fig_save()] for exact export, and [fig_check()] for verification.
#' @examples
#' library(ggplot2)
#'
#' ggplot(ggplot2::mpg, aes(displ, hwy, colour = class, shape = drv)) +
#'   geom_point() +
#'   fig_apply_spec("cell_press")
#'
#' # A project specification supplied directly in R; no journal is involved.
#' report_spec <- list(
#'   name = "Quarterly research report",
#'   font_min_pt = 9,
#'   min_line_pt = 0.5,
#'   print_greyscale = TRUE
#' )
#' ggplot(ggplot2::economics, aes(date, unemploy)) +
#'   geom_line(linewidth = spec_linewidth(report_spec)) +
#'   fig_apply_spec(report_spec)
#' @export
fig_apply_spec <- function(spec, colour = TRUE, shapes = TRUE,
                        style = NULL, base_size = NULL, color = NULL) {
  if (!is.null(color)) colour <- color
  resolved <- spec_get(spec)
  pal <- if (isTRUE(resolved$print_greyscale)) "cividis" else "okabe_ito"
  preview <- list(theme_spec(spec, style = style, base_size = base_size))
  if (isTRUE(colour)) preview <- c(preview, list(scale_colour_figspec(pal), scale_fill_figspec(pal)))
  if (isTRUE(shapes)) preview <- c(preview, list(scale_shape_figspec()))
  structure(preview, class = c("figspec_fit", "list"),
            config = list(spec = spec, colour = isTRUE(colour),
                          shapes = isTRUE(shapes), style = style,
                          base_size = base_size))
}

#' @importFrom ggplot2 ggplot_add
#' @export
ggplot_add.figspec_fit <- function(object, plot, ...) {
  config <- attr(object, "config")
  spec <- spec_get(config$spec)
  parts <- list(theme_spec(config$spec, style = config$style,
                              base_size = config$base_size))
  scale_kind <- function(aesthetic) {
    built <- tryCatch(ggplot2::ggplot_build(plot), error = function(e) NULL)
    if (is.null(built)) return("none")
    sc <- built$plot$scales$get_scales(aesthetic)
    if (is.null(sc)) "none" else if (isTRUE(sc$is_discrete())) "discrete" else "continuous"
  }
  if (isTRUE(config$colour)) {
    pal <- if (isTRUE(spec$print_greyscale)) "cividis" else "okabe_ito"
    colour_kind <- scale_kind("colour")
    fill_kind <- scale_kind("fill")
    parts <- c(parts, list(
      if (identical(colour_kind, "continuous")) {
        ggplot2::scale_colour_viridis_c(option = "D")
      } else scale_colour_figspec(pal),
      if (identical(fill_kind, "continuous")) {
        ggplot2::scale_fill_viridis_c(option = "D")
      } else scale_fill_figspec(pal)
    ))
  }
  if (isTRUE(config$shapes) && !identical(scale_kind("shape"), "continuous")) {
    parts <- c(parts, list(scale_shape_figspec()))
  }
  Reduce(function(p, part) p + part, parts, init = plot)
}

#' Apply distinct shapes to categorical points
#'
#' Adds a discrete ggplot2 shape scale using the tested shape sets returned by
#' [figspec_shapes()]. Shape can support colour as a second visual cue, helping
#' readers distinguish groups when a figure is printed in greyscale or when
#' colours appear similar.
#'
#' @param ... Additional settings for the discrete scale, such as its legend
#'   title, labels, limits, missing-value shape or guide. These are passed to
#'   [ggplot2::discrete_scale()].
#' @param style The kind of marks to use: `"solid"` for solid symbols,
#'   `"hollow"` for outlines, or `"filled"` for symbols whose interior and
#'   outline colours can be controlled separately. The available sets contain
#'   six solid, six hollow and five filled shapes.
#' @return A discrete ggplot2 shape scale to add to a plot.
#' @examples
#' library(ggplot2)
#' ggplot(ggplot2::mpg, aes(displ, hwy, shape = drv)) +
#'   geom_point() +
#'   scale_shape_figspec()
#' @export
scale_shape_figspec <- function(..., style = c("solid", "hollow", "filled")) {
  style <- match.arg(style)
  ggplot2::discrete_scale("shape", palette = function(n) figspec_shapes(n, style), ...)
}
