# The panel width a set of figures can share

Works out the widest plot area that every figure in a set can use while
still fitting the canvas. Pass the answer to
[`fig_save()`](https://dansemakula.github.io/figspec/reference/fig_save.md)
and the figures come out with matching plot areas, which is what makes
them look like a set on the page.

## Usage

``` r
fig_panel_width(
  plots,
  journal = NULL,
  column = NULL,
  width = NULL,
  units = c("mm", "cm", "in"),
  format = NULL
)
```

## Arguments

- plots:

  A list of plots, or one plot.

- journal:

  Registry id. Supplies the canvas width.

- column:

  Which of the journal's stated column widths to fit.

- width:

  Canvas width, if you are not sizing to a journal.

- units:

  Units for `width` and for the returned value.

- format:

  File format the figures will be written in, for example `"tiff"`. Text
  is measured in the font the device resolves, so measuring on the
  device you will actually save with is what makes the answer exact.
  Defaults to the journal's first accepted format.

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
library(ggplot2)
figs <- list(
  a = ggplot(mtcars, aes(wt, mpg)) + geom_point(),
  b = ggplot(mtcars, aes(wt, mpg)) + geom_point() + labs(y = "A much longer label")
)
fig_panel_width(figs, journal = "frontiers")
#> [1] 71.33381
#> attr(,"per_figure")
#>        a        b 
#> 71.33381 71.33381 
```
