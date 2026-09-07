# Apply a figspec palette to filled areas

Adds a discrete ggplot2 fill scale using one of the palettes listed by
[`figspec_palettes()`](https://dansemakula.github.io/figspec/reference/figspec_palettes.md).
Use it for bars, boxes, areas and filled point shapes; use
[`scale_colour_figspec()`](https://dansemakula.github.io/figspec/reference/scale_colour_figspec.md)
for point, line and outline colours.

## Usage

``` r
scale_fill_figspec(palette = "okabe_ito", ...)
```

## Arguments

- palette:

  The id of the figspec palette to use. See
  [`figspec_palettes()`](https://dansemakula.github.io/figspec/reference/figspec_palettes.md)
  for the available choices and their recommended uses.

- ...:

  Additional settings for the discrete scale, such as its legend title,
  labels, limits, missing-value colour or guide. These are passed to
  [`ggplot2::discrete_scale()`](https://ggplot2.tidyverse.org/reference/discrete_scale.html).

## Value

A discrete ggplot2 fill scale to add to a plot.

## Examples

``` r
library(ggplot2)
ggplot(ggplot2::mpg, aes(class, fill = drv)) +
  geom_bar() +
  scale_fill_figspec()
```
