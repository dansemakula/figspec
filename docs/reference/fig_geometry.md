# What size a figure actually is

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

  A `figspec_geometry` object, from `fig_geometry()`.

- ...:

  Ignored.

## Value

A one-row data frame: canvas and panel width and height, and the
decoration each dimension spends on axes, legends and margins.

## Examples

``` r
library(ggplot2)
fig_geometry(ggplot(mtcars, aes(wt, mpg)) + geom_point())
#> 
#> ── Figure geometry ─────────────────────────────────────────────────────────────
#> ℹ The panels have no size of their own yet, so they will take whatever the
#> canvas leaves over. The decoration below is fixed by the labels and the
#> font, and does not change with the canvas.
#> 
#> Decoration - where the rest of the space goes
#>   left      11.8 mm
#>   bottom    11.3 mm
#>   right      1.9 mm
#>   top        1.9 mm
#> 
#> ℹ `plot()` this to see it.
```
