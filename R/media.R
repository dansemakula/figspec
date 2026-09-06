# Supplementary media --------------------------------------------------------
#
# Video and audio submitted alongside an article are governed by their own
# rules - container, codec, frame size, duration, file size - which have
# nothing to do with figure requirements and are never mixed into a figure
# report.
#
# Frame sizes are the reason this needs code rather than a lookup. A publisher
# states a maximum frame size and often a list of preferred ones, and a video
# that exceeds the maximum has to be scaled to fit while keeping its aspect
# ratio, since stretching it would be worse than shrinking it.

#' Look up supplementary media requirements
#'
#' Publications and projects may set separate rules for video and audio:
#' container format, codec, frame size, bit rate and file size. These are not
#' figure requirements and are therefore kept separate from [fig_check()].
#'
#' @param spec A registry id such as `"science"`, a `figspec_spec`, or a
#'   named list of requirements.
#' @return A list of the stated media requirements, or `NULL` with a message
#'   when the selected specification records none.
#' @examples
#' media_spec("science")
#' @export
media_spec <- function(spec) {
  spec <- spec_get(spec)
  if (is.null(spec$media)) {
    msg_wrap("No supplementary media requirements are recorded for '",
            spec$name, "'. See ", spec$source_url)
    return(invisible(NULL))
  }
  structure(
    c(spec$media, list(spec_name = spec$name, source_url = spec$source_url,
                       verified_on = spec$verified_on,
                       publication_stage = spec$publication_stage)),
    class = c("figspec_media_spec", "list")
  )
}

#' @export
print.figspec_media_spec <- function(x, ...) {
  cli::cli_h1("{x$spec_name} - supplementary media")
  line <- function(label, v, unit = "") {
    if (is.null(v)) return(invisible(NULL))
    cli::cli_li("{.strong {label}:} {paste(unlist(v), collapse = ', ')}{unit}")
  }
  cli::cli_ul()
  line("Video formats", toupper(unlist(x$video_formats)))
  line("Video codec", x$video_codec)
  if (!is.null(x$frame_max)) {
    line("Maximum frame size", paste0(x$frame_max$width, " x ", x$frame_max$height))
  }
  if (!is.null(x$frame_preferred)) {
    pref <- vapply(x$frame_preferred, function(f) paste0(f$width, " x ", f$height), character(1))
    line("Preferred frame sizes", paste(pref, collapse = " or "))
  }
  line("Maximum file size", x$max_file_mb, " MB")
  line("Audio formats", toupper(unlist(x$audio_formats)))
  line("Audio bit rate", x$audio_bitrate_kbps, " kb/s")
  cli::cli_end()
  if (!is.null(x$source_quote_frame)) {
    cli::cli_text("")
    cli::cli_text("{.emph {x$source_quote_frame}}")
  }
  cli::cli_text("")
  cli::cli_text("{.strong Source:} {.url {x$source_url}} (verified {x$verified_on})")
  if (!is.null(x$publication_stage) && nzchar(x$publication_stage)) {
    cli::cli_text("{.strong Applies at:} {x$publication_stage} submission")
  }
  invisible(x)
}

# Frame size readers ------------------------------------------------------

# The tkhd box in an MP4 or MOV carries the track's display size as a pair of
# 16.16 fixed-point numbers. Audio tracks carry zeroes, so the video track is
# the largest non-zero pair.
read_mp4_frame <- function(path) {
  n <- file.size(path)
  raw <- readBin(path, "raw", min(n, 4194304L))
  if (length(raw) < 8L) return(NULL)
  tkhd <- charToRaw("tkhd")
  hits <- which(
    raw[seq_len(length(raw) - 3L)] == tkhd[1] &
      raw[seq(2L, length(raw) - 2L)] == tkhd[2] &
      raw[seq(3L, length(raw) - 1L)] == tkhd[3] &
      raw[seq(4L, length(raw))] == tkhd[4]
  )
  if (!length(hits)) return(NULL)
  be <- function(i, k) sum(as.numeric(raw[i:(i + k - 1L)]) * 256^rev(seq_len(k) - 1L))
  best <- NULL
  for (h in hits) {
    ver_at <- h + 4L
    if (ver_at > length(raw)) next
    version <- as.integer(raw[ver_at])
    skip <- if (version == 1L) 32L else 20L
    w_at <- ver_at + 4L + skip + 16L + 36L
    if (w_at + 7L > length(raw)) next
    w <- be(w_at, 4L) / 65536
    hgt <- be(w_at + 4L, 4L) / 65536
    if (w > 0 && hgt > 0 && (is.null(best) || w > best$width)) {
      best <- list(width = round(w), height = round(hgt))
    }
  }
  best
}

