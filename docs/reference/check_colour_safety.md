# Check a figure's colours for safety in print and for colour-blind readers

Reports three things about the colours a plot maps data to: whether it
relies on a red/green contrast, whether its colours stay distinguishable
in greyscale, and whether they stay distinguishable to readers with the
common forms of colour vision deficiency.

## Usage

``` r
check_colour_safety(plot, journal, threshold = 10)

check_color_safety(plot, journal, threshold = 10)
```

## Arguments

- plot:

  A ggplot object.

- journal:

  Registry id.

- threshold:

  Perceptual distance (CIE Delta-E 2000) below which two colours are
  treated as too close to tell apart. Defaults to 10, the point at which
  two colours read as clearly different rather than as shades of one
  another. This is a judgement of figspec's, not a journal requirement,
  and you can raise it if you want a stricter figure.

## Value

A `figspec_report`.

## Details

Only the first two are ever stated as requirements, and only by some
publishers: Cell Press states that red and green should not be used
together, and the Royal Society states that figures are reproduced in
black and white in print by default. The colour-vision result is
reported for every journal but is marked `unspecified` unless the
publisher states it, because it is advice rather than a rule.

## Examples

``` r
library(ggplot2)
p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) + geom_point()
check_colour_safety(p, "cell_press")
#> 
#> ── Cell Press journals ─────────────────────────────────────────────────────────
#> checked: ggplot object
#> 
#> ✖ Colour pairs     red and green both used (#F8766D, #00BA38)
#>                    requires: red and green not used together
#> ℹ Greyscale        3 pair(s) merge in greyscale: #00BA38/#F8766D,
#>                    #00BA38/#619CFF, #F8766D/#619CFF
#>                    requires: not specified by publisher
#> ℹ Colour vision    colours merge under deuteranopia (1)
#>                    requires: not specified by publisher
#> ℹ Redundant coding colour is the only cue: all series share one shape and one
#>                    line type
#>                    requires: not specified by publisher
#> 
#> ✖ 1 requirement not met.
#> ℹ 3 requirements could not be judged automatically - check by hand.
#> Source: <https://www.cell.com/information-for-authors/figure-guidelines>
#> (verified 2026-08-21)
```
