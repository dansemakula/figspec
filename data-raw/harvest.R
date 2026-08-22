# figspec harvest toolkit
# =======================
#
# Tools for collecting journal figure requirements at scale. Not part of the
# package: this directory is excluded by .Rbuildignore.
#
# THE RULE THIS TOOLKIT OBEYS
#   Nothing here writes to the registry. It produces *candidates* with the
#   publisher's own wording attached, for a human to accept, correct or
#   discard. Auto-populating the registry would destroy the one property that
#   makes it worth trusting, which is that every value was read by somebody.
#
# THE THREE FETCH LANES, and what was actually observed on 2026-08-22
#   Lane 1  direct HTTP        works: PLOS, Frontiers, IOP, Cambridge, Royal
#                              Society, Copernicus, JSS, DOAJ, CTAN
#   Lane 2  PDF author guides  works even where the parent site blocks: the
#                              Wiley artwork guide downloaded cleanly while
#                              authorservices.wiley.com itself was fine but
#                              many publisher pages are not
#   Lane 2b Internet Archive   the Wayback Machine is not behind the publishers'
#                              WAF. Pages that return 403 live can often be read
#                              from a recent snapshot. Verified 2026-08-22 on
#                              journals.aps.org/authors/style-basics, which 403s
#                              live and returned its full specification text from
#                              a 2026-04-04 snapshot.
#
#                              INTEGRITY RULE FOR THIS LANE: an entry harvested
#                              from a snapshot records the SNAPSHOT date in
#                              verified_on, never today's date, and says so in
#                              notes. The publisher may have changed the page
#                              since. A snapshot tells you what was true then.
#
#   Lane 3  browser-assisted   required where even the Archive has no snapshot. Elsevier,
#                              Springer, Taylor & Francis, SAGE, OUP, ACS, AGU,
#                              PNAS, BMJ refused both direct HTTP and curl with
#                              a browser user-agent. Nature and Science worked
#                              once browser site-permissions were granted.
#
#   A dead end worth recording: publisher LaTeX classes on CTAN download fine
#   (IEEEtran.cls, revtex, elsarticle, acmart) but compute column widths at
#   run time rather than stating them literally, so extracting a width needs a
#   TeX engine to evaluate the class. Not a viable channel on its own.

library(jsonlite)

UA <- paste("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
            "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36")

# Discovery ---------------------------------------------------------------

# DOAJ indexes ~23,000 open-access journals and records an author-instructions
# URL for most of them, which solves "which page do I even read" at scale.
doaj_journals <- function(query = "*", n = 100, page_size = 100) {
  out <- list()
  page <- 1L
  while (length(out) < n) {
    url <- sprintf("https://doaj.org/api/search/journals/%s?page=%d&pageSize=%d",
                   utils::URLencode(query, reserved = TRUE), page, page_size)
    res <- tryCatch(jsonlite::fromJSON(url, simplifyVector = FALSE),
                    error = function(e) NULL)
    if (is.null(res) || !length(res$results)) break
    for (r in res$results) {
      b <- r$bibjson
      out[[length(out) + 1L]] <- data.frame(
        title = b$title %||% NA_character_,
        publisher = b$publisher$name %||% NA_character_,
        url = (b$ref$author_instructions %||% NA_character_),
        issn = paste(unlist(b$eissn %||% b$pissn %||% ""), collapse = ""),
        stringsAsFactors = FALSE
      )
      if (length(out) >= n) break
    }
    page <- page + 1L
  }
  res <- do.call(rbind, out)
  res[!is.na(res$url), , drop = FALSE]
}

`%||%` <- function(x, y) if (is.null(x)) y else x

# Fetching ----------------------------------------------------------------

# Lane 2b. The Archive stores pages gzipped and the id_ suffix returns them
# without the Wayback toolbar, so the bytes are the publisher's own.
wayback_latest <- function(url) {
  q <- paste0("https://web.archive.org/cdx/search/cdx?url=",
              utils::URLencode(url, reserved = TRUE),
              "&output=json&filter=statuscode:200&limit=1&sort=reverse")
  d <- tryCatch(jsonlite::fromJSON(q, simplifyVector = FALSE), error = function(e) NULL)
  if (is.null(d) || length(d) < 2) return(NULL)
  ts <- d[[2]][[2]]
  list(timestamp = ts,
       date = as.Date(substr(ts, 1, 8), format = "%Y%m%d"),
       url = paste0("https://web.archive.org/web/", ts, "id_/", url))
}

