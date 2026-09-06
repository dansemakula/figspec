# Validate a staged or published pkgdown site. This intentionally checks the
# files users receive, not only the pkgdown configuration that generated them.

args <- commandArgs(trailingOnly = TRUE)
site <- normalizePath(if (length(args)) args[[1]] else "docs", mustWork = TRUE)
root <- normalizePath(".", mustWork = TRUE)
failures <- character()
fail <- function(...) failures <<- c(failures, paste0(...))

required <- c(
  ".nojekyll", "index.html", "reference/index.html", "articles/index.html",
  "news/index.html", "search.json", "sitemap.xml", "extra.css", "extra.js"
)
missing_required <- required[!file.exists(file.path(site, required))]
if (length(missing_required)) {
  fail("missing required site files: ", paste(missing_required, collapse = ", "))
}

for (asset in c("extra.css", "extra.js")) {
  source <- file.path(root, "pkgdown", asset)
  built <- file.path(site, asset)
  if (file.exists(source) && file.exists(built) &&
      !identical(readBin(source, "raw", n = file.info(source)$size),
                 readBin(built, "raw", n = file.info(built)$size))) {
    fail("built ", asset, " does not match pkgdown/", asset)
  }
}

rd <- list.files("man", pattern = "[.]Rd$", full.names = TRUE)
aliases_of <- function(path) {
  gsub(
    "^\\\\alias\\{|\\}[[:space:]]*$", "",
    grep("^\\\\alias\\{", readLines(path, warn = FALSE), value = TRUE)
  )
}
rd_topics <- sub("[.]Rd$", "", basename(rd))
alias_topic <- unlist(lapply(rd, function(path) {
  stats::setNames(rep(sub("[.]Rd$", "", basename(path)), length(aliases_of(path))),
                  aliases_of(path))
}))
expected_reference <- sort(unique(c("index", rd_topics, unlist(lapply(rd, aliases_of)))))
actual_reference <- sort(sub(
  "[.]html$", "",
  basename(list.files(file.path(site, "reference"), pattern = "[.]html$"))
))
if (length(setdiff(expected_reference, actual_reference))) {
  fail(
    "missing reference pages: ",
    paste(setdiff(expected_reference, actual_reference), collapse = ", ")
  )
}
if (length(setdiff(actual_reference, expected_reference))) {
  fail(
    "obsolete reference pages: ",
    paste(setdiff(actual_reference, expected_reference), collapse = ", ")
  )
}

expected_articles <- sort(c(
  "index",
  sub("[.]Rmd$", "", basename(list.files("vignettes", pattern = "[.]Rmd$")))
))
actual_articles <- sort(sub(
  "[.]html$", "",
  basename(list.files(file.path(site, "articles"), pattern = "[.]html$"))
))
if (!identical(expected_articles, actual_articles)) {
  fail(
    "article pages differ; missing: ",
    paste(setdiff(expected_articles, actual_articles), collapse = ", "),
    "; obsolete: ", paste(setdiff(actual_articles, expected_articles), collapse = ", ")
  )
}

html_files <- list.files(site, pattern = "[.]html$", recursive = TRUE, full.names = TRUE)
html_relative <- substring(html_files, nchar(site) + 2L)
id_cache <- new.env(parent = emptyenv())
ids_in <- function(path) {
  key <- normalizePath(path, winslash = "/", mustWork = TRUE)
  if (!exists(key, envir = id_cache, inherits = FALSE)) {
    doc <- xml2::read_html(path)
    assign(key, xml2::xml_attr(xml2::xml_find_all(doc, "//*[@id]"), "id"), envir = id_cache)
  }
  get(key, envir = id_cache, inherits = FALSE)
}
is_redirect_page <- vapply(html_files, function(path) {
  doc <- xml2::read_html(path)
  length(xml2::xml_find_all(
    doc,
    ".//meta[translate(@http-equiv, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')='refresh']"
  )) > 0L
}, logical(1))
canonical_relative <- sort(html_relative[!is_redirect_page])
approved_origin <- "https://dansemakula.github.io/figspec/"

map <- read.csv(
  "tests/testthat/fixtures/api-migration/api-migration-map.csv",
  stringsAsFactors = FALSE
)
active_exports <- ifelse(map$name_state == "migrated", map$new_name, map$old_name)
active_topics <- sort(unique(unname(alias_topic[active_exports])))
migrated_old <- map$old_name[
  map$name_state == "migrated" & map$old_name != map$new_name
]

