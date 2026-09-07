# Create a registry-entry template

Prints a YAML template containing every field figspec understands. Fill
in the requirements stated by the source, list reviewed but unstated
fields under `not_stated`, and leave unreviewed fields in place. figspec
can then report the review status of every field accurately.

## Usage

``` r
registry_entry_template(id, name, source_url)
```

## Arguments

- id:

  Short identifier beginning with a lower-case letter and containing
  only lower-case letters, numbers and underscores.

- name:

  Publication, publisher, project or organisation name.

- source_url:

  Page or internal record from which the requirements will be taken.
  HTTP(S), `file:` and `internal:` addresses are accepted.

## Value

The template, invisibly, as a character string.

## Examples

``` r
registry_entry_template("plos_biology", "PLOS Biology",
                  "https://journals.plos.org/plosbiology/s/figures")
#> - id: plos_biology
#>   name: 'PLOS Biology'
#>   publisher:
#>   disciplines: [ ]
#>   source_url: 'https://journals.plos.org/plosbiology/s/figures'
#>   verified_on: '2026-09-07'
#>   requirements:
#>     # Fill in ONLY what the page states. Quote the wording for any number.
#>     # columns: {single: , onehalf: , double: }
#>     # width_min_mm:
#>     # width_max_mm:
#>     # height_max_mm:
#>     # dpi_min:
#>     # dpi_max:
#>     # dpi_min_inclusive:
#>     # dpi_max_inclusive:
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
#>     # tiff_compression:
#>     # allow_alpha:
#>     # flattened:
#>     # max_pages:
#>     # avoid_colour_pairs: [[red, green]]
#>     # print_greyscale:
#>     # panel_labels: uppercase
#>     # panel_labels_placement: inside_panel
#>     # max_panels:
#>     # text_case: sentence
#>     # text_no_final_stop:
#>     # axes_from_zero:
#>     # axis_lines_and_ticks:
#>     # avoid_coloured_text:
#>     # thousands_separator:
#>     # no_background_grid:
#>   not_stated:
#>     # Fields you READ the page for and confirmed are absent. Do not list a
#>     # field you simply did not check: leave it out and it reports as
#>     # "not yet harvested", which is true.
#>   # tables:
#>     # formats: [html, docx]
#>     # editable:
#>     # orientation: portrait
#>     # width_max_mm:
#>     # font_families: [ ]
#>     # font_min_pt:
#>     # font_max_pt:
#>     # title_style:
#>     # title_position: above
#>     # header_bold:
#>     # vertical_rules:
#>     # horizontal_rules: minimal
#>     # decimal_alignment:
#>     # footnotes:
#>     # abbreviations:
#>     # repeat_header:
#>     # split_rows:
#>   tables_not_stated:
#>     # Table fields you checked and confirmed are absent.
#>   # media: {video_formats: [ ], frame_max: {width: , height: }, max_file_mb: }
#>   # notes: >
```
