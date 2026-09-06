# Cross-system figure support before the first release

Checkpoint: `7d84c79` (`Add cross-system figure export checkpoint`)

## Product promise

figspec should not require a researcher to rebuild a figure in ggplot2 before
using the package. The common workflow should remain:

1. supply a live figure and a specification;
2. apply the requirements that the figure's plotting system exposes;
3. export at the requested physical size and resolution; and
4. inspect the file that was actually written.

The package must report the difference between a requirement it applied, a
property it verified and a property that the plotting system does not expose.

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

Each adapter should eventually implement a small internal contract:
`detect`, `transform`, `render`, `semantic_evidence` and `panel_geometry`.
Unsupported operations return a declared capability result, not a guessed
value.

## Website and documentation placement

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

### Navigation and generated pages

* Add the new guide to the Guides menu, article index and article sequence in
  `_pkgdown.yml`.
* Update the reference-index descriptions for the six universal functions and
  label the ggplot2-only groups explicitly.
* Update `DESCRIPTION`, package-level help, `NEWS.md` and `inst/CITATION` only
  where their capability descriptions require it; the citation title does not
  need a plotting-system list.
* Regenerate `man/`, the options guide and `docs/`; then validate search,
  sitemap, breadcrumbs, guide rails and local links.

## Implementation sequence

1. Harden the adapter contract and add capability results to reports.
2. Add lattice and Plotly semantic extractors where reliable.
3. Complete mixed-system submission, refit, preview and geometry behaviour.
4. Add all function examples and the dedicated guide.
5. Rebuild the website and inspect every new example at desktop and narrow
   browser widths.
6. Run the publication gate from a clean source tarball.

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
