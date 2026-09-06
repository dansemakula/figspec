# Registry schema validation -------------------------------------------------

registry_problems <- function(entries) {
  problems <- character()
  add <- function(...) problems <<- c(problems, paste0(...))
  if (!is.list(entries) || !length(entries)) return("registry contains no entries")

  ids <- vapply(entries, function(j) {
    if (is.list(j) && is.character(j$id) && length(j$id) == 1L) j$id else NA_character_
  }, character(1))
  if (anyDuplicated(ids[!is.na(ids)])) {
    add("Duplicate registry id(s): ", paste(unique(ids[duplicated(ids)]), collapse = ", "))
  }

  positive_numeric <- c(
    "width_min_mm", "width_max_mm", "height_max_mm", "dpi_min", "dpi_max",
    "dpi_line_art", "dpi_bw", "dpi_combination", "font_min_pt", "font_max_pt",
    "max_file_mb", "min_line_pt", "max_line_pt", "max_panels", "max_pages",
    "max_series_recommended"
  )
  logical_fields <- c(
    "dpi_min_inclusive", "dpi_max_inclusive", "allow_alpha", "flattened",
    "text_no_final_stop", "print_greyscale", "axes_from_zero",
    "axis_lines_and_ticks", "avoid_coloured_text", "no_background_grid"
  )
  allowed <- c(requirement_keys(), "max_series_recommended")
  top_allowed <- c(
    "id", "name", "publisher", "disciplines", "source_url", "verified_on",
    "source_archive_url", "source_content_md5", "publication_stage",
    "requirements", "not_stated", "sources", "house_style", "tables", "media",
    "graphical_abstract", "notes"
  )

  for (j in entries) {
    if (!is.list(j)) {
      add("an entry is not a named list")
      next
    }
    id <- if (is.character(j$id) && length(j$id) == 1L && nzchar(j$id)) j$id else "<missing id>"
    unknown_top <- setdiff(names(j), top_allowed)
    if (length(unknown_top)) {
      add(id, ": unrecognised entry field(s): ", paste(unknown_top, collapse = ", "))
    }
    if (identical(id, "<missing id>") || !grepl("^[a-z][a-z0-9_]*$", id)) {
      add(id, ": `id` must match ^[a-z][a-z0-9_]*$")
    }
    if (!is.character(j$name) || length(j$name) != 1L || !nzchar(trimws(j$name))) {
      add(id, ": `name` must be one non-empty string")
    }
    source <- j$source_url
    if (!is.character(source) || length(source) != 1L || !nzchar(trimws(source)) ||
        !grepl("^(https?://|file:|internal:)", source, ignore.case = TRUE)) {
      add(id, ": provenance `source_url` must be an HTTP(S), file:, or internal: URI")
    }
    date_text <- as.character(j$verified_on %||% "")
    parsed_date <- suppressWarnings(as.Date(date_text, format = "%Y-%m-%d"))
    roundtrip <- !is.na(parsed_date) && identical(format(parsed_date, "%Y-%m-%d"), date_text)
    if (!isTRUE(roundtrip) || (!is.na(parsed_date) && parsed_date > Sys.Date())) {
      add(id, ": `verified_on` must be a real YYYY-MM-DD date no later than today")
    }
    if (!is.null(j$publication_stage) &&
        (!is.character(j$publication_stage) || length(j$publication_stage) != 1L ||
         !j$publication_stage %in% c("initial", "revision", "final", "all"))) {
      add(id, ": `publication_stage` must be initial, revision, final, or all")
    }

    sources <- j$sources
    source_fields <- character()
    if (!is.null(sources)) {
      if (!is.list(sources) || !length(sources)) {
        add(id, ": `sources` must be a non-empty list")
      } else {
        for (k in seq_along(sources)) {
          src <- sources[[k]]
          prefix <- paste0(id, ": source ", k)
          if (!is.list(src)) {
            add(prefix, " must be a named list")
            next
          }
          if (!is.character(src$url) || length(src$url) != 1L ||
              !grepl("^https?://", src$url)) add(prefix, " has no valid HTTP(S) URL")
          src_date <- as.character(src$verified_on %||% "")
          src_parsed <- suppressWarnings(as.Date(src_date, format = "%Y-%m-%d"))
          if (is.na(src_parsed) || !identical(format(src_parsed, "%Y-%m-%d"), src_date) ||
              src_parsed > Sys.Date()) add(prefix, " has no valid verification date")
          fields <- unlist(src$fields %||% list())
          if (!is.character(fields) || !length(fields) || any(!fields %in% allowed)) {
            add(prefix, " must name recognised requirement fields")
          } else source_fields <- c(source_fields, fields)
          if (!is.character(src$quote) || length(src$quote) != 1L || !nzchar(trimws(src$quote))) {
            add(prefix, " must preserve a non-empty exact excerpt")
          }
        }
      }
    }

    req <- j$requirements %||% list()
    if (!is.list(req) || (length(req) && (is.null(names(req)) || any(!nzchar(names(req)))))) {
      add(id, ": `requirements` must be a named list")
      next
    }
    unknown <- setdiff(names(req), c(allowed, grep("^source_quote", names(req), value = TRUE)))
    if (length(unknown)) add(id, ": unrecognised requirement field(s): ", paste(unknown, collapse = ", "))
    if (anyDuplicated(names(req))) add(id, ": duplicate requirement field names are not allowed")
    if (!is.null(sources)) {
      claimed <- setdiff(names(req), grep("^source_quote", names(req), value = TRUE))
      missing_sources <- setdiff(claimed, unique(source_fields))
      if (length(missing_sources)) {
        add(id, ": requirement field(s) missing from field-level `sources`: ",
            paste(missing_sources, collapse = ", "))
      }
    }
    quote_fields <- grep("^source_quote", names(req), value = TRUE)
    for (field in quote_fields) {
      value <- req[[field]]
      if (!is.character(value) || length(value) != 1L || !nzchar(trimws(value))) {
        add(id, ": `", field, "` must be one non-empty source excerpt")
      }
    }

    for (field in intersect(positive_numeric, names(req))) {
      value <- req[[field]]
      if (!is.numeric(value) || length(value) != 1L || !is.finite(value) || value <= 0) {
        add(id, ": `", field, "` must be one positive finite number")
      }
    }
    for (field in intersect(logical_fields, names(req))) {
      value <- req[[field]]
      if (!is.logical(value) || length(value) != 1L || is.na(value)) {
        add(id, ": `", field, "` must be TRUE or FALSE")
      }
    }
    if (!is.null(req$columns)) {
      cols <- unlist(req$columns)
      if (!length(cols) || is.null(names(cols)) || any(!nzchar(names(cols))) ||
          !is.numeric(cols) || any(!is.finite(cols) | cols <= 0)) {
        add(id, ": `columns` must be named positive widths in millimetres")
      }
    }
    if (!is.null(req$formats)) {
      formats <- unlist(req$formats)
      if (!is.character(formats) || !length(formats) || any(!grepl("^[a-z0-9]+$", formats, ignore.case = TRUE))) {
        add(id, ": `formats` must contain file extensions without dots")
      }
    }
    if (!is.null(req$font_families)) {
      fonts <- unlist(req$font_families)
      if (!is.character(fonts) || !length(fonts) || any(!nzchar(trimws(fonts)))) {
        add(id, ": `font_families` must contain non-empty names")
      }
    }
    if (!is.null(req$avoid_colour_pairs)) {
      pairs <- req$avoid_colour_pairs
      valid_pairs <- is.list(pairs) && length(pairs) && all(vapply(pairs, function(x) {
        x <- unlist(x)
        is.character(x) && length(x) == 2L && all(nzchar(trimws(x)))
      }, logical(1)))
      if (!valid_pairs) add(id, ": `avoid_colour_pairs` must be a list of two-colour pairs")
    }
    if (!is.null(req$thousands_separator) &&
        (!is.character(req$thousands_separator) || length(req$thousands_separator) != 1L ||
         !nzchar(req$thousands_separator))) {
      add(id, ": `thousands_separator` must be one non-empty string")
    }
    if (!is.null(req$colour_mode)) {
      modes <- tolower(unlist(req$colour_mode))
      if (!length(modes) || any(!modes %in% c("rgb", "cmyk", "grayscale", "greyscale"))) {
        add(id, ": `colour_mode` contains an unsupported value")
      }
    }
    if (!is.null(req$tiff_compression) &&
        (!is.character(req$tiff_compression) || length(req$tiff_compression) != 1L ||
         !tolower(req$tiff_compression) %in% c("none", "lzw", "jpeg", "deflate"))) {
      add(id, ": `tiff_compression` must be none, lzw, jpeg, or deflate")
    }
    if (!is.null(req$panel_labels) && !req$panel_labels %in% c("uppercase", "lowercase", "numbers")) {
      add(id, ": `panel_labels` must be uppercase, lowercase, or numbers")
    }
    if (!is.null(req$panel_labels_placement) &&
        !req$panel_labels_placement %in% c("inside_panel", "outside_image", "publisher")) {
      add(id, ": `panel_labels_placement` has an unsupported value")
    }
    if (!is.null(req$text_case) && !req$text_case %in% "sentence") {
      add(id, ": `text_case` has an unsupported value")
    }
    if (!is.null(req$width_min_mm) && !is.null(req$width_max_mm) && req$width_min_mm > req$width_max_mm) add(id, ": width minimum exceeds maximum")
    if (!is.null(req$dpi_min) && !is.null(req$dpi_max) && req$dpi_min > req$dpi_max) add(id, ": dpi minimum exceeds maximum")
    if (!is.null(req$font_min_pt) && !is.null(req$font_max_pt) && req$font_min_pt > req$font_max_pt) add(id, ": font minimum exceeds maximum")
    if (!is.null(req$min_line_pt) && !is.null(req$max_line_pt) && req$min_line_pt > req$max_line_pt) add(id, ": line minimum exceeds maximum")

    raw_not_stated <- j$not_stated %||% list()
    not_stated <- unlist(raw_not_stated)
    if (length(not_stated) && (!is.character(not_stated) || any(!nzchar(not_stated)) ||
                               anyDuplicated(not_stated))) {
      add(id, ": `not_stated` must contain unique requirement field names")
    }
    bad_absent <- setdiff(not_stated, allowed)
    if (length(bad_absent)) add(id, ": unrecognised `not_stated` field(s): ", paste(bad_absent, collapse = ", "))
    clash <- intersect(not_stated, names(req))
    if (length(clash)) add(
      id, ": field(s) cannot both be absent and stated; found in `requirements` and `not_stated`: ",
      paste(clash, collapse = ", ")
    )
    style <- j$house_style
    if (!is.null(style)) {
      if (!is.list(style) ||
          (length(style) &&
           (is.null(names(style)) || any(!nzchar(names(style)))))) {
        add(id, ": `house_style` must be a named list")
      } else {
        leaked <- intersect(names(style), requirement_keys())
        if (length(leaked)) {
          add(id, ": requirement field(s) in `house_style`: ",
              paste(leaked, collapse = ", "),
              " (house style is taste, not a rule)")
        }
        if (!is.null(style$palette)) {
          palette <- unlist(style$palette)
          valid_palette <- is.character(palette) && length(palette) &&
            !anyNA(palette) && all(nzchar(trimws(palette)))
          if (valid_palette) {
            valid_palette <- tryCatch({
              grDevices::col2rgb(palette)
              TRUE
            }, error = function(e) FALSE)
          }
          if (!valid_palette) {
            add(id, ": `house_style.palette` must contain valid R colours")
          }
        }
      }
    }

    media <- j$media
    if (!is.null(media)) {
      if (!is.list(media) || is.null(names(media))) {
        add(id, ": `media` must be a named list")
      } else {
        media_allowed <- c("video_formats", "audio_formats", "video_codec",
                           "frame_max", "frame_preferred", "max_file_mb",
                           "audio_bitrate_kbps", "source_quote_frame",
                           "source_quote_format")
        unknown_media <- setdiff(names(media), media_allowed)
        if (length(unknown_media)) add(id, ": unrecognised media field(s): ", paste(unknown_media, collapse = ", "))
        for (field in intersect(c("video_formats", "audio_formats"), names(media))) {
          value <- unlist(media[[field]])
          if (!is.character(value) || !length(value) || any(!grepl("^[a-z0-9]+$", value, ignore.case = TRUE))) {
            add(id, ": `media.", field, "` must contain file extensions without dots")
          }
        }
        for (field in intersect(c("max_file_mb", "audio_bitrate_kbps"), names(media))) {
          value <- media[[field]]
          if (!is.numeric(value) || length(value) != 1L || !is.finite(value) || value <= 0) {
            add(id, ": `media.", field, "` must be one positive finite number")
          }
        }
        if (!is.null(media$frame_max)) {
          frame <- unlist(media$frame_max)
          if (!all(c("width", "height") %in% names(frame)) ||
              !is.numeric(frame[c("width", "height")]) ||
              any(!is.finite(frame[c("width", "height")]) | frame[c("width", "height")] <= 0)) {
            add(id, ": `media.frame_max` must have positive numeric width and height")
          }
        }
      }
    }
  }
  unique(problems)
}
