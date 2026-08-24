# Preview a figure at the size it will actually be published

The most common way a compliant figure becomes non-compliant is being
designed on a laptop at roughly 7 by 5 inches and submitted into an 85
mm column. Everything in it is then reduced by more than half. This
opens a device at the journal's real column width, so what you are
looking at while you iterate is the size a reader will see.

## Usage

``` r
figspec_preview(
  plot = ggplot2::last_plot(),
  journal,
  column = "single",
  height = NULL,
  units = c("mm", "cm", "in")
)
```

## Arguments

- plot:

  Plot to preview. Defaults to the last plot displayed.

- journal:

  Registry id.

- column:

  Which column width to preview at.

- height:

  Height. Defaults to three quarters of the width.

- units:

  Units for `height`.

## Value

The plot, invisibly.

## Examples

``` r
library(ggplot2)
p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
if (interactive()) figspec_preview(p, "cell_press", "single")
```
