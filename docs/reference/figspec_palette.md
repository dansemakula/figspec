# The colours in a figspec palette

The colours in a figspec palette

## Usage

``` r
figspec_palette(palette = "okabe_ito", n = NULL)
```

## Arguments

- palette:

  Palette id, from
  [`figspec_palettes()`](https://dansemakula.github.io/figspec/reference/figspec_palettes.md).

- n:

  Number of colours to return. Defaults to all of them.

## Value

A character vector of hex colours.

## Examples

``` r
figspec_palette("okabe_ito", 3)
#> [1] "#000000" "#E69F00" "#56B4E9"
```
