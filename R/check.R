# Checking a figure against a specification --------------------------------
#
# fig_check() answers one question per requirement, and it can be handed two
# very different things to answer it about:
#
#   a ggplot object  still has its typography and its colour mapping, so type
#                    size, fonts and colour safety are all answerable. It has
#                    no file, so resolution, format and file size are not.
#   a saved file     has geometry, resolution, format and size. Its colour
#                    mapping is gone, and its type sizes survive only in a
#                    vector format (see R/vector-text.R).
#
# Neither input answers everything, which is why a requirement that cannot be
# assessed is reported rather than skipped.
#
# Every row of a report is one of four outcomes, and keeping them apart is the
# point of the whole file:
#
#   pass / fail   the specification states the rule and the figure was measured
#   unspecified   nothing states the rule, so there is nothing to meet
#   unknown       the rule exists, but this input cannot answer it
#
# new_row() enforces that, so a pass can never be reported against a rule
# nobody stated. Its four wordings are defined under "Report assembly" below.

# Text size introspection ------------------------------------------------

# Walk a built plot and collect the point size of every text grob. Type size
# in a ggplot is absolute: an 8 pt axis label is 8 pt whatever device size the
# plot is drawn at. That is what makes this check meaningful before saving.
collect_text_sizes <- function(plot) {
  # Measuring a plot opens a null device. When a journal font is registered
  # with the system but not with R's PostScript font database, that device
  # emits one warning per text grob. Those warnings say nothing about type
  # size, which is what we are here to measure, so muffle just those and let
  # every other warning through.
  gt <- withCallingHandlers(
    ggplot2::ggplotGrob(plot),
    warning = function(w) {
      if (grepl("not found in (PostScript|Type 1) font database",
                conditionMessage(w))) {
        invokeRestart("muffleWarning")
      }
    }
  )
  found <- list()
  visit <- function(g) {
    if (is.null(g)) return(invisible(NULL))
    size <- g$gp$fontsize
    if (!is.null(size) && is.numeric(size) && length(size) >= 1L) {
      is_text <- inherits(g, "text") || inherits(g, "titleGrob") ||
        inherits(g, "titleGrob2") || grepl("text|title|label|caption|tag",
                                           g$name %||% "", ignore.case = TRUE)
      if (is_text) {
        found[[length(found) + 1L]] <<- data.frame(
          grob = g$name %||% class(g)[[1]],
          size_pt = min(as.numeric(size)),
          stringsAsFactors = FALSE
        )
      }
    }
    kids <- if (!is.null(g$grobs)) g$grobs else g$children
    for (k in kids) visit(k)
    invisible(NULL)
  }
  visit(gt)
  if (!length(found)) {
    return(data.frame(grob = character(0), size_pt = numeric(0),
                      stringsAsFactors = FALSE))
  }
  out <- do.call(rbind, found)
  out[is.finite(out$size_pt) & out$size_pt > 0, , drop = FALSE]
}

# File inspection --------------------------------------------------------
#
# Geometry and resolution are read out of the image files themselves, byte by
# byte, rather than through an imaging package. figspec is a checking tool, so
# a user should not have to install a reader for every format they might submit
# just to be told how wide their figure is; each of these needs only the header,
# which is a few dozen bytes at the front of the file.
#
# Each reader returns a named list of whatever it could establish, or NULL if
# the file is not what its extension claims. Absent fields are simply absent:
# nothing is guessed, because an invented resolution would be reported to the
# user as a measurement.

# Width, height and resolution from a PNG header.
#
# A PNG is a signature followed by typed chunks, each one a length, a
# four-letter type, its data and a checksum. Only two chunks matter here: IHDR,
# which is always first and carries the pixel dimensions, and pHYs, which is
# optional and carries the physical resolution. pHYs stores pixels per unit
# with a trailing byte naming the unit, and the only defined unit is 1, the
# metre - hence the conversion to inches.
#
# @param path Path to the file.
# @return List of `width_px`, `height_px` and `dpi` where present, or NULL if
#   the signature does not match.
read_png_info <- function(path) {
  con <- file(path, "rb")
  on.exit(close(con), add = TRUE)
  sig <- as.integer(readBin(con, "raw", 8L))
  if (!identical(sig, c(137L, 80L, 78L, 71L, 13L, 10L, 26L, 10L))) return(NULL)
  be <- function(r) sum(as.integer(r) * c(16777216, 65536, 256, 1))
  info <- list()
  repeat {
    len_raw <- readBin(con, "raw", 4L)
    if (length(len_raw) < 4L) break
    len <- be(len_raw)
    type <- rawToChar(readBin(con, "raw", 4L))
    data <- readBin(con, "raw", len)
    readBin(con, "raw", 4L)
    if (type == "IHDR" && length(data) >= 8L) {
      info$width_px <- be(data[1:4])
      info$height_px <- be(data[5:8])
    } else if (type == "pHYs" && length(data) >= 9L) {
      if (as.integer(data[9]) == 1L) info$dpi <- be(data[1:4]) * 0.0254
    } else if (type == "IEND") {
      break
    }
  }
  info
}

