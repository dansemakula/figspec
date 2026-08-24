# Graphical abstract requirements for a journal

Many journals ask for a graphical abstract, or table-of-contents entry,
and set separate rules for it: usually a much smaller canvas than a
figure, and sometimes a character limit on the accompanying text. These
are not figure requirements and are not checked by
[`fig_check()`](https://dansemakula.github.io/figspec/reference/fig_check.md).

## Usage

``` r
graphical_abstract_spec(journal)
```

## Arguments

- journal:

  Registry id, for example `"rsc"`.

## Value

A list of the stated requirements, or `NULL` with a message when the
registry records none for that journal.

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
