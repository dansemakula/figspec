# Review figures and tables together

Runs the relevant figure or table check over every item in a collection
and returns one summary row per item. Use it to review a manuscript,
report, presentation or other project in one place, while retaining
every complete report.

## Usage

``` r
submission_check(
  x,
  spec = NULL,
  column = NULL,
  dpi = NULL,
  pattern = "\\.(tiff?|png|jpe?g|pdf|eps|ps|svg|html?|docx|rtf|tex|latex)$",
  recursive = FALSE,
  art_type = c("auto", "colour", "bw", "line", "combination"),
  asset_type = c("auto", "figure", "table")
)
```

## Arguments

- x:

  A non-empty list of supported live figures or tables, a directory
  path, or a character vector of exported asset paths.

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
  to common figure and table extensions.

- recursive:

  Whether a directory scan should include subdirectories. Must be one
  `TRUE` or `FALSE` value.

- art_type:

  Resolution category passed to
  [`fig_check()`](https://dansemakula.github.io/figspec/reference/fig_check.md).
  `"auto"` uses the content of a live plot; for saved files, where that
  evidence has been lost, it applies the strictest recorded threshold.
  Explicit choices are `"colour"`, `"bw"`, `"line"` and `"combination"`.

- asset_type:

  Whether each item is a figure or table. The default detects live
  objects and treats HTML, DOCX, RTF and TeX files as tables. A uniquely
  named vector can classify every item explicitly.

## Value

An object of class `figspec_submission`: a data frame with one row per
item. The full per-requirement reports are kept in the `"reports"`
attribute.

## Details

Check live figure objects before export and the written files
afterwards. The live object provides styling information; the completed
files provide their actual dimensions, resolution, format, validity and
file size. Using both checks gives the complete picture, especially for
raster files that no longer retain editable type-size information.

## Panel consistency

For ggplot2-compatible objects, this also reports the plot area of each
figure. Figures that meet the same width requirement still have
different plot areas when their axis labels differ in length, and on the
page that is what makes a set look uneven. The report presents this as
layout information because current publisher profiles do not require
equal panel dimensions. Use
[`fig_save()`](https://dansemakula.github.io/figspec/reference/fig_save.md)
with a shared `panel_width` from
[`fig_panel_width()`](https://dansemakula.github.io/figspec/reference/fig_panel_width.md)
to align the set.

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
#> 2 items checked (2 figures, 0 tables)
#>
#> ! vehicles                   figure single  incomplete (5 recorded requirement(s) not judged)
#> ✖ economy                    figure single  failed: Line width
#>
#> ℹ Plot areas differ by 5.3 mm across this set (economy 66 mm, vehicles 71.3 mm). This layout measurement is reported separately from the requirement results. To make them match, pass fig_panel_width() to fig_save().
#>
#> ✖ 1 item would fail this specification.
#> ℹ Some requirements could not be judged automatically. Use submission_detail() to see what remains to be reviewed for each item.
#> Source: <https://www.frontiersin.org/guidelines/author-guidelines> (verified
#> 2026-08-21)
```
