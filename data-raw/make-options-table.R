# Generates vignettes/options.Rmd from the package's own .Rd files, so the
# option reference cannot drift from the documented arguments.
rd_args <- function(path) {
  rd <- tools::parse_Rd(path)
  tag <- function(x) { t <- attr(x, "Rd_tag"); if (is.null(t)) "" else t }
  tags <- vapply(rd, tag, character(1))
  i <- which(tags == paste0("\\", "arguments"))
  if (!length(i)) return(NULL)
  items <- Filter(function(x) identical(tag(x), paste0("\\", "item")), rd[[i]])
  if (!length(items)) return(NULL)
  do.call(rbind, lapply(items, function(it) {
    flat <- function(z) gsub("[[:space:]]+", " ", paste(unlist(z), collapse = ""))
    data.frame(arg = flat(it[[1]]), desc = trimws(flat(it[[2]])),
               stringsAsFactors = FALSE)
  }))
}

rd_title <- function(path) {
  rd <- tools::parse_Rd(path)
  tag <- function(x) { t <- attr(x, "Rd_tag"); if (is.null(t)) "" else t }
  tags <- vapply(rd, tag, character(1))
  i <- which(tags == paste0("\\", "title"))
  if (!length(i)) return("")
  trimws(gsub("[[:space:]]+", " ", paste(unlist(rd[[i]]), collapse = "")))
}

# An exported name is not always the name of its help page: figspec documents
# scale_colour_figspec() and scale_color_figspec() on one page, and the loop
# below used to look for man/<name>.Rd and silently skip anything it could not
# find. This maps every alias to the file that documents it.
rd_for <- local({
  files <- list.files("man", pattern = "[.]Rd$", full.names = TRUE)
  map <- list()
  for (f in files) {
    al <- gsub("^\\\\alias\\{|\\}[[:space:]]*$", "",
               grep("^\\\\alias\\{", readLines(f, warn = FALSE), value = TRUE))
    for (a in al) map[[a]] <- f
  }
  function(fn) map[[fn]] %||% NA_character_
})
`%||%` <- function(x, y) if (is.null(x)) y else x

option_examples <- yaml::read_yaml("inst/extdata/options-examples.yml")

html_escape <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  gsub('"', "&quot;", x, fixed = TRUE)
}

argument_example <- function(fn, arg) {
  example <- option_examples[[fn]]$arguments[[arg]]
  if (is.null(example)) return("")
  paste0(
    '<details class="fs-argument-example"><summary>See how to use it</summary>',
    '<div class="fs-argument-example-body"><p>', html_escape(example$prose),
    '</p><pre><code class="language-r">', html_escape(example$code),
    '</code></pre><p class="fs-example-result"><strong>Result:</strong> ',
    html_escape(example$result), '</p></div></details>'
  )
}

standalone_example <- function(fn) {
  example <- option_examples[[fn]]$example
  if (is.null(example)) return("")
  paste0(
    '<details class="fs-argument-example fs-function-example">',
    '<summary>See how to use it</summary>',
    '<div class="fs-argument-example-body"><p>', html_escape(example$prose),
    '</p><pre><code class="language-r">', html_escape(example$code),
    '</code></pre><p class="fs-example-result"><strong>Result:</strong> ',
    html_escape(example$result), '</p></div></details>'
  )
}

option_table_html <- function(args, fn) {
  rows <- vapply(seq_len(nrow(args)), function(i) {
    paste0(
      '<tr><td><code>', html_escape(args$arg[[i]]), '</code></td><td>',
      html_escape(args$desc[[i]]), argument_example(fn, args$arg[[i]]),
      '</td></tr>'
    )
  }, character(1))
  c(
    '<table class="table fs-options-table">',
    '<colgroup><col style="width:26%"><col style="width:74%"></colgroup>',
    '<thead><tr><th scope="col">Option</th><th scope="col">What it does</th></tr></thead>',
    '<tbody>', rows, '</tbody></table>'
  )
}

# The canonical name a help page is filed under, so an alias can say which
# function it is the same as.
topic_name <- function(fn) {
  f <- rd_for(fn)
  if (is.na(f)) NA_character_ else sub("[.]Rd$", "", basename(f))
}

ns <- readLines("NAMESPACE")
exported <- gsub("export\\(|\\)", "", grep("^export", ns, value = TRUE))

