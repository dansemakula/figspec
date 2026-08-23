# figspec 0.1.0

First release.

## What it does

Builds a figure to a specification, exports it at exactly that size and
resolution, then checks the result and reports where it falls short. A journal
is one way to supply a specification; a panel size, a house style or a
hand-written list of requirements are others.

Checks a figure against the requirements the target journal actually states,
before the figure is submitted rather than after it reaches production.

* `fig_check()` reports up to 21 properties: width, height, resolution,
  file format, file size, type size, font, text case, text colour, line width,
  point outline, colour mode, red/green pairing, greyscale separability,
  colour-vision separability, redundant coding, series count, panel count,
  panel labels, axis furniture, axis origin and number formatting.
* `theme_journal()` applies every requirement a theme can express, layered so a
  house style can never override a journal's rule.
* `fig_save()` saves at the journal's stated width and resolution and
  re-checks the file it wrote.
* `check_submission()` checks a whole bundle; `refit_journal()` re-exports a
  figure set for a different journal after a rejection.
* `figspec_chunk_opts()` and `figspec_knitr_setup()` cover R Markdown and
  Quarto, where figure size comes from chunk options rather than `ggsave()`.
* `suggest_art_type()` reports which resolution rule applies, since publishers
  hold line art to three or four times the general minimum.

## The registry

27 entries covering 21 publisher-wide guidelines and 6 individual journals,
across 20 disciplines.

Every entry records the page it was read from and the date it was read. A
requirement a publisher does not state is reported as unspecified, never as a
pass. A field nobody has harvested yet is reported as such, and is not confused
with a publisher's silence.

## Known limits

The registry is about a fifth populated against the full field grid, and says
so per entry via `registry_status()`. Publisher-wide entries are defaults:
publishers state plainly that individual journals override them.

Type size, line width and colour cannot be recovered from a saved raster, so
those checks need the plot object rather than the file.

## Sizing by panel

* `fig_save()` takes `panel_width` and `panel_height`, which set the plot area
  rather than the image. The canvas is worked out from `canvas = panel +
  decoration`, where the decoration is measured on the device the figure is
  destined for. Give a canvas and a panel and both are honoured, with the slack
  going to the margin; ask for a pair that cannot exist and the error names the
  two values that would work.
* `fig_panel_width()` returns the widest plot area a set of figures can share,
  so a submission comes out even. Panel spread is reported by
  `check_submission()` but never as a pass or a failure: no publisher asks for
  it.
* `fig_panel_size()` sets a panel without saving, and `fig_geometry()` reports
  where the space in a figure is going.

## Specifications without the registry

* `fig_check()` and `fig_save()` take a specification from `journal_spec()` or a
  plain named list, not only a registry id. `fig_check()` with no specification
  inspects the figure and judges nothing.
* Four distinct answers where a requirement is absent, kept apart because they
  mean different things: *not specified by publisher*, *not yet harvested for
  this journal*, *not specified* (a user's own specification is silent), and
  *no specification given*.

## Errors

* Every error carries a class — `figspec_bad_input`, `figspec_not_found`,
  `figspec_unsupported`, `figspec_bad_registry`, `figspec_missing_arg`,
  `figspec_needs_package`, `figspec_bad_size`, `figspec_size_conflict` and
  others, all inheriting `figspec_error` — so a caller can catch the kind of
  problem rather than matching on wording. Conflicts carry the measured
  numbers as fields on the condition.
* Sizes are validated before any graphics device opens. A zero, negative or
  non-finite width, height or resolution previously ended the R session rather
  than raising an error.

## Panel labels

* `tag_panels()` labels the panels of a figure in the style the journal states
  — capitals for Cell Press, lower case for AGU — so the convention does not
  have to be looked up. A patchwork composition is labelled through patchwork's
  own tags rather than a reimplementation of them; a faceted plot has the
  labels drawn into its panels and the strips removed, which is the convention
  for journals that treat facets as sub-figures.
* `fig_check()` now evaluates the panel-label rule on faceted figures. It
  previously counted only composed sub-figures, so a faceted figure was never
  examined and passed a rule it may well have breached. Labels applied by hand
  are recognised, but only when they form a complete tag sequence: one text
  label per panel reading "n=11" is an annotation, not a panel label.

## Seeing where the space goes

* `fig_geometry()` now reports decoration per side — left, right, top, bottom,
  and the gaps between panels — not only as a total. A total is enough to
  compute a canvas but does not say what to change: 26 mm on the right is a
  legend and 12 mm on the left is axis labels, and those have different fixes.
* It prints as a readable summary, largest consumer first, rather than as a
  wide data frame, and `plot()` draws the figure to scale: the canvas, every
  panel, and each band of decoration labelled with its millimetres.
