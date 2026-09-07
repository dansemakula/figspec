# Save a figure at an exact size and resolution

Saves a figure built to a specification. A journal profile can supply
its published size, resolution, file format and font requirements; a
project or organisational specification works in the same place. You can
also set the panel size directly. figspec writes the file and checks the
completed output.

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
  transform = TRUE,
  check = TRUE,
  art_type = c("auto", "colour", "bw", "line", "combination"),
  ...
)
```

## Arguments

- filename:

  Output path. The extension selects the format. With a specification
  and no extension, its first accepted format is used.

- plot:

  Figure to save. This can be a ggplot2 or patchwork object, a `gtable`
  or grid grob, a lattice plot, a Plotly or other HTML widget, a
  recorded base plot, or base-graphics code wrapped in a function or
  one-sided formula. Defaults to the last ggplot2 plot displayed.

- spec:

  Optional specification: a registry id such as `"cell_press"`, a
  `figspec_spec`, or a named list of requirements. When given, it
  supplies the canvas width, resolution, format and font.

- column:

  Which named width in the specification to fit. Only meaningful with
  `spec`; defaults to `"single"` when one is given.

- width:

  Canvas width. Overrides the width selected by `column`.

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

  Resolution. Defaults to the specification's stated minimum, or 300
  when none is recorded.

- transform:

  Whether to apply the specification's reachable visual requirements
  before export. For ggplot2 and lattice this includes typography and
  line rules together with accessible colour and shape defaults; Plotly
  receives the corresponding layout and trace settings; base graphics
  functions and grid grobs receive specification-aware defaults. A
  completed recorded plot is exported with its existing styling; supply
  the original drawing function when you want defaults applied. Set to
  `FALSE` to preserve any supported plot exactly as supplied.

- check:

  Whether to check the result and report failures as a warning.
  Compliance is judged only when `spec` is supplied.

- art_type:

  Resolution category. `"auto"` classifies the live plot; explicit
  choices are `"colour"`, `"bw"`, `"line"`, and `"combination"`.

- ...:

  Named arguments passed to the renderer selected for the figure:
  [`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html)
  for ggplot2-compatible figures, the graphics device for base, lattice
  and grid figures,
  [`webshot2::webshot()`](https://rstudio.github.io/webshot2/reference/webshot.html)
  for browser raster export, or
  [`plotly::save_image()`](https://rdrr.io/pkg/plotly/man/save_image.html)
  for Plotly vector export.

## Value

The path to the written file, invisibly, with the achieved geometry
attached as the `"figspec_geometry"` attribute. See
[`fig_geometry()`](https://dansemakula.github.io/figspec/reference/fig_geometry.md).

## Canvas and panel

A figure has two widths:

- the **canvas**, which is the image file, and

- the **panel**, which is the plot area left once the axis titles, axis
  text, tick marks, legend and margins have taken their share.

`width` sets the canvas and `panel_width` sets the panel. Their
relationship is `canvas = panel + decoration`, where decoration includes
axes, labels, legends and margins. Give either measurement and figspec
calculates the other. Give both and figspec preserves each value,
placing any extra room in the margin. If the pair needs more room than
the canvas provides, the error gives the canvas width or panel width
that will work.

Panel size is what makes a set of figures look like a set. Two figures
saved at the same canvas width can have different panel widths when
their y-axis labels differ in length. figspec presents this as layout
information and lets you give the set one shared data area.

`panel_width = "max"` takes the widest panel that still fits the canvas
you are allowed. Under a journal, that is the widest panel that fits the
column, which gives every figure in a submission the same panel width
without your having to work out what it is.

## What `column` means

Specifications can name the widths available for a figure. `column`
selects between them: `"single"` often fits one text column and
`"double"` often spans the page, while a project can use names of its
own. Both the names and measurements come from the selected
specification. Call
[`fig_columns()`](https://dansemakula.github.io/figspec/reference/fig_columns.md)
to see the available widths, and
[`fig_width()`](https://dansemakula.github.io/figspec/reference/fig_width.md)
for one value.

`column` is a lookup into the specification, so it requires `spec`. Use
`width` when no specification is needed.

## See also

[`fig_panel_size()`](https://dansemakula.github.io/figspec/reference/fig_panel_size.md)
to set a panel size without saving,
[`fig_columns()`](https://dansemakula.github.io/figspec/reference/fig_columns.md)
for the named widths in a specification, and
[`vignette("figure-systems")`](https://dansemakula.github.io/figspec/articles/figure-systems.md)
for worked examples with ggplot2, base R, lattice, grid and Plotly.

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
