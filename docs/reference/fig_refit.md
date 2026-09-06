# Re-export a figure set for a new specification

A figure set may need to move to a different journal, report template or
organisational standard. This takes the editable plot objects you
already have and exports the whole set against the new specification.

## Usage

``` r
fig_refit(
  plots,
  spec,
  output_dir,
  column = NULL,
  retheme = TRUE,
  format = NULL
)
```

## Arguments

- plots:

  A non-empty named list of plot objects. Names become file stems and
  must therefore be unique and safe to use as file names.

- spec:

  The new specification: a registry id, a `figspec_spec`, or a named
  list of requirements.

- output_dir:

  One directory to write into. It is created if necessary.

- column:

  Which column width to use, either one value for all plots or a
  uniquely named vector mapping every plot name to a width.

- retheme:

  Whether to apply
  [`theme_spec()`](https://dansemakula.github.io/figspec/reference/theme_spec.md)
  to each plot so its typography matches the new specification. Must be
  one `TRUE` or `FALSE`.

- format:

  File extension without a dot. Defaults to the first writable format
  accepted by the specification.

## Value

A
[`submission_check()`](https://dansemakula.github.io/figspec/reference/submission_check.md)
report for the files written.

## Details

It works from plot objects, not from saved files, and that is
deliberate. Type size cannot be recovered from a saved raster, and
rescaling one only degrades it, so re-fitting a finished TIFF cannot
produce a compliant figure. Keep your plots in a list and this stays a
one-line operation.

## Examples

``` r
library(ggplot2)
p <- ggplot(ggplot2::mpg, aes(displ, hwy, colour = class)) + geom_point()
p

dir <- file.path(tempdir(), "refit")
res <- suppressWarnings(
  fig_refit(list(figure_1 = p), "frontiers", dir)
)
res
#>
#> ── Submission check - Frontiers journals ───────────────────────────────────────
#> 1 figure checked
#>
#> ! figure_1.tiff              single  incomplete (1 recorded requirement(s) not judged)
#>
#> ! No failures found, but at least one figure is not fully assessed.
#> ℹ Some requirements cannot be judged from a saved file - type size in particular. Check the plot objects before saving.
#> Source: <https://www.frontiersin.org/guidelines/author-guidelines> (verified
#> 2026-08-21)
unlink(dir, recursive = TRUE)
```
