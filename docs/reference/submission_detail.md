# Open the full report for one submission item

[`submission_check()`](https://dansemakula.github.io/figspec/reference/submission_check.md)
gives one summary row for each figure or table. This function retrieves
the underlying report for the item you select, so you can see every
requirement, measured value and reason for any failure or unresolved
result.

## Usage

``` r
submission_detail(x, file)
```

## Arguments

- x:

  The complete `figspec_submission` object returned by
  [`submission_check()`](https://dansemakula.github.io/figspec/reference/submission_check.md).

- file:

  Exactly one item name from the `file` column of `x`. For live objects
  this is the list name; for saved assets it is the file name shown in
  the submission summary.

## Value

The `figspec_report` for that file.

## Examples

``` r
library(ggplot2)
figures <- list(
  vehicles = ggplot(ggplot2::mpg, aes(displ, hwy)) + geom_point(),
  economy = ggplot(ggplot2::economics, aes(date, unemploy)) + geom_line()
)
review <- submission_check(figures, "frontiers")
submission_detail(review, "vehicles")
#>
#> ── Frontiers journals ──────────────────────────────────────────────────────────
#> checked: ggplot2 plot
#>
#> ✔ Width              85 mm                  requires: single 85 mm
#> ! Height        -
#>                 requires: not yet reviewed for this specification
#> ! Resolution    could not determine         requires: min 300 dpi for line
#> ! File format   could not determine         requires: TIFF, JPEG, EPS
#> ✔ Type size     smallest     8.8 pt, largest      11 pt  requires: min 8 pt
#> ! Font          -
#>                 requires: not yet reviewed for this specification
#> ! Line width    could not determine         requires: min 2 pt
#> ✔ Colour mode   RGB                         requires: RGB
#> ℹ Colour pairs  no red/green pairing        requires: not specified by publisher
#> ℹ Greyscale     all colours separable in greyscale
#>                 requires: not specified by publisher
#> ℹ Colour vision separable under deuteranopia, protanopia and tritanopia
#>                 requires: not specified by publisher
#> ℹ File size     -                           requires: not specified by publisher
#>
#> ! No failures were found, but this assessment is incomplete.
#> ℹ 5 requirements or registry fields could not be judged automatically - check
#>   by hand.
#> Source: <https://www.frontiersin.org/guidelines/author-guidelines> (verified
#> 2026-08-21)
```
