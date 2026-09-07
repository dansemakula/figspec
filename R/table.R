# Building, exporting and checking tables ----------------------------------

TABLE_FORMATS <- c("html", "htm", "docx", "rtf", "tex", "latex", "pdf", "png", "jpg", "jpeg")
TABLE_EDITABLE_FORMATS <- c("docx", "rtf", "tex", "latex", "html", "htm")
TABLE_TEXT_LIMIT <- 10 * 1024^2
TABLE_ARCHIVE_LIMIT <- 100 * 1024^2

table_system_or_null <- function(x) {
  if (inherits(x, "gt_tbl")) return("gt")
  if (inherits(x, "flextable")) return("flextable")
  if (inherits(x, "knitr_kable")) return("kable")
  if (inherits(x, "gtable") || inherits(x, "grob")) return("grid")
  if (is.data.frame(x)) return("data_frame")
  if (is.matrix(x)) return("matrix")
  NULL
}

table_system <- function(x) {
  system <- table_system_or_null(x)
  if (is.null(system)) {
    figspec_abort(
      c(
        "{.arg table} is not a supported table object.",
        "i" = paste0(
          "Use a data frame, matrix, gt table, flextable, knitr/kableExtra ",
          "table, or grid table."
        )
      ),
      "unsupported"
    )
  }
  system
}

table_rules <- function(spec, required = FALSE) {
  resolved <- if (is.null(spec)) NULL else spec_get(spec)
  rules <- resolved$tables %||% NULL
  if (isTRUE(required) && is.null(rules)) {
    figspec_abort(
      c(
        "{resolved$name} has no table requirements on record.",
        "i" = "Use a specification that contains a named {.field tables} section."
      ),
      "not_found"
    )
  }
  if (!is.null(rules)) {
    probe <- list(
      id = "inline_table",
      name = "Inline table specification",
      source_url = "internal:inline-table-specification",
      verified_on = as.character(Sys.Date()),
      requirements = list(),
      tables = rules
    )
    problems <- registry_problems(list(probe))
    if (length(problems)) {
      problems <- sub("^inline_table: ?", "", problems)
      figspec_abort(
        c("The tables section is invalid.", "x" = problems),
        "bad_input",
        problems = problems
      )
    }
  }
  list(spec = resolved, rules = rules)
}

table_rule_formats <- function(rules) {
  values <- tolower(unlist(
    rules$formats %||% rules[["format", exact = TRUE]] %||% list(),
    use.names = FALSE
  ))
  unique(values[nzchar(values)])
}

table_evidence <- function(x, system = table_system(x)) {
  stored <- attr(x, "figspec_table_evidence", exact = TRUE) %||% list()
  dims <- switch(
    system,
    data_frame = dim(x),
    matrix = dim(x),
    gt = dim(x[["_data"]]),
    flextable = dim(x$body$dataset),
    c(NA_integer_, NA_integer_)
  )
  utils::modifyList(
    list(
      valid = TRUE,
      format = "R object",
      editable = TRUE,
      rows = as.integer(dims[[1]]),
      columns = as.integer(dims[[2]])
    ),
    stored
  )
}

attach_table_evidence <- function(x, evidence, spec) {
  attr(x, "figspec_table_evidence") <- evidence
  attr(x, "figspec_table_spec") <- spec
  x
}

style_grid_table <- function(x, family = NULL, font_size = NA_real_,
                             header_bold = NULL, context = "") {
  own_context <- paste(context, x$name %||% "")
  if (inherits(x, "text")) {
    changes <- list()
    if (!is.null(family)) changes$fontfamily <- family
    if (is.finite(font_size)) changes$fontsize <- font_size
    if (!is.null(header_bold) &&
        grepl("colhead|header", own_context, ignore.case = TRUE)) {
      changes$font <- if (isTRUE(header_bold)) 2L else 1L
    }
    if (length(changes)) {
      x$gp <- do.call(
        grid::gpar,
        utils::modifyList(as.list(x$gp %||% grid::gpar()), changes)
      )
    }
  }
  if (!is.null(x$grobs)) {
    labels <- if (!is.null(x$layout$name) &&
                  length(x$layout$name) == length(x$grobs)) {
      x$layout$name
    } else {
      rep("", length(x$grobs))
    }
    for (i in seq_along(x$grobs)) {
      x$grobs[[i]] <- style_grid_table(
        x$grobs[[i]], family, font_size, header_bold,
        paste(own_context, labels[[i]])
      )
    }
  }
  if (!is.null(x$children) && length(x$children)) {
    children <- as.list(x$children)
    child_names <- names(children) %||% rep("", length(children))
    for (i in seq_along(children)) {
      children[[i]] <- style_grid_table(
        children[[i]], family, font_size, header_bold,
        paste(own_context, child_names[[i]])
      )
    }
    x$children <- do.call(grid::gList, children)
  }
  x
}

