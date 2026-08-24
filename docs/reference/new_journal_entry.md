# A skeleton for a new registry entry

Prints a YAML template with every field figspec understands, so a
contributor is told what to look for rather than having to guess the
schema. Fill in what the publisher states, list the rest under
`not_stated`, and delete nothing: a field left in neither place is
reported to users as not yet harvested, which is the honest default.

## Usage

``` r
new_journal_entry(id, name, source_url)
```

## Arguments

- id:

  Short identifier for the entry.

- name:

  Journal or publisher name.

- source_url:

  The author-guidelines page the values will come from.

## Value

The template, invisibly, as a character string.

## Examples

``` r
new_journal_entry("plos_biology", "PLOS Biology",
                  "https://journals.plos.org/plosbiology/s/figures")
#> - id: plos_biology
#>   name: PLOS Biology
#>   publisher: 
#>   disciplines: [ ]
#>   source_url: https://journals.plos.org/plosbiology/s/figures
#>   verified_on: '2026-08-24'
#>   requirements:
#>     # Fill in ONLY what the page states. Quote the wording for any number.
#>     # columns: {single: , onehalf: , double: }
#>     # width_min_mm: 
#>     # width_max_mm: 
#>     # height_max_mm: 
#>     # dpi_min: 
#>     # dpi_line_art: 
#>     # dpi_bw: 
#>     # dpi_combination: 
#>     # formats: [ ]
#>     # colour_mode: [ ]
#>     # max_file_mb: 
#>     # font_families: [ ]
#>     # font_min_pt: 
#>     # font_max_pt: 
#>     # min_line_pt: 
#>     # max_line_pt: 
#>     # avoid_colour_pairs: [[red, green]]
#>     # print_greyscale: 
#>     # panel_labels: uppercase
#>     # text_case: sentence
#>   not_stated:
#>     # Fields you READ the page for and confirmed are absent. Do not list a
#>     # field you simply did not check: leave it out and it reports as
#>     # "not yet harvested", which is true.
#>   # media: {video_formats: [ ], frame_max: {width: , height: }, max_file_mb: }
#>   # tables: {orientation: , title_style: }
#>   # notes: >
```
