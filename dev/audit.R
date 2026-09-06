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

# A clean documentation build should remove topics and aliases that belonged
# to former API names. Merely checking that every current export is documented
# would allow those obsolete pages to survive indefinitely.
alias_owner <- unlist(lapply(rd, function(f) {
  stats::setNames(rep(basename(f), length(aliases_of(f))), aliases_of(f))
}))
duplicate_aliases <- unique(names(alias_owner)[duplicated(names(alias_owner))])
chk("no help alias is defined by two topics", duplicate_aliases)

allowed_non_export_aliases <- c(
  "figspec", "figspec-package", "plot.figspec_geometry"
)
chk(
  "help aliases are explicitly approved",
  setdiff(names(alias_owner), c(ex, allowed_non_export_aliases))
)

documented_export_topics <- unique(unlist(lapply(ex, topic_of)))
rd_topics <- sub("[.]Rd$", "", basename(rd))
chk("no obsolete help topics remain",
    setdiff(rd_topics, c(documented_export_topics, "figspec-package")))

options_names <- gsub(
  "^### `|\\(\\)`$", "",
  grep("^### `", readLines("vignettes/options.Rmd", warn = FALSE), value = TRUE)
)
chk("every export is on the options page", setdiff(ex, options_names))
chk("the options page has no unknown functions", setdiff(options_names, ex))
chk("each options-page function appears once", unique(options_names[duplicated(options_names)]))

site_index <- "docs/reference/index.html"
if (file.exists(site_index)) {
  idx <- paste(readLines(site_index, warn = FALSE), collapse = "\n")
  linked <- gsub('href="|\\.html"', "",
                 regmatches(idx, gregexpr('href="[a-zA-Z0-9_.]+\\.html"', idx))[[1]])
  chk("every export is on the site reference index",
      Filter(function(f) !(topic_of(f) %in% linked), ex))

  site_topics <- sub(
    "[.]html$", "",
    basename(list.files("docs/reference", pattern = "[.]html$", full.names = TRUE))
  )
  expected_site_topics <- unique(c("index", rd_topics, names(alias_owner)))
  chk("no obsolete reference pages remain",
      setdiff(site_topics, expected_site_topics))
} else if ("--site" %in% commandArgs(trailingOnly = TRUE)) {
  chk("the built site has a reference index", site_index)
}

y <- yaml::read_yaml("_pkgdown.yml")
listed <- gsub("[`\"]", "", unlist(lapply(y$reference, function(s) s$contents)))
expected_reference_topics <- sort(unique(unlist(lapply(ex, topic_of))))
chk("_pkgdown.yml lists every topic", setdiff(expected_reference_topics, listed))
chk("_pkgdown.yml has no unknown topics", setdiff(listed, expected_reference_topics))
chk("each pkgdown topic is grouped once", unique(listed[duplicated(listed)]))

nav <- sub("\\.html$", "", sub("^articles/", "",
           unlist(lapply(y$navbar$components$guides$menu, function(m) m$href))))
chk("every vignette is in the navbar",
    setdiff(sub("[.]Rmd$", "", basename(list.files("vignettes", pattern = "[.]Rmd$"))), nav))

if (dir.exists("docs/articles")) {
  article_pages <- sub(
    "[.]html$", "",
    basename(list.files("docs/articles", pattern = "[.]html$", full.names = TRUE))
  )
  expected_articles <- c(
    "index",
    sub("[.]Rmd$", "", basename(list.files("vignettes", pattern = "[.]Rmd$")))
  )
  chk("no obsolete article pages remain",
      setdiff(article_pages, expected_articles))
}

# Site freshness is checked only when asked for, because roxygenise() rewrites
# every man/ page on each run whether or not its content changed, so a
# timestamp comparison flags a rebuild that has not actually gone stale. It is
# worth checking before publishing, where the site is genuinely about to be
# served, and dev/check.sh --full runs it there after rebuilding.
if ("--site" %in% commandArgs(trailingOnly = TRUE)) {
  src <- c(list.files("R", full.names = TRUE), list.files("man", full.names = TRUE),
           list.files("vignettes", full.names = TRUE), "README.md", "_pkgdown.yml")
  stale <- if (!file.exists("docs/index.html") ||
               file.mtime("docs/index.html") < max(file.mtime(src)) - 60) "docs/" else character()
  chk("the site is not older than its sources", stale)
}

chk("the registry validates",
    if (isTRUE(suppressMessages(registry_validate_file("inst/extdata/journals.yaml")))) character() else "registry")

n <- nrow(spec_list())
readme_line <- grep(
  "built-in registry contains \\*\\*[0-9]+ profiles",
  readLines("README.md", warn = FALSE),
  value = TRUE
)[1]
readme_n <- as.integer(sub(".*\\*\\*([0-9]+) profiles.*", "\\1", readme_line))
chk("the README's journal count matches the registry",
    if (identical(n, readme_n)) character() else sprintf("README says %s, registry holds %s", readme_n, n))

cat("\n", if (gaps == 0L) "No gaps." else sprintf("%d gap(s).", gaps), "\n")
if (gaps > 0L) quit(status = 1L)
