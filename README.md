# figspec

<!-- badges: start -->
<!-- Slots waiting on something outside the package. Each is written out and
     ready; uncomment the line when its condition is met, and keep this order,
     which runs from build health through reach to terms.

     Needs a GitHub Actions run:
[![R-CMD-check](https://github.com/dansemakula/figspec/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/dansemakula/figspec/actions/workflows/R-CMD-check.yaml)

     Needs the package to be on CRAN. Until then a version badge reads
     "not available" and a downloads badge reads zero, which is worse than
     showing nothing:
[![CRAN](https://www.r-pkg.org/badges/version/figspec)](https://CRAN.R-project.org/package=figspec)
[![CRAN checks](https://badges.cranchecks.info/worst/figspec.svg)](https://cran.r-project.org/web/checks/check_results_figspec.html)
[![Downloads](https://cranlogs.r-pkg.org/badges/figspec)](https://CRAN.R-project.org/package=figspec)
[![Total downloads](https://cranlogs.r-pkg.org/badges/grand-total/figspec)](https://CRAN.R-project.org/package=figspec)

     Needs a Zenodo deposit of a tagged release:
[![DOI](https://zenodo.org/badge/DOI/PLACEHOLDER.svg)](https://doi.org/PLACEHOLDER)
-->
[![Status: actively maintained](https://img.shields.io/badge/status-actively%20maintained-1f9254?style=flat-square)](https://github.com/dansemakula/figspec)
[![Coverage](https://img.shields.io/badge/coverage-86%25-1f9254?style=flat-square)](https://github.com/dansemakula/figspec)
[![Profiles](https://img.shields.io/badge/profiles-29-2b7fd4?style=flat-square)](https://dansemakula.github.io/figspec/articles/journals.html)
[![Licence: GPL-3.0-or-later](https://img.shields.io/badge/licence-GPLv3%2B-7b8b93?style=flat-square)](https://github.com/dansemakula/figspec/blob/main/LICENSE.md)
<!-- badges: end -->

**figspec enables researchers and other R users to build, export and verify
figures and tables against the specifications their work must meet.** It
brings those requirements into R, reducing the time spent searching through
guidance, interpreting rules and applying them by hand. The specification can
come from a publication, an organisation or the needs of a particular project.
figspec can work with one item or review figures and tables together.

## From specified requirements to compliant files

figspec provides one repeatable workflow:

**Define the required result → apply a specification → export it correctly →
verify the finished files → Save specification → Reuse/Repeat.**

That workflow is especially valuable when preparing many figures and tables,
changing journals, maintaining an organisational style or producing the same
kind of report repeatedly.

Individuals and teams can extend figspec without modifying the package. Their
own requirements and visual styles can be named, saved with a project and
loaded in later R sessions, giving repeated work the same rules and appearance.

Three recurring needs explain why these capabilities belong together.

## The need for figures that meet journal requirements

Journals set detailed
rules for submitted figures, including column widths, minimum resolution,
accepted formats, text sizes, line weights, colour use and panel labels. These
rules differ between publishers and are often scattered across several pages
of author guidance. A figure prepared for one journal may therefore need
substantial changes when a paper is submitted elsewhere, or resubmitted after
rejection.

figspec brings these requirements into R, where they can be applied while the
figure is still editable. Its registry currently contains 29 carefully sourced
profiles: 22 cover publisher-wide guidance and seven cover individual journals
with their own requirements. The publisher-wide profiles apply across large
journal portfolios, including those of Elsevier, Springer, Wiley, Taylor &
Francis, Oxford University Press, Cambridge University Press, Cell Press, BMJ,
Frontiers, IEEE and other major publishers, so the registry reaches far beyond
29 individual titles. Journal-specific rules can be added where they differ
from the publisher default.

Every recorded requirement is linked to the publisher's guidance and includes
the date it was verified. Each profile also distinguishes between a field the
source does not mention and one that is still awaiting review. Users can
therefore see exactly what information supports each result.

Preparation rarely stops at one plot. `submission_check()` can review a
directory of finished files or a named collection of figures and tables,
give each item a concise result and retain its detailed report.
`graphical_abstract_spec()` and `media_spec()` surface requirements for other
publication assets. `media_check()` can inspect an actual video or audio file
for properties such as its format, frame size, file size, codec and bit rate.

## The need for tables that meet their specifications

Tables often have separate requirements for file format, editability, page
orientation, width, type size, headings and rules. A publication may ask for
an editable Word table in portrait orientation, while a report or organisation
may have its own typography and layout. These requirements need to be applied
to the table itself; treating the table as an image would discard the structure
that makes it editable.

figspec accepts data frames, matrices and tables made with gt, flextable,
kableExtra and grid. It applies the measurable requirements that each table
system supports, exports through that system and reopens the completed file for
verification. HTML, DOCX, RTF, TeX, PDF and image outputs are available where
the selected table system supports them. Requirements that need someone to
read the table—such as whether its title is concise or every abbreviation is
defined—remain clearly marked for review. Bundled publication profiles can be
used when their table guidance has been reviewed, and project or organisational
table specifications can be supplied directly in R.

## The need for figures with consistent panel sizes

R can set the overall
dimensions of an image, but it does not normally control the exact size of the
plot area inside it. As a result, a figure with long axis labels or a large
legend can have a smaller plotting area than a simpler figure saved at the same
width. Place those figures together in a paper, report or presentation, and
their axes and data panels may no longer align.

figspec can size the plot panel directly and calculate the canvas needed around
it. A set of figures can therefore share the same plotting area even when their
titles, labels, legends and margins differ. This is useful for journal
submissions, but also for reports, presentations and any project where figures
need to be produced consistently.

Together, these tools make figure and table preparation more deliberate,
consistent and reproducible: define the result you need, build to that
specification, and verify the finished output before it leaves R.

figspec accepts figures made with ggplot2, base R, lattice, grid and Plotly.
It applies the requirements that each plotting system makes available, exports
the result at the requested size and verifies the finished file. Exact panel
sizing and the most detailed checks remain available for ggplot2-compatible
figures because those objects expose their complete panel and layer structure.
A palette stored in a specification's optional `house_style` section is used
across ggplot2, base R, lattice and Plotly where the plotting system exposes
its colour settings. A registered house style is different: it is a reusable
ggplot2 theme for choices such as the grid, background and legend position.
The [cross-system guide](https://dansemakula.github.io/figspec/articles/figure-systems.html)
shows the calling pattern, completed output and limits for each system.

## Installation

Until the first CRAN release, install figspec from GitHub:

```r
install.packages("pak")
pak::pak("dansemakula/figspec")
```

Once figspec is available on CRAN, it can be installed with:

```r
install.packages("figspec")
```

figspec is ready for practical use and is being improved continuously.
Publisher guidance is rechecked as it changes, and new profiles and
requirements are added through a documented review process.
`registry_status()` shows what has been verified, confirmed absent or not yet
reviewed for every profile.

## Quick start

Start with an ordinary ggplot:

```r
library(ggplot2)
library(figspec)

p <- ggplot(
  mtcars,
  aes(wt, mpg, colour = factor(cyl), shape = factor(cyl))
) +
  geom_point() +
  labs(
    x = "Weight (1000 lbs)",
    y = "Miles per gallon",
    colour = "Cylinders",
    shape = "Cylinders"
  )
```

### 1. Apply a specification

Add a journal profile as you would add another ggplot2 component:

```r
fitted <- p + fig_apply_spec("cell_press")
```

`fig_apply_spec()` applies the requirements that can be expressed in the plot,
including typography, line settings, structural rules, colours and shapes.
When a specification contains an optional `house_style$palette`, figspec uses
that palette without treating it as a pass-or-fail requirement. For ggplot2,
set `colour = FALSE` when you instead need to preserve colour scales already
attached to the plot.

### 2. Verify the figure

```r
report <- fig_check(fitted, "cell_press", column = "single")
report
```

`fig_check()` returns one result for each relevant requirement. It identifies
what meets the specification, what needs to change and what needs more
information. Check the editable plot before export to assess text size, line
weight and colour relationships. Then check the saved file to confirm its
dimensions, resolution and format.

### 3. Export and check the finished file

```r
fig_save(
  "figure_1.tiff",
  fitted,
  spec = "cell_press",
  column = "single"
)
```

`fig_save()` takes the final width and resolution from the specification,
uses an appropriate graphics device and checks the file it writes. Exporting
at the intended publication size matters because resizing later also changes
the apparent size of text and lines.

### Build and check a table

A table specification can come from your project or from a publication profile
where table requirements have been reviewed:

```r
report_spec <- list(
  name = "Research report",
  tables = list(
    formats = c("html", "docx"),
    font_min_pt = 9,
    header_bold = TRUE,
    vertical_rules = FALSE
  )
)

summary_table <- table_apply_spec(head(mtcars), report_spec)
table_check(summary_table, report_spec)
table_save("summary-table.html", summary_table, report_spec)
```

The first call keeps the table editable and applies the requirements its table
system can express. The final call writes a real file, reopens it, and combines
what can be verified from the file with what remains known from the editable
table. See [Build and check tables from R](https://dansemakula.github.io/figspec/articles/tables.html)
for complete examples.

## Size the panel, and the figure

Two image files can have the same width while leaving different amounts of
space for the data. A long axis title, a legend or a multi-line label reduces
the plotting area inside the image.

```r
fig_save(
  "figure_1.png",
  p,
  panel_width = 62,
  units = "mm",
  dpi = 300
)
```

Here, the plot panel—not the complete image—is 62 mm wide. figspec measures the
labels, legends and margins and calculates the canvas needed around it.
`fig_panel_width()` can also determine a shared panel width for a collection
of figures. See
[Control figure and panel dimensions](https://dansemakula.github.io/figspec/articles/panels.html)
for worked examples.

## Understanding verification results

figspec uses five outcomes so that missing information is never mistaken for
compliance:

| Outcome | Meaning |
|---|---|
| <span class="fs-status fs-pass">pass</span> | The figure or table meets the stated requirement. |
| <span class="fs-status fs-fail">fail</span> | The figure or table does not meet the requirement and needs attention. |
| <span class="fs-status fs-unspecified">unspecified</span> | The specification does not state a requirement for this property. |
| <span class="fs-status fs-unknown">unknown</span> | The requirement needs information from another input or a manual check. |
| <span class="fs-status fs-fail">invalid</span> | The file is corrupt or does not match its stated format. |

From a plot object, figspec can examine typography, line and point weights,
colour relationships, panel labels, axis rules and other visual properties.
From an exported file, it can verify properties such as dimensions,
resolution, format, file size and selected format-specific requirements.
For tables, it combines properties retained by the editable object with the
format and structure of the completed file.
An `unknown` result identifies the information that the supplied plot or file
does not contain. The report then shows what still needs to be checked from the
editable object, the source guidance or another file property.

## Journal and publisher profiles

The built-in registry contains **29 profiles across 21 disciplines**. Twenty-two
profiles cover publisher-wide guidance and therefore apply across complete
journal portfolios; seven represent journals with their own requirements.
Publisher-wide profiles act as defaults, and journal-specific guidance should
take precedence whenever a title states a different rule.

```r
spec_list(discipline = "physics")
spec_get("cell_press")
fig_columns("science")
registry_status()
```

Every recorded requirement includes its publisher source and verification
date. The registry distinguishes requirements that have been verified,
requirements that a publisher explicitly does not state and fields that have
not yet been reviewed. This prevents incomplete information from being
presented as a pass.

Table guidance is reviewed separately from figure guidance. At present, the
bundled registry contains table requirements only for profiles whose table
instructions have been recorded; `registry_status()` shows this coverage in
the `table_stated`, `table_confirmed_absent` and `table_unreviewed`
columns. You can use the full table workflow immediately with a project or
organisational specification.

Browse the
[complete profile table](https://dansemakula.github.io/figspec/articles/journals.html)
or read
[how the registry is reviewed and maintained](https://dansemakula.github.io/figspec/articles/registry.html).

## Use your own requirements and style

figspec is not limited to its built-in journal profiles. You can supply your
own requirements, register an internal publication format or reuse a house
style across projects.

These are two different kinds of reusable extension:

| What you want to reuse | What it contains | Save and restore it with |
|---|---|---|
| A specification | Requirements that a finished figure or table must meet, with an optional cross-system palette | `spec_save()` and `spec_load()` |
| A registered house style | A reusable ggplot2 theme for choices such as the grid, background and legend position | `style_save()` and `style_load()` |

A requirement in a specification can determine whether work passes or fails.
Optional palettes and registered house styles record visual choices, so they
shape appearance without becoming compliance rules. When a ggplot2 theme and
requirements are used together, figspec retains compatible theme choices and
applies the stated requirements wherever they are needed.

```r
style_register(
  "mylab",
  theme_minimal() + theme(panel.grid.minor = element_blank()),
  description = "Our group's figure style"
)

p + fig_apply_spec("frontiers", style = "mylab")
```

Your house style controls the appearance of the figure wherever the
specification is silent. If a style setting conflicts with a stated
requirement—for example, 6 pt text when the minimum is 8 pt—figspec applies
the required value and leaves the rest of the design unchanged.

Custom specifications can be kept under version control and loaded when a
project starts. `spec_save()` writes or safely updates the project YAML file,
and `spec_load()` makes its entries available in a later R session:

```r
report_spec <- list(
  name = "Research unit report",
  columns = list(full = 160),
  dpi_min = 300,
  formats = c("png", "pdf"),
  house_style = list(
    palette = c("#76549A", "#D99000", "#2B78A6")
  )
)

spec_save(
  report_spec,
  "project-specifications.yml",
  id = "research_unit_report"
)
spec_load("project-specifications.yml")
```

The optional palette travels with the specification, so supported plotting
systems can use the same purple, amber and blue identity. `fig_check()` treats
it as a design preference, leaving pass-or-fail decisions to the requirements
recorded in the specification.

The registry marks user-defined profiles with their origin, making them easy
to distinguish from profiles maintained by figspec. They extend the current R
session without changing the installed package.

For a project or research team, keep the files in a predictable folder:

```text
project/
├── config/
│   └── figspec/
│       ├── specifications.yml
│       └── styles.rds
└── analysis.R
```

Save registered house styles with:

```r
dir.create(file.path("config", "figspec"), recursive = TRUE,
           showWarnings = FALSE)

style_save(file.path("config", "figspec", "styles.rds"))
```

Then load both files at the beginning of an analysis, in a project setup
script or in the first code chunk of an R Markdown or Quarto document:

```r
library(figspec)

spec_load(file.path("config", "figspec", "specifications.yml"))
style_load(file.path("config", "figspec", "styles.rds"))
```

The paths are relative to the project directory, so the same code works even
when team members keep the project in different locations on their computers.

Each team member has a separate R installation and a separate local copy of the
project. Git records changes, while GitHub or another Git hosting service stores
the shared repository. Add `.Rprofile` and the two files under `config/figspec/`
to that repository, commit them and push the commit. A new team member clones
the repository once. After that, one person can update a specification or
style, commit and push the change, and everyone else receives it by pulling the
latest changes into their own project copy.

When someone opens the project, their own R installation reads the local
`.Rprofile` and loads the local copies of the figspec files. If they pull an
update while R is already running, they should restart R or run `spec_load()`
and `style_load()` again. The team is not sharing one running R session:
GitHub holds the shared files, and Git places a copy on each computer. Every
computer must have figspec installed. A project using `renv` can record the
package version so everyone uses the same release.

Teams that want these files loaded automatically can place the two load calls
in the project's `.Rprofile`. A setup script is often easier to see and debug,
whereas `.Rprofile` is useful when every R session in the project must have the
same names available. Because `.Rprofile` is executable R code, review changes
to it and never store passwords, access tokens or other secrets in it. Load an
RDS style file only from a repository controlled by people you trust; stored
theme functions remain blocked unless `allow_functions = TRUE` is explicitly
requested.

An organisation with many specifications, styles and helper functions can put
them in a small internal R package that imports figspec.

## More publication workflows

The same specification can be used throughout a project:

- `submission_check()` reviews a directory or named collection of figures
  and tables and summarizes what needs attention.
- `fig_refit()` adapts and re-exports saved plot objects when a manuscript
  moves to a journal with different requirements.
- `figspec_knitr_setup()` applies dimensions and resolution consistently in
  Quarto and R Markdown documents.
- `graphical_abstract_spec()`, `media_spec()` and `media_check()` surface
  separate requirements for graphical abstracts, video and audio.
- `table_apply_spec()`, `table_save()` and `table_check()` provide the
  corresponding build, export and verification workflow for tables.
- `fig_suggest_art_type()` helps identify which resolution rule is relevant when
  a publisher distinguishes colour, grayscale, line and combination artwork.

These functions report the evidence they can establish and collect the items
that still require judgement. When a source gives no requirement, the report
marks that property as unspecified and leaves the decision with the user.

## Function families

The complete public API is organised around the work a user needs to complete:

| Task | What figspec provides | Functions |
|---|---|---|
| Build, export and verify figures | Apply reachable requirements while a figure is editable, write the requested format and inspect the completed file | `fig_apply_spec()`, `theme_spec()`, `fig_save()`, `fig_check()`, `fig_preview()`, `fig_geometry()` |
| Size and align plotting areas | Set the physical size of the data panel, find a shared panel width and retrieve stated publication widths | `fig_panel_size()`, `fig_panel_width()`, `fig_width()`, `fig_columns()` |
| Improve visual distinction | Use accessible colours, shapes, line types and weights; preserve an optional project palette; and check whether groups remain distinguishable | `figspec_palettes()`, `figspec_palette()`, `scale_colour_figspec()`, `scale_fill_figspec()`, `scale_shape_figspec()`, `figspec_shapes()`, `figspec_linetypes()`, `spec_linewidth()`, `colour_safety_check()`, `fig_tag_panels()`, `spec_style_palette()` |
| Find, create and reuse specifications and styles | Use a bundled profile or save project and organisational requirements and ggplot2 themes for later sessions or team use | `spec_list()`, `spec_get()`, `spec_register()`, `spec_save()`, `spec_load()`, `style_register()`, `style_list()`, `style_remove()`, `style_save()`, `style_load()` |
| Review a complete body of work | Check mixed collections of figures and tables, inspect one result in detail, choose an artwork rule and adapt editable figures to another specification | `submission_check()`, `submission_detail()`, `fig_suggest_art_type()`, `fig_refit()` |
| Build, export and verify tables | Apply measurable requirements to supported R table objects, retain editability and check the written output | `table_spec()`, `table_apply_spec()`, `table_save()`, `table_check()` |
| Work with other publication assets | Retrieve graphical-abstract and media requirements and inspect supplementary video or audio | `graphical_abstract_spec()`, `media_spec()`, `media_check()` |
| Use the workflow in reports | Carry figure dimensions and resolution into R Markdown and Quarto | `figspec_knitr_options()`, `figspec_knitr_setup()` |
| Inspect and maintain the registry | Measure coverage, find profiles due for review, recheck sources and validate proposed registry files | `registry_status()`, `registry_stale_entries()`, `registry_check_sources()`, `registry_entry_template()`, `registry_validate_file()` |

The package also provides `color_safety_check()` and
`scale_color_figspec()` as American-English aliases. The
[complete function reference](https://dansemakula.github.io/figspec/reference/index.html)
uses the same task-based groups and provides the arguments and examples for
every function.

## Learn more

- [Getting started with figspec](https://dansemakula.github.io/figspec/articles/figspec.html)
- [Use figspec with different R plotting systems](https://dansemakula.github.io/figspec/articles/figure-systems.html)
- [Control figure and panel dimensions](https://dansemakula.github.io/figspec/articles/panels.html)
- [Build and check tables from R](https://dansemakula.github.io/figspec/articles/tables.html)
- [Journal and publisher profiles](https://dansemakula.github.io/figspec/articles/journals.html)
- [Every function and its options](https://dansemakula.github.io/figspec/articles/options.html)
- [Complete function reference](https://dansemakula.github.io/figspec/reference/index.html)
- [Registry provenance and maintenance](https://dansemakula.github.io/figspec/articles/registry.html)
- [Contributing to figspec](CONTRIBUTING.md)

## Licence

figspec is released under the
[GNU General Public License version 3 or later](LICENSE.md). Registry entries
include short quotations from publisher guidance for verification and
attribution. Publishers retain any rights they hold in their original wording.

When relying on a requirement, consult the linked publisher guidance as the
authoritative source. `spec_get(<id>)$source_url` provides that link and
`$verified_on` records when it was reviewed.
