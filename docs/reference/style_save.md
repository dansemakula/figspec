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

## Details

The complete style collection is written to a temporary file, reopened
and validated before it is placed at the requested path. The destination
must be a regular file path, and any existing style file remains
available if the new collection cannot be written or validated.

## Examples

``` r
library(ggplot2)
style_register("mylab", theme_minimal())
f <- tempfile(fileext = ".rds")
style_save(f)
style_load(f)
unlink(f)
```
