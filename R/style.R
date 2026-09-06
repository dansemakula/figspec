# House styles ---------------------------------------------------------------
#
# A house style is the look a lab, a department or a publication wants its
# figures to have: fonts, colours, grid treatment, whatever it is that makes
# them recognisable. It is emphatically not a specification.
#
# The distinction is enforced rather than described. A house style may not
# contain any key from requirement_keys(), because those are the fields that
# fig_check() grades against, and a preference wearing the clothes of a
# requirement would produce a pass or a fail that no publisher ever asked for.
# Styles are applied underneath a journal's requirements for the same reason:
# where they conflict, the journal wins and the caller is told what was
# displaced.
#
# Styles live in the session, not on disk, unless style_save() is called.

#' Register a reusable visual style
#'
#' A house style records the visual choices a project, team or organisation
#' wants to reuse across its figures. Once registered, the style can be applied
#' by name with [theme_spec()].
#'
#' Styles are applied *underneath* a specification's requirements, never over
#' them. If your style sets type at 6 pt and the specification states a floor
#' of 8 pt, the requirement takes precedence and [theme_spec()] tells you
#' which elements it had to override. That ordering is deliberate: a style can
#' change how a figure looks, but it can never make a figure non-compliant.
#'
#' @param name A short identifier used to apply the style later.
#' @param theme The ggplot2 theme to reuse, or a function that returns one.
#' @param description An optional one-line explanation of where or why the
#'   style is used.
#' @return The registered style, invisibly.
#' @examples
#' library(ggplot2)
#' style_register(
#'   "mylab",
#'   theme_minimal() + theme(panel.grid.minor = element_blank()),
#'   description = "Minimal, no minor grid"
#' )
#' style_list()
#'
#' p <- ggplot(ggplot2::mpg, aes(displ, hwy, colour = class)) + geom_point()
#' p + theme_spec("frontiers", style = "mylab")
#' @export
style_register <- function(name, theme, description = NULL) {
  if (!is.character(name) || length(name) != 1L ||
      !grepl("^[A-Za-z][A-Za-z0-9_.-]*$", name)) {
    figspec_abort("{.arg name} must be one safe, non-empty style identifier.", "bad_input")
  }
  if (!is.function(theme) && !inherits(theme, "theme")) {
    figspec_abort(
      c("{.arg theme} must be a ggplot2 theme, or a function returning one.",
        "x" = "You gave {.cls {class(theme)}}."),
      "bad_input")
  }
  if (!is.null(description) &&
      (!is.character(description) || length(description) != 1L ||
       is.na(description) || grepl("[\r\n]", description))) {
    figspec_abort(
      "{.arg description} must be one line of text or {.code NULL}.",
      "bad_input"
    )
  }
  resolved <- if (is.function(theme)) tryCatch(theme(), error = function(e) e) else theme
  if (inherits(resolved, "error") || !inherits(resolved, "theme")) {
    figspec_abort("{.arg theme} function must return a ggplot2 theme.", "bad_input")
  }
  styles <- .figspec_cache$styles %||% list()
  styles[[name]] <- list(name = name, theme = theme,
                         description = description %||% "")
  .figspec_cache$styles <- styles
  invisible(styles[[name]])
}

