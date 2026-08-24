# Colour palettes that survive print and colour-blind readers

Lists the palettes figspec ships. None is a journal requirement: no
publisher in the registry states which colours to use. They are provided
because they pass the checks in
[`check_colour_safety()`](https://dansemakula.github.io/figspec/reference/check_colour_safety.md),
and each records where it came from.

## Usage

``` r
figspec_palettes()
```

## Value

A data frame of palette names, sizes and sources.

## Examples

``` r
figspec_palettes()
#>          id      name n
#> 1 okabe_ito Okabe-Ito 8
#> 2   cividis   Cividis 5
#> 3   viridis   Viridis 5
#>                                                       source
#> 1                 Okabe & Ito (2008), Color Universal Design
#> 2 Nunez, Anderton & Renslow (2018), PLOS ONE 13(7): e0199239
#> 3                    Smith & van der Walt (2015), matplotlib
```
