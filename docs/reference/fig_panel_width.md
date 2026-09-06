# Find one panel width that fits every figure

Works out the widest plot area that every figure in a set can use while
still fitting the canvas. Pass the answer to
[`fig_save()`](https://dansemakula.github.io/figspec/reference/fig_save.md)
and the figures come out with matching plot areas, which is what makes
them look like a set on the page.

## Usage

``` r
fig_panel_width(
  plots,
  spec = NULL,
  column = NULL,
  width = NULL,
  units = c("mm", "cm", "in"),
  format = NULL
)
```

## Arguments

- plots:

  The plot or list of plots that should share a panel width.

- spec:

  A registry id, a `figspec_spec`, or a named list containing the
  available canvas widths.

- column:

  Which named width in the selected specification the figures must fit.

- width:

  The available canvas width when you are not using a named
  specification.

- units:

  The units used for `width` and for the returned panel width.

- format:

  File format the figures will be written in, for example `"tiff"`. Text
  is measured in the font the device resolves, so measuring on the
  device you will actually save with is what makes the answer exact.
  Defaults to the specification's first accepted format.

## Value

A single number: the shared panel width. The per-figure maxima are
attached as the `"per_figure"` attribute, so you can see which figure is
the binding constraint.

## Details

`panel_width = "max"` on a single figure takes the widest panel *that
figure* can have, which is the same thing
[`fig_save()`](https://dansemakula.github.io/figspec/reference/fig_save.md)
does anyway. Matching panels is a property of a set, not of one figure:
the figure with the longest axis labels has the least room, and it sets
the width the others have to meet. That is what this measures.

## See also

[`fig_save()`](https://dansemakula.github.io/figspec/reference/fig_save.md)

## Examples

``` r
# \donttest{
library(ggplot2)
figs <- list(
  vehicles = ggplot(ggplot2::mpg, aes(displ, hwy)) + geom_point(),
  economy = ggplot(ggplot2::economics, aes(date, unemploy)) +
    geom_line() + labs(y = "Number of unemployed people")
)
fig_panel_width(figs, width = 160)
#> [1] 141.1546
#> attr(,"per_figure")
#> vehicles  economy
#> 146.3338 141.1546
# }
```
