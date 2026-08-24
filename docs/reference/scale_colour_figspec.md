# Discrete colour and fill scales using a figspec palette

Discrete colour and fill scales using a figspec palette

## Usage

``` r
scale_colour_figspec(palette = "okabe_ito", ...)

scale_color_figspec(palette = "okabe_ito", ...)

scale_fill_figspec(palette = "okabe_ito", ...)
```

## Arguments

- palette:

  Palette id, from
  [`figspec_palettes()`](https://dansemakula.github.io/figspec/reference/figspec_palettes.md).

- ...:

  Passed to
  [`ggplot2::discrete_scale()`](https://ggplot2.tidyverse.org/reference/discrete_scale.html).

## Value

A ggplot2 scale.

## Examples

``` r
library(ggplot2)
ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) +
  geom_point() +
  scale_colour_figspec()
```
