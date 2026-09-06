# List the available figure widths

Lists the named widths recorded in a publication, project or
organisational specification. The returned names can be supplied to the
`column` argument of
[`fig_width()`](https://dansemakula.github.io/figspec/reference/fig_width.md),
[`fig_save()`](https://dansemakula.github.io/figspec/reference/fig_save.md)
and other figspec functions.

## Usage

``` r
fig_columns(spec)
```

## Arguments

- spec:

  The specification to inspect: a registry id, a `figspec_spec`, or a
  named list of requirements.

## Value

A named numeric vector of widths in millimetres, or `NULL` when the
specification records a range instead of named widths.

## Details

Some sources state only a permitted width range. In that case there are
no named choices to list, so the function explains the range and returns
`NULL`.

## Examples

``` r
fig_columns("science")
#> single double triple
#>     57    121    184
fig_columns("cell_press")
#>  single onehalf  double
#>      85     114     174

report_spec <- list(
  name = "Research report",
  columns = list(half = 80, full = 160)
)
fig_columns(report_spec)
#> half full
#>   80  160
```
