# Figures and tables from R before the first release

Checkpoint: `7d84c79` (`Add cross-system figure export checkpoint`)

## Product promise

figspec should not require a researcher to rebuild a figure in ggplot2 or
format a table by hand outside R before using the package. The common workflow
should remain:

1. supply a live figure or table and a specification;
2. apply the requirements that its R system exposes;
3. export in the requested format and at the required dimensions; and
4. inspect the file that was actually written.

The package must report the difference between a requirement it applied, a
property it verified and a property that the plotting system does not expose.

At the checkpoint, `table_spec()` only retrieves table guidance. It does not
format, export or verify a table. Only two of the 29 bundled profiles currently
contain table requirements. Both the table engine and the registry coverage
must therefore be completed before the website says that figspec supports
tables to publication specifications.

## Capability model

| Input | Apply visual requirements | Exact canvas | Exact data panel | Inspect live styling | Inspect saved file |
|---|---|---:|---:|---:|---:|
| ggplot2 | Yes | Yes | Yes | Yes | Yes |
| patchwork | Yes | Yes | Yes where its layout is measurable | Yes | Yes |
| base R drawing function or formula | Set typography, line and palette defaults before drawing | Yes | No | Only settings controlled at render time | Yes |
| recorded base plot | No; drawing instructions are already complete | Yes | No | No | Yes |
| lattice | Apply `par.settings` for type, lines, colours and symbols | Yes | Not in the first release unless it can be proved across layouts | Add a lattice-specific extractor | Yes |
| grid grob | Supply inherited graphical defaults | Yes | Only for measurable gtables | Add a grid/gtable extractor where reliable | Yes |
| Plotly | Apply layout fonts and trace colours, markers and line rules | Yes for raster output | No | Add a Plotly-specific extractor | Yes |
| other HTML widget | No general restyling promise | Yes for raster output | No | No common object model | Yes |
| another plotting package | Accept a drawing function as the general fallback | Yes | No unless an adapter can measure it | Depends on a future adapter | Yes |

An explicit colour, font or line setting inside user code may override an
inherited default. figspec must say so rather than describing base or grid
defaults as a guaranteed rewrite.

## Table capability model

The first public release should support these inputs:

| Input | Apply table requirements | Export | Inspect live structure | Inspect saved file |
|---|---|---|---:|---:|
| data frame, tibble or matrix | Build a neutral table with specification-aware defaults | HTML, DOCX, RTF, LaTeX, PDF or raster through an available backend | Yes | Yes where the format retains evidence |
| `gt_tbl` | Use gt's styling and export methods | HTML, DOCX, RTF, LaTeX, PDF and PNG | Yes | Yes |
| `flextable` | Use flextable's formatting and page controls | DOCX, RTF, HTML, PPTX, PNG and SVG | Yes | Yes |
| `knitr_kable` or kableExtra table | Apply supported HTML or LaTeX styling | HTML, LaTeX, PDF and raster | Yes where markup is inspectable | Yes |
| grid/gtable table | Apply inherited graphical defaults | Figure formats | Limited | Figure-file checks only |
| another table package | Accept a supported coercion or an explicit renderer | Depends on the renderer | No claim without an adapter | Yes where the file can be inspected |

The output format matters. A DOCX or RTF table can satisfy a requirement for
editable text; a PNG cannot. An HTML or DOCX file retains rows, columns and
text that can be inspected; a raster file retains only pixels, dimensions and
resolution. PDF occupies the middle: page size and typography may be
recoverable, but the original table structure is not reliable.

## Public API

### Expand the existing universal entry points

* `fig_save()` remains the main cross-system function. Its new `transform`
  argument controls whether figspec applies reachable requirements before
  export. No separate `fig_save_base()`, `fig_save_lattice()` or
  `fig_save_plotly()` functions are needed.
* `fig_check()` accepts the same live inputs. It uses semantic object checks
  where an adapter can supply evidence, renders a temporary file for the
  remaining systems and leaves unrecoverable requirements `unknown`.
* `submission_check()` accepts a named collection containing more than one
  plotting system.
* `fig_refit()` re-exports editable ggplot2, patchwork, base-function, lattice,
  grid and Plotly figures against another specification.
* `fig_preview()` uses an R graphics device for R-rendered figures. For HTML
  widgets it must explain that browser zoom prevents a trustworthy physical
  preview and direct users to the verified export.
* `fig_geometry()` reports canvas geometry from every `fig_save()` result. It
  reports panel geometry only when the layout exposes measurable panels.

### Add parallel table entry points

Use the same noun-verb pattern as the figure API:

* `table_apply_spec(table, spec, ...)` returns an editable table of the same
  supported class with the requirements that its adapter can apply.
