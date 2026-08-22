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
                            column = c("single", "onehalf", "double"),
                            height = NULL, units = c("mm", "cm", "in")) {
  column <- match.arg(column)
  units <- match.arg(units)

  width_mm <- fig_width(journal, column, "mm")
  height_mm <- if (is.null(height)) width_mm * 0.75 else convert_length(height, units, "mm")

  if (!interactive()) {
    message(
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
  message(
    "Previewing at ", fmt_num(width_mm), " x ", fmt_num(height_mm),
    " mm, the ", column, "-column size for '", journal_spec(journal)$name,
    "'. This window is the published size."
  )
  invisible(plot)
}
