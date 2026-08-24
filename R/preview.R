# Previewing at published size -----------------------------------------------
#
# The most common way a compliant figure becomes unreadable is being designed
# at roughly 7 by 5 inches on a laptop and printed into an 85 mm column, which
# reduces everything in it by more than half. Nothing in the usual workflow
# shows an author that reduction until it is too late to matter.
#
# This opens a device at the real column width so the figure being iterated on
# is the size a reader will see. It is deliberately interactive-only: in a
# script or a knitted document there is no window to open, so it reports the
# size it would have used and does nothing.

#' Preview a figure at the size it will actually be published
#'
#' The most common way a compliant figure becomes non-compliant is being
#' designed on a laptop at roughly 7 by 5 inches and submitted into an 85 mm
#' column. Everything in it is then reduced by more than half. This opens a
#' device at the journal's real column width, so what you are looking at while
#' you iterate is the size a reader will see.
#'
#' @param plot Plot to preview. Defaults to the last plot displayed.
#' @param journal Registry id.
#' @param column Which column width to preview at.
#' @param height Height. Defaults to three quarters of the width.
#' @param units Units for `height`.
#' @return The plot, invisibly.
#' @examples
#' library(ggplot2)
#' p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
#' if (interactive()) figspec_preview(p, "cell_press", "single")
#' @export
figspec_preview <- function(plot = ggplot2::last_plot(), journal,
                            column = "single",
                            height = NULL, units = c("mm", "cm", "in")) {
  units <- match.arg(units)

  width_mm <- fig_width(journal, column, "mm")
  height_mm <- if (is.null(height)) width_mm * 0.75 else convert_length(height, units, "mm")

  if (!is_interactive()) {
    msg_wrap(
      "figspec_preview() opens a graphics window and does nothing in a ",
      "non-interactive session. The figure would be ",
      fmt_num(width_mm), " by ", fmt_num(height_mm), " mm."
    )
    return(invisible(plot))
  }

  grDevices::dev.new(
    width = convert_length(width_mm, "mm", "in"),
    height = convert_length(height_mm, "mm", "in"),
    unit = "in", noRStudioGD = TRUE
  )
  print(plot)
  msg_wrap(
    "Previewing at ", fmt_num(width_mm), " x ", fmt_num(height_mm),
    " mm, the ", column, "-column size for '", journal_spec(journal)$name,
    "'. This window is the published size."
  )
  invisible(plot)
}
