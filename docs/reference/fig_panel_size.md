# Set exact dimensions for every data panel

Sets the plot area to an exact physical size and calculates the complete
image around it. Two figures given the same panel size line up even when
their axis labels differ, and their text keeps its intended size.

## Usage

``` r
fig_panel_size(plot, width = NULL, height = NULL, units = c("mm", "cm", "in"))
```

## Arguments

- plot:

  The plot or composition whose data panels you want to size. This can
  be a ggplot, a patchwork composition, or a `gtable`.

- width, height:

  The size of each data panel. Leave either value as `NULL` to change
  only the other dimension.

- units:

  The units used for `width` and `height`.

## Value

A `gtable`, which can be drawn with
[`grid::grid.draw()`](https://rdrr.io/r/grid/grid.draw.html) and saved
like a plot. Its achieved geometry is attached as the
`"figspec_geometry"` attribute.

## Details

Conventional sizing fixes the complete image and leaves the remaining
room to the panel. `fig_panel_size()` fixes the panel itself, then
expands or contracts the image to accommodate its labels, axes, legend
and margins.

For a faceted plot, or a composition made with patchwork, the size
applies to *each* panel, which is what makes panels comparable between
figures.

## What the example demonstrates

The example draws the same data twice at a common physical scale. In the
first figure, a conventional 60 mm canvas leaves less than 62 mm for the
data after the axes and labels have been accommodated. In the second,
`fig_panel_size()` protects a 62 mm data panel and calculates the wider
canvas needed around it. The browser may enlarge the complete comparison
for readability, but the relative dimensions of the two figures remain
unchanged.

## See also

[`fig_save()`](https://dansemakula.github.io/figspec/reference/fig_save.md),
which does this and works out the image size for you.

## Examples

``` r
library(ggplot2)

p <- ggplot(ggplot2::mpg, aes(displ, hwy, fill = cty)) +
  geom_point(
    shape = 21, size = 2, alpha = 0.82,
    colour = "white", stroke = 0.25
  ) +
  scale_fill_gradient(
    low = "#56B4E9", high = "#D55E00", guide = "none"
  ) +
  labs(
    x = "Engine displacement (litres)",
    y = "Highway fuel economy"
  ) +
  theme_minimal(base_size = 9) +
  theme(
    panel.background = element_rect(
      fill = "#F3F8FC", colour = "#1A7391", linewidth = 0.7
    ),
    plot.background = element_rect(
      fill = "white", colour = "#9AA4AE", linewidth = 0.6
    ),
    plot.title = element_text(face = "bold", colour = "#16313B"),
    plot.subtitle = element_text(colour = "#4B6570")
  )

# Before: fixing the complete canvas at 60 mm leaves whatever panel width
# remains after the axes and labels have taken their space.
before_canvas <- 60
before_panel <- fig_panel_width(p, width = before_canvas)
before <- fig_panel_size(
  p + labs(
    title = "Before: 60 mm canvas",
    subtitle = sprintf(
      "Data panel: %.1f mm", before_panel
    )
  ),
  width = before_panel, height = 45
)

# After: protect a 62 mm data panel and let figspec calculate the canvas.
after <- fig_panel_size(
  p + labs(
    title = "After: 62 mm data panel",
    subtitle = "The canvas expands to fit"
  ),
  width = 62, height = 45
)

before_geometry <- fig_geometry(before)
after_geometry <- fig_geometry(after)
data.frame(
  version = c("Before", "After"),
  canvas_width_mm = c(
    before_geometry$canvas_width_mm,
    after_geometry$canvas_width_mm
  ),
  panel_width_mm = c(
    before_geometry$panel_width_mm,
    after_geometry$panel_width_mm
  )
)
#>   version canvas_width_mm panel_width_mm
#> 1  Before           60.02          48.83
#> 2   After           73.18          62.00

# Draw both figures at the same physical scale. The wider after-image is
# deliberate: its additional canvas preserves the requested data panel.
comparison <- gtable::gtable_matrix(
  "before-after",
  grobs = matrix(list(before, after), nrow = 1),
  widths = grid::unit(
    c(
      before_geometry$canvas_width_mm,
      after_geometry$canvas_width_mm
    ),
    "mm"
  ),
  heights = grid::unit(
    max(
      before_geometry$canvas_height_mm,
      after_geometry$canvas_height_mm
    ),
    "mm"
  )
)
comparison <- gtable::gtable_add_cols(
  comparison, grid::unit(5, "mm"), pos = 1
)
grid::grid.newpage()
grid::grid.draw(comparison)
```
