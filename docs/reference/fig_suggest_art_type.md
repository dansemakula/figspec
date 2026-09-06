# Choose a resolution category for a figure

Specifications often set different resolutions for colour, greyscale,
line and combination artwork. This function examines what a ggplot draws
and suggests the corresponding `art_type` value for
[`fig_check()`](https://dansemakula.github.io/figspec/reference/fig_check.md)
or
[`fig_save()`](https://dansemakula.github.io/figspec/reference/fig_save.md).
It also shows the recorded thresholds when you supply a publication or
project specification.

## Usage

``` r
fig_suggest_art_type(plot, spec = NULL)
```

## Arguments

- plot:

  A ggplot object.

- spec:

  Optional specification: a registry id, a `figspec_spec`, or a named
  list of requirements. When supplied, its resolution thresholds are
  shown alongside the suggestion.

## Value

The suggested `art_type` value for
[`fig_check()`](https://dansemakula.github.io/figspec/reference/fig_check.md)
or
[`fig_save()`](https://dansemakula.github.io/figspec/reference/fig_save.md),
invisibly.

## Details

The suggestion describes the plot's visible content; it does not rewrite
or overrule the source's terminology. For example, some publishers
reserve "line art" for pure black-and-white artwork, while others use
the term more broadly. Read the displayed thresholds and source guidance
before choosing a lower resolution for final delivery.

## Examples

``` r
library(ggplot2)
bars <- ggplot(ggplot2::mpg, aes(class)) + geom_bar()
bars

fig_suggest_art_type(bars, "bmj")
#>
#> ── Choose a resolution category ────────────────────────────────────────────────
#> ℹ This plot uses grey but no colour, so it is grayscale art, not line art. For
#>   example, ggplot2's default bar fill is a mid grey, so a default bar chart
#>   belongs in this category.
#>
#> Requirements from BMJ journals:
#> • general minimum: 300 dpi
#> • line art: 1200 dpi
#> For non-vector files (e.g. TIFF, JPEG) a minimum resolution of 300 dpi is
#> required, except for line art which should be 1200 dpi.
#>
#> ✔ Suggested: fig_check(plot, spec, art_type = "bw")
#> ℹ This recommendation is based on what the plot contains. If publisher guidance
#>   is unclear, using a higher resolution increases the file size, while using a
#>   lower resolution may fall below the requirement. Check the linked guidance
#>   before submission.
```
