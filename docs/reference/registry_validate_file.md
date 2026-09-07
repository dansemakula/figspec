# Check a registry file before loading it

Runs the same checks as
[`spec_load()`](https://dansemakula.github.io/figspec/reference/spec_load.md)
and returns the complete set of problems in one report, making the file
easier to correct in a single pass.

## Usage

``` r
registry_validate_file(path)
```

## Arguments

- path:

  Path to a YAML file in registry format.

## Value

`TRUE` invisibly if the file is valid; otherwise the problems are
reported and `FALSE` is returned invisibly.

## Examples

``` r
# registry_validate_file("my-journals.yaml")
```
