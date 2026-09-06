# Apply a figspec palette to point and line colours

Adds a discrete ggplot2 colour scale using one of the palettes listed by
[`figspec_palettes()`](https://dansemakula.github.io/figspec/reference/figspec_palettes.md).
Use this scale when a variable is represented by the colour of points,
lines or outlines. The American spelling `scale_color_figspec()` is an
exact alias.

## Usage

``` r
scale_colour_figspec(palette = "okabe_ito", ...)

scale_color_figspec(palette = "okabe_ito", ...)
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

A discrete ggplot2 colour scale to add to a plot.

## Examples

``` r
library(ggplot2)
ggplot(ggplot2::mpg, aes(displ, hwy, colour = class)) +
  geom_point() +
  scale_colour_figspec()
```
