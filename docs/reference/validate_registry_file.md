# Validate a registry file before loading it

Runs the same checks
[`load_journals()`](https://dansemakula.github.io/figspec/reference/load_journals.md)
runs, but reports everything wrong rather than stopping at the first
problem.

## Usage

``` r
validate_registry_file(path)
```

## Arguments

- path:

  Path to a YAML file in registry format.

## Value

`TRUE` invisibly if the file is valid; otherwise the problems are
reported and `FALSE` is returned invisibly.

## Examples

``` r
# validate_registry_file("my-journals.yaml")
```
