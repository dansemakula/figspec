# Colour safety -------------------------------------------------------------
#
# Three things can go wrong with the colours in a figure, and only the first is
# ever a stated requirement:
#
#   1. a red/green pair, which some publishers name explicitly
#   2. colours that merge when the figure is printed in black and white
#   3. colours that merge for a reader with colour vision deficiency
#
# All three reduce to the same question: after some transformation, are two of
# these colours still far enough apart to tell apart? That distance is measured
# as CIE Delta-E 2000, the standard perceptual difference metric, where roughly
# 1.0 is the smallest difference a person can notice and figspec's default
# threshold of 10 is a comfortable margin. Ordinary RGB distance will not do:
# two colours can be far apart numerically and look identical.
#
# The transformations are: desaturation for print, and simulated deuteranopia,
# protanopia and tritanopia for colour vision. Comparing the transformed
# colours while reporting the original ones is why close_pairs() takes both.
#
# Only the colours a plot maps *data* to are examined. Theme furniture - grey
# panels, black text, white backgrounds - would otherwise show up as merged
# pairs in every figure.

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

# Hue, saturation and value for a vector of colours.
#
# @param cols Character vector of colours.
# @return A list of `h` in degrees (0-360), and `s` and `v` in 0-1.
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

# Perceptual distance between every pair of colours.
#
# Uses CIE Delta-E 2000, which weights differences the way the eye does, so
# that a threshold means the same thing across the spectrum. The caller passes
# colours that have already been transformed, so this is unaware of whether it
# is comparing originals, desaturated versions or a simulation.
#
# @param cols Character vector of colours.
# @return A square matrix of distances, named on both margins, or NULL when
#   there are fewer than two colours to compare.
pairwise_delta_e <- function(cols) {
  if (length(cols) < 2) return(NULL)
  rgbm <- farver::decode_colour(cols)
  d <- farver::compare_colour(rgbm, rgbm, from_space = "rgb", method = "cie2000")
  dimnames(d) <- list(cols, cols)
  d
}

# Pairs that become too similar once transformed.
#
# Takes both vectors because the comparison and the reporting want different
# things: the distance must be measured on the transformed colours, but the
# user needs to be told which of *their* colours are the problem.
#
# @param original The colours as the plot uses them.
# @param transformed The same colours after desaturation or CVD simulation,
#   in the same order.
# @param threshold Delta-E below which two colours count as merged.
# @return A data frame of `a`, `b` and `delta_e`, empty if none merge.
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

# Convert colours to how they would print in black and white.
#
# Uses colorspace's desaturation where it is installed, which is more faithful.
# The fallback is relative luminance under the WCAG definition - the same
# weighting used for text contrast ratios - which linearises each channel,
# weights them by how much the eye contributes to brightness, and re-encodes
# the result as a grey.
#
# @param cols Character vector of colours.
# @return Character vector of greys, same length and order.
to_greyscale <- function(cols) {
  if (has_package("colorspace")) {
    return(colorspace::desaturate(cols))
  }
  # Relative luminance, the same weighting used for contrast ratios.
  m <- grDevices::col2rgb(cols) / 255
  lin <- ifelse(m <= 0.03928, m / 12.92, ((m + 0.055) / 1.055)^2.4)
  y <- 0.2126 * lin[1, ] + 0.7152 * lin[2, ] + 0.0722 * lin[3, ]
  srgb <- ifelse(y <= 0.0031308, y * 12.92, 1.055 * y^(1 / 2.4) - 0.055)
  grDevices::rgb(srgb, srgb, srgb)
}

# Colours as they appear to a reader with a colour vision deficiency.
#
# @param cols Character vector of colours.
# @param type One of "deuteranopia", "protanopia" or "tritanopia".
# @return Character vector of simulated colours, or NULL when colorspace is not
#   installed, in which case the check reports that it could not be run rather
#   than reporting a pass.
simulate_cvd <- function(cols, type) {
  if (!has_package("colorspace")) return(NULL)
  switch(type,
    deuteranopia = colorspace::deutan(cols),
    protanopia = colorspace::protan(cols),
    tritanopia = colorspace::tritan(cols),
    NULL
  )
}

#' Check whether a figure's colours remain distinguishable
#'
#' Examines the colours used to represent data before the figure is exported.
#' The report shows whether the plot uses a prohibited colour pairing, whether
#' its colours remain distinguishable in greyscale, and how they appear under
#' three common forms of colour-vision deficiency. If colours become difficult
#' to tell apart, the report also notes whether shape or line type gives readers
#' another way to identify the groups.
#'
#' When the selected specification states a colour or reproduction rule,
#' figspec reports a pass or fail against that rule. Other findings appear as
#' guidance with an `unspecified` status, keeping the source requirements and
#' the general accessibility review clearly separated.
#'
#' @param plot A ggplot object. Use the editable plot rather than an exported
#'   file so that figspec can inspect the colours actually mapped to data.
#' @param spec The specification to check against. Supply a registry id, a
#'   `figspec_spec`, or a named list containing the colour and reproduction
#'   requirements for a publication, project or organisation.
#' @param threshold The smallest perceptual difference that figspec will accept
#'   between two colours, measured as CIE Delta-E 2000. The default is 10;
#'   raising it makes the distinction test stricter. This setting controls the
#'   accessibility analysis; pass-or-fail publication results continue to use
#'   the rules recorded in the selected specification.
#' @return A `figspec_report`.
#' @examples
#' library(ggplot2)
#' p <- ggplot(ggplot2::mpg, aes(displ, hwy, colour = class)) + geom_point()
#' p
#' colour_safety_check(p, "cell_press")
#' @export
colour_safety_check <- function(plot, spec, threshold = 10) {
  if (!is_ggplot_object(plot)) {
    figspec_abort(
      c("{.arg plot} must be a ggplot object.",
        "i" = "Colours cannot be recovered reliably from a saved figure -
               compression and colour conversion have already changed them."),
      "bad_input")
  }
  if (!is.numeric(threshold) || length(threshold) != 1L ||
      !is.finite(threshold) || threshold <= 0) {
    figspec_abort("{.arg threshold} must be one positive finite number.", "bad_input")
  }
  resolved <- spec_get(spec)
  cols <- plot_colours(plot)
  rows <- colour_rows(cols, resolved, threshold, plot)
  out <- do.call(rbind, rows)
  rownames(out) <- NULL
  structure(
    out,
    spec_name = resolved$name, spec_id = resolved$id,
    source_url = resolved$source_url, verified_on = resolved$verified_on,
    input = "ggplot object", colours = cols,
    class = c("figspec_report", "data.frame")
  )
}

#' @rdname colour_safety_check
#' @export
color_safety_check <- colour_safety_check

# Shared by colour_safety_check() and fig_check().
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
  if (!has_package("colorspace")) {
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
