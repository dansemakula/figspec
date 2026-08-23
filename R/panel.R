# Panel geometry ----------------------------------------------------------
#
# A figure has two widths, and only one of them is what a reader notices.
#
#   canvas = the whole image file
#   panel  = the plot area inside it, once axis titles, axis text, tick marks,
#            the legend and the margins have taken their share
#
# A journal states the canvas: "single column is 85 mm" means the image is
# 85 mm. Saving at that width is what keeps a figure compliant, and that is
# what fig_save() does by default.
#
# But two compliant 85 mm figures whose y-axis labels differ in length have
# different panel widths, and on the printed page they look mismatched. Every
# journal is silent on this, so it is never a compliance failure. It is still
# the thing an author is trying to fix when they ask why their figures do not
# line up.
#
# The relationship is additive and, once the panels are set to an absolute
# size, exactly computable:
#
#   canvas = panel + decoration
#
# So panel sizing is not guesswork. Fix the panel cells of the plot's layout
# table to an absolute width, and every remaining cell is already absolute,
# which makes the total a sum rather than an estimate.


#' Set the size of a plot's panels
#'
#' Sets the plot area to an exact physical size, rather than the image file.
#' Two figures given the same panel size line up, whatever their axis labels
#' do, and the type inside them stays at the size you set it.
#'
#' The usual way to size a figure sets the image and lets the panel take
#' whatever is left over, so a longer y-axis label silently shrinks the plot
#' area. This does the reverse: the panel is what you fix, and the image grows
#' or shrinks around it.
#'
#' For a faceted plot, or a composition made with patchwork, the size applies
#' to *each* panel, which is what makes panels comparable between figures.
#'
#' @param plot A ggplot, a patchwork composition, or a `gtable`.
#' @param width,height Panel size. `NULL` leaves that dimension alone.
#' @param units Units for `width` and `height`.
#' @return A `gtable`, which prints and saves like a plot. Its achieved
#'   geometry is attached as the `"figspec_geometry"` attribute.
#' @aliases set_panel_size panel_size
#' @seealso [fig_save()], which does this and works out the image size for you.
#' @examples
#' library(ggplot2)
#' p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
#' g <- fig_panel_size(p, width = 62, height = 45)
#' fig_geometry(g)
#' @export
fig_panel_size <- function(plot, width = NULL, height = NULL,
                           units = c("mm", "cm", "in")) {
  units <- match.arg(units)
  check_size(width, "width", units)
  check_size(height, "height", units)
  w_mm <- if (is.null(width)) NULL else convert_length(width, units, "mm")
  h_mm <- if (is.null(height)) NULL else convert_length(height, units, "mm")
  if (is.null(w_mm) && is.null(h_mm)) {
    figspec_abort("Give a {.arg width}, a {.arg height}, or both.", "missing_arg")
  }
  gt <- set_panels(as_plot_gtable(plot), w_mm, h_mm)
  attr(gt, "figspec_geometry") <- measure_gtable(gt)
  # Keep the plot the gtable was built from. Laying a plot out discards what
  # only the plot knows -- its theme, its layers, its scales -- and fig_check()
  # needs those to judge type size, font and colour. A sized figure that can no
  # longer be checked would be a poor trade for a fixed panel.
  if (!inherits(plot, "gtable")) attr(gt, "figspec_plot") <- plot
  gt
}


#' What size a figure actually is
#'
#' Reports the canvas and panel dimensions of a plot, in millimetres. Use it to
#' see where the space in a figure is going before you decide what to change.
#'
#' @param x A ggplot, a patchwork composition, a `gtable`, or the value
#'   returned by [fig_save()].
#' @return A one-row data frame: canvas and panel width and height, and the
#'   decoration each dimension spends on axes, legends and margins.
#' @examples
#' library(ggplot2)
#' fig_geometry(ggplot(mtcars, aes(wt, mpg)) + geom_point())
#' @export
fig_geometry <- function(x) {
  geom <- attr(x, "figspec_geometry")
  if (!is.null(geom)) return(geom)
  measure_gtable(as_plot_gtable(x))
}


# The measurement --------------------------------------------------------

# Everything below reports millimetres. Text width depends on the font, and
# the font depends on the device, so a measurement taken on one device and
# used on another is off by a fraction of a millimetre. fig_save() therefore
# measures on the same device it is about to write with; the default here is
# only for interactive inspection.

