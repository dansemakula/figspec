# Labelling panels --------------------------------------------------------
#
# Publishers that take multi-part figures ask for the parts to be labelled, and
# they disagree about how: Cell Press wants capitals, AGU and the Royal Society
# want lower case, and the brackets around the letter are a house convention
# rather than a rule. figspec already reads those requirements, so a caller
# should not have to look them up again in order to satisfy one.
#
# Two kinds of figure need labelling and they work differently.
#
#   A composition -- separate plots assembled with patchwork -- already has tag
#   machinery, and patchwork does it well. figspec should defer to it rather
#   than reimplement it, and only supply the level the journal asks for.
#
#   A faceted plot has no tag machinery at all. Its panels are drawn from one
#   dataset, and the strip above each one carries a data value, not a label. So
#   the tags have to be drawn into the panels, and the strips usually removed:
#   a strip reading "cyl: 6" above a panel labelled "(b)" is two competing
#   captions for the same thing.


#' Label the panels of a figure
#'
#' Adds panel labels in the style the journal asks for. Where a publisher
#' states one — capitals, lower case, numbers — that is what you get, so the
#' convention does not have to be looked up.
#'
#' A composition made with patchwork is labelled through patchwork's own tags.
#' A faceted plot has no such machinery, so the labels are drawn inside the
#' panels and the facet strips are removed, which is the convention for
#' journals that treat facets as sub-figures. Keep the strips with
#' `strips = TRUE` if their content is doing work the labels do not replace.
#'
#' Nothing here is invented. Where a journal states no labelling rule, the
#' `level` you give applies, and if you give none the default is lower case —
#' a convention, and reported as one rather than as a requirement.
#'
#' @param plot A ggplot, faceted or not, or a patchwork composition.
#' @param journal Registry id, or a specification. Supplies the label style.
#' @param level Label vocabulary: `"A"`, `"a"`, `"1"`, `"I"` or `"i"`.
#'   Overrides the journal, which is what you want when a co-author has asked
#'   for something the publisher does not mention.
#' @param open,close Characters around the label. Journals rarely state these;
#'   `"("` and `")"` are common in print.
#' @param strips Whether to keep facet strips. Ignored for a composition.
#' @param x,y,hjust,vjust Where the label sits inside its panel.
#' @param ... Passed to [ggplot2::geom_text()], for size, face or family.
#' @return The plot, labelled. [fig_check()] recognises the result.
#' @seealso [fig_check()], which reports whether a figure's panels meet the
#'   journal's labelling rule.
#' @examples
#' library(ggplot2)
#' p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_wrap(~cyl)
#'
#' # Cell Press asks for capitals; AGU asks for lower case.
#' tag_panels(p, "cell_press")
#'
#' # Or say it yourself, where no journal is involved.
#' tag_panels(p, level = "a")
#' @export
tag_panels <- function(plot, journal = NULL, level = NULL,
                       open = "(", close = ")", strips = FALSE,
                       x = -Inf, y = Inf, hjust = -0.6, vjust = 1.4, ...) {
  level <- resolve_tag_level(journal, level)

  if (inherits(plot, "patchwork")) {
    if (!requireNamespace("patchwork", quietly = TRUE)) {
      figspec_abort(
        c("Labelling a composition needs the patchwork package.",
          ">" = 'Install it with {.code install.packages("patchwork")}.'),
        "needs_package", package = "patchwork"
      )
    }
    # patchwork owns tags on compositions and does them well. All figspec adds
    # is the level the publisher asked for.
    return(plot + patchwork::plot_annotation(
      tag_levels = level, tag_prefix = open, tag_suffix = close
    ))
  }

  if (!inherits(plot, "ggplot")) {
    figspec_abort(
      c("{.arg plot} must be a ggplot or a patchwork composition.",
        "x" = "You gave {.cls {class(plot)}}."),
      "bad_input"
    )
  }

  panels <- facet_panel_keys(plot)
  if (is.null(panels)) {
    figspec_abort(
      c("This plot has one panel, so there is nothing to label.",
        "i" = "Panel labels identify the parts of a multi-part figure.",
        ">" = "Facet the plot, or compose several with patchwork."),
      "bad_input"
    )
  }

  n <- nrow(panels)
  tags <- data.frame(
    panels,
    .figspec_tag = paste0(open, tag_vocabulary(level, n), close),
    stringsAsFactors = FALSE
  )

  out <- plot + ggplot2::geom_text(
    data = tags,
    mapping = ggplot2::aes(x = x, y = y, label = .data$.figspec_tag),
    hjust = hjust, vjust = vjust, inherit.aes = FALSE, ...
  )
  if (!isTRUE(strips)) {
    out <- out + ggplot2::theme(
      strip.text = ggplot2::element_blank(),
      strip.background = ggplot2::element_blank()
    )
  }

  # Record what was applied, so fig_check() recognises figspec's own labelling
  # exactly rather than having to infer it from the layers.
  attr(out, "figspec_panel_tags") <- level
  out
}


# The label style a journal states, or the caller's own. An explicit `level`
# wins: a publisher's rule is a floor, not a prohibition on being asked for
# something else by a co-author or a house style.
resolve_tag_level <- function(journal, level) {
  valid <- c("A", "a", "1", "I", "i")
  if (!is.null(level)) {
    if (!is.character(level) || length(level) != 1L || !level %in% valid) {
      figspec_abort(
        c("{.arg level} must be one of {.val {valid}}.",
          "x" = "You gave {.val {level}}."),
        "bad_input"
      )
    }
    return(level)
  }
  if (is.null(journal)) return("a")

  spec <- journal_spec(journal)
  stated <- spec$panel_labels
  if (is.null(stated)) {
    # Say so rather than letting a default pass for a requirement.
    default_note(spec, "panel_labels", "lower-case letters",
                 "how panels should be labelled")
    return("a")
  }
  switch(as.character(stated),
    uppercase = "A", lowercase = "a", numbers = "1",
    roman = "I", roman_lower = "i",
    {
      figspec_abort(
        c("{spec$name} states a panel label style figspec does not know how to
           apply: {.val {stated}}.",
          ">" = "Give a {.arg level} explicitly, and see {.url {spec$source_url}}."),
        "unsupported", stated = stated
      )
    }
  )
}


# The labels themselves, in the requested vocabulary.
tag_vocabulary <- function(level, n) {
  if (n > length(LETTERS) && level %in% c("A", "a")) {
    figspec_abort(
      c("{n} panels is more than the {length(LETTERS)} letters available.",
        ">" = 'Use {.code level = "1"} to number them instead.'),
      "unsupported", panels = n
    )
  }
  switch(level,
    A = LETTERS[seq_len(n)],
    a = letters[seq_len(n)],
    `1` = as.character(seq_len(n)),
    I = as.character(utils::as.roman(seq_len(n))),
    i = tolower(as.character(utils::as.roman(seq_len(n))))
  )
}


# The facetting variables and their values, one row per panel, in the order the
# panels are drawn. A text layer needs these columns to land one label in each
# panel rather than all of them in every panel.
facet_panel_keys <- function(plot) {
  lay <- tryCatch(ggplot2::ggplot_build(plot)$layout$layout,
                  error = function(e) NULL)
  if (is.null(lay) || nrow(lay) < 2L) return(NULL)
  drop <- c("PANEL", "ROW", "COL", "SCALE_X", "SCALE_Y")
  keys <- lay[order(lay$PANEL), setdiff(names(lay), drop), drop = FALSE]
  if (!ncol(keys)) return(NULL)
  rownames(keys) <- NULL
  keys
}