# Page size from a PDF.
#
# A PDF has no resolution: it is drawn from instructions, not pixels, so the
# only geometry to recover is the page box. /MediaBox gives it as four numbers,
# the left, bottom, right and top edges in user-space units, which default to
# 1/72 inch. Null bytes are replaced with spaces before the search so that the
# binary streams in the file cannot terminate the text early.
#
# @param path Path to the file.
# @return List of `width_mm`, `height_mm` and `vector = TRUE`, or NULL if no
#   /MediaBox was found.
read_pdf_info <- function(path) {
  n <- file.size(path)
  raw <- readBin(path, "raw", n)
  raw[raw == as.raw(0L)] <- as.raw(32L)
  txt <- rawToChar(raw)
  m <- regexpr(
    "/MediaBox[[:space:]]*\\[[[:space:]]*[-0-9.]+[[:space:]]+[-0-9.]+[[:space:]]+[-0-9.]+[[:space:]]+[-0-9.]+[[:space:]]*\\]",
    txt, useBytes = TRUE
  )
  if (m == -1L) return(NULL)
  box <- regmatches(txt, m)
  nums <- as.numeric(regmatches(box, gregexpr("[-0-9.]+", box))[[1]])
  if (length(nums) < 4L) return(NULL)
  # PDF user space units are 1/72 inch.
  list(
    width_mm = (nums[3] - nums[1]) / 72 * MM_PER_IN,
    height_mm = (nums[4] - nums[2]) / 72 * MM_PER_IN,
    vector = TRUE
  )
}


# Dimensions, resolution and colour mode from a TIFF header.
#
# TIFF is the most involved of these formats and the most important to read,
# because it is what most publishers ask for. The file opens with a byte-order
# mark, "II" for little-endian or "MM" for big, then the magic number 42, then
# the offset of an image file directory. That directory is a count followed by
# 12-byte entries, each a tag, a type, and either a value or an offset to one.
#
# The tags read here:
#
#   256  image width in pixels          282  horizontal resolution
#   257  image height in pixels         296  unit that resolution is in
#   262  photometric interpretation, which is what tells us whether the file
#        is greyscale, RGB or CMYK - and CMYK matters, because journals that
#        print in colour state which of the two they accept
#
# Resolution unit 3 is centimetres and 2 is inches; 2 is assumed when the tag
# is absent, which is what the specification requires.
#
# @param path Path to the file.
# @return List of `width_px`, `height_px`, `dpi` and `colour_mode`, omitting
#   any that could not be read, or NULL if the file is not a TIFF.
read_tiff_info <- function(path) {
  con <- file(path, "rb")
  on.exit(close(con), add = TRUE)
  hdr <- readBin(con, "raw", 8L)
  if (length(hdr) < 8L) return(NULL)
  bo <- rawToChar(hdr[1:2])
  endian <- if (bo == "II") "little" else if (bo == "MM") "big" else return(NULL)

  rd <- function(offset, size) {
    seek(con, offset)
    bytes <- readBin(con, "raw", size)
    if (length(bytes) < size) return(NA_real_)
    if (endian == "big") bytes <- rev(bytes)
    sum(as.numeric(bytes) * 256^(seq_along(bytes) - 1L))
  }
  if (rd(2L, 2L) != 42) return(NULL)
  # The image file directory can sit anywhere, commonly after the pixel data,
  # so seek to it rather than assuming it is near the start of the file.
  ifd <- rd(4L, 4L)
  if (is.na(ifd)) return(NULL)
  count <- rd(ifd, 2L)
  if (is.na(count) || count < 1 || count > 4096) return(NULL)

  vals <- list()
  for (i in seq_len(count)) {
    e <- ifd + 2 + (i - 1) * 12
    tag <- rd(e, 2L)
    type <- rd(e + 2, 2L)
    if (is.na(tag) || is.na(type)) break
    value <- if (type == 3) {
      rd(e + 8, 2L)
    } else if (type == 4) {
      rd(e + 8, 4L)
    } else if (type == 5) {
      off <- rd(e + 8, 4L)
      den <- rd(off + 4, 4L)
      if (is.na(den) || den == 0) NA_real_ else rd(off, 4L) / den
    } else {
      NA_real_
    }
    vals[[as.character(tag)]] <- value
  }

  photometric <- vals[["262"]]
  xres <- vals[["282"]]
  unit <- vals[["296"]]
  if (is.null(unit) || is.na(unit)) unit <- 2
  dpi <- if (is.null(xres) || is.na(xres)) NULL else if (unit == 3) xres * 2.54 else xres
  colour_mode <- if (is.null(photometric) || is.na(photometric)) NULL else {
    switch(as.character(photometric), "0" = "grayscale", "1" = "grayscale",
           "2" = "RGB", "5" = "CMYK", NULL)
  }
  out <- list(width_px = vals[["256"]], height_px = vals[["257"]], dpi = dpi,
              colour_mode = colour_mode)
  out[!vapply(out, function(v) is.null(v) || (length(v) == 1L && is.na(v)), logical(1))]
}

