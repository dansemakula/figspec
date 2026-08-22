# data-raw

Working material behind `inst/extdata/journals.yaml`. Excluded from the built
package by `.Rbuildignore`, kept in the repository so every registry value can
be traced back to the publisher page it was read from.

- `registry-source-notes.md` — verbatim quotes harvested from publisher author
  guidelines, with the URL and the date each was read. When a publisher stated
  nothing for a field, that is recorded as `NOT STATED` rather than filled in.

Two entries carry caveats:

- **Wiley** — the source PDF is self-dated "Updated 1 September 2016". Re-verify
  against current Wiley Author Services before relying on it.
- **APS (Physical Review)** — harvested from a search summary, never fetched
  verbatim, and therefore **not shipped** in the registry. Do not add it without
  reading the publisher page directly.
