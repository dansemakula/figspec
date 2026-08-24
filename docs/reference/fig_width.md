# Figure width for a journal column

Resolves the width a figure should be saved at. Column names come from
the journal itself rather than a fixed vocabulary: Science lays out in
one, two or three columns, most journals in one, one-and-a-half or two.
Use
[`fig_columns()`](https://dansemakula.github.io/figspec/reference/fig_columns.md)
to see what a given journal offers.

## Usage

``` r
fig_width(journal, column = "single", units = c("mm", "cm", "in"))
```

## Arguments

- journal:

  Registry id, for example `"cell_press"`.

- column:

  Column name, for example `"single"`, `"double"` or, for Science,
  `"triple"`.

- units:

  Unit for the returned width: `"mm"`, `"cm"` or `"in"`.

## Value

A single numeric width, or an error if the journal does not state a
width for that column.

## Details

When a journal states a permitted range rather than named columns,
`"single"` returns the minimum width and `"double"` the maximum.

## Examples

``` r
fig_width("cell_press", "single")
#> [1] 85
fig_width("science", "triple")
#> [1] 184
fig_width("frontiers", "double", units = "in")
#> [1] 7.086614
```
