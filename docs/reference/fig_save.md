# Save a figure at an exact size and resolution

Saves a figure built to a specification. A journal is one way to supply
one: name a journal and the size, resolution, file format and font come
from its published requirements. Give a panel size instead, or as well,
and the plot area is set to that size exactly. Give neither and this
behaves like
[`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html)
with millimetres as the default unit and the written file checked
afterwards.

## Usage

``` r
fig_save(
  filename,
  plot = ggplot2::last_plot(),
  spec = NULL,
  column = NULL,
  width = NULL,
  height = NULL,
  panel_width = NULL,
  panel_height = NULL,
  units = c("mm", "cm", "in"),
  dpi = NULL,
  check = TRUE,
  art_type = c("auto", "colour", "bw", "line", "combination"),
  ...
)
```

## Arguments

- filename:

  Output path. The extension selects the format. With a journal and no
  extension, the journal's first accepted format is used.

- plot:

  Plot to save: a ggplot, a patchwork composition, or a `gtable`.
  Defaults to the last plot displayed.

- spec:

  Optional specification: a registry id such as `"cell_press"`, a
  `figspec_spec`, or a named list of requirements. When given, it
  supplies the canvas width, resolution, format and font.

- column:

  Which of the journal's stated column widths to fit. Only meaningful
  with `spec`; defaults to `"single"` when one is given.

- width:

  Canvas width. Overrides the journal's column width.

- height:

  Canvas height. Defaults to three quarters of the canvas width, which
  is a convenience, not a journal requirement.

- panel_width, panel_height:

  Size of the plot area itself. A number, or `"max"` for the largest
  that fits the canvas. With facets or a patchwork composition this
  applies to each panel.

- units:

  Units for `width`, `height`, `panel_width` and `panel_height`.

- dpi:

  Resolution. Defaults to the journal's stated minimum, or 300.

- check:

  Whether to check the result and report failures as a warning. Only
  checks against a journal when one is given.

- art_type:

  Resolution category. `"auto"` classifies the live plot; explicit
  choices are `"colour"`, `"bw"`, `"line"`, and `"combination"`.

- ...:

  Passed to
  [`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html).

## Value

The path to the written file, invisibly, with the achieved geometry
attached as the `"figspec_geometry"` attribute. See
[`fig_geometry()`](https://dansemakula.github.io/figspec/reference/fig_geometry.md).

## Canvas and panel

A figure has two widths:

- the **canvas**, which is the image file, and

- the **panel**, which is the plot area left once the axis titles, axis
  text, tick marks, legend and margins have taken their share.

`width` sets the canvas. `panel_width` sets the panel. They are not
alternatives and they are not in conflict: the two are related by
`canvas = panel + decoration`, and the decoration is measured, not
guessed. Give one and the other is worked out. Give both and both are
honoured, with any slack going to the margin so that neither number is
quietly adjusted. Ask for a pair that cannot exist and the error reports
the two values that would work, because you cannot arrive at them
without this measurement.

Panel size is what makes a set of figures look like a set. Two figures
saved at the same canvas width have different panel widths if their
y-axis labels differ in length, and on the page they look mismatched. No
journal states a rule about this, so figspec never reports it as a
compliance failure — but it is usually what an author is trying to fix.

`panel_width = "max"` takes the widest panel that still fits the canvas
you are allowed. Under a journal, that is the widest panel that fits the
column, which gives every figure in a submission the same panel width
without your having to work out what it is.

## What `column` means

Journals lay their pages out in columns, and state a figure width for
each one a figure may span. `column` selects between the widths that
journal publishes: `"single"` fits one text column, `"double"` spans the
page, and some publishers also state `"half"`, `"onehalf"` or
`"triple"`. The names and the millimetres both come from the journal, so
they differ between publishers — Science's single column is 57 mm where
Cell Press's is 85 mm. Call
[`fig_columns()`](https://dansemakula.github.io/figspec/reference/fig_columns.md)
to see what a journal offers, and
[`fig_width()`](https://dansemakula.github.io/figspec/reference/fig_width.md)
for one value.

`column` is a lookup into a journal's own layout, so it means nothing
without `spec`. Sizing without a specification is what `width` is for.

## See also

[`fig_panel_size()`](https://dansemakula.github.io/figspec/reference/fig_panel_size.md)
to set a panel size without saving,
[`fig_columns()`](https://dansemakula.github.io/figspec/reference/fig_columns.md)
for a journal's stated widths.

## Examples

``` r
library(ggplot2)
p <- ggplot(ggplot2::mpg, aes(displ, hwy, colour = class)) + geom_point()

# To a journal's requirements, saved in a format that journal accepts
out <- file.path(tempdir(), "figure_1.tiff")
styled <- p + theme_spec("frontiers")
styled

fig_save(out, styled, spec = "frontiers")
#> Warning: Saved figure could not be certified against 1 recorded requirement(s) of 'Frontiers journals': Line width.
unlink(out)

# To an exact panel size, no journal involved
panelled <- file.path(tempdir(), "figure_2.png")
fig_save(panelled, p, panel_width = 62)
unlink(panelled)

# \donttest{
# To a project specification supplied directly in R. This opens a second
# graphics device, so it remains a worked website example without slowing
# CRAN's ordinary example pass.
report_spec <- list(
  name = "Quarterly research report",
  columns = list(full = 160),
  formats = "png",
  dpi_min = 300,
  font_min_pt = 9
)
report_file <- file.path(tempdir(), "report-figure.png")
fig_save(report_file, p + theme_spec(report_spec),
         spec = report_spec, column = "full")
unlink(report_file)
# }

# Working the canvas out from the panel means opening a device to measure
# the decoration on, which is slow enough that the rest of the tour is kept
# out of the timed examples rather than cut from the documentation.
# \donttest{
widest <- file.path(tempdir(), "figure_3.tiff")

# The widest panel that still fits the column
fig_save(widest, p, spec = "frontiers", panel_width = "max")
#> Warning: Saved figure could not be certified against 1 recorded requirement(s) of 'Frontiers journals': Line width.
unlink(widest)

# Where the space in a figure went
measured <- file.path(tempdir(), "figure_4.png")
fig_geometry(fig_save(measured, p, panel_width = 62))
#>
#> ── Figure geometry ─────────────────────────────────────────────────────────────
#>   canvas  108.2 x 81.1 mm
#>   panel   62 x 68 mm
#>
#> Decoration - where the rest of the space goes
#>   46.2 mm across, 13.1 mm down   (sides are not separable for a composition)
#>
#> ℹ `plot()` this to see it.
unlink(measured)
# }
```
