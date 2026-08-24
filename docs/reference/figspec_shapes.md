# Point shapes that stay legible at journal size

Returns shapes chosen to remain distinguishable when a figure is reduced
to a single column. No publisher in the registry states which shapes to
use, so this is a recommendation rather than a requirement. It matters
because shape is the cue that still works when a journal prints in black
and white.

## Usage

``` r
figspec_shapes(n, style = c("solid", "hollow", "filled"))
```

## Arguments

- n:

  How many shapes are needed.

- style:

  `"solid"` for filled marks, `"hollow"` for outlines, or `"filled"` for
  shapes 21 to 25, which take a fill and an outline colour separately.

## Value

An integer vector of shape codes.

## Examples

``` r
library(ggplot2)
ggplot(mtcars, aes(wt, mpg, shape = factor(cyl))) +
  geom_point() +
  scale_shape_manual(values = figspec_shapes(3))
```