read_gif_frame <- function(path) {
  raw <- readBin(path, "raw", 10L)
  if (length(raw) < 10L) return(NULL)
  if (!rawToChar(raw[1:3]) == "GIF") return(NULL)
  le <- function(i) as.integer(raw[i]) + as.integer(raw[i + 1L]) * 256L
  list(width = le(7L), height = le(9L))
}

inspect_media <- function(path) {
  ext <- tolower(tools::file_ext(path))
  raw <- readBin(path, "raw", min(file.size(path), 32L))
  sig <- function(from, text) {
    to <- from + nchar(text, type = "bytes") - 1L
    length(raw) >= to && identical(as.integer(raw[from:to]), as.integer(charToRaw(text)))
  }
  valid <- switch(ext,
    gif = sig(1L, "GIF87a") || sig(1L, "GIF89a"),
    mp4 = , m4v = , mov = , m4a = sig(5L, "ftyp"),
    wav = sig(1L, "RIFF") && sig(9L, "WAVE"),
    mp3 = length(raw) >= 3L && (sig(1L, "ID3") ||
      (as.integer(raw[1]) == 255L && bitwAnd(as.integer(raw[2]), 224L) == 224L)),
    NA
  )
  info <- list(format = ext, size_mb = file.size(path) / 1024^2, valid = valid)
  frame <- switch(ext,
    mp4 = ,
    m4v = ,
    mov = read_mp4_frame(path),
    gif = read_gif_frame(path),
    NULL
  )
  if (!is.null(frame)) {
    info$width_px <- frame$width
    info$height_px <- frame$height
  }
  probe <- inspect_media_ffprobe(path)
  if (!is.null(probe)) {
    signature_valid <- info$valid
    info <- utils::modifyList(info, probe)
    if (identical(signature_valid, FALSE)) info$valid <- FALSE
  }
  info
}

inspect_media_ffprobe <- function(path) {
  exe <- Sys.which("ffprobe")
  if (!nzchar(exe)) return(NULL)
  probe_one <- function(selector) {
    args <- c("-v", "error", "-select_streams", selector,
              "-show_entries", "stream=codec_name,width,height,bit_rate",
              "-of", "default=noprint_wrappers=1", shQuote(normalizePath(path)))
    out <- tryCatch(suppressWarnings(system2(exe, args, stdout = TRUE, stderr = TRUE)),
                    error = function(e) character())
    if (!length(out) || !is.null(attr(out, "status"))) return(NULL)
    bits <- strsplit(out[grepl("=", out, fixed = TRUE)], "=", fixed = TRUE)
    values <- vapply(bits, function(x) paste(x[-1], collapse = "="), character(1))
    names(values) <- vapply(bits, `[[`, character(1), 1L)
    values
  }
  video <- probe_one("v:0")
  audio <- probe_one("a:0")
  if (is.null(video) && is.null(audio)) return(NULL)
  number <- function(x) {
    if (is.null(x) || !grepl("^[0-9]+(?:[.][0-9]+)?$", x)) return(NULL)
    as.numeric(x)
  }
  list(
    valid = TRUE,
    width_px = number(video[["width"]]),
    height_px = number(video[["height"]]),
    video_codec = video[["codec_name"]] %||% NULL,
    video_bitrate_kbps = if (!is.null(number(video[["bit_rate"]]))) number(video[["bit_rate"]]) / 1000 else NULL,
    audio_codec = audio[["codec_name"]] %||% NULL,
    audio_bitrate_kbps = if (!is.null(number(audio[["bit_rate"]]))) number(audio[["bit_rate"]]) / 1000 else NULL
  )
}