#' Apply a specification to a table
#'
#' Applies recorded table requirements while the table is still editable.
#' Supported inputs are data frames, matrices, gt tables, flextable objects,
#' knitr or kableExtra tables and grid tables. A data frame or matrix is
#' converted to a gt table.
#'
#' figspec applies the measurable requirements supported by the table system.
#' [table_check()] gathers editorial requirements, such as title clarity, for
#' the user's final review.
#'
#' @param table A supported table object.
#' @param spec The specification to apply. It must contain a tables section.
#' @return A styled table object with evidence of the applied values attached.
#' @examples
#' report_spec <- list(
#'   name = "Research report",
#'   tables = list(font_min_pt = 9, header_bold = TRUE,
#'                 vertical_rules = FALSE)
#' )
#' if (requireNamespace("gt", quietly = TRUE)) {
#' table_apply_spec(head(mtcars), report_spec)
#' }
#' @export
table_apply_spec <- function(table, spec) {
  system <- table_system(table)
  resolved <- table_rules(spec, required = TRUE)
  rules <- resolved$rules
  font_size <- as.numeric(
    rules$font_min_pt %||% rules$font_max_pt %||% NA_real_
  )
  family <- unlist(rules$font_families %||% list(), use.names = FALSE)
  family <- if (length(family)) as.character(family[[1]]) else NULL
  header_bold <- rules$header_bold %||% NULL
  vertical_rules <- rules$vertical_rules %||% NULL
  horizontal_rules <- rules$horizontal_rules %||% NULL
  width_mm <- as.numeric(rules$width_max_mm %||% NA_real_)
  applied <- list()

  if (system %in% c("data_frame", "matrix")) {
    if (!has_package("gt")) {
      figspec_abort(
        c(
          "Styling a data frame requires the {.pkg gt} package.",
          ">" = "Install it with {.code install.packages(\"gt\")}."
        ),
        "needs_package"
      )
    }
    table <- gt::gt(as.data.frame(table, stringsAsFactors = FALSE))
    system <- "gt"
  }

  if (system == "gt") {
    options <- list(data = table)
    if (!is.null(family)) options$table.font.names <- family
    if (is.finite(font_size)) {
      options$table.font.size <- gt::px(font_size * 96 / 72)
    }
    if (is.finite(width_mm)) {
      options$table.width <- gt::px(width_mm / MM_PER_IN * 96)
    }
    if (!is.null(header_bold)) {
      options$column_labels.font.weight <-
        if (isTRUE(header_bold)) "bold" else "normal"
    }
    if (!is.null(vertical_rules)) {
      value <- if (isTRUE(vertical_rules)) "solid" else "none"
      options$table_body.vlines.style <- value
      options$column_labels.vlines.style <- value
    }
    if (!is.null(horizontal_rules)) {
      options$table_body.hlines.style <-
        if (horizontal_rules == "none") "none" else "solid"
    }
    if (!is.null(rules$repeat_header)) {
      options$latex.header_repeat <- isTRUE(rules$repeat_header)
    }
    if (!is.null(rules$orientation)) {
      options$page.orientation <- tolower(rules$orientation)
    }
    table <- do.call(gt::tab_options, options)
    applied <- list(
      font_family = family,
      font_size_pt = if (is.finite(font_size)) font_size else NULL,
      header_bold = header_bold,
      vertical_rules = vertical_rules,
      horizontal_rules = horizontal_rules,
      width_mm = if (is.finite(width_mm)) width_mm else NULL
    )
  } else if (system == "flextable") {
    if (!has_package("flextable")) {
      figspec_abort(
        "Working with a flextable requires the {.pkg flextable} package.",
        "needs_package"
      )
    }
    if (is.finite(font_size)) {
      table <- flextable::fontsize(table, size = font_size, part = "all")
    }
    if (!is.null(family)) {
      table <- flextable::font(table, fontname = family, part = "all")
    }
    if (!is.null(header_bold)) {
      table <- flextable::bold(
        table, bold = isTRUE(header_bold), part = "header"
      )
    }
    needs_borders <- !is.null(vertical_rules) || !is.null(horizontal_rules)
    if (needs_borders && !has_package("officer")) {
      figspec_abort(
        "Applying table rules requires the {.pkg officer} package.",
        "needs_package"
      )
    }
    line <- if (needs_borders) {
      officer::fp_border(color = "#333333", width = 0.75)
    } else {
      NULL
    }
    no_line <- if (needs_borders) {
      officer::fp_border(style = "none", width = 0)
    } else {
      NULL
    }
    if (!is.null(vertical_rules)) {
      table <- flextable::vline(
        table,
        border = if (isTRUE(vertical_rules)) line else no_line,
        part = "all"
      )
    }
    if (!is.null(horizontal_rules)) {
      if (horizontal_rules == "none") {
        table <- flextable::hline(table, border = no_line, part = "all")
      } else if (horizontal_rules == "all") {
        table <- flextable::hline(table, border = line, part = "all")
      } else {
        table <- flextable::hline(table, border = no_line, part = "all")
        table <- flextable::hline_top(
          table, border = line, part = "header"
        )
        table <- flextable::hline_bottom(
          table, border = line, part = "header"
        )
        table <- flextable::hline_bottom(
          table, border = line, part = "body"
        )
      }
    }
    if (!is.null(rules$repeat_header)) {
      table <- flextable::paginate(
        table,
        init = isTRUE(rules$repeat_header),
        hdr_ftr = isTRUE(rules$repeat_header)
      )
    }
    table <- flextable::set_table_properties(
      table,
      layout = "fixed"
    )
    applied <- list(
      font_family = family,
      font_size_pt = if (is.finite(font_size)) font_size else NULL,
      header_bold = header_bold,
      vertical_rules = vertical_rules,
      horizontal_rules = horizontal_rules,
      repeat_header = rules$repeat_header %||% NULL
    )
  } else if (system == "kable") {
    if (!has_package("kableExtra")) {
      figspec_abort(
        "Styling a knitr table requires the {.pkg kableExtra} package.",
        "needs_package"
      )
    }
    table <- kableExtra::kable_styling(
      table,
      font_size = if (is.finite(font_size)) font_size else NULL,
      full_width = FALSE
    )
    applied <- list(
      font_size_pt = if (is.finite(font_size)) font_size else NULL
    )
  } else if (system == "grid") {
    table <- style_grid_table(
      table,
      family = family,
      font_size = font_size,
      header_bold = header_bold
    )
    applied <- list(
      font_family = family,
      font_size_pt = if (is.finite(font_size)) font_size else NULL,
      header_bold = header_bold
    )
  }

  evidence <- table_evidence(table, system)
  evidence <- utils::modifyList(
    evidence,
    c(applied, list(transformed = length(applied) > 0L))
  )
  attach_table_evidence(table, evidence, resolved$spec)
}