# A successful build can still carry stale prose from an authored page (NEWS
# was the source of one such case). Check the canonical pages themselves, not
# just their filenames and search-index entries. Redirect pages are excluded
# because their sole purpose is to preserve an approved alternate URL.
canonical_html <- html_files[!is_redirect_page]

# Every canonical page must retain the same global wayfinding after a rebuild.
# Contextual guide/reference navigation is added by extra.js at runtime, so the
# validator also confirms that those page types load the script responsible
# for breadcrumbs, return links and previous/next links.
for (page in canonical_html) {
  doc <- xml2::read_html(page)
  rel <- substring(page, nchar(site) + 2L)
  site_nav <- xml2::xml_find_all(doc, ".//nav[@aria-label='Site navigation']")
  if (length(site_nav) != 1L) {
    fail("canonical page must contain one site navigation menu: ", rel)
    next
  }
  nav_text <- trimws(xml2::xml_text(site_nav))
  for (label in c("Home", "Get started", "Reference", "Guides", "Changelog")) {
    if (!grepl(paste0("\\b", label, "\\b"), nav_text)) {
      fail("site navigation is missing '", label, "' in ", rel)
    }
  }
  guide_index_link <- xml2::xml_find_all(
    site_nav,
    ".//a[normalize-space(.)='All guides']"
  )
  if (length(guide_index_link) != 1L) {
    fail("site navigation must contain one All guides link in ", rel)
  }

  classes <- strsplit(xml2::xml_attr(xml2::xml_find_first(doc, ".//body/div[contains(@class, 'template-')]"), "class"), "[[:space:]]+")[[1]]
  needs_context <- any(classes %in% c("template-article", "template-reference-topic"))
  if (needs_context) {
    scripts <- xml2::xml_attr(xml2::xml_find_all(doc, ".//script[@src]"), "src")
    if (!any(endsWith(scripts, "extra.js"))) {
      fail("contextual navigation script is missing from ", rel)
    }
  }
}

navigation_source <- paste(readLines("pkgdown/extra.js", warn = FALSE), collapse = "\n")
for (probe in c(
  "addGuideNavigation", "addReferenceTopicNavigation", "addIndexBreadcrumbs",
  "All guides", "All functions", "Previous: ", "Next: "
)) {
  if (!grepl(probe, navigation_source, fixed = TRUE)) {
    fail("contextual navigation implementation is missing: ", probe)
  }
}

for (old in migrated_old) {
  patterns <- if (identical(old, "journals")) {
    c(
      "\\bjournals\\s*(?:&lt;-\\s*function|\\()",
      "figspec(?:::|:::)journals\\b",
      "export\\(journals\\)"
    )
  } else {
    paste0("(?<![[:alnum:]_.])", old, "(?![[:alnum:]_.])")
  }
  hits <- canonical_html[vapply(canonical_html, function(path) {
    page <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
    any(vapply(patterns, grepl, logical(1), x = page, perl = TRUE))
  }, logical(1))]
  if (length(hits)) {
    fail(
      "former function name ", old, " remains in canonical page(s): ",
      paste(substring(hits, nchar(site) + 2L), collapse = ", ")
    )
  }
}

