# Review a set of figures together

Runs
[`fig_check()`](https://dansemakula.github.io/figspec/reference/fig_check.md)
over every figure in a collection and returns one summary row per
figure. Use it to review the figures for a manuscript, report,
presentation or other project in one place, while retaining the full
check report for each item.

## Usage

``` r
submission_check(
  x,
  spec = NULL,
  column = NULL,
  dpi = NULL,
  pattern = "\\.(tiff?|png|jpe?g|pdf|eps|ps|svg)$",
  recursive = FALSE,
  art_type = c("auto", "colour", "bw", "line", "combination")
)
```

## Arguments

- x:

  A non-empty list containing only plots, a directory path, or a
  character vector of figure-file paths. Plot names and file basenames
  are used in the summary.

- spec:

  The specification to use: a registry id, a `figspec_spec`, a named
  list of requirements, or `NULL` to inspect without assigning pass or
  fail results.

- column:

  Which named width each figure targets. Supply one non-empty name for
  the whole set, or a uniquely named character vector covering every
  figure name in `x`.

- dpi:

  The shared resolution of files that do not record it themselves. It is
  also the intended export resolution when `x` contains live plots.

- pattern:

  Regular expression selecting files when `x` is a directory. Defaults
  to common figure extensions.

- recursive:

  Whether a directory scan should include subdirectories. Must be one
  `TRUE` or `FALSE` value.

- art_type:

  Resolution category passed to
  [`fig_check()`](https://dansemakula.github.io/figspec/reference/fig_check.md).
  `"auto"` uses the content of a live plot; for saved files, where that
  evidence has been lost, it applies the strictest recorded threshold.
  Explicit choices are `"colour"`, `"bw"`, `"line"` and `"combination"`.

## Value

An object of class `figspec_submission`: a data frame with one row per
figure. The full per-requirement reports are kept in the `"reports"`
attribute.

## Details

Check plot objects before export and the written files afterwards when
you can. The plot objects preserve typography, colour mappings and panel
geometry. The files provide the actual dimensions, resolution, format,
validity and file size. Raster files cannot preserve editable type-size
information, so the two checks answer complementary questions.

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
  vehicles = ggplot(ggplot2::mpg, aes(displ, hwy)) + geom_point(),
  economy = ggplot(ggplot2::economics, aes(date, unemploy)) +
    geom_line() + labs(y = "Number of unemployed people")
)
figs$vehicles

figs$economy

submission_check(figs, "frontiers")
#>
#> ── Submission check - Frontiers journals ───────────────────────────────────────
#> 2 figures checked
#>
#> ! vehicles                   single  incomplete (5 recorded requirement(s) not judged)
#> ✖ economy                    single  failed: Line width
#>
#> ℹ Plot areas differ by 5.3 mm across this set (economy 66 mm, vehicles 71.3 mm). No publisher requires them to match, so this is not a failure. To make them match, pass fig_panel_width() to fig_save().
#>
#> ✖ 1 figure would fail this specification.
#> ℹ Some requirements are not on record in this specification, so they were not judged.
#> Source: <https://www.frontiersin.org/guidelines/author-guidelines> (verified
#> 2026-08-21)
```
