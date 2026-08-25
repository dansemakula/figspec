# Getting started with figspec

[`library`](https://rdrr.io/r/base/library.html)`(`[`ggplot2`](https://ggplot2.tidyverse.org)`)`` `[`library`](https://rdrr.io/r/base/library.html)`(`[`figspec`](https://dansemakula.github.io/figspec/)`)`

## Two jobs

figspec builds a figure to a specification, exports it at exactly that
size and resolution, then checks the result and says where it falls
short.

A specification can come from two places, and the package does two jobs
accordingly.

**A journal’s published requirements.** Name a target journal and the
width, resolution, file format, typography and colour rules come from
its author guidelines, as data, with the page they were read from and
the date. This is what the rest of this article covers.

**A size you choose yourself.** No journal need be involved. The most
useful case is setting the *plot panel* rather than the image, so a set
of figures shares one plot area whatever their axis labels do —
something R cannot otherwise express. That has its own article:
[`vignette("panels")`](https://dansemakula.github.io/figspec/articles/panels.md).

You can also write a specification by hand, or register a house style,
and check against it exactly as though it were a journal. Wherever this
article says “journal”, a specification of your own works the same way.

## The problem journals create

Journals publish precise rules for the figures you submit, and the rules
differ. Cell Press asks for 85, 114 or 174 mm wide with type between 6
and 8 pt. Science asks for 57, 121 or 184 mm with type no smaller than 5
pt. PNAS caps type at 12 pt and asks that numerical axes reach zero.
Nature wants panel labels upright; the Royal Society wants them
italicised.

Nothing in an ordinary plotting workflow makes any of that visible, and
most people find out at the production stage, after acceptance.

## Bring the journal in as you plot

The simplest way to meet a journal’s requirements is to build the figure
to them from the start. Add the journal the way you would add a colour
scale:

`fitted`` ``<-`` `[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``mtcars``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``wt``, ``mpg``, colour ``=`` `[`factor`](https://rdrr.io/r/base/factor.html)`(``cyl``)``, shape ``=`` `[`factor`](https://rdrr.io/r/base/factor.html)`(``cyl``)``)``)`` ``+`` `` `[`geom_point`](https://ggplot2.tidyverse.org/reference/geom_point.html)`(``)`` ``+`` `` `[`labs`](https://ggplot2.tidyverse.org/reference/labs.html)`(``title ``=`` ``"Fuel economy"``, x ``=`` ``"Weight (1000 lbs)"``, y ``=`` ``"Miles per gallon"``)`` ``+`` `` `[`fit_journal`](https://dansemakula.github.io/figspec/reference/fit_journal.md)`(``"cell_press"``)`` `` ``report`` ``<-`` `[`fig_check`](https://dansemakula.github.io/figspec/reference/fig_check.md)`(``fitted``, ``"cell_press"``, column ``=`` ``"single"``)`` ``knitr``::`[`kable`](https://rdrr.io/pkg/knitr/man/kable.html)`(``report``[``, `[`c`](https://rdrr.io/r/base/c.html)`(``"check"``, ``"actual"``, ``"status"``)``]``, row.names ``=`` ``FALSE``)`

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
| Greyscale | 1 pair(s) merge in greyscale: \#E69F00/#56B4E9 | unspecified |
| Colour vision | separable under deuteranopia, protanopia and tritanopia | unspecified |
| Redundant coding | colours merge in greyscale but 3 shapes still separate the series | unspecified |
| Text case | 3 label(s), not checked | unspecified |
| File size | could not determine | unknown |

That one line carries the journal’s typography, its stated line weights,
its structural rules, and colours and shapes chosen to survive what the
journal does to a figure in production.

### What actually changes

Both figures below are the same data and the same code, drawn at Cell
Press’s single-column width of 85 mm — the size a reader sees, not the
size you draw at on a laptop. That is the whole difficulty: at 85 mm a
default ggplot is about half the width it was designed at, and
everything in it shrinks with it.

`plain`` ``<-`` `[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``mtcars``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``wt``, ``mpg``, colour ``=`` `[`factor`](https://rdrr.io/r/base/factor.html)`(``cyl``)``)``)`` ``+`` `` `[`geom_point`](https://ggplot2.tidyverse.org/reference/geom_point.html)`(``)`` ``+`` `` `[`labs`](https://ggplot2.tidyverse.org/reference/labs.html)`(``title ``=`` ``"Fuel economy"``, x ``=`` ``"Weight (1000 lbs)"``,`` `` y ``=`` ``"Miles per gallon"``, colour ``=`` ``"Cylinders"``)`` `` ``plain`

![A default ggplot at 85 mm wide, with type too large and a red-green
palette.](figspec_files/figure-html/before-1.png)

ggplot2’s default base size is 11 pt, which puts this figure’s text
between 8.8 and 13.2 pt against Cell Press’s 6 to 8. Its default palette
opens with a red and a green, which Cell Press states should not be used
together. And the three series are told apart by colour alone.

`plain`` ``+`` `` `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``shape ``=`` `[`factor`](https://rdrr.io/r/base/factor.html)`(``cyl``)``)`` ``+`` `` ``# Give the shape the same label as the colour, so ggplot2 merges the two`` `` ``# into one legend rather than drawing a second.`` `` `[`labs`](https://ggplot2.tidyverse.org/reference/labs.html)`(``shape ``=`` ``"Cylinders"``)`` ``+`` `` `[`fit_journal`](https://dansemakula.github.io/figspec/reference/fit_journal.md)`(``"cell_press"``)`

![The same figure with fit_journal applied: smaller type, Okabe-Ito
colours, and a different shape per
series.](figspec_files/figure-html/after-1.png)

Type is now inside the journal’s range, the palette is Okabe-Ito, which
has no red-green pair and stays separable under the common colour vision
deficiencies, and each series carries its own shape, so the figure still
reads if it is printed in black and white. Nothing about the data
changed.

## Checking a figure you have already drawn

Type size lives in the plot object. Once a figure becomes a TIFF it is
pixels, and the point sizes have gone with it, so the moment to check is
while you still hold the plot.

`p`` ``<-`` `[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``mtcars``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``wt``, ``mpg``, colour ``=`` `[`factor`](https://rdrr.io/r/base/factor.html)`(``cyl``)``)``)`` ``+`` `` `[`geom_point`](https://ggplot2.tidyverse.org/reference/geom_point.html)`(``)`` ``+`` `` `[`labs`](https://ggplot2.tidyverse.org/reference/labs.html)`(``title ``=`` ``"Fuel economy"``, x ``=`` ``"Weight (1000 lbs)"``, y ``=`` ``"Miles per gallon"``,`` `` colour ``=`` ``"Cylinders"``)`` `` `[`fig_check`](https://dansemakula.github.io/figspec/reference/fig_check.md)`(``p``, ``"cell_press"``, column ``=`` ``"single"``)`` ``#> `` ``#> ``──`` ``Cell Press journals`` ``─────────────────────────────────────────────────────────`` ``#> ``checked: ggplot object`` ``#> `` ``#> ``✔`` Width 85 mm`` ``#> requires: single 85 mm | onehalf 114 mm | double 174 mm`` ``#> ``!`` Height could not determine requires: max 200 mm`` ``#> ``!`` Resolution could not determine`` ``#> requires: min 300 dpi for colour; also states black and`` ``#> white 500, line art 1000 dpi`` ``#> ``!`` File format could not determine requires: TIFF, PDF, EPS, JPEG`` ``#> ``✖`` Type size smallest 8.8 pt, largest 13.2 pt`` ``#> requires: min 6 pt, max 8 pt`` ``#> ``!`` Font could not determine requires: Arial`` ``#> ``!`` Line width could not determine requires: min 0.5 pt, max 1.5 pt`` ``#> ``✔`` Colour mode RGB requires: RGB`` ``#> ``✖`` Colour pairs red and green both used (#F8766D, #00BA38)`` ``#> requires: red and green not used together`` ``#> ``ℹ`` Greyscale 3 pair(s) merge in greyscale: #00BA38/#F8766D,`` ``#> #00BA38/#619CFF, #F8766D/#619CFF`` ``#> requires: not specified by publisher`` ``#> ``ℹ`` Colour vision colours merge under deuteranopia (1)`` ``#> requires: not specified by publisher`` ``#> ``ℹ`` Redundant coding colour is the only cue: all series share one shape and one`` ``#> line type`` ``#> requires: not specified by publisher`` ``#> ``ℹ`` Text case 4 label(s), not checked`` ``#> requires: not specified by publisher`` ``#> ``!`` File size could not determine requires: max 20 MB`` ``#> `` ``#> ``✖`` 2 requirements not met.`` ``#> ``ℹ`` 10 requirements could not be judged automatically - check by hand.`` ``#> ``Source:`` ``<https://www.cell.com/information-for-authors/figure-guidelines>`` ``#> (verified 2026-08-21)`

