# Accept a clean R CMD check, or the single precisely described pre-launch
# incoming-feasibility note. Any other note, warning, error or abnormal process
# exit fails the local release gate.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2L) {
  stop("usage: check-cran-log.R <00check.log> <process-status>", call. = FALSE)
}
log_path <- args[[1]]
process_status <- suppressWarnings(as.integer(args[[2]]))
if (is.na(process_status) || process_status != 0L) {
  stop("R CMD check exited with status ", args[[2]], call. = FALSE)
}

lines <- readLines(log_path, warn = FALSE)
status <- grep("^Status:", lines, value = TRUE)
if (length(status) != 1L) {
  stop("expected exactly one terminal R CMD check Status line", call. = FALSE)
}
status_index <- grep("^Status:", lines)
done_index <- grep("^\\* DONE$", lines)
if (length(done_index) != 1L || done_index >= status_index) {
  stop("R CMD check log does not contain one completed * DONE marker", call. = FALSE)
}
finding_headers <- grep(
  "^\\* checking.* (NOTE|WARNING|ERROR)$",
  lines,
  value = TRUE
)
normalized_finding_headers <- sub(
  " \\[[0-9]+s(?:/[0-9]+s)?\\](?= (NOTE|WARNING|ERROR)$)",
  "",
  finding_headers,
  perl = TRUE
)
if (identical(status, "Status: OK")) {
  if (length(finding_headers)) {
    stop(
      "clean Status contradicts finding header(s): ",
      paste(finding_headers, collapse = "; "),
      call. = FALSE
    )
  }
  cat("R CMD check status is clean.\n")
  quit(status = 0L)
}
if (!identical(status, "Status: 1 NOTE")) {
  stop("unexpected R CMD check status: ", status, call. = FALSE)
}

if (!identical(
  normalized_finding_headers,
  "* checking CRAN incoming feasibility ... NOTE"
)) {
  stop("unexpected check finding: ", paste(finding_headers, collapse = "; "), call. = FALSE)
}

start <- grep("^\\* checking CRAN incoming feasibility .* NOTE$", lines)
end_candidates <- grep("^\\* checking", lines)
end_candidates <- end_candidates[end_candidates > start]
end <- if (length(end_candidates)) min(end_candidates) - 1L else length(lines)
body <- trimws(lines[seq.int(start + 1L, end)])
body <- body[nzchar(body)]

prelaunch_urls <- c(
  "https://dansemakula.github.io/figspec/",
  paste0(
    "https://dansemakula.github.io/figspec/articles/",
    c("figspec.html", "figure-systems.html", "journals.html", "options.html",
      "panels.html", "registry.html", "tables.html")
  ),
  "https://dansemakula.github.io/figspec/reference/index.html"
)
prelaunch_sources <- c(
  "From: DESCRIPTION", "man/figspec-package.Rd", "inst/CITATION",
  "From: README.md"
)

allowed <- vapply(body, function(line) {
  grepl("^Maintainer:", line) ||
    identical(line, "New submission") ||
    identical(line, "Found the following (possibly) invalid URLs:") ||
    sub("^URL: ", "", line) %in% prelaunch_urls ||
    line %in% prelaunch_sources ||
    identical(line, "Status: 404") ||
    identical(line, "Message: Not Found")
}, logical(1))

if (!all(allowed) || !"New submission" %in% body) {
  stop(
    "incoming-feasibility NOTE differs from the approved pre-launch note: ",
    paste(body[!allowed], collapse = "; "),
    call. = FALSE
  )
}
cat("Only the approved pre-launch new-submission/website NOTE remains.\n")
