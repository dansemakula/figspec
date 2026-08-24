# Set knitr chunk options for a journal

Convenience wrapper that applies
[`figspec_chunk_opts()`](https://dansemakula.github.io/figspec/reference/figspec_chunk_opts.md)
to the current document. Call it from a setup chunk.

## Usage

``` r
figspec_knitr_setup(
  journal,
  column = "single",
  height = NULL,
  units = c("mm", "cm", "in")
)
```

## Arguments

- journal:

  Registry id, for example `"plos_one"`.

- column:

  Which column width to size to.

- height:

  Figure height. Defaults to three quarters of the width, which is a
  convenience rather than a journal requirement.

- units:

  Units for `height`.

## Value

The previous chunk options, invisibly.

## Examples

``` r
# In a setup chunk:
# figspec_knitr_setup("frontiers", "double")
```
