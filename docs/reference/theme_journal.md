# A ggplot2 theme that satisfies a journal's typography rules

Journals set a floor on type size, and often name the fonts they accept.
`theme_journal()` takes any base theme and enforces those constraints on
top of it, rather than imposing a look of its own. Every text element is
set to at least the journal's minimum size, so nothing falls below the
floor because of a relative sizing rule in the base theme.

## Usage

``` r
theme_journal(
  journal,
  base = NULL,
  style = NULL,
  base_size = NULL,
  base_family = NULL
)
```

## Arguments

- journal:

  Registry id, for example `"plos_one"`.

- base:

  A ggplot2 theme to build on. Defaults to
  [`ggplot2::theme_bw()`](https://ggplot2.tidyverse.org/reference/ggtheme.html).

- style:

  A house style to apply: a name registered with
  [`register_house_style()`](https://dansemakula.github.io/figspec/reference/register_house_style.md),
  a ggplot2 theme, or a function returning one. Styles are applied
  underneath the journal's requirements and can never override them.

- base_size:

  Base type size in points. Defaults to the journal's stated minimum, or
  9 pt when the journal states none.

- base_family:

  Font family. Defaults to the graphics device's own font. The journal's
  named font is *not* forced here, because a family the current device
  cannot resolve makes the plot fail to render at all.
  [`fig_save()`](https://dansemakula.github.io/figspec/reference/fig_save.md)
  applies the journal's font at save time, where the device is known.
  Pass a family explicitly to override.

## Value

A ggplot2 theme object.

## Details

This only holds if the figure is saved at the journal's stated width,
since type size is fixed in points but a figure scaled down after the
fact takes its text with it.
[`fig_save()`](https://dansemakula.github.io/figspec/reference/fig_save.md)
saves at the right width for you.

## Examples

``` r
library(ggplot2)
p <- ggplot(mtcars, aes(wt, mpg)) +
  geom_point() +
  theme_journal("plos_one")
```
