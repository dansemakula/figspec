#' Save a figure at a journal's required size and resolution
#'
#' Works like [ggplot2::ggsave()], but takes the width from the journal's
#' stated column width and the resolution from its stated minimum, so the
#' saved file is the size the journal asks for rather than a size that will be
#' rescaled later. Rescaling is what silently pushes type below the minimum.
#'
#' @param filename Output path. The extension selects the format. If it has no
#'   extension, the journal's first accepted format is used.
#' @param plot Plot to save. Defaults to the last plot displayed.
#' @param journal Registry id, for example `"cell_press"`.
#' @param column Which column width to size to.
#' @param height Height. Defaults to three quarters of the width, which is a
#'   convenience, not a journal requirement.
#' @param units Units for `height`.
#' @param dpi Resolution. Defaults to the journal's stated minimum, or 300
#'   when it states none.
#' @param check Whether to check the result and report failures as a warning.
#' @param ... Passed to [ggplot2::ggsave()].
#' @return The path to the written file, invisibly.
#' @examples
#' library(ggplot2)
#' p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + theme_journal("frontiers")
#' out <- file.path(tempdir(), "figure_1.tiff")
#' ggsave_journal(out, p, "frontiers")
#' unlink(out)
#' @export
ggsave_journal <- function(filename, plot = ggplot2::last_plot(), journal,
                           column = "single",
                           height = NULL, units = c("mm", "cm", "in"),
                           dpi = NULL, check = TRUE, ...) {
  units <- match.arg(units)
  spec <- journal_spec(journal)

  width_mm <- fig_width(journal, column, "mm")

  ext <- tolower(tools::file_ext(filename))
  if (!nzchar(ext)) {
    ext <- default_format(spec)
    filename <- paste0(filename, ".", ext)
  }
  if (!is.null(spec$formats) && !ext %in% tolower(unlist(spec$formats))) {
    warning(
      "'", spec$name, "' does not list ", toupper(ext),
      " among its accepted formats (", paste(toupper(unlist(spec$formats)), collapse = ", "),
      ").", call. = FALSE
    )
  }

  if (is.null(dpi)) {
    dpi <- if (is.null(spec$dpi_min)) {
      default_note(spec, "dpi_min", "300 dpi", "a minimum resolution")
      300
    } else {
      as.numeric(spec$dpi_min)
    }
  }
  height_mm <- if (is.null(height)) width_mm * 0.75 else convert_length(height, units, "mm")
  if (!is.null(spec$height_max_mm) && height_mm > as.numeric(spec$height_max_mm)) {
    warning(
      "Height of ", fmt_num(height_mm), " mm exceeds the ",
      spec$height_max_mm, " mm maximum stated by '", spec$name, "'.",
      call. = FALSE
    )
  }

  device <- select_device(ext)

  # Only ragg and svglite resolve system font families reliably. Applying the
  # journal's font on a device that cannot find it does not degrade the
  # figure, it stops it rendering, so apply the font only where it will work
  # and say so plainly where it will not.
  if (!is.null(spec$font_families) && !nzchar(theme_family_raw(plot))) {
    fam <- resolve_family(spec$font_families)
    if (device_resolves_system_fonts(ext) && nzchar(fam)) {
      plot <- plot + ggplot2::theme(text = ggplot2::element_text(family = fam))
    } else {
      warning(
        "'", spec$name, "' asks for ", paste(unlist(spec$font_families), collapse = " or "),
        ", which this ", toupper(ext), " device cannot apply",
        if (!nzchar(fam)) " and which is not installed on this system" else "",
        ". The figure was saved in the default font. Save as TIFF or PNG, ",
        "which figspec renders with ragg, to meet the font requirement.",
        call. = FALSE
      )
    }
  }

  args <- list(
    filename = filename, plot = plot,
    width = width_mm, height = height_mm, units = "mm", dpi = dpi, ...
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
  saved <- tryCatch(quiet_font(do.call(ggplot2::ggsave, args)), error = function(e) e)
  if (inherits(saved, "error")) {
    if (grepl("invalid font type|font family|font database", conditionMessage(saved))) {
      # Vector devices on some systems cannot use a system-installed font.
      # Produce the file rather than failing, but be explicit that the font
      # requirement is now unmet: a silent default font is how a figure comes
      # back from production in the wrong typeface.
      warning(
        "The ", toupper(ext), " device on this system cannot render the font '",
        theme_family(plot), "' that '", spec$name, "' requires, so the figure ",
        "was saved in the default font and does NOT meet the font requirement. ",
        "Save as TIFF or PNG instead, which figspec renders with ragg, or ",
        "install the font for this device.",
        call. = FALSE
      )
      args$plot <- plot + ggplot2::theme(text = ggplot2::element_text(family = ""))
      quiet_font(do.call(ggplot2::ggsave, args))
    } else {
      stop(saved)
    }
  }

  if (!file.exists(filename) || file.size(filename) == 0) {
    stop(
      "The ", toupper(ext), " device did not write a usable file. ",
      "Try a different format, for example TIFF or PNG.",
      call. = FALSE
    )
  }

  if (isTRUE(check)) {
    report <- check_journal(filename, journal, column)
    fails <- report[report$status == "fail", , drop = FALSE]
    if (nrow(fails) > 0) {
      warning(
        "Saved figure does not meet ", nrow(fails), " requirement(s) of '",
        spec$name, "': ", paste(fails$check, collapse = ", "),
        ". Run check_journal() on the file for detail.",
        call. = FALSE
      )
    }
  }
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
    stop(
      "'", spec$name, "' lists ", paste(toupper(fmts), collapse = ", "),
      ", none of which R can write. Give an explicit file extension, or export ",
      "one of those formats from another program.",
      call. = FALSE
    )
  }
  default_note(spec, "formats", "PDF", "which file formats it accepts")
  "pdf"
}

# Prefer ragg for raster output: it renders text more accurately and writes
# the pHYs resolution header that check_journal() reads back.
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
