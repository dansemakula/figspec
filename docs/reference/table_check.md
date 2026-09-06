# Verify a table against a specification

Checks a supported live R table or an exported HTML, DOCX, RTF, TeX,
PDF, PNG or JPEG table. File checks use the file that was actually
written; live-object checks can also use styling evidence that an image
or PDF no longer preserves.

## Usage

``` r
table_check(x, spec = NULL)
```

## Arguments

- x:

  A supported live table or one table-file path.

- spec:

  The specification to use, or NULL for inspection only.

## Value

A figspec table report, with one row per requirement considered.

## Details

Requirements that need a person to read the table, such as whether its
title is concise or every abbreviation is defined, are reported as
unresolved. figspec does not convert their absence into a pass.

## Examples

``` r
table_check(head(mtcars), list(
  name = "Research report",
  tables = list(header_bold = TRUE, vertical_rules = FALSE)
))
#>
#> ── Research report ─────────────────────────────────────────────────────────────
#> checked: data_frame table object
#>
#> ✔ File validity  valid                       requires: readable table object
#> ! Bold header    could not determine         requires: TRUE
#> ! Vertical rules could not determine         requires: FALSE
#>
#> ! No failures were found, but this assessment is incomplete.
#> ℹ 2 requirements or registry fields could not be judged automatically - check
#>   by hand.
```
