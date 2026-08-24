# Set the size of a plot's panels

Sets the plot area to an exact physical size, rather than the image
file. Two figures given the same panel size line up, whatever their axis
labels do, and the type inside them stays at the size you set it.

## Usage

``` r
fig_panel_size(plot, width = NULL, height = NULL, units = c("mm", "cm", "in"))
```

## Arguments

- plot:

  A ggplot, a patchwork composition, or a `gtable`.

- width, height:

  Panel size. `NULL` leaves that dimension alone.

- units:

  Units for `width` and `height`.

## Value

A `gtable`, which prints and saves like a plot. Its achieved geometry is
attached as the `"figspec_geometry"` attribute.

## Details

The usual way to size a figure sets the image and lets the panel take
whatever is left over, so a longer y-axis label silently shrinks the
plot area. This does the reverse: the panel is what you fix, and the
image grows or shrinks around it.

For a faceted plot, or a composition made with patchwork, the size
applies to *each* panel, which is what makes panels comparable between
figures.

## See also

[`fig_save()`](https://dansemakula.github.io/figspec/reference/fig_save.md),
which does this and works out the image size for you.

## Examples

``` r
library(ggplot2)
p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
g <- fig_panel_size(p, width = 62, height = 45)
fig_geometry(g)
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
```
