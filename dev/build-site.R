# Build pkgdown away from docs/, validate the complete result, and only then
# replace the live site. A rendering failure therefore leaves docs/ untouched.

main <- function() {
  root <- normalizePath(".", winslash = "/", mustWork = TRUE)
  destination <- file.path(root, "docs")

  # Browser-dependent Plotly examples are unsuitable for CRAN's vignette
  # builder, where Chrome is not guaranteed. The controlled website build has
  # a real browser gate, so enable those examples here and nowhere else.
  Sys.setenv(FIGSPEC_BUILD_BROWSER_EXAMPLES = "true")

  # Build outside the package tree so an interrupted build can never leak into
  # an R source tarball. Copy the validated result to an ignored candidate in
  # the repository before using same-filesystem renames for rollback safety.
  stage <- tempfile("figspec-site-stage-")
  candidate <- tempfile(".figspec-site-candidate-", tmpdir = root)
  backup <- tempfile(".figspec-site-backup-", tmpdir = root)
  dir.create(stage)

  on.exit({
    if (dir.exists(stage)) unlink(stage, recursive = TRUE, force = TRUE)
    if (dir.exists(candidate)) unlink(candidate, recursive = TRUE, force = TRUE)
    # A backup is removed explicitly only after successful promotion. If an
    # exceptional restoration failure occurs, preserve it for manual recovery.
  }, add = TRUE)

  pkg <- pkgdown::as_pkgdown(root, override = list(destination = stage))
  pkgdown::build_site(
    pkg = pkg,
    preview = FALSE,
    devel = FALSE,
    install = TRUE,
    new_process = TRUE
  )
  file.create(file.path(stage, ".nojekyll"))

  # pkgdown's captured console output can contain insignificant spaces before
  # line breaks. Normalise generated Markdown so `git diff --check` remains a
  # useful release gate instead of reporting renderer-created whitespace.
  markdown <- list.files(stage, pattern = "[.]md$", recursive = TRUE, full.names = TRUE)
  whitespace_probe <- c("what", "space ", paste0("tab", "\t"))
  stopifnot(identical(
    sub("[[:blank:]]+$", "", whitespace_probe),
    c("what", "space", "tab")
  ))
  for (path in markdown) {
    lines <- readLines(path, warn = FALSE)
    cleaned <- sub("[[:blank:]]+$", "", lines)
    if (!identical(lines, cleaned)) writeLines(cleaned, path, useBytes = TRUE)
  }

  validate <- function(path) {
    status <- system2(
      file.path(R.home("bin"), "Rscript"),
      c("dev/validate-site.R", shQuote(path))
    )
    if (!identical(status, 0L)) {
      stop("website validation failed for ", path, call. = FALSE)
    }
  }
  validate(stage)

  dir.create(candidate)
  staged_entries <- list.files(
    stage,
    all.files = TRUE,
    no.. = TRUE,
    full.names = TRUE
  )
  copied <- file.copy(
    staged_entries,
    candidate,
    recursive = TRUE,
    copy.mode = TRUE,
    copy.date = TRUE
  )
  if (length(copied) != length(staged_entries) || !all(copied)) {
    stop("could not copy the validated website to its promotion candidate", call. = FALSE)
  }
  validate(candidate)

  had_destination <- dir.exists(destination)
  if (had_destination && !file.rename(destination, backup)) {
    stop("could not move the current docs/ site to its rollback location", call. = FALSE)
  }

  restore <- function() {
    if (!had_destination) return(TRUE)
    file.rename(backup, destination)
  }

  if (!file.rename(candidate, destination)) {
    restored <- restore()
    if (!restored) {
      stop(
        "could not promote the candidate or restore the former site; rollback remains at ",
        backup,
        call. = FALSE
      )
    }
    stop("could not promote the validated site; the former site was restored", call. = FALSE)
  }

  promoted_ok <- tryCatch({
    validate(destination)
    TRUE
  }, error = function(e) FALSE)
  if (!promoted_ok) {
    unlink(destination, recursive = TRUE, force = TRUE)
    restored <- restore()
    if (!restored) {
      stop(
        "promoted website failed validation and restoration failed; rollback remains at ",
        backup,
        call. = FALSE
      )
    }
    stop("promoted website failed validation; the former site was restored", call. = FALSE)
  }

  if (had_destination) unlink(backup, recursive = TRUE, force = TRUE)
  cat("Validated website promoted to docs/.\n")
}

main()