read_bounded_raw <- function(path, limit = TABLE_TEXT_LIMIT) {
  size <- file.info(path)$size
  if (!is.finite(size) || size > limit) {
    figspec_abort(
      "{.file {basename(path)}} is too large to inspect safely.",
      "bad_input"
    )
  }
  con <- file(path, "rb")
  on.exit(close(con), add = TRUE)
  readBin(con, "raw", n = size)
}

read_bounded_text <- function(path, limit = TABLE_TEXT_LIMIT) {
  rawToChar(read_bounded_raw(path, limit), multiple = FALSE)
}

inspect_docx_table <- function(path) {
  listing <- tryCatch(utils::unzip(path, list = TRUE),
                      error = function(e) NULL)
  too_large <- !is.null(listing) &&
    sum(listing$Length, na.rm = TRUE) > TABLE_ARCHIVE_LIMIT
  too_compressed <- !is.null(listing) &&
    sum(listing$Length, na.rm = TRUE) > max(file.size(path), 1) * 1000
  if (is.null(listing) || !nrow(listing) || too_large || too_compressed) {
    return(list(valid = FALSE, format = "docx", editable = TRUE))
  }
  wanted <- "word/document.xml"
  if (!wanted %in% listing$Name) {
    return(list(valid = FALSE, format = "docx", editable = TRUE))
  }
  length_xml <- listing$Length[listing$Name == wanted][[1]]
  if (length_xml > TABLE_TEXT_LIMIT) {
    return(list(valid = FALSE, format = "docx", editable = TRUE))
  }
  con <- unz(path, wanted, open = "rb")
  on.exit(close(con), add = TRUE)
  xml <- rawToChar(readBin(con, "raw", n = length_xml))
  count <- function(pattern) {
    matches <- gregexpr(pattern, xml, perl = TRUE)[[1]]
    if (identical(matches[[1]], -1L)) 0L else length(matches)
  }
  font_sizes <- regmatches(
    xml,
    gregexpr("w:sz w:val=[\"'][0-9.]+[\"']", xml, perl = TRUE)
  )[[1]]
  font_size <- if (length(font_sizes) && !identical(font_sizes[[1]], "")) {
    values <- as.numeric(gsub("[^0-9.]", "", font_sizes))
    min(values, na.rm = TRUE) / 2
  } else {
    NULL
  }
  fonts <- regmatches(
    xml,
    gregexpr("w:ascii=[\"'][^\"']+[\"']", xml, perl = TRUE)
  )[[1]]
  font_family <- if (length(fonts) && !identical(fonts[[1]], "")) {
    sub(".*=[\"']([^\"']+)[\"'].*", "\\1", fonts[[1]])
  } else {
    NULL
  }
  list(
    valid = grepl("<w:tbl(?:[ >])", xml, perl = TRUE),
    format = "docx",
    editable = TRUE,
    rows = count("<w:tr(?:[ >])"),
    cells = count("<w:tc(?:[ >])"),
    orientation = if (grepl(
      "w:orient=[\"']landscape[\"']", xml, perl = TRUE
    )) "landscape" else "portrait",
    font_size_pt = font_size,
    font_family = font_family
  )
}

