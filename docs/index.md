# figspec

**figspec enables researchers and other R users to build, export and
verify figures and tables against the specifications their work must
meet.** It brings those requirements into R, reducing the time spent
searching through guidance, interpreting rules and applying them by
hand. The specification can come from a publication, an organisation or
the needs of a particular project. figspec can work with one item or
review figures and tables together.

## From specified requirements to compliant files

figspec provides one repeatable workflow:

**Define the required result → apply a specification → export it
correctly → verify the finished files → Save specification →
Reuse/Repeat.**

That workflow is especially valuable when preparing many figures and
tables, changing journals, maintaining an organisational style or
producing the same kind of report repeatedly.

Individuals and teams can extend figspec without modifying the package.
Their own requirements and visual styles can be named, saved with a
project and loaded in later R sessions, giving repeated work the same
rules and appearance.

Three recurring needs explain why these capabilities belong together.

## The need for figures that meet journal requirements

Journals set detailed rules for submitted figures, including column
widths, minimum resolution, accepted formats, text sizes, line weights,
colour use and panel labels. These rules differ between publishers and
are often scattered across several pages of author guidance. A figure
prepared for one journal may therefore need substantial changes when a
paper is submitted elsewhere, or resubmitted after rejection.

figspec brings these requirements into R, where they can be applied
while the figure is still editable. Its registry currently contains 29
carefully sourced profiles: 22 cover publisher-wide guidance and seven
cover individual journals with their own requirements. The
publisher-wide profiles apply across large journal portfolios, including
those of Elsevier, Springer, Wiley, Taylor & Francis, Oxford University
Press, Cambridge University Press, Cell Press, BMJ, Frontiers, IEEE and
other major publishers, so the registry reaches far beyond 29 individual
titles. Journal-specific rules can be added where they differ from the
publisher default.

Every recorded requirement is linked to the publisher’s guidance and
includes the date it was verified. Each profile also distinguishes
between a field the source does not mention and one that is still
awaiting review. Users can therefore see exactly what information
supports each result.

