# A discrete shape scale using shapes that stay legible at journal size

A discrete shape scale using shapes that stay legible at journal size

## Usage

``` r
scale_shape_figspec(..., style = c("solid", "hollow", "filled"))
```

## Arguments

- ...:

  Passed to
  [`ggplot2::discrete_scale()`](https://ggplot2.tidyverse.org/reference/discrete_scale.html).

- style:

  Passed to
  [`figspec_shapes()`](https://dansemakula.github.io/figspec/reference/figspec_shapes.md).

## Value

A ggplot2 scale.

## Examples

``` r
library(ggplot2)
ggplot(mtcars, aes(wt, mpg, shape = factor(cyl))) +
  geom_point() +
  scale_shape_figspec()
```
