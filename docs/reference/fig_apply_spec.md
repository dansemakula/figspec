# Apply a specification while building a plot

Adds a figure specification to a plot the same way you would add a
colour scale, so the figure is built to its requirements from the start
rather than corrected afterwards. The specification may be an included
publisher or journal profile, one loaded by your team, or a named list
supplied directly in R. One line applies its typography, stated line
weights and structural rules, together with colours and shapes chosen to
remain distinguishable.

## Usage

``` r
fig_apply_spec(
  spec,
  colour = TRUE,
  shapes = TRUE,
  style = NULL,
  base_size = NULL,
  color = NULL
)
```

## Arguments

- spec:

  A registry id such as `"cell_press"`, a `figspec_spec`, or a named
  list of requirements. The specification does not have to describe a
  journal.

- colour:

  Whether to set the colour and fill scales. Turn this off to keep a
  palette you have chosen yourself.

- shapes:

  Whether to set the shape scale.

- style:

  A house style registered with
  [`style_register()`](https://dansemakula.github.io/figspec/reference/style_register.md),
  applied underneath the journal's requirements.

- base_size:

  Base type size in points, passed to
  [`theme_spec()`](https://dansemakula.github.io/figspec/reference/theme_spec.md).

- color:

  American spelling of `colour`. Takes precedence when given. R's
  partial matching cannot cover this one, because `color` is not a
  prefix of `colour` - the spellings diverge at the fifth letter.

## Value

A list of ggplot2 components, to add to a plot with `+`.

## Details

Add it last. A scale added after this one replaces the journal's, which
is occasionally what you want and usually not.

When the specification includes a house-style palette,
`fig_apply_spec()` uses it. Otherwise, a specification that calls for
greyscale reproduction uses cividis, whose colours remain distinct in
greyscale; other specifications use the colour-vision-safe Okabe-Ito
palette.

Line widths inside a geom are set on the layer rather than the theme, so
pass
[`spec_linewidth()`](https://dansemakula.github.io/figspec/reference/spec_linewidth.md)
to any layer that draws lines.

## See also

[`spec_get()`](https://dansemakula.github.io/figspec/reference/spec_get.md)
for supplying a registry or project specification,
[`fig_save()`](https://dansemakula.github.io/figspec/reference/fig_save.md)
for exact export, and
[`fig_check()`](https://dansemakula.github.io/figspec/reference/fig_check.md)
for verification.

## Examples

``` r
library(ggplot2)

ggplot(ggplot2::mpg, aes(displ, hwy, colour = class, shape = drv)) +
  geom_point() +
  fig_apply_spec("cell_press")


# A project specification supplied directly in R; no journal is involved.
report_spec <- list(
  name = "Quarterly research report",
  font_min_pt = 9,
  min_line_pt = 0.5,
  print_greyscale = TRUE
)
ggplot(ggplot2::economics, aes(date, unemploy)) +
  geom_line(linewidth = spec_linewidth(report_spec)) +
  fig_apply_spec(report_spec)
```
