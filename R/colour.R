# Extracting what a plot actually draws -----------------------------------

# The colours a plot maps data to, taken from the built plot rather than the
# grob tree, so theme furniture (grey panels, black text) is not mistaken for
# a data colour.
plot_colours <- function(plot) {
  built <- tryCatch(ggplot2::ggplot_build(plot)$data, error = function(e) NULL)
  if (is.null(built)) return(character(0))
  layers <- tryCatch(plot$layers, error = function(e) NULL)

  cols <- character(0)
  for (i in seq_along(built)) {
    d <- built[[i]]
    cols <- c(cols, d$colour)
    # A layer can carry a fill it never draws. geom_smooth(se = FALSE) is the
    # common case: the ribbon fill is still in the built data but nothing is
    # painted with it, and reporting it as a figure colour would be a false
    # alarm.
    draws_fill <- TRUE
    if (!is.null(layers) && i <= length(layers)) {
      se <- layers[[i]]$geom_params$se
      if (!is.null(se) && identical(se, FALSE)) draws_fill <- FALSE
    }
    if (draws_fill) cols <- c(cols, d$fill)
  }
  cols <- cols[!is.na(cols)]
  cols <- cols[!cols %in% c("NA", "transparent", "none")]
  unique(cols)
}

# Line widths a plot draws, converted from ggplot2's linewidth units to the
# points that publishers state.
plot_linewidths <- function(plot) {
  built <- ggplot2::ggplot_build(plot)$data
  lw <- unlist(lapply(built, function(d) d$linewidth))
  lw <- lw[!is.na(lw) & lw > 0]
  if (!length(lw)) return(numeric(0))
  sort(unique(ggplot_linewidth_to_pt(lw)))
}

# How many data series a plot draws. ggplot2 assigns each series a group, and
# leaves group at -1 when nothing is grouped.
plot_series_count <- function(plot) {
  built <- tryCatch(ggplot2::ggplot_build(plot)$data, error = function(e) NULL)
  if (is.null(built)) return(0L)
  grp <- unlist(lapply(built, function(d) d$group))
  grp <- grp[!is.na(grp) & grp > 0]
  length(unique(grp))
}

plot_linetypes <- function(plot) {
  built <- ggplot2::ggplot_build(plot)$data
  lt <- unlist(lapply(built, function(d) d$linetype))
  unique(lt[!is.na(lt)])
}

# Colour analysis ---------------------------------------------------------

#' @keywords internal
#' @noRd
hue_of <- function(cols) {
  m <- grDevices::col2rgb(cols)
  hsv <- grDevices::rgb2hsv(m)
  list(h = hsv["h", ] * 360, s = hsv["s", ], v = hsv["v", ])
}

# Reds and greens, ignoring colours too washed out or too dark to read as
# either. The bands are deliberately generous: the point is to catch a palette
# that leans on a red/green contrast, not to adjudicate borderline hues.
is_reddish <- function(cols) {
  x <- hue_of(cols)
  (x$h >= 330 | x$h <= 20) & x$s > 0.25 & x$v > 0.2
}

is_greenish <- function(cols) {
  x <- hue_of(cols)
  x$h >= 75 & x$h <= 165 & x$s > 0.25 & x$v > 0.2
}

# Perceptual distance between every pair, in whatever space the colours have
# already been transformed into.
pairwise_delta_e <- function(cols) {
  if (length(cols) < 2) return(NULL)
  rgbm <- farver::decode_colour(cols)
  d <- farver::compare_colour(rgbm, rgbm, from_space = "rgb", method = "cie2000")
  dimnames(d) <- list(cols, cols)
  d
}

# Pairs that fall below the discrimination threshold once transformed.
close_pairs <- function(original, transformed, threshold) {
  d <- pairwise_delta_e(transformed)
  if (is.null(d)) return(data.frame())
  out <- list()
  for (i in seq_len(nrow(d) - 1L)) {
    for (j in seq(i + 1L, ncol(d))) {
      if (d[i, j] < threshold) {
        out[[length(out) + 1L]] <- data.frame(
          a = original[i], b = original[j], delta_e = d[i, j],
          stringsAsFactors = FALSE
        )
      }
    }
  }
  if (!length(out)) return(data.frame())
  do.call(rbind, out)
}

# A crowded figure can produce dozens of merged pairs, and printing every one
# buries the finding it is meant to communicate. Name a few and count the rest.
list_pairs <- function(pairs, max_shown = 4) {
  labels <- sprintf("%s/%s", pairs$a, pairs$b)
  if (length(labels) <= max_shown) return(paste(labels, collapse = ", "))
  paste0(paste(labels[seq_len(max_shown)], collapse = ", "),
         " and ", length(labels) - max_shown, " more")
}