# Dimensions and resolution from a JPEG header.
#
# A JPEG is a chain of segments, each introduced by 0xFF and a marker byte.
# This walks that chain looking for two things: APP0 (0xE0), the JFIF header,
# which carries pixel density and a unit byte where 1 is per-inch and 2 is
# per-centimetre; and any start-of-frame marker, which carries the dimensions
# and ends the walk. The start-of-frame markers are 0xC0-0xC3, 0xC5-0xC7,
# 0xC9-0xCB and 0xCD-0xCF - the gaps are other markers that share the range.
#
# Only the first megabyte is read, which is far past any header, so a large
# photograph is not loaded into memory to be measured.
#
# @param path Path to the file.
# @return List of `width_px`, `height_px` and `dpi` where present, or NULL if
#   the file does not start with a JPEG marker.
read_jpeg_info <- function(path) {
  n <- file.size(path)
  raw <- readBin(path, "raw", min(n, 1048576L))
  if (length(raw) < 4L || !identical(as.integer(raw[1:2]), c(255L, 216L))) return(NULL)
  be <- function(i) as.integer(raw[i]) * 256L + as.integer(raw[i + 1L])
  i <- 3L
  info <- list()
  while (i < length(raw) - 3L) {
    if (as.integer(raw[i]) != 255L) { i <- i + 1L; next }
    marker <- as.integer(raw[i + 1L])
    if (marker %in% c(216L, 217L)) { i <- i + 2L; next }
    len <- be(i + 2L)
    if (marker == 224L && i + 13L <= length(raw)) {
      # JFIF: identifier and version, then a units byte at offset 11 and the
      # horizontal density at 12. Units 1 and 2 are per-inch and
      # per-centimetre. Units 0 means the two density numbers express an
      # aspect ratio and carry no physical size at all, so there is no
      # resolution to report - R's own jpeg() device writes exactly that.
      unit <- as.integer(raw[i + 11L])
      xd <- be(i + 12L)
      if (xd > 0 && unit %in% c(1L, 2L)) {
        info$dpi <- if (unit == 2L) xd * 2.54 else xd
      }
    }
    if (marker %in% c(192L:195L, 197L:199L, 201L:203L, 205L:207L)) {
      # Start of frame: length, then one byte of sample precision, then the
      # height and the width, in that order.
      info$height_px <- be(i + 5L)
      info$width_px <- be(i + 7L)
      break
    }
    i <- i + 2L + len
  }
  info
}

# Everything that can be established about a figure file without rendering it.
#
# Dispatches on the file extension to the reader for that format, then converts
# pixels to millimetres wherever both a pixel size and a resolution were found.
# A format with no reader still yields its extension and size on disk, and
# vector formats are flagged so that resolution is reported as inapplicable
# rather than missing.
#
# @param path Path to the file.
# @return A list carrying `format` and `size_mb` always, and whichever of
#   `width_px`, `height_px`, `width_mm`, `height_mm`, `dpi`, `colour_mode` and
#   `vector` the format could supply.
inspect_file <- function(path) {
  ext <- tolower(tools::file_ext(path))
  info <- list(format = ext, size_mb = file.size(path) / 1024^2)
  if (ext == "png") {
    png <- read_png_info(path)
    if (!is.null(png)) {
      info$colour_mode <- "RGB"
      info$width_px <- png$width_px
      info$height_px <- png$height_px
      info$dpi <- png$dpi
      if (!is.null(png$dpi) && !is.null(png$width_px)) {
        info$width_mm <- png$width_px / png$dpi * MM_PER_IN
        info$height_mm <- png$height_px / png$dpi * MM_PER_IN
      }
    }
  } else if (ext == "pdf") {
    pdf <- read_pdf_info(path)
    if (!is.null(pdf)) {
      info$width_mm <- pdf$width_mm
      info$height_mm <- pdf$height_mm
      info$vector <- TRUE
    }
  } else if (ext %in% c("tiff", "tif")) {
    tif <- read_tiff_info(path)
    if (!is.null(tif)) {
      info$width_px <- tif$width_px
      info$height_px <- tif$height_px
      info$dpi <- tif$dpi
      info$colour_mode <- tif$colour_mode
      if (!is.null(tif$dpi) && !is.null(tif$width_px)) {
        info$width_mm <- tif$width_px / tif$dpi * MM_PER_IN
        info$height_mm <- tif$height_px / tif$dpi * MM_PER_IN
      }
    }
  } else if (ext %in% c("jpeg", "jpg")) {
    jpg <- read_jpeg_info(path)
    if (!is.null(jpg)) {
      info$width_px <- jpg$width_px
      info$height_px <- jpg$height_px
      info$dpi <- jpg$dpi
      if (!is.null(jpg$dpi) && !is.null(jpg$width_px)) {
        info$width_mm <- jpg$width_px / jpg$dpi * MM_PER_IN
        info$height_mm <- jpg$height_px / jpg$dpi * MM_PER_IN
      }
    }
  } else if (ext %in% c("eps", "ps", "svg")) {
    info$vector <- TRUE
  }
  info
}

