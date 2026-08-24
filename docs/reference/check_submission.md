# Check a whole set of figures together

A submission is a set of figures that have to pass as a set. This runs
[`fig_check()`](https://dansemakula.github.io/figspec/reference/fig_check.md)
over every one and returns a row each, so the result is something you
can read at a glance or hand to a co-author.

## Usage

``` r
check_submission(
  x,
  journal = NULL,
  column = "single",
  dpi = NULL,
  pattern = "\\.(tiff?|png|jpe?g|pdf|eps|ps|svg)$",
  recursive = FALSE
)
```

## Arguments

- x:

  A list of plots; or a directory; or a character vector of file paths.

- journal:

  Registry id, for example `"plos_one"`; a specification from
  [`journal_spec()`](https://dansemakula.github.io/figspec/reference/journal_spec.md);
  or `NULL` to inspect the figures without judging them.

- column:

  Which column width the figures target. Either one value for all, or a
  named character vector mapping name to column.

- dpi:

  Resolution the files were written at. Useful for files that do not
  record it, such as those from base R's
  [`png()`](https://rdrr.io/r/grDevices/png.html) device.

- pattern:

  Regular expression selecting files when `x` is a directory. Defaults
  to common figure extensions.

- recursive:

  Whether to descend into subdirectories.

## Value

An object of class `figspec_submission`: a data frame with one row per
figure. The full per-requirement reports are kept in the `"reports"`
attribute.

## Details

Give it plot objects rather than files where you can. A written file has
lost the information that only the plot carries: type size and panel
geometry do not survive into a raster. From files, geometry, format,
resolution and file size can still be judged.

## Panel consistency

Given plot objects, this also reports the plot area of each figure.
Figures that meet the same width requirement still have different plot
areas when their axis labels differ in length, and on the page that is
what makes a set look uneven. No publisher states a rule about it, so it
is never reported as a failure — it is an observation about your own
figures, and
[`fig_save()`](https://dansemakula.github.io/figspec/reference/fig_save.md)
with a shared `panel_width` from
[`fig_panel_width()`](https://dansemakula.github.io/figspec/reference/fig_panel_width.md)
is the fix.

## Examples

``` r
library(ggplot2)
figs <- list(
  fig1 = ggplot(mtcars, aes(wt, mpg)) + geom_point(),
  fig2 = ggplot(mtcars, aes(wt, mpg * 100000)) + geom_point()
)
check_submission(figs, "frontiers")
#> 
#> ── Submission check - Frontiers journals ───────────────────────────────────────
#> 2 figures checked
#> 
#> ✔ fig1                       single  no failures (9 not judged)
#> ✔ fig2                       single  no failures (9 not judged)
#> 
#> ℹ Plot areas differ by 8.8 mm across this set (fig2 62.4 mm, fig1 71.3 mm). No publisher requires them to match, so this is not a failure. To make them match, pass fig_panel_width() to fig_save().
#> 
#> ✔ No figure breaches a requirement on record.
#> ℹ Some requirements are not on record for this journal, so they were not judged.
#> Source: <https://www.frontiersin.org/guidelines/author-guidelines> (verified
#> 2026-08-21)
```
