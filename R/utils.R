# Errors ------------------------------------------------------------------

# Every error figspec raises carries a class, so a caller can catch the kind of
# problem it has rather than matching on the wording. `figspec_error` is the
# parent; the specific class says what went wrong:
#
#   bad_input       an argument is the wrong type or shape
#   missing_arg     something required was not supplied
#   not_found       a named thing -- journal, palette, style, file -- is unknown
#   unsupported     a request the package cannot serve
#   bad_registry    a registry entry is malformed
#   needs_package   an optional package is not installed
#   bad_size        a size that would take the graphics device down
#   size_conflict   two sizes that cannot both hold
#
# `call` is the frame the user called, so the error is attributed to the
# exported function rather than to an internal helper. `.envir` is the frame the
# message was written in, which is where cli looks up `{...}` expressions.
figspec_abort <- function(msg, class, call = parent.frame(), ...,
                          .envir = parent.frame()) {
  cli::cli_abort(
    msg,
    class = c(paste0("figspec_", class), "figspec_error"),
    call = call,
    .envir = .envir,
    ...
  )
}

`%||%` <- function(x, y) if (is.null(x)) y else x

MM_PER_IN <- 25.4

#' Convert a length between units
#'
#' @param x Numeric vector of lengths.
#' @param from,to One of `"mm"`, `"cm"`, `"in"`, `"px"`.
#' @param dpi Dots per inch, required when converting to or from `"px"`.
#' @return A numeric vector in the target unit.
#' @keywords internal
#' @noRd
convert_length <- function(x, from, to, dpi = NULL) {
  to_mm <- function(v, u) {
    switch(u,
      mm = v,
      cm = v * 10,
      `in` = v * MM_PER_IN,
      px = {
        if (is.null(dpi)) figspec_abort(
              c("{.arg dpi} is needed to convert pixels to a physical size.",
                "i" = "A pixel has no size of its own until a resolution says how
                       many of them make an inch."),
              "missing_arg")
        v / dpi * MM_PER_IN
      },
      figspec_abort(
            c("Unsupported unit {.val {u}}.",
              "i" = "Use {.val mm}, {.val cm}, {.val in}, {.val pt} or {.val px}."),
            "unsupported", unit = u)
    )
  }
  from_mm <- function(v, u) {
    switch(u,
      mm = v,
      cm = v / 10,
      `in` = v / MM_PER_IN,
      px = {
        if (is.null(dpi)) {
          figspec_abort(
            c("{.arg dpi} is needed to convert pixels to a physical size.",
              "i" = "A pixel has no size of its own until a resolution says
                     how many of them make an inch."),
            "missing_arg")
        }
        v / MM_PER_IN * dpi
      },
      figspec_abort(
        c("Unsupported unit {.val {u}}.",
          "i" = "Use {.val mm}, {.val cm}, {.val in} or {.val px}."),
        "unsupported", unit = u)
    )
  }
  from_mm(to_mm(x, from), to)
}

# Round for display without introducing false precision.
fmt_num <- function(x, digits = 1) {
  if (is.null(x) || !length(x)) return(NA_character_)
  formatC(round(as.numeric(x), digits), format = "fg", digits = 6)
}

is_ggplot_object <- function(x) {
  inherits(x, "ggplot") || inherits(x, "ggassemble")
}

# message() does not fold at the console width either, so a sentence assembled
# from registry text runs off the side of the screen and off the side of a
# rendered vignette.
msg_wrap <- function(...) {
  txt <- paste0(...)
  width <- max(getOption("width", 80L) - 2L, 30L)
  message(paste(strwrap(txt, width = width), collapse = "\n"))
}

# A working default has to be supplied when a publisher is silent, but it must
# never be passed off as the publisher's requirement.
default_note <- function(spec, field, value, what) {
  msg_wrap(
    "'", spec$name, "' does not state ", what, ". Using ", value,
    " as a figspec default - this is not a requirement of the journal. ",
    "See ", spec$source_url
  )
  value
}

# cli's alerts do not wrap, so a long sentence runs off the side of the console
# and off the side of a rendered vignette. cli_bullets() carries the same
# symbols and does wrap, with a hanging indent under the text.
alert_wrap <- function(text, type = c("info", "success", "danger", "warning")) {
  bullet <- switch(match.arg(type),
    info = "i", success = "v", danger = "x", warning = "!"
  )
  names(text) <- rep(bullet, length(text))
  cli::cli_bullets(text)
}

# "color" is not a prefix of "colour" - the spellings diverge at the fifth
# letter - so neither R's partial argument matching nor match.arg() can carry
# the American form on its own. Anywhere a caller may reasonably type one, the
# value passes through here first.
british_spelling <- function(x) {
  if (!is.character(x)) return(x)
  sub("color", "colour", x, fixed = TRUE)
}
