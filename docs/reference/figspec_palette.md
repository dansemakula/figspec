# Get colours from a figspec palette

Returns a vector of hexadecimal colours that can be passed to a ggplot2
manual scale or used anywhere else R accepts colours. Use
[`figspec_palettes()`](https://dansemakula.github.io/figspec/reference/figspec_palettes.md)
to compare the available palettes and their recommended uses.

## Usage

``` r
figspec_palette(palette = "okabe_ito", n = NULL)
```

## Arguments

- palette:

  The id of the palette to use, as listed by
  [`figspec_palettes()`](https://dansemakula.github.io/figspec/reference/figspec_palettes.md).

- n:

  The number of colours to return. When omitted, a sequential palette
  returns five colours and a fixed palette returns all of its colours.
  Cividis and Viridis can generate any requested number; a fixed palette
  returns an error rather than recycling a colour for two groups.

## Value

A character vector of hex colours.

## Examples

``` r
library(ggplot2)
colours <- figspec_palette("okabe_ito", 7)
ggplot(ggplot2::mpg, aes(displ, hwy, colour = class)) +
  geom_point() +
  scale_colour_manual(values = colours)
```
