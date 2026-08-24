# The column widths a journal states

The column widths a journal states

## Usage

``` r
fig_columns(journal)
```

## Arguments

- journal:

  Registry id.

## Value

A named numeric vector of widths in millimetres, or `NULL` when the
journal states a range rather than named columns.

## Examples

``` r
fig_columns("science")
#> single double triple 
#>     57    121    184 
fig_columns("cell_press")
#>  single onehalf  double 
#>      85     114     174 
```
