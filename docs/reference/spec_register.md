# Register a publication specification for this session

Adds a specification that is not bundled with figspec, such as
requirements for an individual journal, conference or other publication.
The entry lasts for the current R session and can immediately be used
with
[`fig_save()`](https://dansemakula.github.io/figspec/reference/fig_save.md),
[`fig_check()`](https://dansemakula.github.io/figspec/reference/fig_check.md),
[`fig_apply_spec()`](https://dansemakula.github.io/figspec/reference/fig_apply_spec.md)
and the other specification-aware functions.
[`spec_list()`](https://dansemakula.github.io/figspec/reference/spec_list.md)
marks it as user-supplied so it remains distinct from profiles
maintained by figspec.

## Usage

``` r
spec_register(
  id,
  name,
  source_url,
  verified_on,
  requirements = list(),
  house_style = NULL,
  ...
)
```

## Arguments

- id:

  A short, unique identifier beginning with a lower-case letter and
  containing only lower-case letters, numbers and underscores. This is
  the value supplied to functions such as
  `fig_save(spec = "my_journal")`.

- name:

  The publication name shown in reports and registry listings.

- source_url:

  Where the requirements came from: an HTTP(S) page, a `file:` URI or an
  `internal:` identifier.

- verified_on:

  Date the source was last checked, as `"YYYY-MM-DD"` or a `Date`.
  Future and invalid dates are rejected.

- requirements:

  A named list containing only requirements stated by the source, such
  as `columns`, `dpi_min`, `formats`, `font_min_pt` or `min_line_pt`.
  Values are validated before the entry is registered.

- house_style:

  Optional named visual preferences, such as
  `list(palette = c("#1B4965", "#CA6702"))`. Requirements do not belong
  here and are rejected if included.

- ...:

  Optional registry information such as `publisher`, `disciplines`,
  `publication_stage`, `notes`, `tables`, `media` or
  `graphical_abstract`.

## Value

The registered specification, invisibly.

## Details

Every registered entry needs a source and a date. Use the public
guidance page when one exists. For a private manual or internal
decision, use an `internal:` identifier such as
`"internal:figure-handbook-v3"`.

## See also

[`spec_save()`](https://dansemakula.github.io/figspec/reference/spec_save.md)
to write a reusable YAML registry,
[`spec_load()`](https://dansemakula.github.io/figspec/reference/spec_load.md)
to load reusable entries and
[`registry_entry_template()`](https://dansemakula.github.io/figspec/reference/registry_entry_template.md)
to create a registry template.

## Examples

``` r
spec_register(
  id = "lab_report",
  name = "Our lab report format",
  source_url = "internal:handbook-v3",
  verified_on = "2026-08-22",
  requirements = list(columns = list(single = 100, double = 170),
                      font_min_pt = 9, formats = list("pdf"))
)
fig_width("lab_report", "double")
#> [1] 170
```
