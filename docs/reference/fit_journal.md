# Bring a journal's requirements into a plot as you build it

Adds a journal's requirements to a plot the same way you would add a
colour scale, so the figure is built to specification from the start
rather than corrected afterwards. One line carries the journal's
typography, its stated line weights, its structural rules such as axis
lines and tick marks, and colours and shapes chosen to survive whatever
that journal does to a figure in production.

## Usage

``` r
fit_journal(
  journal,
  colour = TRUE,
  shapes = TRUE,
  style = NULL,
  base_size = NULL,
  color = NULL
)
```

## Arguments

- journal:

  Registry id, for example `"cell_press"`.

- colour:

  Whether to set the colour and fill scales. Turn this off to keep a
  palette you have chosen yourself.

- shapes:

  Whether to set the shape scale.

- style:

  A house style registered with
  [`register_house_style()`](https://dansemakula.github.io/figspec/reference/register_house_style.md),
  applied underneath the journal's requirements.

- base_size:

  Base type size in points, passed to
  [`theme_journal()`](https://dansemakula.github.io/figspec/reference/theme_journal.md).

- color:

  American spelling of `colour`. Takes precedence when given. R's
  partial matching cannot cover this one, because `color` is not a
  prefix of `colour` - the spellings diverge at the fifth letter.

## Value

A list of ggplot2 components, to add to a plot with `+`.

## Details

Add it last. A scale added after this one replaces the journal's, which
is occasionally what you want and usually not.

The palette follows the journal. Where a publisher reproduces figures in
black and white, `fit_journal()` reaches for cividis, which keeps its
colours apart in greyscale. Everywhere else it uses Okabe-Ito, built to
stay readable under the common forms of colour vision deficiency.

Line widths inside a geom are set on the layer rather than the theme, so
pass
[`figspec_linewidth()`](https://dansemakula.github.io/figspec/reference/figspec_linewidth.md)
to any layer that draws lines.

## Examples

``` r
library(ggplot2)

ggplot(mtcars, aes(wt, mpg, colour = factor(cyl), shape = factor(cyl))) +
  geom_point() +
  fit_journal("cell_press")


# Keep your own palette, take everything else.
ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) +
  geom_point() +
  scale_colour_viridis_d() +
  fit_journal("plos_one", colour = FALSE)
```
