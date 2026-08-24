# Type size in a saved file ------------------------------------------------

# Type size lives in the plot object, and once a figure becomes a raster the
# point sizes have gone with it: the text is pixels, and recovering a size
# would mean measuring glyphs and calling the estimate a measurement. A vector
# file is different. PDF, EPS and SVG all record the size at which each string
# was set, so the figure a publisher actually receives can be read back and
# checked.
#
# There is a second reason to read the file rather than trust the object. R's
# pdf() and
# postscript() devices round text to whole points, so a ggplot theme asking for
# 8.8 pt writes 9 pt into the file, and one asking for 5.2 pt writes 5. The
# object and the file genuinely disagree, and it is the file that gets
# submitted. Checking the object cannot see this; checking the file can.

VECTOR_TEXT_FORMATS <- c("pdf", "eps", "ps", "svg")

# Point sizes of every string set in a vector file, or NULL when they cannot
# be read - a format that does not carry them, an unreadable file, or a
# missing optional package. NULL leaves the report saying "could not
# determine", which is the honest answer rather than a guess.
vector_text_sizes <- function(path, format = NULL) {
  fmt <- tolower(format %||% tools::file_ext(path))
  sizes <- switch(fmt,
    pdf = pdf_text_sizes(path),
    svg = svg_text_sizes(path),
    eps = ps_text_sizes(path),
    ps  = ps_text_sizes(path),
    NULL
  )
  sizes <- sizes[is.finite(sizes) & sizes > 0]
  if (!length(sizes)) return(NULL)
  data.frame(element = "text", size_pt = sizes, stringsAsFactors = FALSE)
}

# Does this file begin with the PDF signature?
#
# Every PDF starts with the five bytes "%PDF-". Checking that before parsing
# keeps a mislabelled or corrupt file out of a reader that would complain from
# C, where the message cannot be caught or redirected.
#
# @param path Path to the file.
# @return TRUE if the first five bytes are the PDF signature.
is_pdf <- function(path) {
  # Existence is checked first rather than caught: opening a missing file warns
  # before it errors, and the warning would escape a tryCatch on the error.
  if (!file.exists(path) || isTRUE(file.info(path)$isdir)) return(FALSE)
  con <- file(path, "rb")
  on.exit(close(con), add = TRUE)
  sig <- readBin(con, "raw", 5L)
  length(sig) == 5L && identical(rawToChar(sig), "%PDF-")
}

# poppler reads the text matrix and the font matrix together, which is what
# actually determines the size on the page; a regex over the content stream
# would have to compose those itself and would be wrong wherever a figure was
# scaled. This is the one format where reaching for a library beats parsing.
pdf_text_sizes <- function(path) {
  if (!has_package("pdftools")) return(NULL)
  # poppler reports a malformed file by writing to stderr from C, which no R
  # handler can catch and which then appears in the middle of unrelated output.
  # A file that does not open with the PDF signature is not worth handing to it.
  if (!is_pdf(path)) return(NULL)
  pages <- tryCatch(pdftools::pdf_data(path, font_info = TRUE),
                    error = function(e) NULL)
  if (is.null(pages) || !length(pages)) return(NULL)
  out <- unlist(lapply(pages, function(p) {
    if (is.null(p$font_size)) NULL else as.numeric(p$font_size)
  }), use.names = FALSE)
  if (is.null(out)) NULL else out
}

# svglite writes the size straight onto each text element, unrounded, and sets
# the canvas so that one user unit is one point.
svg_text_sizes <- function(path) {
  txt <- tryCatch(paste(readLines(path, warn = FALSE), collapse = "\n"),
                  error = function(e) NULL)
  if (is.null(txt)) return(NULL)
  hits <- regmatches(txt, gregexpr("font-size: *[0-9.]+ *(px|pt)?", txt))[[1]]
  if (!length(hits)) return(NULL)
  as.numeric(sub("^font-size: *([0-9.]+).*$", "\\1", hits))
}

# PostScript sets a size by scaling a font before selecting it. R writes that
# through its own shorthand, `/Font1 findfont 9 s`, where `s` is defined in the
# prologue as `scalefont setfont`; other producers write `9 scalefont` in full.
# Both are matched, and the `findfont` on the same line keeps a bare number
# from being read as a size.
ps_text_sizes <- function(path) {
  lines <- tryCatch(readLines(path, warn = FALSE), error = function(e) NULL)
  if (is.null(lines)) return(NULL)
  short <- regmatches(lines, regexpr("findfont +[0-9.]+ +s\\b", lines))
  long <- regmatches(lines, regexpr("[0-9.]+ +scalefont", lines))
  vals <- c(sub("^findfont +([0-9.]+).*$", "\\1", short),
            sub("^([0-9.]+) +scalefont$", "\\1", long))
  if (!length(vals)) return(NULL)
  as.numeric(vals)
}
