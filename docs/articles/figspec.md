# Getting started with figspec

[`library`](https://rdrr.io/r/base/library.html)`(`[`ggplot2`](https://ggplot2.tidyverse.org)`)`` `[`library`](https://rdrr.io/r/base/library.html)`(`[`figspec`](https://dansemakula.github.io/figspec/)`)`

## Choose the requirements for your figure

A clear and accurate figure may still need changes before it can be
submitted, published or placed in a report. It may be too wide for the
page, have too few pixels for print, use an unsupported file format, or
contain text that will be unreadable at its final size. Figures saved at
the same width can also look uneven when their plotting areas do not
line up.

Start by giving figspec the requirements for the finished figure. You
can do this in three ways:

- **Use a publication profile.** Name a journal or publisher in the
  registry. figspec loads its recorded requirements and shows where they
  came from and when they were last verified.
- **Write your own requirements.** Describe the needs of a report,
  presentation, thesis, organisation or production workflow in a named R
  list.
- **Set the dimensions directly.** Give the exact image or
  plotting-panel size when size is the only constraint.

Whichever route you take, the workflow is the same: define the
requirements, build the plot, export it and check the finished file.

### Using your own requirements

For your own project, write the requirements in a named R list. Here, a
quarterly report accepts PNG or PDF figures that are 160 mm wide, at
least 300 dpi, with text no smaller than 9 pt and lines no thinner than
0.5 pt:

`report_spec`` ``<-`` `[`list`](https://rdrr.io/r/base/list.html)`(`` `` name ``=`` ``"Quarterly outcomes report"``,`` `` columns ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(``full ``=`` ``160``)``,`` `` formats ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"png"``, ``"pdf"``)``,`` `` dpi_min ``=`` ``300``,`` `` font_min_pt ``=`` ``9``,`` `` min_line_pt ``=`` ``0.5`` ``)`

Use `report_spec` wherever a function asks for a journal or
specification, including
[`fig_apply_spec()`](https://dansemakula.github.io/figspec/reference/fig_apply_spec.md),
[`theme_spec()`](https://dansemakula.github.io/figspec/reference/theme_spec.md),
[`fig_check()`](https://dansemakula.github.io/figspec/reference/fig_check.md)
and
[`fig_save()`](https://dansemakula.github.io/figspec/reference/fig_save.md).
Those functions accept either a registry name or your own list, so no
journal is required.

A **specification** lists the requirements the finished figure must
meet. A **house style** sets visual choices, such as a reusable ggplot2
theme. They can be used together, but they are kept separate so a
preferred appearance is not mistaken for a requirement. Use
[`style_register()`](https://dansemakula.github.io/figspec/reference/style_register.md)
to save and reuse that appearance.

For exact panel sizing without any specification, see the [panel-sizing
guide](https://dansemakula.github.io/figspec/articles/panels.md). It
demonstrates why equal image widths do not guarantee equal plotting
areas and how to make a set align.

## Using a journal or publisher profile

Journals and publishers make a useful example because they give exact
measurements and do not all use the same ones. Cell Press asks for
widths of 85, 114 or 174 mm and type between 6 and 8 pt. Science uses
widths of 57, 121 or 184 mm and type no smaller than 5 pt. PNAS caps
type at 12 pt, while Nature and the Royal Society use different
panel-label styles.

Each publisher is designing a different page, so the differences are
reasonable. The difficulty is that a normal ggplot gives no warning when
a figure breaks one of these rules. The problem may only be discovered
after submission or during production.

## Apply the requirements while you build

It is easier to make changes while the plot is still editable. Add a
publication profile much like a ggplot2 scale:

`fitted`` ``<-`` `[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``ggplot2``::`[`mpg`](https://ggplot2.tidyverse.org/reference/mpg.html)`,`` `` `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``displ``, ``hwy``, colour ``=`` `[`factor`](https://rdrr.io/r/base/factor.html)`(``cyl``)``, shape ``=`` `[`factor`](https://rdrr.io/r/base/factor.html)`(``cyl``)``)``)`` ``+`` `` `[`geom_point`](https://ggplot2.tidyverse.org/reference/geom_point.html)`(``)`` ``+`` `` `[`labs`](https://ggplot2.tidyverse.org/reference/labs.html)`(``title ``=`` ``"Engine size and highway fuel economy"``,`` `` x ``=`` ``"Engine displacement (litres)"``, y ``=`` ``"Highway miles per gallon"``,`` `` colour ``=`` ``"Cylinders"``, shape ``=`` ``"Cylinders"``)`` ``+`` `` `[`fig_apply_spec`](https://dansemakula.github.io/figspec/reference/fig_apply_spec.md)`(``"cell_press"``)`` `` ``report`` ``<-`` `[`fig_check`](https://dansemakula.github.io/figspec/reference/fig_check.md)`(``fitted``, ``"cell_press"``, column ``=`` ``"single"``)`` ``knitr``::`[`kable`](https://rdrr.io/pkg/knitr/man/kable.html)`(``report``[``, `[`c`](https://rdrr.io/r/base/c.html)`(``"check"``, ``"actual"``, ``"status"``)``]``, row.names ``=`` ``FALSE``)`

| check | actual | status |
|:---|:---|:---|
| Width | 85 mm | pass |
| Height | could not determine | unknown |
| Resolution | could not determine | unknown |
| File format | could not determine | unknown |
| Type size | smallest 6 pt, largest 7.5 pt | pass |
| Font | could not determine | unknown |
| Line width | could not determine | unknown |
| Colour mode | RGB | pass |
| Colour pairs | no red/green pairing | pass |
| Greyscale | 1 pair(s) merge in greyscale: \#56B4E9/#E69F00 | unspecified |
| Colour vision | separable under deuteranopia, protanopia and tritanopia | unspecified |
| Redundant coding | colours merge in greyscale but 4 shapes still separate the series | unspecified |
| Text case | 5 label(s), not checked | unspecified |
| File size | could not determine | unknown |

[`fig_apply_spec()`](https://dansemakula.github.io/figspec/reference/fig_apply_spec.md)
applies the typography and structural rules that a ggplot2 theme can
control. It also uses accessible colours and, when the plot maps a
variable to shape, shapes designed to remain distinguishable in print.

### What figspec changes

The two figures below use the same data, variables and labels. Both are
drawn on a Cell Press single-column canvas, which is 85 mm wide. The
website displays them at a larger size so that the details are easy to
compare; the underlying figure dimensions and measurements remain 85 mm.
ggplot2’s default text sizes do not adjust to the requirements of that
smaller canvas, so labels that look fine on screen may be too large, too
small or too crowded in the final figure.

`plain`` ``<-`` `[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``ggplot2``::`[`mpg`](https://ggplot2.tidyverse.org/reference/mpg.html)`, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``displ``, ``hwy``, colour ``=`` `[`factor`](https://rdrr.io/r/base/factor.html)`(``cyl``)``)``)`` ``+`` `` `[`geom_point`](https://ggplot2.tidyverse.org/reference/geom_point.html)`(``)`` ``+`` `` `[`labs`](https://ggplot2.tidyverse.org/reference/labs.html)`(``title ``=`` ``"Engine size and highway fuel economy"``,`` `` x ``=`` ``"Engine displacement (litres)"``, y ``=`` ``"Highway miles per gallon"``,`` `` colour ``=`` ``"Cylinders"``)`` `` ``plain`

![A default ggplot at 85 mm wide, with type too large and a red-green
palette.](figspec_files/figure-html/before-1.png)

ggplot2’s default base size is 11 pt, which gives this figure text
ranging from 8.8 to 13.2 pt. Cell Press allows 6 to 8 pt. The default
palette also includes red and green together, which Cell Press does not
allow, and colour is the only way to tell the four series apart.

`plain`` ``+`` `` `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``shape ``=`` `[`factor`](https://rdrr.io/r/base/factor.html)`(``cyl``)``)`` ``+`` `` ``# Give the shape the same label as the colour, so ggplot2 merges the two`` `` ``# into one legend rather than drawing a second.`` `` `[`labs`](https://ggplot2.tidyverse.org/reference/labs.html)`(``shape ``=`` ``"Cylinders"``)`` ``+`` `` `[`fig_apply_spec`](https://dansemakula.github.io/figspec/reference/fig_apply_spec.md)`(``"cell_press"``)`

![The same figure with fig_apply_spec applied: smaller type, Okabe-Ito
colours, and a different shape per
series.](figspec_files/figure-html/after-1.png)

The text now falls within the journal’s range. The Okabe-Ito palette
avoids a red-green pairing and remains distinguishable for people with
common forms of colour-vision deficiency. Each series also has its own
shape, so the figure still works in black and white. The data have not
changed.

## Checking a figure you have already drawn

Check the plot before saving whenever possible. At that stage, R still
knows the text sizes, colours, layers and theme settings. In a finished
TIFF, text is stored as pixels and its original point size cannot be
recovered reliably.

`p`` ``<-`` ``plain`` `` `[`fig_check`](https://dansemakula.github.io/figspec/reference/fig_check.md)`(``p``, ``"cell_press"``, column ``=`` ``"single"``)`` ``#> `` ``#> ``──`` ``Cell Press journals`` ``─────────────────────────────────────────────────────────`` ``#> ``checked: ggplot object`` ``#> `` ``#> ``✔`` Width 85 mm requires: single 85 mm`` ``#> ``!`` Height could not determine requires: max 200 mm`` ``#> ``!`` Resolution could not determine`` ``#> requires: min 300 dpi for colour; also states black and`` ``#> white 500, line art 1000 dpi`` ``#> ``!`` File format could not determine requires: TIFF, PDF, EPS, JPEG`` ``#> ``✖`` Type size smallest 8.8 pt, largest 13.2 pt`` ``#> requires: min 6 pt, max 8 pt`` ``#> ``!`` Font could not determine requires: Arial`` ``#> ``!`` Line width could not determine requires: min 0.5 pt, max 1.5 pt`` ``#> ``✔`` Colour mode RGB requires: RGB`` ``#> ``✖`` Colour pairs red and green both used (#F8766D, #7CAE00)`` ``#> requires: red and green not used together`` ``#> ``ℹ`` Greyscale 6 pair(s) merge in greyscale: #F8766D/#00BFC4,`` ``#> #F8766D/#C77CFF, #F8766D/#7CAE00, #00BFC4/#C77CFF and 2 more`` ``#> requires: not specified by publisher`` ``#> ``ℹ`` Colour vision colours merge under deuteranopia (1)`` ``#> requires: not specified by publisher`` ``#> ``ℹ`` Redundant coding colour is the only cue: all series share one shape and one`` ``#> line type`` ``#> requires: not specified by publisher`` ``#> ``ℹ`` Text case 4 label(s), not checked`` ``#> requires: not specified by publisher`` ``#> ``!`` File size could not determine requires: max 20 MB`` ``#> `` ``#> ``✖`` 2 requirements not met.`` ``#> ``ℹ`` 6 requirements or registry fields could not be judged automatically - check`` ``#> by hand.`` ``#> ``Source:`` ``<https://www.cell.com/information-for-authors/figure-guidelines>`` ``#> (verified 2026-08-21)`

The report finds two failures caused by ordinary ggplot2 defaults. The
text is larger than Cell Press permits, and the default palette uses red
and green together.

## Reading the report

Each requirement receives one of five results. A `fail` identifies
something that must be fixed. An `invalid` result means the file could
not be assessed reliably.

| Outcome | Meaning |
|----|----|
| pass | Meets the requirement |
| fail | Does not meet the requirement |
| unspecified | No requirement is stated, so there is nothing to test |
| unknown | A requirement exists, but the plot or file does not contain enough information to test it |
| invalid | The file is damaged or its contents do not match its extension |

When no value is available for a requirement, figspec distinguishes
between two reasons:

`r`` ``<-`` `[`fig_check`](https://dansemakula.github.io/figspec/reference/fig_check.md)`(``p``, ``"frontiers"``)`` ``knitr``::`[`kable`](https://rdrr.io/pkg/knitr/man/kable.html)`(`` `` ``r``[``r``$``check`` `[`%in%`](https://rdrr.io/r/base/match.html)` `[`c`](https://rdrr.io/r/base/c.html)`(``"File size"``, ``"Height"``)``, `[`c`](https://rdrr.io/r/base/c.html)`(``"check"``, ``"requirement"``, ``"status"``)``]``,`` `` row.names ``=`` ``FALSE`` ``)`

| check     | requirement                             | status      |
|:----------|:----------------------------------------|:------------|
| Height    | not yet reviewed for this specification | unknown     |
| File size | not specified by publisher              | unspecified |

Frontiers does not publish a file-size limit in the guidance that was
reviewed, so figspec reports *not specified by publisher*. A maximum
figure height has not yet been entered in the registry, so it reports
*not yet harvested for this journal*. The first describes the
publisher’s guidance; the second describes the current state of the
registry. Keeping them separate prevents missing data from being
mistaken for confirmation that no rule exists.

## Fixing what failed

[`theme_spec()`](https://dansemakula.github.io/figspec/reference/theme_spec.md)
applies the requirements that ggplot2’s theme system can control,
including the font family, minimum and maximum text sizes, theme line
widths, and structural rules such as Nature’s requirement to show axis
lines and tick marks.

`fixed`` ``<-`` ``p`` ``+`` `` `[`scale_colour_figspec`](https://dansemakula.github.io/figspec/reference/scale_colour_figspec.md)`(``"cividis"``)`` ``+`` `` `[`scale_shape_manual`](https://ggplot2.tidyverse.org/reference/scale_manual.html)`(``values ``=`` `[`figspec_shapes`](https://dansemakula.github.io/figspec/reference/figspec_shapes.md)`(``4``)``)`` ``+`` `` `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``shape ``=`` `[`factor`](https://rdrr.io/r/base/factor.html)`(``cyl``)``)`` ``+`` `` `[`theme_spec`](https://dansemakula.github.io/figspec/reference/theme_spec.md)`(``"cell_press"``)`` `` ``r`` ``<-`` `[`fig_check`](https://dansemakula.github.io/figspec/reference/fig_check.md)`(``fixed``, ``"cell_press"``, column ``=`` ``"single"``)`` ``knitr``::`[`kable`](https://rdrr.io/pkg/knitr/man/kable.html)`(`` `` ``r``[``r``$``status`` `[`%in%`](https://rdrr.io/r/base/match.html)` `[`c`](https://rdrr.io/r/base/c.html)`(``"pass"``, ``"fail"``)``, `[`c`](https://rdrr.io/r/base/c.html)`(``"check"``, ``"actual"``, ``"status"``)``]``,`` `` row.names ``=`` ``FALSE`` ``)`

| check        | actual                        | status |
|:-------------|:------------------------------|:-------|
| Width        | 85 mm                         | pass   |
| Type size    | smallest 6 pt, largest 7.5 pt | pass   |
| Colour mode  | RGB                           | pass   |
| Colour pairs | no red/green pairing          | pass   |

## Adjusting colour and shape

figspec separates publisher requirements from general guidance. If a
plot breaks a rule stated in the selected profile, the check fails.
Other useful findings are shown as guidance.

`knitr``::`[`kable`](https://rdrr.io/pkg/knitr/man/kable.html)`(`` `` `[`colour_safety_check`](https://dansemakula.github.io/figspec/reference/colour_safety_check.md)`(``p``, ``"cell_press"``)``[``, `[`c`](https://rdrr.io/r/base/c.html)`(``"check"``, ``"actual"``, ``"status"``)``]``,`` `` row.names ``=`` ``FALSE`` ``)`

| check | actual | status |
|:---|:---|:---|
| Colour pairs | red and green both used (#F8766D, \#7CAE00) | fail |
| Greyscale | 6 pair(s) merge in greyscale: \#F8766D/#00BFC4, \#F8766D/#C77CFF, \#F8766D/#7CAE00, \#00BFC4/#C77CFF and 2 more | unspecified |
| Colour vision | colours merge under deuteranopia (1) | unspecified |
| Redundant coding | colour is the only cue: all series share one shape and one line type | unspecified |

Cell Press states that red and green should not be used together, so
figspec treats that combination as a failed requirement. The Royal
Society publishes in black and white by default, so figspec checks
whether its colours remain distinct in greyscale. When a publisher does
not state either rule, figspec still reports the relevant result but
labels it `unspecified` instead of presenting it as a requirement.

Colour does not have to carry all the information. Giving each series a
different point shape or line type provides a second way to identify it
if two colours look alike. figspec calls this *redundant coding* and
reports whether the plot provides that additional visual cue:

`knitr``::`[`kable`](https://rdrr.io/pkg/knitr/man/kable.html)`(`` `` `[`colour_safety_check`](https://dansemakula.github.io/figspec/reference/colour_safety_check.md)`(``fixed``, ``"royal_society"``)``[``, `[`c`](https://rdrr.io/r/base/c.html)`(``"check"``, ``"actual"``, ``"status"``)``]``,`` `` row.names ``=`` ``FALSE`` ``)`

| check | actual | status |
|:---|:---|:---|
| Colour pairs | no red/green pairing | unspecified |
| Greyscale | all colours separable in greyscale | pass |
| Colour vision | separable under deuteranopia, protanopia and tritanopia | unspecified |

[`figspec_palettes()`](https://dansemakula.github.io/figspec/reference/figspec_palettes.md)
lists the palettes that ship with the package, each with its source.
Cividis is safe both under colour vision deficiency and in greyscale;
Okabe-Ito is safe under colour vision deficiency but **not** in
greyscale, because two of its colours sit at almost the same lightness.

## Saving at the right size

[`fig_save()`](https://dansemakula.github.io/figspec/reference/fig_save.md)
normally sizes the whole image, or canvas, to the width stated by the
journal. The plotting area inside that image is a second measurement,
and it can vary between figures even when their canvases are identical.
The next section introduces panel sizing, and the [panel-sizing
guide](https://dansemakula.github.io/figspec/articles/panels.md) covers
it in detail.

A common mistake is to save a figure much wider than the space available
and assume the publisher can reduce it safely. If a 180 mm figure is
reduced to an 85 mm column, everything becomes 47% of its original size.
An 8 pt label then appears at only 3.8 pt.

[`fig_save`](https://dansemakula.github.io/figspec/reference/fig_save.md)`(``"figure_1.tiff"``, ``fixed``, spec ``=`` ``"cell_press"``, column ``=`` ``"single"``)`

[`fig_save()`](https://dansemakula.github.io/figspec/reference/fig_save.md)
reads the required width and resolution from the registry, chooses a
graphics device for the requested file format, writes the file, and
checks the result—including whether that format is accepted.

You can see the available column widths before choosing one:

[`fig_columns`](https://dansemakula.github.io/figspec/reference/fig_columns.md)`(``"science"``)`` ``#> single double triple `` ``#> 57 121 184`` `[`fig_columns`](https://dansemakula.github.io/figspec/reference/fig_columns.md)`(``"cell_press"``)`` ``#> single onehalf double `` ``#> 85 114 174`

## Keep data panels aligned across a figure set

Saving every figure at the same width does not guarantee that the
regions containing the data will match. Axis labels, titles and legends
use part of the surrounding canvas. A figure with longer labels
therefore has less room left for its data, even when its image file is
exactly the same width.

The two plots below use all 234 observations in
[`ggplot2::mpg`](https://ggplot2.tidyverse.org/reference/mpg.html), with
identical variables, scales and a 150 mm canvas. Only the y-axis labels
differ. Colour and shape identify the drive type, so the groups remain
distinguishable without relying on colour alone.

### Before: equal canvases leave unequal room for data

`panel_colours`` ``<-`` `[`setNames`](https://rdrr.io/r/stats/setNames.html)`(`` `` `[`figspec_palette`](https://dansemakula.github.io/figspec/reference/figspec_palette.md)`(``"okabe_ito"``)``[`[`c`](https://rdrr.io/r/base/c.html)`(``6``, ``7``, ``4``)``]``,`` `` `[`c`](https://rdrr.io/r/base/c.html)`(``"4"``, ``"f"``, ``"r"``)`` ``)`` ``panel_shapes`` ``<-`` `[`setNames`](https://rdrr.io/r/stats/setNames.html)`(`[`figspec_shapes`](https://dansemakula.github.io/figspec/reference/figspec_shapes.md)`(``3``)``, `[`c`](https://rdrr.io/r/base/c.html)`(``"4"``, ``"f"``, ``"r"``)``)`` `` ``panel_base`` ``<-`` `[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(`` `` ``ggplot2``::`[`mpg`](https://ggplot2.tidyverse.org/reference/mpg.html)`,`` `` `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``displ``, ``hwy``, colour ``=`` ``drv``, shape ``=`` ``drv``)`` ``)`` ``+`` `` `[`geom_point`](https://ggplot2.tidyverse.org/reference/geom_point.html)`(``alpha ``=`` ``0.72``, size ``=`` ``1.8``)`` ``+`` `` `[`scale_colour_manual`](https://ggplot2.tidyverse.org/reference/scale_manual.html)`(``values ``=`` ``panel_colours``)`` ``+`` `` `[`scale_shape_manual`](https://ggplot2.tidyverse.org/reference/scale_manual.html)`(``values ``=`` ``panel_shapes``)`` ``+`` `` `[`labs`](https://ggplot2.tidyverse.org/reference/labs.html)`(``x ``=`` ``"Engine displacement (litres)"``,`` `` y ``=`` ``"Highway fuel economy"``,`` `` colour ``=`` ``"Drive type"``,`` `` shape ``=`` ``"Drive type"``)`` ``+`` `` `[`theme_spec`](https://dansemakula.github.io/figspec/reference/theme_spec.md)`(``"cell_press"``, base_size ``=`` ``8``)`` ``+`` `` `[`theme`](https://ggplot2.tidyverse.org/reference/theme.html)`(`` `` legend.position ``=`` ``"bottom"``,`` `` panel.background ``=`` `[`element_rect`](https://ggplot2.tidyverse.org/reference/element.html)`(`` `` fill ``=`` ``"#F3F8FC"``, colour ``=`` ``"#0072B2"``, linewidth ``=`` ``0.7`` `` ``)``,`` `` plot.background ``=`` `[`element_rect`](https://ggplot2.tidyverse.org/reference/element.html)`(`` `` fill ``=`` ``"white"``, colour ``=`` ``"#9AA4AE"``, linewidth ``=`` ``0.6`` `` ``)`` `` ``)`` `` ``panel_figures`` ``<-`` `[`list`](https://rdrr.io/r/base/list.html)`(`` `` short_labels ``=`` ``panel_base`` ``+`` `[`labs`](https://ggplot2.tidyverse.org/reference/labs.html)`(``title ``=`` ``"Short tick labels"``)``,`` `` long_labels ``=`` ``panel_base`` ``+`` `` `[`scale_y_continuous`](https://ggplot2.tidyverse.org/reference/scale_continuous.html)`(``labels ``=`` ``function``(``x``)`` `[`paste`](https://rdrr.io/r/base/paste.html)`(``x``, ``"miles per gallon"``)``)`` ``+`` `` `[`labs`](https://ggplot2.tidyverse.org/reference/labs.html)`(``title ``=`` ``"Long tick labels"``)`` ``)`` `` ``panel_figures``$``short_labels`` ``panel_figures``$``long_labels`

![A coloured fuel-economy plot with short y-axis labels and a relatively
wide pale-blue data
panel.](figspec_files/figure-html/panel-before-1.png)![The same coloured
observations and scales with longer y-axis labels and a visibly narrower
pale-blue data panel.](figspec_files/figure-html/panel-before-2.png)

The longer labels leave less horizontal room for the data.
[`fig_panel_width()`](https://dansemakula.github.io/figspec/reference/fig_panel_width.md)
measures both layouts and finds the widest data panel that every figure
can share within the available 150 mm.
[`fig_panel_size()`](https://dansemakula.github.io/figspec/reference/fig_panel_size.md)
then applies that exact width and gives each figure the additional
canvas its labels require.

### After: equal data panels with every label preserved

`shared_width`` ``<-`` `[`fig_panel_width`](https://dansemakula.github.io/figspec/reference/fig_panel_width.md)`(``panel_figures``, width ``=`` ``150``)`` ``aligned_figures`` ``<-`` `[`lapply`](https://rdrr.io/r/base/lapply.html)`(``panel_figures``, ``fig_panel_size``, width ``=`` ``shared_width``)`` ``aligned_geometry`` ``<-`` `[`lapply`](https://rdrr.io/r/base/lapply.html)`(``aligned_figures``, ``fig_geometry``)`` `` ``aligned_dir`` ``<-`` ``knitr``::`[`opts_current`](https://rdrr.io/pkg/knitr/man/opts_chunk.html)`$``get``(``"fig.path"``)`` `[`dir.create`](https://rdrr.io/r/base/files2.html)`(``aligned_dir``, recursive ``=`` ``TRUE``, showWarnings ``=`` ``FALSE``)`` ``aligned_files`` ``<-`` `[`file.path`](https://rdrr.io/r/base/file.path.html)`(`` `` ``aligned_dir``, `[`c`](https://rdrr.io/r/base/c.html)`(``"figspec-aligned-short.png"``, ``"figspec-aligned-long.png"``)`` ``)`` `[`invisible`](https://rdrr.io/r/base/invisible.html)`(`[`Map`](https://rdrr.io/r/base/funprog.html)`(``function``(``figure``, ``geometry``, ``path``)`` ``{`` `` ``ggplot2``::`[`ggsave`](https://ggplot2.tidyverse.org/reference/ggsave.html)`(`` `` ``path``, ``figure``,`` `` width ``=`` ``geometry``$``canvas_width_mm``,`` `` height ``=`` ``geometry``$``canvas_height_mm``,`` `` units ``=`` ``"mm"``, dpi ``=`` ``180``, bg ``=`` ``"white"`` `` ``)`` ``}``, ``aligned_figures``, ``aligned_geometry``, ``aligned_files``)``)`` ``#> Saving 135 x 114 mm image`` ``#> Saving 150 x 114 mm image`` ``knitr``::`[`include_graphics`](https://rdrr.io/pkg/knitr/man/include_graphics.html)`(``aligned_files``)`

![The coloured short-label plot after figspec applies the shared
data-panel
width.](figspec_files/figure-html/figspec-aligned-short.png)![The
coloured long-label plot with the same measured data-panel width and
enough surrounding canvas to preserve its
labels.](figspec_files/figure-html/figspec-aligned-long.png)

Before adjustment, the two data panels could occupy 140.2 and 124.8 mm
respectively. After adjustment, both are exactly 124.8 mm wide. The
long-label figure receives a wider canvas instead of a smaller plotting
area, so its text remains readable and the two data regions align.

This workflow is independent of journals. It is useful whenever figures
must align in a report, presentation, thesis, dashboard or composite
layout. The [panel-sizing
guide](https://dansemakula.github.io/figspec/articles/panels.md)
explains the geometry and export options in detail.

## Resolution requirements for different figure types

Publishers often require different resolutions for different kinds of
artwork. A colour or greyscale figure may need 300 dpi, while line art
may need 600 to 1200 dpi. Twelve registry entries currently state a
separate resolution for line art.

In this context, line art means **monochrome artwork with no shading**.
Publishers use phrases such as “black and white graphic with no shading”
and “monochrome”. Its sharp edges show stair-stepping easily, which is
why it is usually assigned the highest resolution.

A colour figure is therefore not line art and should not automatically
be checked against the line-art resolution.
[`fig_suggest_art_type()`](https://dansemakula.github.io/figspec/reference/fig_suggest_art_type.md)
examines what the plot contains and recommends the appropriate category:

`line_art`` ``<-`` `[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``ggplot2``::`[`mpg`](https://ggplot2.tidyverse.org/reference/mpg.html)`, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``displ``, ``hwy``)``)`` ``+`` `` `[`geom_point`](https://ggplot2.tidyverse.org/reference/geom_point.html)`(``colour ``=`` ``"black"``)`` `[`fig_suggest_art_type`](https://dansemakula.github.io/figspec/reference/fig_suggest_art_type.md)`(``line_art``, ``"bmj"``)`` ``#> `` ``#> ``──`` ``Choose a resolution category`` ``────────────────────────────────────────────────`` ``#> ``ℹ`` This plot uses only black and white, with no grey. Publishers classify this`` ``#> as ``line art`` and usually require the highest resolution because sharp edges`` ``#> show pixelation easily.`` ``#> `` ``#> Requirements from ``BMJ journals``:`` ``#> • general minimum: 300 dpi`` ``#> • line art: 1200 dpi`` ``#> ``For non-vector files (e.g. TIFF, JPEG) a minimum resolution of 300 dpi is`` ``#> ``required, except for line art which should be 1200 dpi.`` ``#> `` ``#> ``✔`` Suggested: fig_check(plot, spec, art_type = "line")`` ``#> ``ℹ`` This recommendation is based on what the plot contains. If publisher guidance`` ``#> is unclear, using a higher resolution increases the file size, while using a`` ``#> lower resolution may fall below the requirement. Check the linked guidance`` ``#> before submission.`

ggplot2’s default bar fill is `#595959`, a mid grey, so a default bar
chart is grayscale art:

[`fig_suggest_art_type`](https://dansemakula.github.io/figspec/reference/fig_suggest_art_type.md)`(`[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``ggplot2``::`[`mpg`](https://ggplot2.tidyverse.org/reference/mpg.html)`, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``class``)``)`` ``+`` `[`geom_bar`](https://ggplot2.tidyverse.org/reference/geom_bar.html)`(``)``)`` ``#> `` ``#> ``──`` ``Choose a resolution category`` ``────────────────────────────────────────────────`` ``#> ``ℹ`` This plot uses grey but no colour, so it is ``grayscale art``, not line art. For`` ``#> example, ggplot2's default bar fill is a mid grey, so a default bar chart`` ``#> belongs in this category.`` ``#> `` ``#> ``✔`` Suggested: fig_check(plot, spec, art_type = "bw")`` ``#> ``ℹ`` This recommendation is based on what the plot contains. If publisher guidance`` ``#> is unclear, using a higher resolution increases the file size, while using a`` ``#> lower resolution may fall below the requirement. Check the linked guidance`` ``#> before submission.`

[`fig_check()`](https://dansemakula.github.io/figspec/reference/fig_check.md)
can classify a live plot from its layers and colours and then use the
matching resolution rule. A saved file may no longer reveal how the plot
was constructed, so `"auto"` uses the strictest recorded threshold
rather than risk approving a file with too little resolution.

## Checking a whole submission

One call can review a named collection of live plots. Because the plots
are still editable R objects, figspec can inspect their text sizes,
colours and structure as well as their dimensions:

`submission_figures`` ``<-`` `[`list`](https://rdrr.io/r/base/list.html)`(`` `` engine_size ``=`` ``fitted``,`` `` vehicle_class ``=`` `[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``ggplot2``::`[`mpg`](https://ggplot2.tidyverse.org/reference/mpg.html)`, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``class``, ``hwy``, fill ``=`` ``class``)``)`` ``+`` `` `[`geom_boxplot`](https://ggplot2.tidyverse.org/reference/geom_boxplot.html)`(``show.legend ``=`` ``FALSE``)`` ``+`` `` `[`labs`](https://ggplot2.tidyverse.org/reference/labs.html)`(``x ``=`` ``"Vehicle class"``, y ``=`` ``"Highway miles per gallon"``)`` ``+`` `` `[`fig_apply_spec`](https://dansemakula.github.io/figspec/reference/fig_apply_spec.md)`(``"cell_press"``)`` ``)`` `` ``submission_figures``$``engine_size`` ``submission_figures``$``vehicle_class`

![A fitted scatter plot of engine displacement and highway fuel
economy.](figspec_files/figure-html/submission-plots-1.png)![A fitted
box plot comparing highway fuel economy across vehicle
classes.](figspec_files/figure-html/submission-plots-2.png)

[`submission_check`](https://dansemakula.github.io/figspec/reference/submission_check.md)`(``submission_figures``, ``"cell_press"``)`` ``#> `` ``#> ``──`` ``Submission check - Cell Press journals`` ``──────────────────────────────────────`` ``#> 2 figures checked`` ``#> `` ``#> ``!`` engine_size single incomplete (6 recorded requirement(s) not judged)`` ``#> ``!`` vehicle_class single incomplete (5 recorded requirement(s) not judged)`` ``#> `` ``#> ``ℹ`` Plot areas differ by 13 mm across this set (engine_size 64 mm, vehicle_class 77.1 mm). No publisher requires them to match, so this is not a failure. To make them match, pass fig_panel_width() to fig_save().`` ``#> `` ``#> ``!`` No failures found, but at least one figure is not fully assessed.`` ``#> ``ℹ`` Some requirements are not on record in this specification, so they were not judged.`` ``#> ``Source:`` ``<https://www.cell.com/information-for-authors/figure-guidelines>`` ``#> (verified 2026-08-21)`

The same function accepts a directory or a vector of saved file paths.
It can check those files for dimensions, format, resolution and file
size, but it can no longer recover plot settings such as the original
text sizes. For the most complete assessment, check the editable plots
first and the exported files afterwards.

## In R Markdown or Quarto

Figures created in R Markdown or Quarto are often saved directly by
knitr rather than through
[`ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html). Their
dimensions and resolution therefore come from chunk options such as
`fig.width` and `dpi`.

[`figspec_knitr_options`](https://dansemakula.github.io/figspec/reference/figspec_knitr_options.md)`(``"cell_press"``, ``"double"``)`` ``#> $fig.width`` ``#> [1] 6.850394`` ``#> `` ``#> $fig.height`` ``#> [1] 5.137795`` ``#> `` ``#> $dpi`` ``#> [1] 1000`` ``#> `` ``#> $dev`` ``#> [1] "tiff"`

Use `figspec_knitr_setup("cell_press", "double")` in the setup chunk to
apply the journal’s size and resolution to every figure in the document.

The project specification created at the start works here too:

[`figspec_knitr_options`](https://dansemakula.github.io/figspec/reference/figspec_knitr_options.md)`(``report_spec``, ``"full"``, height ``=`` ``100``, units ``=`` ``"mm"``)`` ``#> $fig.width`` ``#> [1] 6.299213`` ``#> `` ``#> $fig.height`` ``#> [1] 3.937008`` ``#> `` ``#> $dpi`` ``#> [1] 300`` ``#> `` ``#> $dev`` ``#> [1] "ragg_png"`

## Reusing a figure set for another specification

A figure set may move to a new journal, report or production system. The
new requirements can be incompatible with the old ones: Cell Press wants
type between 6 and 8 pt, whereas PLOS ONE asks for 8 to 12 pt. Rather
than redraw the set by hand, re-export the plot objects against the new
specification.

[`fig_refit`](https://dansemakula.github.io/figspec/reference/fig_refit.md)`(``my_plots``, spec ``=`` ``"plos_one"``, output_dir ``=`` ``"figures_plos/"``)`

[`fig_refit()`](https://dansemakula.github.io/figspec/reference/fig_refit.md)
applies the new theme and exports the figures again. It also accepts a
project specification instead of a registry name. The function needs the
original plot objects because a finished TIFF no longer contains
reliable information about settings such as the original text sizes.

## Tables, graphical abstracts, video and audio

A publication may also include tables, graphical abstracts, video or
audio, each with requirements of its own. A publisher may specify how
tables are formatted, the dimensions of a graphical abstract, or the
file types and technical limits accepted for video and audio. figspec
reports each kind of requirement separately so it is clear which rules
apply to which file.

[`graphical_abstract_spec`](https://dansemakula.github.io/figspec/reference/graphical_abstract_spec.md)`(``"rsc"``)`` ``#> `` ``#> ``──`` ``Royal Society of Chemistry journals - graphical abstract`` ``────────────────────`` ``#> • ``Maximum size:`` 80 x 40 mm`` ``#> • ``Resolution:`` 600 dpi`` ``#> • ``Formats:`` TIFF`` ``#> • ``Text limit:`` 250 characters`` ``#> `` ``#> ``The figure should be a maximum size of 8 cm wide x 4 cm high ... Figures should`` ``#> ``be supplied as TIFF files, with a resolution of 600 dpi or greater ... The text`` ``#> ``supplied should be 1-2 sentences long, using a maximum of 250 characters.`` ``#> `` ``#> ``Source:`` ``#> ``<https://www.rsc.org/publishing/publish-with-us/publish-a-journal-article/chem-soc-rev>`` ``#> (verified 2026-08-22)`` `[`table_spec`](https://dansemakula.github.io/figspec/reference/table_spec.md)`(``"nature"``)`` ``#> `` ``#> ``──`` ``Nature - tables`` ``─────────────────────────────────────────────────────────────`` ``#> • ``Orientation:`` portrait`` ``#> • ``Title style:`` short, one-line title in bold text`` ``#> • ``Notes:`` Symbols and abbreviations are defined immediately below the table,`` ``#> followed by essential descriptive material, all in double-spaced text.`` ``#> `` ``#> ``Publisher's wording: Tables should each be presented on a separate page,`` ``#> ``portrait (not landscape) orientation, and upright on the page, not sideways.`` ``#> ``Tables have a short, one-line title in bold text. Tables should be as small as`` ``#> ``possible.`` ``#> `` ``#> ``Source:`` ``<https://www.nature.com/nature/for-authors/final-submission>`` (verified`` ``#> 2026-09-03)`` `[`media_spec`](https://dansemakula.github.io/figspec/reference/media_spec.md)`(``"science"``)`` ``#> `` ``#> ``──`` ``Science - supplementary media`` ``───────────────────────────────────────────────`` ``#> • ``Video formats:`` MP4, MOV`` ``#> • ``Video codec:`` H.264`` ``#> • ``Maximum frame size:`` 1920 x 1080`` ``#> • ``Preferred frame sizes:`` 640 x 480 or 1280 x 720`` ``#> • ``Maximum file size:`` 50 MB`` ``#> • ``Audio formats:`` WAV, MP3, M4A`` ``#> • ``Audio bit rate:`` 160 kb/s`` ``#> `` ``#> ``Aim to stay within 640 x 480 or 1280 x 720 resolution. Do not exceed full HD`` ``#> ``frame size (1920 x 1080)`` ``#> `` ``#> ``Source:`` ``#> ``<https://www.science.org/content/page/instructions-preparing-initial-manuscript>`` ``#> (verified 2026-08-22)`` ``#> ``Applies at:`` initial submission`

[`media_check()`](https://dansemakula.github.io/figspec/reference/media_check.md)
inspects an actual supplementary video or audio file. It compares the
file format, frame dimensions, file size, codec and audio bit rate with
the recorded requirements. Anything it cannot determine is identified
for manual review.

## When manual review is still needed

Some requirements cannot be checked automatically. If guidance gives
dimensions in pixels but no resolution for converting them, figspec
keeps the dimensions in pixels rather than guessing a physical size. If
the guidance does not state a rule, the report says that it is
unspecified. To check text size, provide the original plot because a
saved raster image no longer records the text’s point size. The report
lists each item that still needs manual review.

figspec also measures differences between plotting-panel sizes without
calling them a failure. No publisher profile in the registry currently
requires every panel to have the same dimensions. You can use the
measurements to align a set when your report, presentation or figure
layout needs it, without presenting a design preference as a publisher
requirement.

## Where to go next

- [Learn about panel
  sizing](https://dansemakula.github.io/figspec/articles/panels.md) to
  align the plotting areas across a set of figures.
- [Browse the publication
  profiles](https://dansemakula.github.io/figspec/articles/journals.md)
  and see how complete each registry entry is.
- [Review every function
  argument](https://dansemakula.github.io/figspec/articles/options.md).
- Run [`help(package = "figspec")`](https://rdrr.io/pkg/figspec/man) in
  an installed R session to browse the function index, organised by the
  job each function performs.
