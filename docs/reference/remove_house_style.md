# Remove a registered house style

Remove a registered house style

## Usage

``` r
remove_house_style(name)
```

## Arguments

- name:

  Name of the style to remove.

## Value

`TRUE` invisibly.

## Examples

``` r
library(ggplot2)
register_house_style("temporary", theme_void())
remove_house_style("temporary")
```
