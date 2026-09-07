# Apply distinct shapes to categorical points

Adds a discrete ggplot2 shape scale using the tested shape sets returned
by
[`figspec_shapes()`](https://dansemakula.github.io/figspec/reference/figspec_shapes.md).
Shape can support colour as a second visual cue, helping readers
distinguish groups when a figure is printed in greyscale or when colours
appear similar.

## Usage

``` r
scale_shape_figspec(..., style = c("solid", "hollow", "filled"))
```

## Arguments

- ...:

  Additional settings for the discrete scale, such as its legend title,
  labels, limits, missing-value shape or guide. These are passed to
  [`ggplot2::discrete_scale()`](https://ggplot2.tidyverse.org/reference/discrete_scale.html).

- style:

  The kind of marks to use: `"solid"` for solid symbols, `"hollow"` for
  outlines, or `"filled"` for symbols whose interior and outline colours
  can be controlled separately. The available sets contain six solid,
  six hollow and five filled shapes.

## Value

A discrete ggplot2 shape scale to add to a plot.

## Examples

``` r
library(ggplot2)
ggplot(ggplot2::mpg, aes(displ, hwy, shape = drv)) +
  geom_point() +
  scale_shape_figspec()
```
