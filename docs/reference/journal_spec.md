# Look up one journal's figure specification

Look up one journal's figure specification

## Usage

``` r
journal_spec(journal)
```

## Arguments

- journal:

  Registry id, for example `"plos_one"`. Use
  [`journals()`](https://dansemakula.github.io/figspec/reference/journals.md)
  to see the available ids.

## Value

An object of class `figspec_spec`.

## Examples

``` r
journal_spec("frontiers")
#> 
#> ── Frontiers journals ──────────────────────────────────────────────────────────
#> Publisher: Frontiers Media
#> Disciplines: multidisciplinary
#> 
#> • Column widths: single 85 mm | double 180 mm
#> • Max height: not yet harvested
#> • Minimum resolution: 300 dpi
#> • Line-art resolution: not yet harvested
#> • File formats: TIFF, JPEG, EPS
#> • Fonts: not yet harvested
#> • Type size: 8 pt
#> • Colour mode: RGB
#> • Max file size: not specified by publisher
#> 
#> The two-point minimum line width is unusually heavy compared with other
#> publishers; it is stated as "Any lines in the graphic should be no smaller than
#> two points wide."
#> 
#> Source: <https://www.frontiersin.org/guidelines/author-guidelines>
#> Verified: 2026-08-21
```