measure_gtable <- function(gt) {
  on_measure_device(NULL, {
    # A panel that has not been given a size is a `null` track: it takes
    # whatever the canvas leaves over, so it has no width until a canvas is
    # chosen. Reporting 0, or reporting the decoration as though it were the
    # whole figure, would both be wrong. Report that it is not yet determined.
    bare <- set_panels(gt, 0, 0)
    dec_w <- sum_units(bare, "width")
    dec_h <- sum_units(bare, "height")
    pw <- panel_track(gt, "width")
    ph <- panel_track(gt, "height")
    sx <- decoration_sides(bare, "width")
    sy <- decoration_sides(bare, "height")
    structure(
      data.frame(
        canvas_width_mm  = if (is.na(pw)) NA_real_ else round(sum_units(gt, "width"), 2),
        canvas_height_mm = if (is.na(ph)) NA_real_ else round(sum_units(gt, "height"), 2),
        panel_width_mm   = round(pw, 2),
        panel_height_mm  = round(ph, 2),
        decoration_width_mm  = round(dec_w, 2),
        decoration_height_mm = round(dec_h, 2),
        left_mm   = round(sx[["before"]], 2),
        right_mm  = round(sx[["after"]], 2),
        top_mm    = round(sy[["before"]], 2),
        bottom_mm = round(sy[["after"]], 2),
        gap_x_mm  = round(sx[["between"]], 2),
        gap_y_mm  = round(sy[["between"]], 2),
        panels_across = count_panel_tracks(gt, "width"),
        panels_down   = count_panel_tracks(gt, "height"),
        stringsAsFactors = FALSE
      ),
      class = c("figspec_geometry", "data.frame")
    )
  })
}

# Where the decoration actually goes. A total is enough to compute a canvas,
# but it does not tell you what to change: 26 mm on the right is a legend and
# 12 mm on the left is axis labels, and those have different fixes. Measured
# with the panels collapsed, so what remains either side of them is decoration.
#
# `between` is the space between panels -- facet spacing -- which is neither
# margin nor panel and grows with the panel count.
decoration_sides <- function(bare, dim) {
  none <- c(before = NA_real_, after = NA_real_, between = NA_real_)
  if (!inherits(bare, "gtable")) return(none)
  sizes <- if (dim == "width") bare$widths else bare$heights
  conv  <- if (dim == "width") grid::convertWidth else grid::convertHeight
  pos   <- if (dim == "width") bare$layout$l else bare$layout$t
  idx <- sort(unique(pos[grepl("^panel", bare$layout$name)]))
  # A composition nests its plots, so "left of the panel" has no single answer
  # at the top level. Report the total and leave the sides unclaimed.
  if (!length(idx)) return(none)

  mm <- function(i) {
    if (!length(i)) return(0)
    v <- vapply(i, function(k) {
      u <- sizes[k]
      if (identical(as.character(grid::unitType(u))[1], "null")) 0
      else conv(u, "mm", valueOnly = TRUE)
    }, numeric(1))
    sum(v)
  }
  n <- length(sizes)
  inner <- setdiff(seq(min(idx), max(idx)), idx)
  c(before  = mm(seq_len(min(idx) - 1L)),
    after   = if (max(idx) < n) mm(seq(max(idx) + 1L, n)) else 0,
    between = mm(inner))
}


# "60 x 40 mm" reads as a size; "60 mm wide, not set tall" reads as a fault.
fmt_pair <- function(w, h) {
  if (is.na(w) && is.na(h)) return("not set")
  paste0(if (is.na(w)) "?" else mm(w), " x ",
         if (is.na(h)) "?" else mm(h), " mm")
}

#' @export
print.figspec_geometry <- function(x, ...) {
  cli::cli_h1("Figure geometry")
  n <- x$panels_across * x$panels_down
  free <- is.na(x$panel_width_mm) && is.na(x$panel_height_mm)

  if (free) {
    cli::cli_alert_info(
      "The panels have no size of their own yet, so they will take whatever the
       canvas leaves over. The decoration below is fixed by the labels and the
       font, and does not change with the canvas."
    )
  } else {
    cli::cli_verbatim(c(
      paste0("  canvas  ", fmt_pair(x$canvas_width_mm, x$canvas_height_mm)),
      paste0("  panel   ", fmt_pair(x$panel_width_mm, x$panel_height_mm),
             if (n > 1) paste0("   (each of ", n, ")") else "")
    ))
  }

  cli::cli_text("")
  cli::cli_text("{.strong Decoration} - where the rest of the space goes")
  bits <- c(left = x$left_mm, right = x$right_mm,
            top = x$top_mm, bottom = x$bottom_mm,
            `gaps between panels` = x$gap_x_mm)
  bits <- bits[!is.na(bits) & bits >= 0.005]
  if (length(bits)) {
    bits <- sort(bits, decreasing = TRUE)
    cli::cli_verbatim(paste0(
      "  ", format(names(bits), width = max(nchar(names(bits)))),
      "  ", formatC(vapply(bits, mm, character(1)), width = 6), " mm"
    ))
  } else {
    cli::cli_verbatim(paste0(
      "  ", mm(x$decoration_width_mm), " mm across, ",
      mm(x$decoration_height_mm), " mm down",
      "   (sides are not separable for a composition)"
    ))
  }
  cli::cli_text("")
  cli::cli_alert_info("{.fn plot} this to see it.")
  invisible(x)
}