search_paths <- character()
search_ids <- character()
if (file.exists(file.path(site, "search.json"))) {
  search <- tryCatch(
    jsonlite::fromJSON(file.path(site, "search.json"), simplifyVector = FALSE),
    error = function(e) e
  )
  if (inherits(search, "error") || !length(search)) {
    fail("search.json is empty or invalid")
  } else {
    search_paths <- vapply(search, function(entry) {
      if (!length(entry$path)) "" else as.character(entry$path[[1]])
    }, character(1))
    search_ids <- vapply(search, function(entry) {
      if (!length(entry$id)) "" else as.character(entry$id[[1]])
    }, character(1))
    # pkgdown inserts empty separator records between some reference groups.
    # They carry no URL and are not searchable pages; validate every real row.
    populated <- nzchar(search_paths)
    search_paths <- search_paths[populated]
    search_ids <- search_ids[populated]
    if (any(!startsWith(search_paths, approved_origin))) {
      fail("search.json contains a path outside the approved figspec site")
    }
    search_relative <- sub(approved_origin, "", search_paths, fixed = TRUE)
    if (any(grepl("[?#]", search_relative))) {
      fail("search.json paths must not contain query strings or fragments")
    }
    if (anyDuplicated(paste(search_paths, search_ids, sep = "#"))) {
      fail("search.json contains duplicate page-and-anchor entries")
    }
    for (i in seq_along(search_relative)) {
      target <- file.path(site, search_relative[[i]])
      if (!file.exists(target)) {
        fail("search.json points to a missing page: ", search_relative[[i]])
      } else if (nzchar(search_ids[[i]]) && !search_ids[[i]] %in% ids_in(target)) {
        fail(
          "search.json points to a missing anchor: ",
          search_relative[[i]], "#", search_ids[[i]]
        )
      }
    }
    deliberately_unindexed <- c(
      "404.html", "LICENSE.html", "articles/index.html", "reference/index.html"
    )
    expected_search_relative <- setdiff(canonical_relative, deliberately_unindexed)
    if (!identical(sort(unique(search_relative)), sort(expected_search_relative))) {
      fail(
        "search.json page set differs; missing: ",
        paste(setdiff(expected_search_relative, unique(search_relative)), collapse = ", "),
        "; unexpected: ",
        paste(setdiff(unique(search_relative), expected_search_relative), collapse = ", ")
      )
    }
  }
}
for (topic in active_topics) {
  suffix <- paste0("/reference/", topic, ".html")
  if (!any(endsWith(search_paths, suffix))) {
    fail("search.json does not index canonical topic ", topic)
  }
}
for (old in migrated_old) {
  if (any(endsWith(search_paths, paste0("/reference/", old, ".html")))) {
    fail("search.json retains former canonical topic ", old)
  }
}

sitemap_locations <- character()
if (file.exists(file.path(site, "sitemap.xml"))) {
  sitemap <- tryCatch(
    xml2::read_xml(file.path(site, "sitemap.xml")),
    error = function(e) e
  )
  if (inherits(sitemap, "error") || !length(xml2::xml_find_all(sitemap, ".//*[local-name()='loc']"))) {
    fail("sitemap.xml is empty or invalid")
  } else {
    sitemap_locations <- xml2::xml_text(
      xml2::xml_find_all(sitemap, ".//*[local-name()='loc']")
    )
  }
}
if (length(sitemap_locations)) {
  expected_sitemap <- paste0(approved_origin, canonical_relative)
  if (any(!startsWith(sitemap_locations, approved_origin))) {
    fail("sitemap.xml contains a URL outside the approved figspec site")
  }
  if (anyDuplicated(sitemap_locations)) {
    fail("sitemap.xml contains duplicate URLs")
  }
  if (!identical(sort(sitemap_locations), sort(expected_sitemap))) {
    fail(
      "sitemap.xml URL set differs; missing: ",
      paste(setdiff(expected_sitemap, sitemap_locations), collapse = ", "),
      "; unexpected: ",
      paste(setdiff(sitemap_locations, expected_sitemap), collapse = ", ")
    )
  }
}
for (topic in active_topics) {
  suffix <- paste0("/reference/", topic, ".html")
  if (!any(endsWith(sitemap_locations, suffix))) {
    fail("sitemap.xml does not contain canonical topic ", topic)
  }
}
for (old in migrated_old) {
  if (any(endsWith(sitemap_locations, paste0("/reference/", old, ".html")))) {
    fail("sitemap.xml retains former canonical topic ", old)
  }
}

reference_index <- paste(
  readLines(file.path(site, "reference", "index.html"), warn = FALSE),
  collapse = "\n"
)
for (topic in active_topics) {
  if (!grepl(paste0('href="', topic, '[.]html"'), reference_index)) {
    fail("reference index does not link canonical topic ", topic)
  }
}

