# Load saved visual styles

Restores styles previously written by
[`style_save()`](https://dansemakula.github.io/figspec/reference/style_save.md)
and adds them to the styles already registered in the current R session.
An RDS file is a trusted-input format; do not load one received from an
untrusted person or website.

## Usage

``` r
style_load(path, allow_functions = FALSE)
```

## Arguments

- path:

  The RDS file previously created by
  [`style_save()`](https://dansemakula.github.io/figspec/reference/style_save.md).

- allow_functions:

  Whether to permit stored theme functions. Defaults to `FALSE`.

## Value

The names of the loaded styles, invisibly.

## Details

Theme functions contain executable R code. They are refused by default
even when the rest of the file is valid. Set `allow_functions = TRUE`
only for a file you created and control.

## Examples

``` r
library(ggplot2)
style_register("mylab", theme_minimal())
f <- tempfile(fileext = ".rds")
style_save(f)
style_remove("mylab")
style_load(f)
unlink(f)
```
