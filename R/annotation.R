# Structural and typographic conventions ------------------------------------
#
# The rules in this file are the ones about how a figure is put together rather
# than how large it is: how its panels are labelled, whether its axes are drawn,
# how its tick labels are punctuated, what case its text is in, whether its
# axes reach zero.
#
# Two things make these harder to check than a width in millimetres.
#
# First, publishers disagree, so there is no default to fall back on. Nature
# wants panel labels upright and the Royal Society wants them italicised; Cell
# Press wants capitals and AGU wants lower case. Every rule here is therefore
# read from the specification and graded only where one is stated.
#
# Second, the evidence has to be dug out of the plot object, and a wrong guess
# is worse than no answer. A text layer is only read as panel labels when there
# is exactly one label per panel and those labels form a complete sequence,
# because a looser test would read an ordinary annotation as a panel label and
# report a pass nobody earned. Where figspec applied the labels itself,
# tag_panels() leaves a marker so the work can be recognised rather than
# inferred.
#
# The file ends with the rows fig_check() folds into its report.

# Panel labels ------------------------------------------------------------

# A patchwork nests: the object holds the plots composed into it plus itself,
# so counting panels means walking down.
count_panels <- function(plot) {
  if (!inherits(plot, "patchwork")) return(1L)
  kids <- plot$patches$plots
  if (!length(kids)) return(1L)
  patchwork_self(plot) + sum(vapply(kids, count_panels, integer(1)))
}

# A patchwork holds its most recently added plot in its own slots and the
# earlier ones in $patches$plots. When both operands are themselves patchworks,
# as in (a|b|c)/(d|e|f), that slot holds no plot at all and counting it adds a
# panel that does not exist. A real plot there always has at least one layer.
patchwork_self <- function(plot) {
  n <- tryCatch(length(plot$layers), error = function(e) 1L)
  if (is.null(n) || is.na(n) || n == 0L) 0L else 1L
}

# Total visible parts, which is a different question from how many plots were
# composed. A faceted plot is one object drawn as several panels, and a
# publisher limiting "individual parts" means the panels a reader sees. Panel
# LABELS, by contrast, are about composed sub-figures, so count_panels() stays
# composition-only and this counts parts.
#
# Known limit: for a patchwork whose top-level plot is itself faceted, that
# plot contributes 1 rather than its facet count.
count_parts <- function(plot) {
  if (inherits(plot, "patchwork")) {
    kids <- plot$patches$plots
    if (!length(kids)) return(1L)
    return(patchwork_self(plot) + sum(vapply(kids, count_parts, integer(1))))
  }
  n <- tryCatch(length(ggplot2::ggplot_build(plot)$layout$panel_params),
                error = function(e) 1L)
  max(1L, as.integer(n))
}

# What a figure is labelling its panels with, if anything. patchwork calls
# these tag levels: "A" for capitals, "a" for lower case, "1" for numbers,
# "I" or "i" for roman numerals.
#
# A faceted plot has panels too, and a publisher asking for labelled panels
# means the parts a reader sees, not the objects that were composed. But
# facets carry no tag machinery, so the labels have to be found in the layers.
panel_tag_levels <- function(plot) {
  if (inherits(plot, "patchwork")) {
    lv <- plot$patches$annotation$tag_levels
    if (!is.null(lv)) return(as.character(lv)[[1]])
    return(NULL)
  }
  tag <- tryCatch(plot$labels$tag, error = function(e) NULL)
  if (!is.null(tag)) {
    return(if (grepl("^[A-Z]", tag)) "A" else if (grepl("^[a-z]", tag)) "a" else "1")
  }
  facet_tag_levels(plot)
}

# Tags applied by tag_panels() are recorded on the plot, so figspec can always
# recognise its own work. Anything else has to be inferred, and inference here
# is deliberately strict: a text layer counts as panel labels only when it has
# exactly one label per panel AND those labels are a complete tag sequence.
# A looser test would read an ordinary annotation as a panel label and report a
# pass nobody earned.
facet_tag_levels <- function(plot) {
  marked <- tryCatch(attr(plot, "figspec_panel_tags"), error = function(e) NULL)
  if (!is.null(marked)) return(as.character(marked)[[1]])

  n <- tryCatch(length(ggplot2::ggplot_build(plot)$layout$panel_params),
                error = function(e) 0L)
  if (is.null(n) || n < 2L) return(NULL)

  layers <- tryCatch(plot$layers, error = function(e) NULL)
  for (ly in layers %||% list()) {
    if (!inherits(ly$geom, c("GeomText", "GeomLabel"))) next
    d <- tryCatch(ly$data, error = function(e) NULL)
    if (!is.data.frame(d) || nrow(d) != n) next
    lab <- tryCatch(as.character(d[[rlang_label_col(ly, d)]]), error = function(e) NULL)
    lv <- tag_sequence_level(lab)
    if (!is.null(lv)) return(lv)
  }
  NULL
}

