# Saving --------------------------------------------------------------------
#
# fig_save() is ggsave() with three things added, and most of the code below is
# those three:
#
#   size      the caller may fix the canvas, the panel, or both. Panel sizing
#             is solved in R/panel.R; this file receives the answer and writes
#             it out.
#   device    the format a journal wants decides which device can write it, and
#             the devices differ in what they can do. Base pdf() and
#             postscript() only know R's own font database, so a journal font
#             such as Arial silently does not apply; cairo and ragg resolve
#             system fonts. ragg also writes the resolution header back into a
#             PNG or TIFF, which is what lets fig_check() read the dpi off the
#             saved file afterwards.
#   check     the file is inspected after it is written, so a figure that does
#             not meet the specification says so at the point of saving rather
#             than at submission.
#
# The device choices are made in select_device() and are all conditional on an
# optional package being installed, so every path has to degrade rather than
# fail.

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
#' without `spec`. Sizing without a specification is what `width` is for.
#'
#' @param filename Output path. The extension selects the format. With a
#'   journal and no extension, the journal's first accepted format is used.
#' @param plot Plot to save: a ggplot, a patchwork composition, or a `gtable`.
#'   Defaults to the last plot displayed.
#' @param spec Optional specification: a registry id such as `"cell_press"`,
#'   a `figspec_spec`, or a named list of requirements. When given, it supplies
#'   the canvas width, resolution, format and font.
#' @param column Which of the journal's stated column widths to fit. Only
#'   meaningful with `spec`; defaults to `"single"` when one is given.
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
#' @param art_type Resolution category. `"auto"` classifies the live plot;
#'   explicit choices are `"colour"`, `"bw"`, `"line"`, and `"combination"`.
#' @param ... Passed to [ggplot2::ggsave()].
#' @return The path to the written file, invisibly, with the achieved geometry
#'   attached as the `"figspec_geometry"` attribute. See [fig_geometry()].
#' @seealso [fig_panel_size()] to set a panel size without saving,
#'   [fig_columns()] for a journal's stated widths.
#' @examples
#' library(ggplot2)
#' p <- ggplot(ggplot2::mpg, aes(displ, hwy, colour = class)) + geom_point()
#'
#' # To a journal's requirements, saved in a format that journal accepts
#' out <- file.path(tempdir(), "figure_1.tiff")
#' styled <- p + theme_spec("frontiers")
#' styled
#' fig_save(out, styled, spec = "frontiers")
#' unlink(out)
#'
#' # To an exact panel size, no journal involved
#' panelled <- file.path(tempdir(), "figure_2.png")
#' fig_save(panelled, p, panel_width = 62)
#' unlink(panelled)
#'
#' \donttest{
#' # To a project specification supplied directly in R. This opens a second
#' # graphics device, so it remains a worked website example without slowing
#' # CRAN's ordinary example pass.
#' report_spec <- list(
#'   name = "Quarterly research report",
#'   columns = list(full = 160),
#'   formats = "png",
#'   dpi_min = 300,
#'   font_min_pt = 9
#' )
#' report_file <- file.path(tempdir(), "report-figure.png")
#' fig_save(report_file, p + theme_spec(report_spec),
#'          spec = report_spec, column = "full")
#' unlink(report_file)
#' }
#'
#' # Working the canvas out from the panel means opening a device to measure
#' # the decoration on, which is slow enough that the rest of the tour is kept
#' # out of the timed examples rather than cut from the documentation.
#' \donttest{
#' widest <- file.path(tempdir(), "figure_3.tiff")
#'
#' # The widest panel that still fits the column
#' fig_save(widest, p, spec = "frontiers", panel_width = "max")
#' unlink(widest)
#'
#' # Where the space in a figure went
#' measured <- file.path(tempdir(), "figure_4.png")
#' fig_geometry(fig_save(measured, p, panel_width = 62))
#' unlink(measured)
#' }
#' @export
fig_save <- function(filename, plot = ggplot2::last_plot(),
                     spec = NULL, column = NULL,
                     width = NULL, height = NULL,
                     panel_width = NULL, panel_height = NULL,
                     units = c("mm", "cm", "in"),
                     dpi = NULL, check = TRUE,
                     art_type = c("auto", "colour", "bw", "line", "combination"),
                     ...) {
  units <- match.arg(units)
  art_type <- british_spelling(art_type)
  art_type <- match.arg(art_type)
  dots <- list(...)
  if ("scale" %in% names(dots)) {
    figspec_abort(
      c("{.arg scale} cannot be used with {.fn fig_save}.",
        "i" = "It changes the written dimensions after figspec has solved and recorded them.",
        ">" = "Set {.arg width}, {.arg height}, {.arg panel_width}, or {.arg panel_height} explicitly instead."),
      "size_conflict")
  }

  # Before anything opens a device. A bad size does not produce an R error
  # further down; it ends the session.
  check_size(width, "width", units)
  check_size(height, "height", units)
  check_size(panel_width, "panel_width", units, allow_max = TRUE)
  check_size(panel_height, "panel_height", units, allow_max = TRUE)
  check_dpi(dpi)

  if (!is.null(column) && is.null(spec)) {
    figspec_abort(
      c("{.arg column} needs a {.arg spec}.",
        "i" = "{.arg column} selects between the widths recorded in a
               specification, so {.val {column}} means nothing on its own
               - Science's single column is 57 mm where Cell Press's is 85 mm.",
        ">" = "To size to a specification: {.code fig_save(file, plot,
               spec = \"cell_press\", column = \"{column}\")}",
        ">" = "To size without one: {.code fig_save(file, plot, width = 85)}
               or {.code fig_save(file, plot, panel_width = 62)}"),
      "column_without_spec", environment(), column = column
    )
  }

  # `column` names one of the specification's widths and `width` states a width
  # outright. Given both, one has to be discarded, and discarding it quietly is
  # how a figure ends up a size nobody asked for.
  if (!is.null(column) && !is.null(width)) {
    stated <- tryCatch(fig_width(spec, column, units), error = function(e) NULL)
    figspec_abort(
      c("{.arg column} and {.arg width} both set the canvas width, so only one
         can apply.",
        "*" = if (is.null(stated)) {
          "{.code column = \"{column}\"} takes the width recorded in the specification."
        } else {
          "{.code column = \"{column}\"} is {stated} {units}."
        },
        "*" = "{.code width = {width}} is {width} {units}.",
        ">" = "Drop whichever you did not mean."),
      "column_width_conflict", environment(),
      column = column, width = width, column_width = stated
    )
  }
  spec <- if (is.null(spec)) NULL else spec_get(spec)
  if (!is.null(spec) && is.null(column)) column <- default_column(spec)
  chosen_art_type <- if (identical(art_type, "auto")) infer_art_type(plot) else art_type

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
    } else if (is.null(resolution_for_art_type(spec, chosen_art_type))) {
      default_note(spec, "dpi_min", "300 dpi", "a minimum resolution")
      300
    } else {
      resolution_for_art_type(spec, chosen_art_type)
    }
  }
  if (!is.null(spec$dpi_max) &&
      !meets_resolution(dpi, NULL, spec$dpi_max, TRUE,
                        spec$dpi_max_inclusive %||% TRUE)) {
    figspec_abort(
      c("{dpi} dpi exceeds the maximum recorded for {spec$name}.",
        "x" = "Maximum: {spec$dpi_max} dpi.",
        ">" = "Choose a resolution inside the specification's permitted range."),
      "bad_input", dpi = dpi)
  }

  required_modes <- tolower(unlist(spec$colour_mode %||% list()))
  cmyk_output <- length(required_modes) && "cmyk" %in% required_modes &&
    !any(required_modes %in% c("rgb", "grayscale", "greyscale"))
  if (isTRUE(cmyk_output) && !ext %in% c("pdf", "eps", "ps")) {
    figspec_abort(
      c("{spec$name} requires CMYK output, which {.val {toupper(ext)}} cannot write reliably from R.",
        "i" = "No RGB fallback is being written because it would not meet the recorded requirement.",
        ">" = "Use PDF, EPS, or PS for a CMYK export, or export through a colour-managed prepress tool."),
      "unsupported", colour_mode = required_modes)
  }

  # ---- the font, before anything is measured -----------------------------
  # Type is measured in the font it will be drawn in, so the font has to be on
  # the plot before the panel arithmetic runs, or the decoration comes out the
  # width of the wrong typeface.
  if (!is.null(spec) && !is.null(spec$font_families) && inherits(plot, "ggplot")) {
    base_font_device <- ext %in% c("pdf", "eps", "ps") &&
      (isTRUE(cmyk_output) || !cairo_ok())
    fam <- if (base_font_device) {
      base_device_family(spec$font_families, ext)
    } else {
      resolve_family(spec$font_families)
    }
    font_device_ok <- if (base_font_device) nzchar(fam) else device_resolves_system_fonts(ext)
    if (font_device_ok && nzchar(fam)) {
      current <- theme_family_raw(plot)
      if (nzchar(current) && !tolower(current) %in% tolower(unlist(spec$font_families))) {
        warning("Replacing disallowed font '", current, "' with '", fam,
                "' for '", spec$name, "'.", call. = FALSE)
      }
      plot <- plot + ggplot2::theme(text = ggplot2::element_text(family = fam))
    } else {
      figspec_abort(
        c("{spec$name} requires {paste(unlist(spec$font_families), collapse = ' or ')}, which this {toupper(ext)} device cannot apply.",
          "i" = "The file was not written because substituting a default font would violate the recorded requirement.",
          ">" = "Use a supported PDF/EPS font, or save as TIFF/PNG with ragg after installing an allowed font."),
        "unsupported", font_families = spec$font_families
      )
    }
  }

  # ---- geometry ----------------------------------------------------------
  spec_w <- if (is.null(spec)) {
    NULL
  } else if (!is.null(spec$columns)) {
    fig_width(spec, column, "mm")
  } else if (is.null(width) && !is.null(column)) {
    fig_width(spec, column, "mm")
  } else {
    NULL
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
  if (is.null(width_mm) && !is.null(spec_w)) width_mm <- spec_w
  if (is.null(width_mm) && is.null(pw)) {
    if (!is.null(spec)) {
      default_note(spec, "columns", "7 inches", "a figure width")
    }
    width_mm <- 7 * MM_PER_IN
  }

  geom <- solve_geometry(
    plot, ext,
    width_mm = width_mm, height_mm = height_mm,
    panel_width = pw, panel_height = ph,
    spec_width_mm = spec_w
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
  device <- select_device(ext, colour_mode = if (isTRUE(cmyk_output)) "cmyk" else NULL)
  args <- c(list(
    filename = filename, plot = geom$plot,
    width = final_w, height = final_h, units = "mm", dpi = dpi
  ), dots)
  if (!is.null(device)) args$device <- device
  if (isTRUE(cmyk_output) && exists("fam", inherits = FALSE) && nzchar(fam)) {
    args$family <- fam
  }
  if (ext %in% c("tiff", "tif") && !is.null(spec)) {
    if (!is.null(spec$tiff_compression)) args$compression <- spec$tiff_compression
    if (identical(spec$allow_alpha, FALSE)) args$bg <- "white"
  }

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
  saved <- tryCatch(with_r_fontconfig(quiet_font(do.call(ggplot2::ggsave, args))),
                    error = function(e) e)
  if (inherits(saved, "error")) {
    if (grepl("invalid font type|font family|font database",
              conditionMessage(saved))) {
      # Vector devices on some systems cannot use a system-installed font.
      # Produce the file rather than failing, but be explicit that the font
      # requirement is now unmet: a silent default font is how a figure comes
      # back from production in the wrong typeface.
      if (!is.null(spec) && !is.null(spec$font_families)) {
        figspec_abort(
          c("The {toupper(ext)} device cannot render the font {theme_family(plot)} required by {spec$name}.",
            "i" = "The file was not rewritten in a substitute font.",
            ">" = "Choose a device that can render an allowed font, or install it for this device."),
          "unsupported", font = theme_family(plot))
      }
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
          spec_width_mm = spec_w
        )$plot
      }
      with_r_fontconfig(quiet_font(do.call(ggplot2::ggsave, args)))
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
  if (ext %in% c("jpeg", "jpg")) ensure_jpeg_density(filename, dpi)

  # ---- report ------------------------------------------------------------
  if (isTRUE(check) && !is.null(spec)) {
    plot_report <- fig_check(plot, spec, column = column,
                             width = final_w, height = final_h, units = "mm",
                             dpi = dpi, format = ext,
                             colour_mode = if (isTRUE(cmyk_output)) "CMYK" else "RGB",
                             art_type = chosen_art_type)
    file_report <- fig_check(filename, spec, column = column,
                             dpi = dpi, art_type = chosen_art_type)
    report <- merge_figspec_reports(plot_report, file_report)
    problems <- report[report$status %in% c("fail", "invalid"), , drop = FALSE]
    open <- report[report$status == "unknown", , drop = FALSE]
    if (nrow(problems) > 0) {
      warning(
        "Saved figure does not meet ", nrow(problems), " requirement(s) of '",
        spec$name, "': ", paste(problems$check, collapse = ", "),
        ". Inspect attr(result, 'figspec_report') for detail.",
        call. = FALSE
      )
    } else if (nrow(open) > 0) {
      warning("Saved figure could not be certified against ", nrow(open),
              " recorded requirement(s) of '", spec$name, "': ",
              paste(open$check, collapse = ", "), ".", call. = FALSE)
    }
  }

  attr(filename, "figspec_geometry") <- structure(
    data.frame(
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
    ),
    class = c("figspec_geometry", "data.frame")
  )
  if (exists("report", inherits = FALSE)) attr(filename, "figspec_report") <- report
  invisible(filename)
}

merge_figspec_reports <- function(...) {
  reports <- list(...)
  all <- do.call(rbind, lapply(seq_along(reports), function(i) {
    x <- as.data.frame(reports[[i]])
    x$.source <- c("plot", "file")[pmin(i, 2L)]
    x
  }))
  priority <- c(invalid = 5L, fail = 4L, pass = 3L, unknown = 2L, unspecified = 1L)
  keep <- unlist(lapply(split(seq_len(nrow(all)), all$check), function(idx) {
    idx[which.max(unname(priority[all$status[idx]]))]
  }), use.names = FALSE)
  out <- all[sort(keep), c("check", "requirement", "actual", "status"), drop = FALSE]
  rownames(out) <- NULL
  template <- reports[[1]]
  structure(out,
            spec_name = attr(template, "spec_name"),
            spec_id = attr(template, "spec_id"),
            source_url = attr(template, "source_url"),
            verified_on = attr(template, "verified_on"),
            publication_stage = attr(template, "publication_stage"),
            input = "plot and saved file",
            class = c("figspec_report", "data.frame"))
}


# Formats R can actually write. A journal may accept Illustrator, Photoshop or
# PowerPoint files, and listing them first does not mean R can produce one, so
# a default has to be drawn from what a device exists for.
WRITABLE_FORMATS <- c("pdf", "eps", "ps", "svg", "tiff", "tif", "png", "jpeg", "jpg")

# The format to write when the caller did not name one.
#
# Takes the first format the specification lists that R can actually write. A
# specification that lists only formats R cannot produce is an error rather
# than a silent substitution, because writing a PDF when the journal asked for
# Illustrator would look like compliance.
#
# @param spec A specification list.
# @return A lower-case file extension.
default_format <- function(spec) {
  fmts <- tolower(unlist(spec$formats %||% list()))
  modes <- tolower(unlist(spec$colour_mode %||% list()))
  cmyk_only <- "cmyk" %in% modes &&
    !any(modes %in% c("rgb", "grayscale", "greyscale"))
  if (cmyk_only) {
    vector <- fmts[fmts %in% c("pdf", "eps", "ps")]
    vector <- vector[vapply(vector, function(x) format_supports_required_font(spec, x),
                            logical(1))]
    if (length(vector)) return(vector[[1]])
    figspec_abort(
      c("{spec$name} requires CMYK output, but no accepted format can write it reliably on this system.",
        ">" = "Use an accepted PDF, EPS, or PS device with an allowed font, or use a colour-managed prepress tool."),
      "unsupported", formats = fmts, colour_mode = modes
    )
  }
  writable <- intersect(fmts, WRITABLE_FORMATS)
  eligible <- writable[vapply(writable, function(x) format_supports_required_font(spec, x),
                              logical(1))]
  if (length(eligible)) return(eligible[[1]])
  if (length(writable) && !is.null(spec$font_families)) {
    figspec_abort(
      c("R can write {toupper(writable)}, but none can apply the font required by {spec$name} on this system.",
        "x" = "Required: {paste(unlist(spec$font_families), collapse = ' or ')}.",
        ">" = "Install an allowed font and a system-font graphics device such as ragg, or choose a format whose base device provides it."),
      "unsupported", formats = writable, font_families = spec$font_families
    )
  }
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

# Whether the device figspec would select can actually honour a named-font
# requirement. A format is not a usable default merely because R can create a
# file with that extension: silently substituting another face makes the
# resulting file non-compliant.
format_supports_required_font <- function(spec, ext) {
  families <- spec$font_families
  if (is.null(families) || !length(families)) return(TRUE)
  modes <- tolower(unlist(spec$colour_mode %||% list()))
  cmyk_only <- "cmyk" %in% modes &&
    !any(modes %in% c("rgb", "grayscale", "greyscale"))
  if (ext %in% c("pdf", "eps", "ps")) {
    if (cmyk_only || !cairo_ok()) return(nzchar(base_device_family(families, ext)))
    return(nzchar(resolve_family(families)))
  }
  if (ext %in% c("tiff", "tif", "png", "jpeg", "jpg")) {
    return(has_package("ragg") && nzchar(resolve_family(families)))
  }
  if (ext == "svg") {
    return(has_package("svglite") && nzchar(resolve_family(families)))
  }
  FALSE
}

# The graphics device to write a given extension with.
#
# Prefers ragg for raster output: it renders text more accurately and writes
# the pHYs resolution header that fig_check() reads back, which the base png()
# and tiff() devices do not. Every branch is conditional on an optional package
# or capability, so NULL is a normal answer meaning "use whatever ggsave would
# have chosen".
#
# @param ext Lower-case file extension.
# @return A device function, or NULL to leave the choice to ggsave().
select_device <- function(ext, colour_mode = NULL) {
  if (identical(colour_mode, "cmyk") && ext == "pdf") return(cmyk_pdf_device)
  if (identical(colour_mode, "cmyk") && ext %in% c("eps", "ps")) return(cmyk_ps_device)
  if (ext %in% c("tiff", "tif") && has_package("ragg")) {
    return(ragg::agg_tiff)
  }
  if (ext == "png" && has_package("ragg")) {
    return(ragg::agg_png)
  }
  if (ext %in% c("jpeg", "jpg") && has_package("ragg")) {
    return(ragg::agg_jpeg)
  }
  if (ext == "svg" && has_package("svglite")) {
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

cmyk_pdf_device <- function(filename, width, height, bg = "white", ...) {
  grDevices::pdf(file = filename, width = width, height = height, bg = bg,
                 colormodel = "cmyk", onefile = FALSE, ...)
}

cmyk_ps_device <- function(filename, width, height, bg = "white", ...) {
  grDevices::postscript(file = filename, width = width, height = height, bg = bg,
                        colormodel = "cmyk", onefile = FALSE,
                        horizontal = FALSE, paper = "special", ...)
}

base_device_family <- function(families, ext) {
  with_r_fontconfig({
    candidates <- as.character(unlist(families %||% list()))
    available <- if (ext == "pdf") {
      names(grDevices::pdfFonts())
    } else {
      names(grDevices::postscriptFonts())
    }
    hit <- candidates[tolower(candidates) %in% tolower(available)]
    if (!length(hit)) "" else available[match(tolower(hit[[1]]), tolower(available))]
  })
}

# ragg and several platform JPEG devices omit the JFIF density even when they
# render at a requested resolution. Preserve the pixels and add only the
# standard APP0 density header, so the physical size can be independently read
# back from the delivered file rather than trusted from the save call.
ensure_jpeg_density <- function(path, dpi) {
  density <- as.integer(round(dpi))
  if (!is.finite(density) || density < 1L || density > 65535L) return(invisible(FALSE))
  first <- readBin(path, "raw", 20L)
  if (length(first) < 2L || !identical(as.integer(first[1:2]), c(255L, 216L))) {
    return(invisible(FALSE))
  }
  bytes <- as.raw(c(1L, density %/% 256L, density %% 256L,
                    density %/% 256L, density %% 256L))
  jfif <- length(first) >= 20L &&
    identical(as.integer(first[3:6]), c(255L, 224L, 0L, 16L)) &&
    identical(rawToChar(first[7:10]), "JFIF") && as.integer(first[11]) == 0L
  if (jfif) {
    con <- file(path, "r+b")
    on.exit(close(con), add = TRUE)
    seek(con, where = 13L, origin = "start")
    writeBin(bytes, con)
    return(invisible(TRUE))
  }

  app0 <- as.raw(c(255L, 224L, 0L, 16L, charToRaw("JFIF"), 0L,
                   1L, 2L, as.integer(bytes), 0L, 0L))
  tmp <- tempfile(pattern = ".figspec-jfif-", tmpdir = dirname(path), fileext = ".jpg")
  input <- file(path, "rb")
  output <- file(tmp, "wb")
  on.exit({
    try(close(input), silent = TRUE)
    try(close(output), silent = TRUE)
    if (file.exists(tmp)) unlink(tmp)
  }, add = TRUE)
  writeBin(first[1:2], output)
  writeBin(app0, output)
  seek(input, where = 2L, origin = "start")
  repeat {
    chunk <- readBin(input, "raw", 1024L * 1024L)
    if (!length(chunk)) break
    writeBin(chunk, output)
  }
  close(input); close(output)
  if (!file.copy(tmp, path, overwrite = TRUE, copy.mode = TRUE)) {
    figspec_abort("Could not attach JPEG resolution metadata to {.file {path}}.", "bad_input")
  }
  invisible(TRUE)
}


# The font family a plot's theme actually asks for, or "" if it asks for none.
#
# @param plot A ggplot object.
# @return A single string, possibly empty.
theme_family_raw <- function(plot) {
  fam <- tryCatch(plot$theme$text$family, error = function(e) NULL)
  if (is.null(fam)) "" else fam
}

# The same, phrased for a warning message. A theme that names no family still
# needs something readable in "X cannot apply Y".
#
# @param plot A ggplot object.
# @return A single non-empty string.
theme_family <- function(plot) {
  fam <- theme_family_raw(plot)
  if (!nzchar(fam)) "the requested font" else fam
}

# Whether the device chosen for this extension can use a font installed on the
# system, as opposed to only the fonts R itself knows about.
#
# This decides whether a journal's named font can be honoured at all. When it
# is FALSE the font requirement cannot be met in that format, and fig_save()
# says so rather than writing a figure in the wrong face.
#
# @param ext Lower-case file extension.
# @return TRUE if system fonts will resolve.
device_resolves_system_fonts <- function(ext) {
  if (ext %in% c("png", "tiff", "tif", "jpeg", "jpg")) return(has_package("ragg"))
  if (ext == "svg") return(has_package("svglite"))
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
    devices_before <- grDevices::dev.list()
    current_before <- grDevices::dev.cur()
    ok <- tryCatch({
      with_r_fontconfig(withCallingHandlers({
        grDevices::cairo_pdf(tmp, width = 1, height = 1)
        opened_devices <- setdiff(
          if (is.null(grDevices::dev.list())) integer() else unname(grDevices::dev.list()),
          if (is.null(devices_before)) integer() else unname(devices_before)
        )
        if (length(opened_devices) != 1L) {
          figspec_abort(
            "The Cairo probe did not open exactly one graphics device.",
            "device_failed"
          )
        }
        grDevices::dev.off(which = opened_devices[[1]])
        file.exists(tmp) && file.size(tmp) > 0
      }, warning = function(w) invokeRestart("muffleWarning")))
    }, error = function(e) FALSE, finally = {
      # A failed device opening can leave its device active. Close only devices
      # created by this probe; closing every open device would destroy plots
      # belonging to the caller (and pkgdown's example-capture device).
      devices_after <- grDevices::dev.list()
      created <- setdiff(
        if (is.null(devices_after)) integer() else unname(devices_after),
        if (is.null(devices_before)) integer() else unname(devices_before)
      )
      for (device in rev(created)) {
        suppressWarnings(try(grDevices::dev.off(which = device), silent = TRUE))
      }
      remaining <- grDevices::dev.list()
      if (current_before > 1L &&
          !is.null(remaining) && current_before %in% unname(remaining)) {
        suppressWarnings(grDevices::dev.set(current_before))
      }
    })
    if (isTRUE(ok) && !file.exists(tmp)) ok <- FALSE
    unlink(tmp)
  }
  .figspec_cache$cairo_ok <- isTRUE(ok)
  .figspec_cache$cairo_ok
}