# Redirect pages are an explicit, small compatibility surface. Validate both
# the browser refresh and canonical URL, their local target, and the exact set
# of redirect pages expected at the current migration stage.
redirect_manifest <- read.csv("dev/site-redirects.csv", stringsAsFactors = FALSE)
if (!identical(
  names(redirect_manifest),
  c("current_source", "current_target", "final_source", "final_target", "reason")
) || nrow(redirect_manifest) != 4L ||
    anyDuplicated(redirect_manifest$current_source) ||
    anyDuplicated(redirect_manifest$final_source) ||
    any(!nzchar(unlist(redirect_manifest)))) {
  fail("site redirect manifest has changed shape or contains invalid rows")
}
redirect_identity <- tempfile()
on.exit(unlink(redirect_identity), add = TRUE)
writeLines(
  apply(redirect_manifest[, 1:4, drop = FALSE], 1, paste, collapse = "|"),
  redirect_identity
)
if (!identical(
  unname(tools::md5sum(redirect_identity)),
  "47aa611b89c81d7699c5dcd248789e3a"
)) {
  fail("site redirect source/target pairs changed after approval")
}
redirect_use_final <- vapply(redirect_manifest$current_source, function(source) {
  i <- match(source, map$old_name)
  !is.na(i) && map$name_state[[i]] == "migrated"
}, logical(1))
expected_redirect_source <- ifelse(
  redirect_use_final,
  redirect_manifest$final_source,
  redirect_manifest$current_source
)
expected_redirect_target <- ifelse(
  redirect_use_final,
  redirect_manifest$final_target,
  redirect_manifest$current_target
)
expected_redirects <- stats::setNames(
  paste0("reference/", expected_redirect_target, ".html"),
  paste0("reference/", expected_redirect_source, ".html")
)

site_relative_url <- function(url) {
  value <- sub("^[[:space:]]*[0-9]+;[[:space:]]*URL=", "", url, ignore.case = TRUE)
  value <- sub("^https?://[^/]+/figspec/", "", value, ignore.case = TRUE)
  value <- sub("^/figspec/", "", value)
  value <- sub("^[.]/", "", value)
  sub("[?#].*$", "", value)
}

actual_redirects <- character()
for (page in html_files) {
  doc <- xml2::read_html(page)
  refresh <- xml2::xml_attr(
    xml2::xml_find_all(
      doc,
      ".//meta[translate(@http-equiv, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')='refresh']"
    ),
    "content"
  )
  if (!length(refresh)) next
  rel_page <- substring(page, nchar(site) + 2L)
  canonical <- xml2::xml_attr(
    xml2::xml_find_all(
      doc,
      ".//link[contains(concat(' ', normalize-space(@rel), ' '), ' canonical ')]"
    ),
    "href"
  )
  if (length(refresh) != 1L || length(canonical) != 1L) {
    fail("redirect page must have one refresh and one canonical URL: ", rel_page)
    next
  }
  refresh_url <- sub(
    "^[[:space:]]*[0-9]+;[[:space:]]*URL=",
    "",
    refresh[[1]],
    ignore.case = TRUE
  )
  approved_origin_pattern <- "^https://dansemakula[.]github[.]io/figspec/"
  if (!grepl(approved_origin_pattern, refresh_url) ||
      !grepl(approved_origin_pattern, canonical[[1]])) {
    fail("redirect leaves the approved figspec site in ", rel_page)
  }
  refresh_target <- site_relative_url(refresh[[1]])
  canonical_target <- site_relative_url(canonical[[1]])
  if (!identical(refresh_target, canonical_target)) {
    fail("redirect refresh and canonical targets differ in ", rel_page)
  }
  if (identical(refresh_target, rel_page)) {
    fail("redirect loop in ", rel_page)
  }
  if (!file.exists(file.path(site, refresh_target))) {
    fail("redirect target does not exist for ", rel_page, ": ", refresh_target)
  }
  actual_redirects[[rel_page]] <- refresh_target
}
if (!identical(sort(names(actual_redirects)), sort(names(expected_redirects)))) {
  fail(
    "redirect page set differs; missing: ",
    paste(setdiff(names(expected_redirects), names(actual_redirects)), collapse = ", "),
    "; unexpected: ",
    paste(setdiff(names(actual_redirects), names(expected_redirects)), collapse = ", ")
  )
}
for (source in intersect(names(expected_redirects), names(actual_redirects))) {
  if (!identical(actual_redirects[[source]], expected_redirects[[source]])) {
    fail(
      "redirect target differs for ", source, ": expected ",
      expected_redirects[[source]], ", found ", actual_redirects[[source]]
    )
  }
}

referenced_assets <- character()