inspect_text_table <- function(path, ext) {
  text <- tryCatch(read_bounded_text(path), error = function(e) NULL)
  if (is.null(text)) return(list(valid = FALSE, format = ext))
  count <- function(pattern, ignore.case = FALSE) {
    matches <- gregexpr(
      pattern, text, ignore.case = ignore.case, perl = TRUE
    )[[1]]
    if (identical(matches[[1]], -1L)) 0L else length(matches)
  }
  if (ext %in% c("html", "htm")) {
    size_match <- regexec(
      "font-size\\s*:\\s*([0-9.]+)\\s*(px|pt)",
      text,
      ignore.case = TRUE,
      perl = TRUE
    )
    size_parts <- regmatches(text, size_match)[[1]]
    font_size <- if (length(size_parts) == 3L) {
      value <- as.numeric(size_parts[[2]])
      if (tolower(size_parts[[3]]) == "px") value * 0.75 else value
    } else {
      NULL
    }
    family_match <- regexec(
      "font-family\\s*:\\s*([^;}{]+)",
      text,
      ignore.case = TRUE,
      perl = TRUE
    )
    family_parts <- regmatches(text, family_match)[[1]]
    return(list(
      valid = grepl("<table(?:[ >])", text, ignore.case = TRUE, perl = TRUE),
      format = ext,
      editable = TRUE,
      rows = count("<tr(?:[ >])", TRUE),
      cells = count("<t[dh](?:[ >])", TRUE),
      font_size_pt = font_size,
      font_family = if (length(family_parts) == 2L) {
        trimws(gsub("[\"']", "", strsplit(family_parts[[2]], ",")[[1]][[1]]))
      } else {
        NULL
      }
    ))
  }
  if (ext == "rtf") {
    size_match <- regexec("\\\\fs([0-9]+)", text, perl = TRUE)
    size_parts <- regmatches(text, size_match)[[1]]
    return(list(
      valid = grepl("^\\{\\\\rtf", text),
      format = ext,
      editable = TRUE,
      rows = count("\\\\trowd"),
      orientation = if (grepl("\\\\landscape", text)) {
        "landscape"
      } else {
        "portrait"
      },
      font_size_pt = if (length(size_parts) == 2L) {
        as.numeric(size_parts[[2]]) / 2
      } else {
        NULL
      }
    ))
  }
  size_match <- regexec(
    "\\\\fontsize\\{([0-9.]+)pt\\}",
    text,
    perl = TRUE
  )
  size_parts <- regmatches(text, size_match)[[1]]
  list(
    valid = grepl(
      "\\\\begin\\{(?:tabular\\*?|longtable)\\}",
      text,
      perl = TRUE
    ),
    format = ext,
    editable = TRUE,
    rows = count("\\\\\\\\"),
    repeat_header = if (grepl("longtable", text, fixed = TRUE)) NA else FALSE,
    font_size_pt = if (length(size_parts) == 2L) {
      as.numeric(size_parts[[2]])
    } else {
      NULL
    }
  )
}

inspect_table_file <- function(path) {
  if (!is.character(path) || length(path) != 1L || is.na(path) ||
      !nzchar(trimws(path))) {
    figspec_abort(
      "{.arg x} must be one non-empty table-file path.",
      "bad_input"
    )
  }
  if (!file.exists(path) || dir.exists(path)) {
    figspec_abort(
      "Table file not found: {.file {path}}.",
      "not_found",
      path = path
    )
  }
  ext <- tolower(tools::file_ext(path))
  if (!ext %in% TABLE_FORMATS) {
    figspec_abort(
      c(
        "Unsupported table format: {.val {toupper(ext)}}.",
        "i" = "Use HTML, DOCX, RTF, TeX, PDF, PNG or JPEG."
      ),
      "unsupported",
      format = ext
    )
  }
  if (ext == "docx") return(inspect_docx_table(path))
  if (ext %in% c("html", "htm", "rtf", "tex", "latex")) {
    return(inspect_text_table(path, ext))
  }
  image <- inspect_file(path)
  list(
    valid = image$valid %||% FALSE,
    format = ext,
    editable = FALSE,
    width_mm = image$width_mm %||% NULL,
    height_mm = image$height_mm %||% NULL
  )
}

