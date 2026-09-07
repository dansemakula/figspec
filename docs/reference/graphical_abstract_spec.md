# Look up graphical abstract requirements

A publication or project may require a graphical abstract or
table-of-contents image with its own dimensions, resolution, format and
text limit. These requirements are separate from ordinary figures and
are not checked by
[`fig_check()`](https://dansemakula.github.io/figspec/reference/fig_check.md).

## Usage

``` r
graphical_abstract_spec(spec)
```

## Arguments

- spec:

  A registry id such as `"rsc"`, a `figspec_spec`, or a named list
  containing graphical-abstract requirements.

## Value

A list of the stated requirements, or `NULL` with a message when the
selected specification records none.

## Examples

``` r
graphical_abstract_spec("rsc")
#>
#> ── Royal Society of Chemistry journals - graphical abstract ────────────────────
#> • Maximum size: 80 x 40 mm
#> • Resolution: 600 dpi
#> • Formats: TIFF
#> • Text limit: 250 characters
#>
#> The figure should be a maximum size of 8 cm wide x 4 cm high ... Figures should
#> be supplied as TIFF files, with a resolution of 600 dpi or greater ... The text
#> supplied should be 1-2 sentences long, using a maximum of 250 characters.
#>
#> Source:
#> <https://www.rsc.org/publishing/publish-with-us/publish-a-journal-article/chem-soc-rev>
#> (verified 2026-08-22)
```
