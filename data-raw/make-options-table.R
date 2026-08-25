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

# The canonical name a help page is filed under, so an alias can say which
# function it is the same as.
topic_name <- function(fn) {
  f <- rd_for(fn)
  if (is.na(f)) NA_character_ else sub("[.]Rd$", "", basename(f))
}

ns <- readLines("NAMESPACE")
exported <- gsub("export\\(|\\)", "", grep("^export", ns, value = TRUE))

groups <- list(
  "Fitting a plot to a journal" = c("fit_journal", "theme_journal", "scale_colour_figspec",
                                    "scale_color_figspec", "scale_fill_figspec",
                                    "scale_shape_figspec", "figspec_linewidth",
                                    "figspec_shapes", "figspec_linetypes"),
  "Checking"                    = c("fig_check", "check_colour_safety", "check_color_safety",
                                    "check_submission", "submission_detail",
                                    "suggest_art_type", "check_media"),
  "Sizing and exporting"        = c("fig_save", "fig_panel_size", "fig_panel_width",
                                    "fig_geometry", "refit_journal", "figspec_preview",
                                    "figspec_chunk_opts", "figspec_knitr_setup"),
  "Labelling panels"            = c("tag_panels"),
  "Looking things up"           = c("journals", "journal_spec", "fig_width", "fig_columns",
                                    "figspec_palettes", "figspec_palette", "table_spec",
                                    "media_spec", "graphical_abstract_spec", "journal_palette"),
  "Your own styles and journals" = c("register_house_style", "house_styles",
                                     "remove_house_style", "save_house_styles", "load_house_styles",
                                     "register_journal", "load_journals"),
  "Maintaining the registry"     = c("registry_status", "stale_entries", "check_sources",
                                     "new_journal_entry", "validate_registry_file")
)

# A 26/74 split, written as dashes so pandoc emits the same <colgroup> for
# every table on the page.
OPTION_TABLE_RULE <- paste0("|:", strrep("-", 26), "|:", strrep("-", 74), "|")

out <- c(
  "---", "title: \"Every function and what its options do\"",
  "output: rmarkdown::html_vignette", "vignette: >",
  "  %\\VignetteIndexEntry{Every function and what its options do}",
  "  %\\VignetteEngine{knitr::rmarkdown}", "  %\\VignetteEncoding{UTF-8}", "---", "",
  "This page is generated from the package's own documentation, so it stays in",
  "step with the functions themselves. Each entry lists what the function is for",
  "and what every one of its options does.", ""
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
    if (is.null(args)) { out <- c(out, "_No options._", ""); next }
    args <- args[args$arg != "...", , drop = FALSE]
    # Pandoc sets a table's column widths from the widest cell it finds in the
    # source, so tables with short descriptions came out with a narrow first
    # column and tables with long ones came out wide - no two lined up down
    # the page. A separator row of fixed proportions pins every table to the
    # same 26/74 split.
    out <- c(out, "| Option | What it does |", OPTION_TABLE_RULE,
             sprintf("| `%s` | %s |", args$arg, gsub("\\|", "\\\\|", args$desc)), "")
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