* `table_save(filename, table, spec = NULL, transform = TRUE, check = TRUE,
  ...)` writes the table with its native backend, reopens the result and
  attaches the verification report.
* `table_check(x, spec = NULL, ...)` checks a live table or an exported table
  file and uses `pass`, `fail`, `unknown`, `unspecified` and `invalid` with the
  same meanings as figure reports.
* `table_spec()` remains the way to retrieve the recorded table requirements.

Do not add separate functions such as `gt_save_spec()` or
`flextable_save_spec()`. Class adapters belong behind the three common entry
points. For a named collection, extend `submission_check()` with an
`asset_type = c("auto", "figure", "table")` argument and an `asset` column so
it can review figures, tables or a mixed submission without creating a second
collection API. `submission_detail()` can continue to retrieve one full
report.

This proposal changed the reviewed API from 47 to 50 exports and changed the
formal contract of `submission_check()`. The subsequent addition of
`spec_save()` raised the pre-release API to 51 exports. These decisions are
recorded in the API manifest and checked by the strict contract gate.

### Keep system-specific helpers explicit

The following functions should remain clearly labelled as ggplot2 helpers:
`fig_apply_spec()`, `theme_spec()`, `fig_panel_size()`, `fig_panel_width()`,
`fig_tag_panels()`, the `scale_*_figspec()` functions and the house-style theme
functions. They should link to `fig_save()` for other plotting systems.

`fig_suggest_art_type()` and `colour_safety_check()` currently depend on
ggplot2 layers and scales. Before release, investigate lattice and Plotly
extractors. Broaden these functions only when tests prove that mapped data
colours, symbols and line types can be recovered without treating decorative
elements as data. Otherwise their reference pages must state the limitation
and `fig_check()` must leave the corresponding result unknown.

Do not add exported adapter-registration functions for version 0.1.0. Keep
the adapter boundary internal until its interface has been exercised on real
packages. This preserves the reviewed 47-function public API apart from the
intentional `fig_save(transform = TRUE)` addition.

## Internal placement

* `R/figure-systems.R`: detection, capability declarations, transformations
  and rendering adapters only.
* `R/save.R`: validate one user request, resolve the specification and
  geometry, select an adapter, write the file and attach the final report.
* `R/check.R`: combine adapter-provided semantic evidence with independent
  inspection of the rendered file.
* `R/submission.R`: mixed collections and per-figure capability reporting.
* `R/refit.R`: repeat the same `fig_save()` workflow over editable figures;
  do not maintain a second transformation implementation.
* `R/panel.R`: physical panel measurement for systems whose layouts expose it.
* `R/preview.R`: interactive display only; it must not be used as evidence of
  compliance.
* `R/table-systems.R`: table detection, normalized capabilities and adapters
  for data frames, gt, flextable, kableExtra and grid tables.
* `R/table-apply.R`: `table_apply_spec()` orchestration without file I/O.
* `R/table-save.R`: renderer selection, transactional writing and post-export
  checking.
* `R/table-check.R`: live-object and exported-file checks plus the table report
  class.
* `R/table-files.R`: bounded HTML, DOCX, RTF, LaTeX, PDF and raster inspection.

Each adapter should eventually implement a small internal contract:
`detect`, `transform`, `render`, `semantic_evidence` and `panel_geometry`.
Unsupported operations return a declared capability result, not a guessed
value.

Table adapters should use the equivalent internal contract: `detect`,
`transform`, `render`, `semantic_evidence` and `file_formats`. The normalized
evidence should include body dimensions, headings, captions, footnotes,
alignment, borders, type settings, page orientation and editability only when
the source object or file actually exposes them.

### Table specification schema and registry

Expand the validated `tables` schema to hold only independently useful,
sourced fields, including accepted/editable formats, page orientation, maximum
width, typeface and type range, title and caption placement, header rules,
permitted horizontal or vertical rules, decimal alignment, footnote and
abbreviation instructions, row splitting and repeated headers. Each field
needs the same source excerpt and review state used for figure requirements.

Before the table capability is advertised:

1. review table guidance for every bundled publisher/journal profile;
2. record stated rules, explicitly not-stated fields and not-yet-reviewed
   fields separately;
3. add source URLs and last-checked dates for table guidance when it comes from
   a page different from the figure guidance;
4. add schema contradiction and provenance checks; and
5. make `registry_status()` report table-field coverage separately from figure
   coverage.

The launch gate is complete review, not an arbitrary number of populated
fields: a publisher that states no table rule is valid when that absence was
actually checked.

## Website and documentation placement

### Current wording inventory

The table claim is currently distributed rather than confined to one page:

* `DESCRIPTION` and `inst/CITATION` define the package and citation as a
  figure-only product.
