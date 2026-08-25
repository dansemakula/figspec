# Completeness audit: the things that go stale silently.
#
# Most of this package's documentation is generated from other parts of it -
# the options page from man/, the site from everything, the README's journal
# table from the registry. Generated content drifts when the thing that
# generates it keeps a hand-maintained list, and it drifts quietly: the page
# still builds, it is just missing things. Every gap found in this package's
# documentation so far has been of that kind.
#
# Run from the package root. Exits non-zero on a gap, so dev/check.sh can gate
# on it.

suppressMessages(pkgload::load_all(".", quiet = TRUE))
ex <- sort(getNamespaceExports("figspec"))
rd <- list.files("man", pattern = "[.]Rd$", full.names = TRUE)

aliases_of <- function(f) {
  gsub("^\\\\alias\\{|\\}[[:space:]]*$", "",
       grep("^\\\\alias\\{", readLines(f, warn = FALSE), value = TRUE))
}
topic_of <- local({
  map <- list()
  for (f in rd) for (a in aliases_of(f)) map[[a]] <- sub("[.]Rd$", "", basename(f))
  function(fn) map[[fn]]
})

gaps <- 0L
chk <- function(label, missing) {
  ok <- length(missing) == 0L
  cat(sprintf("  %-46s %s%s\n", label, if (ok) "ok" else "GAP  ",
              if (ok) "" else paste(missing, collapse = ", ")))
  if (!ok) gaps <<- gaps + 1L
}

chk("every export has a help page",
    setdiff(ex, unlist(lapply(rd, aliases_of))))

chk("every export is on the options page",
    setdiff(ex, gsub("^### `|\\(\\)`$", "",
                     grep("^### `", readLines("vignettes/options.Rmd", warn = FALSE),
                          value = TRUE))))

idx <- paste(readLines("docs/reference/index.html", warn = FALSE), collapse = "\n")
linked <- gsub('href="|\\.html"', "",
               regmatches(idx, gregexpr('href="[a-zA-Z0-9_.]+\\.html"', idx))[[1]])
chk("every export is on the site reference index",
    Filter(function(f) !(topic_of(f) %in% linked), ex))

y <- yaml::read_yaml("_pkgdown.yml")
listed <- gsub("[`\"]", "", unlist(lapply(y$reference, function(s) s$contents)))
chk("_pkgdown.yml lists every topic",
    Filter(function(f) !(topic_of(f) %in% listed || f %in% listed), ex))

nav <- sub("\\.html$", "", sub("^articles/", "",
           unlist(lapply(y$navbar$components$articles$menu, function(m) m$href))))
chk("every vignette is in the navbar",
    setdiff(sub("[.]Rmd$", "", basename(list.files("vignettes", pattern = "[.]Rmd$"))), nav))

# Site freshness is checked only when asked for, because roxygenise() rewrites
# every man/ page on each run whether or not its content changed, so a
# timestamp comparison flags a rebuild that has not actually gone stale. It is
# worth checking before publishing, where the site is genuinely about to be
# served, and dev/check.sh --full runs it there after rebuilding.
if ("--site" %in% commandArgs(trailingOnly = TRUE)) {
  src <- c(list.files("R", full.names = TRUE), list.files("man", full.names = TRUE),
           list.files("vignettes", full.names = TRUE), "README.md", "_pkgdown.yml")
  stale <- if (file.mtime("docs/index.html") < max(file.mtime(src)) - 60) "docs/" else character()
  chk("the site is not older than its sources", stale)
}

chk("the registry validates",
    if (isTRUE(suppressMessages(validate_registry_file("inst/extdata/journals.yaml")))) character() else "registry")

n <- nrow(journals())
readme_n <- as.integer(sub(".*\\*\\*([0-9]+) entries\\*\\*.*", "\\1",
                           grep("entries\\*\\*", readLines("README.md", warn = FALSE), value = TRUE)[1]))
chk("the README's journal count matches the registry",
    if (identical(n, readme_n)) character() else sprintf("README says %s, registry holds %s", readme_n, n))

cat("\n", if (gaps == 0L) "No gaps." else sprintf("%d gap(s).", gaps), "\n")
if (gaps > 0L) quit(status = 1L)
