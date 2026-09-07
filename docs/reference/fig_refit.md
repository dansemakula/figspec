# Re-export a figure set for a new specification

A figure set may need to move to a different journal, report template or
organisational standard. This takes the editable figures you already
have and exports the whole set against the new specification.

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

  A non-empty named list of editable figures. Supported inputs include
  ggplot2 and patchwork objects, lattice and Plotly plots, grid grobs,
  and base-graphics code wrapped in functions or one-sided formulas.
  Names become file stems and must be unique and safe to use as file
  names.

- spec:

  The new specification: a registry id, a `figspec_spec`, or a named
  list of requirements.

- output_dir:

  One directory to write into. It is created if necessary.

- column:

  Which column width to use, either one value for all plots or a
  uniquely named vector mapping every plot name to a width.

- retheme:

  Whether to apply the requirements exposed by each plotting system
  before export. Must be one `TRUE` or `FALSE`.

- format:

  File extension without a dot. Defaults to the first writable format
  accepted by the specification.

## Value

A
[`submission_check()`](https://dansemakula.github.io/figspec/reference/submission_check.md)
report for the files written.

## Details

Keep the editable figures in a named list so figspec can apply the new
type, colour and line settings before export. Saved raster files no
longer contain those editable settings. With the original objects
available, adapting and checking the complete set remains a one-line
operation.

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
#> 1 item checked (1 figure, 0 tables)
#>
#> ! figure_1.tiff              figure single  incomplete (1 recorded requirement(s) not judged)
#>
#> ! No failures found, but at least one item is not fully assessed.
#> ℹ Some requirements could not be judged automatically. Use submission_detail() to see what remains to be reviewed for each item.
#> Source: <https://www.frontiersin.org/guidelines/author-guidelines> (verified
#> 2026-08-21)
unlink(dir, recursive = TRUE)
```
