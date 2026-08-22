# House styles ------------------------------------------------------------

#' Register a house style of your own
#'
#' A house style is the visual half of a figure: the look you want your lab,
#' group or publication to have. Register one and you can apply it to any
#' journal by name.
#'
#' Styles are applied *underneath* a journal's requirements, never over them.
#' If your style sets type at 6 pt and the journal states a floor of 8 pt, the
#' journal wins and [theme_journal()] tells you which elements it had to
#' override. That ordering is deliberate: a style can change how a figure
#' looks, but it can never make a figure non-compliant.
#'
#' @param name Short name you will refer to the style by.
#' @param theme A ggplot2 theme object, or a function returning one.
#' @param description Optional one-line description.
#' @return The registered style, invisibly.
#' @examples
#' library(ggplot2)
#' register_house_style(
#'   "mylab",
#'   theme_minimal() + theme(panel.grid.minor = element_blank()),
#'   description = "Minimal, no minor grid"
#' )
#' house_styles()
#'
#' p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
#' p + theme_journal("frontiers", style = "mylab")
#' @export
register_house_style <- function(name, theme, description = NULL) {
  if (!is.function(theme) && !inherits(theme, "theme")) {
    stop("`theme` must be a ggplot2 theme object or a function returning one.",
         call. = FALSE)
  }
  styles <- .figspec_cache$styles %||% list()
  styles[[name]] <- list(name = name, theme = theme,
                         description = description %||% "")
  .figspec_cache$styles <- styles
  invisible(styles[[name]])
}

#' House styles registered in this session
#'
#' @return A data frame of registered style names and descriptions.
#' @examples
#' house_styles()
#' @export
house_styles <- function() {
  styles <- .figspec_cache$styles %||% list()
  if (!length(styles)) {
    return(data.frame(name = character(0), description = character(0),
                      stringsAsFactors = FALSE))
  }
  out <- do.call(rbind, lapply(styles, function(s) {
    data.frame(name = s$name, description = s$description,
               stringsAsFactors = FALSE)
  }))
  rownames(out) <- NULL
  out
}

#' Remove a registered house style
#'
#' @param name Name of the style to remove.
#' @return `TRUE` invisibly.
#' @examples
#' library(ggplot2)
#' register_house_style("temporary", theme_void())
#' remove_house_style("temporary")
#' @export
remove_house_style <- function(name) {
  styles <- .figspec_cache$styles %||% list()
  styles[[name]] <- NULL
  .figspec_cache$styles <- styles
  invisible(TRUE)
}

#' Save and reload your house styles
#'
#' Styles registered with [register_house_style()] last only for the session.
#' Save them to a file to keep them, and load them from a project setup script
#' or your `.Rprofile`.
#'
#' @param path File to write to or read from.
#' @return For `save_house_styles()`, `path` invisibly. For
#'   `load_house_styles()`, the names loaded, invisibly.
#' @examples
#' library(ggplot2)
#' register_house_style("mylab", theme_minimal())
#' f <- tempfile(fileext = ".rds")
#' save_house_styles(f)
#' load_house_styles(f)
#' unlink(f)
#' @export
save_house_styles <- function(path) {
  saveRDS(.figspec_cache$styles %||% list(), path)
  invisible(path)
}

#' @rdname save_house_styles
#' @export
load_house_styles <- function(path) {
  styles <- readRDS(path)
  existing <- .figspec_cache$styles %||% list()
  .figspec_cache$styles <- utils::modifyList(existing, styles)
  invisible(names(styles))
}

# Resolve whatever the user passed to `style` into a theme, or NULL.
resolve_style <- function(style) {
  if (is.null(style)) return(NULL)
  if (inherits(style, "theme")) return(style)
  if (is.function(style)) return(style())
  if (is.character(style) && length(style) == 1L) {
    styles <- .figspec_cache$styles %||% list()
    if (!style %in% names(styles)) {
      stop("No house style named '", style, "'. Registered: ",
           if (length(styles)) paste(names(styles), collapse = ", ") else "none",
           call. = FALSE)
    }
    th <- styles[[style]]$theme
    return(if (is.function(th)) th() else th)
  }
  stop("`style` must be a style name, a ggplot2 theme, or a function.",
       call. = FALSE)
}

# Report which of a style's type sizes the journal's requirements override, so
# the user learns why their style did not fully take effect.
style_overrides <- function(style_theme, min_pt, max_pt) {
  if (is.null(style_theme)) return(character(0))
  hits <- character(0)
  for (nm in names(style_theme)) {
    el <- style_theme[[nm]]
    # A rel() size is a multiplier of the base size, not a point size, and
    # inherits from numeric. Comparing it against a point floor would flag
    # every relative element as too small.
    if (inherits(el, "element_text") && !inherits(el$size, "rel") &&
        is.numeric(el$size) && length(el$size) == 1L) {
      if (el$size < min_pt || (!is.null(max_pt) && el$size > max_pt)) {
        hits <- c(hits, nm)
      }
    }
  }
  hits
}
