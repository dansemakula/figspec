# Adversarial review of the API migration plan

Date: 2026-09-05

## Verdict

The compatibility policy is a clean pre-CRAN break, as recorded below. No
renaming should begin until the repaired release gates pass together and a new
verified green recovery archive is recorded. The rename should then proceed
from the specification resolver outward, one tested family at a time.

No function names were changed during this review.

## Recovery point

A complete post-repair, pre-rename archive is recorded at:

```text
/Users/dan/Documents/ChatGPT/Figspec-backups/Figspec-pre-api-rename-green-2026-09-05.tar.gz
```

It represents the repository after the full release gate and independent
technical review passed. Its SHA-256 checksum is stored beside it in a
`.sha256` file.

The earlier pre-review archive remains available at:

```text
/Users/dan/Documents/ChatGPT/Figspec-backups/Figspec-pre-api-rename-2026-09-05.tar.gz
```

It contains the working directory, Git metadata, tracked modifications,
untracked files, source code and generated website. The archive passed
`gzip -t`, contains 1,692 entries and has this SHA-256 digest:

```text
89081d1f1d2b90a180ee85ad7340f10bcddfcd4e8b7e5f62773518a07f24d9a1
```

Its checksum is also stored beside the archive in a `.sha256` file.

## Independent findings and their resolution

### 1. The pre-migration baseline was repaired

The first review found six failed expectations, one test error and four
completeness gaps. Those defects were corrected before any rename. On
2026-09-05 the package passed 2,591 expectations with no failures or errors;
both completeness audits were clean; coverage was 89.6%; every supported
output format was exercised independently; and the separate real 250,000-row
stress render passed.

A clean source tarball also passed `R CMD check --as-cran` with no errors or
warnings. The only NOTE was the exact expected incoming-feasibility note for a
new submission and GitHub Pages URLs that will remain unavailable until launch.
The release gate now rejects any nonzero check process and any NOTE whose
contents do not match that temporary allowlist exactly.

The website is no longer rebuilt destructively in place. It is installed from
the current source into a temporary library, built outside the package tree,
checked for pages, assets, links, anchors, search entries and sitemap entries,
then copied to an ignored same-filesystem candidate and promoted only after a
second validation succeeds. An interrupted build therefore cannot enter the R
source tarball or replace the last valid `docs/` site.

### 2. Three proposed names needed correction

The independent review challenged three names, and the objections were
accepted:

- `fit_journal()` should become `fig_apply_spec()`, not `fig_fit()`. The
  function receives a specification and returns a component added to a ggplot;
  it does not receive and fit a completed figure.
- `figspec_chunk_opts()` should become `figspec_knitr_options()`. This visibly
  pairs it with `figspec_knitr_setup()` and spells out `options`.
- `journal_palette()` should become `spec_style_palette()`, not
  `spec_palette()`. The palette is stored under the optional `house_style`
  section and is explicitly not a compliance requirement.

The complete corrected map remains in `dev/api-naming.md`.

### 3. Storage-schema migration is out of scope

Renaming the installed `journals.yaml` file or its top-level `journals:` key
would not be a function-name cleanup. It would change a versioned storage
format used by validation, harvesting, tests and contributor documentation.
The API migration will leave that file, key and `schema_version` unchanged.

Neutral internal cache names may still be introduced because they are not a
persistent file format, but they must be covered by registry-state tests.

### 4. Compatibility policy: clean pre-CRAN break

The production Pages URLs still return 404 and the package has not reached
CRAN. The migration therefore uses a clean break so the first public release
has one clear API: no deprecated wrappers and no former canonical function
pages. NEWS will contain the complete migration table. The site retains only
the intentional American-spelling, package-help and S3-help redirects recorded
in `dev/site-redirects.csv`; each redirect is checked for a matching canonical
URL, an existing local target and loops. The undocumented historical
`set_panel_size` and `panel_size` help aliases are removed.

### 5. Output-set atomicity is a separate functional issue

`fig_refit()` currently writes destination files one at a time. A later failure
can therefore leave earlier files in place. The rename must not claim that the
whole output operation is transactional. Atomic set replacement can be added
and tested as a separate publication-hardening change.

## Breakage surface

The rename reaches beyond function declarations:

- About 950 call-like occurrences appear in authored R code, tests, vignettes,
  examples and configuration; about 700 more appear in generated help and
  website files.
- `spec_get()` replaces the resolver used by nearly every specification-aware
  function, so it is the root of the internal dependency graph.
- Named `journal =` calls occur in functions whose names do not change,
  including `fig_save()`, `fig_check()`, `fig_width()`, `fig_columns()` and
  `fig_panel_width()`.
- `figspec_fit` stores `journal` in its `config` attribute.
- Figure and submission reports store `journal` and `journal_id`; their print
  and subset methods read and remove those fields.
- Table, media and graphical-abstract objects return a `journal` field.
- `merge_figspec_reports()` copies the same attributes.
- Error conditions include function names and the public subclass
  `figspec_column_without_journal`.
- `inst/extdata/options-examples.yml` is keyed by current function and argument
  names, while `data-raw/make-options-table.R` contains a manual function-group
  list.
- `_pkgdown.yml`, `dev/audit.R`, maintainer scripts, README, NEWS,
  CONTRIBUTING and all vignette sources contain hard-coded names.
- `NAMESPACE`, `man/`, `vignettes/options.Rmd` and `docs/` are generated and
  must be rebuilt rather than patched manually.
- A clean pkgdown build must preserve custom JavaScript, CSS and `.nojekyll`.

One specific code hazard must be removed first: `figspec_knitr_setup()` calls
the option helper with six positional arguments. Convert that call to named
arguments before changing the helper's formal order.

## Required execution order

1. Preserve the verified pre-migration state and its checksum.
2. Keep the approved maps and complete current/final API contracts frozen.
3. Apply the chosen clean pre-CRAN break: no obsolete wrappers or canonical
   pages, apart from the four explicitly approved help/spelling redirects.
4. Introduce `spec_get()` and migrate internal calls to named arguments.
5. Rename and test each family separately: specification, figure and
   `figspec_fit`, style, reports/checks, registry maintenance, then knitr.
6. Update the options-example YAML and every authored documentation source,
   then make the family state the final authored edit in that checkpoint.
7. Run roxygen, regenerate the options vignette, render all vignettes and clean
   build pkgdown.
8. Audit both source and generated output for former names, permitting only
   approved redirects and migration notes. If any gate fails, revert that
   family and its state together.
9. Build and install the tarball into an empty library, then test it from a
   separate directory in a fresh R process.
10. Complete real-data, real-file, security, website and CRAN checks described
    in `dev/api-naming.md`.

## Acceptance gates

- Zero test failures and zero completeness gaps before and after migration.
- The exact approved export set, formal signatures, defaults and order.
- All S3 methods registered and working.
- Explicit tests for report attributes, returned fields, error classes and
  print/subset behaviour.
- Old names absent except in approved compatibility or migration locations.
- Real small, medium and large plot tests, including a new case larger than the
  current approximately 100,000-row stress coverage.
- Separate real round trips for every supported file format so one missing
  optional device cannot skip later formats.
- Raster text correctly reported as unknowable and vector text inspected where
  supported.
- Optional tools tested both present and deliberately unavailable.
- Offline examples and vignettes; clean website with valid links, assets,
  search index and sitemap.
- Clean installed-package smoke test from outside the repository.
- `R CMD check --as-cran` with no errors, warnings or avoidable notes.
- Linux, Windows and macOS checks during phase 6.