#' Verify a supplementary media file
#'
#' Checks container format, frame size, file size, video codec and audio bit
#' rate. Codec and bit rate are read with the system `ffprobe` executable when
#' it is available; without it those rows are reported as `unknown`, never
#' guessed.
#'
#' @param path One path to an existing media file.
#' @param spec A registry id, a `figspec_spec`, or a named list containing
#'   supplementary media requirements.
#' @return A `figspec_report`.
#' @examples
#' # A real, valid 1 x 1 pixel GIF written to a temporary file.
#' gif_hex <- c(
#'   "47", "49", "46", "38", "39", "61", "01", "00", "01", "00",
#'   "80", "00", "00", "00", "00", "00", "ff", "ff", "ff", "21",
#'   "f9", "04", "01", "00", "00", "00", "00", "2c", "00", "00",
#'   "00", "00", "01", "00", "01", "00", "00", "02", "02", "44",
#'   "01", "00", "3b"
#' )
#' media_file <- tempfile(fileext = ".gif")
#' writeBin(as.raw(strtoi(gif_hex, 16L)), media_file)
#'
#' project_media_spec <- list(
#'   name = "Project media handoff",
#'   media = list(
#'     video_formats = "gif",
#'     frame_max = list(width = 1280, height = 720),
#'     max_file_mb = 1
#'   )
#' )
#' media_check(media_file, project_media_spec)
#' unlink(media_file)
#' @export
media_check <- function(path, spec) {
  if (!is.character(path) || length(path) != 1L || is.na(path) ||
      !nzchar(trimws(path))) {
    figspec_abort("{.arg path} must be one non-empty media-file path.", "bad_input")
  }
  if (!file.exists(path)) figspec_abort("File not found: {.file {path}}.", "not_found", path = path)
  if (dir.exists(path)) {
    figspec_abort("{.arg path} points to a directory, not a media file: {.file {path}}.", "bad_input")
  }
  spec <- spec_get(spec)
  media <- spec$media
  if (is.null(media)) {
    figspec_abort(
      c("No supplementary media requirements are recorded for {spec$name}.",
        "i" = "That is a gap in the registry, not a statement that the
               publisher has no rules.",
        ">" = "Check the guidelines yourself: {.url {spec$source_url}}"),
      "not_found", spec_name = spec$name)
  }
  info <- inspect_media(path)
  rows <- list()

  rows[[1]] <- if (identical(info$valid, FALSE)) {
    new_row("File validity", "valid media container",
            paste0("not a readable ", toupper(info$format), " file"), "invalid")
  } else if (isTRUE(info$valid)) {
    new_row("File validity", "valid media container", "valid", "pass")
  } else {
    new_row("File validity", "valid media container", "not inspected", "unknown")
  }

  is_audio <- tolower(info$format) %in% tolower(unlist(media$audio_formats %||% list()))
  fmt_allowed <- c(unlist(media$video_formats %||% list()),
                   unlist(media$audio_formats %||% list()))
  rows[[length(rows) + 1L]] <- graded(
    "Format",
    if (length(fmt_allowed)) paste(toupper(fmt_allowed), collapse = ", ") else NULL,
    toupper(info$format),
    tolower(info$format) %in% tolower(fmt_allowed)
  )

  if (!is_audio) {
    fm <- media$frame_max
    actual_frame <- if (!is.null(info$width_px)) {
      paste0(info$width_px, " x ", info$height_px)
    } else NULL
    rows[[length(rows) + 1L]] <- graded(
      "Frame size",
      if (!is.null(fm)) paste0("max ", fm$width, " x ", fm$height) else NULL,
      actual_frame,
      !is.null(info$width_px) && !is.null(fm) &&
        info$width_px <= fm$width && info$height_px <= fm$height
    )
  }

  rows[[length(rows) + 1L]] <- graded(
    "File size",
    if (!is.null(media$max_file_mb)) paste0("max ", media$max_file_mb, " MB") else NULL,
    paste0(fmt_num(info$size_mb, 2), " MB"),
    !is.null(media$max_file_mb) && info$size_mb <= as.numeric(media$max_file_mb)
  )

  normalise_codec <- function(x) gsub("[^a-z0-9]", "", tolower(x))
  if (!is_audio) {
    rows[[length(rows) + 1L]] <- graded(
      "Video codec",
      media$video_codec,
      info$video_codec,
      !is.null(info$video_codec) && !is.null(media$video_codec) &&
        normalise_codec(info$video_codec) == normalise_codec(media$video_codec)
    )
  } else {
    rows[[length(rows) + 1L]] <- graded(
      "Audio bit rate",
      if (!is.null(media$audio_bitrate_kbps)) paste0("min ", media$audio_bitrate_kbps, " kb/s") else NULL,
      if (!is.null(info$audio_bitrate_kbps)) paste0(round(info$audio_bitrate_kbps), " kb/s") else NULL,
      !is.null(info$audio_bitrate_kbps) && !is.null(media$audio_bitrate_kbps) &&
        info$audio_bitrate_kbps >= as.numeric(media$audio_bitrate_kbps)
    )
  }

  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  if (identical(info$valid, FALSE)) {
    out$status[out$check != "File validity" & out$status %in% c("pass", "fail")] <- "invalid"
  }
  structure(out, spec_name = spec$name, spec_id = spec$id,
            source_url = spec$source_url, verified_on = spec$verified_on,
            publication_stage = spec$publication_stage,
            input = path, class = c("figspec_report", "data.frame"))
}
