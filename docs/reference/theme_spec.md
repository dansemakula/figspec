# Apply typography requirements and a visual style

`theme_spec()` takes any base theme and adds the typographic constraints
recorded in a specification. The specification may come from a
publisher, a journal or a project. Every text element is set to at least
its minimum size, so nothing falls below the floor because of a relative
sizing rule in the base theme.

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
  a ggplot2 theme, or a function returning one. Visual choices are
  applied first, followed by any overlapping requirements in the
  specification.

- base_size:

  Base type size in points. Defaults to the specification's stated
  minimum, or 9 pt when none is recorded.

- base_family:

  Font family. Defaults to the graphics device's own font.
  [`fig_save()`](https://dansemakula.github.io/figspec/reference/fig_save.md)
  resolves a font named by the specification when it selects the output
  device. Pass a family here when you already know which installed font
  the current device should use.

## Value

A ggplot2 theme object.

## Details

Preserve these type sizes by saving the figure at its intended width.
[`fig_save()`](https://dansemakula.github.io/figspec/reference/fig_save.md)
reads that width from the specification and writes the finished file
accordingly.

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