# Report assembly --------------------------------------------------------

UNSTATED <- "not specified by publisher"
UNHARVESTED <- "not yet harvested for this journal"
# A third case, distinct from both. "Not specified by publisher" is a fact
# about a publisher and "not yet harvested" is a fact about the registry;
# neither is true when the caller simply did not give a specification. Saying
# either would put a claim in figspec's mouth that nobody made.
NO_SPEC <- "no specification given"
# And a fourth. A specification written by the user, rather than read off a
# publisher's page, cannot be "awaiting harvest": there is no page to read. A
# field it does not mention is simply one the author did not state.
UNSTATED_USER <- "not specified"

new_row <- function(check, requirement, actual, status) {
  # A publisher that states no requirement cannot be passed or failed. Rather
  # than trust every call site to remember that, enforce it here: an unstated
  # requirement is always reported as unspecified, whatever verdict was
  # computed. Reporting a pass against a rule that does not exist is the same
  # error as inventing the rule.
  if (identical(requirement, UNSTATED) && status %in% c("pass", "fail")) {
    status <- "unspecified"
  }
  if (identical(requirement, UNHARVESTED) && status %in% c("pass", "fail")) {
    status <- "unknown"
  }
  data.frame(
    check = check, requirement = requirement, actual = actual,
    status = status, stringsAsFactors = FALSE
  )
}

# A blank requirement means one of two different things, and conflating them
# puts a claim in figspec's mouth that nobody earned. If the entry records the
# field in `not_stated`, somebody read the publisher's page and confirmed the
# rule is absent. If it does not, nobody has looked yet. The first is a fact
# about the publisher; the second is a fact about the registry.
graded <- function(check, requirement, actual, ok, spec = NULL, fields = NULL) {
  if (is.null(requirement) || is.na(requirement) || !nzchar(requirement)) {
    confirmed <- !is.null(spec) && !is.null(fields) &&
      length(fields) > 0 && all(fields %in% unlist(spec$not_stated %||% list()))
    if (confirmed) {
      return(new_row(check, UNSTATED, actual %||% "-", "unspecified"))
    }
    return(new_row(check, UNHARVESTED, actual %||% "-", "unknown"))
  }
  if (is.null(actual) || is.na(actual) || !nzchar(actual)) {
    return(new_row(check, requirement, "could not determine", "unknown"))
  }
  new_row(check, requirement, actual, if (isTRUE(ok)) "pass" else "fail")
}

