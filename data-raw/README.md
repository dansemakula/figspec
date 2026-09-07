# data-raw

Working material behind `inst/extdata/journals.yaml`. Excluded from the built
package by `.Rbuildignore`, kept in the repository so every registry value can
be traced back to the publisher page it was read from.

- `registry-source-notes.md` — verbatim quotes harvested from publisher author
  guidelines, with the URL and the date each was read. When a publisher stated
  nothing for a field, that is recorded as `NOT STATED` rather than filled in.
- `harvest.R` — a provenance-first discovery pipeline for live HTML, publisher
  PDFs, and dated Internet Archive snapshots. It caps downloads, rejects local
  and private URLs, fingerprints each fetched document, and writes every exact
  candidate excerpt to a review CSV. Every decision begins as `unreviewed`; a
  person must classify the wording as a requirement, advice, or absence before
  copying any value into the registry. The harvester never edits the registry.

Two entries carry caveats:

- **Wiley** — the source PDF is self-dated "Updated 1 September 2016". Re-verify
  against current Wiley Author Services before relying on it.
- **APS (Physical Review)** — the live page refused automated access. The
  shipped entry was read from a dated 2026-04-04 Internet Archive snapshot, and
  its verification date deliberately records that snapshot rather than the day
  the harvester happened to retrieve it.