# The size of a single panel, which is the quantity that makes two figures
# comparable. Summing every panel would answer a different and less useful
# question, and for a composition it would answer it wrongly. NA means the
# panels are still free to stretch, so they have no size of their own yet.
panel_track <- function(gt, dim) {
  if (!inherits(gt, "gtable")) return(NA_real_)
  sizes <- if (dim == "width") gt$widths else gt$heights
  conv  <- if (dim == "width") grid::convertWidth else grid::convertHeight
  pos   <- if (dim == "width") gt$layout$l else gt$layout$t
  idx <- unique(pos[grepl("^panel", gt$layout$name)])
  if (length(idx)) {
    u <- sizes[idx[1]]
    if (identical(as.character(grid::unitType(u))[1], "null")) return(NA_real_)
    return(conv(u, "mm", valueOnly = TRUE))
  }
  for (g in gt$grobs) {
    v <- panel_track(g, dim)
    if (!is.na(v)) return(v)
  }
  NA_real_
}

# Total extent of a gtable along one dimension.
#
# Two cases need care. A `null` unit has no size of its own -- it takes what is
# left over -- so a column holding one cannot be summed directly; we descend
# into whatever grob sits there and measure that instead. This is what makes a
# patchwork composition, whose sub-plots sit in null cells, measurable at all.
sum_units <- function(gt, dim = c("width", "height")) {
  dim <- match.arg(dim)
  if (!inherits(gt, "gtable")) return(0)
  sizes <- if (dim == "width") gt$widths else gt$heights
  conv  <- if (dim == "width") grid::convertWidth else grid::convertHeight
  total <- 0
  for (i in seq_along(sizes)) {
    u <- sizes[i]
    if (identical(as.character(grid::unitType(u))[1], "null")) {
      # Leftover space. Measure the child that occupies it.
      total <- total + child_extent(gt, i, dim)
    } else {
      total <- total + conv(u, "mm", valueOnly = TRUE)
    }
  }
  total
}

# The gtables sitting in one row or column of a parent gtable.
children_at <- function(gt, i, dim) {
  pos  <- if (dim == "width") gt$layout$l else gt$layout$t
  span <- if (dim == "width") gt$layout$r else gt$layout$b
  hits <- which(pos <= i & span >= i)
  Filter(function(g) inherits(g, "gtable"), gt$grobs[hits])
}

nested_gtable_in <- function(gt, i, dim) length(children_at(gt, i, dim)) > 0

# A cell may hold several stacked plots; the one that needs the most room sets
# the size, which is how grid lays it out.
child_extent <- function(gt, i, dim) {
  kids <- children_at(gt, i, dim)
  if (!length(kids)) return(0)
  max(vapply(kids, sum_units, numeric(1), dim = dim))
}


# Setting the panels ------------------------------------------------------

# Descends through nested gtables so that a patchwork composition gets the
# same treatment as a single plot: every leaf panel takes the given size, and
# the composition's total falls out of that.
set_panels <- function(gt, w_mm, h_mm) {
  if (!inherits(gt, "gtable")) return(gt)
  is_panel <- grepl("^panel", gt$layout$name)
  if (any(is_panel)) {
    if (!is.null(w_mm)) {
      gt$widths[unique(gt$layout$l[is_panel])] <- grid::unit(w_mm, "mm")
    }
    if (!is.null(h_mm)) {
      gt$heights[unique(gt$layout$t[is_panel])] <- grid::unit(h_mm, "mm")
    }
  }
  gt$grobs <- lapply(gt$grobs, set_panels, w_mm = w_mm, h_mm = h_mm)
  gt
}

