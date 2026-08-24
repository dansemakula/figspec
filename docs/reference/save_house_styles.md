# Save and reload your house styles

Styles registered with
[`register_house_style()`](https://dansemakula.github.io/figspec/reference/register_house_style.md)
last only for the session. Save them to a file to keep them, and load
them from a project setup script or your `.Rprofile`.

## Usage

``` r
save_house_styles(path)

load_house_styles(path)
```

## Arguments

- path:

  File to write to or read from.

## Value

For `save_house_styles()`, `path` invisibly. For `load_house_styles()`,
the names loaded, invisibly.

## Examples

``` r
library(ggplot2)
register_house_style("mylab", theme_minimal())
f <- tempfile(fileext = ".rds")
save_house_styles(f)
load_house_styles(f)
unlink(f)
```
