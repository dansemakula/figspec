# All function arguments

The tables on this page list the arguments accepted by figspec’s
functions and explain what each argument controls. Use them to compare
related functions or find the setting for a particular task. For
complete instructions, return values and runnable examples, open the
function’s page in the Reference section.

## Building, checking and exporting a figure

### `fig_save()`

Save a figure at an exact size and resolution

These examples use all 234 rows of ggplot2’s mpg data. Run the setup
once, then open an argument below to see how it changes the export. The
setup also defines a project specification to show the alternative to
using a bundled journal profile.

Run the example setup

``` r

library(ggplot2)

p <- ggplot(mpg, aes(displ, hwy, colour = drv, shape = drv)) +
  geom_point(alpha = 0.7) +
  labs(
    x = "Engine displacement (litres)",
    y = "Highway fuel economy",
    colour = "Drive type",
    shape = "Drive type"
  ) +
  theme_minimal()

report_spec <- list(
  name = "Research report",
  columns = list(full = 160),
  formats = "png",
  dpi_min = 300,
  dpi_line_art = 600
)
```

[TABLE]

### `fig_check()`

Inspect a figure and verify it against a specification

These examples check the same real plot and a TIFF exported from it. Run
the setup once, then open an argument to see what figspec measures and
how it reports the result.

Run the example setup

``` r

library(ggplot2)

p <- ggplot(mpg, aes(displ, hwy, colour = drv, shape = drv)) +
  geom_point(alpha = 0.7) +
  labs(
    x = "Engine displacement (litres)",
    y = "Highway fuel economy",
    colour = "Drive type",
    shape = "Drive type"
  ) +
  theme_minimal()

pnas_file <- fig_save(
  file.path(tempdir(), "pnas-check-example.tiff"),
  p,
  spec = "pnas",
  column = "small",
  art_type = "colour",
  check = FALSE
)

report_spec <- list(
  name = "Research report",
  columns = list(full = 160),
  formats = "png",
  dpi_min = 300
)
```

[TABLE]

### `fig_geometry()`

Measure panel and canvas dimensions

fig_geometry() measures the panel and the complete canvas. Its plot()
method turns those measurements into a diagram, making it easier to see
how much room is used by labels, legends and margins.

Run the example setup

``` r

library(ggplot2)

p <- ggplot(mpg, aes(displ, hwy, colour = drv, shape = drv)) +
  geom_point(alpha = 0.7) +
  labs(
    x = "Engine displacement (litres)",
    y = "Highway fuel economy",
    colour = "Drive type",
    shape = "Drive type"
  ) +
  theme_minimal()

sized <- fig_panel_size(p, width = 62, height = 45)
geometry <- fig_geometry(sized)

saved <- fig_save(
  file.path(tempdir(), "measured-panel.png"),
  p,
  panel_width = 62,
  panel_height = 45,
  check = FALSE
)
```

[TABLE]

### `fig_apply_spec()`

Apply a specification while building a plot

The examples start with one plot so that each argument’s effect is easy
to compare. fig_apply_spec() returns ggplot2 components, which are added
to the plot with + while it is still editable.

Run the example setup

``` r

library(ggplot2)

base_plot <- ggplot(
  mpg,
  aes(displ, hwy, colour = drv, shape = drv)
) +
  geom_point(alpha = 0.75, size = 2) +
  labs(
    title = "Fuel economy by drive type",
    x = "Engine displacement (litres)",
    y = "Highway fuel economy",
    colour = "Drive type",
    shape = "Drive type"
  )

manual_colours <- c(
  "4" = "#375A7F",
  "f" = "#2A9D8F",
  "r" = "#C44E52"
)
manual_shapes <- c("4" = 15, "f" = 17, "r" = 18)

style_register(
  "research_report",
  theme_minimal() +
    theme(
      legend.position = "bottom",
      panel.grid.minor = element_blank()
    ),
  description = "Minimal grid with the legend below the figure"
)

report_spec <- list(
  name = "Research report",
  font_min_pt = 10,
  min_line_pt = 0.75,
  print_greyscale = TRUE
)
```

[TABLE]

### `fig_preview()`

Preview a figure at its intended output size

A preview opens at the physical size the finished figure will occupy.
This lets you judge text, symbols and detail at their intended size
while the plot is still editable.

Run the example setup

``` r

library(ggplot2)

p <- ggplot(mpg, aes(displ, hwy, colour = drv, shape = drv)) +
  geom_point(alpha = 0.75, size = 2) +
  scale_colour_manual(values = c(
    "4" = "#375A7F",
    "f" = "#2A9D8F",
    "r" = "#C44E52"
  )) +
  labs(
    title = "Fuel economy by drive type",
    x = "Engine displacement (litres)",
    y = "Highway fuel economy",
    colour = "Drive type",
    shape = "Drive type"
  ) +
  theme_minimal()

report_spec <- list(
  name = "Research report",
  columns = list(full = 160)
)
```

[TABLE]

## Size and align figures

### `fig_panel_size()`

Set exact dimensions for every data panel

Set the physical size of the data panel and let figspec calculate the
outer image around it. For a faceted plot or a multi-plot composition,
the requested dimensions apply to every panel.

Run the example setup

``` r

library(ggplot2)

p <- ggplot(mpg, aes(displ, hwy, colour = drv, shape = drv)) +
  geom_point(alpha = 0.75, size = 2) +
  scale_colour_manual(values = c(
    "4" = "#375A7F",
    "f" = "#2A9D8F",
    "r" = "#C44E52"
  )) +
  labs(
    title = "Fuel economy by drive type",
    x = "Engine displacement (litres)",
    y = "Highway fuel economy",
    colour = "Drive type",
    shape = "Drive type"
  ) +
  theme_minimal()

faceted <- p +
  facet_wrap(~drv, nrow = 1) +
  guides(colour = "none", shape = "none")
```

