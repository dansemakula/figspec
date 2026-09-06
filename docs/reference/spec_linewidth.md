# Use line widths that meet a specification

Some specifications state a minimum line weight in points, while ggplot2
uses a different scale for its `linewidth` argument. This function
converts the recorded requirement into the value you pass to a
line-drawing geom.
[`theme_spec()`](https://dansemakula.github.io/figspec/reference/theme_spec.md)
applies the requirement to axes, ticks and gridlines, but lines drawn by
data layers must be set directly.

## Usage

``` r
spec_linewidth(spec)
```

## Arguments

- spec:

  A registry id, a `figspec_spec`, or a named list containing the
  required minimum line width.

## Value

A single numeric `linewidth`, or `NULL` when the specification states no
minimum.

## Examples

``` r
library(ggplot2)
lw <- spec_linewidth("frontiers")
ggplot(ggplot2::economics, aes(date, unemploy)) +
  geom_line(linewidth = lw) +
  theme_spec("frontiers")
```
