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
      unit <- as.integer(raw[i + 11L])
      xd <- be(i + 12L)
      if (xd > 0) info$dpi <- if (unit == 2L) xd * 2.54 else xd
    }
    if (marker %in% c(192L:195L, 197L:199L, 201L:203L, 205L:207L)) {
      info$height_px <- be(i + 7L)
      info$width_px <- be(i + 9L)
      break
    }
    i <- i + 2L + len
  }
  info
}

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

new_row <- function(check, requirement, actual, status) {
  # A publisher that states no requirement cannot be passed or failed. Rather
  # than trust every call site to remember that, enforce it here: an unstated
  # requirement is always reported as unspecified, whatever verdict was
  # computed. Reporting a pass against a rule that does not exist is the same
  # error as inventing the rule.
  if (identical(requirement, UNSTATED) && status %in% c("pass", "fail")) {
    status <- "unspecified"
  }
  data.frame(
    check = check, requirement = requirement, actual = actual,
    status = status, stringsAsFactors = FALSE
  )
}

# An unstated requirement is reported as unspecified. It must never be
# recorded as a pass: the publisher has not told us what would pass.
graded <- function(check, requirement, actual, ok) {
  if (is.null(requirement) || is.na(requirement) || !nzchar(requirement)) {
    return(new_row(check, UNSTATED, actual %||% "-", "unspecified"))
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
#'   than quietly applying the most lenient one.
#' @return An object of class `figspec_report`, a data frame of one row per
#'   requirement.
#' @examples
#' library(ggplot2)
#' p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
#' check_journal(p, "frontiers")
#' @export
check_journal <- function(x, journal, column = "single",
                          width = NULL, height = NULL,
                          units = c("mm", "cm", "in"),
                          dpi = NULL, format = NULL,
                          art_type = c("colour", "bw", "line", "combination")) {
  units <- match.arg(units)
  art_type <- match.arg(art_type)
  spec <- journal_spec(journal)
  rows <- list()
  info <- list()

  is_file <- is.character(x) && length(x) == 1L
  if (is_file) {
    if (!file.exists(x)) stop("File not found: ", x, call. = FALSE)
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
    text_sizes <- NULL
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
    stop("`x` must be a ggplot object or a path to a figure file.", call. = FALSE)
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
      actual_h <= as.numeric(spec$height_max_mm) + 0.5
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
    req_dpi_txt <- if (is.null(required_dpi)) NULL else {
      paste0("min ", required_dpi, " dpi for ", art_type,
             if (length(others)) paste0("; also states ", paste(others, collapse = ", "), " dpi") else "")
    }
    rows[[length(rows) + 1L]] <- graded(
      "Resolution", req_dpi_txt,
      if (!is.null(actual_dpi)) paste0(fmt_num(actual_dpi, 0), " dpi") else NULL,
      !is.null(actual_dpi) && !is.null(required_dpi) &&
        actual_dpi >= as.numeric(required_dpi)
    )
  }

  # File format -----------------------------------------------------------
  rows[[length(rows) + 1L]] <- graded(
    "File format",
    if (!is.null(spec$formats)) paste(toupper(unlist(spec$formats)), collapse = ", ") else NULL,
    if (!is.null(actual_format)) toupper(actual_format) else NULL,
    !is.null(actual_format) && !is.null(spec$formats) &&
      tolower(actual_format) %in% tolower(unlist(spec$formats))
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
      ok_txt
    )
  } else {
    rows[[length(rows) + 1L]] <- graded(
      "Type size",
      if (!is.null(spec$font_min_pt)) paste0("min ", spec$font_min_pt, " pt") else NULL,
      NULL, NA
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
      tolower(actual_family) %in% tolower(unlist(spec$font_families))
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
    graded("Line width", lw_req, NULL, NA)
  } else {
    ok_lw <- (is.null(spec$min_line_pt) || min(line_pts) >= as.numeric(spec$min_line_pt) - 1e-6) &&
      (is.null(spec$max_line_pt) || max(line_pts) <= as.numeric(spec$max_line_pt) + 1e-6)
    graded("Line width", lw_req,
           paste0(fmt_num(min(line_pts), 2), " to ", fmt_num(max(line_pts), 2), " pt"),
           ok_lw)
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
           max(shp$outline_pt) <= as.numeric(spec$max_line_pt) + 1e-6)
    )
  }

  # Colour mode -----------------------------------------------------------
  actual_mode <- if (is_file) info$colour_mode else "RGB"
  rows[[length(rows) + 1L]] <- graded(
    "Colour mode",
    if (!is.null(spec$colour_mode)) paste(unlist(spec$colour_mode), collapse = " or ") else NULL,
    actual_mode,
    !is.null(actual_mode) && !is.null(spec$colour_mode) &&
      tolower(actual_mode) %in% tolower(unlist(spec$colour_mode))
  )

  # Colour safety ---------------------------------------------------------
  if (!is_file) {
    rows <- c(rows, colour_rows(plot_colours(x), spec, plot = x))
    rows <- c(rows, annotation_rows(x, spec))
  }

  # File size -------------------------------------------------------------
  rows[[length(rows) + 1L]] <- graded(
    "File size",
    if (!is.null(spec$max_file_mb)) paste0("max ", spec$max_file_mb, " MB") else NULL,
    if (!is.null(actual_size)) paste0(fmt_num(actual_size, 2), " MB") else NULL,
    !is.null(actual_size) && !is.null(spec$max_file_mb) &&
      actual_size <= as.numeric(spec$max_file_mb)
  )

  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  structure(
    out,
    journal = spec$name,
    journal_id = spec$id,
    source_url = spec$source_url,
    verified_on = spec$verified_on,
    input = if (is_file) x else "ggplot object",
    class = c("figspec_report", "data.frame")
  )
}

#' @export
`[.figspec_report` <- function(x, ...) {
  out <- NextMethod()
  if (is.data.frame(out)) {
    attributes(out)[c("journal", "journal_id", "source_url", "verified_on", "input")] <- NULL
    class(out) <- "data.frame"
  }
  out
}

#' @export
print.figspec_report <- function(x, ...) {
  cli::cli_h1("{attr(x, 'journal')}")
  cli::cli_text("{.emph checked: {attr(x, 'input')}}")
  cli::cli_text("")
  sym <- c(pass = "v", fail = "x", unspecified = "-", unknown = "?")
  for (i in seq_len(nrow(x))) {
    r <- x[i, ]
    label <- paste0(
      format(r$check, width = 12), " ",
      format(r$actual, width = 34), " ", "(requires: ", r$requirement, ")"
    )
    switch(r$status,
      pass = cli::cli_alert_success(label),
      fail = cli::cli_alert_danger(label),
      unspecified = cli::cli_alert_info(label),
      unknown = cli::cli_alert_warning(label)
    )
  }
  fails <- sum(x$status == "fail")
  cli::cli_text("")
  if (fails == 0) {
    cli::cli_alert_success("No failures against the requirements on record.")
  } else {
    cli::cli_alert_danger("{fails} requirement{?s} not met.")
  }
  n_open <- sum(x$status %in% c("unspecified", "unknown"))
  if (n_open > 0) {
    cli::cli_alert_info(
      "{n_open} requirement{?s} could not be judged automatically - check by hand."
    )
  }
  cli::cli_text("{.strong Source:} {.url {attr(x, 'source_url')}} (verified {attr(x, 'verified_on')})")
  invisible(x)
}