#' List the visual styles available in this session
#'
#' Shows the reusable styles currently registered with
#' [style_register()]. Styles last for the current R session unless they
#' are saved with [style_save()].
#'
#' @return A data frame containing each registered style's name and
#'   description. If no styles are registered, the data frame has no rows.
#' @examples
#' style_list()
#' @export
style_list <- function() {
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

#' Remove a visual style from the current session
#'
#' Removes a style previously added with [style_register()]. This changes
#' only the current R session; a saved style file is not modified.
#'
#' @param name The registered style name, as shown by [style_list()].
#' @return `TRUE` invisibly when the style is removed.
#' @examples
#' library(ggplot2)
#' style_register("temporary", theme_void())
#' style_remove("temporary")
#' @export
style_remove <- function(name) {
  if (!is.character(name) || length(name) != 1L || is.na(name) ||
      !grepl("^[A-Za-z][A-Za-z0-9_.-]*$", name)) {
    figspec_abort(
      "{.arg name} must be one safe, non-empty style identifier.",
      "bad_input"
    )
  }
  styles <- .figspec_cache$styles %||% list()
  if (!name %in% names(styles)) {
    figspec_abort(
      c(
        "No house style named {.val {name}} is registered.",
        "i" = if (length(styles)) {
          "Registered styles: {.val {names(styles)}}."
        } else {
          "No house styles are registered in this session."
        }
      ),
      "not_found"
    )
  }
  styles[[name]] <- NULL
  .figspec_cache$styles <- styles
  invisible(TRUE)
}

#' Save visual styles for reuse
#'
#' Styles registered with [style_register()] last only for the session.
#' Save them to an RDS file when you want to use them in a later session or
#' share them across projects you control.
#'
#' @param path The RDS file to create.
#' @return `path` invisibly.
#' @examples
#' library(ggplot2)
#' style_register("mylab", theme_minimal())
#' f <- tempfile(fileext = ".rds")
#' style_save(f)
#' style_load(f)
#' unlink(f)
#' @export
style_save <- function(path) {
  saveRDS(.figspec_cache$styles %||% list(), path)
  invisible(path)
}

#' Load saved visual styles
#'
#' Restores styles previously written by [style_save()] and adds them to
#' the styles already registered in the current R session. An RDS file is a
#' trusted-input format; do not load one received from an untrusted person or
#' website.
#'
#' Theme functions contain executable R code. They are refused by default even
#' when the rest of the file is valid. Set `allow_functions = TRUE` only for a
#' file you created and control.
#'
#' @param path The RDS file previously created by [style_save()].
#' @param allow_functions Whether to permit stored theme functions. Defaults to
#'   `FALSE`.
#' @return The names of the loaded styles, invisibly.
#' @examples
#' library(ggplot2)
#' style_register("mylab", theme_minimal())
#' f <- tempfile(fileext = ".rds")
#' style_save(f)
#' style_remove("mylab")
#' style_load(f)
#' unlink(f)
#' @export
style_load <- function(path, allow_functions = FALSE) {
  styles <- readRDS(path)
  if (!is.list(styles) || is.null(names(styles)) || any(!nzchar(names(styles)))) {
    figspec_abort("House-style file must contain a named list.", "bad_input")
  }
  for (nm in names(styles)) {
    entry <- styles[[nm]]
    if (!is.list(entry) || !identical(entry$name, nm) || is.null(entry$theme)) {
      figspec_abort("House-style entry {.val {nm}} is malformed.", "bad_input")
    }
    if (is.function(entry$theme) && !isTRUE(allow_functions)) {
      figspec_abort(
        c("House-style entry {.val {nm}} contains executable R code.",
          ">" = "Load only a file you trust, then set {.code allow_functions = TRUE}."),
        "bad_input")
    }
    resolved <- if (is.function(entry$theme)) {
      tryCatch(entry$theme(), error = function(e) e)
    } else entry$theme
    if (inherits(resolved, "error") || !inherits(resolved, "theme")) {
      figspec_abort("House-style entry {.val {nm}} does not resolve to a ggplot2 theme.",
                    "bad_input")
    }
  }
  existing <- .figspec_cache$styles %||% list()
  .figspec_cache$styles <- utils::modifyList(existing, styles)
  invisible(names(styles))
}

# Resolve whatever the user passed to `style` into a theme, or NULL.
resolve_style <- function(style) {
  if (is.null(style)) return(NULL)
  if (inherits(style, "theme")) return(style)
  if (is.function(style)) {
    out <- tryCatch(style(), error = function(e) e)
    if (inherits(out, "error") || !inherits(out, "theme")) {
      figspec_abort("{.arg style} function must return a ggplot2 theme.", "bad_input")
    }
    return(out)
  }
  if (is.character(style) && length(style) == 1L) {
    styles <- .figspec_cache$styles %||% list()
    if (!style %in% names(styles)) {
      figspec_abort(
        c("No house style named {.val {style}}.",
          "i" = if (length(styles)) {
            "Registered: {.val {names(styles)}}."
          } else {
            "No house styles are registered yet - see {.fn style_register}."
          }),
        "not_found", style = style)
    }
    th <- styles[[style]]$theme
    out <- if (is.function(th)) tryCatch(th(), error = function(e) e) else th
    if (inherits(out, "error") || !inherits(out, "theme")) {
      figspec_abort("Registered style {.val {style}} does not resolve to a ggplot2 theme.",
                    "bad_input")
    }
    return(out)
  }
  figspec_abort(
    c("{.arg style} must be a style name, a ggplot2 theme, or a function.",
      "x" = "You gave {.cls {class(style)}}."),
    "bad_input")
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
