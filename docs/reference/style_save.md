# Save visual styles for reuse

Styles registered with
[`style_register()`](https://dansemakula.github.io/figspec/reference/style_register.md)
last only for the session. Save them to an RDS file when you want to use
them in a later session or share them across projects you control.

## Usage

``` r
style_save(path)
```

## Arguments

- path:

  The RDS file to create.

## Value

`path` invisibly.

## Examples

``` r
library(ggplot2)
style_register("mylab", theme_minimal())
f <- tempfile(fileext = ".rds")
style_save(f)
style_load(f)
unlink(f)
```
