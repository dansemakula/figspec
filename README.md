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
[![Coverage](https://img.shields.io/badge/coverage-89%25-1f9254?style=flat-square)](https://github.com/dansemakula/figspec)
[![Profiles](https://img.shields.io/badge/profiles-29-2b7fd4?style=flat-square)](https://dansemakula.github.io/figspec/articles/journals.html)
[![Licence: GPL-3.0-or-later](https://img.shields.io/badge/licence-GPLv3%2B-7b8b93?style=flat-square)](https://github.com/dansemakula/figspec/blob/main/LICENSE.md)
<!-- badges: end -->

**figspec enables researchers and other R users to build, export and verify
figures against the specifications their work must meet.** It brings those
requirements into R, reducing the time spent searching through guidance,
interpreting rules and applying them by hand. The specification can come from
a journal, a house style or the needs of a particular project. figspec can
work with one figure or a complete set, and it can also retrieve recorded
requirements for tables, graphical abstracts and supplementary video or
audio.

It addresses two common needs.

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
the date it was verified. figspec does not fill gaps with guesses: when a
publisher does not state a requirement, or a field has not yet been reviewed,
the package says so.

Figure preparation rarely stops at one plot. `submission_check()` can review
a directory of finished files or a named collection of plots together, give
each figure a concise result and retain the detailed report for every item.
For related publication assets, `table_spec()`, `graphical_abstract_spec()` and
`media_spec()` surface their separate requirements without mixing them into a
figure report. `media_check()` can then inspect an actual video or audio file
for properties such as its format, frame size, file size, codec and audio bit
rate, reporting anything it cannot determine rather than guessing.

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

Together, these tools make figure preparation more deliberate, consistent and
reproducible: define the result you need, build the figure to that
specification, and verify the finished output before it leaves R.

figspec accepts figures made with ggplot2, base R, lattice, grid and Plotly.
It applies the requirements that each plotting system makes available, exports
the result at the requested size and verifies the finished file. Exact panel
sizing and the most detailed checks remain available for ggplot2-compatible
figures because those objects expose their complete panel and layer structure.

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
You can keep a palette or other design choice you have already made by turning
off the corresponding adjustment.

### 2. Verify the figure

```r
report <- fig_check(fitted, "cell_press", column = "single")
report
```

`fig_check()` returns one result for each relevant requirement. It identifies
what meets the specification, what needs to change and what cannot be
determined from the available input. Checking the plot object is important:
properties such as text size, line weight and colour relationships cannot be
reliably recovered after a figure has been converted to raster pixels.

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

## Size the panel, not just the image

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
| <span class="fs-status fs-pass">pass</span> | The figure meets the stated requirement. |
| <span class="fs-status fs-fail">fail</span> | The figure does not meet the requirement and needs attention. |
| <span class="fs-status fs-unspecified">unspecified</span> | The specification does not state a requirement for this property. |
| <span class="fs-status fs-unknown">unknown</span> | figspec cannot determine the answer from this input. |
| <span class="fs-status fs-fail">invalid</span> | The file is corrupt or does not match its stated format. |

From a plot object, figspec can examine typography, line and point weights,
colour relationships, panel labels, axis rules and other visual properties.
From an exported file, it can verify properties such as dimensions,
resolution, format, file size and selected format-specific requirements.
Where a property cannot be recovered reliably, the result is `unknown`
rather than an unsupported conclusion.

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

Browse the
[complete profile table](https://dansemakula.github.io/figspec/articles/journals.html)
or read
[how the registry is reviewed and maintained](https://dansemakula.github.io/figspec/articles/registry.html).

## Use your own requirements and style

figspec is not limited to its built-in journal profiles. You can supply your
own requirements, register an internal publication format or reuse a house
style across projects.

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
project starts. User-defined profiles are clearly marked so they cannot be
confused with the registry maintained by figspec.

## More publication workflows

The same specification can be used throughout a project:

- `submission_check()` reviews a directory or named collection of figure
  files and summarizes what needs attention.
- `fig_refit()` adapts and re-exports saved plot objects when a manuscript
  moves to a journal with different requirements.
- `figspec_knitr_setup()` applies dimensions and resolution consistently in
  Quarto and R Markdown documents.
- `graphical_abstract_spec()`, `media_spec()` and `media_check()` surface
  separate requirements for graphical abstracts, video and audio.
- `fig_suggest_art_type()` helps identify which resolution rule is relevant when
  a publisher distinguishes colour, grayscale, line and combination artwork.

These functions report what they can establish and identify anything that
still requires judgement. They do not infer requirements that a publisher has
not stated.

## Learn more

- [Getting started with figspec](https://dansemakula.github.io/figspec/articles/figspec.html)
- [Control figure and panel dimensions](https://dansemakula.github.io/figspec/articles/panels.html)
- [Journal and publisher profiles](https://dansemakula.github.io/figspec/articles/journals.html)
- [Every function and its options](https://dansemakula.github.io/figspec/articles/options.html)
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
