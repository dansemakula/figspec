# Look up a figure width

Returns a named figure width from a publication, project or
organisational specification. The specification defines both the
available names and their widths: for example, Cell Press records
`"single"`, `"onehalf"` and `"double"`, while Science also records
`"triple"`. Use
[`fig_columns()`](https://dansemakula.github.io/figspec/reference/fig_columns.md)
to see the names available in a specification.

## Usage

``` r
fig_width(spec, column = "single", units = c("mm", "cm", "in"))
```

## Arguments

- spec:

  The specification to use: a registry id such as `"cell_press"`, a
  `figspec_spec`, or a named list of requirements.

- column:

  Name of the required width, such as `"single"`, `"double"` or
  `"triple"`. The available names come from the specification.

- units:

  Unit for the returned width: `"mm"`, `"cm"` or `"in"`.

## Value

A single numeric width in the requested unit. An error is raised if the
specification does not contain the requested width.

## Details

When a specification records a permitted range instead of named widths,
`"single"` returns the minimum and `"double"` returns the maximum.

## Examples

``` r
fig_width("cell_press", "single")
#> [1] 85
fig_width("science", "triple")
#> [1] 184
fig_width("frontiers", "double", units = "in")
#> [1] 7.086614

report_spec <- spec_get(list(
  name = "Research report",
  columns = list(half = 80, full = 160)
))
fig_width(report_spec, "full")
#> [1] 160
```
