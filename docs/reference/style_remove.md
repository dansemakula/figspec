# Remove a visual style from the current session

Removes a style previously added with
[`style_register()`](https://dansemakula.github.io/figspec/reference/style_register.md).
This changes only the current R session; a saved style file is not
modified.

## Usage

``` r
style_remove(name)
```

## Arguments

- name:

  The registered style name, as shown by
  [`style_list()`](https://dansemakula.github.io/figspec/reference/style_list.md).

## Value

`TRUE` invisibly when the style is removed.

## Examples

``` r
library(ggplot2)
style_register("temporary", theme_void())
style_remove("temporary")
```
