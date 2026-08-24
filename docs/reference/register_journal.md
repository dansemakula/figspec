# Add your own journal to the registry

Registers a journal for the current session, for a journal figspec does
not ship yet or for an internal report format of your own. Registered
journals behave exactly like shipped ones, but
[`journals()`](https://dansemakula.github.io/figspec/reference/journals.md)
marks them as user-supplied so it stays obvious which entries figspec
stands behind.

## Usage

``` r
register_journal(
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

  Short identifier, used everywhere a journal is named.

- name:

  Human-readable journal name.

- source_url:

  Where the requirements came from.

- verified_on:

  Date the source was read, as `"YYYY-MM-DD"`.

- requirements:

  Named list of stated requirements. See the shipped registry for the
  field names.

- house_style:

  Optional named list of purely visual preferences. May not contain
  requirement fields.

- ...:

  Further entry fields such as `publisher` or `disciplines`.

## Value

The registered specification, invisibly.

## Details

Provenance is required here too. If the requirements came from you
rather than a publisher, say so in `source_url`.

## Examples

``` r
register_journal(
  id = "lab_report",
  name = "Our lab report format",
  source_url = "internal handbook v3",
  verified_on = "2026-08-22",
  requirements = list(columns = list(single = 100, double = 170),
                      font_min_pt = 9, formats = list("pdf"))
)
fig_width("lab_report", "double")
#> [1] 170
```
