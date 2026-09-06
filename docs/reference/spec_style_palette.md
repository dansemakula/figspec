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

A house-style palette is a design preference, not a requirement. It is
never graded by
[`fig_check()`](https://dansemakula.github.io/figspec/reference/fig_check.md),
and using it does not by itself make a figure comply with a
specification. When no palette is recorded, figspec reports that fact
and returns `NULL` rather than inventing colours.

## Examples

``` r
spec_style_palette("plos_one")
#> No house-style palette is recorded for 'PLOS ONE'. figspec does not invent
#> missing house-style information. See figspec_palettes() for optional palettes
#> and guidance on where each works best.
```