[TABLE]

### `fig_panel_width()`

Find one panel width that fits every figure

Find the widest data panel that every figure in a set can use without
exceeding the available canvas width. Figures with longer labels or
larger legends receive more surrounding space while their data panels
remain the same width.

Run the example setup

``` r

library(ggplot2)

base_plot <- ggplot(mpg, aes(displ, hwy, colour = drv, shape = drv)) +
  geom_point(alpha = 0.75, size = 2) +
  scale_colour_manual(values = c(
    "4" = "#375A7F",
    "f" = "#2A9D8F",
    "r" = "#C44E52"
  )) +
  labs(
    x = "Engine displacement (litres)",
    y = "Highway fuel economy",
    colour = "Drive type",
    shape = "Drive type"
  ) +
  theme_minimal()

figs <- list(
  numeric_labels = base_plot,
  labels_with_units = base_plot +
    scale_y_continuous(
      labels = function(x) paste(x, "miles per gallon")
    )
)

report_spec <- list(
  name = "Research report",
  columns = list(full = 150),
  formats = "png"
)
```

[TABLE]

## Apply and reuse visual standards

### `theme_spec()`

Apply typography requirements and a visual style

Apply the type sizes and other theme-level requirements recorded in a
specification while retaining control over the figure’s overall visual
style. The specification may belong to a publication, project or
organisation.

Run the example setup

``` r

library(ggplot2)

base_plot <- ggplot(mpg, aes(displ, hwy, colour = drv, shape = drv)) +
  geom_point(alpha = 0.75, size = 2) +
  scale_colour_manual(values = c(
    "4" = "#375A7F",
    "f" = "#2A9D8F",
    "r" = "#C44E52"
  )) +
  labs(
    title = "Fuel economy by drive type",
    subtitle = "All 234 vehicles in ggplot2::mpg",
    x = "Engine displacement (litres)",
    y = "Highway fuel economy",
    colour = "Drive type",
    shape = "Drive type",
    caption = "Source: ggplot2::mpg"
  )

style_register(
  "research_report",
  theme_minimal() +
    theme(
      legend.position = "bottom",
      panel.grid.minor = element_blank(),
      axis.text = element_text(size = 6)
    ),
  description = "Project report style"
)

report_spec <- list(
  name = "Research report",
  font_min_pt = 10,
  font_max_pt = 14
)
```

[TABLE]

### `style_register()`

Register a reusable visual style

Give a reusable name to the visual choices shared by a project, team or
organisation. The registered style is available for the rest of the R
session and can be applied alongside any publication or project
specification.

Run the example setup

``` r

library(ggplot2)

p <- ggplot(mpg, aes(displ, hwy, colour = drv, shape = drv)) +
  geom_point(alpha = 0.75, size = 2) +
  scale_colour_manual(values = c(
    "4" = "#375A7F",
    "f" = "#2A9D8F",
    "r" = "#C44E52"
  )) +
  labs(
    title = "Fuel economy by drive type",
    x = "Engine displacement (litres)",
    y = "Highway fuel economy",
    colour = "Drive type",
    shape = "Drive type"
  )

report_spec <- list(
  name = "Research report",
  font_min_pt = 9,
  font_max_pt = 14
)
```

[TABLE]

### `style_list()`

List the visual styles available in this session

View the reusable visual styles currently available in the R session.
The returned table helps you find the name to pass to theme_spec() or
fig_apply_spec() and records what each style is intended for.

*This function has no arguments.*

Run the example setup

``` r

library(ggplot2)

style_register(
  "research_report",
  theme_minimal() +
    theme(legend.position = "bottom"),
  description = "Figures for research reports"
)

style_register(
  "presentation",
  theme_classic() +
    theme(plot.title = element_text(face = "bold")),
  description = "Figures for presentations"
)
```

See how to use it

Call style_list() without any arguments. It returns one row for each
style registered in the current session.

``` r
available_styles <- style_list()
available_styles
```

**Result:** The table lists research_report and presentation together
with their descriptions.

### `style_remove()`

Remove a visual style from the current session

Remove a visual style that is no longer needed in the current R session.
Other registered styles remain available, and any RDS file previously
used to save the styles is left unchanged.

Run the example setup

``` r

library(ggplot2)

style_register(
  "research_report",
  theme_minimal(),
  description = "Figures for research reports"
)

style_register(
  "presentation",
  theme_classic(),
  description = "Figures for presentations"
)
```

[TABLE]

### `style_save()`

Save visual styles for reuse

Save the visual styles registered in the current R session when you want
to reuse them later. The resulting RDS file can be loaded from a project
setup script or another session you control.

Run the example setup

``` r

library(ggplot2)

style_register(
  "research_report",
  theme_minimal() +
    theme(legend.position = "bottom"),
  description = "Figures for research reports"
)

style_file <- tempfile(fileext = ".rds")
```

[TABLE]

### `style_load()`

Load saved visual styles

Restore visual styles saved in an earlier session. Loaded styles are
added to those already registered, allowing a project or organisation to
keep a consistent figure style without recreating it by hand.

Run the example setup

``` r

library(ggplot2)

style_register(
  "research_report",
  theme_minimal(),
  description = "Figures for research reports"
)
style_file <- tempfile(fileext = ".rds")
style_save(style_file)
style_remove("research_report")

style_register(
  "dynamic_style",
  function() theme_minimal() +
    theme(legend.position = getOption(
      "figspec.legend.position",
      "bottom"
    )),
  description = "Style that reads a project option"
)
function_file <- tempfile(fileext = ".rds")
style_save(function_file)
style_remove("dynamic_style")
```