# Guessing an exact URL is the weak point: the Archive only holds pages that
# existed. A wildcard CDX search finds what it actually has, which is how you
# recover a guidelines page whose URL the publisher has since restructured.
#
# Filter server-side: a bare limit truncates alphabetically, so it returns the
# first N URLs on the domain rather than the N you want. The CDX API is also
# rate limited, so space calls out and expect intermittent 503s.
wayback_discover <- function(domain_pattern, keyword = "artwork|figure|graphic|illustration",
                             limit = 200) {
  q <- paste0("https://web.archive.org/cdx/search/cdx?url=",
              utils::URLencode(domain_pattern, reserved = TRUE),
              "&matchType=prefix&output=json&filter=statuscode:200",
              "&filter=original:.*(", keyword, ").*",
              "&collapse=urlkey&limit=", limit)
  d <- tryCatch(jsonlite::fromJSON(q, simplifyVector = FALSE), error = function(e) NULL)
  if (is.null(d) || length(d) < 2) return(character(0))
  urls <- vapply(d[-1], function(r) r[[3]], character(1))
  unique(grep(keyword, urls, value = TRUE, ignore.case = TRUE))
}

fetch_wayback <- function(url, timeout = 60) {
  snap <- wayback_latest(url)
  if (is.null(snap)) {
    return(list(ok = FALSE, status = NA, reason = "no Archive snapshot"))
  }
  h <- curl::new_handle(useragent = UA, timeout = timeout, followlocation = TRUE)
  curl::handle_setheaders(h, "Accept-Encoding" = "gzip")
  res <- tryCatch(curl::curl_fetch_memory(snap$url, handle = h), error = function(e) NULL)
  if (is.null(res) || res$status_code != 200L) {
    return(list(ok = FALSE, status = if (is.null(res)) NA else res$status_code,
                reason = "snapshot fetch failed"))
  }
  body <- res$content
  if (length(body) > 2 && body[1] == as.raw(0x1f) && body[2] == as.raw(0x8b)) {
    body <- memDecompress(body, type = "gzip")
  }
  txt <- rawToChar(body)
  txt <- gsub("<script.*?</script>|<style.*?</style>", " ", txt, perl = TRUE)
  txt <- gsub("<[^>]+>", " ", txt)
  list(ok = TRUE, status = 200L, text = gsub("\\s+", " ", txt),
       via = "internet archive", snapshot_date = snap$date,
       snapshot_url = snap$url)
}

fetch_page <- function(url, timeout = 30) {
  h <- curl::new_handle(useragent = UA, timeout = timeout, followlocation = TRUE)
  res <- tryCatch(curl::curl_fetch_memory(url, handle = h), error = function(e) NULL)
  if (is.null(res)) return(list(ok = FALSE, status = NA, reason = "connection failed"))
  if (res$status_code != 200L) {
    return(list(ok = FALSE, status = res$status_code,
                reason = if (res$status_code %in% c(403L, 503L))
                  "blocked - needs lane 3 (browser)" else "http error"))
  }
  ct <- unlist(curl::parse_headers_list(res$headers)[["content-type"]])
  body <- rawToChar(res$content)
  if (grepl("pdf", ct %||% "", ignore.case = TRUE)) {
    return(list(ok = FALSE, status = 200L, reason = "PDF - use lane 2"))
  }
  txt <- gsub("<script.*?</script>|<style.*?</style>", " ", body, perl = TRUE)
  txt <- gsub("<[^>]+>", " ", txt)
  txt <- gsub("&nbsp;|&amp;|&#39;|&quot;", " ", txt)
  list(ok = TRUE, status = 200L, text = gsub("\\s+", " ", txt))
}

# Extraction --------------------------------------------------------------

# Pull only the sentences that carry a specification. Everything a human
# reviewer sees is the publisher's own wording, never a paraphrase.
SPEC_PATTERNS <- c(
  width       = "column|width|mm\\b|cm\\b|inch",
  resolution  = "dpi|ppi|resolution|pixels per",
  format      = "TIFF|TIF\\b|EPS\\b|JPEG|JPG|PNG|PDF|vector|file format",
  type        = "point|\\bpt\\b|font|type size|lettering|typeface",
  colour      = "RGB|CMYK|colour mode|color mode|greyscale|grayscale|red and green",
  line        = "line width|line weight|stroke|rule",
  filesize    = "\\bMB\\b|megabyte|file size",
  media       = "video|movie|frame size|codec|audio"
)

