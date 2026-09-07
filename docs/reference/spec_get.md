# Retrieve or create a specification

Retrieves a bundled publisher or journal profile by its registry id, or
converts a named list maintained by your project or organisation into a
`figspec_spec`. The resulting object can be passed to
[`fig_check()`](https://dansemakula.github.io/figspec/reference/fig_check.md),
[`fig_save()`](https://dansemakula.github.io/figspec/reference/fig_save.md)
and the other specification-aware functions.

## Usage

``` r
spec_get(spec)
```

## Arguments

- spec:

  The specification to use: a registry id such as `"plos_one"`, an
  existing `figspec_spec`, or a named list containing at least a
  non-empty `name`. Use
  [`spec_list()`](https://dansemakula.github.io/figspec/reference/spec_list.md)
  to browse the available registry ids. Project, report and
  organisational specifications are accepted in the same form as
  publication profiles.

## Value

An object of class `figspec_spec`. An existing specification object is
returned unchanged.

## Examples

``` r
spec_get("frontiers")
#>
#> ── Frontiers journals ──────────────────────────────────────────────────────────
#> Publisher: Frontiers Media
#> Disciplines: multidisciplinary
#>
#>   • Column widths: single 85 mm | double 180 mm
#>   • Max height: not yet harvested
#>   • Minimum resolution: 300 dpi
#>   • Line-art resolution: not yet harvested
#>   • File formats: TIFF, JPEG, EPS
#>   • Fonts: not yet harvested
#>   • Type size: 8 pt
#>   • Colour mode: RGB
#>   • Max file size: not specified by publisher
#>
#> The two-point minimum line width is unusually heavy compared with other
#> publishers; it is stated as "Any lines in the graphic should be no smaller than
#> two points wide."
#>
#> Source: <https://www.frontiersin.org/guidelines/author-guidelines>
#> Verified: 2026-08-21

report_spec <- spec_get(list(
  name = "Quarterly research report",
  columns = list(full = 160),
  formats = c("png", "pdf"),
  dpi_min = 300,
  font_min_pt = 9
))
report_spec
#>
#> ── Quarterly research report ───────────────────────────────────────────────────
#>
#>   • Column widths: full 160 mm
#>   • Max height: not yet harvested
#>   • Minimum resolution: 300 dpi
#>   • Line-art resolution: not yet harvested
#>   • File formats: PNG, PDF
#>   • Fonts: not yet harvested
#>   • Type size: 9 pt
#>   • Colour mode: not yet harvested
#>   • Max file size: not yet harvested
#>
#> Source: <>
#> Verified:
```
