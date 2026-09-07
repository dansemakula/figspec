# Get a set of distinct line types

Returns line types that can distinguish a small number of series without
relying on colour alone. Use them in a manual linetype scale so that a
plot remains readable when it is reproduced in greyscale or when two
colours are difficult to tell apart.

## Usage

``` r
figspec_linetypes(n)
```

## Arguments

- n:

  The number of line types needed, usually the number of series in the
  data. Up to six are available.

## Value

A character vector containing one ggplot2 line type per series.

## Details

These patterns are design recommendations, not requirements taken from a
publication or project specification. figspec provides six and reports
that capacity when more are requested, keeping every series visually
distinct.

## Examples

``` r
library(ggplot2)
series <- subset(
  ggplot2::economics_long,
  variable %in% c("psavert", "uempmed", "unemploy")
)
ggplot(series, aes(date, value01, linetype = variable)) +
  geom_line(linewidth = 0.7) +
  scale_linetype_manual(values = figspec_linetypes(3)) +
  labs(x = NULL, y = "Value, rescaled to 0–1", linetype = "Series")
```