# The column a text layer draws from, which may be named by the layer's own
# mapping rather than being called "label".
rlang_label_col <- function(ly, d) {
  m <- tryCatch(ly$mapping$label, error = function(e) NULL)
  nm <- if (!is.null(m)) all.vars(m)[1] else NULL
  if (!is.null(nm) && nm %in% names(d)) return(nm)
  if ("label" %in% names(d)) return("label")
  names(d)[[1]]
}

# Which tag vocabulary a set of labels is, if it is a complete one. Brackets
# and trailing punctuation are conventions around the tag, not part of it.
tag_sequence_level <- function(lab) {
  if (is.null(lab) || anyNA(lab) || !length(lab)) return(NULL)
  bare <- gsub("^[[:punct:][:space:]]+|[[:punct:][:space:]]+$", "", lab)
  n <- length(bare)
  if (n > length(LETTERS)) return(NULL)
  seqs <- list(A = LETTERS[seq_len(n)], a = letters[seq_len(n)],
               `1` = as.character(seq_len(n)),
               I = as.character(utils::as.roman(seq_len(n))),
               i = tolower(as.character(utils::as.roman(seq_len(n)))))
  for (lv in names(seqs)) if (identical(bare, seqs[[lv]])) return(lv)
  NULL
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

# Axis furniture and text colour ------------------------------------------

# Which of the axis lines and tick marks a plot leaves out. ggplot2's default
# theme draws tick marks but no axis line, using the panel border instead, so a
# journal asking for both is a real requirement rather than a formality.
missing_axis_furniture <- function(plot) {
  th <- tryCatch(ggplot2::ggplot_build(plot)$plot$theme, error = function(e) NULL)
  if (is.null(th)) return(NULL)
  blank <- function(el) {
    e <- tryCatch(ggplot2::calc_element(el, th), error = function(e) NULL)
    is.null(e) || inherits(e, "element_blank")
  }
  out <- character(0)
  if (blank("axis.line")) out <- c(out, "axis lines")
  if (blank("axis.ticks")) out <- c(out, "tick marks")
  out
}

# A grey has equal red, green and blue channels, so this catches an actual hue
# rather than any departure from pure black.
is_coloured <- function(col) {
  if (is.null(col) || !length(col) || is.na(col)) return(FALSE)
  m <- tryCatch(grDevices::col2rgb(col), error = function(e) NULL)
  if (is.null(m)) return(FALSE)
  !(m[1] == m[2] && m[2] == m[3])
}

plot_text_colour <- function(plot) {
  th <- tryCatch(ggplot2::ggplot_build(plot)$plot$theme, error = function(e) NULL)
  if (is.null(th)) return(NULL)
  tryCatch(ggplot2::calc_element("text", th)$colour, error = function(e) NULL)
}

# Axis tick label formatting ----------------------------------------------

# Axis labels that use a comma as a thousands separator. The pattern is a digit
# followed by a comma and exactly three digits, which is what scales::comma()
# produces and what a decimal comma would not.
labels_with_comma_thousands <- function(plot) {
  b <- tryCatch(ggplot2::ggplot_build(plot), error = function(e) NULL)
  if (is.null(b)) return(NULL)
  pp <- tryCatch(b$layout$panel_params[[1]], error = function(e) NULL)
  if (is.null(pp)) return(NULL)
  labs <- character(0)
  for (ax in c("x", "y")) {
    l <- tryCatch(pp[[ax]]$get_labels(), error = function(e) NULL)
    if (!is.null(l)) labs <- c(labs, as.character(l))
  }
  labs <- labs[!is.na(labs)]
  unique(labs[grepl("[0-9],[0-9]{3}", labs)])
}

# Background grid ---------------------------------------------------------

# Whether a plot draws bars, which is what BMJ's rule is scoped to. geom_bar
# and geom_histogram both build GeomBar.
has_bar_layer <- function(plot) {
  ls <- tryCatch(plot$layers, error = function(e) NULL)
  if (is.null(ls) || !length(ls)) return(FALSE)
  any(vapply(ls, function(l) inherits(l$geom, "GeomBar"), logical(1)))
}

grid_is_drawn <- function(plot) {
  th <- tryCatch(ggplot2::ggplot_build(plot)$plot$theme, error = function(e) NULL)
  if (is.null(th)) return(NA)
  el <- tryCatch(ggplot2::calc_element("panel.grid", th), error = function(e) NULL)
  if (is.null(el)) return(NA)
  !inherits(el, "element_blank")
}

# Rows shared with fig_check() ----------------------------------------

annotation_rows <- function(plot, spec) {
  rows <- list()

  # Panel labels ----------------------------------------------------------
  # Counted as parts, not as compositions: a three-facet figure shows a reader
  # three panels, and a publisher asking for labelled panels means those.
  # Gating on compositions let every faceted figure past unexamined.
  n_panels <- count_parts(plot)
  if (n_panels > 1L) {
    tag_level <- panel_tag_levels(plot)
    req <- if (!is.null(spec$panel_labels)) {
      paste0("panels labelled with ",
             switch(spec$panel_labels, uppercase = "capital letters",
                    lowercase = "lower-case letters", numbers = "numbers",
                    spec$panel_labels))
    } else NULL
    actual <- if (is.null(tag_level)) {
      paste0(n_panels, " panels, none labelled")
    } else {
      paste0(n_panels, " panels labelled with ",
             switch(tag_level, A = "capital letters", a = "lower-case letters",
                    `1` = "numbers", I = "roman numerals", i = "roman numerals",
                    tag_level))
    }
    # Publishers differ: Cell Press asks for capital letters, AGU for lower
    # case. Match the entry's own wording rather than assuming capitals.
    wanted <- switch(spec$panel_labels %||% "",
      uppercase = "A", lowercase = "a", numbers = "1", NULL)
    ok <- !is.null(tag_level) && (is.null(wanted) || identical(tag_level, wanted))
    rows[[length(rows) + 1L]] <- graded("Panel labels", req, actual, ok)
  }

  # Panel count -----------------------------------------------------------
  if (!is.null(spec$max_panels)) {
    n_parts <- count_parts(plot)
    rows[[length(rows) + 1L]] <- graded(
      "Panel count",
      paste0("no more than ", spec$max_panels, " parts in a composite figure"),
      paste0(n_parts, " part", if (n_parts != 1L) "s" else ""),
      n_parts <= as.numeric(spec$max_panels)
    )
  }

  # Axis lines and tick marks ---------------------------------------------
  if (isTRUE(spec$axis_lines_and_ticks)) {
    missing_bits <- missing_axis_furniture(plot)
    if (!is.null(missing_bits)) {
      rows[[length(rows) + 1L]] <- graded(
        "Axis furniture", "axis lines and tick marks included",
        if (length(missing_bits)) {
          paste0("missing ", paste(missing_bits, collapse = " and "))
        } else {
          "axis lines and tick marks present"
        },
        length(missing_bits) == 0
      )
    }
  }

  # Text colour -----------------------------------------------------------
  if (isTRUE(spec$avoid_coloured_text)) {
    col <- plot_text_colour(plot)
    rows[[length(rows) + 1L]] <- graded(
      "Text colour", "text not coloured",
      if (is.null(col)) NULL else paste0("text is ", col),
      !is.null(col) && !is_coloured(col)
    )
  }

  # Background grid -------------------------------------------------------
  # Scoped to bar and histogram layers, because that is how BMJ scopes it.
  if (isTRUE(spec$no_background_grid) && has_bar_layer(plot)) {
    drawn <- grid_is_drawn(plot)
    rows[[length(rows) + 1L]] <- graded(
      "Background grid", "histograms drawn with no background grid",
      if (is.na(drawn)) NULL else if (drawn) "background grid is drawn" else "no background grid",
      !is.na(drawn) && !drawn
    )
  }

  # Number formatting -----------------------------------------------------
  if (!is.null(spec$thousands_separator)) {
    commas <- labels_with_comma_thousands(plot)
    if (!is.null(commas)) {
      rows[[length(rows) + 1L]] <- graded(
        "Number format",
        paste0("thousands separated by ", spec$thousands_separator, ", not commas"),
        if (length(commas)) {
          paste0("comma used in axis label", if (length(commas) > 1) "s" else "",
                 ": ", paste(utils::head(commas, 3), collapse = ", "),
                 if (length(commas) > 3) paste0(" and ", length(commas) - 3, " more") else "")
        } else {
          "no comma thousands separators in axis labels"
        },
        length(commas) == 0
      )
    }
  }

  # Axis origin -----------------------------------------------------------
  if (isTRUE(spec$axes_from_zero)) {
    missing_zero <- axes_missing_zero(plot)
    if (!is.null(missing_zero)) {
      rows[[length(rows) + 1L]] <- graded(
        "Axis origin", "numerical axes reach zero, except log axes",
        if (length(missing_zero)) {
          paste0(paste(toupper(missing_zero), collapse = " and "),
                 " axis does not reach zero")
        } else {
          "all numerical axes reach zero"
        },
        length(missing_zero) == 0
      )
    }
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

# Axis origin -------------------------------------------------------------

# Which continuous axes exclude zero. Log axes are exempt: zero is not on a
# log scale at all. Discrete axes are not numeric, so the rule cannot apply.
axes_missing_zero <- function(plot) {
  b <- tryCatch(ggplot2::ggplot_build(plot), error = function(e) NULL)
  if (is.null(b)) return(NULL)
  pp <- tryCatch(b$layout$panel_params[[1]], error = function(e) NULL)
  if (is.null(pp)) return(NULL)

  out <- character(0)
  for (ax in c("x", "y")) {
    rng <- pp[[paste0(ax, ".range")]]
    if (is.null(rng) || length(rng) != 2L || anyNA(rng)) next
    sc <- tryCatch(pp[[ax]]$scale, error = function(e) NULL)
    if (is.null(sc) || inherits(sc, "ScaleDiscretePosition")) next
    trans <- tryCatch(pp[[ax]]$scale$trans$name, error = function(e) NULL)
    if (!is.null(trans) && grepl("log", trans, ignore.case = TRUE)) next
    if (rng[1] > 0 || rng[2] < 0) out <- c(out, ax)
  }
  out
}
