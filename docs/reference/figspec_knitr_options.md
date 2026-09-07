# Create figure settings for R Markdown or Quarto

Figures created inside an R Markdown or Quarto code chunk do not pass
through
[`fig_save()`](https://dansemakula.github.io/figspec/reference/fig_save.md).
This function translates a publication, project or organisational
specification into the width, height, resolution and graphics device
settings understood by knitr.

## Usage

``` r
figspec_knitr_options(
  spec,
  column = NULL,
  width = NULL,
  height = NULL,
  units = c("mm", "cm", "in"),
  art_type = c("auto", "colour", "bw", "line", "combination")
)
```

## Arguments

- spec:

  The specification to use: a registry id such as `"plos_one"`, a
  `figspec_spec`, or a named list of requirements.

- column:

  Which named width in the specification to use. Leave it `NULL` when
  supplying `width` explicitly.

- width:

  Explicit figure width for specifications that do not publish named
  columns.

- height:

  Figure height. Defaults to three quarters of the width when no height
  is recorded; supply an explicit value when the specification or layout
  requires one.

- units:

  Units for `width` and `height`.

- art_type:

  Resolution category. With no plot available, `"auto"` conservatively
  uses the strictest rule the journal states.

## Value

A named list suitable for `knitr::opts_chunk$set()`.

## Examples

``` r
figspec_knitr_options("frontiers", "single")
#> $fig.width
#> [1] 3.346457
#>
#> $fig.height
#> [1] 2.509843
#>
#> $dpi
#> [1] 300
#>
#> $dev
#> [1] "tiff"
#>

# A report format maintained by your own team.
report_spec <- list(
  name = "Landscape report figure",
  columns = list(full = 180),
  formats = "png",
  dpi_min = 300
)
figspec_knitr_options(report_spec, "full", height = 100, units = "mm")
#> $fig.width
#> [1] 7.086614
#>
#> $fig.height
#> [1] 3.937008
#>
#> $dpi
#> [1] 300
#>
#> $dev
#> [1] "ragg_png"
#>

# In a setup chunk:
# do.call(knitr::opts_chunk$set, figspec_knitr_options("frontiers"))
```
