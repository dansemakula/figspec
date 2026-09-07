# Register a reusable visual style

A house style records the visual choices a project, team or organisation
wants to reuse across its figures. Once registered, the style can be
applied by name with
[`theme_spec()`](https://dansemakula.github.io/figspec/reference/theme_spec.md).

## Usage

``` r
style_register(name, theme, description = NULL)
```

## Arguments

- name:

  A short identifier used to apply the style later.

- theme:

  The ggplot2 theme to reuse, or a function that returns one.

- description:

  An optional one-line explanation of where or why the style is used.

## Value

The registered style, invisibly.

## Details

The style supplies the starting appearance, followed by any overlapping
requirements in the specification. If your style sets type at 6 pt and
the specification states a floor of 8 pt,
[`theme_spec()`](https://dansemakula.github.io/figspec/reference/theme_spec.md)
raises the type to 8 pt and tells you which elements changed. All other
style choices remain in the finished figure.

## Examples

``` r
library(ggplot2)
style_register(
  "mylab",
  theme_minimal() + theme(panel.grid.minor = element_blank()),
  description = "Minimal, no minor grid"
)
style_list()
#>    name            description
#> 1 mylab Minimal, no minor grid

p <- ggplot(ggplot2::mpg, aes(displ, hwy, colour = class)) + geom_point()
p + theme_spec("frontiers", style = "mylab")
```
