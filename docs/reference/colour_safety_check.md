# Check whether a figure's colours remain distinguishable

Examines the colours used to represent data before the figure is
exported. The report shows whether the plot uses a prohibited colour
pairing, whether its colours remain distinguishable in greyscale, and
how they appear under three common forms of colour-vision deficiency. If
colours become difficult to tell apart, the report also notes whether
shape or line type gives readers another way to identify the groups.

## Usage

``` r
colour_safety_check(plot, spec, threshold = 10)

color_safety_check(plot, spec, threshold = 10)
```

## Arguments

- plot:

  A ggplot object. Use the editable plot rather than an exported file so
  that figspec can inspect the colours actually mapped to data.

- spec:

  The specification to check against. Supply a registry id, a
  `figspec_spec`, or a named list containing the colour and reproduction
  requirements for a publication, project or organisation.

- threshold:

  The smallest perceptual difference that figspec will accept between
  two colours, measured as CIE Delta-E 2000. The default is 10; raising
  it makes the distinction test stricter. This setting controls the
  accessibility analysis; pass-or-fail publication results continue to
  use the rules recorded in the selected specification.

## Value

A `figspec_report`.

## Details

When the selected specification states a colour or reproduction rule,
figspec reports a pass or fail against that rule. Other findings appear
as guidance with an `unspecified` status, keeping the source
requirements and the general accessibility review clearly separated.

## Examples

``` r
library(ggplot2)
p <- ggplot(ggplot2::mpg, aes(displ, hwy, colour = class)) + geom_point()
p

colour_safety_check(p, "cell_press")
#>
#> ── Cell Press journals ─────────────────────────────────────────────────────────
#> checked: ggplot object
#>
#> ✖ Colour pairs     red and green both used (#F8766D, #53B400)
#>                    requires: red and green not used together
#> ℹ Greyscale        21 pair(s) merge in greyscale: #C49A00/#53B400,
#>                    #C49A00/#FB61D7, #C49A00/#F8766D, #C49A00/#00C094 and 17
#>                    more
#>                    requires: not specified by publisher
#> ℹ Colour vision    colours merge under deuteranopia (4), protanopia (3),
#>                    tritanopia (3)
#>                    requires: not specified by publisher
#> ℹ Redundant coding colour is the only cue: all series share one shape and one
#>                    line type
#>                    requires: not specified by publisher
#>
#> ✖ 1 requirement not met.
#> Source: <https://www.cell.com/information-for-authors/figure-guidelines>
#> (verified 2026-08-21)
```
