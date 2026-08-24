# The palette recorded for a journal's house style

Some registry entries record what a journal's figures tend to look like.
That is taste, not a rule: it lives in the entry's `house_style` block,
it is never checked, and using it does not make a figure compliant.

## Usage

``` r
journal_palette(journal)
```

## Arguments

- journal:

  Registry id.

## Value

A character vector of colours, or `NULL` if the entry records none.

## Examples

``` r
journal_palette("plos_one")
#> No house-style palette is recorded for 'PLOS ONE'. figspec does not invent
#> one: no publisher in the registry states which colours to use. See
#> figspec_palettes() for palettes chosen to survive print and colour-blind
#> readers.
```
