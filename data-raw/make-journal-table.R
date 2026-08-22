# Regenerates the journals table in README.md from the registry itself.
suppressMessages(pkgload::load_all(".", quiet = TRUE))
reg <- figspec:::load_registry()

rows <- do.call(rbind, lapply(reg, function(j) {
  scope <- if (grepl("journals$|Publications|books$|magazines$", j$name)) {
    "publisher"
  } else "journal"
  disc <- paste(unlist(j$disciplines %||% "—"), collapse = ", ")
  data.frame(name = j$name, id = j$id, scope = scope, disc = disc,
             stringsAsFactors = FALSE)
}))
rows <- rows[order(rows$name), ]

tbl <- c(
  "| Journal or publisher | `id` | Covers | Fields |",
  "|---|---|---|---|",
  sprintf("| %s | `%s` | %s | %s |", rows$name, rows$id,
          ifelse(rows$scope == "publisher", "all its journals", "this journal"),
          vapply(rows$id, function(i) {
            st <- figspec::registry_status()
            as.character(st$stated[st$id == i])
          }, character(1)))
)

# A long table dominates the page and will only grow, so the scannable list
# stays visible and the detail folds away. <details> renders on GitHub and in
# pkgdown alike.
names_line <- paste(rows$name, collapse = " · ")

block <- c(
  "## Journals covered",
  "",
  sprintf("**%d entries**, %d of them covering a publisher's whole portfolio, across %d disciplines.",
          nrow(rows), sum(rows$scope == "publisher"),
          length(unique(unlist(strsplit(paste(rows$disc, collapse = ", "), ", "))))),
  "",
  names_line,
  "",
  "<details>",
  "<summary><strong>Full table</strong> — ids, coverage, and how much has been harvested</summary>",
  "",
  tbl,
  "",
  "`Fields` counts the requirements harvested so far for that entry.",
  "",
  "</details>",
  "",
  "[The full table of widths, resolutions and type sizes](https://dansemakula.github.io/figspec/articles/journals.html)",
  "is generated from the registry, as is",
  "[the reference to every function and option](https://dansemakula.github.io/figspec/articles/options.html).",
  "Use `journal_spec(id)` for any entry's full specification and its source.",
  ""
)

readme <- readLines("README.md")
start <- grep("^## Journals covered$", readme)
anchor <- grep("^## Looking things up$", readme)[1]
if (length(start)) {
  readme <- c(readme[seq_len(start - 1)], block, readme[anchor:length(readme)])
} else {
  readme <- c(readme[seq_len(anchor - 1)], block, readme[anchor:length(readme)])
}
writeLines(readme, "README.md")
cat("README journals table updated:", nrow(rows), "entries\n")
