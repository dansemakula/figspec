# Look up table requirements

Publications, organisations and projects may set separate requirements
for tables, including orientation, titles, notes and permitted file
types. `table_spec()` returns the recorded instructions so they can be
consulted while the table is still being prepared. It does not claim to
verify rules that require editorial judgement.

## Usage

``` r
table_spec(spec)
```

## Arguments

- spec:

  A registry id such as `"nature"`, a `figspec_spec`, or a named list
  containing table requirements.

## Value

A list of the stated table requirements, or `NULL` with a message when
the selected specification records none.

## Examples

``` r
table_spec("nature")
#>
#> ── Nature - tables ─────────────────────────────────────────────────────────────
#> • Orientation: portrait
#> • Title style: short, one-line title in bold text
#> • Notes: Symbols and abbreviations are defined immediately below the table,
#> followed by essential descriptive material, all in double-spaced text.
#>
#> Publisher's wording: Tables should each be presented on a separate page,
#> portrait (not landscape) orientation, and upright on the page, not sideways.
#> Tables have a short, one-line title in bold text. Tables should be as small as
#> possible.
#>
#> Source: <https://www.nature.com/nature/for-authors/final-submission> (verified
#> 2026-09-03)
```
