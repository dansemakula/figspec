# Save a specification for reuse

Writes a publication, project or organisational specification to a safe,
reusable YAML registry file. A new specification is appended when the
file already contains other entries. Replacing an entry with the same
`id` requires `overwrite = TRUE`.

## Usage

``` r
spec_save(
  spec,
  path,
  id = NULL,
  source_url = NULL,
  verified_on = NULL,
  overwrite = FALSE
)
```

## Arguments

- spec:

  A registry id, a `figspec_spec`, or a named list containing at least a
  non-empty `name` and any figure, table, media or graphical-abstract
  requirements to save.

- path:

  Destination `.yaml` or `.yml` file. If it already contains a valid
  figspec registry, a new `id` is appended without removing the other
  entries.

- id:

  A short identifier beginning with a lower-case letter and containing
  only lower-case letters, numbers and underscores. It may be omitted
  when `spec` already contains an `id`.

- source_url:

  Where the requirements came from: an HTTP(S) page, a `file:` URI or an
  `internal:` identifier. When omitted, an existing value in `spec` is
  kept; otherwise `internal:<id>` is recorded.

- verified_on:

  Date the source or internal requirements were last checked, as
  `"YYYY-MM-DD"` or a `Date`. When omitted, an existing value in `spec`
  is kept; otherwise today's date is recorded.

- overwrite:

  Whether an entry with the same `id` may be replaced. Other entries in
  the file are always preserved.

## Value

`path`, invisibly.

## Details

The complete registry is validated in a temporary file before the
requested path is changed. If writing or validation fails, an existing
file is left unchanged. The resulting file can be kept with a project,
shared under version control and loaded in any R session with
[`spec_load()`](https://dansemakula.github.io/figspec/reference/spec_load.md).

A specification created directly in R may not contain provenance fields.
In that case figspec records `internal:<id>` as its source and today's
date as the date the internal requirements were recorded. Supply
`source_url` and `verified_on` when the requirements came from a
published or separately maintained source.

## See also

[`spec_load()`](https://dansemakula.github.io/figspec/reference/spec_load.md),
[`spec_register()`](https://dansemakula.github.io/figspec/reference/spec_register.md),
[`registry_validate_file()`](https://dansemakula.github.io/figspec/reference/registry_validate_file.md)

## Examples

``` r
report_spec <- list(
  name = "Research unit report",
  columns = list(full = 160),
  dpi_min = 300,
  formats = c("png", "pdf")
)
registry_file <- tempfile(fileext = ".yml")
spec_save(report_spec, registry_file, id = "research_unit_report")
spec_load(registry_file)
fig_width("research_unit_report", "full")
#> [1] 160
unlink(registry_file)
```