to_greyscale <- function(cols) {
  if (requireNamespace("colorspace", quietly = TRUE)) {
    return(colorspace::desaturate(cols))
  }
  # Relative luminance, the same weighting used for contrast ratios.
  m <- grDevices::col2rgb(cols) / 255
  lin <- ifelse(m <= 0.03928, m / 12.92, ((m + 0.055) / 1.055)^2.4)
  y <- 0.2126 * lin[1, ] + 0.7152 * lin[2, ] + 0.0722 * lin[3, ]
  srgb <- ifelse(y <= 0.0031308, y * 12.92, 1.055 * y^(1 / 2.4) - 0.055)
  grDevices::rgb(srgb, srgb, srgb)
}

simulate_cvd <- function(cols, type) {
  if (!requireNamespace("colorspace", quietly = TRUE)) return(NULL)
  switch(type,
    deuteranopia = colorspace::deutan(cols),
    protanopia = colorspace::protan(cols),
    tritanopia = colorspace::tritan(cols),
    NULL
  )
}

#' Check a figure's colours for safety in print and for colour-blind readers
#'
#' Reports three things about the colours a plot maps data to: whether it
#' relies on a red/green contrast, whether its colours stay distinguishable in
#' greyscale, and whether they stay distinguishable to readers with the common
#' forms of colour vision deficiency.
#'
#' Only the first two are ever stated as requirements, and only by some
#' publishers: Cell Press states that red and green should not be used
#' together, and the Royal Society states that figures are reproduced in black
#' and white in print by default. The colour-vision result is reported for
#' every journal but is marked `unspecified` unless the publisher states it,
#' because it is advice rather than a rule.
#'
#' @param plot A ggplot object.
#' @param journal Registry id.
#' @param threshold Perceptual distance (CIE Delta-E 2000) below which two
#'   colours are treated as too close to tell apart. Defaults to 10, the point
#'   at which two colours read as clearly different rather than as shades of
#'   one another. This is a judgement of figspec's, not a journal requirement,
#'   and you can raise it if you want a stricter figure.
#' @return A `figspec_report`.
#' @examples
#' library(ggplot2)
#' p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) + geom_point()
#' check_colour_safety(p, "cell_press")
#' @export
check_colour_safety <- function(plot, journal, threshold = 10) {
  if (!is_ggplot_object(plot)) {
    figspec_abort(
      c("{.arg plot} must be a ggplot object.",
        "i" = "Colours cannot be recovered reliably from a saved figure -
               compression and colour conversion have already changed them."),
      "bad_input")
  }
  spec <- journal_spec(journal)
  cols <- plot_colours(plot)
  rows <- colour_rows(cols, spec, threshold, plot)
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  structure(
    out,
    journal = spec$name, journal_id = spec$id,
    source_url = spec$source_url, verified_on = spec$verified_on,
    input = "ggplot object", colours = cols,
    class = c("figspec_report", "data.frame")
  )
}

#' @rdname check_colour_safety
#' @export
check_color_safety <- check_colour_safety

# Shared by check_colour_safety() and fig_check().
colour_rows <- function(cols, spec, threshold = 10, plot = NULL) {
  rows <- list()

  if (!length(cols)) {
    rows[[1]] <- new_row("Colour", UNSTATED,
                         "no data colours found", "unspecified")
    return(rows)
  }

  # Red/green together ----------------------------------------------------
  wants_pair_check <- !is.null(spec$avoid_colour_pairs)
  has_rg <- any(is_reddish(cols)) && any(is_greenish(cols))
  rg_actual <- if (has_rg) {
    paste0("red and green both used (",
           paste(unique(c(cols[is_reddish(cols)], cols[is_greenish(cols)])),
                 collapse = ", "), ")")
  } else {
    "no red/green pairing"
  }
  rows[[length(rows) + 1L]] <- if (wants_pair_check) {
    new_row("Colour pairs", "red and green not used together", rg_actual,
            if (has_rg) "fail" else "pass")
  } else {
    new_row("Colour pairs", UNSTATED, rg_actual, "unspecified")
  }

  # Greyscale -------------------------------------------------------------
  grey_pairs <- close_pairs(cols, to_greyscale(cols), threshold)
  grey_actual <- if (nrow(grey_pairs)) {
    paste0(nrow(grey_pairs), " pair(s) merge in greyscale: ",
           list_pairs(grey_pairs))
  } else {
    "all colours separable in greyscale"
  }
  rows[[length(rows) + 1L]] <- if (isTRUE(spec$print_greyscale)) {
    new_row("Greyscale", "must remain readable in black and white",
            grey_actual, if (nrow(grey_pairs)) "fail" else "pass")
  } else {
    new_row("Greyscale", UNSTATED, grey_actual, "unspecified")
  }

  # Colour vision deficiency ----------------------------------------------
  if (!requireNamespace("colorspace", quietly = TRUE)) {
    rows[[length(rows) + 1L]] <- new_row(
      "Colour vision", UNSTATED,
      "install colorspace to test", "unknown"
    )
  } else {
    hits <- character(0)
    for (type in c("deuteranopia", "protanopia", "tritanopia")) {
      sim <- simulate_cvd(cols, type)
      p <- close_pairs(cols, sim, threshold)
      if (nrow(p)) hits <- c(hits, paste0(type, " (", nrow(p), ")"))
    }
    cvd_actual <- if (length(hits)) {
      paste0("colours merge under ", paste(hits, collapse = ", "))
    } else {
      "separable under deuteranopia, protanopia and tritanopia"
    }
    rows[[length(rows) + 1L]] <- new_row(
      "Colour vision", UNSTATED, cvd_actual, "unspecified"
    )
  }

  # Series count ----------------------------------------------------------
  # Only reported where a publisher names a limit. Some do, but call it a
  # recommendation, so it is never graded: the wording carries the comparison
  # instead. Where nobody names a limit there is nothing to say, and a bare
  # "3 series" would be a measurement rather than a finding. Every other
  # advisory row here reports something the reader can act on; this one would
  # not. A figure with too many series shows up anyway, as colours that merge
  # in greyscale or under colour vision deficiency.
  rec <- spec$max_series_recommended
  if (!is.null(plot) && !is.null(rec)) {
    n_series <- plot_series_count(plot)
    if (n_series > 0) {
      rows[[length(rows) + 1L]] <- new_row(
        "Series count",
        paste0("no more than ", rec, " series (recommended, not required)"),
        paste0(n_series, " series, ",
               if (n_series > as.numeric(rec)) {
                 paste0("above the ", rec, " recommended")
               } else {
                 paste0("within the ", rec, " recommended")
               }),
        "unspecified"
      )
    }
  }

  # Whether anything other than colour distinguishes the series ------------
  if (!is.null(plot)) {
    lts <- plot_linetypes(plot)
    shp <- plot_shapes(plot)
    n_shapes <- shp$n_shapes %||% 0
    other_cue <- length(lts) > 1L || n_shapes > 1L
    if (length(cols) > 2 && !other_cue && (nrow(grey_pairs) > 0 || has_rg)) {
      rows[[length(rows) + 1L]] <- new_row(
        "Redundant coding", UNSTATED,
        "colour is the only cue: all series share one shape and one line type",
        "unspecified"
      )
    } else if (length(cols) > 2 && other_cue && nrow(grey_pairs) > 0) {
      rows[[length(rows) + 1L]] <- new_row(
        "Redundant coding", UNSTATED,
        paste0("colours merge in greyscale but ",
               if (n_shapes > 1L) paste0(n_shapes, " shapes") else paste0(length(lts), " line types"),
               " still separate the series"),
        "unspecified"
      )
    }
  }
  rows
}

# The colour checks read the colours a plot assigns to its series. A saved file
# has no series - a raster has anti-aliased pixels, and even a vector file
# records paint without recording which layer asked for it - so none of these
# questions can be answered from a file.
#
# They are still reported. A check that quietly disappears reads as a check
# that passed, and the difference between "your colours are fine" and "nobody
# looked at your colours" is the difference this package exists to keep. The
# requirement still comes from the journal; only the answer is missing.
colour_rows_unmeasurable <- function(spec) {
  rows <- list()

  rows[[1]] <- graded(
    "Colour pairs",
    if (!is.null(spec$avoid_colour_pairs)) "red and green not used together" else NULL,
    NULL, NA, spec, "avoid_colour_pairs"
  )
  rows[[2]] <- graded(
    "Greyscale",
    if (isTRUE(spec$print_greyscale)) "must remain readable in black and white" else NULL,
    NULL, NA, spec, "print_greyscale"
  )
  # Neither of these is stated by any publisher in the registry, so they are
  # reported rather than graded whatever the input. What changes for a file is
  # that there is nothing to report either.
  rows[[3]] <- new_row("Colour vision", UNSTATED, "could not determine", "unspecified")
  rows[[4]] <- new_row("Redundant coding", UNSTATED, "could not determine", "unspecified")
  rows
}