* The first paragraph of `README.md` says tables are requirements that figspec
  can retrieve, while the quick start, result definitions and workflow list
  describe figures only.
* `_pkgdown.yml` uses figure-only home metadata and places `table_spec()` under
  "publication assets" rather than a build/export/check workflow.
* `vignettes/figspec.Rmd` gives tables one lookup example beside graphical
  abstracts and media; it has no table creation, export or verification.
* `vignettes/options.Rmd` documents only the lookup argument for
  `table_spec()`.
* `NEWS.md` describes the release as building and checking figures and lists
  tables only as retrieved guidance.
* `R/spec.R` and `man/table_spec.Rd` explicitly promise consultation while a
  table is prepared, not transformation or verification.
* `vignettes/registry.Rmd`, the registry status pages and `CONTRIBUTING.md` do
  not yet expose table-field coverage or a table-specific review workflow.

These authored sources must be changed together. Generated `man/`, `docs/`,
`docs/search.json`, `docs/sitemap.xml` and `docs/llms.txt` follow from them and
must not be edited as substitutes for the source text.

### Home page (`README.md`)

* Add a short, early statement that figspec accepts ggplot2, base R, lattice,
  grid and Plotly figures.
* Replace the present universal phrase "From a plot object" with wording that
  distinguishes full ggplot2 inspection from file-based verification for
  other systems.
* Add one compact example showing the same `fig_save()` call shape for ggplot2,
  base R and lattice. Link the details to a dedicated guide.
* Correct the workflow list: `fig_refit()` works from editable live figures,
  not "saved plot objects".
* Change the main promise, title and summary only after the table release gate
  passes. The final wording can say that figspec helps R users build, export
  and verify figures and tables against the specifications their work must
  meet.
* Add a short table example beside the figure quick start. Do not leave tables
  in the present "related assets" paragraph once they have a complete
  production workflow.

### New guide (`vignettes/plotting-systems.Rmd`)

Title: **Use figspec with different R plotting systems**.

The guide should contain:

1. the capability table above in ordinary language;
2. a base R example using `airquality`, showing the ordinary export beside the
   specification-aware export and the actual file report;
3. a lattice example using `iris`, with visible before-and-after type, colour,
   symbol and line changes;
4. a Plotly example using `mpg`, showing the interactive source and the static
   file produced for submission;
5. a grid/grob example and the distinction between inherited and explicitly
   fixed settings;
6. a mixed `submission_check()` and `fig_refit()` example; and
7. a concise explanation of recorded plots, generic HTML widgets, Chrome and
   Kaleido.

Every static demonstration must be produced by the public API from real data,
then reopened and inspected. Images should be large enough to read in a normal
browser and should include colour plus a non-colour cue where groups differ.

### New table guide (`vignettes/tables.Rmd`)

Title: **Build and check tables from R**.

The guide should explain the table specification first, then demonstrate the
same real summary table as a data frame, gt table and flextable. It should show
an unformatted before table and a specification-aware after table at readable
size, export actual HTML and DOCX files, reopen them, and display the resulting
checks. A longer table should demonstrate portrait/landscape choice, repeated
headers and page splitting. A final example should review figures and tables
together with `submission_check()`.

The guide must distinguish automatically checkable properties from editorial
instructions such as whether a title is sufficiently concise or every
abbreviation has been explained. Those remain `unknown` or manual-review
items, not automated passes.

### Existing guides

* `vignettes/figspec.Rmd`: present ggplot2 as the most deeply supported route,
  not the only route; link to the new guide near the first example and update
  the submission/refit language.
* `vignettes/panels.Rmd`: state near the start that exact panel sizing applies
  to ggplot2-compatible/gtable layouts; link to exact canvas sizing for other
  systems.
* `vignettes/options.Rmd` and
  `inst/extdata/options-examples.yml`: expand the `fig_save()`, `fig_check()`,
  `submission_check()`, `fig_refit()`, `fig_preview()` and `fig_geometry()`
  accordions with system-specific calls.
* `vignettes/journals.Rmd`: one sentence confirming that a publication profile
  can be used with any supported figure input.
* `vignettes/registry.Rmd`: no structural change; only examples that imply
  specifications apply solely to ggplot2 need correction.
* `vignettes/journals.Rmd` and `vignettes/registry.Rmd`: show separate figure
  and table source coverage and explain that some publishers keep them on
  different guidance pages.
* `CONTRIBUTING.md`: document how table requirements are sourced, reviewed and
  tested without copying excessive publisher text.

### Navigation and generated pages

* Add the new guide to the Guides menu, article index and article sequence in
  `_pkgdown.yml`.
* Add a reference-index group named **Building, checking and exporting
  tables** containing `table_spec()`, `table_apply_spec()`, `table_save()` and
  `table_check()`.
