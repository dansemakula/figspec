options_examples_path <- function() {
  path <- system.file(
    "extdata", "options-examples.yml",
    package = "figspec",
    mustWork = TRUE
  )
  normalizePath(path, winslash = "/", mustWork = TRUE)
}