groups <- list(
  "Building, checking and exporting a figure" = c("fig_save", "fig_check", "fig_geometry",
                            "fig_apply_spec", "fig_preview"),
  "Size and align figures" = c("fig_panel_size", "fig_panel_width"),
  "Apply and reuse visual standards" = c(
    "theme_spec", "style_register", "style_list",
    "style_remove", "style_save", "style_load",
    "fig_tag_panels", "spec_linewidth"
  ),
  "Colour and visual distinction" = c(
    "colour_safety_check", "color_safety_check", "figspec_palettes",
    "figspec_palette", "scale_colour_figspec", "scale_color_figspec",
    "scale_fill_figspec", "scale_shape_figspec", "figspec_shapes",
    "figspec_linetypes", "spec_style_palette"
  ),
  "Find and use specifications" = c(
    "spec_list", "spec_get", "fig_width", "fig_columns",
    "spec_register", "spec_load"
  ),
  "Check collections and publication assets" = c(
    "submission_check", "submission_detail", "fig_suggest_art_type",
    "fig_refit", "table_spec", "media_spec", "media_check",
    "graphical_abstract_spec"
  ),
  "R Markdown and Quarto" = c("figspec_knitr_options", "figspec_knitr_setup"),
  "Maintain trusted registry data" = c(
    "registry_status", "registry_stale_entries", "registry_check_sources",
    "registry_entry_template", "registry_validate_file"
  )
)

# Validate every hand-maintained input before writing anything. The options
# guide is generated, so a missing YAML section or duplicate group entry must
# stop the build instead of quietly producing an incomplete page.
grouped <- unlist(groups, use.names = FALSE)
duplicated_group_entries <- unique(grouped[duplicated(grouped)])
if (length(duplicated_group_entries)) {
  stop(
    "listed in more than one options group: ",
    paste(duplicated_group_entries, collapse = ", "),
    call. = FALSE
  )
}
if (length(setdiff(exported, grouped)) || length(setdiff(grouped, exported))) {
  stop(
    "options groups must contain every export exactly once; missing: ",
    paste(setdiff(exported, grouped), collapse = ", "),
    "; unknown: ", paste(setdiff(grouped, exported), collapse = ", "),
    call. = FALSE
  )
}

canonical_topics <- sort(unique(vapply(exported, topic_name, character(1))))
missing_yaml_topics <- setdiff(canonical_topics, names(option_examples))
extra_yaml_topics <- setdiff(names(option_examples), canonical_topics)
if (length(missing_yaml_topics) || length(extra_yaml_topics)) {
  stop(
    "option-example YAML keys do not match canonical help topics; missing: ",
    paste(missing_yaml_topics, collapse = ", "),
    "; unknown: ", paste(extra_yaml_topics, collapse = ", "),
    call. = FALSE
  )
}

is_text_scalar <- function(x) {
  is.character(x) && length(x) == 1L && !is.na(x) && nzchar(trimws(x))
}
require_example_fields <- function(x, label) {
  fields <- c("prose", "code", "result")
  if (!is.list(x) || !setequal(names(x), fields) || anyDuplicated(names(x)) ||
      !all(vapply(x[fields], is_text_scalar, logical(1)))) {
    stop(label, " must contain exactly one non-empty prose, code and result string", call. = FALSE)
  }
  tryCatch(
    parse(text = x$code),
    error = function(e) stop(label, " contains R code that does not parse: ", conditionMessage(e), call. = FALSE)
  )
}

for (topic in canonical_topics) {
  path <- rd_for(topic)
  args <- rd_args(path)
  example <- option_examples[[topic]]
  required_arguments <- if (is.null(args)) character() else args$arg
  supplied_arguments <- names(example$arguments) %||% character()
  if (!setequal(required_arguments, supplied_arguments) ||
      anyDuplicated(supplied_arguments)) {
    stop(
      topic, "() option examples do not exactly match its documented arguments; ",
      "missing: ", paste(setdiff(required_arguments, supplied_arguments), collapse = ", "),
      "; unknown: ", paste(setdiff(supplied_arguments, required_arguments), collapse = ", "),
      call. = FALSE
    )
  }
  if (!is_text_scalar(example$introduction) || !is_text_scalar(example$setup)) {
    stop(topic, "() needs an introduction and setup", call. = FALSE)
  }
  tryCatch(
    parse(text = example$setup),
    error = function(e) stop(topic, "() setup does not parse: ", conditionMessage(e), call. = FALSE)
  )
  if (!length(required_arguments)) {
    require_example_fields(example$example, paste0(topic, "() no-argument example"))
  } else {
    for (argument in required_arguments) {
      require_example_fields(
        example$arguments[[argument]],
        paste0(topic, "() example for ", argument)
      )
    }
  }
}

