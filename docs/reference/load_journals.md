# Load journal entries from your own registry file

Reads a YAML file in the same shape as the shipped registry and adds
every entry for the current session. Use this to keep an institutional
set of journals under version control alongside your papers.

## Usage

``` r
load_journals(path)
```

## Arguments

- path:

  Path to a YAML file.

## Value

The ids loaded, invisibly.

## Examples

``` r
# load_journals("my-journals.yaml")
```
