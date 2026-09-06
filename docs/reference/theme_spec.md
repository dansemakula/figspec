# Apply typography requirements and a visual style

`theme_spec()` takes any base theme and applies the typographic
constraints in a specification on top of it, rather than imposing a look
of its own. The specification may come from a publisher, a journal or a
project. Every text element is set to at least its minimum size, so
nothing falls below the floor because of a relative sizing rule in the
base theme.

## Usage

``` r
theme_spec(
  spec,
  base = NULL,
  style = NULL,
  base_size = NULL,
  base_family = NULL
)
```

## Arguments

- spec:

  A registry id such as `"plos_one"`, a `figspec_spec`, or a named list
  of requirements.

- base:

  A ggplot2 theme to build on. Defaults to
  [`ggplot2::theme_bw()`](https://ggplot2.tidyverse.org/reference/ggtheme.html).

- style:

  A house style to apply: a name registered with
  [`style_register()`](https://dansemakula.github.io/figspec/reference/style_register.md),
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

## See also

[`fig_apply_spec()`](https://dansemakula.github.io/figspec/reference/fig_apply_spec.md)
to apply typography, colour and shape together, and
[`style_register()`](https://dansemakula.github.io/figspec/reference/style_register.md)
to reuse an organisation or project style.

## Examples

``` r
library(ggplot2)
p <- ggplot(ggplot2::economics, aes(date, unemploy)) +
  geom_point() +
  theme_spec("plos_one")

# Project typography can be supplied directly.
report_spec <- list(name = "Annual report", font_min_pt = 10)
ggplot(ggplot2::economics, aes(date, unemploy)) +
  geom_line() +
  theme_spec(report_spec)
```