[TABLE]

### `fig_tag_panels()`

Add and format labels for every panel

Add clear, consistent labels to faceted plots and multi-plot
compositions. figspec can follow a recorded publication requirement or
use a label style chosen for a report, presentation or other project.

Run the example setup

``` r

library(ggplot2)

base_plot <- ggplot(mpg, aes(displ, hwy, colour = drv, shape = drv)) +
  geom_point(alpha = 0.75, size = 2) +
  scale_colour_manual(values = c(
    "4" = "#375A7F",
    "f" = "#2A9D8F",
    "r" = "#C44E52"
  )) +
  labs(
    x = "Engine displacement (litres)",
    y = "Highway fuel economy",
    colour = "Drive type",
    shape = "Drive type"
  ) +
  theme_minimal()

faceted <- base_plot +
  facet_wrap(~drv, nrow = 1) +
  guides(colour = "none", shape = "none")

city_plot <- ggplot(mpg, aes(displ, cty, colour = drv, shape = drv)) +
  geom_point(alpha = 0.75, size = 2) +
  labs(
    title = "City driving",
    x = "Engine displacement (litres)",
    y = "City fuel economy"
  ) +
  theme_minimal() +
  theme(legend.position = "none")

highway_plot <- base_plot +
  labs(title = "Highway driving") +
  theme(legend.position = "none")

composition <- patchwork::wrap_plots(
  city_plot,
  highway_plot,
  ncol = 2
)

report_spec <- list(
  name = "Research report",
  panel_labels = "numbers"
)
```

[TABLE]

### `spec_linewidth()`

Use line widths that meet a specification

Convert a minimum line weight recorded in points into the value expected
by ggplot2’s linewidth argument. This prevents a direct point value from
being interpreted on the wrong scale and producing lines that are too
thick or too thin.

Run the example setup

``` r

library(ggplot2)

line_plot <- ggplot(economics, aes(date, unemploy)) +
  labs(
    x = NULL,
    y = "Number of unemployed people",
    caption = "Source: ggplot2::economics"
  ) +
  theme_spec("frontiers", base = theme_minimal())

report_spec <- list(
  name = "Annual report",
  min_line_pt = 1.25
)
```

[TABLE]

## Colour and visual distinction

### `colour_safety_check()`

Check whether a figure’s colours remain distinguishable

Examine the colours used to represent data before exporting the figure.
figspec checks any colour rules in the selected specification and also
reports whether the colours remain distinct in greyscale and under
common forms of colour-vision deficiency. When colour is not the only
visual cue, it records that as well.

Run the example setup

``` r

library(ggplot2)

unsafe_plot <- ggplot(
  mpg,
  aes(displ, hwy, colour = drv)
) +
  geom_point(size = 2, alpha = 0.8) +
  scale_colour_manual(values = c(
    "4" = "#D62728",
    "f" = "#2CA02C",
    "r" = "#1F77B4"
  )) +
  labs(
    title = "Colour is the only cue",
    x = "Engine displacement (litres)",
    y = "Highway fuel economy",
    colour = "Drive type"
  ) +
  theme_minimal()

safer_plot <- ggplot(
  mpg,
  aes(displ, hwy, colour = drv, shape = drv)
) +
  geom_point(size = 2, alpha = 0.8) +
  scale_colour_manual(values = c(
    "4" = "#000000",
    "f" = "#0072B2",
    "r" = "#E69F00"
  )) +
  scale_shape_manual(values = c(
    "4" = 16,
    "f" = 17,
    "r" = 15
  )) +
  labs(
    title = "Colour and shape identify each group",
    x = "Engine displacement (litres)",
    y = "Highway fuel economy",
    colour = "Drive type",
    shape = "Drive type"
  ) +
  theme_minimal()

report_spec <- list(
  name = "Research report",
  avoid_colour_pairs = list(c("red", "green")),
  print_greyscale = TRUE
)
```

[TABLE]

### `color_safety_check()`

Check whether a figure’s colours remain distinguishable