as_plot_gtable <- function(plot) {
  if (inherits(plot, "gtable")) return(plot)
  if (inherits(plot, "patchwork")) {
    if (!requireNamespace("patchwork", quietly = TRUE)) {
      figspec_abort(
        c("Sizing a patchwork composition needs the patchwork package.",
          ">" = 'Install it with {.code install.packages("patchwork")}.'),
        "needs_package", package = "patchwork")
    }
    return(patchwork::patchworkGrob(plot))
  }
  if (!inherits(plot, "ggplot")) {
    figspec_abort(
      c("{.arg plot} must be a ggplot, a patchwork composition, or a gtable.",
        "x" = "You gave {.cls {class(plot)}}."),
      "bad_input")
  }
  ggplot2::ggplotGrob(plot)
}

# Pads the outside of a figure so it fills a canvas larger than it needs,
# keeping it centred. Used when a caller fixes both the canvas and the panel
# and the decoration does not fill the gap: rather than quietly stretching the
# panel, the slack goes to the margin, and both numbers are honoured exactly.
pad_gtable <- function(gt, extra_w_mm = 0, extra_h_mm = 0) {
  if (extra_w_mm > 1e-6) {
    half <- grid::unit(extra_w_mm / 2, "mm")
    gt <- gtable::gtable_add_cols(gt, half, pos = 0)
    gt <- gtable::gtable_add_cols(gt, half, pos = -1)
  }
  if (extra_h_mm > 1e-6) {
    half <- grid::unit(extra_h_mm / 2, "mm")
    gt <- gtable::gtable_add_rows(gt, half, pos = 0)
    gt <- gtable::gtable_add_rows(gt, half, pos = -1)
  }
  gt
}


# The measuring device ----------------------------------------------------

# Text width is a font measurement, and fonts resolve per device. Measuring on
# whatever device happens to be current, then writing with ragg, puts the
# panel out by a fraction of a millimetre. So measurement opens the device the
# figure is actually destined for, at a size large enough that nothing is
# clipped, and closes it again.
on_measure_device <- function(ext, expr) {
  old <- grDevices::dev.cur()
  tmp <- tempfile(fileext = paste0(".", if (is.null(ext)) "pdf" else ext))
  opened <- open_measure_device(ext, tmp)
  on.exit({
    if (opened) suppressWarnings(try(grDevices::dev.off(), silent = TRUE))
    if (old > 1L && old %in% grDevices::dev.list()) grDevices::dev.set(old)
    unlink(tmp)
  }, add = TRUE)
  force(expr)
}

# Devices disagree about how they take a size: ragg wants pixels plus a
# resolution, the base and cairo devices want inches. Both are handled rather
# than falling back to a generic device, because the generic device is exactly
# the source of error this function exists to remove.
open_measure_device <- function(ext, path) {
  big_in <- 40
  dev <- if (is.null(ext)) NULL else select_device(ext)
  ok <- FALSE

  if (!is.null(dev)) {
    ok <- tryCatch({
      if (isTRUE(ext %in% c("tiff", "tif", "png"))) {
        dev(path, width = big_in, height = big_in, units = "in", res = 300)
      } else {
        dev(path, width = big_in, height = big_in)
      }
      TRUE
    }, error = function(e) FALSE)
  }

  if (!ok) {
    ok <- tryCatch({
      grDevices::pdf(NULL, width = big_in, height = big_in)
      TRUE
    }, error = function(e) FALSE)
  }
  ok
}


# Solving for a size ------------------------------------------------------

# mm() pads to a common width so columns line up in a report. Inside a
# sentence that padding reads as a typo, so trim it here.
mm <- function(x) trimws(fmt_num(x))