for (page in html_files) {
  doc <- tryCatch(xml2::read_html(page), error = function(e) e)
  if (inherits(doc, "error")) {
    fail("invalid HTML: ", substring(page, nchar(site) + 2L))
    next
  }
  nodes <- xml2::xml_find_all(doc, "//*[@href or @src]")
  refs <- unique(c(xml2::xml_attr(nodes, "href"), xml2::xml_attr(nodes, "src")))
  refs <- refs[!is.na(refs) & nzchar(refs)]
  for (ref in refs) {
    base_page <- page
    if (grepl("^(https?:|mailto:|tel:|data:|javascript:|//)", ref, ignore.case = TRUE) ||
        identical(ref, "/")) next
    if (startsWith(ref, "/figspec/")) {
      ref <- substring(ref, nchar("/figspec/") + 1L)
      base_page <- file.path(site, "index.html")
    } else if (startsWith(ref, "/")) {
      next
    }
    parts <- strsplit(ref, "#", fixed = TRUE)[[1]]
    relative <- sub("[?].*$", "", parts[[1]])
    fragment <- if (length(parts) > 1L) utils::URLdecode(parts[[2]]) else ""
    target <- if (!nzchar(relative)) base_page else file.path(dirname(base_page), utils::URLdecode(relative))
    if (dir.exists(target)) target <- file.path(target, "index.html")
    if (!file.exists(target)) {
      fail(
        "broken local reference in ", substring(page, nchar(site) + 2L),
        ": ", ref
      )
      next
    }
    if (grepl("[.](png|jpe?g|gif|svg)$", target, ignore.case = TRUE)) {
      referenced_assets <- c(
        referenced_assets,
        normalizePath(target, winslash = "/", mustWork = TRUE)
      )
    }
    if (nzchar(fragment) && grepl("[.]html$", target, ignore.case = TRUE) &&
        !fragment %in% ids_in(target)) {
      fail(
        "missing anchor in ", substring(page, nchar(site) + 2L),
        ": ", ref
      )
    }
  }
}

# Generated stylesheets also refer to image assets (for example pkgdown's
# heading-link icon). Count those references before deciding that an image is
# orphaned; checking HTML alone would reject a file that the browser uses.
css_files <- list.files(site, pattern = "[.]css$", recursive = TRUE, full.names = TRUE)
for (stylesheet in css_files) {
  css <- paste(readLines(stylesheet, warn = FALSE), collapse = "\n")
  matches <- regmatches(css, gregexpr("url\\([^)]*\\)", css, perl = TRUE))[[1]]
  if (!length(matches) || identical(matches, "")) next
  refs <- sub("^url\\([[:space:]]*['\"]?", "", matches)
  refs <- sub("['\"]?[[:space:]]*\\)$", "", refs)
  refs <- refs[!grepl("^(data:|https?:|//|#)", refs, ignore.case = TRUE)]
  for (ref in refs) {
    relative <- sub("[?#].*$", "", utils::URLdecode(ref))
    if (!nzchar(relative)) next
    target <- file.path(dirname(stylesheet), relative)
    if (!file.exists(target)) {
      fail(
        "broken local stylesheet reference in ",
        substring(stylesheet, nchar(site) + 2L), ": ", ref
      )
      next
    }
    if (grepl("[.](png|jpe?g|gif|svg)$", target, ignore.case = TRUE)) {
      referenced_assets <- c(
        referenced_assets,
        normalizePath(target, winslash = "/", mustWork = TRUE)
      )
    }
  }
}

image_assets <- list.files(
  site,
  pattern = "[.](png|jpe?g|gif|svg)$",
  recursive = TRUE,
  full.names = TRUE,
  ignore.case = TRUE
)
image_assets <- normalizePath(image_assets, winslash = "/", mustWork = TRUE)
orphan_images <- setdiff(image_assets, unique(referenced_assets))
if (length(orphan_images)) {
  fail(
    "unreferenced image asset(s): ",
    paste(substring(orphan_images, nchar(site) + 2L), collapse = ", ")
  )
}

if (length(failures)) {
  cat(paste0("- ", unique(failures), collapse = "\n"), "\n")
  quit(status = 1L)
}
cat(sprintf("Site validation passed: %d HTML pages checked in %s\n", length(html_files), site))
