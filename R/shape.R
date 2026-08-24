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

#' Point shapes that stay legible at journal size
#'
#' Returns shapes chosen to remain distinguishable when a figure is reduced to
#' a single column. No publisher in the registry states which shapes to use, so
#' this is a recommendation rather than a requirement. It matters because shape
#' is the cue that still works when a journal prints in black and white.
#'
#' @param n How many shapes are needed.
#' @param style `"solid"` for filled marks, `"hollow"` for outlines, or
#'   `"filled"` for shapes 21 to 25, which take a fill and an outline colour
#'   separately.
#' @return An integer vector of shape codes.
#' @examples
#' library(ggplot2)
#' ggplot(mtcars, aes(wt, mpg, shape = factor(cyl))) +
#'   geom_point() +
#'   scale_shape_manual(values = figspec_shapes(3))
#' @export
figspec_shapes <- function(n, style = c("solid", "hollow", "filled")) {
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

#' Line types that stay distinct in print
#'
#' Line type is the other cue that survives black-and-white reproduction. As
#' with shapes, no publisher in the registry states which to use, so this is a
#' recommendation.
#'
#' @param n How many line types are needed.
#' @return A character vector of line types.
#' @examples
#' figspec_linetypes(3)
#' @export
figspec_linetypes <- function(n) {
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
