# Find and use publication specifications

figspec includes a registry of carefully sourced figure requirements
from major publishers and selected journals. It currently contains 29
profiles: 22 record publisher-wide guidance that applies across large
journal portfolios, while seven cover individual journals with their own
requirements.

Each recorded requirement includes the page from which it was taken and
the date on which that page was reviewed. A missing value is never
treated as permission or as a passing result: figspec distinguishes a
requirement that the source does not state from one that has not yet
been reviewed for that profile.

The registry is optional. You can also supply requirements maintained by
your project or organisation, or load a registry file maintained by your
team. A house style is different: it controls visual choices, while a
specification defines requirements that can be checked.

## Find a relevant profile

[`spec_list()`](https://dansemakula.github.io/figspec/reference/spec_list.md)
lists the available publisher and journal profiles. Use the registry ID
in functions such as
[`spec_get()`](https://dansemakula.github.io/figspec/reference/spec_get.md),
[`fig_apply_spec()`](https://dansemakula.github.io/figspec/reference/fig_apply_spec.md),
[`fig_save()`](https://dansemakula.github.io/figspec/reference/fig_save.md)
and
[`fig_check()`](https://dansemakula.github.io/figspec/reference/fig_check.md).
You can list everything or narrow the results by discipline:

`physics_profiles`` ``<-`` `[`spec_list`](https://dansemakula.github.io/figspec/reference/spec_list.md)`(``discipline ``=`` ``"physics"``)`` ``knitr``::`[`kable`](https://rdrr.io/pkg/knitr/man/kable.html)`(`` `` ``physics_profiles``[``, `[`c`](https://rdrr.io/r/base/c.html)`(`` `` ``"id"``, ``"name"``, ``"publisher"``, ``"single_mm"``, ``"double_mm"``, ``"verified_on"`` `` ``)``]``,`` `` col.names ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(`` `` ``"Registry ID"``, ``"Profile"``, ``"Publisher"``, ``"Single (mm)"``, ``"Double (mm)"``,`` `` ``"Verified"`` `` ``)``,`` `` row.names ``=`` ``FALSE`` ``)`

| Registry ID | Profile | Publisher | Single (mm) | Double (mm) | Verified |
|:---|:---|:---|---:|---:|:---|
| iop | IOP Publishing journals | IOP Publishing | 85 | 150 | 2026-08-21 |
| aps | American Physical Society journals | American Physical Society | 85 | NA | 2026-04-04 |

A publisher-wide profile is appropriate when a journal follows that
publisher’s central figure guidance. Use a journal-specific profile when
the journal publishes additional or different requirements. Always
follow any instructions supplied directly by the journal for the article
you are preparing.

## Inspect a profile before using it

[`spec_get()`](https://dansemakula.github.io/figspec/reference/spec_get.md)
presents the recorded requirements, source and verification date
together.
[`fig_columns()`](https://dansemakula.github.io/figspec/reference/fig_columns.md)
extracts the available figure widths when that is all you need:

`cell_press`` ``<-`` `[`spec_get`](https://dansemakula.github.io/figspec/reference/spec_get.md)`(``"cell_press"``)`` ``cell_press`` ``#> `` ``#> ``──`` ``Cell Press journals`` ``─────────────────────────────────────────────────────────`` ``#> ``Publisher:`` Cell Press (Elsevier)`` ``#> ``Disciplines:`` life-sciences, biomedical`` ``#> `` ``#> • ``Column widths:`` single 85 mm | onehalf 114 mm | double 174 mm`` ``#> • ``Max height:`` 200 mm`` ``#> • ``Minimum resolution:`` 300 dpi`` ``#> • ``Line-art resolution:`` 1000 dpi`` ``#> • ``File formats:`` TIFF, PDF, EPS, JPEG`` ``#> • ``Fonts:`` Arial`` ``#> • ``Type size:`` 6-8 pt`` ``#> • ``Colour mode:`` RGB`` ``#> • ``Max file size:`` 20 MB`` ``#> `` ``#> ``Cell Press also publishes a three-column format for previews and commentaries`` ``#> ``with widths 5.5 cm, 11.4 cm and 17.4 cm. Red and green should not be used`` ``#> ``together.`` ``#> `` ``#> ``Source:`` ``<https://www.cell.com/information-for-authors/figure-guidelines>`` ``#> ``Verified:`` 2026-08-21`` `[`fig_columns`](https://dansemakula.github.io/figspec/reference/fig_columns.md)`(``cell_press``)`` ``#> single onehalf double `` ``#> 85 114 174`

The returned specification is an ordinary R object. Pass it directly to
the rest of the figspec workflow, or use the shorter registry ID. Here
the selected profile is applied to all 234 observations in
[`ggplot2::mpg`](https://ggplot2.tidyverse.org/reference/mpg.html):

`profile_plot`` ``<-`` `[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(`` `` ``ggplot2``::`[`mpg`](https://ggplot2.tidyverse.org/reference/mpg.html)`,`` `` `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``displ``, ``hwy``, colour ``=`` `[`factor`](https://rdrr.io/r/base/factor.html)`(``cyl``)``, shape ``=`` `[`factor`](https://rdrr.io/r/base/factor.html)`(``cyl``)``)`` ``)`` ``+`` `` `[`geom_point`](https://ggplot2.tidyverse.org/reference/geom_point.html)`(``size ``=`` ``1.8``, alpha ``=`` ``0.72``)`` ``+`` `` `[`labs`](https://ggplot2.tidyverse.org/reference/labs.html)`(``x ``=`` ``"Engine displacement (litres)"``,`` `` y ``=`` ``"Highway fuel economy"``,`` `` colour ``=`` ``"Cylinders"``,`` `` shape ``=`` ``"Cylinders"``)`` ``+`` `` `[`fig_apply_spec`](https://dansemakula.github.io/figspec/reference/fig_apply_spec.md)`(``cell_press``)`` `` ``profile_plot`

![A coloured scatter plot of engine displacement and highway fuel
economy after applying the Cell Press
profile.](journals_files/figure-html/apply-profile-1.png)

Because the plot is still editable,
[`fig_check()`](https://dansemakula.github.io/figspec/reference/fig_check.md)
can assess its text, colour, shapes and layout as well as its intended
width:

`profile_result`` ``<-`` `[`fig_check`](https://dansemakula.github.io/figspec/reference/fig_check.md)`(``profile_plot``, ``cell_press``, column ``=`` ``"single"``)`` ``knitr``::`[`kable`](https://rdrr.io/pkg/knitr/man/kable.html)`(`` `` ``profile_result``[`` `` ``profile_result``$``check`` `[`%in%`](https://rdrr.io/r/base/match.html)` `[`c`](https://rdrr.io/r/base/c.html)`(`` `` ``"Width"``, ``"Type size"``, ``"Colour pairs"``, ``"Colour vision"``,`` `` ``"Redundant coding"`` `` ``)``,`` `` `[`c`](https://rdrr.io/r/base/c.html)`(``"check"``, ``"actual"``, ``"status"``)`` `` ``]``,`` `` row.names ``=`` ``FALSE`` ``)`

| check | actual | status |
|:---|:---|:---|
| Width | 85 mm | pass |
| Type size | smallest 6 pt, largest 6 pt | pass |
| Colour pairs | no red/green pairing | pass |
| Colour vision | separable under deuteranopia, protanopia and tritanopia | unspecified |
| Redundant coding | colours merge in greyscale but 4 shapes still separate the series | unspecified |

## Browse all included profiles

The compact table below is rebuilt from
[`spec_list()`](https://dansemakula.github.io/figspec/reference/spec_list.md)
and
[`spec_get()`](https://dansemakula.github.io/figspec/reference/spec_get.md)
whenever the website is generated. A dash keeps the overview readable;
inspect the profile to learn whether its source is silent on that
requirement or the field has not yet been reviewed.

View all 29 publication profiles

| Profile | Registry ID | Figure width (mm) | General dpi | Line-art dpi | Text size (pt) | Accepted formats |
|:---|:---|:---|:---|:---|:---|:---|
| American Chemical Society journals | acs | single 84.7, double 177.8 | 300 | 1200 | 4.5+ | – |
| American Geophysical Union journals | agu | – | – | – | – | JPEG, TIFF, EPS, PS, PDF |
| American Physical Society journals | aps | single 85 | – | – | – | – |
| BioMed Central journals | bmc | single 85, double 170 | 300 | – | – | EPS, PDF, DOC, PPT, TIFF, JPEG, PNG, BMP, CDX |
| BMJ journals | bmj | – | 300 | 1200 | – | TIFF, EPS, JPEG, PDF |
| Cambridge University Press journals | cambridge | – | 300 | 1000 | 9+ | TIFF, EPS, PDF, JPEG |
| Cell Press journals | cell_press | single 85, onehalf 114, double 174 | 300 | 1000 | 6–8 | TIFF, PDF, EPS, JPEG |
| Copernicus Publications journals | copernicus | 80–? | 300 | – | – | PDF, PS, EPS, JPEG, PNG, TIFF |
| Elsevier journals | elsevier | single 90, onehalf 140, double 190 | 300 | 1000 | 6+ | – |
| Frontiers journals | frontiers | single 85, double 180 | 300 | – | 8+ | TIFF, JPEG, EPS |
| IEEE journals | ieee | single 88.9, double 182 | 300 | 600 | – | PS, EPS, PDF |
| IEEE magazines | ieee_magazines | single 88.9, double 181.9 | 300 | 600 | – | PS, EPS, PDF, PNG, TIFF |
| IOP Publishing journals | iop | single 85, double 150 | – | – | 8–12 | EPS, PDF, TIFF, PNG, JPEG |
| Journal of Statistical Software | jss | – | – | – | – | PDF, PNG, JPEG |
| MDPI journals | mdpi | – | 600 | – | – | PNG, JPEG, TIFF |
| Nature | nature | single 89, double 183 | 300 | – | 5–7 | AI, EPS, PDF, PS, SVG, PSD, TIFF, PNG, JPEG, PPT, CDX |
| Oxford University Press journals | oup | – | 300 | 1200 | 7+ | – |
| PLOS ONE | plos_one | 66.8–190.5 | 300 | – | 8–12 | TIFF, EPS |
| PNAS | pnas | small 90, medium 110, large 180 | 300 | 1000 | 6–12 | TIFF, EPS, PDF, PPT |
| Royal Society journals | royal_society | – | – | – | 7.5+ | PNG, EPS, TIFF, JPEG |
| Royal Society of Chemistry books | rsc_books | ?–200 | 600 | – | – | TIFF, JPEG, PNG, EPS, PDF |
| Royal Society of Chemistry journals | rsc | single 83, double 171 | 600 | – | – | TIFF, EPS, PDF |
| Sage journals | sage | – | 300 | 800 | – | TIFF, JPEG, EPS |
| Science | science | single 57, double 121, triple 184 | 300 | – | 5+ | – |
| Springer journals | springer | single 84, double 174 | 300 | 1200 | 8–12 | EPS, TIFF |
| STAR Protocols | star_protocols | single 134, double 172 | – | – | – | JPEG |
| Taylor & Francis and Routledge journals | taylor_francis | – | 300 | 1200 | – | JPEG, TIFF, EPS |
| The Journal of Infectious Diseases | jid | – | 300 | 600 | – | TIFF, EPS |
| Wiley journals | wiley | single 80, double 180 | 300 | 600 | – | EPS, PDF, TIFF, PNG |

## How publication requirements differ

Publishers prepare figures for different page layouts, printing
processes and digital formats, so their requirements are not identical.
A figure that meets one publication’s guidance may therefore need
changes before it is submitted elsewhere. The registry records
differences such as these:

**Panel labels.** Cell Press asks for capital letters. AGU, Nature,
Springer and the Royal Society use lower-case letters. Nature specifies
upright labels, whereas the Royal Society specifies italics.

**Text in EPS files.** BMJ asks authors to outline text in EPS artwork.
Nature asks authors not to outline it.

**Line-art resolution.** Twelve profiles record a separate resolution
for line art. The recorded thresholds range from 600 dpi for IEEE and
Wiley to 1200 dpi for BMJ, ACS, OUP, Springer and Taylor & Francis,
compared with a common general minimum of 300 dpi. Where sources define
line art, they commonly describe monochrome artwork without shading.
[`fig_suggest_art_type()`](https://dansemakula.github.io/figspec/reference/fig_suggest_art_type.md)
helps select the applicable resolution rule.

**Colour in print.** Some publications accept or provide colour, while
others expect figures to remain readable when printed in greyscale. The
Royal Society, Sage and Taylor & Francis record black-and-white printing
as the default; RSC records free colour for journals, while its book
policy depends on the author’s contract.

These are production choices, not disagreements. figspec keeps them
separate so that the requirements applied to a figure match its intended
destination.

## Check what each profile covers

[`registry_status()`](https://dansemakula.github.io/figspec/reference/registry_status.md)
distinguishes three kinds of registry coverage:

- **Stated** means the source gives a requirement for that field.
- **Confirmed absent** means the source was reviewed but gives no
  requirement for that field.
- **Not yet harvested** means the field has not yet been reviewed or
  entered for that profile.

The categories account for every field tracked by the registry. Keeping
them separate prevents an unreviewed field from being mistaken for a
requirement that the publisher does not state.

View coverage for all 29 profiles

| Registry ID    | Stated | Confirmed absent | Not yet harvested | Verified   |
|:---------------|-------:|-----------------:|------------------:|:-----------|
| nature         |     16 |                0 |                19 | 2026-09-03 |
| plos_one       |     15 |                0 |                20 | 2026-08-21 |
| cell_press     |     15 |                0 |                20 | 2026-08-21 |
| springer       |     11 |                0 |                24 | 2026-08-22 |
| pnas           |     10 |                0 |                25 | 2026-08-22 |
| frontiers      |      8 |                1 |                26 | 2026-08-21 |
| taylor_francis |      8 |                1 |                26 | 2026-08-22 |
| cambridge      |      7 |                2 |                26 | 2026-08-21 |
| acs            |      7 |                0 |                28 | 2026-08-22 |
| oup            |      7 |                1 |                27 | 2026-08-23 |
| bmc            |      7 |                0 |                28 | 2026-09-03 |
| royal_society  |      6 |                2 |                27 | 2026-08-22 |
| elsevier       |      6 |                0 |                29 | 2026-08-22 |
| iop            |      5 |                3 |                27 | 2026-08-21 |
| wiley          |      5 |                2 |                28 | 2026-08-21 |
| ieee_magazines |      5 |                0 |                30 | 2026-08-22 |
| rsc_books      |      5 |                0 |                30 | 2026-08-22 |
| ieee           |      5 |                0 |                30 | 2026-08-22 |
| jid            |      5 |                0 |                30 | 2026-09-03 |
| copernicus     |      4 |                2 |                29 | 2026-08-21 |
| sage           |      4 |                1 |                30 | 2026-08-22 |
| bmj            |      4 |                0 |                31 | 2026-08-22 |
| rsc            |      4 |                0 |                31 | 2026-08-22 |
| star_protocols |      3 |                0 |                32 | 2026-08-21 |
| science        |      3 |                0 |                32 | 2026-08-22 |
| aps            |      2 |                0 |                33 | 2026-04-04 |
| agu            |      2 |                2 |                31 | 2026-08-22 |
| mdpi           |      2 |                1 |                32 | 2026-08-22 |
| jss            |      1 |                2 |                32 | 2026-08-21 |

## Use your own specification

Publication profiles are only one source of requirements. The same
functions accept a named list describing a report, thesis, presentation,
organisation or production workflow. This example defines a 160 mm
quarterly-report figure, builds a real plot from
[`ggplot2::mpg`](https://ggplot2.tidyverse.org/reference/mpg.html), and
applies the required text size:

`project_spec`` ``<-`` `[`spec_get`](https://dansemakula.github.io/figspec/reference/spec_get.md)`(`[`list`](https://rdrr.io/r/base/list.html)`(`` `` name ``=`` ``"Quarterly outcomes report"``,`` `` columns ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(``full ``=`` ``160``)``,`` `` formats ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"png"``, ``"pdf"``)``,`` `` dpi_min ``=`` ``300``,`` `` font_min_pt ``=`` ``9``,`` `` min_line_pt ``=`` ``0.5`` ``)``)`` `` ``project_colours`` ``<-`` `[`setNames`](https://rdrr.io/r/stats/setNames.html)`(`` `` `[`figspec_palette`](https://dansemakula.github.io/figspec/reference/figspec_palette.md)`(``"okabe_ito"``)``[`[`c`](https://rdrr.io/r/base/c.html)`(``6``, ``7``, ``4``)``]``,`` `` `[`c`](https://rdrr.io/r/base/c.html)`(``"4"``, ``"f"``, ``"r"``)`` ``)`` `` ``project_plot`` ``<-`` `[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(`` `` ``ggplot2``::`[`mpg`](https://ggplot2.tidyverse.org/reference/mpg.html)`,`` `` `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``displ``, ``hwy``, colour ``=`` ``drv``, shape ``=`` ``drv``)`` ``)`` ``+`` `` `[`geom_point`](https://ggplot2.tidyverse.org/reference/geom_point.html)`(``size ``=`` ``2``, alpha ``=`` ``0.72``)`` ``+`` `` `[`scale_colour_manual`](https://ggplot2.tidyverse.org/reference/scale_manual.html)`(``values ``=`` ``project_colours``)`` ``+`` `` `[`scale_shape_figspec`](https://dansemakula.github.io/figspec/reference/scale_shape_figspec.md)`(``)`` ``+`` `` `[`labs`](https://ggplot2.tidyverse.org/reference/labs.html)`(``x ``=`` ``"Engine displacement (litres)"``,`` `` y ``=`` ``"Highway fuel economy"``,`` `` colour ``=`` ``"Drive type"``,`` `` shape ``=`` ``"Drive type"``)`` ``+`` `` `[`theme_spec`](https://dansemakula.github.io/figspec/reference/theme_spec.md)`(``project_spec``, base_size ``=`` ``9``)`` `` ``project_plot`

![A coloured scatter plot of engine displacement and highway fuel
economy prepared for a quarterly report
specification.](journals_files/figure-html/custom-specification-1.png)

The example below writes an actual 300 dpi PNG, reopens it and checks
its saved properties against the project specification:

`project_file`` ``<-`` `[`tempfile`](https://rdrr.io/r/base/tempfile.html)`(``fileext ``=`` ``".png"``)`` `[`fig_save`](https://dansemakula.github.io/figspec/reference/fig_save.md)`(`` `` ``project_file``,`` `` ``project_plot``,`` `` spec ``=`` ``project_spec``,`` `` column ``=`` ``"full"``,`` `` dpi ``=`` ``300``,`` `` check ``=`` ``FALSE`` ``)`` `` ``project_result`` ``<-`` `[`fig_check`](https://dansemakula.github.io/figspec/reference/fig_check.md)`(``project_file``, ``project_spec``)`` ``knitr``::`[`kable`](https://rdrr.io/pkg/knitr/man/kable.html)`(`` `` ``project_result``[`` `` ``project_result``$``check`` `[`%in%`](https://rdrr.io/r/base/match.html)` `[`c`](https://rdrr.io/r/base/c.html)`(`` `` ``"File validity"``, ``"Width"``, ``"Resolution"``, ``"File format"`` `` ``)``,`` `` `[`c`](https://rdrr.io/r/base/c.html)`(``"check"``, ``"requirement"``, ``"actual"``, ``"status"``)`` `` ``]``,`` `` row.names ``=`` ``FALSE`` ``)`

| check         | requirement            | actual   | status |
|:--------------|:-----------------------|:---------|:-------|
| File validity | valid, readable file   | valid    | pass   |
| Width         | full 160 mm            | 159.9 mm | pass   |
| Resolution    | min 300 dpi for colour | 300 dpi  | pass   |
| File format   | PNG, PDF               | PNG      | pass   |

A field omitted from your own specification is reported as
**unspecified**. It is not called *not yet harvested*, because you
supplied the requirements and the omission is not a gap in figspec’s
review of a publication source.

Pass no specification at all and
[`fig_check()`](https://dansemakula.github.io/figspec/reference/fig_check.md)
becomes an inspection: it reports the figure’s size, resolution, format
and file size without assigning a pass or fail where no requirement was
provided.