#' Check a figure against a journal's requirements
#'
#' Accepts either a ggplot object, checked before it is saved, or the path to
#' a figure file that has already been written.
#'
#' Each requirement is reported with one of four outcomes. `pass` and `fail`
#' mean what they say. `unspecified` means the publisher does not state that
#' requirement, so nothing can be concluded. `unknown` means the requirement
#' exists but this input cannot answer it, for example type size in a raster
#' file. Only `fail` is a problem you must fix; `unspecified` and `unknown`
#' are prompts to check by hand.
#'
#' Type size is read back from PDF, EPS and SVG files, which record the size
#' each string was set at. This is worth doing rather than trusting the plot
#' object, because R's `pdf()` and `postscript()` devices round text to whole
#' points: a theme asking for 8.8 pt writes 9 pt into the file, and one asking
#' for 5.2 pt writes 5. The file is what a publisher receives. Reading a PDF
#' needs the pdftools package. A raster carries no type sizes at all, and is
#' reported as `unknown` rather than estimated.
#'
#' @param x A ggplot object, or a path to a figure file.
#' @param journal Registry id, for example `"frontiers"`.
#' @param column Which column width the figure is intended for. One of
#'   `"single"`, `"onehalf"` or `"double"`.
#' @param width,height Intended output size. Defaults to the journal's width
#'   for `column`. Ignored when `x` is a file, whose real size is measured.
#' @param units Units for `width` and `height`.
#' @param dpi Resolution. For a ggplot object, the resolution you intend to
#'   save at. For a file, the resolution it was written at, which lets figspec
#'   judge physical size for files that do not record it themselves - base R's
#'   `png()` and `tiff()` devices do not, whereas ragg does.
#' @param format Output format, for example `"tiff"`. Only used when `x` is a
#'   ggplot object.
#' @param art_type Which resolution rule applies. Publishers set different
#'   minimums for different kinds of artwork: Cell Press asks 300 dpi for
#'   colour or greyscale, 500 for black and white, and 1000 for line art.
#'   figspec cannot tell which one your figure is, so it checks against
#'   `"colour"` by default and names the other thresholds in the report rather
#'   than quietly applying the most lenient one. `"color"` is accepted too.
#' @return An object of class `figspec_report`, a data frame of one row per
#'   requirement.
#' @examples
#' library(ggplot2)
#' p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
#' fig_check(p, "frontiers")
#' @export
fig_check <- function(x, journal = NULL, column = "single",
                          width = NULL, height = NULL,
                          units = c("mm", "cm", "in"),
                          dpi = NULL, format = NULL,
                          art_type = c("colour", "bw", "line", "combination")) {
  art_type_given <- !missing(art_type)
  units <- match.arg(units)
  # match.arg() reads its choices from the formal, so it needs a bare symbol;
  # the spelling is normalised into the variable before the call rather than
  # wrapped around it.
  art_type <- british_spelling(art_type)
  art_type <- match.arg(art_type)
  # With no specification there is nothing to judge against, so the report
  # becomes an inspection: it says what the figure is and states plainly that
  # no requirement was supplied. An empty spec produces exactly that, because
  # every check already refuses to pass or fail an unstated requirement.
  # A figure sized by fig_panel_size() is a gtable carrying its source plot.
  # Check the plot, so nothing is lost by having set a panel size.
  if (inherits(x, "gtable")) {
    src <- attr(x, "figspec_plot")
    if (is.null(src)) {
      figspec_abort(
        c("This gtable does not carry the plot it was built from.",
          "i" = "Laying a plot out discards its theme, layers and scales, so
                 type size, font and colour cannot be read back.",
          ">" = "Pass the plot itself, or a figure built with
                 {.fn fig_panel_size}, which keeps it."),
        "bad_input")
    }
    x <- src
  }
  no_spec <- is.null(journal)
  from_registry <- !no_spec && is.character(journal) && length(journal) == 1L
  spec <- if (no_spec) {
    structure(list(name = "no specification"), class = c("figspec_spec", "list"))
  } else {
    journal_spec(journal)
  }
  rows <- list()
  info <- list()

  is_file <- is.character(x) && length(x) == 1L
  if (is_file) {
    if (!file.exists(x)) figspec_abort("File not found: {.file {x}}.", "not_found", path = x)
    info <- inspect_file(x)
    actual_w <- info$width_mm
    actual_h <- info$height_mm
    actual_dpi <- info$dpi %||% dpi
    if (is.null(info$dpi) && !is.null(dpi) && !is.null(info$width_px)) {
      actual_w <- info$width_px / dpi * MM_PER_IN
      actual_h <- if (is.null(info$height_px)) NULL else info$height_px / dpi * MM_PER_IN
    }
    actual_format <- info$format
    actual_size <- info$size_mb
    px_note <- if (is.null(actual_w) && !is.null(info$width_px)) {
      paste0(info$width_px, " px, resolution not recorded in file")
    } else NULL
    # A vector file still records the size each string was set at, so type
    # size is answerable here even though a raster's text is only pixels.
    text_sizes <- vector_text_sizes(x, actual_format)
  } else if (is_ggplot_object(x)) {
    if (is.null(width)) {
      width <- tryCatch(fig_width(journal, column, "mm"), error = function(e) NULL)
    } else {
      width <- convert_length(width, units, "mm")
    }
    actual_w <- width
    actual_h <- if (is.null(height)) NULL else convert_length(height, units, "mm")
    actual_dpi <- dpi
    actual_format <- if (is.null(format)) NULL else tolower(format)
    actual_size <- NULL
    px_note <- NULL
    text_sizes <- collect_text_sizes(x)
  } else {
    figspec_abort(
      c("{.arg x} must be a ggplot object or a path to a figure file.",
        "x" = "You gave {.cls {class(x)}}."),
      "bad_input")
  }

  # Width -----------------------------------------------------------------
  if (!is.null(spec$columns)) {
    allowed <- unlist(spec$columns)
    req <- paste0(paste0(names(allowed), " ", allowed, " mm", collapse = " | "))
    ok <- !is.null(actual_w) && any(abs(actual_w - allowed) <= 0.5)
  } else if (!is.null(spec$width_min_mm) || !is.null(spec$width_max_mm)) {
    lo <- spec$width_min_mm %||% -Inf
    hi <- spec$width_max_mm %||% Inf
    req <- paste0(
      if (is.finite(lo)) paste0("min ", lo, " mm") else NULL,
      if (is.finite(lo) && is.finite(hi)) ", " else NULL,
      if (is.finite(hi)) paste0("max ", hi, " mm") else NULL
    )
    ok <- !is.null(actual_w) && actual_w >= lo - 0.5 && actual_w <= hi + 0.5
  } else {
    req <- NULL
    ok <- NA
  }
  rows[[length(rows) + 1L]] <- if (is.null(actual_w) && !is.null(px_note)) {
    # Pixel count is known but physical size is not, so the requirement cannot
    # be judged. Reporting that as a failure would be a false alarm.
    new_row("Width", req %||% UNSTATED, px_note,
            if (is.null(req)) "unspecified" else "unknown")
  } else {
    graded("Width", req,
           if (!is.null(actual_w)) paste0(fmt_num(actual_w), " mm") else NULL, ok)
  }

  # Height ----------------------------------------------------------------
  rows[[length(rows) + 1L]] <- graded(
    "Height",
    if (!is.null(spec$height_max_mm)) paste0("max ", spec$height_max_mm, " mm") else NULL,
    if (!is.null(actual_h)) paste0(fmt_num(actual_h), " mm") else NULL,
    !is.null(actual_h) && !is.null(spec$height_max_mm) &&
      actual_h <= as.numeric(spec$height_max_mm) + 0.5,
    spec, "height_max_mm"
  )

  # Resolution ------------------------------------------------------------
  is_vector_fmt <- isTRUE(info$vector) ||
    (!is.null(actual_format) && actual_format %in% c("pdf", "eps", "ps", "svg"))
  if (is_file && isTRUE(is_vector_fmt)) {
    rows[[length(rows) + 1L]] <- new_row(
      "Resolution",
      if (!is.null(spec$dpi_min)) paste0("min ", spec$dpi_min, " dpi") else UNSTATED,
      "vector format, resolution independent",
      if (!is.null(spec$dpi_min)) "pass" else "unspecified"
    )
  } else {
    required_dpi <- switch(art_type,
      colour = spec$dpi_min,
      bw = spec$dpi_bw %||% spec$dpi_min,
      line = spec$dpi_line_art %||% spec$dpi_min,
      combination = spec$dpi_combination %||% spec$dpi_min
    )
    # Name every threshold the publisher states. A figure judged as colour art
    # must not look compliant when it is really line art held to a higher bar.
    others <- c(
      if (!is.null(spec$dpi_bw) && art_type != "bw") paste0("black and white ", spec$dpi_bw),
      if (!is.null(spec$dpi_line_art) && art_type != "line") paste0("line art ", spec$dpi_line_art),
      if (!is.null(spec$dpi_combination) && art_type != "combination") paste0("combination ", spec$dpi_combination)
    )
    # Where the caller did not choose an art type, figspec checks against the
    # general minimum. Most statistical plots are line art in the sense
    # publishers mean, and several hold line art to three or four times the
    # general minimum, so say so rather than let a lenient default pass
    # silently. The verdict is not changed: the choice stays the caller's.
    line_art_warning <- NULL
    if (!art_type_given && !is_file && !is.null(spec$dpi_line_art) &&
        !is.null(required_dpi) &&
        as.numeric(spec$dpi_line_art) > as.numeric(required_dpi) &&
        identical(classify_tone(x), "bitonal")) {
      line_art_warning <- paste0(
        "; this plot is pure black and white, which this journal holds to ",
        spec$dpi_line_art, " dpi - see suggest_art_type()"
      )
    }
    req_dpi_txt <- if (is.null(required_dpi)) NULL else {
      paste0("min ", required_dpi, " dpi for ", art_type,
             if (length(others)) paste0("; also states ", paste(others, collapse = ", "), " dpi") else "",
             line_art_warning %||% "")
    }
    rows[[length(rows) + 1L]] <- graded(
      "Resolution", req_dpi_txt,
      if (!is.null(actual_dpi)) paste0(fmt_num(actual_dpi, 0), " dpi") else NULL,
      !is.null(actual_dpi) && !is.null(required_dpi) &&
        actual_dpi >= as.numeric(required_dpi),
      spec, "dpi_min"
    )
  }

  # File format -----------------------------------------------------------
  rows[[length(rows) + 1L]] <- graded(
    "File format",
    if (!is.null(spec$formats)) paste(toupper(unlist(spec$formats)), collapse = ", ") else NULL,
    if (!is.null(actual_format)) toupper(actual_format) else NULL,
    !is.null(actual_format) && !is.null(spec$formats) &&
      tolower(actual_format) %in% tolower(unlist(spec$formats)),
    spec, "formats"
  )

  # Type size -------------------------------------------------------------
  if (!is.null(text_sizes) && nrow(text_sizes) > 0) {
    smallest <- min(text_sizes$size_pt)
    largest <- max(text_sizes$size_pt)
    req_txt <- if (!is.null(spec$font_min_pt)) {
      paste0("min ", spec$font_min_pt, " pt",
             if (!is.null(spec$font_max_pt)) paste0(", max ", spec$font_max_pt, " pt"))
    } else NULL
    ok_txt <- !is.null(spec$font_min_pt) &&
      smallest >= as.numeric(spec$font_min_pt) - 1e-6 &&
      (is.null(spec$font_max_pt) || largest <= as.numeric(spec$font_max_pt) + 1e-6)
    rows[[length(rows) + 1L]] <- graded(
      "Type size", req_txt,
      paste0("smallest ", fmt_num(smallest), " pt, largest ", fmt_num(largest), " pt"),
      ok_txt, spec, "font_min_pt"
    )
  } else {
    rows[[length(rows) + 1L]] <- graded(
      "Type size",
      if (!is.null(spec$font_min_pt)) paste0("min ", spec$font_min_pt, " pt") else NULL,
      NULL, NA, spec, "font_min_pt"
    )
  }

  # Font family -----------------------------------------------------------
  actual_family <- if (!is_file) {
    f <- tryCatch(x$theme$text$family, error = function(e) NULL)
    if (is.null(f) || !nzchar(f)) NULL else f
  } else NULL
  rows[[length(rows) + 1L]] <- graded(
    "Font",
    if (!is.null(spec$font_families)) paste(unlist(spec$font_families), collapse = ", ") else NULL,
    actual_family,
    !is.null(actual_family) && !is.null(spec$font_families) &&
      tolower(actual_family) %in% tolower(unlist(spec$font_families)),
    spec, "font_families"
  )

  # Line width ------------------------------------------------------------
  line_pts <- if (!is_file) plot_linewidths(x) else numeric(0)
  lw_req <- if (!is.null(spec$min_line_pt) || !is.null(spec$max_line_pt)) {
    paste0(
      if (!is.null(spec$min_line_pt)) paste0("min ", spec$min_line_pt, " pt") else NULL,
      if (!is.null(spec$min_line_pt) && !is.null(spec$max_line_pt)) ", " else NULL,
      if (!is.null(spec$max_line_pt)) paste0("max ", spec$max_line_pt, " pt") else NULL
    )
  } else NULL
  rows[[length(rows) + 1L]] <- if (!length(line_pts)) {
    graded("Line width", lw_req, NULL, NA, spec, "min_line_pt")
  } else {
    ok_lw <- (is.null(spec$min_line_pt) || min(line_pts) >= as.numeric(spec$min_line_pt) - 1e-6) &&
      (is.null(spec$max_line_pt) || max(line_pts) <= as.numeric(spec$max_line_pt) + 1e-6)
    graded("Line width", lw_req,
           paste0(fmt_num(min(line_pts), 2), " to ", fmt_num(max(line_pts), 2), " pt"),
           ok_lw, spec, "min_line_pt")
  }

  # Point outline ---------------------------------------------------------
  shp <- if (!is_file) plot_shapes(x) else NULL
  if (!is.null(shp) && isTRUE(shp$hollow) && length(shp$outline_pt)) {
    rows[[length(rows) + 1L]] <- graded(
      "Point outline", lw_req,
      paste0(fmt_num(min(shp$outline_pt), 2), " pt (hollow shapes)"),
      (is.null(spec$min_line_pt) ||
         min(shp$outline_pt) >= as.numeric(spec$min_line_pt) - 1e-6) &&
        (is.null(spec$max_line_pt) ||
           max(shp$outline_pt) <= as.numeric(spec$max_line_pt) + 1e-6),
      spec, "min_line_pt"
    )
  }

  # Colour mode -----------------------------------------------------------
  actual_mode <- if (is_file) info$colour_mode else "RGB"
  rows[[length(rows) + 1L]] <- graded(
    "Colour mode",
    if (!is.null(spec$colour_mode)) paste(unlist(spec$colour_mode), collapse = " or ") else NULL,
    actual_mode,
    !is.null(actual_mode) && !is.null(spec$colour_mode) &&
      tolower(actual_mode) %in% tolower(unlist(spec$colour_mode)),
    spec, "colour_mode"
  )

  # Colour safety ---------------------------------------------------------
  if (!is_file) {
    rows <- c(rows, colour_rows(plot_colours(x), spec, plot = x))
    rows <- c(rows, annotation_rows(x, spec))
  } else {
    rows <- c(rows, colour_rows_unmeasurable(spec))
  }

  # File size -------------------------------------------------------------
  rows[[length(rows) + 1L]] <- graded(
    "File size",
    if (!is.null(spec$max_file_mb)) paste0("max ", spec$max_file_mb, " MB") else NULL,
    if (!is.null(actual_size)) paste0(fmt_num(actual_size, 2), " MB") else NULL,
    !is.null(actual_size) && !is.null(spec$max_file_mb) &&
      actual_size <= as.numeric(spec$max_file_mb),
    spec, "max_file_mb"
  )

  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  if (no_spec) {
    # Not "unspecified by the publisher" and not "not yet harvested": there is
    # no publisher and no registry entry in play. Say the third thing.
    out$requirement <- NO_SPEC
    out$status <- "unspecified"
  } else if (!from_registry) {
    # A hand-written or loaded specification. Silence about a field is the
    # author's own omission, not a gap in figspec's registry, so it must not be
    # reported as one - and there is no publisher here either, so neither
    # wording that names one can stand.
    gap <- out$requirement %in% c(UNHARVESTED, UNSTATED)
    out$requirement[gap] <- UNSTATED_USER
    out$status[gap] <- "unspecified"
  }
  structure(
    out,
    no_spec = no_spec,
    journal = if (no_spec) NULL else spec$name,
    journal_id = spec$id,
    source_url = spec$source_url,
    verified_on = spec$verified_on,
    input = if (is_file) x else "ggplot object",
    class = c("figspec_report", "data.frame")
  )
}

# Subsetting a report yields a plain data frame.
#
# A report carries the journal, the source URL and the date it was read as
# attributes, and its print method presents them as the provenance of the whole
# report. A subset is no longer that report - `r[r$status == "fail", ]` is a
# selection the user made - so the attributes and the class are dropped rather
# than left to imply that the remaining rows are the complete finding.
#
#' @export
`[.figspec_report` <- function(x, ...) {
  out <- NextMethod()
  if (is.data.frame(out)) {
    attributes(out)[c("journal", "journal_id", "source_url", "verified_on", "input")] <- NULL
    class(out) <- "data.frame"
  }
  out
}

# Lay out one row of a report to the console width.
#
# cli's alerts do not wrap, so a long requirement would run off the side of the
# screen and off the side of a rendered vignette. A row that fits stays on one
# line with its columns aligned; a row that does not carries its requirement on
# wrapped continuation lines, indented to sit under `actual`.
#
# @param check,actual,requirement The three fields of the row.
# @param width Console width to lay out to.
# @param lab_w Width of the check-name column, sized to the widest name in the
#   report so that every row in it lines up.
# @return A list of `head`, the first line, and `rest`, zero or more
#   continuation lines already indented.
BULLET_W <- 2L

report_row <- function(check, actual, requirement, width, lab_w = 12L) {
  lab <- paste0(format(check, width = lab_w), " ")
  req <- paste0("requires: ", requirement)
  one <- trimws(paste0(lab, format(actual, width = 26), "  ", req), "right")
  if (BULLET_W + nchar(one) <= width) {
    return(list(head = one, rest = character()))
  }
  indent <- strrep(" ", BULLET_W + lab_w + 1L)
  avail <- max(width - nchar(indent), 24L)
  head_txt <- strwrap(actual, width = avail)
  if (!length(head_txt)) head_txt <- ""
  list(
    head = paste0(lab, head_txt[1]),
    rest = paste0(indent, c(head_txt[-1], strwrap(req, width = avail)))
  )
}

#' @export
print.figspec_report <- function(x, ...) {
  cli::cli_h1("{attr(x, 'journal') %||% 'Figure inspection'}")
  cli::cli_text("{.emph checked: {attr(x, 'input')}}")
  cli::cli_text("")
  w <- max(cli::console_width(), 50L)
  lab_w <- max(nchar(x$check), 1L)
  for (i in seq_len(nrow(x))) {
    r <- x[i, ]
    ln <- report_row(r$check, r$actual, r$requirement, w, lab_w)
    switch(r$status,
      pass = cli::cli_alert_success("{ln$head}"),
      fail = cli::cli_alert_danger("{ln$head}"),
      unspecified = cli::cli_alert_info("{ln$head}"),
      unknown = cli::cli_alert_warning("{ln$head}")
    )
    if (length(ln$rest)) cli::cli_verbatim(ln$rest)
  }
  fails <- sum(x$status == "fail")
  cli::cli_text("")
  # With no specification there is nothing to have failed, and saying "no
  # failures" would read as a clean bill of health that nothing was checked
  # for. Report the absence instead.
  if (isTRUE(attr(x, "no_spec"))) {
    cli::cli_alert_info(
      "Nothing was checked: no specification was given. Pass a journal id, or ",
      "a specification of your own, to have these judged."
    )
  } else if (fails == 0) {
    cli::cli_alert_success("No failures against the requirements on record.")
  } else {
    cli::cli_alert_danger("{fails} requirement{?s} not met.")
  }
  n_open <- sum(x$status %in% c("unspecified", "unknown"))
  if (n_open > 0 && !isTRUE(attr(x, "no_spec"))) {
    cli::cli_alert_info(
      "{n_open} requirement{?s} could not be judged automatically - check by hand."
    )
  }
  # A source line with nothing in it reads as a missing citation rather than as
  # an absent one, so print it only when there is a source to cite.
  src <- attr(x, "source_url")
  if (!is.null(src) && nzchar(src)) {
    seen <- attr(x, "verified_on")
    cli::cli_text(
      "{.strong Source:} {.url {src}}",
      if (!is.null(seen) && nzchar(seen)) " (verified {seen})" else ""
    )
  }
  invisible(x)
}
