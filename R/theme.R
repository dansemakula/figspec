#' A ggplot2 theme that satisfies a journal's typography rules
#'
#' Journals set a floor on type size, and often name the fonts they accept.
#' `theme_journal()` takes any base theme and enforces those constraints on top
#' of it, rather than imposing a look of its own. Every text element is set to
#' at least the journal's minimum size, so nothing falls below the floor
#' because of a relative sizing rule in the base theme.
#'
#' This only holds if the figure is saved at the journal's stated width, since
#' type size is fixed in points but a figure scaled down after the fact takes
#' its text with it. [ggsave_journal()] saves at the right width for you.
#'
#' @param journal Registry id, for example `"plos_one"`.
#' @param base A ggplot2 theme to build on. Defaults to [ggplot2::theme_bw()].
#' @param style A house style to apply: a name registered with
#'   [register_house_style()], a ggplot2 theme, or a function returning one.
#'   Styles are applied underneath the journal's requirements and can never
#'   override them.
#' @param base_size Base type size in points. Defaults to the journal's stated
#'   minimum, or 9 pt when the journal states none.
#' @param base_family Font family. Defaults to the graphics device's own font.
#'   The journal's named font is *not* forced here, because a family the
#'   current device cannot resolve makes the plot fail to render at all.
#'   [ggsave_journal()] applies the journal's font at save time, where the
#'   device is known. Pass a family explicitly to override.
#' @return A ggplot2 theme object.
#' @examples
#' library(ggplot2)
#' p <- ggplot(mtcars, aes(wt, mpg)) +
#'   geom_point() +
#'   theme_journal("plos_one")
#' @export
theme_journal <- function(journal, base = NULL, style = NULL, base_size = NULL,
                          base_family = NULL) {
  spec <- journal_spec(journal)
  min_pt <- as.numeric(spec$font_min_pt %||% 9)
  max_pt <- if (is.null(spec$font_max_pt)) NULL else as.numeric(spec$font_max_pt)

  if (is.null(base_size)) base_size <- min_pt
  if (!is.null(max_pt) && base_size > max_pt) base_size <- max_pt
  if (base_size < min_pt) {
    warning(
      "`base_size` of ", base_size, " pt is below the ", min_pt,
      " pt minimum stated by '", spec$name, "'.",
      call. = FALSE
    )
  }
  # Deliberately not the journal's font: see the base_family documentation.
  if (is.null(base_family)) base_family <- ""

  # Give headings a little emphasis, but never past a stated ceiling.
  title_pt <- base_size * 1.25
  if (!is.null(max_pt)) title_pt <- min(title_pt, max_pt)

  base <- base %||% ggplot2::theme_bw(base_size = base_size,
                                      base_family = base_family)

  # Order matters: base, then house style, then requirements. Requirements are
  # applied last so a style can never push a figure out of compliance.
  style_theme <- resolve_style(style)
  if (!is.null(style_theme)) {
    overridden <- style_overrides(style_theme, min_pt, max_pt)
    if (length(overridden)) {
      message(
        "'", spec$name, "' requires type ",
        if (is.null(max_pt)) paste0("of at least ", min_pt, " pt")
        else paste0("between ", min_pt, " and ", max_pt, " pt"),
        ", so the journal's sizes override your style for: ",
        paste(overridden, collapse = ", "), "."
      )
    }
    base <- base + style_theme
  }

  # Line weight is a stated requirement for several publishers, not a matter
  # of taste. ggplot2 measures linewidth in millimetres.
  line_el <- if (!is.null(spec$min_line_pt)) {
    ggplot2::element_line(linewidth = pt_to_ggplot_linewidth(spec$min_line_pt))
  } else {
    NULL
  }

  # Pin every element that a base theme usually shrinks with rel(), so the
  # journal's floor holds regardless of which base theme was supplied.
  # Where a publisher requires axis lines and tick marks, draw them: the point
  # of theme_journal is to meet the stated requirements, and ggplot2's default
  # theme leaves the axis line out.
  furniture <- if (isTRUE(spec$axis_lines_and_ticks)) {
    ggplot2::theme(axis.line = ggplot2::element_line(colour = "black"),
                   axis.ticks = ggplot2::element_line(colour = "black"))
  } else {
    ggplot2::theme()
  }

  base + furniture + ggplot2::theme(
    text = ggplot2::element_text(family = base_family, size = base_size),
    axis.text = ggplot2::element_text(size = min_pt),
    axis.title = ggplot2::element_text(size = base_size),
    legend.text = ggplot2::element_text(size = min_pt),
    legend.title = ggplot2::element_text(size = base_size),
    strip.text = ggplot2::element_text(size = min_pt),
    plot.title = ggplot2::element_text(size = title_pt),
    plot.subtitle = ggplot2::element_text(size = min_pt),
    plot.caption = ggplot2::element_text(size = min_pt)
  ) +
    (if (!is.null(line_el)) ggplot2::theme(line = line_el) else ggplot2::theme())
}

#' Line width that satisfies a journal's minimum
#'
#' Several publishers state a minimum line weight in points. ggplot2 measures
#' `linewidth` in millimetres, so this converts the journal's figure into the
#' number you pass to a geom. [theme_journal()] already applies it to axes,
#' ticks and gridlines, but geom line widths are set on the layer, not the
#' theme, so pass this to layers that draw lines.
#'
#' @param journal Registry id.
#' @return A single numeric `linewidth`, or `NULL` when the journal states no
#'   minimum.
#' @examples
#' library(ggplot2)
#' lw <- figspec_linewidth("frontiers")
#' ggplot(ggplot2::economics, aes(date, unemploy)) +
#'   geom_line(linewidth = lw) +
#'   theme_journal("frontiers")
#' @export
figspec_linewidth <- function(journal) {
  spec <- journal_spec(journal)
  if (is.null(spec$min_line_pt)) {
    message("'", spec$name, "' states no minimum line width.")
    return(invisible(NULL))
  }
  pt_to_ggplot_linewidth(spec$min_line_pt)
}

# The first font a journal names that is actually installed here. Returns ""
# when none is available, which means "leave the device default alone".
resolve_family <- function(families) {
  if (!length(families)) return("")
  if (!requireNamespace("systemfonts", quietly = TRUE)) return("")
  available <- tryCatch(systemfonts::system_fonts()$family,
                        error = function(e) character(0))
  hit <- unlist(families)[tolower(unlist(families)) %in% tolower(available)]
  if (length(hit)) hit[[1]] else ""
}


# ggplot2 draws lines with lwd = linewidth * .pt, and R's lwd unit is 1/96
# inch, so one linewidth unit renders at .pt / 96 * 72 = 2.134 points. Treating
# linewidth as millimetres (the intuitive but wrong reading) under-draws every
# line by about a quarter.
PT_PER_LINEWIDTH <- 72.27 / 25.4 * 0.75

pt_to_ggplot_linewidth <- function(pt) {
  as.numeric(pt) / PT_PER_LINEWIDTH
}

ggplot_linewidth_to_pt <- function(linewidth) {
  as.numeric(linewidth) * PT_PER_LINEWIDTH
}