Two real failures in an ordinary ggplot, from defaults nobody thinks
about. ggplot2’s base size is 11 pt, which puts text between 8.8 and
13.2 pt against Cell Press’s 6 to 8. And ggplot2’s default palette
contains a red and a green, which Cell Press states should not be used
together.

## Reading the report

Each requirement gets one of four outcomes, and only one of them is a
problem you must fix.

| Outcome     | Meaning                                                     |
|-------------|-------------------------------------------------------------|
| pass        | Meets the requirement                                       |
| fail        | Breaches it                                                 |
| unspecified | The publisher does not state this. Nothing can be concluded |
| unknown     | The requirement exists, but this input cannot answer it     |

`unspecified` splits further, and the distinction matters:

`r`` ``<-`` `[`fig_check`](https://dansemakula.github.io/figspec/reference/fig_check.md)`(``p``, ``"frontiers"``)`` ``knitr``::`[`kable`](https://rdrr.io/pkg/knitr/man/kable.html)`(`` `` ``r``[``r``$``check`` `[`%in%`](https://rdrr.io/r/base/match.html)` `[`c`](https://rdrr.io/r/base/c.html)`(``"File size"``, ``"Height"``)``, `[`c`](https://rdrr.io/r/base/c.html)`(``"check"``, ``"requirement"``, ``"status"``)``]``,`` `` row.names ``=`` ``FALSE`` ``)`

| check     | requirement                        | status      |
|:----------|:-----------------------------------|:------------|
| Height    | not yet harvested for this journal | unknown     |
| File size | not specified by publisher         | unspecified |

Frontiers’ file-size rule was read and confirmed absent, so it is *not
specified by publisher*. Its height rule has not been resolved into a
number by anyone, so it is *not yet harvested for this journal*. The
first is a fact about Frontiers. The second is a fact about this
registry, and saying so is the difference between a registry you can
trust and one that is confidently wrong.

## Fixing it

[`theme_journal()`](https://dansemakula.github.io/figspec/reference/theme_journal.md)
applies every requirement a theme can express: the font family, the type
floor and ceiling, stated line weights, and structural rules such as
Nature’s requirement that axis lines and tick marks be drawn.

`fixed`` ``<-`` ``p`` ``+`` `` `[`scale_colour_figspec`](https://dansemakula.github.io/figspec/reference/scale_colour_figspec.md)`(``"cividis"``)`` ``+`` `` `[`scale_shape_manual`](https://ggplot2.tidyverse.org/reference/scale_manual.html)`(``values ``=`` `[`figspec_shapes`](https://dansemakula.github.io/figspec/reference/figspec_shapes.md)`(``3``)``)`` ``+`` `` `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``shape ``=`` `[`factor`](https://rdrr.io/r/base/factor.html)`(``cyl``)``)`` ``+`` `` `[`theme_journal`](https://dansemakula.github.io/figspec/reference/theme_journal.md)`(``"cell_press"``)`` `` ``r`` ``<-`` `[`fig_check`](https://dansemakula.github.io/figspec/reference/fig_check.md)`(``fixed``, ``"cell_press"``, column ``=`` ``"single"``)`` ``knitr``::`[`kable`](https://rdrr.io/pkg/knitr/man/kable.html)`(`` `` ``r``[``r``$``status`` `[`%in%`](https://rdrr.io/r/base/match.html)` `[`c`](https://rdrr.io/r/base/c.html)`(``"pass"``, ``"fail"``)``, `[`c`](https://rdrr.io/r/base/c.html)`(``"check"``, ``"actual"``, ``"status"``)``]``,`` `` row.names ``=`` ``FALSE`` ``)`

| check        | actual                        | status |
|:-------------|:------------------------------|:-------|
| Width        | 85 mm                         | pass   |
| Type size    | smallest 6 pt, largest 7.5 pt | pass   |
| Colour mode  | RGB                           | pass   |
| Colour pairs | no red/green pairing          | pass   |

## Colour, and why shape matters

Three colour findings are reported, and which of them can *fail* depends
on what the publisher actually states.

`knitr``::`[`kable`](https://rdrr.io/pkg/knitr/man/kable.html)`(`` `` `[`check_colour_safety`](https://dansemakula.github.io/figspec/reference/check_colour_safety.md)`(``p``, ``"cell_press"``)``[``, `[`c`](https://rdrr.io/r/base/c.html)`(``"check"``, ``"actual"``, ``"status"``)``]``,`` `` row.names ``=`` ``FALSE`` ``)`

| check | actual | status |
|:---|:---|:---|
| Colour pairs | red and green both used (#F8766D, \#00BA38) | fail |
| Greyscale | 3 pair(s) merge in greyscale: \#00BA38/#F8766D, \#00BA38/#619CFF, \#F8766D/#619CFF | unspecified |
| Colour vision | colours merge under deuteranopia (1) | unspecified |
| Redundant coding | colour is the only cue: all series share one shape and one line type | unspecified |

Red-and-green is a **requirement** for Cell Press because Cell Press
states it. Greyscale separability is a requirement for the Royal
Society, which prints in black and white by default. Colour-vision
safety is reported for every journal and stays `unspecified`, since it
is good practice that publishers leave to your judgement.

Note the last row. If colours merge but shapes differ, the figure still
reads:

`knitr``::`[`kable`](https://rdrr.io/pkg/knitr/man/kable.html)`(`` `` `[`check_colour_safety`](https://dansemakula.github.io/figspec/reference/check_colour_safety.md)`(``fixed``, ``"royal_society"``)``[``, `[`c`](https://rdrr.io/r/base/c.html)`(``"check"``, ``"actual"``, ``"status"``)``]``,`` `` row.names ``=`` ``FALSE`` ``)`

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

Sizes here are canvas sizes: the image file is the width the journal
states. That is what compliance means, and it is what
[`fig_save()`](https://dansemakula.github.io/figspec/reference/fig_save.md)
does by default. There is a second width — the plot area inside the
image — which the journal says nothing about and which is what makes a
set of figures look even or uneven.
[`vignette("panels")`](https://dansemakula.github.io/figspec/articles/panels.md)
covers it.

This is the part that is easiest to get wrong. Type size is absolute.
Save a figure at 180 mm, have the journal place it in an 85 mm column,
and everything is scaled to 47%: a compliant 8 pt label arrives at 3.8
pt.

[`fig_save`](https://dansemakula.github.io/figspec/reference/fig_save.md)`(``"figure_1.tiff"``, ``fixed``, journal ``=`` ``"cell_press"``, column ``=`` ``"single"``)`

[`fig_save()`](https://dansemakula.github.io/figspec/reference/fig_save.md)
takes the width from the registry, defaults the resolution to the
journal’s stated minimum, picks a device that can render the required
font, and re-checks the file it wrote.

Column names come from the journal itself:

[`fig_columns`](https://dansemakula.github.io/figspec/reference/fig_columns.md)`(``"science"``)`` ``#> single double triple `` ``#> 57 121 184`` `[`fig_columns`](https://dansemakula.github.io/figspec/reference/fig_columns.md)`(``"cell_press"``)`` ``#> single onehalf double `` ``#> 85 114 174`

## Which resolution rule applies

Publishers set different resolutions for different kinds of artwork, and
the gap is large: 300 dpi generally, against 600 to 1200 dpi for line
art. Twelve entries in the registry state a separate line-art figure.

Line art means **monochrome**, and the distinction carries real weight.
Springer defines it as a “Black and white graphic with no shading”; ACS
and IEEE both write “black and white line art”; Taylor & Francis and OUP
both write “monochrome”. In prepress it is a one-bit image, and it
carries the highest resolution bar precisely because sharp one-bit edges
alias badly when sampled too coarsely.

So a colour figure is *not* line art, and asking 1200 dpi of it would be
the wrong advice.
[`suggest_art_type()`](https://dansemakula.github.io/figspec/reference/suggest_art_type.md)
classifies what the plot actually contains:

`line_art`` ``<-`` `[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``mtcars``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``wt``, ``mpg``)``)`` ``+`` `[`geom_point`](https://ggplot2.tidyverse.org/reference/geom_point.html)`(``colour ``=`` ``"black"``)`` `[`suggest_art_type`](https://dansemakula.github.io/figspec/reference/suggest_art_type.md)`(``line_art``, ``"bmj"``)`` ``#> `` ``#> ``──`` ``Which resolution rule applies`` ``───────────────────────────────────────────────`` ``#> ``ℹ`` This plot is pure black and white with no grey. That is ``line art`` in the sense`` ``#> publishers mean, and it carries the highest resolution bar: sharp one-bit`` ``#> edges alias badly when sampled too coarsely.`` ``#> `` ``#> ``BMJ journals`` states:`` ``#> • general minimum: 300 dpi`` ``#> • line art: 1200 dpi`` ``#> ``For non-vector files (e.g. TIFF, JPEG) a minimum resolution of 300 dpi is`` ``#> ``required, except for line art which should be 1200 dpi.`` ``#> `` ``#> ``✔`` Suggested: fig_check(plot, journal, art_type = "line")`` ``#> ``ℹ`` This is a suggestion from what the plot contains, not a rule. Where`` ``#> publishers disagree, the stricter reading costs file size; the looser one`` ``#> risks a figure below the resolution the journal asked for.`

ggplot2’s default bar fill is `#595959`, a mid grey, so a default bar
chart is grayscale art:

[`suggest_art_type`](https://dansemakula.github.io/figspec/reference/suggest_art_type.md)`(`[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``mtcars``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(`[`factor`](https://rdrr.io/r/base/factor.html)`(``cyl``)``)``)`` ``+`` `[`geom_bar`](https://ggplot2.tidyverse.org/reference/geom_bar.html)`(``)``)`` ``#> `` ``#> ``──`` ``Which resolution rule applies`` ``───────────────────────────────────────────────`` ``#> ``ℹ`` This plot uses grey but no colour, so it is ``grayscale art``, not line art.`` ``#> ggplot2's default bar fill is a mid grey, so a default bar chart lands here`` ``#> rather than in line art.`` ``#> `` ``#> ``✔`` Suggested: fig_check(plot, journal, art_type = "bw")`` ``#> ``ℹ`` This is a suggestion from what the plot contains, not a rule. Where`` ``#> publishers disagree, the stricter reading costs file size; the looser one`` ``#> risks a figure below the resolution the journal asked for.`

[`fig_check()`](https://dansemakula.github.io/figspec/reference/fig_check.md)
checks against the general minimum unless you say otherwise, and
mentions the line-art rule only when a plot really is pure black and
white and the journal holds line art to more. It does not change the
verdict for you.

## Checking a whole submission

[`check_submission`](https://dansemakula.github.io/figspec/reference/check_submission.md)`(``"figures/"``, ``"cell_press"``)`` ``#> ✔ Figure_1.tiff single all requirements met`` ``#> ✖ Figure_2.tiff double failed: Resolution, File format`

Files are checked as files, so geometry, format, resolution and file
size can be judged but type size cannot. That is why step one happens
before saving.

## In R Markdown or Quarto

A large share of academic figures never pass through
[`ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html) at
all: they come out of a knitr chunk at whatever `fig.width` happens to
be.

[`figspec_chunk_opts`](https://dansemakula.github.io/figspec/reference/figspec_chunk_opts.md)`(``"cell_press"``, ``"double"``)`` ``#> $fig.width`` ``#> [1] 6.850394`` ``#> `` ``#> $fig.height`` ``#> [1] 5.137795`` ``#> `` ``#> $dpi`` ``#> [1] 300`` ``#> `` ``#> $dev`` ``#> [1] "tiff"`

Put that in a setup chunk with
`figspec_knitr_setup("cell_press", "double")` and every figure in the
document is emitted at the journal’s size.

## When the paper is rejected

The next journal has different rules, and they can be incompatible: Cell
Press wants type between 6 and 8 pt, PLOS ONE between 8 and 12.

[`refit_journal`](https://dansemakula.github.io/figspec/reference/refit_journal.md)`(``my_plots``, journal ``=`` ``"plos_one"``, outdir ``=`` ``"figures_plos/"``)`

[`refit_journal()`](https://dansemakula.github.io/figspec/reference/refit_journal.md)
re-themes and re-exports the set. It works from plot objects and refuses
saved files, because type size cannot be recovered from a finished TIFF
and a re-fitted file could not be trusted.

## Other display items

Journals set rules for other display items too.

[`graphical_abstract_spec`](https://dansemakula.github.io/figspec/reference/graphical_abstract_spec.md)`(``"rsc"``)`` ``#> `` ``#> ``──`` ``Royal Society of Chemistry journals - graphical abstract`` ``────────────────────`` ``#> • ``Maximum size:`` 80 x 40 mm`` ``#> • ``Resolution:`` 600 dpi`` ``#> • ``Formats:`` TIFF`` ``#> • ``Text limit:`` 250 characters`` ``#> `` ``#> ``The figure should be a maximum size of 8 cm wide x 4 cm high ... Figures should`` ``#> ``be supplied as TIFF files, with a resolution of 600 dpi or greater ... The text`` ``#> ``supplied should be 1-2 sentences long, using a maximum of 250 characters.`` ``#> `` ``#> ``Source:`` ``#> ``<https://www.rsc.org/publishing/publish-with-us/publish-a-journal-article/chem-soc-rev>`` ``#> (verified 2026-08-22)`

[`table_spec()`](https://dansemakula.github.io/figspec/reference/table_spec.md)
and
[`media_spec()`](https://dansemakula.github.io/figspec/reference/media_spec.md)
do the same for tables and for supplementary video and audio.

## Where figspec hands the judgement back to you

Where a publisher never said what compliance means, figspec reports the
silence. It leaves a pixel size in pixels until a resolution arrives to
convert it with. It reports a recommendation as a recommendation. And
when type size is the question it asks for the plot object, since a
saved raster has already turned that into pixels.

Each of those is a moment where the honest answer is “check this
yourself”, and figspec says so plainly instead of filling the gap with a
guess.

The same rule governs what figspec will *not* claim. Panel consistency
across a set of figures is reported, because it is measurable and it is
usually what an author is trying to fix — but never as a pass or a
failure, because no publisher asks for it. A green tick against an
invented rule would be the same error as inventing the rule.

## Where to go next

- [`vignette("panels")`](https://dansemakula.github.io/figspec/articles/panels.md)
  — sizing by the plot panel rather than the image, and making a set of
  figures match.
- [`vignette("journals")`](https://dansemakula.github.io/figspec/articles/journals.md)
  — every entry in the registry, and how complete each one is.
- [`vignette("options")`](https://dansemakula.github.io/figspec/articles/options.md)
  — every function and what its arguments do.
