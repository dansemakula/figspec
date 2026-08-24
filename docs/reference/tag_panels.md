# Label the panels of a figure

Adds panel labels in the style the journal asks for. Where a publisher
states one — capitals, lower case, numbers — that is what you get, so
the convention does not have to be looked up.

## Usage

``` r
tag_panels(
  plot,
  journal = NULL,
  level = NULL,
  open = "(",
  close = ")",
  strips = FALSE,
  x = -Inf,
  y = Inf,
  hjust = -0.6,
  vjust = 1.4,
  ...
)
```

## Arguments

- plot:

  A ggplot, faceted or not, or a patchwork composition.

- journal:

  Registry id, or a specification. Supplies the label style.

- level:

  Label vocabulary: `"A"`, `"a"`, `"1"`, `"I"` or `"i"`. Overrides the
  journal, which is what you want when a co-author has asked for
  something the publisher does not mention.

- open, close:

  Characters around the label. Journals rarely state these; `"("` and
  `")"` are common in print.

- strips:

  Whether to keep facet strips. Ignored for a composition.

- x, y, hjust, vjust:

  Where the label sits inside its panel.

- ...:

  Passed to
  [`ggplot2::geom_text()`](https://ggplot2.tidyverse.org/reference/geom_text.html),
  for size, face or family.

## Value

The plot, labelled.
[`fig_check()`](https://dansemakula.github.io/figspec/reference/fig_check.md)
recognises the result.

## Details

A composition made with patchwork is labelled through patchwork's own
tags. A faceted plot has no such machinery, so the labels are drawn
inside the panels and the facet strips are removed, which is the
convention for journals that treat facets as sub-figures. Keep the
strips with `strips = TRUE` if their content is doing work the labels do
not replace.

Nothing here is invented. Where a journal states no labelling rule, the
`level` you give applies, and if you give none the default is lower case
— a convention, and reported as one rather than as a requirement.

## See also

[`fig_check()`](https://dansemakula.github.io/figspec/reference/fig_check.md),
which reports whether a figure's panels meet the journal's labelling
rule.

## Examples

``` r
library(ggplot2)
p <- ggplot(mtcars, aes(wt, mpg)) + geom_point() + facet_wrap(~cyl)

# Cell Press asks for capitals; AGU asks for lower case.
tag_panels(p, "cell_press")


# Or say it yourself, where no journal is involved.
tag_panels(p, level = "a")
```
