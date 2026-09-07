# Get a set of distinct point shapes

Returns ggplot2 shape codes chosen to remain visually distinct when a
figure is reduced or reproduced without colour. Use the codes in a
manual shape scale when you need direct control;
[`scale_shape_figspec()`](https://dansemakula.github.io/figspec/reference/scale_shape_figspec.md)
applies the same sets automatically.

## Usage

``` r
figspec_shapes(n, style = c("solid", "hollow", "filled"))
```

## Arguments

- n:

  The number of shapes needed, usually the number of groups in the data.
  Up to six solid, six hollow or five separately filled shapes are
  available.

- style:

  The kind of marks to return: `"solid"` for solid symbols, `"hollow"`
  for outlines, or `"filled"` for shapes 21 to 25, whose interior and
  outline colours can be controlled separately.

## Value

An integer vector containing one ggplot2 shape code per group.

## Details

These shapes are design recommendations, not requirements taken from a
publication or project specification. The sets are deliberately short.
When more shapes are requested, figspec reports the available number so
you can split the figure or choose another visual cue.

## Examples

``` r
library(ggplot2)
ggplot(ggplot2::mpg, aes(displ, hwy, shape = drv)) +
  geom_point() +
  scale_shape_manual(values = figspec_shapes(3))
```
