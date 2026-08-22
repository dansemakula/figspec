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

ns <- readLines("NAMESPACE")
exported <- gsub("export\\(|\\)", "", grep("^export", ns, value = TRUE))

groups <- list(
  "Fitting a plot to a journal" = c("fit_journal", "theme_journal", "scale_colour_figspec",
                                    "scale_shape_figspec", "figspec_linewidth",
                                    "figspec_shapes", "figspec_linetypes"),
  "Checking"                    = c("check_journal", "check_colour_safety",
                                    "check_submission", "suggest_art_type", "check_media"),
  "Exporting"                   = c("ggsave_journal", "refit_journal", "figspec_preview",
                                    "figspec_chunk_opts", "figspec_knitr_setup"),
  "Looking things up"           = c("journals", "journal_spec", "fig_width", "fig_columns",
                                    "figspec_palettes", "figspec_palette", "table_spec",
                                    "media_spec", "graphical_abstract_spec", "journal_palette"),
  "Your own styles and journals" = c("register_house_style", "house_styles",
                                     "save_house_styles", "register_journal", "load_journals"),
  "Maintaining the registry"     = c("registry_status", "stale_entries",
                                     "new_journal_entry", "validate_registry_file")
)

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
    path <- file.path("man", paste0(fn, ".Rd"))
    if (!file.exists(path)) next
    args <- rd_args(path)
    out <- c(out, paste0("### `", fn, "()`"), "", rd_title(path), "")
    if (is.null(args)) { out <- c(out, "_No options._", ""); next }
    args <- args[args$arg != "...", , drop = FALSE]
    out <- c(out, "| Option | What it does |", "|---|---|",
             sprintf("| `%s` | %s |", args$arg, gsub("\\|", "\\\\|", args$desc)), "")
  }
}
writeLines(out, "vignettes/options.Rmd")
cat("wrote vignettes/options.Rmd:", length(out), "lines\n")
