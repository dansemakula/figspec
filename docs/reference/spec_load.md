# Load specifications from a YAML registry

Reads a YAML registry maintained by a publication, project or
organisation and adds its specifications to the current R session. Each
entry then works with the same building, exporting and verification
functions as a bundled profile.
[`spec_list()`](https://dansemakula.github.io/figspec/reference/spec_list.md)
marks loaded entries as user-supplied.

## Usage

``` r
spec_load(path)
```

## Arguments

- path:

  Path to a non-empty YAML registry file. The file may contain a
  top-level `specifications:` list written by
  [`spec_save()`](https://dansemakula.github.io/figspec/reference/spec_save.md),
  the legacy `journals:` list used by figspec's bundled registry, or be
  the list of entries itself.

## Value

A character vector containing the loaded ids, invisibly.

## Details

Keep the YAML file with the project or in a shared version-controlled
repository. When requirements change, edit the file and call
`spec_load()` again; entries with the same user-defined id are updated
for the current session. Bundled profile ids remain reserved, keeping
loaded specifications clearly separated from package-maintained records.

Registry YAML is treated as data: YAML expression evaluation is disabled
regardless of the user's global `yaml.eval.expr` option. The complete
file is validated first, and its entries are added to the session
together only after every one passes.

## See also

[`spec_save()`](https://dansemakula.github.io/figspec/reference/spec_save.md)
to write reusable entries,
[`spec_register()`](https://dansemakula.github.io/figspec/reference/spec_register.md)
to add one entry directly in R and
[`registry_validate_file()`](https://dansemakula.github.io/figspec/reference/registry_validate_file.md)
to check a file without loading it.

## Examples

``` r
# spec_load("my-journals.yaml")
```
