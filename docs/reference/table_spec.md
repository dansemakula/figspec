# Table requirements for a journal

Journals also publish rules for tables, but those rules are mostly
editorial rather than numeric: orientation, how the title is set, where
footnotes go. `table_spec()` surfaces what the publisher states so you
can follow it. It deliberately does not try to check a table
automatically, because almost nothing in a table specification is
mechanically checkable from an R object.

## Usage

``` r
table_spec(journal)
```

## Arguments

- journal:

  Registry id, for example `"nature"`.

## Value

A list of the stated table requirements, or `NULL` with a message when
the registry records none for that journal.

## Examples

``` r
table_spec("nature")
#> 
#> ── Nature - tables ─────────────────────────────────────────────────────────────
#> • orientation: portrait
#> • title_style: short, one-line title in bold text
#> • notes: Symbols and abbreviations are defined immediately below the table,
#> followed by essential descriptive material, all in double-spaced text.
#> 
#> Publisher's wording: Tables should each be presented on a separate page,
#> portrait (not landscape) orientation, and upright on the page, not sideways.
#> Tables have a short, one-line title in bold text. Tables should be as small as
#> possible.
#> 
#> Source: <https://www.nature.com/nature/for-authors/initial-submission>
#> (verified 2026-08-22)
```
