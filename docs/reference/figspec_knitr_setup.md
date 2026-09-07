# Apply figure settings to R Markdown or Quarto

Applies the settings returned by
[`figspec_knitr_options()`](https://dansemakula.github.io/figspec/reference/figspec_knitr_options.md)
to knitr's current chunk configuration. Call it once in a document's
setup chunk so later figures use the chosen dimensions, resolution and
output format by default.

## Usage

``` r
figspec_knitr_setup(
  spec,
  column = NULL,
  width = NULL,
  height = NULL,
  units = c("mm", "cm", "in"),
  art_type = c("auto", "colour", "bw", "line", "combination")
)
```

## Arguments

- spec:

  The specification to use: a registry id such as `"plos_one"`, a
  `figspec_spec`, or a named list of requirements.

- column:

  Which named width in the specification to use. Leave it `NULL` when
  supplying `width` explicitly.

- width:

  Explicit figure width for specifications that do not publish named
  columns.

- height:

  Figure height. Defaults to three quarters of the width when no height
  is recorded; supply an explicit value when the specification or layout
  requires one.

- units:

  Units for `width` and `height`.

- art_type:

  Resolution category. With no plot available, `"auto"` conservatively
  uses the strictest rule the journal states.

## Value

The previous chunk options, invisibly.

## Examples

``` r
# In a setup chunk:
# figspec_knitr_setup("frontiers", "double")
```
