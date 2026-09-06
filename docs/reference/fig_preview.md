# Preview a figure at its intended output size

The most common way a compliant figure becomes non-compliant is being
designed on a laptop at roughly 7 by 5 inches and submitted into an 85
mm column. Everything in it is then reduced by more than half. This
opens a device at the journal's real column width, so what you are
looking at while you iterate is the size a reader will see.

## Usage

``` r
fig_preview(
  plot = ggplot2::last_plot(),
  spec,
  column = "single",
  height = NULL,
  units = c("mm", "cm", "in")
)
```

## Arguments

- plot:

  Figure to preview. Accepts the same live figure inputs as
  [`fig_save()`](https://dansemakula.github.io/figspec/reference/fig_save.md)
  and defaults to the last ggplot2 plot displayed.

- spec:

  A registry id, a `figspec_spec`, or a named list containing the
  available output widths.

- column:

  Which column width to preview at.

- height:

  Height. Defaults to three quarters of the width.

- units:

  Units for `height`.

## Value

The plot, invisibly.

## See also

[`fig_save()`](https://dansemakula.github.io/figspec/reference/fig_save.md)
to write the figure at that size and
[`fig_width()`](https://dansemakula.github.io/figspec/reference/fig_width.md)
to retrieve a recorded width without opening a preview.

## Examples

``` r
library(ggplot2)
p <- ggplot(ggplot2::mpg, aes(displ, hwy, colour = class)) + geom_point()
if (interactive()) fig_preview(p, "cell_press", "single")
p
```
