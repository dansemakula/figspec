# Changelog

## figspec 0.1.0

This is the first public release of figspec.

figspec enables researchers and other R users to build, export and
verify figures and tables against the specifications their work must
meet. A specification can come from a journal, a publisher, a house
style, an organisation or the needs of a particular project.

### Build and export figures to a specification

- [`fig_apply_spec()`](https://dansemakula.github.io/figspec/reference/fig_apply_spec.md)
  brings a specification into a ggplot while it is still editable.
  [`theme_spec()`](https://dansemakula.github.io/figspec/reference/theme_spec.md)
  applies the recorded typography requirements, and can combine them
  with a reusable house style. When the two specify the same property,
  the requirement is used; other house-style choices are kept.
- [`fig_save()`](https://dansemakula.github.io/figspec/reference/fig_save.md)
  exports a figure at the required physical dimensions, resolution and
  file format. It verifies both the editable plot and the file written
  to disk, because each contains information the other does not.
- [`figspec_knitr_options()`](https://dansemakula.github.io/figspec/reference/figspec_knitr_options.md)
  and
  [`figspec_knitr_setup()`](https://dansemakula.github.io/figspec/reference/figspec_knitr_setup.md)
  carry the same dimensions, resolution and output settings into R
  Markdown and Quarto documents.
- [`fig_refit()`](https://dansemakula.github.io/figspec/reference/fig_refit.md)
  prepares a complete set of editable plots for a new specification,
  making it easier to move figures between journals, reports or other
  destinations without resizing finished image files.

### Verify figures before delivery

- [`fig_check()`](https://dansemakula.github.io/figspec/reference/fig_check.md)
  reviews the requirements recorded in a specification and reports what
  passes, what fails and what cannot be determined. Checks cover
  dimensions, resolution, format, file validity, typography, line
  weights, colour use, visual distinction, panel labels, axes, number
  formatting and relevant properties of raster and vector files.
- [`submission_check()`](https://dansemakula.github.io/figspec/reference/submission_check.md)
  reviews figures and tables, as live objects or saved files, together.
  [`submission_detail()`](https://dansemakula.github.io/figspec/reference/submission_detail.md)
  opens the complete report for any one item in the collection.
- [`fig_suggest_art_type()`](https://dansemakula.github.io/figspec/reference/fig_suggest_art_type.md)
  helps select the appropriate resolution category for colour,
  greyscale, line or combination artwork while keeping the recorded
  source guidance visible.
- [`colour_safety_check()`](https://dansemakula.github.io/figspec/reference/colour_safety_check.md)
  examines colour-vision and greyscale separation and reports whether
  colour is supported by another visual cue such as shape or line type.
- [`media_check()`](https://dansemakula.github.io/figspec/reference/media_check.md)
  verifies the format, frame dimensions, file size and, when FFmpeg is
  available, the codec or bit rate of supplementary video and audio.

figspec does not turn missing information into a pass. It distinguishes
a requirement stated by the source, a field reviewed but not stated, a
field that has not yet been reviewed, and a property that cannot be
recovered from the available input.

### Control the space available for data

- [`fig_panel_size()`](https://dansemakula.github.io/figspec/reference/fig_panel_size.md)
  sets the physical size of the plotting panel rather than only the size
  of the surrounding image.
- [`fig_panel_width()`](https://dansemakula.github.io/figspec/reference/fig_panel_width.md)
  finds a panel width that a set of figures can share, even when their
  labels, legends and margins require different amounts of space.
- [`fig_save()`](https://dansemakula.github.io/figspec/reference/fig_save.md)
  can export by panel size and calculate the canvas required around it.
  It can also find the largest panel that fits a fixed canvas.
- [`fig_geometry()`](https://dansemakula.github.io/figspec/reference/fig_geometry.md)
  reports the panel, canvas and space used on each side by labels,
  legends, margins and gaps between panels.

These tools also work with faceted plots and supported multi-panel
compositions, allowing every panel to retain a deliberate physical size.

### Improve clarity and consistency

- Built-in colour palettes are designed to remain distinguishable for
  readers with common colour-vision deficiencies and when reproduced in
  greyscale.
- Colour scales can be combined with shape and line-type scales so
  groups do not depend on colour alone.
- [`spec_linewidth()`](https://dansemakula.github.io/figspec/reference/spec_linewidth.md),
  [`figspec_shapes()`](https://dansemakula.github.io/figspec/reference/figspec_shapes.md)
  and
  [`figspec_linetypes()`](https://dansemakula.github.io/figspec/reference/figspec_linetypes.md)
  provide values suited to figures that will be viewed at their final
  size.
- [`fig_tag_panels()`](https://dansemakula.github.io/figspec/reference/fig_tag_panels.md)
  labels faceted plots and multi-panel compositions using the convention
  in the selected specification or a convention supplied by the user.

### Use publication requirements or create your own

- [`spec_save()`](https://dansemakula.github.io/figspec/reference/spec_save.md)
  writes project, organisational or publication specifications to a
  validated YAML registry for reuse. It appends new ids, requires
  explicit permission before replacing an existing id and leaves the
  previous file intact if the updated registry cannot be written or
  validated.

The bundled registry contains 29 carefully sourced profiles. Twenty-two
cover publisher-wide guidance and therefore apply across large journal
portfolios; seven record requirements for individual journals that
publish their own instructions. The included profiles cover major
publishers such as Elsevier, Springer, Wiley, Taylor & Francis, Oxford
University Press, Cambridge University Press, Cell Press, BMJ, Frontiers
and IEEE.

- [`spec_list()`](https://dansemakula.github.io/figspec/reference/spec_list.md)
  searches and filters the registry, while
  [`spec_get()`](https://dansemakula.github.io/figspec/reference/spec_get.md),
  [`fig_columns()`](https://dansemakula.github.io/figspec/reference/fig_columns.md)
  and
  [`fig_width()`](https://dansemakula.github.io/figspec/reference/fig_width.md)
  retrieve the requirements needed in code.
- Every bundled profile records its source and the date that source was
  last checked.
  [`registry_status()`](https://dansemakula.github.io/figspec/reference/registry_status.md),
  [`registry_stale_entries()`](https://dansemakula.github.io/figspec/reference/registry_stale_entries.md)
  and
  [`registry_check_sources()`](https://dansemakula.github.io/figspec/reference/registry_check_sources.md)
  support ongoing review and updating.
- [`spec_register()`](https://dansemakula.github.io/figspec/reference/spec_register.md)
  accepts a specification created in R for the current session.
  [`spec_load()`](https://dansemakula.github.io/figspec/reference/spec_load.md)
  loads reusable specifications from a YAML file.
- House styles can be registered, saved and reloaded independently of
  publication requirements.

### Build, export and verify tables

- [`table_apply_spec()`](https://dansemakula.github.io/figspec/reference/table_apply_spec.md)
  applies measurable table requirements to data frames, matrices and
  tables made with gt, flextable, kableExtra or grid while they remain
  editable.
- [`table_save()`](https://dansemakula.github.io/figspec/reference/table_save.md)
  exports through the table’s own system, checks the completed HTML,
  DOCX, RTF, TeX, PDF or image file when that format is supported, and
  replaces an existing output only after rendering succeeds and the
  result is structurally valid.
- [`table_check()`](https://dansemakula.github.io/figspec/reference/table_check.md)
  combines evidence retained by the editable object with evidence
  recovered from the written file. Rules needing editorial judgement
  remain unresolved instead of being reported as passes.
- [`submission_check()`](https://dansemakula.github.io/figspec/reference/submission_check.md)
  now accepts mixed collections of figures and tables and labels each
  item in its summary.
- [`table_spec()`](https://dansemakula.github.io/figspec/reference/table_spec.md),
  [`media_spec()`](https://dansemakula.github.io/figspec/reference/media_spec.md)
  and
  [`graphical_abstract_spec()`](https://dansemakula.github.io/figspec/reference/graphical_abstract_spec.md)
  retrieve the separate requirements recorded for tables, supplementary
  media and graphical abstracts.

### Reliability and safe defaults

- Saved files are reopened and inspected. Corrupt or incorrectly
  labelled files are reported as invalid rather than compliant.
- Inputs that could produce an unsafe path, an unusable graphics device
  or an ambiguous result are rejected with a clear error before files
  are written.
- Raster and vector readers limit the amount of untrusted data they
  allocate and validate the structural markers needed for a reliable
  result.
- Registry files are checked for invalid, unknown or contradictory
  fields before their specifications are loaded.
- Registry harvesting places proposed values and exact source excerpts
  into a review queue. It does not add unreviewed material directly to
  the trusted registry.

figspec is licensed under GNU GPL version 3 or later. Third-party
dependencies and generated website assets retain their own compatible
licences.

### Continuing development

The specification registry will continue to grow as additional
publishers and individual journals are reviewed. Publisher-wide profiles
provide a useful default, but an individual journal’s current
instructions take priority when they differ.

Some properties exist only in the editable plot. Type size, line width
and colour mappings generally cannot be recovered from a saved raster
image, so figspec recommends checking plot objects before export and the
written files afterwards. PDF, EPS and SVG may preserve some typography
information that a raster file does not.

Publication guidance also changes over time. Source links, review dates
and registry-maintenance tools are included so users and contributors
can see what figspec is applying and identify records that need to be
checked again.