The same function as
[`colour_safety_check()`](https://dansemakula.github.io/figspec/reference/colour_safety_check.md),
under the other spelling. Its options are identical.

| Option | What it does |
|:---|:---|
| `plot` | A ggplot object. Use the editable plot rather than an exported file so that figspec can inspect the colours actually mapped to data. |
| `spec` | The specification to check against. Supply a registry id, a figspec_spec, or a named list containing the colour and reproduction requirements for a publication, project or organisation. |
| `threshold` | The smallest perceptual difference that figspec will accept between two colours, measured as CIE Delta-E 2000. The default is 10; raising it makes the distinction test stricter. This setting controls the accessibility analysis; pass-or-fail publication results continue to use the rules recorded in the selected specification. |

### `figspec_palettes()`

List the colour palettes included with figspec

See which palettes figspec provides before choosing one for a plot. The
catalogue distinguishes palettes for separate categories from palettes
for ordered values, explains where each works best and records its
source. These are optional design tools, kept separate from publication
requirements and their pass-or-fail checks.

*This function has no arguments.*

Run the example setup

``` r

library(ggplot2)
```

See how to use it

Print the catalogue to compare the palettes, then draw their colours as
swatches. Eight colours are shown for the fixed Okabe-Ito palette and
for each sequential ramp so that their different structures are visible.

``` r
available_palettes <- figspec_palettes()
available_palettes

swatches <- do.call(
  rbind,
  lapply(seq_len(nrow(available_palettes)), function(i) {
    palette_id <- available_palettes$id[[i]]
    data.frame(
      palette = available_palettes$name[[i]],
      position = seq_len(8),
      colour = figspec_palette(palette_id, 8)
    )
  })
)

ggplot(swatches, aes(position, 1, fill = colour)) +
  geom_tile(width = 0.96, height = 0.8) +
  facet_wrap(~palette, ncol = 1) +
  scale_fill_identity() +
  scale_x_continuous(breaks = seq_len(8)) +
  coord_cartesian(expand = FALSE) +
  labs(x = "Colour position") +
  theme_void() +
  theme(
    strip.text = element_text(size = 11, face = "bold"),
    axis.title.x = element_text(size = 9),
    axis.text.x = element_text(size = 8),
    panel.spacing.y = grid::unit(4, "mm")
  )
```

**Result:** The catalogue lists one fixed eight-colour qualitative
palette and two sequential palettes that can generate any requested
number of colours; the swatches show the colours and lightness
progression in each.

### `figspec_palette()`

Get colours from a figspec palette

Retrieve the colours from one of figspec’s palettes as hexadecimal
values. The returned vector can be used in a ggplot2 manual scale, a
base R plot or any other function that accepts R colours.

Run the example setup

``` r

library(ggplot2)

mpg_six_classes <- subset(
  mpg,
  class != "2seater"
)

base_plot <- ggplot(
  mpg_six_classes,
  aes(displ, hwy)
) +
  labs(
    x = "Engine displacement (litres)",
    y = "Highway fuel economy"
  ) +
  theme_minimal()
```

[TABLE]

### `scale_colour_figspec()`

Apply a figspec palette to point and line colours

Add a figspec palette directly to the colour scale of a ggplot. This
affects the colour of points, lines and outlines; it does not control
the interiors of bars or other filled shapes.

Run the example setup

``` r

library(ggplot2)

mpg_six_classes <- subset(
  mpg,
  class != "2seater"
)

colour_base <- ggplot(
  mpg_six_classes,
  aes(displ, hwy)
) +
  labs(
    x = "Engine displacement (litres)",
    y = "Highway fuel economy"
  ) +
  theme_minimal()
```

[TABLE]

### `scale_color_figspec()`

Apply a figspec palette to point and line colours

The same function as
[`scale_colour_figspec()`](https://dansemakula.github.io/figspec/reference/scale_colour_figspec.md),
under the other spelling. Its options are identical.

| Option | What it does |
|:---|:---|
| `palette` | The id of the figspec palette to use. See figspec_palettes() for the available choices and their recommended uses. |
| `...` | Additional settings for the discrete scale, such as its legend title, labels, limits, missing-value colour or guide. These are passed to ggplot2::discrete_scale(). |

### `scale_fill_figspec()`

Apply a figspec palette to filled areas

Add a figspec palette to the fill scale of a ggplot. Use it for the
interiors of bars, boxes, areas and filled point shapes; use
scale_colour_figspec() for points, lines and outlines.

Run the example setup

``` r

library(ggplot2)

fill_base <- ggplot(
  mpg,
  aes(class, fill = drv)
) +
  geom_bar() +
  labs(
    x = "Vehicle class",
    y = "Number of models"
  ) +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = 35, hjust = 1))
```

[TABLE]

### `scale_shape_figspec()`

Apply distinct shapes to categorical points

Add a tested set of distinct point shapes to a ggplot. Shape can
reinforce colour so that groups remain identifiable when colours are
difficult to distinguish or the figure is reproduced in greyscale.

Run the example setup

``` r

library(ggplot2)

shape_base <- ggplot(
  mpg,
  aes(displ, hwy, shape = drv, fill = drv)
) +
  geom_point(
    size = 2.6,
    colour = "#243642",
    stroke = 0.8,
    alpha = 0.85
  ) +
  scale_fill_figspec("okabe_ito") +
  labs(
    x = "Engine displacement (litres)",
    y = "Highway fuel economy",
    shape = "Drive type",
    fill = "Drive type"
  ) +
  theme_minimal()
```

[TABLE]

### `figspec_shapes()`

Get a set of distinct point shapes

Retrieve distinct ggplot2 shape codes for a manual scale or another
plotting function. figspec supplies a short, deliberate set and reports
its capacity when more shapes are requested than readers can reliably
distinguish.

Run the example setup

``` r

library(ggplot2)

shape_plot <- function(shape_values, title) {
  ggplot(
    mpg,
    aes(displ, hwy, shape = drv, fill = drv)
  ) +
    geom_point(
      size = 2.6,
      colour = "#243642",
      stroke = 0.8,
      alpha = 0.85
    ) +
    scale_shape_manual(values = shape_values) +
    scale_fill_figspec("okabe_ito") +
    labs(
      title = title,
      x = "Engine displacement (litres)",
      y = "Highway fuel economy",
      shape = "Drive type",
      fill = "Drive type"
    ) +
    theme_minimal()
}
```

[TABLE]

### `figspec_linetypes()`

Get a set of distinct line types

Retrieve distinct line patterns for a manual scale. Adding line type to
colour gives readers a second way to follow each series when the figure
is reproduced in greyscale or two colours appear similar.

Run the example setup

``` r

library(ggplot2)

economic_series <- economics_long
number_of_series <- length(unique(economic_series$variable))

line_base <- ggplot(
  economic_series,
  aes(date, value01, group = variable)
) +
  labs(
    x = NULL,
    y = "Value, rescaled within each series",
    caption = "Source: ggplot2::economics_long"
  ) +
  theme_minimal() +
  theme(legend.position = "bottom")
```

[TABLE]

### `spec_style_palette()`

Retrieve a recorded house-style palette

Retrieve an optional palette recorded as part of a specification’s house
style. This may describe a publication, project or organisation. A
recorded palette records a visual preference and remains separate from
requirements. When none is recorded, the plotting system’s existing
colours stay in use.

Run the example setup

``` r

library(ggplot2)

report_spec <- list(
  name = "Annual research report",
  house_style = list(
    palette = c(
      "Four-wheel drive" = "#1D3557",
      "Front-wheel drive" = "#2A9D8F",
      "Rear-wheel drive" = "#E76F51"
    )
  )
)
```

[TABLE]

## Find and use specifications

### `spec_list()`

Browse available specification profiles

Browse the specification profiles available to figspec. Most bundled
profiles apply across a publisher’s journal portfolio, while others
record requirements for an individual journal or publication type, so
the table reaches substantially more publications than its row count
suggests.

Run the example setup

``` r

all_profiles <- spec_list()
```

[TABLE]

### `spec_get()`

Retrieve or create a specification

Retrieve a specification from figspec’s registry or create one from a
named list maintained by your project or organisation. The resulting
object works with the same building, exporting and verification
functions regardless of where its requirements came from.

Run the example setup

``` r

library(ggplot2)

project_requirements <- list(
  name = "Clinical research report",
  columns = list(single = 80, full = 160),
  dpi_min = 300,
  formats = c("png", "pdf"),
  font_min_pt = 9
)
```

[TABLE]

### `fig_width()`

Look up a figure width

Retrieve a figure width from a publication, project or organisational
specification. Using the recorded value keeps the figure’s dimensions
tied to the same specification used to build, export and verify it.

Run the example setup

``` r

library(ggplot2)

cell_press_spec <- spec_get("cell_press")
report_spec <- spec_get(list(
  name = "Clinical research report",
  columns = list(half = 80, full = 160),
  formats = "png",
  dpi_min = 300
))

width_plot <- ggplot(
  mpg,
  aes(displ, hwy, colour = drv, shape = drv)
) +
  geom_point(size = 2.2, alpha = 0.8) +
  labs(
    title = "Fuel economy by engine size",
    x = "Engine displacement (litres)",
    y = "Highway fuel economy",
    colour = "Drive layout",
    shape = "Drive layout"
  ) +
  fig_apply_spec(cell_press_spec, base_size = 10)
```

[TABLE]

### `fig_columns()`

List the available figure widths

See which named figure widths a specification provides before choosing
one for a plot. The names are not universal: some sources use single and
double, others add choices such as onehalf, triple, half or full.

Run the example setup

``` r

library(ggplot2)

cell_press_spec <- spec_get("cell_press")
report_spec <- spec_get(list(
  name = "Clinical research report",
  columns = list(half = 80, full = 160),
  formats = "png",
  dpi_min = 300
))

columns_plot <- ggplot(
  mpg,
  aes(displ, hwy, colour = drv, shape = drv)
) +
  geom_point(size = 2.2, alpha = 0.8) +
  labs(
    title = "Fuel economy by engine size",
    x = "Engine displacement (litres)",
    y = "Highway fuel economy",
    colour = "Drive layout",
    shape = "Drive layout"
  ) +
  fig_apply_spec(cell_press_spec, base_size = 10)
```

[TABLE]

### `spec_register()`

Register a publication specification for this session

Add a publication specification that is not bundled with figspec. The
new entry is available throughout the current R session and is marked as
user-supplied whenever the registry is listed.

Run the example setup

``` r

library(ggplot2)

registered_spec <- spec_register(
  id = "research_methods_review",
  name = "Research Methods Review",
  source_url = "internal:author-guidelines-v2",
  verified_on = Sys.Date(),
  requirements = list(
    columns = list(single = 85, full = 170),
    height_max_mm = 220,
    dpi_min = 300,
    formats = c("png", "pdf"),
    font_min_pt = 9,
    font_max_pt = 12,
    colour_mode = "RGB",
    max_file_mb = 20
  ),
  not_stated = c(
    "font_families", "min_line_pt", "max_line_pt",
    "avoid_colour_pairs", "print_greyscale"
  ),
  house_style = list(
    palette = c("#1B4965", "#CA6702", "#5C677D")
  ),
  publisher = "Example Research Society",
  disciplines = c("health", "statistics"),
  publication_stage = "all",
  notes = "Example requirements for demonstrating a user entry."
)
```

[TABLE]

### `spec_save()`

Save a specification for reuse

Save a publication, project or organisational specification in a YAML
file that figspec can load in later R sessions. figspec validates the
complete file before replacing anything, so a failed update leaves the
previous registry intact.

Run the example setup

``` r

reusable_spec <- list(
  name = "Research unit report",
  columns = list(full = 160),
  dpi_min = 300,
  formats = c("png", "pdf"),
  font_min_pt = 9,
  tables = list(
    formats = c("html", "docx"),
    font_min_pt = 9,
    header_bold = TRUE,
    vertical_rules = FALSE
  )
)

spec_output_dir <- tempfile("figspec-spec-save-")
dir.create(spec_output_dir)
```

[TABLE]

### `spec_load()`

Load specifications from a YAML registry

Load one or more reusable specifications from a YAML file maintained by
a publication, project or organisation. Loaded entries remain separate
from figspec’s bundled profiles and last for the current R session.

Run the example setup

``` r

library(ggplot2)

registry_file <- file.path(
  tempdir(),
  "research-unit-specifications.yml"
)

yaml::write_yaml(
  list(
    specifications = list(
      list(
        id = "research_unit_report",
        name = "Research Unit Report",
        publisher = "Example Research Unit",
        disciplines = c("health", "economics"),
        source_url = "internal:report-guide-v4",
        verified_on = as.character(Sys.Date()),
        requirements = list(
          columns = list(half = 80, full = 160),
          height_max_mm = 120,
          dpi_min = 300,
          formats = c("png", "pdf"),
          font_min_pt = 9,
          font_max_pt = 12,
          colour_mode = "RGB",
          max_file_mb = 20
        ),
        not_stated = c(
          "font_families", "min_line_pt", "max_line_pt",
          "avoid_colour_pairs", "print_greyscale"
        ),
        house_style = list(
          palette = c("#1B4965", "#CA6702", "#5C677D")
        )
      )
    )
  ),
  registry_file
)
```

[TABLE]

## Check collections and publication assets

### `submission_check()`

Review figures and tables together

Review figures and tables in one operation. A concise summary identifies
each item and shows whether it passes, fails, needs more information or
was inspected without a specification. The complete report for every
item remains available for closer inspection.

Run the example setup

``` r

library(ggplot2)

submission_spec <- spec_get(list(
  name = "Research report figure set",
  columns = list(single = 85, double = 170),
  height_max_mm = 220,
  dpi_min = 300,
  formats = "png",
  font_min_pt = 9,
  font_max_pt = 12,
  colour_mode = "RGB",
  max_file_mb = 20,
  not_stated = c(
    "font_families", "min_line_pt", "max_line_pt",
    "avoid_colour_pairs", "print_greyscale"
  )
))

vehicles_plot <- ggplot(
  mpg,
  aes(displ, hwy, colour = drv, shape = drv)
) +
  geom_point(size = 2.2, alpha = 0.8) +
  labs(
    title = "Vehicle fuel economy",
    x = "Engine displacement (litres)",
    y = "Highway fuel economy",
    colour = "Drive layout",
    shape = "Drive layout"
  ) +
  fig_apply_spec(submission_spec, base_size = 10)

economy_plot <- ggplot(
  economics,
  aes(date, unemploy)
) +
  geom_line(colour = "#1B4965", linewidth = 0.8) +
  labs(
    title = "Unemployment over time",
    x = NULL,
    y = "People unemployed (thousands)"
  ) +
  fig_apply_spec(
    submission_spec,
    colour = FALSE,
    shapes = FALSE,
    base_size = 10
  )

diamonds_plot <- ggplot(
  diamonds,
  aes(carat, fill = cut)
) +
  geom_histogram(binwidth = 0.1, position = "identity", alpha = 0.7) +
  labs(
    title = "Distribution of diamond size",
    x = "Carat",
    y = "Number of diamonds",
    fill = "Cut"
  ) +
  fig_apply_spec(submission_spec, base_size = 10)

figures <- list(
  vehicles = vehicles_plot,
  economy = economy_plot,
  diamonds = diamonds_plot
)
column_map <- c(
  vehicles = "single",
  economy = "double",
  diamonds = "double"
)
file_column_map <- setNames(
  unname(column_map),
  paste0(names(column_map), ".png")
)

example_root <- tempfile("figspec-submission-")
dir.create(example_root)

save_figure_set <- function(directory) {
  dir.create(directory, recursive = TRUE, showWarnings = FALSE)
  paths <- vapply(names(figures), function(figure_name) {
    fig_save(
      file.path(directory, paste0(figure_name, ".png")),
      figures[[figure_name]],
      spec = submission_spec,
      column = unname(column_map[[figure_name]]),
      height = if (figure_name == "vehicles") 75 else 95,
      dpi = 300,
      check = FALSE
    )
  }, character(1))
  unname(paths)
}
```

[TABLE]

### `submission_detail()`

Open the full report for one submission item

A collection review is intentionally brief. Open one figure or table’s
full report when you need to see why it failed, which values were
measured or which requirements could not be assessed. This example
checks two plots made from all 234 rows of ggplot2’s mpg data. The
second plot deliberately uses text below the project’s minimum so there
is a real problem to diagnose.

Run the example setup

``` r

library(ggplot2)

detail_spec <- spec_get(list(
  name = "Research report",
  columns = list(single = 85),
  dpi_min = 300,
  formats = "png",
  font_min_pt = 9,
  font_max_pt = 12,
  colour_mode = "RGB",
  not_stated = c(
    "font_families", "min_line_pt", "max_line_pt",
    "avoid_colour_pairs", "print_greyscale"
  )
))

ready_plot <- ggplot(
  mpg,
  aes(displ, hwy, colour = drv, shape = drv)
) +
  geom_point(size = 2.2, alpha = 0.8) +
  labs(
    title = "Vehicle fuel economy",
    x = "Engine displacement (litres)",
    y = "Highway fuel economy",
    colour = "Drive layout",
    shape = "Drive layout"
  ) +
  fig_apply_spec(detail_spec, base_size = 10)

small_text_plot <- ready_plot +
  theme(
    text = element_text(size = 7),
    axis.text = element_text(size = 7),
    plot.title = element_text(size = 7)
  )

detail_review <- submission_check(
  list(
    ready = ready_plot,
    text_too_small = small_text_plot
  ),
  spec = detail_spec,
  column = "single",
  dpi = 300
)
```

[TABLE]

### `fig_suggest_art_type()`

Choose a resolution category for a figure

Resolution requirements depend on the kind of artwork being exported.
Run the setup once, then use these examples to see how figspec
classifies a real plot and how a publication or project specification
supplies the thresholds needed to make the final choice.

Run the example setup

``` r

library(ggplot2)

colour_plot <- ggplot(
  mpg,
  aes(displ, hwy, colour = drv, shape = drv)
) +
  geom_point(size = 2.2, alpha = 0.8) +
  scale_colour_figspec("okabe_ito") +
  labs(
    x = "Engine displacement (litres)",
    y = "Highway fuel economy",
    colour = "Drive layout",
    shape = "Drive layout"
  ) +
  theme_minimal()

resolution_spec <- list(
  name = "Research report",
  dpi_min = 300,
  dpi_bw = 600,
  dpi_line_art = 1000,
  dpi_combination = 600
)
```

[TABLE]

### `fig_refit()`

Re-export a figure set for a new specification

Use this function when a complete set of editable plots must be prepared
for a new destination. The examples use 234 vehicle observations and 574
monthly economic observations, export real files and then inspect the
resulting submission report. The destination can be a journal, report,
organisation or any other recorded specification.

Run the example setup

``` r

library(ggplot2)

vehicle_plot <- ggplot(
  mpg,
  aes(displ, hwy, colour = drv, shape = drv)
) +
  geom_point(size = 2.2, alpha = 0.8) +
  scale_colour_figspec("okabe_ito") +
  labs(
    title = "Vehicle fuel economy",
    x = "Engine displacement (litres)",
    y = "Highway fuel economy",
    colour = "Drive layout",
    shape = "Drive layout"
  ) +
  theme_minimal(base_size = 14)

economy_plot <- ggplot(
  economics,
  aes(date, unemploy)
) +
  geom_line(colour = "#1B4965", linewidth = 0.8) +
  labs(
    title = "Unemployment over time",
    x = NULL,
    y = "People unemployed (thousands)"
  ) +
  theme_minimal(base_size = 14)

refit_plots <- list(
  vehicles = vehicle_plot,
  economy = economy_plot
)

handoff_spec <- list(
  name = "Research report",
  columns = list(compact = 85, full = 170),
  dpi_min = 300,
  formats = c("png", "tiff"),
  font_min_pt = 9,
  font_max_pt = 12,
  colour_mode = "RGB",
  not_stated = c(
    "font_families", "min_line_pt", "max_line_pt",
    "avoid_colour_pairs", "print_greyscale"
  )
)

refit_root <- tempfile("figspec-refit-")
dir.create(refit_root)
```

[TABLE]

### `media_spec()`

Look up supplementary media requirements

Video and audio use their own technical requirements. This lookup shows
the accepted containers, frame limits, codec, bit rate and file-size
rules recorded for a publication or project.

Run the example setup

``` r

project_media_spec <- list(
  name = "Research media handoff",
  source_url = "internal:media-guide",
  verified_on = as.character(Sys.Date()),
  media = list(
    video_formats = "mp4",
    video_codec = "h264",
    frame_max = list(width = 1280, height = 720),
    max_file_mb = 5
  )
)
```

[TABLE]

### `media_check()`

Verify a supplementary media file

These examples create a real 640 × 360 pixel MP4, read it back from disk
and compare its saved properties with a media specification. ffprobe
adds codec and bit-rate inspection when it is installed. The report
marks any property without reliable file evidence as unknown and ready
for review.

Run the example setup

``` r

ffmpeg <- Sys.which("ffmpeg")
if (!nzchar(ffmpeg)) {
  stop("This example requires FFmpeg.")
}

media_file <- tempfile(fileext = ".mp4")
ffmpeg_output <- system2(
  ffmpeg,
  c(
    "-loglevel", "error", "-y",
    "-f", "lavfi", "-i",
    "color=c=0x1B4965:s=640x360:d=0.5",
    "-c:v", "libx264",
    "-pix_fmt", "yuv420p",
    media_file
  ),
  stdout = TRUE,
  stderr = TRUE
)
if (!is.null(attr(ffmpeg_output, "status"))) {
  stop("FFmpeg could not create the example video.")
}

video_spec <- list(
  name = "Research media handoff",
  source_url = "internal:media-guide",
  verified_on = as.character(Sys.Date()),
  media = list(
    video_formats = "mp4",
    video_codec = "h264",
    frame_max = list(width = 1280, height = 720),
    max_file_mb = 5
  )
)
```

[TABLE]

### `graphical_abstract_spec()`

Look up graphical abstract requirements

A graphical abstract may have a different canvas, resolution, format and
text limit from the figures inside the article or report. This function
retrieves those separate requirements without mixing them into an
ordinary figure check.

Run the example setup

``` r

project_abstract_spec <- list(
  name = "Research summary card",
  source_url = "internal:summary-card-guide",
  verified_on = as.character(Sys.Date()),
  graphical_abstract = list(
    width_mm = 120,
    height_mm = 70,
    dpi_min = 300,
    formats = "png",
    max_characters = 180
  )
)
```

[TABLE]

## Build, export and check tables

### `table_spec()`

Look up table requirements

Retrieve the table requirements recorded for a publication, project or
organisation. Measurable fields can be passed directly to the table
build, export and check workflow; editorial instructions remain visible
for review with the same source and review date.

Run the example setup

``` r

custom_table_spec <- list(
  name = "Annual research report",
  source_url = "internal:report-style-guide",
  verified_on = as.character(Sys.Date()),
  tables = list(
    orientation = "portrait",
    title_style = "Short title above the table",
    notes = "Define abbreviations below the table"
  )
)
```

[TABLE]

### `table_apply_spec()`

Apply a specification to a table

Apply measurable table requirements while the table is still editable.
Data frames and matrices become gt tables; gt, flextable, kableExtra and
grid tables remain in their own table systems.

Run the example setup

``` r

table_project_spec <- list(
  name = "Research report",
  source_url = "internal:report-table-guide",
  verified_on = as.character(Sys.Date()),
  tables = list(
    formats = c("html", "docx"),
    orientation = "portrait",
    font_families = "Arial",
    font_min_pt = 9,
    header_bold = TRUE,
    vertical_rules = FALSE,
    horizontal_rules = "minimal",
    repeat_header = TRUE
  )
)
vehicle_table <- ggplot2::mpg[1:12, c(
  "manufacturer", "model", "displ", "year", "hwy"
)]
```

[TABLE]

### `table_save()`

Export and verify a table

Export a table through its own table system, reopen the completed file
and keep the live-object and file checks together. A temporary file is
promoted only after the renderer succeeds and, when checking is enabled,
the file is confirmed to be structurally valid.

Run the example setup

``` r

table_save_spec <- list(
  name = "Research report",
  source_url = "internal:report-table-guide",
  verified_on = as.character(Sys.Date()),
  tables = list(
    formats = "html",
    font_min_pt = 9,
    header_bold = TRUE,
    vertical_rules = FALSE
  )
)
table_for_export <- ggplot2::mpg[1:20, c(
  "manufacturer", "model", "displ", "hwy"
)]
table_output_dir <- tempfile("figspec-table-options-")
dir.create(table_output_dir)
```

[TABLE]

### `table_check()`

Verify a table against a specification

Check an editable R table or a completed table file. The two inputs
retain different evidence, so table_save combines them when both are
available.

Run the example setup

``` r

table_check_spec <- list(
  name = "Research report",
  source_url = "internal:report-table-guide",
  verified_on = as.character(Sys.Date()),
  tables = list(
    formats = "html",
    font_min_pt = 9,
    header_bold = TRUE,
    vertical_rules = FALSE
  )
)
table_check_data <- ggplot2::mpg[1:10, c(
  "manufacturer", "model", "displ", "hwy"
)]
```

[TABLE]

## R Markdown and Quarto

### `figspec_knitr_options()`

Create figure settings for R Markdown or Quarto

Figures created inside R Markdown or Quarto need the same deliberate
size and resolution as figures saved from an R script. These examples
translate a specification into the four settings knitr uses: figure
width, figure height, resolution and graphics device.

Run the example setup

``` r

report_chunk_spec <- list(
  name = "Research report",
  columns = list(compact = 85, full = 170),
  formats = "png",
  dpi_min = 300,
  dpi_line_art = 600
)

slide_chunk_spec <- list(
  name = "Presentation slide",
  formats = "png",
  dpi_min = 192
)
```

[TABLE]

### `figspec_knitr_setup()`

Apply figure settings to R Markdown or Quarto

Use this function once in a document’s setup chunk to make the chosen
figure settings the defaults for later chunks. Each example applies the
settings and then reads them back from knitr so the effect is visible.

Run the example setup

``` r

if (!requireNamespace("knitr", quietly = TRUE)) {
  stop("This example requires knitr.")
}

document_spec <- list(
  name = "Research report",
  columns = list(compact = 85, full = 170),
  formats = "png",
  dpi_min = 300,
  dpi_line_art = 600
)

presentation_spec <- list(
  name = "Presentation slide",
  formats = "png",
  dpi_min = 192
)
```

[TABLE]

## Maintain trusted registry data

### `registry_status()`

Review registry coverage and update dates

Use this summary to see when every specification was last checked and
how much of its field list has been reviewed. It distinguishes a
requirement recorded from the source, a field reviewed but not stated,
and a field that still needs review.

Run the example setup

``` r

today <- Sys.Date()
```

[TABLE]

### `registry_stale_entries()`

Find specifications due for review

Use this focused check when you want the ids of specifications whose
source pages are due to be reviewed again. It reports the entries and
returns their ids so they can be passed into an updating workflow.

Run the example setup

``` r

today <- Sys.Date()
```

[TABLE]

### `registry_check_sources()`

Check whether registry source pages still respond

A stored source address can stop working even when the registry file
itself has not changed. This function asks the selected pages whether
they still respond and separates missing pages from temporary failures,
redirects and sites that block automated requests. It requires an
internet connection.

Run the example setup

``` r

# No setup is required. The examples make live network requests.
```

[TABLE]

### `registry_entry_template()`

Create a registry-entry template

Start a new specification from a complete YAML template containing every
registry field. The template separates requirements that are stated,
requirements confirmed as absent and fields that have not yet been
reviewed.

Run the example setup

``` r

# No setup is required.
```

[TABLE]

### `registry_validate_file()`

Check a registry file before loading it

Validate a registry file before loading or contributing it. The check
reads the actual YAML and reports all detected problems together,
including missing provenance, invalid dates, unsupported fields and
impossible numeric values.

Run the example setup

``` r

valid_registry_file <- tempfile(fileext = ".yml")
writeLines(
  c(
    "journals:",
    "- id: research_report",
    "  name: Research report",
    "  source_url: internal:report-guide",
    paste0("  verified_on: '", Sys.Date(), "'"),
    "  requirements:",
    "    columns: {compact: 85, full: 170}",
    "    dpi_min: 300",
    "    formats: [png]"
  ),
  valid_registry_file
)

invalid_registry_file <- tempfile(fileext = ".yml")
writeLines(
  c(
    "journals:",
    "- id: Invalid ID",
    "  name: Broken example",
    "  verified_on: yesterday",
    "  requirements:",
    "    dpi_min: -10",
    "    invented_field: true"
  ),
  invalid_registry_file
)
```

[TABLE]
