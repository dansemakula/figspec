# Chunk options that produce journal-compliant figures in R Markdown or Quarto

A large share of academic figures never pass through
[`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html)
at all: they are produced by a knitr chunk, at whatever size `fig.width`
and `fig.height` happen to be. This returns the chunk options that make
knitr emit figures at the journal's size, resolution and format.

## Usage

``` r
figspec_chunk_opts(
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

A named list suitable for
[knitr::opts_chunk](https://rdrr.io/pkg/knitr/man/opts_chunk.html)`$set()`.

## Examples

``` r
figspec_chunk_opts("plos_one", "single")
#> $fig.width
#> [1] 2.629921
#> 
#> $fig.height
#> [1] 1.972441
#> 
#> $dpi
#> [1] 300
#> 
#> $dev
#> [1] "tiff"
#> 

# In a setup chunk:
# do.call(knitr::opts_chunk$set, figspec_chunk_opts("plos_one"))
```