Preparation rarely stops at one plot.
[`submission_check()`](https://dansemakula.github.io/figspec/reference/submission_check.md)
can review a directory of finished files or a named collection of
figures and tables, give each item a concise result and retain its
detailed report.
[`graphical_abstract_spec()`](https://dansemakula.github.io/figspec/reference/graphical_abstract_spec.md)
and
[`media_spec()`](https://dansemakula.github.io/figspec/reference/media_spec.md)
surface requirements for other publication assets.
[`media_check()`](https://dansemakula.github.io/figspec/reference/media_check.md)
can inspect an actual video or audio file for properties such as its
format, frame size, file size, codec and bit rate.

## The need for tables that meet their specifications

Tables often have separate requirements for file format, editability,
page orientation, width, type size, headings and rules. A publication
may ask for an editable Word table in portrait orientation, while a
report or organisation may have its own typography and layout. These
requirements need to be applied to the table itself; treating the table
as an image would discard the structure that makes it editable.

figspec accepts data frames, matrices and tables made with gt,
flextable, kableExtra and grid. It applies the measurable requirements
that each table system supports, exports through that system and reopens
the completed file for verification. HTML, DOCX, RTF, TeX, PDF and image
outputs are available where the selected table system supports them.
Requirements that need someone to read the table—such as whether its
title is concise or every abbreviation is defined—remain clearly marked
for review. Bundled publication profiles can be used when their table
guidance has been reviewed, and project or organisational table
specifications can be supplied directly in R.

## The need for figures with consistent panel sizes

R can set the overall dimensions of an image, but it does not normally
control the exact size of the plot area inside it. As a result, a figure
with long axis labels or a large legend can have a smaller plotting area
than a simpler figure saved at the same width. Place those figures
together in a paper, report or presentation, and their axes and data
panels may no longer align.

figspec can size the plot panel directly and calculate the canvas needed
around it. A set of figures can therefore share the same plotting area
even when their titles, labels, legends and margins differ. This is
useful for journal submissions, but also for reports, presentations and
any project where figures need to be produced consistently.

Together, these tools make figure and table preparation more deliberate,
consistent and reproducible: define the result you need, build to that
specification, and verify the finished output before it leaves R.

figspec accepts figures made with ggplot2, base R, lattice, grid and
Plotly. It applies the requirements that each plotting system makes
available, exports the result at the requested size and verifies the
finished file. Exact panel sizing and the most detailed checks remain
available for ggplot2-compatible figures because those objects expose
their complete panel and layer structure. A palette stored in a
specification’s optional `house_style` section is used across ggplot2,
base R, lattice and Plotly where the plotting system exposes its colour
settings. A registered house style is different: it is a reusable
ggplot2 theme for choices such as the grid, background and legend
position. The [cross-system
guide](https://dansemakula.github.io/figspec/articles/figure-systems.html)
shows the calling pattern, completed output and limits for each system.

## Installation

Until the first CRAN release, install figspec from GitHub:

[`install.packages`](https://rdrr.io/r/utils/install.packages.html)`(``"pak"``)`` ``pak``::`[`pak`](https://pak.r-lib.org/reference/pak.html)`(``"dansemakula/figspec"``)`

Once figspec is available on CRAN, it can be installed with:

[`install.packages`](https://rdrr.io/r/utils/install.packages.html)`(``"figspec"``)`

figspec is ready for practical use and is being improved continuously.
Publisher guidance is rechecked as it changes, and new profiles and
requirements are added through a documented review process.
[`registry_status()`](https://dansemakula.github.io/figspec/reference/registry_status.md)
shows what has been verified, confirmed absent or not yet reviewed for
every profile.

## Quick start

Start with an ordinary ggplot:

[`library`](https://rdrr.io/r/base/library.html)`(`[`ggplot2`](https://ggplot2.tidyverse.org)`)`` `[`library`](https://rdrr.io/r/base/library.html)`(`[`figspec`](https://dansemakula.github.io/figspec/)`)`` `` ``p`` ``<-`` `[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(`` `` ``mtcars``,`` `` `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``wt``, ``mpg``, colour ``=`` `[`factor`](https://rdrr.io/r/base/factor.html)`(``cyl``)``, shape ``=`` `[`factor`](https://rdrr.io/r/base/factor.html)`(``cyl``)``)`` ``)`` ``+`` `` `[`geom_point`](https://ggplot2.tidyverse.org/reference/geom_point.html)`(``)`` ``+`` `` `[`labs`](https://ggplot2.tidyverse.org/reference/labs.html)`(`` `` x ``=`` ``"Weight (1000 lbs)"``,`` `` y ``=`` ``"Miles per gallon"``,`` `` colour ``=`` ``"Cylinders"``,`` `` shape ``=`` ``"Cylinders"`` `` ``)`

### 1. Apply a specification

Add a journal profile as you would add another ggplot2 component:

`fitted`` ``<-`` ``p`` ``+`` `[`fig_apply_spec`](https://dansemakula.github.io/figspec/reference/fig_apply_spec.md)`(``"cell_press"``)`

[`fig_apply_spec()`](https://dansemakula.github.io/figspec/reference/fig_apply_spec.md)
applies the requirements that can be expressed in the plot, including
typography, line settings, structural rules, colours and shapes. When a
specification contains an optional `house_style$palette`, figspec uses
that palette without treating it as a pass-or-fail requirement. For
ggplot2, set `colour = FALSE` when you instead need to preserve colour
scales already attached to the plot.

### 2. Verify the figure

`report`` ``<-`` `[`fig_check`](https://dansemakula.github.io/figspec/reference/fig_check.md)`(``fitted``, ``"cell_press"``, column ``=`` ``"single"``)`` ``report`

[`fig_check()`](https://dansemakula.github.io/figspec/reference/fig_check.md)
returns one result for each relevant requirement. It identifies what
meets the specification, what needs to change and what needs more
information. Check the editable plot before export to assess text size,
line weight and colour relationships. Then check the saved file to
confirm its dimensions, resolution and format.

### 3. Export and check the finished file

[`fig_save`](https://dansemakula.github.io/figspec/reference/fig_save.md)`(`` `` ``"figure_1.tiff"``,`` `` ``fitted``,`` `` spec ``=`` ``"cell_press"``,`` `` column ``=`` ``"single"`` ``)`

[`fig_save()`](https://dansemakula.github.io/figspec/reference/fig_save.md)
takes the final width and resolution from the specification, uses an
appropriate graphics device and checks the file it writes. Exporting at
the intended publication size matters because resizing later also
changes the apparent size of text and lines.

### Build and check a table

A table specification can come from your project or from a publication
profile where table requirements have been reviewed:

`report_spec`` ``<-`` `[`list`](https://rdrr.io/r/base/list.html)`(`` `` name ``=`` ``"Research report"``,`` `` tables ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(`` `` formats ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"html"``, ``"docx"``)``,`` `` font_min_pt ``=`` ``9``,`` `` header_bold ``=`` ``TRUE``,`` `` vertical_rules ``=`` ``FALSE`` `` ``)`` ``)`` `` ``summary_table`` ``<-`` `[`table_apply_spec`](https://dansemakula.github.io/figspec/reference/table_apply_spec.md)`(`[`head`](https://rdrr.io/r/utils/head.html)`(``mtcars``)``, ``report_spec``)`` `[`table_check`](https://dansemakula.github.io/figspec/reference/table_check.md)`(``summary_table``, ``report_spec``)`` `[`table_save`](https://dansemakula.github.io/figspec/reference/table_save.md)`(``"summary-table.html"``, ``summary_table``, ``report_spec``)`

The first call keeps the table editable and applies the requirements its
table system can express. The final call writes a real file, reopens it,
and combines what can be verified from the file with what remains known
from the editable table. See [Build and check tables from
R](https://dansemakula.github.io/figspec/articles/tables.html) for
complete examples.

## Size the panel, and the figure

Two image files can have the same width while leaving different amounts
of space for the data. A long axis title, a legend or a multi-line label
reduces the plotting area inside the image.

[`fig_save`](https://dansemakula.github.io/figspec/reference/fig_save.md)`(`` `` ``"figure_1.png"``,`` `` ``p``,`` `` panel_width ``=`` ``62``,`` `` units ``=`` ``"mm"``,`` `` dpi ``=`` ``300`` ``)`

Here, the plot panel—not the complete image—is 62 mm wide. figspec
measures the labels, legends and margins and calculates the canvas
needed around it.
[`fig_panel_width()`](https://dansemakula.github.io/figspec/reference/fig_panel_width.md)
can also determine a shared panel width for a collection of figures. See
[Control figure and panel
dimensions](https://dansemakula.github.io/figspec/articles/panels.html)
for worked examples.

## Understanding verification results

figspec uses five outcomes so that missing information is never mistaken
for compliance:

| Outcome | Meaning |
|----|----|
| pass | The figure or table meets the stated requirement. |
| fail | The figure or table does not meet the requirement and needs attention. |
| unspecified | The specification does not state a requirement for this property. |
| unknown | The requirement needs information from another input or a manual check. |
| invalid | The file is corrupt or does not match its stated format. |

From a plot object, figspec can examine typography, line and point
weights, colour relationships, panel labels, axis rules and other visual
properties. From an exported file, it can verify properties such as
dimensions, resolution, format, file size and selected format-specific
requirements. For tables, it combines properties retained by the
editable object with the format and structure of the completed file. An
`unknown` result identifies the information that the supplied plot or
file does not contain. The report then shows what still needs to be
checked from the editable object, the source guidance or another file
property.

## Journal and publisher profiles

The built-in registry contains **29 profiles across 21 disciplines**.
Twenty-two profiles cover publisher-wide guidance and therefore apply
across complete journal portfolios; seven represent journals with their
own requirements. Publisher-wide profiles act as defaults, and
journal-specific guidance should take precedence whenever a title states
a different rule.

[`spec_list`](https://dansemakula.github.io/figspec/reference/spec_list.md)`(``discipline ``=`` ``"physics"``)`` `[`spec_get`](https://dansemakula.github.io/figspec/reference/spec_get.md)`(``"cell_press"``)`` `[`fig_columns`](https://dansemakula.github.io/figspec/reference/fig_columns.md)`(``"science"``)`` `[`registry_status`](https://dansemakula.github.io/figspec/reference/registry_status.md)`(``)`

Every recorded requirement includes its publisher source and
verification date. The registry distinguishes requirements that have
been verified, requirements that a publisher explicitly does not state
and fields that have not yet been reviewed. This prevents incomplete
information from being presented as a pass.

Table guidance is reviewed separately from figure guidance. At present,
the bundled registry contains table requirements only for profiles whose
table instructions have been recorded;
[`registry_status()`](https://dansemakula.github.io/figspec/reference/registry_status.md)
shows this coverage in the `table_stated`, `table_confirmed_absent` and
`table_unreviewed` columns. You can use the full table workflow
immediately with a project or organisational specification.

Browse the [complete profile
table](https://dansemakula.github.io/figspec/articles/journals.html) or
read [how the registry is reviewed and
maintained](https://dansemakula.github.io/figspec/articles/registry.html).

## Use your own requirements and style

figspec is not limited to its built-in journal profiles. You can supply
your own requirements, register an internal publication format or reuse
a house style across projects.

These are two different kinds of reusable extension:

| What you want to reuse | What it contains | Save and restore it with |
|----|----|----|
| A specification | Requirements that a finished figure or table must meet, with an optional cross-system palette | [`spec_save()`](https://dansemakula.github.io/figspec/reference/spec_save.md) and [`spec_load()`](https://dansemakula.github.io/figspec/reference/spec_load.md) |
| A registered house style | A reusable ggplot2 theme for choices such as the grid, background and legend position | [`style_save()`](https://dansemakula.github.io/figspec/reference/style_save.md) and [`style_load()`](https://dansemakula.github.io/figspec/reference/style_load.md) |

A requirement in a specification can determine whether work passes or
fails. Optional palettes and registered house styles record visual
choices, so they shape appearance without becoming compliance rules.
When a ggplot2 theme and requirements are used together, figspec retains
compatible theme choices and applies the stated requirements wherever
they are needed.

[`style_register`](https://dansemakula.github.io/figspec/reference/style_register.md)`(`` `` ``"mylab"``,`` `` `[`theme_minimal`](https://ggplot2.tidyverse.org/reference/ggtheme.html)`(``)`` ``+`` `[`theme`](https://ggplot2.tidyverse.org/reference/theme.html)`(``panel.grid.minor ``=`` `[`element_blank`](https://ggplot2.tidyverse.org/reference/element.html)`(``)``)``,`` `` description ``=`` ``"Our group's figure style"`` ``)`` `` ``p`` ``+`` `[`fig_apply_spec`](https://dansemakula.github.io/figspec/reference/fig_apply_spec.md)`(``"frontiers"``, style ``=`` ``"mylab"``)`

Your house style controls the appearance of the figure wherever the
specification is silent. If a style setting conflicts with a stated
requirement—for example, 6 pt text when the minimum is 8 pt—figspec
applies the required value and leaves the rest of the design unchanged.

Custom specifications can be kept under version control and loaded when
a project starts.
[`spec_save()`](https://dansemakula.github.io/figspec/reference/spec_save.md)
writes or safely updates the project YAML file, and
[`spec_load()`](https://dansemakula.github.io/figspec/reference/spec_load.md)
makes its entries available in a later R session:

`report_spec`` ``<-`` `[`list`](https://rdrr.io/r/base/list.html)`(`` `` name ``=`` ``"Research unit report"``,`` `` columns ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(``full ``=`` ``160``)``,`` `` dpi_min ``=`` ``300``,`` `` formats ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"png"``, ``"pdf"``)``,`` `` house_style ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(`` `` palette ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"#76549A"``, ``"#D99000"``, ``"#2B78A6"``)`` `` ``)`` ``)`` `` `[`spec_save`](https://dansemakula.github.io/figspec/reference/spec_save.md)`(`` `` ``report_spec``,`` `` ``"project-specifications.yml"``,`` `` id ``=`` ``"research_unit_report"`` ``)`` `[`spec_load`](https://dansemakula.github.io/figspec/reference/spec_load.md)`(``"project-specifications.yml"``)`

The optional palette travels with the specification, so supported
plotting systems can use the same purple, amber and blue identity.
[`fig_check()`](https://dansemakula.github.io/figspec/reference/fig_check.md)
treats it as a design preference, leaving pass-or-fail decisions to the
requirements recorded in the specification.

The registry marks user-defined profiles with their origin, making them
easy to distinguish from profiles maintained by figspec. They extend the
current R session without changing the installed package.

For a project or research team, keep the files in a predictable folder:

```
project/
├── config/
│   └── figspec/
│       ├── specifications.yml
│       └── styles.rds
└── analysis.R
```

Save registered house styles with:

[`dir.create`](https://rdrr.io/r/base/files2.html)`(`[`file.path`](https://rdrr.io/r/base/file.path.html)`(``"config"``, ``"figspec"``)``, recursive ``=`` ``TRUE``,`` `` showWarnings ``=`` ``FALSE``)`` `` `[`style_save`](https://dansemakula.github.io/figspec/reference/style_save.md)`(`[`file.path`](https://rdrr.io/r/base/file.path.html)`(``"config"``, ``"figspec"``, ``"styles.rds"``)``)`

Then load both files at the beginning of an analysis, in a project setup
script or in the first code chunk of an R Markdown or Quarto document:

[`library`](https://rdrr.io/r/base/library.html)`(`[`figspec`](https://dansemakula.github.io/figspec/)`)`` `` `[`spec_load`](https://dansemakula.github.io/figspec/reference/spec_load.md)`(`[`file.path`](https://rdrr.io/r/base/file.path.html)`(``"config"``, ``"figspec"``, ``"specifications.yml"``)``)`` `[`style_load`](https://dansemakula.github.io/figspec/reference/style_load.md)`(`[`file.path`](https://rdrr.io/r/base/file.path.html)`(``"config"``, ``"figspec"``, ``"styles.rds"``)``)`

The paths are relative to the project directory, so the same code works
even when team members keep the project in different locations on their
computers.

Each team member has a separate R installation and a separate local copy
of the project. Git records changes, while GitHub or another Git hosting
service stores the shared repository. Add `.Rprofile` and the two files
under `config/figspec/` to that repository, commit them and push the
commit. A new team member clones the repository once. After that, one
person can update a specification or style, commit and push the change,
and everyone else receives it by pulling the latest changes into their
own project copy.

When someone opens the project, their own R installation reads the local
`.Rprofile` and loads the local copies of the figspec files. If they
pull an update while R is already running, they should restart R or run
[`spec_load()`](https://dansemakula.github.io/figspec/reference/spec_load.md)
and
[`style_load()`](https://dansemakula.github.io/figspec/reference/style_load.md)
again. The team is not sharing one running R session: GitHub holds the
shared files, and Git places a copy on each computer. Every computer
must have figspec installed. A project using `renv` can record the
package version so everyone uses the same release.

Teams that want these files loaded automatically can place the two load
calls in the project’s `.Rprofile`. A setup script is often easier to
see and debug, whereas `.Rprofile` is useful when every R session in the
project must have the same names available. Because `.Rprofile` is
executable R code, review changes to it and never store passwords,
access tokens or other secrets in it. Load an RDS style file only from a
repository controlled by people you trust; stored theme functions remain
blocked unless `allow_functions = TRUE` is explicitly requested.

An organisation with many specifications, styles and helper functions
can put them in a small internal R package that imports figspec.

## More publication workflows

The same specification can be used throughout a project:

- [`submission_check()`](https://dansemakula.github.io/figspec/reference/submission_check.md)
  reviews a directory or named collection of figures and tables and
  summarizes what needs attention.
- [`fig_refit()`](https://dansemakula.github.io/figspec/reference/fig_refit.md)
  adapts and re-exports saved plot objects when a manuscript moves to a
  journal with different requirements.
- [`figspec_knitr_setup()`](https://dansemakula.github.io/figspec/reference/figspec_knitr_setup.md)
  applies dimensions and resolution consistently in Quarto and R
  Markdown documents.
- [`graphical_abstract_spec()`](https://dansemakula.github.io/figspec/reference/graphical_abstract_spec.md),
  [`media_spec()`](https://dansemakula.github.io/figspec/reference/media_spec.md)
  and
  [`media_check()`](https://dansemakula.github.io/figspec/reference/media_check.md)
  surface separate requirements for graphical abstracts, video and
  audio.
- [`table_apply_spec()`](https://dansemakula.github.io/figspec/reference/table_apply_spec.md),
  [`table_save()`](https://dansemakula.github.io/figspec/reference/table_save.md)
  and
  [`table_check()`](https://dansemakula.github.io/figspec/reference/table_check.md)
  provide the corresponding build, export and verification workflow for
  tables.
- [`fig_suggest_art_type()`](https://dansemakula.github.io/figspec/reference/fig_suggest_art_type.md)
  helps identify which resolution rule is relevant when a publisher
  distinguishes colour, grayscale, line and combination artwork.

These functions report the evidence they can establish and collect the
items that still require judgement. When a source gives no requirement,
the report marks that property as unspecified and leaves the decision
with the user.

## Function families

The complete public API is organised around the work a user needs to
complete:

| Task | What figspec provides | Functions |
|----|----|----|
| Build, export and verify figures | Apply reachable requirements while a figure is editable, write the requested format and inspect the completed file | [`fig_apply_spec()`](https://dansemakula.github.io/figspec/reference/fig_apply_spec.md), [`theme_spec()`](https://dansemakula.github.io/figspec/reference/theme_spec.md), [`fig_save()`](https://dansemakula.github.io/figspec/reference/fig_save.md), [`fig_check()`](https://dansemakula.github.io/figspec/reference/fig_check.md), [`fig_preview()`](https://dansemakula.github.io/figspec/reference/fig_preview.md), [`fig_geometry()`](https://dansemakula.github.io/figspec/reference/fig_geometry.md) |
| Size and align plotting areas | Set the physical size of the data panel, find a shared panel width and retrieve stated publication widths | [`fig_panel_size()`](https://dansemakula.github.io/figspec/reference/fig_panel_size.md), [`fig_panel_width()`](https://dansemakula.github.io/figspec/reference/fig_panel_width.md), [`fig_width()`](https://dansemakula.github.io/figspec/reference/fig_width.md), [`fig_columns()`](https://dansemakula.github.io/figspec/reference/fig_columns.md) |
| Improve visual distinction | Use accessible colours, shapes, line types and weights; preserve an optional project palette; and check whether groups remain distinguishable | [`figspec_palettes()`](https://dansemakula.github.io/figspec/reference/figspec_palettes.md), [`figspec_palette()`](https://dansemakula.github.io/figspec/reference/figspec_palette.md), [`scale_colour_figspec()`](https://dansemakula.github.io/figspec/reference/scale_colour_figspec.md), [`scale_fill_figspec()`](https://dansemakula.github.io/figspec/reference/scale_fill_figspec.md), [`scale_shape_figspec()`](https://dansemakula.github.io/figspec/reference/scale_shape_figspec.md), [`figspec_shapes()`](https://dansemakula.github.io/figspec/reference/figspec_shapes.md), [`figspec_linetypes()`](https://dansemakula.github.io/figspec/reference/figspec_linetypes.md), [`spec_linewidth()`](https://dansemakula.github.io/figspec/reference/spec_linewidth.md), [`colour_safety_check()`](https://dansemakula.github.io/figspec/reference/colour_safety_check.md), [`fig_tag_panels()`](https://dansemakula.github.io/figspec/reference/fig_tag_panels.md), [`spec_style_palette()`](https://dansemakula.github.io/figspec/reference/spec_style_palette.md) |
| Find, create and reuse specifications and styles | Use a bundled profile or save project and organisational requirements and ggplot2 themes for later sessions or team use | [`spec_list()`](https://dansemakula.github.io/figspec/reference/spec_list.md), [`spec_get()`](https://dansemakula.github.io/figspec/reference/spec_get.md), [`spec_register()`](https://dansemakula.github.io/figspec/reference/spec_register.md), [`spec_save()`](https://dansemakula.github.io/figspec/reference/spec_save.md), [`spec_load()`](https://dansemakula.github.io/figspec/reference/spec_load.md), [`style_register()`](https://dansemakula.github.io/figspec/reference/style_register.md), [`style_list()`](https://dansemakula.github.io/figspec/reference/style_list.md), [`style_remove()`](https://dansemakula.github.io/figspec/reference/style_remove.md), [`style_save()`](https://dansemakula.github.io/figspec/reference/style_save.md), [`style_load()`](https://dansemakula.github.io/figspec/reference/style_load.md) |
| Review a complete body of work | Check mixed collections of figures and tables, inspect one result in detail, choose an artwork rule and adapt editable figures to another specification | [`submission_check()`](https://dansemakula.github.io/figspec/reference/submission_check.md), [`submission_detail()`](https://dansemakula.github.io/figspec/reference/submission_detail.md), [`fig_suggest_art_type()`](https://dansemakula.github.io/figspec/reference/fig_suggest_art_type.md), [`fig_refit()`](https://dansemakula.github.io/figspec/reference/fig_refit.md) |
| Build, export and verify tables | Apply measurable requirements to supported R table objects, retain editability and check the written output | [`table_spec()`](https://dansemakula.github.io/figspec/reference/table_spec.md), [`table_apply_spec()`](https://dansemakula.github.io/figspec/reference/table_apply_spec.md), [`table_save()`](https://dansemakula.github.io/figspec/reference/table_save.md), [`table_check()`](https://dansemakula.github.io/figspec/reference/table_check.md) |
| Work with other publication assets | Retrieve graphical-abstract and media requirements and inspect supplementary video or audio | [`graphical_abstract_spec()`](https://dansemakula.github.io/figspec/reference/graphical_abstract_spec.md), [`media_spec()`](https://dansemakula.github.io/figspec/reference/media_spec.md), [`media_check()`](https://dansemakula.github.io/figspec/reference/media_check.md) |
| Use the workflow in reports | Carry figure dimensions and resolution into R Markdown and Quarto | [`figspec_knitr_options()`](https://dansemakula.github.io/figspec/reference/figspec_knitr_options.md), [`figspec_knitr_setup()`](https://dansemakula.github.io/figspec/reference/figspec_knitr_setup.md) |
| Inspect and maintain the registry | Measure coverage, find profiles due for review, recheck sources and validate proposed registry files | [`registry_status()`](https://dansemakula.github.io/figspec/reference/registry_status.md), [`registry_stale_entries()`](https://dansemakula.github.io/figspec/reference/registry_stale_entries.md), [`registry_check_sources()`](https://dansemakula.github.io/figspec/reference/registry_check_sources.md), [`registry_entry_template()`](https://dansemakula.github.io/figspec/reference/registry_entry_template.md), [`registry_validate_file()`](https://dansemakula.github.io/figspec/reference/registry_validate_file.md) |

The package also provides
[`color_safety_check()`](https://dansemakula.github.io/figspec/reference/colour_safety_check.md)
and
[`scale_color_figspec()`](https://dansemakula.github.io/figspec/reference/scale_colour_figspec.md)
as American-English aliases. The [complete function
reference](https://dansemakula.github.io/figspec/reference/index.html)
uses the same task-based groups and provides the arguments and examples
for every function.

## Learn more

- [Getting started with
  figspec](https://dansemakula.github.io/figspec/articles/figspec.html)
- [Use figspec with different R plotting
  systems](https://dansemakula.github.io/figspec/articles/figure-systems.html)
- [Control figure and panel
  dimensions](https://dansemakula.github.io/figspec/articles/panels.html)
- [Build and check tables from
  R](https://dansemakula.github.io/figspec/articles/tables.html)
- [Journal and publisher
  profiles](https://dansemakula.github.io/figspec/articles/journals.html)
- [Every function and its
  options](https://dansemakula.github.io/figspec/articles/options.html)
- [Complete function
  reference](https://dansemakula.github.io/figspec/reference/index.html)
- [Registry provenance and
  maintenance](https://dansemakula.github.io/figspec/articles/registry.html)
- [Contributing to
  figspec](https://dansemakula.github.io/figspec/CONTRIBUTING.md)

## Licence

figspec is released under the [GNU General Public License version 3 or
later](https://dansemakula.github.io/figspec/LICENSE.md). Registry
entries include short quotations from publisher guidance for
verification and attribution. Publishers retain any rights they hold in
their original wording.

When relying on a requirement, consult the linked publisher guidance as
the authoritative source. `spec_get(<id>)$source_url` provides that link
and `$verified_on` records when it was reviewed.
