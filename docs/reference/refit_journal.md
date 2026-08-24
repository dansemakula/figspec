# Re-export a set of figures for a different journal

Papers get rejected and resubmitted, and the new journal has different
widths, formats and type limits. This takes the plot objects you already
have and writes the whole set to another journal's specification.

## Usage

``` r
refit_journal(
  plots,
  journal,
  outdir,
  column = "single",
  retheme = TRUE,
  format = NULL
)
```

## Arguments

- plots:

  A named list of plot objects. Names become file stems.

- journal:

  Registry id of the journal to fit to.

- outdir:

  Directory to write into. Created if it does not exist.

- column:

  Which column width to use, either one value for all plots or a named
  vector mapping plot name to column.

- retheme:

  Whether to apply
  [`theme_journal()`](https://dansemakula.github.io/figspec/reference/theme_journal.md)
  to each plot so its typography matches the new journal. Defaults to
  `TRUE`.

- format:

  File format. Defaults to the journal's first accepted format.

## Value

A
[`check_submission()`](https://dansemakula.github.io/figspec/reference/check_submission.md)
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
p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
dir <- file.path(tempdir(), "refit")
res <- suppressWarnings(
  refit_journal(list(figure_1 = p), "frontiers", dir)
)
unlink(dir, recursive = TRUE)
```
