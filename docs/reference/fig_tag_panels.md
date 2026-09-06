# Add and format labels for every panel

Adds panel labels in the style the journal asks for. Where a publisher
states one — capitals, lower case, numbers — that is what you get, so
the convention does not have to be looked up.

## Usage

``` r
fig_tag_panels(
  plot,
  spec = NULL,
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

  A faceted ggplot or a patchwork composition to label.

- spec:

  A registry id, a `figspec_spec`, or a named list containing the
  panel-label requirements.

- level:

  Label vocabulary: `"A"`, `"a"`, `"1"`, `"I"` or `"i"`. An explicit
  value overrides the specification;
  [`fig_check()`](https://dansemakula.github.io/figspec/reference/fig_check.md)
  will report a failure if the choice conflicts with a stated
  requirement.

- open, close:

  The characters placed before and after each label. Parentheses are
  used by default.

- strips:

  Whether to retain facet-strip headings. This is ignored for a
  patchwork composition.

- x, y, hjust, vjust:

  The position and alignment of labels inside each faceted panel.

- ...:

  Additional label settings passed to
  [`ggplot2::geom_text()`](https://ggplot2.tidyverse.org/reference/geom_text.html),
  such as `size`, `fontface`, `family`, or `colour`.

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
p <- ggplot(ggplot2::mpg, aes(displ, hwy)) +
  geom_point() + facet_wrap(~drv)

# Cell Press asks for capitals; AGU asks for lower case.
fig_tag_panels(p, "cell_press")


# Or say it yourself, where no journal is involved.
fig_tag_panels(p, level = "a")
```