table_check_row <- function(check, requirement, actual, ok, spec, fields) {
  table_context <- spec
  if (!is.null(table_context)) {
    table_context$not_stated <- table_context$tables_not_stated %||% list()
  }
  fields <- sub("^tables[.]", "", fields)
  fields[fields == "format"] <- "formats"
  graded(check, requirement, actual, ok, table_context, fields)
}

#' Verify a table against a specification
#'
#' Checks a supported live R table or an exported HTML, DOCX, RTF, TeX, PDF,
#' PNG or JPEG table. File checks use the file that was actually written;
#' live-object checks can also use styling evidence that an image or PDF no
#' longer preserves.
#'
#' Requirements that depend on meaning, such as whether a title is concise or
#' every abbreviation is defined, are gathered under unresolved items. Read
#' these parts in context to complete the review.
#'
#' @param x A supported live table or one table-file path.
#' @param spec The specification to use, or NULL for inspection only.
#' @return A figspec table report, with one row per requirement considered.
#' @examples
#' table_check(head(mtcars), list(
#'   name = "Research report",
#'   tables = list(header_bold = TRUE, vertical_rules = FALSE)
#' ))
#' @export
table_check <- function(x, spec = NULL) {
  resolved <- table_rules(spec, required = !is.null(spec))
  rules <- resolved$rules %||% list()
  no_spec <- is.null(resolved$spec)
  live_system <- table_system_or_null(x)
  is_file <- is.null(live_system) && is.character(x) && length(x) == 1L
  system <- if (is_file) "file" else table_system(x)
  info <- if (is_file) inspect_table_file(x) else table_evidence(x, system)
  rule <- function(field) {
    value <- rules[[field]]
    if (is.null(value)) NULL else as.character(value[[1]])
  }
  actual <- function(field) {
    value <- info[[field]]
    if (is.null(value) || !length(value) || is.na(value[[1]])) {
      NULL
    } else {
      as.character(value[[1]])
    }
  }
  rows <- list(new_row(
    "File validity",
    if (is_file) "readable table file" else "readable table object",
    if (isTRUE(info$valid)) "valid" else "invalid",
    if (isTRUE(info$valid)) "pass" else "invalid"
  ))

  formats <- table_rule_formats(rules)
  if (length(formats)) {
    allowed <- if ("editable" %in% formats) {
      unique(c(formats, TABLE_EDITABLE_FORMATS))
    } else {
      formats
    }
    observed_format <- actual("format")
    if (identical(observed_format, "R object")) observed_format <- NULL
    rows[[length(rows) + 1L]] <- table_check_row(
      "File format",
      paste(toupper(formats), collapse = ", "),
      observed_format,
      !is.null(observed_format) &&
        tolower(observed_format) %in% allowed,
      resolved$spec,
      c("tables.formats", "tables.format")
    )
  }
  if (!is.null(rules$editable) || "editable" %in% formats) {
    required_editable <- isTRUE(rules$editable) || "editable" %in% formats
    rows[[length(rows) + 1L]] <- table_check_row(
      "Editable output",
      if (required_editable) "required" else "not required",
      if (is.null(info$editable)) {
        NULL
      } else if (isTRUE(info$editable)) {
        "editable"
      } else {
        "not editable"
      },
      identical(isTRUE(info$editable), required_editable),
      resolved$spec,
      c("tables.editable", "tables.format")
    )
  }
  allowed_fonts <- unlist(rules$font_families %||% list(), use.names = FALSE)
  if (length(allowed_fonts)) {
    observed_font <- actual("font_family")
    rows[[length(rows) + 1L]] <- table_check_row(
      "Font family",
      paste(allowed_fonts, collapse = ", "),
      observed_font,
      !is.null(observed_font) &&
        tolower(observed_font) %in% tolower(allowed_fonts),
      resolved$spec,
      "tables.font_families"
    )
  }

  checks <- list(
    orientation = list(
      "Orientation", function(a, r) tolower(a) == tolower(r)
    ),
    width_max_mm = list(
      "Maximum width", function(a, r) as.numeric(a) <= as.numeric(r)
    ),
    font_min_pt = list(
      "Minimum type size", function(a, r) as.numeric(a) >= as.numeric(r)
    ),
    font_max_pt = list(
      "Maximum type size", function(a, r) as.numeric(a) <= as.numeric(r)
    ),
    header_bold = list(
      "Bold header", function(a, r) identical(tolower(a), tolower(r))
    ),
    vertical_rules = list(
      "Vertical rules", function(a, r) identical(tolower(a), tolower(r))
    ),
    horizontal_rules = list(
      "Horizontal rules", function(a, r) identical(tolower(a), tolower(r))
    ),
    repeat_header = list(
      "Repeated header", function(a, r) identical(tolower(a), tolower(r))
    )
  )
  actual_field <- c(
    orientation = "orientation",
    width_max_mm = "width_mm",
    font_min_pt = "font_size_pt",
    font_max_pt = "font_size_pt",
    header_bold = "header_bold",
    vertical_rules = "vertical_rules",
    horizontal_rules = "horizontal_rules",
    repeat_header = "repeat_header"
  )
  for (field in names(checks)) {
    requirement <- rule(field)
    if (is.null(requirement)) next
    observed <- actual(actual_field[[field]])
    ok <- !is.null(observed) && isTRUE(tryCatch(
      checks[[field]][[2]](observed, requirement),
      error = function(e) FALSE
    ))
    rows[[length(rows) + 1L]] <- table_check_row(
      checks[[field]][[1]],
      requirement,
      observed,
      ok,
      resolved$spec,
      paste0("tables.", field)
    )
  }

  editorial <- c(
    title_style = "Title style",
    title_position = "Title position",
    decimal_alignment = "Decimal alignment",
    footnotes = "Footnotes",
    abbreviations = "Abbreviations",
    split_rows = "Row splitting"
  )
  for (field in names(editorial)) {
    requirement <- rule(field)
    if (!is.null(requirement)) {
      rows[[length(rows) + 1L]] <- new_row(
        editorial[[field]], requirement, "requires review", "unknown"
      )
    }
  }
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  if (no_spec) {
    out$requirement <- NO_SPEC
    out$status <- "unspecified"
    if (is_file && !isTRUE(info$valid)) {
      out$status[out$check == "File validity"] <- "invalid"
    }
  }
  structure(
    out,
    no_spec = no_spec,
    spec_name = resolved$spec$name %||% NULL,
    spec_id = resolved$spec$id %||% NULL,
    source_url = resolved$spec$source_url %||% NULL,
    verified_on = resolved$spec$verified_on %||% NULL,
    publication_stage = resolved$spec$publication_stage %||% NULL,
    input = if (is_file) x else paste0(system, " table object"),
    table_system = system,
    class = c("figspec_table_report", "figspec_report", "data.frame")
  )
}

