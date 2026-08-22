# Panel labels ------------------------------------------------------------

# A patchwork nests: the object holds the plots composed into it plus itself,
# so counting panels means walking down.
count_panels <- function(plot) {
  if (!inherits(plot, "patchwork")) return(1L)
  kids <- plot$patches$plots
  if (!length(kids)) return(1L)
  1L + sum(vapply(kids, count_panels, integer(1)))
}

# What a composition is labelling its panels with, if anything. patchwork
# calls these tag levels: "A" for capitals, "a" for lower case, "1" for
# numbers, "I" or "i" for roman numerals.
panel_tag_levels <- function(plot) {
  if (inherits(plot, "patchwork")) {
    lv <- plot$patches$annotation$tag_levels
    if (!is.null(lv)) return(as.character(lv)[[1]])
    return(NULL)
  }
  tag <- tryCatch(plot$labels$tag, error = function(e) NULL)
  if (is.null(tag)) return(NULL)
  if (grepl("^[A-Z]", tag)) "A" else if (grepl("^[a-z]", tag)) "a" else "1"
}

# Text case ---------------------------------------------------------------

# The text a reader sees: axis titles, plot titles and legend titles.
plot_label_text <- function(plot) {
  labs <- tryCatch(plot$labels, error = function(e) NULL)
  if (is.null(labs) || !length(labs)) return(character(0))
  drop <- c("tag")
  labs <- labs[setdiff(names(labs), drop)]
  vals <- unlist(labs)
  vals <- vals[!is.na(vals) & nzchar(vals)]
  vals[vapply(vals, is.character, logical(1)) | TRUE]
}

# Words that read as acronyms or units rather than sentence-case violations.
looks_like_acronym <- function(word) {
  clean <- gsub("[^A-Za-z0-9]", "", word)
  nchar(clean) == 0 ||
    clean == toupper(clean) ||        # CO2, BMI, SD
    nchar(clean) <= 3                  # per, of, the, and short units
}

# Deliberately conservative: only flag a label when at least two substantial,
# non-acronym words are capitalised, which is Title Case rather than an
# ordinary proper noun.
is_title_case <- function(x) {
  words <- strsplit(x, "\\s+")[[1]]
  if (length(words) < 2) return(FALSE)
  caps <- words[grepl("^[A-Z]", words) & !vapply(words, looks_like_acronym, logical(1))]
  length(caps) >= 2
}

has_final_stop <- function(x) grepl("\\.\\s*$", x) & !grepl("\\.\\.\\.\\s*$", x)

starts_lower <- function(x) grepl("^[a-z]", x)

# Rows shared with check_journal() ----------------------------------------

annotation_rows <- function(plot, spec) {
  rows <- list()

  # Panel labels ----------------------------------------------------------
  n_panels <- count_panels(plot)
  if (n_panels > 1L) {
    tag_level <- panel_tag_levels(plot)
    req <- if (!is.null(spec$panel_labels)) {
      paste0("panels labelled with ", spec$panel_labels, " letters")
    } else NULL
    actual <- if (is.null(tag_level)) {
      paste0(n_panels, " panels, none labelled")
    } else {
      paste0(n_panels, " panels labelled with ",
             switch(tag_level, A = "capital letters", a = "lower-case letters",
                    `1` = "numbers", I = "roman numerals", i = "roman numerals",
                    tag_level))
    }
    ok <- !is.null(tag_level) &&
      (!identical(spec$panel_labels, "uppercase") || identical(tag_level, "A"))
    rows[[length(rows) + 1L]] <- graded("Panel labels", req, actual, ok)
  }

  # Text case -------------------------------------------------------------
  labels <- plot_label_text(plot)
  states_rule <- identical(spec$text_case, "sentence") || isTRUE(spec$text_no_final_stop)
  if (length(labels) && !states_rule) {
    # The publisher states no rule, so nothing was tested. Saying the labels
    # "follow sentence case" would be a verdict we never reached.
    rows[[length(rows) + 1L]] <- new_row(
      "Text case", UNSTATED,
      paste0(length(labels), " label(s), not checked"), "unspecified"
    )
  } else if (length(labels)) {
    problems <- character(0)
    if (isTRUE(spec$text_no_final_stop)) {
      hits <- labels[has_final_stop(labels)]
      if (length(hits)) {
        problems <- c(problems, paste0("ends with a full stop: ",
                                       paste(sQuote(hits), collapse = ", ")))
      }
    }
    if (identical(spec$text_case, "sentence")) {
      low <- labels[starts_lower(labels)]
      if (length(low)) {
        problems <- c(problems, paste0("does not start with a capital: ",
                                       paste(sQuote(low), collapse = ", ")))
      }
      title_case <- labels[vapply(labels, is_title_case, logical(1))]
      if (length(title_case)) {
        problems <- c(problems, paste0("uses Title Case: ",
                                       paste(sQuote(title_case), collapse = ", ")))
      }
    }
    req <- "sentence case, first letter capitalised, no final full stop"
    actual <- if (length(problems)) {
      paste(problems, collapse = "; ")
    } else {
      paste0(length(labels), " label(s) follow sentence case")
    }
    rows[[length(rows) + 1L]] <- graded("Text case", req, actual, !length(problems))
  }

  rows
}