* Update the reference-index descriptions for the six universal functions and
  label the ggplot2-only groups explicitly.
* Update `DESCRIPTION`, package-level help, `NEWS.md`, `_pkgdown.yml` and
  `inst/CITATION` from "figures" to "figures and tables" only after the table
  tests and registry review are complete. The citation title does not need a
  list of plotting or table packages.
* Regenerate `man/`, the options guide and `docs/`; then validate search,
  sitemap, breadcrumbs, guide rails and local links.

## Implementation sequence

1. Freeze the three table function names, `submission_check()` change, table
   report metadata and expanded registry schema in the API manifests.
2. Harden the figure adapter contract and add capability results to reports.
3. Add lattice and Plotly semantic extractors where reliable.
4. Implement table detection and a neutral evidence model, then the data-frame,
   gt, flextable and kableExtra adapters one at a time.
5. Implement bounded file inspection and transactional table export.
6. Extend mixed-system submission/refit/preview/geometry behaviour and mixed
   figure/table submission review.
7. Review table guidance for all 29 registry profiles and run the registry
   provenance gates.
8. Add all function examples and both dedicated guides.
9. Change the public figures-and-tables wording only after the functionality
   and registry gates pass.
10. Rebuild the website, inspect every new example at desktop and narrow
    browser widths, and run the publication gate from a clean source tarball.

## Real-functionality test matrix

Use small, medium and large datasets rather than synthetic string checks:

* small: `mtcars` or `airquality`;
* medium: all 150 rows of `iris` and all 234 rows of `ggplot2::mpg`;
* stress: at least 250,000 observations for one base path and one
  object-based path.

For each relevant plotting system test:

* transform on and off;
* an exact-width PNG and TIFF with density read back from the file;
* PDF or SVG when the system has a trustworthy vector renderer;
* long labels, legends, several groups and missing data;
* a mixed-system submission and refit;
* absent optional dependencies, an unavailable browser/Kaleido, CMYK-only
  requirements and failed render cleanup;
* Windows, macOS and Linux through hosted checks.

For tables, use real data at three practical scales: a 5-row descriptive
summary, all 150 `iris` records, and a multi-page table with several thousand
rows for performance and failure behaviour. Include missing values, Unicode,
long headings, decimal alignment, grouped headers, captions, footnotes and
abbreviations. Verify:

* transformation on and off for every supported object class;
* object class and data values are preserved after styling;
* HTML structure and CSS, DOCX editability and page orientation, RTF/LaTeX
  structure, PDF page/type properties and raster dimensions/resolution;
* portrait and landscape output, repeated headers and page splitting;
* a required editable format failing for PNG or other flattened output;
* optional-package failures that name the exact missing package;
* atomic replacement, cleanup after renderer failure and paths containing
  spaces or Unicode; and
* protection against oversized ZIP/XML/HTML input, external XML entities,
  malformed markup and unbounded regular-expression work.

The final gate comprises all testthat tests with zero warnings, the explicit
250,000-row stress run, `R CMD check --as-cran`, clean-tarball installation,
an external consumer smoke test, coverage at or above the existing threshold,
strict API migration audit, rebuilt-site validation and a final retired-name
scan.

## Evidence behind the boundaries

R documents a `recordedplot` as a replayable device display list and warns that
replay can fail for code from other packages; it is therefore an export input,
not a safe editable representation:
<https://search.r-project.org/R/refmans/grDevices/html/recordplot.html>.

Lattice documents `par.settings`, labels, panels and layout as components of a
retained Trellis object, which supports an object adapter:
<https://stat.ethz.ch/R-manual/R-devel/library/lattice/html/trellis.object.html>.

The R Plotly package documents `save_image()` as a Kaleido-backed static image
exporter, while HTML widgets document context-dependent browser sizing. That
is why the browser path is suitable for exact raster pixels but not a claim
about an on-screen physical preview:
<https://search.r-project.org/CRAN/refmans/plotly/html/save_image.html> and
<https://www.htmlwidgets.org/develop_sizing.html>.

gt documents one table object that can be styled before rendering and exported
to HTML, LaTeX, RTF, DOCX, PDF and PNG, while flextable provides native DOCX,
RTF, HTML, PowerPoint and image outputs. kableExtra has separate HTML and
LaTeX paths and uses a browser renderer for HTML-derived images. These are
different object and export models, so one public API should dispatch to
class-specific adapters rather than coercing every table through one package:
<https://gt.rstudio.com/reference/gt.html>,
<https://gt.rstudio.com/reference/gtsave.html>,
<https://search.r-project.org/CRAN/refmans/flextable/html/save_as_docx.html> and
<https://search.r-project.org/CRAN/refmans/kableExtra/html/save_kable.html>.
