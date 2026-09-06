# List the colour palettes included with figspec

Shows the palettes available through
[`figspec_palette()`](https://dansemakula.github.io/figspec/reference/figspec_palette.md)
and the figspec colour scales. The catalogue explains whether each
palette is intended for separate categories or ordered values, how many
colours it can provide, and when it is most useful. Each palette also
records its published source.

## Usage

``` r
figspec_palettes()
```

## Value

A data frame containing the palette id, display name, type, maximum
number of colours, recommended use, source and source URL. An infinite
maximum means that the sequential palette can generate any requested
number of colours.

## Details

These palettes are optional design tools, not requirements taken from a
publication. Each was selected for documented accessibility or
perceptual properties, but not every palette suits every output. In
particular, Okabe-Ito distinguishes categories for readers with common
forms of colour-vision deficiency but is not intended for greyscale
reproduction; Cividis and Viridis use an ordered lightness ramp that
remains legible in greyscale.

## Examples

``` r
figspec_palettes()
#>          id      name        type   n
#> 1 okabe_ito Okabe-Ito qualitative   8
#> 2   cividis   Cividis  sequential Inf
#> 3   viridis   Viridis  sequential Inf
#>                                                                                                                                                                                                                     guidance
#> 1 Built to stay distinguishable under the common forms of colour vision deficiency. It is NOT greyscale-safe: two of its colours sit at almost the same lightness, so use cividis where a journal prints in black and white.
#> 2                                                      Safe under colour vision deficiency and monotonic in lightness, so it also survives reproduction in black and white. Use this one when a journal prints in greyscale.
#> 3                                                              Perceptually uniform and monotonic in lightness, so it survives greyscale reproduction. Being a ramp, it suits ordered categories better than unordered ones.
#>                                                       source
#> 1                 Okabe & Ito (2008), Color Universal Design
#> 2 Nunez, Anderton & Renslow (2018), PLOS ONE 13(7): e0199239
#> 3                    Smith & van der Walt (2015), matplotlib
#>                                     source_url
#> 1             https://jfly.uni-koeln.de/color/
#> 2 https://doi.org/10.1371/journal.pone.0199239
#> 3             https://bids.github.io/colormap/
```
