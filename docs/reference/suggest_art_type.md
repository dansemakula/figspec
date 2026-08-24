# Which resolution rule applies to this figure

Publishers set different resolutions for different kinds of artwork, and
the gap is large: a general minimum of 300 dpi against 600 to 1200 dpi
for line art. Which one applies to a statistical plot is not obvious,
and getting it wrong is expensive in one direction.

## Usage

``` r
suggest_art_type(plot, journal = NULL)
```

## Arguments

- plot:

  A ggplot object.

- journal:

  Optional registry id. When given, the journal's own thresholds are
  shown alongside the suggestion.

## Value

The suggested `art_type` for
[`fig_check()`](https://dansemakula.github.io/figspec/reference/fig_check.md),
invisibly.

## Details

Most R plots are line art. PNAS says so explicitly, giving "line art,
e.g., bar graphs". A plot made of lines, flat fills and text is line art
in that sense, whatever colour it is. Springer defines line art more
narrowly, as a "Black and white graphic with no shading", which would
place a coloured plot in combination art instead. Publishers genuinely
disagree, so this reports what the plot contains and leaves the decision
to you.

## Examples

``` r
library(ggplot2)
suggest_art_type(ggplot(mtcars, aes(factor(cyl))) + geom_bar(), "bmj")
#> 
#> ── Which resolution rule applies ───────────────────────────────────────────────
#> ℹ This plot uses grey but no colour, so it is grayscale art, not line art.
#>   ggplot2's default bar fill is a mid grey, so a default bar chart lands here
#>   rather than in line art.
#> 
#> BMJ journals states:
#>   • general minimum: 300 dpi
#>   • line art: 1200 dpi
#> For non-vector files (e.g. TIFF, JPEG) a minimum resolution of 300 dpi is
#> required, except for line art which should be 1200 dpi.
#> 
#> ✔ Suggested: fig_check(plot, journal, art_type = "bw")
#> ℹ This is a suggestion from what the plot contains, not a rule. Where
#>   publishers disagree, the stricter reading costs file size; the looser one
#>   risks a figure below the resolution the journal asked for.
```
