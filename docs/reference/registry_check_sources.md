# Check whether registry source pages still respond

Every entry names the page it was read from, and a page can be taken
down without anything in the registry changing. This asks each source
URL whether it still resolves.

## Usage

``` r
registry_check_sources(ids = NULL, timeout = 10)
```

## Arguments

- ids:

  Character vector of registry ids to check. Defaults to all of them.

- timeout:

  One positive number giving the seconds allowed for each response.

## Value

A data frame with one row per entry: `id`, `url`, `http` (the status
code, `NA` if nothing answered), `verdict`, and `final_url` where a
redirect led somewhere else. Ordered worst first.

## Details

A publisher that blocks robots is not a broken link. Most academic
publishers sit behind bot protection and answer a scripted request with
`403` while the page opens normally in a browser, so those are reported
as *blocked* and are not failures. Only `404` and `410` are read as
dead.

This reaches the network, so it is for maintainers rather than for use
inside anything that has to run offline.

## See also

[`registry_status()`](https://dansemakula.github.io/figspec/reference/registry_status.md)
for how old an entry is,
[`registry_stale_entries()`](https://dansemakula.github.io/figspec/reference/registry_stale_entries.md)
for which are due a recheck.

## Examples

``` r
# Reaches the network, so it is not run here.
if (FALSE) { # \dontrun{
registry_check_sources()
registry_check_sources("plos_one")
} # }
```
