#' Save a figure at an exact size and resolution
#'
#' Saves a figure built to a specification. A journal is one way to supply one:
#' name a journal and the size, resolution, file format and font come from its
#' published requirements. Give a panel size instead, or as well, and the plot
#' area is set to that size exactly. Give neither and this behaves like
#' [ggplot2::ggsave()] with millimetres as the default unit and the written
#' file checked afterwards.
#'
#' # Canvas and panel
#'
#' A figure has two widths:
#'
#' * the **canvas**, which is the image file, and
#' * the **panel**, which is the plot area left once the axis titles, axis
#'   text, tick marks, legend and margins have taken their share.
#'
#' `width` sets the canvas. `panel_width` sets the panel. They are not
#' alternatives and they are not in conflict: the two are related by
#' `canvas = panel + decoration`, and the decoration is measured, not guessed.
#' Give one and the other is worked out. Give both and both are honoured, with
#' any slack going to the margin so that neither number is quietly adjusted.
#' Ask for a pair that cannot exist and the error reports the two values that
#' would work, because you cannot arrive at them without this measurement.
#'
#' Panel size is what makes a set of figures look like a set. Two figures saved
#' at the same canvas width have different panel widths if their y-axis labels
#' differ in length, and on the page they look mismatched. No journal states a
#' rule about this, so figspec never reports it as a compliance failure — but
#' it is usually what an author is trying to fix.
#'
#' `panel_width = "max"` takes the widest panel that still fits the canvas you
#' are allowed. Under a journal, that is the widest panel that fits the column,
#' which gives every figure in a submission the same panel width without your
#' having to work out what it is.
#'
#' # What `column` means
#'
#' Journals lay their pages out in columns, and state a figure width for each
#' one a figure may span. `column` selects between the widths that journal
#' publishes: `"single"` fits one text column, `"double"` spans the page, and
#' some publishers also state `"half"`, `"onehalf"` or `"triple"`. The names
#' and the millimetres both come from the journal, so they differ between
#' publishers — Science's single column is 57 mm where Cell Press's is 85 mm.
#' Call [fig_columns()] to see what a journal offers, and [fig_width()] for one
#' value.
#'
#' `column` is a lookup into a journal's own layout, so it means nothing
#' without `journal`. Sizing without a journal is what `width` is for.
#'
#' @param filename Output path. The extension selects the format. With a
#'   journal and no extension, the journal's first accepted format is used.
#' @param plot Plot to save: a ggplot, a patchwork composition, or a `gtable`.
#'   Defaults to the last plot displayed.
#' @param journal Registry id, for example `"cell_press"`. Optional. When
#'   given, it supplies the canvas width, resolution, format and font.
#' @param column Which of the journal's stated column widths to fit. Only
#'   meaningful with `journal`; defaults to `"single"` when one is given.
#' @param width Canvas width. Overrides the journal's column width.
#' @param height Canvas height. Defaults to three quarters of the canvas
#'   width, which is a convenience, not a journal requirement.
#' @param panel_width,panel_height Size of the plot area itself. A number, or
#'   `"max"` for the largest that fits the canvas. With facets or a patchwork
#'   composition this applies to each panel.
#' @param units Units for `width`, `height`, `panel_width` and `panel_height`.
#' @param dpi Resolution. Defaults to the journal's stated minimum, or 300.
#' @param check Whether to check the result and report failures as a warning.
#'   Only checks against a journal when one is given.
#' @param ... Passed to [ggplot2::ggsave()].
#' @return The path to the written file, invisibly, with the achieved geometry
#'   attached as the `"figspec_geometry"` attribute. See [fig_geometry()].
#' @seealso [fig_panel_size()] to set a panel size without saving,
#'   [fig_columns()] for a journal's stated widths.
#' @examples
#' library(ggplot2)
#' p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
#'
#' # To a journal's requirements, saved in a format that journal accepts
#' out <- file.path(tempdir(), "figure_1.tiff")
#' fig_save(out, p + theme_journal("frontiers"), journal = "frontiers")
#' unlink(out)
#'
#' # To an exact panel size, no journal involved
#' panelled <- file.path(tempdir(), "figure_2.png")
#' fig_save(panelled, p, panel_width = 62)
#' unlink(panelled)
#'
#' # Working the canvas out from the panel means opening a device to measure
#' # the decoration on, which is slow enough that the rest of the tour is kept
#' # out of the timed examples rather than cut from the documentation.
#' \donttest{
#' widest <- file.path(tempdir(), "figure_3.tiff")
#'
#' # The widest panel that still fits the column
#' fig_save(widest, p, journal = "frontiers", panel_width = "max")
#' unlink(widest)
#'
#' # Where the space in a figure went
#' measured <- file.path(tempdir(), "figure_4.png")
#' fig_geometry(fig_save(measured, p, panel_width = 62))
#' unlink(measured)
#' }
#' @export
fig_save <- function(filename, plot = ggplot2::last_plot(),
                     journal = NULL, column = NULL,
                     width = NULL, height = NULL,
                     panel_width = NULL, panel_height = NULL,
                     units = c("mm", "cm", "in"),
                     dpi = NULL, check = TRUE, ...) {
  units <- match.arg(units)

  # Before anything opens a device. A bad size does not produce an R error
  # further down; it ends the session.
  check_size(width, "width", units)
  check_size(height, "height", units)
  check_size(panel_width, "panel_width", units, allow_max = TRUE)
  check_size(panel_height, "panel_height", units, allow_max = TRUE)
  check_dpi(dpi)

  if (!is.null(column) && is.null(journal)) {
    figspec_abort(
      c("{.arg column} needs a {.arg journal}.",
        "i" = "{.arg column} selects between the widths a journal publishes for
               its own page layout, so {.val {column}} means nothing on its own
               - Science's single column is 57 mm where Cell Press's is 85 mm.",
        ">" = "To size to a journal: {.code fig_save(file, plot,
               journal = \"cell_press\", column = \"{column}\")}",
        ">" = "To size without one: {.code fig_save(file, plot, width = 85)}
               or {.code fig_save(file, plot, panel_width = 62)}"),
      "column_without_journal", environment(), column = column
    )
  }

  # `column` names one of the journal's own widths and `width` states a width
  # outright. Given both, one has to be discarded, and discarding it quietly is
  # how a figure ends up a size nobody asked for.
  if (!is.null(column) && !is.null(width)) {
    stated <- tryCatch(fig_width(journal, column, units), error = function(e) NULL)
    figspec_abort(
      c("{.arg column} and {.arg width} both set the canvas width, so only one
         can apply.",
        "*" = if (is.null(stated)) {
          "{.code column = \"{column}\"} takes the width the journal states."
        } else {
          "{.code column = \"{column}\"} is {stated} {units}."
        },
        "*" = "{.code width = {width}} is {width} {units}.",
        ">" = "Drop whichever you did not mean."),
      "column_width_conflict", environment(),
      column = column, width = width, column_width = stated
    )
  }
  spec <- if (is.null(journal)) NULL else journal_spec(journal)
  if (!is.null(spec) && is.null(column)) column <- "single"

  # ---- format ------------------------------------------------------------
  ext <- tolower(tools::file_ext(filename))
  if (!nzchar(ext)) {
    ext <- if (is.null(spec)) "png" else default_format(spec)
    filename <- paste0(filename, ".", ext)
  }
  if (!is.null(spec) && !is.null(spec$formats) &&
      !ext %in% tolower(unlist(spec$formats))) {
    warning(
      "'", spec$name, "' does not list ", toupper(ext),
      " among its accepted formats (",
      paste(toupper(unlist(spec$formats)), collapse = ", "), ").",
      call. = FALSE
    )
  }

  # ---- resolution --------------------------------------------------------
  if (is.null(dpi)) {
    dpi <- if (is.null(spec)) {
      300
    } else if (is.null(spec$dpi_min)) {
      default_note(spec, "dpi_min", "300 dpi", "a minimum resolution")
      300
    } else {
      as.numeric(spec$dpi_min)
    }
  }

  # ---- the font, before anything is measured -----------------------------
  # Type is measured in the font it will be drawn in, so the font has to be on
  # the plot before the panel arithmetic runs, or the decoration comes out the
  # width of the wrong typeface.
  if (!is.null(spec) && !is.null(spec$font_families) &&
      inherits(plot, "ggplot") && !nzchar(theme_family_raw(plot))) {
    fam <- resolve_family(spec$font_families)
    if (device_resolves_system_fonts(ext) && nzchar(fam)) {
      plot <- plot + ggplot2::theme(text = ggplot2::element_text(family = fam))
    } else {
      warning(
        "'", spec$name, "' asks for ",
        paste(unlist(spec$font_families), collapse = " or "),
        ", which this ", toupper(ext), " device cannot apply",
        if (!nzchar(fam)) " and which is not installed on this system" else "",
        ". The figure was saved in the default font. Save as TIFF or PNG, ",
        "which figspec renders with ragg, to meet the font requirement.",
        call. = FALSE
      )
    }
  }

  # ---- geometry ----------------------------------------------------------
  journal_w <- if (is.null(spec)) NULL else {
    tryCatch(fig_width(journal, column, "mm"), error = function(e) stop(e))
  }
  width_mm <- if (is.null(width)) NULL else convert_length(width, units, "mm")
  height_mm <- if (is.null(height)) NULL else convert_length(height, units, "mm")
  pw <- if (is.numeric(panel_width)) convert_length(panel_width, units, "mm") else panel_width
  ph <- if (is.numeric(panel_height)) convert_length(panel_height, units, "mm") else panel_height

  # A journal states the canvas, and that is not negotiable: a figure wider or
  # narrower than the column gets rescaled in production, which is what drives
  # type below the stated minimum. So the column pins the canvas even when a
  # panel size is given -- the panel then decides how much margin sits around
  # it, not how wide the image is. An explicit `width` overrides.
  if (is.null(width_mm) && !is.null(journal_w)) width_mm <- journal_w

  geom <- solve_geometry(
    plot, ext,
    width_mm = width_mm, height_mm = height_mm,
    panel_width = pw, panel_height = ph,
    journal_width_mm = journal_w,
    journal_name = if (is.null(spec)) NULL else spec$name
  )

  final_w <- geom$width_mm
  final_h <- if (!is.null(geom$height_mm)) geom$height_mm else final_w * 0.75
  if (is.null(height_mm) && is.null(ph)) final_h <- final_w * 0.75

  if (!is.null(spec) && !is.null(spec$height_max_mm) &&
      final_h > as.numeric(spec$height_max_mm)) {
    warning(
      "Height of ", fmt_num(final_h), " mm exceeds the ",
      spec$height_max_mm, " mm maximum stated by '", spec$name, "'.",
      call. = FALSE
    )
  }

  # ---- write -------------------------------------------------------------
  device <- select_device(ext)
  args <- list(
    filename = filename, plot = geom$plot,
    width = final_w, height = final_h, units = "mm", dpi = dpi, ...
  )
  if (!is.null(device)) args$device <- device

  # One clear warning about an unusable font is more useful than one warning
  # per text grob, so muffle the device's per-grob chatter here.
  quiet_font <- function(expr) {
    withCallingHandlers(expr, warning = function(w) {
      if (grepl("not found in (PostScript|Type 1) font database|cairo DLL",
                conditionMessage(w))) {
        invokeRestart("muffleWarning")
      }
    })
  }
  saved <- tryCatch(quiet_font(do.call(ggplot2::ggsave, args)),
                    error = function(e) e)
  if (inherits(saved, "error")) {
    if (grepl("invalid font type|font family|font database",
              conditionMessage(saved))) {
      # Vector devices on some systems cannot use a system-installed font.
      # Produce the file rather than failing, but be explicit that the font
      # requirement is now unmet: a silent default font is how a figure comes
      # back from production in the wrong typeface.
      warning(
        "The ", toupper(ext), " device on this system cannot render the font '",
        theme_family(plot), "'", if (!is.null(spec)) paste0(" that '", spec$name, "' requires") else "",
        ", so the figure was saved in the default font. ",
        "Save as TIFF or PNG instead, which figspec renders with ragg, or ",
        "install the font for this device.",
        call. = FALSE
      )
      if (inherits(plot, "ggplot")) {
        plain <- plot + ggplot2::theme(text = ggplot2::element_text(family = ""))
        args$plot <- solve_geometry(
          plain, ext, width_mm = width_mm, height_mm = height_mm,
          panel_width = pw, panel_height = ph,
          journal_width_mm = journal_w,
          journal_name = if (is.null(spec)) NULL else spec$name
        )$plot
      }
      quiet_font(do.call(ggplot2::ggsave, args))
    } else {
      stop(saved)
    }
  }

  if (!file.exists(filename) || file.size(filename) == 0) {
    figspec_abort(
      c("The {toupper(ext)} device did not write a usable file.",
        ">" = "Try a different format, for example TIFF or PNG."),
      "device_failed", format = ext)
  }

  # ---- report ------------------------------------------------------------
  if (isTRUE(check) && !is.null(spec)) {
    report <- fig_check(filename, journal, column)
    fails <- report[report$status == "fail", , drop = FALSE]
    if (nrow(fails) > 0) {
      warning(
        "Saved figure does not meet ", nrow(fails), " requirement(s) of '",
        spec$name, "': ", paste(fails$check, collapse = ", "),
        ". Run fig_check() on the file for detail.",
        call. = FALSE
      )
    }
  }

  attr(filename, "figspec_geometry") <- data.frame(
    canvas_width_mm  = round(final_w, 2),
    canvas_height_mm = round(final_h, 2),
    panel_width_mm   = round(geom$panel_width_mm, 2),
    panel_height_mm  = round(
      if (is.null(ph)) (final_h - geom$decoration_height_mm) /
        max(geom$panels_down, 1) else geom$panel_height_mm, 2),
    decoration_width_mm  = round(geom$decoration_width_mm, 2),
    decoration_height_mm = round(geom$decoration_height_mm, 2),
    panels_across = geom$panels_across,
    panels_down   = geom$panels_down,
    stringsAsFactors = FALSE
  )
  invisible(filename)
}


# Formats R can actually write. A journal may accept Illustrator, Photoshop or
# PowerPoint files, and listing them first does not mean R can produce one, so
# a default has to be drawn from what a device exists for.
WRITABLE_FORMATS <- c("pdf", "eps", "ps", "svg", "tiff", "tif", "png", "jpeg", "jpg")

default_format <- function(spec) {
  fmts <- tolower(unlist(spec$formats %||% list()))
  writable <- intersect(fmts, WRITABLE_FORMATS)
  if (length(writable)) return(writable[[1]])
  if (length(fmts)) {
    figspec_abort(
      c("{spec$name} accepts {toupper(fmts)}, none of which R can write.",
        ">" = "Give an explicit file extension, or export one of those formats
               from another program."),
      "unsupported", formats = fmts)
  }
  default_note(spec, "formats", "PDF", "which file formats it accepts")
  "pdf"
}

# Prefer ragg for raster output: it renders text more accurately and writes
# the pHYs resolution header that fig_check() reads back.
select_device <- function(ext) {
  if (ext %in% c("tiff", "tif") && requireNamespace("ragg", quietly = TRUE)) {
    return(ragg::agg_tiff)
  }
  if (ext == "png" && requireNamespace("ragg", quietly = TRUE)) {
    return(ragg::agg_png)
  }
  if (ext == "svg" && requireNamespace("svglite", quietly = TRUE)) {
    return(svglite::svglite)
  }
  # The base pdf/postscript devices only know their own font database, so a
  # journal font such as Arial fails there. Cairo resolves system fonts.
  if (ext == "pdf" && cairo_ok()) {
    return(grDevices::cairo_pdf)
  }
  if (ext %in% c("eps", "ps") && cairo_ok()) {
    return(grDevices::cairo_ps)
  }
  NULL
}


# The font family a plot's theme actually asks for, if any.
theme_family_raw <- function(plot) {
  fam <- tryCatch(plot$theme$text$family, error = function(e) NULL)
  if (is.null(fam)) "" else fam
}

theme_family <- function(plot) {
  fam <- theme_family_raw(plot)
  if (!nzchar(fam)) "the requested font" else fam
}

device_resolves_system_fonts <- function(ext) {
  if (ext %in% c("png", "tiff", "tif")) return(requireNamespace("ragg", quietly = TRUE))
  if (ext == "svg") return(requireNamespace("svglite", quietly = TRUE))
  if (ext %in% c("pdf", "eps", "ps")) return(cairo_ok())
  FALSE
}


# capabilities("cairo") can report TRUE on builds where the cairo device still
# fails to load at run time, which produces an empty file rather than an
# error. Probe it once for real and remember the answer.
cairo_ok <- function() {
  if (!is.null(.figspec_cache$cairo_ok)) return(.figspec_cache$cairo_ok)
  ok <- FALSE
  if (isTRUE(capabilities("cairo"))) {
    tmp <- tempfile(fileext = ".pdf")
    ok <- tryCatch(
      withCallingHandlers({
        grDevices::cairo_pdf(tmp, width = 1, height = 1)
        grDevices::dev.off()
        file.exists(tmp) && file.size(tmp) > 0
      }, warning = function(w) invokeRestart("muffleWarning")),
      error = function(e) FALSE
    )
    if (isTRUE(ok) && !file.exists(tmp)) ok <- FALSE
    unlink(tmp)
    suppressWarnings(while (grDevices::dev.cur() > 1L) grDevices::dev.off())
  }
  .figspec_cache$cairo_ok <- isTRUE(ok)
  .figspec_cache$cairo_ok
}
