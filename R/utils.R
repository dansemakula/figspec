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
        if (is.null(dpi)) stop("`dpi` is required to convert pixels.", call. = FALSE)
        v / dpi * MM_PER_IN
      },
      stop("Unsupported unit: ", u, call. = FALSE)
    )
  }
  from_mm <- function(v, u) {
    switch(u,
      mm = v,
      cm = v / 10,
      `in` = v / MM_PER_IN,
      px = {
        if (is.null(dpi)) stop("`dpi` is required to convert pixels.", call. = FALSE)
        v / MM_PER_IN * dpi
      },
      stop("Unsupported unit: ", u, call. = FALSE)
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
