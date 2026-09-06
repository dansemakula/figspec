# Apply a specification to a table

Applies recorded table requirements while the table is still editable.
Supported inputs are data frames, matrices, gt tables, flextable
objects, knitr or kableExtra tables and grid tables. A data frame or
matrix is converted to a gt table.

## Usage

``` r
table_apply_spec(table, spec)
```

## Arguments

- table:

  A supported table object.

- spec:

  The specification to apply. It must contain a tables section.

## Value

A styled table object with evidence of the applied values attached.

## Details

Only requirements that can be applied safely are changed. Rules that
need editorial judgement remain for
[`table_check()`](https://dansemakula.github.io/figspec/reference/table_check.md)
to report.

## Examples

``` r
report_spec <- list(
  name = "Research report",
  tables = list(font_min_pt = 9, header_bold = TRUE,
                vertical_rules = FALSE)
)
if (requireNamespace("gt", quietly = TRUE)) {
table_apply_spec(head(mtcars), report_spec)
}




mpg
```
