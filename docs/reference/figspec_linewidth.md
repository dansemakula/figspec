# Line width that satisfies a journal's minimum

Several publishers state a minimum line weight in points. ggplot2
measures `linewidth` in millimetres, so this converts the journal's
figure into the number you pass to a geom.
[`theme_journal()`](https://dansemakula.github.io/figspec/reference/theme_journal.md)
already applies it to axes, ticks and gridlines, but geom line widths
are set on the layer, not the theme, so pass this to layers that draw
lines.

## Usage

``` r
figspec_linewidth(journal)
```

## Arguments

- journal:

  Registry id.

## Value

A single numeric `linewidth`, or `NULL` when the journal states no
minimum.

## Examples

``` r
library(ggplot2)
lw <- figspec_linewidth("frontiers")
ggplot(ggplot2::economics, aes(date, unemploy)) +
  geom_line(linewidth = lw) +
  theme_journal("frontiers")
```