# A 26/74 split, written as dashes so pandoc emits the same <colgroup> for
# every table on the page.
OPTION_TABLE_RULE <- paste0("|:", strrep("-", 26), "|:", strrep("-", 74), "|")

out <- c(
  "---", "title: \"All function arguments\"",
  "output: rmarkdown::html_vignette", "vignette: >",
  "  %\\VignetteIndexEntry{All function arguments}",
  "  %\\VignetteEngine{knitr::rmarkdown}", "  %\\VignetteEncoding{UTF-8}", "---", "",
  "The tables on this page list the arguments accepted by figspec's functions and",
  "explain what each argument controls. Use them to compare related functions or",
  "find the setting for a particular task. For complete instructions, return",
  "values and runnable examples, open the function's page in the Reference",
  "section.", ""
)

for (g in names(groups)) {
  out <- c(out, paste("##", g), "")
  for (fn in groups[[g]]) {
    path <- rd_for(fn)
    if (is.na(path) || !file.exists(path)) {
      warning("no help page for ", fn, call. = FALSE)
      next
    }
    args <- rd_args(path)
    canonical <- topic_name(fn)
    out <- c(out, paste0("### `", fn, "()`"), "", rd_title(path), "")
    if (!identical(fn, canonical)) {
      out <- c(out, paste0("The same function as `", canonical,
                           "()`, under the other spelling. Its options are ",
                           "identical."), "")
    }
    examples <- option_examples[[canonical]]
    if (is.null(args)) {
      if (!is.null(examples) && identical(fn, canonical)) {
        out <- c(
          out,
          examples$introduction, "",
          "_This function has no arguments._", "",
          '<details class="fs-function-setup"><summary>Run the example setup</summary>',
          '<div class="fs-argument-example-body"><pre><code class="language-r">',
          html_escape(examples$setup),
          '</code></pre></div></details>', "",
          standalone_example(canonical), ""
        )
      } else {
        out <- c(out, "_This function has no arguments._", "")
      }
      next
    }
    if (!is.null(examples)) {
      missing <- setdiff(args$arg, names(examples$arguments))
      if (length(missing)) {
        stop("missing ", canonical, "() examples for: ",
             paste(missing, collapse = ", "), call. = FALSE)
      }
      if (identical(fn, canonical)) {
        out <- c(
          out,
          examples$introduction, "",
          '<details class="fs-function-setup"><summary>Run the example setup</summary>',
          '<div class="fs-argument-example-body"><pre><code class="language-r">',
          html_escape(examples$setup),
          '</code></pre></div></details>', ""
        )
      }
    }
    # Pandoc sets a table's column widths from the widest cell it finds in the
    # source, so tables with short descriptions came out with a narrow first
    # column and tables with long ones came out wide - no two lined up down
    # the page. A separator row of fixed proportions pins every table to the
    # same 26/74 split.
    if (!is.null(examples) && identical(fn, canonical)) {
      # Raw HTML is deliberate here. A Markdown pipe table cannot contain a
      # multi-line disclosure with readable code without ending the table at
      # the first line break.
      out <- c(out, option_table_html(args, canonical), "")
    } else {
      out <- c(out, "| Option | What it does |", OPTION_TABLE_RULE,
               sprintf("| `%s` | %s |", args$arg,
                       gsub("\\|", "\\\\|", args$desc)), "")
    }
  }
}
# A hand-kept list goes stale silently: the panel-sizing functions were absent
# from this page for a fortnight because nobody added them here. Every export
# is now listed under its own name, aliases included, so the check is exact.
uncovered <- setdiff(exported, unlist(groups, use.names = FALSE))
if (length(uncovered)) {
  stop("not on the options page: ", paste(uncovered, collapse = ", "), call. = FALSE)
}

writeLines(out, "vignettes/options.Rmd")
cat("wrote vignettes/options.Rmd:", length(out), "lines\n")
