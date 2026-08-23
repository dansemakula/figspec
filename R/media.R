# Supplementary media -----------------------------------------------------

#' Supplementary media requirements for a journal
#'
#' Journals publish separate rules for video and audio submitted as
#' supplementary material: container format, codec, frame size and file size.
#' These are not figure requirements and are not checked by [check_journal()].
#'
#' @param journal Registry id, for example `"science"`.
#' @return A list of the stated media requirements, or `NULL` with a message
#'   when the registry records none for that journal.
#' @examples
#' media_spec("science")
#' @export
media_spec <- function(journal) {
  spec <- journal_spec(journal)
  if (is.null(spec$media)) {
    msg_wrap("No supplementary media requirements are recorded for '",
            spec$name, "'. See ", spec$source_url)
    return(invisible(NULL))
  }
  structure(
    c(spec$media, list(journal = spec$name, source_url = spec$source_url,
                       verified_on = spec$verified_on)),
    class = c("figspec_media_spec", "list")
  )
}

#' @export
print.figspec_media_spec <- function(x, ...) {
  cli::cli_h1("{x$journal} - supplementary media")
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
  invisible(x)
}

# Frame size readers ------------------------------------------------------

# The tkhd box in an MP4 or MOV carries the track's display size as a pair of
# 16.16 fixed-point numbers. Audio tracks carry zeroes, so the video track is
# the largest non-zero pair.
read_mp4_frame <- function(path) {
  n <- file.size(path)
  raw <- readBin(path, "raw", min(n, 4194304L))
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
  info <- list(format = ext, size_mb = file.size(path) / 1024^2)
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
  info
}

#' Check a supplementary media file against a journal's requirements
#'
#' Checks container format, frame size and file size. Codec and bit rate are
#' recorded in the registry but are not inspected: reading them reliably needs
#' a media library, and reporting a guess would be worse than reporting
#' nothing.
#'
#' @param path Path to a media file.
#' @param journal Registry id.
#' @return A `figspec_report`.
#' @examples
#' # check_media("movie_s1.mp4", "science")
#' @export
check_media <- function(path, journal) {
  if (!file.exists(path)) stop("File not found: ", path, call. = FALSE)
  spec <- journal_spec(journal)
  media <- spec$media
  if (is.null(media)) {
    stop("No supplementary media requirements are recorded for '", spec$name,
         "'. See ", spec$source_url, call. = FALSE)
  }
  info <- inspect_media(path)
  rows <- list()

  is_audio <- tolower(info$format) %in% tolower(unlist(media$audio_formats %||% list()))
  fmt_allowed <- c(unlist(media$video_formats %||% list()),
                   unlist(media$audio_formats %||% list()))
  rows[[1]] <- graded(
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

  rows[[length(rows) + 1L]] <- new_row(
    "Codec",
    if (!is.null(media$video_codec)) media$video_codec else "not specified by publisher",
    "not inspected - figspec does not decode media streams",
    "unknown"
  )

  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  structure(out, journal = spec$name, journal_id = spec$id,
            source_url = spec$source_url, verified_on = spec$verified_on,
            input = path, class = c("figspec_report", "data.frame"))
}