# Works out the final canvas and panel geometry from whatever the caller
# supplied, and says plainly when the combination cannot be built.
#
# The four inputs are canvas width, canvas height, panel width and panel
# height, each optionally NULL, plus the journal's stated canvas width where
# there is one. They are not in conflict with each other; they are a pair of
# constraints on one equation, canvas = panel + decoration, whose third term is
# measurable. So the job is to solve, and only to refuse when no solution
# exists -- in which case the two numbers that would work are reported, since
# the caller cannot compute them without doing this measurement themselves.
solve_geometry <- function(plot, ext,
                           width_mm = NULL, height_mm = NULL,
                           panel_width = NULL, panel_height = NULL,
                           journal_width_mm = NULL, journal_name = NULL) {

  on_measure_device(ext, {
    gt <- as_plot_gtable(plot)

    # Decoration is measured with the panels collapsed, so what remains is
    # exactly what the axes, legend, strips and margins need.
    bare <- set_panels(gt, 0, 0)
    dec_w <- sum_units(bare, "width")
    dec_h <- sum_units(bare, "height")
    n_panel_cols <- count_panel_tracks(gt, "width")
    n_panel_rows <- count_panel_tracks(gt, "height")

    # "max" means: the widest panel that still fits the canvas we are allowed.
    ceiling_w <- width_mm %||% journal_width_mm
    if (identical(panel_width, "max")) {
      if (is.null(ceiling_w)) {
        figspec_abort(
          c("{.code panel_width = \"max\"} needs a canvas to fit inside.",
            ">" = "Give a {.arg journal}, or a {.arg width}."),
          "max_without_canvas", parent.frame()
        )
      }
      panel_width <- (ceiling_w - dec_w) / max(n_panel_cols, 1)
      if (panel_width <= 0) {
        figspec_abort(
          c("There is no room left for a panel.",
            "x" = "The axes, legend and margins alone need {mm(dec_w)} mm, and
                   the canvas is {mm(ceiling_w)} mm.",
            ">" = "Shorten the axis labels, move the legend, or use a wider
                   column."),
          "no_room_for_panel", parent.frame(),
          decoration_mm = dec_w, canvas_mm = ceiling_w
        )
      }
    }
    if (identical(panel_height, "max")) {
      if (is.null(height_mm)) {
        figspec_abort(
          c("{.code panel_height = \"max\"} needs a canvas to fit inside.",
            ">" = "Give a {.arg height}."),
          "max_without_canvas", parent.frame()
        )
      }
      panel_height <- (height_mm - dec_h) / max(n_panel_rows, 1)
    }

    pw <- if (is.null(panel_width)) NULL else as.numeric(panel_width)
    ph <- if (is.null(panel_height)) NULL else as.numeric(panel_height)

    # Natural size, with the panels set where the caller asked for them.
    sized <- set_panels(gt, pw, ph)
    nat_w <- sum_units(sized, "width")
    nat_h <- sum_units(sized, "height")

    pad_w <- 0
    pad_h <- 0
    final_w <- nat_w
    final_h <- nat_h

    # Both a canvas and a panel: honour both, or explain why they cannot both
    # hold. Slack goes to the margin so neither number is quietly adjusted.
    if (!is.null(width_mm) && !is.null(pw)) {
      slack <- width_mm - nat_w
      if (slack < -0.05) {
        needed_panel <- (width_mm - dec_w) / max(n_panel_cols, 1)
        wanted <- if (n_panel_cols > 1) {
          paste0(n_panel_cols, " panels of ", mm(pw), " mm each")
        } else {
          paste0("a ", mm(pw), " mm panel")
        }
        figspec_abort(
          c("A {mm(width_mm)} mm canvas cannot hold {wanted}.",
            "i" = "The axes, legend and margins need {mm(dec_w)} mm, which
                   leaves {mm(width_mm - dec_w)} mm.",
            "*" = "Widen the canvas to {mm(nat_w)} mm, or",
            "*" = "set {.code panel_width = {mm(max(needed_panel, 0))}}{if
                   (n_panel_cols > 1) ' (each)' else ''}."),
          "size_conflict", environment(),
          canvas_mm = width_mm, panel_mm = pw, decoration_mm = dec_w,
          canvas_that_fits_mm = nat_w,
          panel_that_fits_mm = max(needed_panel, 0), panels = n_panel_cols
        )
      }
      pad_w <- max(slack, 0)
      final_w <- width_mm
    } else if (!is.null(width_mm)) {
      final_w <- width_mm
    }

    if (!is.null(height_mm) && !is.null(ph)) {
      slack <- height_mm - nat_h
      if (slack < -0.05) {
        needed_panel <- (height_mm - dec_h) / max(n_panel_rows, 1)
        figspec_abort(
          c("A {mm(height_mm)} mm canvas cannot hold a {mm(ph)} mm panel.",
            "i" = "The title, axes and margins need {mm(dec_h)} mm, which
                   leaves {mm(height_mm - dec_h)} mm.",
            "*" = "Make the canvas {mm(nat_h)} mm tall, or",
            "*" = "set {.code panel_height = {mm(max(needed_panel, 0))}}."),
          "size_conflict", environment(),
          canvas_mm = height_mm, panel_mm = ph, decoration_mm = dec_h,
          canvas_that_fits_mm = nat_h, panel_that_fits_mm = max(needed_panel, 0)
        )
      }
      pad_h <- max(slack, 0)
      final_h <- height_mm
    } else if (!is.null(height_mm)) {
      final_h <- height_mm
    }

    # A journal always pins the canvas (see fig_save()), so an over-wide panel
    # arrives at the canvas-versus-panel check above and is reported there.
    # An explicit `width` that overruns the column is caught by fig_check()
    # on the written file, which is where a width failure belongs.

    out <- if (pad_w > 0 || pad_h > 0) pad_gtable(sized, pad_w, pad_h) else sized

    list(
      plot = out,
      width_mm = final_w,
      height_mm = final_h,
      panel_width_mm = if (is.null(pw)) (final_w - dec_w) / max(n_panel_cols, 1) else pw,
      panel_height_mm = if (is.null(ph)) (final_h - dec_h) / max(n_panel_rows, 1) else ph,
      decoration_width_mm = dec_w,
      decoration_height_mm = dec_h,
      panels_across = n_panel_cols,
      panels_down = n_panel_rows,
      panel_set = !is.null(pw) || !is.null(ph)
    )
  })
}

# How many panels sit side by side, counting through nested compositions. A
# panel width applies to each of them, so the canvas grows with the count.
count_panel_tracks <- function(gt, dim) {
  if (!inherits(gt, "gtable")) return(0)
  pos <- if (dim == "width") gt$layout$l else gt$layout$t
  n <- length(unique(pos[grepl("^panel", gt$layout$name)]))
  kids <- vapply(gt$grobs, function(g) count_panel_tracks(g, dim), numeric(1))
  if (n > 0) n else if (length(kids)) max(0, sum(kids)) else 0
}


#' The panel width a set of figures can share
#'
#' Works out the widest plot area that every figure in a set can use while
#' still fitting the canvas. Pass the answer to [fig_save()] and the figures
#' come out with matching plot areas, which is what makes them look like a set
#' on the page.
#'
#' `panel_width = "max"` on a single figure takes the widest panel *that
#' figure* can have, which is the same thing [fig_save()] does anyway. Matching
#' panels is a property of a set, not of one figure: the figure with the
#' longest axis labels has the least room, and it sets the width the others
#' have to meet. That is what this measures.
#'
#' @param plots A list of plots, or one plot.
#' @param journal Registry id. Supplies the canvas width.
#' @param column Which of the journal's stated column widths to fit.
#' @param width Canvas width, if you are not sizing to a journal.
#' @param units Units for `width` and for the returned value.
#' @param format File format the figures will be written in, for example
#'   `"tiff"`. Text is measured in the font the device resolves, so measuring
#'   on the device you will actually save with is what makes the answer exact.
#'   Defaults to the journal's first accepted format.
#' @return A single number: the shared panel width. The per-figure maxima are
#'   attached as the `"per_figure"` attribute, so you can see which figure is
#'   the binding constraint.
#' @seealso [fig_save()]
#' @examples
#' library(ggplot2)
#' figs <- list(
#'   a = ggplot(mtcars, aes(wt, mpg)) + geom_point(),
#'   b = ggplot(mtcars, aes(wt, mpg)) + geom_point() + labs(y = "A much longer label")
#' )
#' fig_panel_width(figs, journal = "frontiers")
#' @export
fig_panel_width <- function(plots, journal = NULL, column = NULL,
                            width = NULL, units = c("mm", "cm", "in"),
                            format = NULL) {
  units <- match.arg(units)
  check_size(width, "width", units)
  if (!is.null(column) && is.null(journal)) {
    figspec_abort(
      c("{.arg column} names one of a journal's own widths, so it needs a {.arg journal}.",
        ">" = "Give a {.arg width} in {units} instead."),
      "column_without_journal", parent.frame(), column = column
    )
  }
  if (inherits(plots, "ggplot") || inherits(plots, "patchwork") ||
      inherits(plots, "gtable")) {
    plots <- list(plots)
  }
  if (!length(plots)) figspec_abort("{.arg plots} is empty.", "bad_input")

  canvas_mm <- if (!is.null(width)) {
    convert_length(width, units, "mm")
  } else if (!is.null(journal)) {
    fig_width(journal, column %||% "single", "mm")
  } else {
    figspec_abort(
      c("Give a {.arg journal} or a {.arg width}.",
        "i" = "A shared panel width is the widest panel that fits a canvas, so
               there has to be a canvas to fit inside."),
      "missing_arg")
  }

  if (is.null(format) && !is.null(journal)) {
    format <- tryCatch(default_format(journal_spec(journal)),
                       error = function(e) NULL)
  }
  ext <- if (is.null(format)) "png" else tolower(sub("^\\.", "", format))

  per <- vapply(plots, function(p) {
    on_measure_device(ext, {
      gt <- as_plot_gtable(p)
      dec <- sum_units(set_panels(gt, 0, 0), "width")
      n <- max(count_panel_tracks(gt, "width"), 1)
      (canvas_mm - dec) / n
    })
  }, numeric(1))
  names(per) <- names(plots)

  if (any(per <= 0)) {
    worst <- names(per)[which.min(per)] %||% which.min(per)
    figspec_abort(
      c("Figure {worst} has no room left for a panel at {mm(canvas_mm)} mm.",
        "x" = "Its axes, legend and margins already fill the canvas.",
        ">" = "Shorten the axis labels, move the legend, or use a wider column."),
      "no_room_for_panel", figure = worst, canvas_mm = canvas_mm)
  }

  out <- convert_length(min(per), "mm", units)
  attr(out, "per_figure") <- convert_length(per, "mm", units)
  out
}


# Validating a size ------------------------------------------------------

# Graphics devices do not defend themselves. Handed a width of zero, a negative
# height or a non-finite resolution, they do not raise an R error -- they take
# the whole session down with them. So every size that can reach a device is
# checked here first, at the door, where the argument still has a name the
# caller recognises and a value worth quoting back.

check_size <- function(x, arg, units = "mm", allow_max = FALSE,
                       call = parent.frame()) {
  if (is.null(x)) return(invisible(NULL))

  if (allow_max && is.character(x)) {
    if (length(x) == 1L && identical(x, "max")) return(invisible(x))
    figspec_abort(
      c("{.arg {arg}} must be a number or {.val max}.",
        "x" = "You gave {.val {x}}."),
      "bad_size", call, arg = arg, value = x
    )
  }
  if (!is.numeric(x) || length(x) != 1L) {
    figspec_abort(
      c("{.arg {arg}} must be a single number{if (allow_max) ' or \"max\"' else ''}, in {units}.",
        "x" = if (length(x) != 1L) {
          "You gave {length(x)} value{?s}."
        } else {
          "You gave {.cls {class(x)}}."
        }),
      "bad_size", call, arg = arg, value = x
    )
  }
  if (is.na(x) || !is.finite(x)) {
    figspec_abort(
      c("{.arg {arg}} must be a finite number of {units}.",
        "x" = "You gave {.val {x}}."),
      "bad_size", call, arg = arg, value = x
    )
  }
  if (x <= 0) {
    figspec_abort(
      c("{.arg {arg}} must be greater than zero.",
        "x" = "You gave {.val {x}} {units}.",
        "i" = "A figure with no width cannot be drawn, and the graphics device
               would fail rather than refuse."),
      "bad_size", call, arg = arg, value = x
    )
  }
  invisible(x)
}

check_dpi <- function(dpi, call = parent.frame()) {
  if (is.null(dpi)) return(invisible(NULL))
  if (!is.numeric(dpi) || length(dpi) != 1L || is.na(dpi) ||
      !is.finite(dpi) || dpi <= 0) {
    figspec_abort(
      c("{.arg dpi} must be a single positive number.",
        "x" = "You gave {.val {dpi}}."),
      "bad_size", call, value = dpi
    )
  }
  invisible(dpi)
}


#' @param x A `figspec_geometry` object, from [fig_geometry()].
#' @param ... Ignored.
#' @rdname fig_geometry
#' @export
plot.figspec_geometry <- function(x, ...) {
  if (is.na(x$canvas_width_mm) || is.na(x$canvas_height_mm)) {
    figspec_abort(
      c("This figure has no canvas to draw.",
        "i" = "Its panels are still free to stretch, so the layout has no
               size of its own yet.",
        ">" = "Size it first with {.fn fig_panel_size}, or measure a saved
               figure."),
      "bad_input"
    )
  }

  cw <- x$canvas_width_mm; ch <- x$canvas_height_mm
  nx <- max(x$panels_across, 1L); ny <- max(x$panels_down, 1L)
  pw <- x$panel_width_mm; ph <- x$panel_height_mm
  gx <- if (nx > 1L) (x$gap_x_mm %|NA|% 0) / (nx - 1L) else 0
  gy <- if (ny > 1L) (x$gap_y_mm %|NA|% 0) / (ny - 1L) else 0
  block_w <- pw * nx + gx * (nx - 1L)
  block_h <- ph * ny + gy * (ny - 1L)
  l <- x$left_mm %|NA|% ((cw - block_w) / 2)
  b <- x$bottom_mm %|NA|% ((ch - block_h) / 2)

  # Every panel drawn, not one rectangle standing in for all of them: a
  # three-facet figure does not look like one wide panel, and the gaps between
  # them are part of where the space goes.
  grid_xy <- expand.grid(col = seq_len(nx), row = seq_len(ny))
  panels <- data.frame(
    xmin = l + (grid_xy$col - 1) * (pw + gx),
    xmax = l + (grid_xy$col - 1) * (pw + gx) + pw,
    ymin = b + (grid_xy$row - 1) * (ph + gy),
    ymax = b + (grid_xy$row - 1) * (ph + gy) + ph,
    what = "panel", stringsAsFactors = FALSE
  )
  parts <- rbind(
    data.frame(xmin = 0, xmax = cw, ymin = 0, ymax = ch, what = "canvas",
               stringsAsFactors = FALSE),
    panels
  )

  # One panel can carry its own label. Several cannot: written across the
  # middle one it overflows into its neighbours and reads as a caption for
  # that panel rather than for all of them, so it goes below the figure.
  many <- nx * ny > 1
  labs <- data.frame(
    x = c(cw / 2, if (many) cw / 2 else l + block_w / 2),
    y = c(ch + ch * 0.17, if (many) -ch * 0.14 else b + block_h / 2),
    label = c(paste0("canvas  ", mm(cw), " x ", mm(ch), " mm"),
              paste0(if (many) paste0(nx * ny, " panels of  ") else "panel  ",
                     mm(pw), " x ", mm(ph), " mm")),
    stringsAsFactors = FALSE
  )

  # The decoration each side, written where that side is. A band too thin to
  # hold its own label gets it just outside the canvas instead, rather than
  # printed over the panel edge.
  rt <- x$right_mm %|NA|% 0; tp <- x$top_mm %|NA|% 0
  thin <- 5
  sides <- data.frame(
    side  = c("left", "right", "top", "bottom"),
    band  = c(x$left_mm, x$right_mm, x$top_mm, x$bottom_mm),
    x     = c(l / 2, cw - rt / 2, cw / 2, cw / 2),
    y     = c(b + block_h / 2, b + block_h / 2, ch - tp / 2, b / 2),
    out_x = c(-cw * 0.045, cw + cw * 0.045, cw / 2, cw / 2),
    out_y = c(b + block_h / 2, b + block_h / 2, ch + ch * 0.05, -ch * 0.06),
    angle = c(90, 90, 0, 0),
    stringsAsFactors = FALSE
  )
  sides <- sides[!is.na(sides$band) & sides$band >= 0.05, , drop = FALSE]
  if (nrow(sides)) {
    tight <- sides$band < thin
    sides$x[tight] <- sides$out_x[tight]
    sides$y[tight] <- sides$out_y[tight]
    sides$label <- vapply(sides$band, mm, character(1))
  }

  ggplot2::ggplot() +
    ggplot2::geom_rect(
      data = parts,
      ggplot2::aes(xmin = .data$xmin, xmax = .data$xmax,
                   ymin = .data$ymin, ymax = .data$ymax,
                   fill = .data$what, colour = .data$what),
      linewidth = 0.4
    ) +
    ggplot2::geom_text(data = sides,
                       ggplot2::aes(.data$x, .data$y, label = .data$label,
                                    angle = .data$angle),
                       size = 2.9, colour = "grey25") +
    ggplot2::geom_text(data = labs,
                       ggplot2::aes(.data$x, .data$y, label = .data$label),
                       size = 3.2, lineheight = 0.95, colour = "grey10") +
    ggplot2::scale_fill_manual(values = c(canvas = "grey93", panel = "white")) +
    ggplot2::scale_colour_manual(values = c(canvas = "grey60", panel = "grey35")) +
    ggplot2::coord_fixed(clip = "off") +
    ggplot2::labs(x = NULL, y = NULL) +
    ggplot2::theme_void() +
    ggplot2::theme(legend.position = "none",
                   plot.margin = ggplot2::margin(16, 18, 20, 18))
}

# NA-coalescing, for the composition case where a side is not separable.
`%|NA|%` <- function(a, b) if (is.null(a) || is.na(a)) b else a