extract_spec_sentences <- function(text, max_per_field = 4) {
  sentences <- unlist(strsplit(text, "(?<=[.;:])\\s+", perl = TRUE))
  sentences <- trimws(sentences)
  sentences <- sentences[nchar(sentences) > 25 & nchar(sentences) < 400]
  lapply(SPEC_PATTERNS, function(p) {
    hit <- unique(grep(p, sentences, value = TRUE, ignore.case = TRUE))
    hit <- hit[grepl("[0-9]", hit) | grepl("RGB|CMYK|TIFF|EPS|vector", hit, ignore.case = TRUE)]
    utils::head(hit, max_per_field)
  })
}

# Candidate emission ------------------------------------------------------

# Produces an entry a reviewer fills in, with the source sentences beside it.
# Every field starts unharvested, which is the honest default.
candidate_entry <- function(id, name, url, sentences, publisher = "",
                            via = NULL, snapshot_date = NULL) {
  q <- function(field) {
    s <- sentences[[field]]
    if (!length(s)) return(paste0("    # ", field, ": nothing found - confirm absent, then add to not_stated\n"))
    paste0(paste0("    # ", field, ": ", gsub("\\s+", " ", s), collapse = "\n"), "\n")
  }
  paste0(
    "- id: ", id, "\n",
    "  name: ", name, "\n",
    "  publisher: ", publisher, "\n",
    "  source_url: ", url, "\n",
    "  verified_on: '",
    format(if (!is.null(snapshot_date)) snapshot_date else Sys.Date()),
    "'   # ",
    if (!is.null(via)) "DATE OF THE ARCHIVE SNAPSHOT, not today - the live page may differ"
    else "set to the date YOU read it",
    "\n",
    if (!is.null(via)) paste0("  # SOURCE: retrieved from the Internet Archive, not the live page.\n") else "",
    "  requirements:\n",
    "    # ---- candidate sentences from the page, for you to turn into fields ----\n",
    paste0(vapply(names(SPEC_PATTERNS), q, character(1)), collapse = ""),
    "  not_stated: []   # list fields you confirmed the page does not state\n\n"
  )
}

# Pipeline ----------------------------------------------------------------

harvest <- function(targets, outfile = "data-raw/candidates.yaml",
                    blockedfile = "data-raw/blocked-worklist.csv") {
  candidates <- character(0)
  blocked <- list()
  for (i in seq_len(nrow(targets))) {
    tg <- targets[i, ]
    message(sprintf("[%d/%d] %s", i, nrow(targets), substr(tg$title, 1, 50)))
    res <- fetch_page(tg$url)
    if (!isTRUE(res$ok) && grepl("blocked|http error|connection", res$reason)) {
      message("      direct fetch ", res$reason, " - trying the Internet Archive")
      res <- fetch_wayback(tg$url)
    }
    if (!isTRUE(res$ok)) {
      blocked[[length(blocked) + 1L]] <- data.frame(
        title = tg$title, url = tg$url, status = res$status,
        reason = res$reason, stringsAsFactors = FALSE
      )
      next
    }
    sentences <- extract_spec_sentences(res$text)
    if (!length(unlist(sentences))) {
      blocked[[length(blocked) + 1L]] <- data.frame(
        title = tg$title, url = tg$url, status = 200L,
        reason = "fetched but no specification sentences found",
        stringsAsFactors = FALSE)
      next
    }
    id <- tolower(gsub("[^a-z0-9]+", "_", tolower(tg$title)))
    candidates <- c(candidates,
                    candidate_entry(id, tg$title, tg$url, sentences, tg$publisher,
                                    via = res$via, snapshot_date = res$snapshot_date))
  }
  if (length(candidates)) writeLines(c("journals:", candidates), outfile)
  if (length(blocked)) utils::write.csv(do.call(rbind, blocked), blockedfile, row.names = FALSE)
  message(sprintf("\n%d candidate(s) written to %s", length(candidates), outfile))
  message(sprintf("%d target(s) need lane 3 (browser); worklist at %s",
                  length(blocked), blockedfile))
  invisible(list(candidates = length(candidates), blocked = length(blocked)))
}
