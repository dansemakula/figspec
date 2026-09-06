# Check a registry file before loading it

Runs the same checks
[`spec_load()`](https://dansemakula.github.io/figspec/reference/spec_load.md)
runs, but reports everything wrong rather than stopping at the first
problem.

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