#' @export
print.figspec_table_report <- function(x, ...) {
  shown <- x
  class(shown) <- c("figspec_report", "data.frame")
  if (is.null(attr(shown, "spec_name"))) {
    attr(shown, "spec_name") <- "Table inspection"
  }
  print(shown, ...)
  invisible(x)
}

write_table_backend <- function(table, path, system, ...) {
  ext <- tolower(tools::file_ext(path))
  dots <- list(...)
  if (length(dots) &&
      (is.null(names(dots)) || any(!nzchar(names(dots))) ||
       anyDuplicated(names(dots)))) {
    figspec_abort(
      "Additional table-export arguments must have unique, non-empty names.",
      "bad_input"
    )
  }
  reserved <- switch(
    system,
    gt = c("data", "filename", "path"),
    flextable = c("x", "Table", "values", "path"),
    kable = c("x", "file", "self_contained"),
    grid = c("filename", "plot", "spec", "check"),
    character()
  )
  conflicts <- intersect(names(dots), reserved)
  if (length(conflicts)) {
    figspec_abort(
      c(
        "An exporter argument cannot replace figspec's protected output settings.",
        "x" = "Reserved argument(s): {.arg {conflicts}}."
      ),
      "bad_input",
      arguments = conflicts
    )
  }
  allowed <- switch(
    system,
    gt = c("html", "htm", "docx", "rtf", "tex", "latex", "pdf", "png"),
    flextable = c("html", "htm", "docx", "rtf", "png"),
    kable = if (identical(attr(table, "format"), "latex")) {
      c("tex", "pdf", "png", "jpg", "jpeg")
    } else if (identical(attr(table, "format"), "html")) {
      c("html", "htm", "pdf", "png", "jpg", "jpeg")
    } else {
      character()
    },
    grid = c("pdf", "png", "jpg", "jpeg"),
    character()
  )
  if (!ext %in% allowed) {
    shown <- if (length(allowed)) {
      paste(toupper(allowed), collapse = ", ")
    } else {
      "none for this object"
    }
    figspec_abort(
      c(
        "A {.val {system}} table cannot be exported as {.val {toupper(ext)}}.",
        "i" = "Available from this table object: {shown}."
      ),
      "unsupported",
      table_system = system,
      format = ext
    )
  }
  if (system == "gt") {
    if (!has_package("gt")) {
      figspec_abort(
        "Exporting this table requires the {.pkg gt} package.",
        "needs_package"
      )
    }
    old_cache <- Sys.getenv("R_USER_CACHE_DIR", unset = NA_character_)
    on.exit(if (is.na(old_cache)) {
      Sys.unsetenv("R_USER_CACHE_DIR")
    } else {
      Sys.setenv(R_USER_CACHE_DIR = old_cache)
    }, add = TRUE)
    cache <- file.path(tempdir(), "figspec-r-cache")
    dir.create(cache, recursive = TRUE, showWarnings = FALSE)
    Sys.setenv(R_USER_CACHE_DIR = cache)
    if (ext == "latex") {
      if (length(dots)) {
        figspec_abort(
          "Exporter arguments are not available for a .latex table.",
          "bad_input"
        )
      }
      writeLines(as.character(gt::as_latex(table)), path, useBytes = TRUE)
    } else {
      do.call(gt::gtsave, c(list(data = table, filename = path), dots))
    }
  } else if (system == "flextable") {
    if (!has_package("flextable")) {
      figspec_abort(
        "Exporting this table requires the {.pkg flextable} package.",
        "needs_package"
      )
    }
    args <- c(list(Table = table), list(path = path), dots)
    saved_spec <- attr(table, "figspec_table_spec", exact = TRUE)
    orientation <- saved_spec$tables$orientation %||% NULL
    if (ext %in% c("docx", "rtf") && !is.null(orientation) &&
        !"pr_section" %in% names(args)) {
      if (!has_package("officer")) {
        figspec_abort(
          "Applying Word or RTF page orientation requires {.pkg officer}.",
          "needs_package"
        )
      }
      args$pr_section <- officer::prop_section(
        page_size = officer::page_size(orient = tolower(orientation))
      )
    }
    if (ext == "docx") {
      do.call(flextable::save_as_docx, args)
    } else if (ext == "rtf") {
      do.call(flextable::save_as_rtf, args)
    } else if (ext %in% c("html", "htm")) {
      do.call(flextable::save_as_html, args)
    } else if (ext == "png") {
      do.call(
        flextable::save_as_image,
        c(list(x = table, path = path), dots)
      )
    } else {
      figspec_abort(
        "flextable cannot export {.val {toupper(ext)}} through figspec.",
        "unsupported"
      )
    }
  } else if (system == "kable") {
    if (!has_package("kableExtra")) {
      figspec_abort(
        "Exporting this table requires the {.pkg kableExtra} package.",
        "needs_package"
      )
    }
    do.call(
      kableExtra::save_kable,
      c(
        list(x = table, file = path, self_contained = TRUE),
        dots
      )
    )
  } else if (system == "grid") {
    draw <- function() grid::grid.draw(table)
    args <- list(
      filename = path,
      plot = draw,
      width = 165,
      height = 100,
      units = "mm",
      check = FALSE
    )
    for (name in names(dots)) args[[name]] <- dots[[name]]
    do.call(fig_save, args)
  } else {
    figspec_abort(
      "No table exporter is available for {.val {system}}.",
      "unsupported"
    )
  }
  invisible(path)
}

