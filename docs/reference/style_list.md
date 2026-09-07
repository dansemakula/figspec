# List the visual styles available in this session

Shows the reusable styles currently registered with
[`style_register()`](https://dansemakula.github.io/figspec/reference/style_register.md).
Styles last for the current R session unless they are saved with
[`style_save()`](https://dansemakula.github.io/figspec/reference/style_save.md).

## Usage

``` r
style_list()
```

## Value

A data frame containing each registered style's name and description. If
no styles are registered, the data frame has no rows.

## Examples

``` r
style_list()
#> [1] name        description
#> <0 rows> (or 0-length row.names)
```
