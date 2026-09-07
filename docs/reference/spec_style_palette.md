# Retrieve a recorded house-style palette

Retrieves the optional palette stored in the `house_style` section of a
registry or user-supplied specification. This can represent the visual
identity of a publication, project or organisation.

## Usage

``` r
spec_style_palette(spec)
```

## Arguments

- spec:

  The specification whose house-style palette should be retrieved.
  Supply a registry id, a `figspec_spec`, or a named list. It may
  describe a publication, project or organisation.

## Value

A character vector of recorded R colours, preserving any names, or
`NULL` when the specification contains no house-style palette.

## Details

A house-style palette is a design preference, so
[`fig_check()`](https://dansemakula.github.io/figspec/reference/fig_check.md)
keeps it separate from pass-or-fail requirements. When no palette is
recorded, figspec reports that fact and returns `NULL`, leaving the
plotting system's existing colours in place.

## Examples

``` r
spec_style_palette("plos_one")
#> No house-style palette is recorded for 'PLOS ONE'. The plotting system will
#> keep its current colours. See figspec_palettes() when you want to choose an
#> optional palette, with guidance on where each works best.
```