promote_table_file <- function(tmp, destination) {
  backup <- NULL
  if (file.exists(destination)) {
    backup <- tempfile(
      ".figspec-table-backup-",
      tmpdir = dirname(destination),
      fileext = paste0(".", tools::file_ext(destination))
    )
    if (!file.rename(destination, backup)) {
      figspec_abort(
        "Could not protect the existing {.file {destination}} before replacement.",
        "bad_input"
      )
    }
  }
  ok <- file.rename(tmp, destination)
  restored <- TRUE
  if (!ok && !is.null(backup)) restored <- file.rename(backup, destination)
  if (!restored) {
    figspec_abort(
      c(
        "Could not place the new table or restore the former output.",
        "i" = "The recoverable former output remains at {.file {backup}}."
      ),
      "bad_input",
      path = destination,
      backup = backup
    )
  }
  if (!ok) {
    figspec_abort(
      "Could not atomically place {.file {destination}}.",
      "bad_input"
    )
  }
  if (!is.null(backup)) unlink(backup)
  invisible(destination)
}

#' Export and verify a table
#'
#' Writes a supported R table to a format available from that table system.
#' When a specification is supplied, figspec applies the supported
#' requirements, writes to a temporary file in the destination directory and
#' reopens that file for verification. After the file passes its structural
#' checks, it is placed at the requested output path.
#'
#' gt tables support HTML, DOCX, RTF, TeX, PDF and PNG. Flextable objects
#' support HTML, DOCX, RTF and PNG. HTML or LaTeX kable objects support their
#' native format and browser- or LaTeX-rendered PDF and images. Grid tables
#' support PDF, PNG and JPEG. Data frames and matrices use gt, except that DOCX
#' and RTF use flextable when it is installed. Formats that need a browser,
#' Pandoc or LaTeX also need those local rendering tools.
#'
#' @param filename Destination file. The extension selects the output format.
#' @param table A supported table object.
#' @param spec The specification to apply and check, or NULL.
#' @param transform Whether to call [table_apply_spec()] before export.
#' @param check Whether to reopen and check the completed file.
#' @param ... Arguments passed to the table system's exporter.
#' @return Invisibly, the output path. A table report is attached when checking
#'   was requested.
#' @examples
#' \dontrun{
#' report_spec <- list(
#'   name = "Research report",
#'   tables = list(formats = "html", font_min_pt = 9,
#'                 header_bold = TRUE, vertical_rules = FALSE)
#' )
#' out <- file.path(tempdir(), "summary-table.html")
#' table_save(out, head(mtcars), report_spec)
#' attr(out, "figspec_table_report")
#' }
#' @export
table_save <- function(filename, table, spec = NULL, transform = TRUE,
                       check = TRUE, ...) {
  if (!is.character(filename) || length(filename) != 1L ||
      is.na(filename) || !nzchar(trimws(filename))) {
    figspec_abort(
      "{.arg filename} must be one non-empty path.",
      "bad_input"
    )
  }
  if (dir.exists(filename)) {
    figspec_abort(
      "The table destination is an existing directory: {.file {filename}}.",
      "bad_input",
      path = filename
    )
  }
  for (value in list(transform, check)) {
    if (!is.logical(value) || length(value) != 1L || is.na(value)) {
      figspec_abort(
        "{.arg transform} and {.arg check} must be TRUE or FALSE.",
        "bad_input"
      )
    }
  }
  ext <- tolower(tools::file_ext(filename))
  if (!ext %in% TABLE_FORMATS) {
    figspec_abort(
      c(
        "Unsupported table output format: {.val {toupper(ext)}}.",
        "i" = "Use HTML, DOCX, RTF, TeX, PDF, PNG or JPEG."
      ),
      "unsupported",
      format = ext
    )
  }
  parent <- dirname(filename)
  if (!dir.exists(parent)) {
    figspec_abort(
      "Output directory does not exist: {.file {parent}}.",
      "not_found"
    )
  }
  resolved <- if (is.null(spec)) {
    NULL
  } else {
    table_rules(spec, required = TRUE)
  }
  rules <- resolved$rules %||% list()
  formats <- table_rule_formats(rules)
  if (length(formats)) {
    allowed <- if ("editable" %in% formats) {
      unique(c(formats, TABLE_EDITABLE_FORMATS))
    } else {
      formats
    }
    if (!ext %in% allowed) {
      warning(
        "'", resolved$spec$name, "' does not list ", toupper(ext),
        " among its table formats (",
        paste(toupper(formats), collapse = ", "), ").",
        call. = FALSE
      )
    }
  }
  source_system <- table_system(table)
  table_for_export <- if (
    source_system %in% c("data_frame", "matrix") &&
      ext %in% c("docx", "rtf") && has_package("flextable")
  ) {
    flextable::flextable(as.data.frame(table, stringsAsFactors = FALSE))
  } else {
    table
  }
  prepared <- if (isTRUE(transform) && !is.null(spec)) {
    table_apply_spec(table_for_export, spec)
  } else {
    table_for_export
  }
  system <- table_system(prepared)
  if (system %in% c("data_frame", "matrix")) {
    if (!has_package("gt")) {
      figspec_abort(
        "Exporting a data frame requires the {.pkg gt} package.",
        "needs_package"
      )
    }
    prepared <- gt::gt(as.data.frame(prepared, stringsAsFactors = FALSE))
    system <- "gt"
  }
  tmp <- tempfile(
    ".figspec-table-",
    tmpdir = parent,
    fileext = paste0(".", ext)
  )
  on.exit(if (file.exists(tmp)) unlink(tmp), add = TRUE)
  write_table_backend(prepared, tmp, system, ...)
  if (!file.exists(tmp) || file.size(tmp) <= 0) {
    figspec_abort(
      "The table renderer did not write a usable {.val {toupper(ext)}} file.",
      "device_failed"
    )
  }
  report <- if (isTRUE(check)) {
    file_report <- table_check(tmp, spec)
    if (!is.null(spec)) {
      object_report <- table_check(prepared, spec)
      merged <- merge_figspec_reports(object_report, file_report)
      attr(merged, "input") <- paste0(system, " table and saved file")
      attr(merged, "table_system") <- system
      class(merged) <- c(
        "figspec_table_report", "figspec_report", "data.frame"
      )
      merged
    } else {
      file_report
    }
  } else {
    NULL
  }
  if (!is.null(report) && any(report$status == "invalid")) {
    figspec_abort(
      "The table renderer produced an invalid file; the destination was not changed.",
      "device_failed",
      path = filename
    )
  }
  promote_table_file(tmp, filename)
  out <- filename
  if (!is.null(report)) {
    attr(report, "input") <- filename
    attr(out, "figspec_table_report") <- report
    problems <- report$status %in% c("fail", "invalid")
    if (any(problems)) {
      warning(
        "Saved table does not meet ", sum(problems),
        " requirement(s): ",
        paste(report$check[problems], collapse = ", "), ".",
        call. = FALSE
      )
    }
  }
  invisible(out)
}
