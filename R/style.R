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

STYLE_FILE_LIMIT <- 10 * 1024^2

style_file_path <- function(path, must_exist = TRUE) {
  if (!is.character(path) || length(path) != 1L || is.na(path) ||
      !nzchar(trimws(path)) || grepl("[\r\n]", path)) {
    figspec_abort("{.arg path} must be one non-empty RDS file path.", "bad_input")
  }
  if (!identical(tolower(tools::file_ext(path)), "rds")) {
    figspec_abort("{.arg path} must end in {.file .rds}.", "bad_input", path = path)
  }
  expanded <- path.expand(path)
  parent <- dirname(expanded)
  if (!dir.exists(parent)) {
    figspec_abort(
      "The style-file directory does not exist: {.file {parent}}.",
      "not_found",
      path = path
    )
  }
  if (dir.exists(expanded)) {
    figspec_abort("{.file {path}} is a directory, not an RDS file.", "bad_input")
  }
  if (file.exists(expanded)) {
    link <- Sys.readlink(expanded)
    if (length(link) == 1L && !is.na(link) && nzchar(link)) {
      figspec_abort(
        "Refusing to use the symbolic link {.file {path}} as a style file.",
        "bad_input",
        path = path
      )
    }
  } else if (isTRUE(must_exist)) {
    figspec_abort("Style file not found: {.file {path}}.", "not_found", path = path)
  }
  file.path(
    normalizePath(parent, winslash = "/", mustWork = TRUE),
    basename(expanded)
  )
}

validate_style_file_contents <- function(styles, allow_functions = FALSE,
                                         resolve_functions = TRUE) {
  if (!is.list(styles)) {
    figspec_abort("House-style file must contain a list.", "bad_input")
  }
  if (!length(styles)) return(invisible(TRUE))
  style_names <- names(styles)
  if (is.null(style_names) || anyNA(style_names) || any(!nzchar(style_names)) ||
      anyDuplicated(style_names) ||
      any(!grepl("^[A-Za-z][A-Za-z0-9_.-]*$", style_names))) {
    figspec_abort(
      "House-style file must use unique, safe names for every style.",
      "bad_input"
    )
  }
  for (nm in style_names) {
    entry <- styles[[nm]]
    if (!is.list(entry) || is.object(entry) ||
        !identical(entry$name, nm) || is.null(entry$theme) ||
        !is.character(entry$description) ||
        length(entry$description) != 1L || is.na(entry$description) ||
        grepl("[\r\n]", entry$description)) {
      figspec_abort("House-style entry {.val {nm}} is malformed.", "bad_input")
    }
    if (is.function(entry$theme) && !isTRUE(allow_functions)) {
      figspec_abort(
        c("House-style entry {.val {nm}} contains executable R code.",
          ">" = "Load only a file you trust, then set {.code allow_functions = TRUE}."),
        "bad_input"
      )
    }
    resolved <- if (is.function(entry$theme) && isTRUE(resolve_functions)) {
      tryCatch(entry$theme(), error = function(e) e)
    } else {
      entry$theme
    }
    if ((!is.function(resolved) || isTRUE(resolve_functions)) &&
        (inherits(resolved, "error") || !inherits(resolved, "theme"))) {
      figspec_abort(
        "House-style entry {.val {nm}} does not resolve to a ggplot2 theme.",
        "bad_input"
      )
    }
  }
  invisible(TRUE)
}

read_style_file <- function(path, allow_functions = FALSE,
                            resolve_functions = TRUE) {
  resolved_path <- style_file_path(path, must_exist = TRUE)
  info <- file.info(resolved_path)
  if (!is.finite(info$size) || info$size < 1L) {
    figspec_abort("Style file is empty: {.file {path}}.", "bad_input", path = path)
  }
  if (info$size > STYLE_FILE_LIMIT) {
    figspec_abort(
      "Style file is larger than 10 MB: {.file {path}}.",
      "bad_input",
      path = path
    )
  }
  styles <- tryCatch(readRDS(resolved_path), error = function(e) e)
  if (inherits(styles, "error")) {
    figspec_abort(
      c("Could not read styles from {.file {path}}.",
        "x" = conditionMessage(styles)),
      "bad_input",
      path = path
    )
  }
  validate_style_file_contents(styles, allow_functions, resolve_functions)
  styles
}

promote_style_file <- function(candidate, destination) {
  backup <- NULL
  if (file.exists(destination)) {
    backup <- tempfile(
      ".figspec-style-backup-",
      tmpdir = dirname(destination),
      fileext = ".rds"
    )
    if (!file.rename(destination, backup)) {
      figspec_abort(
        "Could not protect the existing style file before replacement.",
        "bad_input",
        path = destination
      )
    }
  }
  placed <- file.rename(candidate, destination)
  restored <- TRUE
  if (!placed && !is.null(backup)) restored <- file.rename(backup, destination)
  if (!restored) {
    figspec_abort(
      c("Could not save the style file or restore its previous version.",
        "i" = "The recoverable previous file remains at {.file {backup}}."),
      "bad_input",
      path = destination,
      backup = backup
    )
  }
  if (!placed) {
    figspec_abort("Could not atomically place the style file.", "bad_input")
  }
  if (!is.null(backup)) unlink(backup)
  invisible(destination)
}

#' Register a reusable visual style
#'
#' A house style records the visual choices a project, team or organisation
#' wants to reuse across its figures. Once registered, the style can be applied
#' by name with [theme_spec()].
#'
#' The style supplies the starting appearance, followed by any overlapping
#' requirements in the specification. If your style sets type at 6 pt and the
#' specification states a floor of 8 pt, [theme_spec()] raises the type to 8 pt
#' and tells you which elements changed. All other style choices remain in the
#' finished figure.
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
#' The complete style collection is written to a temporary file, reopened and
#' validated before it is placed at the requested path. The destination must be
#' a regular file path, and any existing style file remains available if the
#' new collection cannot be written or validated.
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
  destination <- style_file_path(path, must_exist = FALSE)
  styles <- .figspec_cache$styles %||% list()
  validate_style_file_contents(
    styles,
    allow_functions = TRUE,
    resolve_functions = FALSE
  )
  candidate <- tempfile(
    ".figspec-style-",
    tmpdir = dirname(destination),
    fileext = ".rds"
  )
  on.exit(if (file.exists(candidate)) unlink(candidate), add = TRUE)
  write_error <- tryCatch({
    saveRDS(styles, candidate)
    NULL
  }, error = identity)
  if (inherits(write_error, "error")) {
    figspec_abort(
      c("Could not write the style file.", "x" = conditionMessage(write_error)),
      "bad_input",
      path = path
    )
  }
  written <- read_style_file(
    candidate,
    allow_functions = TRUE,
    resolve_functions = FALSE
  )
  if (!identical(names(written), names(styles))) {
    figspec_abort("The written style file did not preserve its style names.", "bad_input")
  }
  promote_style_file(candidate, destination)
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
  if (!is.logical(allow_functions) || length(allow_functions) != 1L ||
      is.na(allow_functions)) {
    figspec_abort("{.arg allow_functions} must be TRUE or FALSE.", "bad_input")
  }
  styles <- read_style_file(path, allow_functions, resolve_functions = TRUE)
  existing <- .figspec_cache$styles %||% list()
  .figspec_cache$styles <- utils::modifyList(existing, styles)
  invisible(names(styles) %||% character())
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
