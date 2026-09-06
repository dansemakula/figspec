# Point shapes and line types ------------------------------------------------
#
# Choosing marks and dashes that survive being printed small, and converting
# between the units ggplot2 uses and the points publishers state.
#
# Two reasons this matters beyond taste. A figure that distinguishes its series
# by colour alone becomes unreadable in greyscale or to a colour-blind reader,
# so shapes and line types are the redundant cue that keeps it readable - which
# is why fig_check() reports whether any exists. And a point outline is a line:
# it has a width, and journals that state a minimum line width state it for
# every stroke on the page, including the ring around a marker.
#
# The stroke conversion below is the one that is easy to get wrong, so it is
# derived rather than asserted.

# ggplot2 draws a point outline with lwd = stroke * .stroke / 2, and R's lwd
# unit is 1/96 inch, so a stroke renders at stroke * .stroke * 0.375 points.
# The default stroke of 0.5 is therefore about 0.71 pt, which is thinner than
# some journals allow for a line.
PT_PER_STROKE <- 3.779528 * 0.375

stroke_to_pt <- function(stroke) as.numeric(stroke) * PT_PER_STROKE
pt_to_stroke <- function(pt) as.numeric(pt) / PT_PER_STROKE

# Shapes 0-14 are drawn as outlines only, 15-20 as solid marks, and 21-25 take
# a fill and a separate outline colour.
shape_is_hollow <- function(shape) {
  s <- suppressWarnings(as.numeric(shape))
  !is.na(s) & s >= 0 & s <= 14
}

shape_takes_fill <- function(shape) {
  s <- suppressWarnings(as.numeric(shape))
  !is.na(s) & s >= 21 & s <= 25
}

plot_shapes <- function(plot) {
  built <- tryCatch(ggplot2::ggplot_build(plot)$data, error = function(e) NULL)
  if (is.null(built)) return(NULL)
  shapes <- unlist(lapply(built, function(d) d$shape))
  strokes <- unlist(lapply(built, function(d) d$stroke))
  shapes <- shapes[!is.na(shapes)]
  strokes <- strokes[!is.na(strokes) & strokes > 0]
  if (!length(shapes)) return(NULL)
  list(
    shapes = unique(shapes),
    n_shapes = length(unique(shapes)),
    hollow = any(shape_is_hollow(unique(shapes))),
    outline_pt = if (length(strokes)) sort(unique(stroke_to_pt(strokes))) else numeric(0)
  )
}

#' Get a set of distinct point shapes
#'
#' Returns ggplot2 shape codes chosen to remain visually distinct when a figure
#' is reduced or reproduced without colour. Use the codes in a manual shape
#' scale when you need direct control; [scale_shape_figspec()] applies the same
#' sets automatically.
#'
#' These shapes are design recommendations, not requirements taken from a
#' publication or project specification. The sets are deliberately short:
#' figspec returns an error instead of recycling a shape or adding symbols that
#' become difficult to tell apart at small sizes.
#'
#' @param n The number of shapes needed, usually the number of groups in the
#'   data. Up to six solid, six hollow or five separately filled shapes are
#'   available.
#' @param style The kind of marks to return: `"solid"` for solid symbols,
#'   `"hollow"` for outlines, or `"filled"` for shapes 21 to 25, whose interior
#'   and outline colours can be controlled separately.
#' @return An integer vector containing one ggplot2 shape code per group.
#' @examples
#' library(ggplot2)
#' ggplot(ggplot2::mpg, aes(displ, hwy, shape = drv)) +
#'   geom_point() +
#'   scale_shape_manual(values = figspec_shapes(3))
#' @export
figspec_shapes <- function(n, style = c("solid", "hollow", "filled")) {
  if (!is.numeric(n) || length(n) != 1L || !is.finite(n) || n < 1 || n != floor(n)) {
    figspec_abort("{.arg n} must be one positive whole number.", "bad_input")
  }
  style <- match.arg(style)
  sets <- list(
    # Circle, triangle, square and diamond stay apart at small sizes; the
    # later entries are progressively harder to tell apart.
    solid = c(16, 17, 15, 18, 8, 3),
    hollow = c(1, 2, 0, 5, 6, 4),
    filled = c(21, 24, 22, 23, 25)
  )
  pool <- sets[[style]]
  if (n > length(pool)) {
    figspec_abort(
      c("Only {length(pool)} {style} shapes stay reliably distinct at journal
         size, and {n} were asked for.",
        ">" = "Split the figure into panels rather than adding shapes a reader
               cannot separate."),
      "unsupported", available = length(pool), requested = n)
  }
  pool[seq_len(n)]
}

#' Get a set of distinct line types
#'
#' Returns line types that can distinguish a small number of series without
#' relying on colour alone. Use them in a manual linetype scale so that a plot
#' remains readable when it is reproduced in greyscale or when two colours are
#' difficult to tell apart.
#'
#' These patterns are design recommendations, not requirements taken from a
#' publication or project specification. figspec provides six and returns an
#' error instead of recycling a pattern when more are requested.
#'
#' @param n The number of line types needed, usually the number of series in
#'   the data. Up to six are available.
#' @return A character vector containing one ggplot2 line type per series.
#' @examples
#' library(ggplot2)
#' series <- subset(
#'   ggplot2::economics_long,
#'   variable %in% c("psavert", "uempmed", "unemploy")
#' )
#' ggplot(series, aes(date, value01, linetype = variable)) +
#'   geom_line(linewidth = 0.7) +
#'   scale_linetype_manual(values = figspec_linetypes(3)) +
#'   labs(x = NULL, y = "Value, rescaled to 0–1", linetype = "Series")
#' @export
figspec_linetypes <- function(n) {
  if (!is.numeric(n) || length(n) != 1L || !is.finite(n) || n < 1 || n != floor(n)) {
    figspec_abort("{.arg n} must be one positive whole number.", "bad_input")
  }
  pool <- c("solid", "dashed", "dotted", "dotdash", "longdash", "twodash")
  if (n > length(pool)) {
    figspec_abort(
      c("Only {length(pool)} line types stay reliably distinct, and {n} were
         asked for.",
        ">" = "Distinguish the extra series by colour or by panel instead."),
      "unsupported", available = length(pool), requested = n)
  }
  pool[seq_len(n)]
}
