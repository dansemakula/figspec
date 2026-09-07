# Inspect a figure and verify it against a specification

Accepts a live figure made with ggplot2, lattice, Plotly, base graphics
or grid, or the path to an exported figure file. With no specification
it reports what can be measured without issuing pass or fail claims. A
specification may come from the included registry, your own registry, or
a named list supplied directly in R. For plotting systems that expose
fewer editable details than ggplot2, figspec renders a temporary file
and verifies the properties recorded there. The report identifies any
requirements that need evidence from the original plotting code or
another source.

## Usage

``` r
fig_check(
  x,
  spec = NULL,
  column = NULL,
  width = NULL,
  height = NULL,
  units = c("mm", "cm", "in"),
  dpi = NULL,
  format = NULL,
  colour_mode = NULL,
  color_mode = NULL,
  art_type = c("auto", "colour", "bw", "line", "combination")
)
```

## Arguments

- x:

  A supported live figure, or a path to a figure file. Live figures
  include ggplot2 and patchwork objects, lattice plots, Plotly and other
  HTML widgets, grid grobs, recorded base plots, and base-graphics code
  wrapped in a function or one-sided formula.

- spec:

  Optional specification: a registry id such as `"frontiers"`, a
  `figspec_spec`, or a named list of requirements.

- column:

  Which column width the figure is intended for. One of `"single"`,
  `"onehalf"` or `"double"`.

- width, height:

  Intended output size. Defaults to the width selected by `column` in
  the specification. Ignored when `x` is a file, whose real size is
  measured.

- units:

  Units for `width` and `height`.

- dpi:

  Resolution. For a live figure, the resolution you intend to save at.
  For a file, the resolution it was written at. Supply this value when a
  raster lacks embedded resolution metadata, as files written by base
  R's [`png()`](https://rdrr.io/r/grDevices/png.html) and
  [`tiff()`](https://rdrr.io/r/grDevices/png.html) devices often do;
  figspec can then calculate its physical size from the pixel
  dimensions.

- format:

  Output format, for example `"tiff"`. Only used when `x` is a live
  figure.

- colour_mode:

  Intended output colour model for a live figure. Defaults to `"RGB"`;
  [`fig_save()`](https://dansemakula.github.io/figspec/reference/fig_save.md)
  supplies `"CMYK"` when it selects a CMYK-capable vector device.

- color_mode:

  American spelling of `colour_mode`. Takes precedence when supplied.

- art_type:

  Which resolution rule applies. Publishers set different minimums for
  different kinds of artwork: Cell Press asks 300 dpi for colour or
  greyscale, 500 for black and white, and 1000 for line art. `"auto"`
  classifies a plot from what it actually draws. For a saved file that
  no longer contains that evidence, it applies the strictest stated rule
  and records the category used in the report. `"color"` is accepted as
  an alias for `"colour"`.

## Value

An object of class `figspec_report`, a data frame of one row per
requirement.

## Details

Each requirement is reported with one of five outcomes. `pass` and
`fail` mean what they say. `unspecified` means the selected
specification gives no rule for that property. `unknown` means the
requirement exists but this input does not contain the needed evidence,
such as type size in a raster file. `invalid` means the input is not a
readable file of the type its name claims. A pass applies to its
individual requirement; the complete report shows whether every recorded
requirement has been addressed.

PDF, EPS and SVG files can record the size used for each string, so
figspec reads those values from the completed file. This matters because
R's [`pdf()`](https://rdrr.io/r/grDevices/pdf.html) and
[`postscript()`](https://rdrr.io/r/grDevices/postscript.html) devices
round text to whole points: a theme asking for 8.8 pt writes 9 pt into
the file, and one asking for 5.2 pt writes 5. Reading a PDF requires the
pdftools package. Raster files do not retain point sizes, so their
typography row is marked `unknown` and directed to review of the
editable plot.

## See also

[`fig_save()`](https://dansemakula.github.io/figspec/reference/fig_save.md)
to export and check in one step,
[`submission_check()`](https://dansemakula.github.io/figspec/reference/submission_check.md)
to review several figures together,
[`spec_get()`](https://dansemakula.github.io/figspec/reference/spec_get.md)
for registry and project specifications, and
[`vignette("figure-systems")`](https://dansemakula.github.io/figspec/articles/figure-systems.md)
for worked examples with different R plotting systems.

## Examples

``` r
library(ggplot2)
p <- ggplot(ggplot2::mpg, aes(displ, hwy, colour = class)) + geom_point()
p


# Inspect first, without judging the plot against external requirements.
fig_check(p)
#>
#> ── Figure inspection ───────────────────────────────────────────────────────────
#> checked: ggplot2 plot
#>
#> ℹ Width            -                           requires: no specification given
#> ℹ Height           -                           requires: no specification given
#> ℹ Resolution       -                           requires: no specification given
#> ℹ File format      -                           requires: no specification given
#> ℹ Type size        smallest 8.8 pt, largest 11 pt
#>                    requires: no specification given
#> ℹ Font             -                           requires: no specification given
#> ℹ Line width       -                           requires: no specification given
#> ℹ Colour mode      RGB                         requires: no specification given
#> ℹ Colour pairs     red and green both used (#F8766D, #53B400)
#>                    requires: no specification given
#> ℹ Greyscale        21 pair(s) merge in greyscale: #C49A00/#53B400,
#>                    #C49A00/#FB61D7, #C49A00/#F8766D, #C49A00/#00C094 and 17
#>                    more
#>                    requires: no specification given
#> ℹ Colour vision    colours merge under deuteranopia (4), protanopia (3),
#>                    tritanopia (3)
#>                    requires: no specification given
#> ℹ Redundant coding colour is the only cue: all series share one shape and one
#>                    line type
#>                    requires: no specification given
#> ℹ File size        -                           requires: no specification given
#>
#> ℹ Nothing was checked: no specification was given. Pass a registry id or a
#>   named list of requirements to have these judged.

# Verify the same plot against project requirements supplied directly in R.
report_spec <- list(
  name = "Quarterly research report",
  columns = list(full = 160),
  dpi_min = 300,
  formats = "png",
  font_min_pt = 9
)
fig_check(p, report_spec, column = "full", height = 95,
          dpi = 300, format = "png")
#>
#> ── Quarterly research report ───────────────────────────────────────────────────
#> checked: ggplot2 plot
#>
#> ✔ Width                160 mm                  requires: full 160 mm
#> ℹ Height                95 mm                  requires: not specified
#> ✔ Resolution           300 dpi                 requires: min 300 dpi for colour
#> ✔ File format      PNG                         requires: PNG
#> ✖ Type size        smallest     8.8 pt, largest      11 pt  requires: min 9 pt
#> ℹ Font             -                           requires: not specified
#> ℹ Line width       -                           requires: not specified
#> ℹ Colour mode      RGB                         requires: not specified
#> ℹ Colour pairs     red and green both used (#F8766D, #53B400)
#>                    requires: not specified
#> ℹ Greyscale        21 pair(s) merge in greyscale: #C49A00/#53B400,
#>                    #C49A00/#FB61D7, #C49A00/#F8766D, #C49A00/#00C094 and 17
#>                    more
#>                    requires: not specified
#> ℹ Colour vision    colours merge under deuteranopia (4), protanopia (3),
#>                    tritanopia (3)
#>                    requires: not specified
#> ℹ Redundant coding colour is the only cue: all series share one shape and one
#>                    line type
#>                    requires: not specified
#> ℹ File size        -                           requires: not specified
#>
#> ✖ 1 requirement not met.
```
