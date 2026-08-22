# figspec 0.1.0

First release.

## What it does

Checks a figure against the requirements the target journal actually states,
before the figure is submitted rather than after it reaches production.

* `check_journal()` reports up to 21 properties: width, height, resolution,
  file format, file size, type size, font, text case, text colour, line width,
  point outline, colour mode, red/green pairing, greyscale separability,
  colour-vision separability, redundant coding, series count, panel count,
  panel labels, axis furniture, axis origin and number formatting.
* `theme_journal()` applies every requirement a theme can express, layered so a
  house style can never override a journal's rule.
* `ggsave_journal()` saves at the journal's stated width and resolution and
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
