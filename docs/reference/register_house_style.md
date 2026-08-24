# Register a house style of your own

A house style is the visual half of a figure: the look you want your
lab, group or publication to have. Register one and you can apply it to
any journal by name.

## Usage

``` r
register_house_style(name, theme, description = NULL)
```

## Arguments

- name:

  Short name you will refer to the style by.

- theme:

  A ggplot2 theme object, or a function returning one.

- description:

  Optional one-line description.

## Value

The registered style, invisibly.

## Details

Styles are applied *underneath* a journal's requirements, never over
them. If your style sets type at 6 pt and the journal states a floor of
8 pt, the journal wins and
[`theme_journal()`](https://dansemakula.github.io/figspec/reference/theme_journal.md)
tells you which elements it had to override. That ordering is
deliberate: a style can change how a figure looks, but it can never make
a figure non-compliant.

## Examples

``` r
library(ggplot2)
register_house_style(
  "mylab",
  theme_minimal() + theme(panel.grid.minor = element_blank()),
  description = "Minimal, no minor grid"
)
house_styles()
#>    name            description
#> 1 mylab Minimal, no minor grid

p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
p + theme_journal("frontiers", style = "mylab")
```
