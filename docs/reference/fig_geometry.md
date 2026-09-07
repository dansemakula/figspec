# Measure panel and canvas dimensions

Reports the canvas and panel dimensions of a plot, in millimetres. Use
it to see where the space in a figure is going before you decide what to
change.

## Usage

``` r
fig_geometry(x)

# S3 method for class 'figspec_geometry'
plot(x, ...)
```

## Arguments

- x:

  For `fig_geometry()`, a ggplot, patchwork composition, `gtable`, or
  the value returned by
  [`fig_save()`](https://dansemakula.github.io/figspec/reference/fig_save.md).
  For [`plot()`](https://rdrr.io/r/graphics/plot.default.html), the
  `figspec_geometry` object returned by `fig_geometry()`.

- ...:

  Accepted by the
  [`plot()`](https://rdrr.io/r/graphics/plot.default.html) generic for
  compatibility and ignored by this method.

## Value

A one-row data frame: canvas and panel width and height, and the
decoration each dimension spends on axes, legends and margins.

## Examples

``` r
library(ggplot2)
p <- ggplot(ggplot2::mpg, aes(displ, hwy)) + geom_point()
sized <- fig_panel_size(p, width = 62, height = 45)
geometry <- fig_geometry(sized)
geometry
#>
#> ── Figure geometry ─────────────────────────────────────────────────────────────
#>   canvas  75.5 x 57.9 mm
#>   panel   62 x 45 mm
#>
#> Decoration - where the rest of the space goes
#>   left      11.6 mm
#>   bottom    10.9 mm
#>   right      1.9 mm
#>   top        1.9 mm
#>
#> ℹ `plot()` this to see it.
plot(geometry)
```
