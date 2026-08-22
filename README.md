# figspec

<!-- badges: start -->
[![R-CMD-check](https://github.com/dansemakula/figspec/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/dansemakula/figspec/actions/workflows/R-CMD-check.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

figspec lets you quickly and reliably **fit your plots to** your target
journal's published figure requirements, or **check whether they already meet
them** — without looking those requirements up every time.

It brings the requirements of 27 publishers into your R session as data, builds
your figure to meet them, and exports it at exactly the stated size and
resolution. Every requirement records the page it came from and the date it was
read.

## Installation

```r
# install.packages("pak")
pak::pak("dansemakula/figspec")
```

figspec is **experimental**: the registry is roughly a fifth populated against
the full field grid, and the API may still change. `registry_status()` reports
exactly how much of each entry has been harvested.

## How you use it

### 1. Check whether a plot meets a journal's requirements

Pass the plot and the journal. You get one row per requirement.

```r
library(ggplot2)
library(figspec)

p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) +
  geom_point() +
  labs(title = "Fuel economy")

check_journal(p, "cell_press", column = "single")
#> ✔ Width         85 mm                       (requires: single 85 | double 174 mm)
#> ✖ Type size     smallest 8.8, largest 13.2 pt   (requires: min 6 pt, max 8 pt)
#> ✖ Colour pairs  red and green both used         (requires: not used together)
```

Two failures in an ordinary ggplot, from defaults nobody thinks about: ggplot2
runs 8.8–13.2 pt against Cell Press's 6–8, and its default palette contains a
red and a green.

**Check the plot object, not the saved file.** Type size, line width and colour
cannot be recovered from a TIFF.

### 2. Fit a plot to a journal

`theme_journal()` applies everything the journal states that a theme can carry:
font family, type floor and ceiling, line weights, and structural rules such as
Nature's requirement that axis lines and tick marks be drawn.

```r
p + theme_journal("cell_press")
```

Add compliant values where they live on the layer rather than the theme:

```r
p +
  scale_colour_figspec("cividis") +                  # safe in print and for CVD
  scale_shape_manual(values = figspec_shapes(3)) +   # a second cue besides colour
  geom_line(linewidth = figspec_linewidth("cell_press")) +
  theme_journal("cell_press")
```

### 3. Export at exactly the stated size and resolution

```r
ggsave_journal("figure_1.tiff", p, journal = "cell_press", column = "single")
```

Takes the width from the registry, defaults the resolution to the journal's
minimum, picks a device that can render the required font, and re-checks the
file it wrote.

### 4. Look up what a journal requires

```r
journals(discipline = "physics")     # browse by field
journal_spec("cell_press")           # the full specification, with its source
fig_columns("science")               # single 57, double 121, triple 184
fig_width("frontiers", "double")     # 180
```

### 5. Check a whole submission

```r
check_submission("figures/", "cell_press")
#> ✔ Figure_1.tiff  single  all requirements met
#> ✖ Figure_2.tiff  double  failed: Resolution, File format
```

### 6. Move a figure set to a different journal

Rejected, and the next journal's rules are incompatible? Cell Press wants type
6–8 pt; PLOS ONE wants 8–12.

```r
refit_journal(my_plots, journal = "plos_one", outdir = "figures_plos/")
```

Re-themes and re-exports the set. Works from plot objects, since type size
cannot be recovered from a finished file.

### 7. Use it in Quarto or R Markdown

Where figure size comes from chunk options rather than `ggsave()`:

```r
figspec_knitr_setup("cell_press", column = "double")
```

### 8. Add your own style, or your own journal

```r
register_house_style("mylab", theme_minimal())
p + theme_journal("frontiers", style = "mylab")

register_journal("lab_report", "Our lab format",
                 source_url = "internal handbook v3", verified_on = "2026-08-22",
                 requirements = list(columns = list(single = 100, double = 170),
                                     font_min_pt = 9))
```

A style is applied *underneath* the journal's requirements, so it can never
push a figure out of compliance.

### 9. Find out which resolution rule applies

Publishers hold line art to three or four times the general minimum, and line
art means monochrome.

```r
suggest_art_type(p, "bmj")
```

## Looking things up

```r
journals()
journals(discipline = "physics")
journal_spec("cell_press")
fig_width("frontiers", "double", units = "in")
```

## What the four outcomes mean

| Outcome | Meaning |
|---|---|
| `pass` | Meets the requirement. |
| `fail` | Breaches it. Fix this. |
| `unspecified` | **The publisher does not state this requirement.** Nothing can be concluded. |
| `unknown` | The requirement exists, but this input cannot answer it — type size in a raster file, for example. |

`unspecified` is deliberately not a pass. If a publisher is silent on maximum
height, figspec will not tell you your figure is fine; it will tell you the
publisher said nothing and leave the judgement to you.

## Colour, line weight and the rest

figspec is not only about size. It checks every property a journal states and
that can be determined from your figure:

| Property | From a plot object | From a saved file |
|---|---|---|
| Width, height | yes | yes |
| Resolution | yes | yes (TIFF, PNG, JPEG, PDF) |
| File format, file size | yes | yes |
| Type size, font | **yes** | no — points do not survive into a raster |
| Line width | **yes** | no |
| Colour mode | yes | yes (TIFF, PNG) |
| Red/green pairing, greyscale, colour vision | **yes** | no |
| Panel labels, text case | **yes** | no |
| Video format, frame size, file size | n/a | yes, via `check_media()` |

```r
p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) + geom_point()
check_colour_safety(p, "cell_press")
#> ✖ Colour pairs  red and green both used (#F8766D, #00BA38)
#>                 (requires: red and green not used together)
#> ℹ Greyscale     3 pair(s) merge in greyscale
#> ℹ Colour vision colours merge under deuteranopia (1), protanopia (1)
```

ggplot2's default three-colour palette is red, green and blue — which is
precisely what Cell Press states you should not do. Swap in a palette designed
for it and all three clear:

```r
p + scale_colour_manual(values = c("#000000", "#0072B2", "#E69F00"))
#> ✔ Colour pairs  no red/green pairing
#> ✔ Greyscale     all colours separable in greyscale
#> ℹ Colour vision separable under deuteranopia, protanopia and tritanopia
```

Note the outcomes. Red/green is a **requirement** for Cell Press because Cell
Press states it, so it can fail. Greyscale is a requirement for the Royal
Society, which prints in black and white by default. Colour-vision safety is
reported for every journal but is always `unspecified`, because it is good
practice rather than a published rule — figspec will show you the finding but
will not claim a journal demanded it.

Line weights are checked too, against the range the publisher states:

```r
ggplot(economics, aes(date, unemploy)) +
  geom_line(linewidth = figspec_linewidth("frontiers")) +   # Frontiers states 2 pt
  theme_journal("frontiers")
```

## Beyond the figure itself

**Panel labels.** Cell Press states that panels are labelled with capital
letters. figspec counts the panels in a patchwork composition and checks how
they are tagged:

```r
check_journal((p1 | p2) / p3, "cell_press")
#> ✖ Panel labels  3 panels, none labelled  (requires: panels labelled with uppercase letters)
```

Add `plot_annotation(tag_levels = "A")` and it passes; `tag_levels = "1"` still
fails, because Cell Press asked for letters.

**Text case.** Nature states that lettering should be lower-case with the first
letter capitalised and no full stop:

```r
p + labs(title = "Fuel economy.", y = "Miles Per Gallon")
#> ✖ Text case  ends with a full stop: 'Fuel economy.'; uses Title Case: 'Miles Per Gallon'
```

The Title Case test is deliberately conservative. It ignores acronyms and short
words, so `"Body mass index (BMI)"` and `"CO2 emissions per capita"` pass while
`"Miles Per Gallon"` does not.

**Graphical abstracts and supplementary media.** Both have their own rules,
separate from figures. A graphical abstract is usually a far smaller canvas
than a figure, and often carries a character limit on its text:

```r
graphical_abstract_spec("rsc")
#> Maximum size: 80 x 40 mm    Resolution: 600 dpi
#> Formats: TIFF               Text limit: 250 characters

media_spec("science")
#> Video formats: MP4, MOV      Video codec: H.264
#> Maximum frame size: 1920 x 1080
#> Preferred frame sizes: 640 x 480 or 1280 x 720
#> Maximum file size: 50 MB

check_media("movie_s1.mp4", "science")
```

Frame size is read from the MP4/MOV `tkhd` box or the GIF header. Codec and bit
rate are recorded in the registry but reported as **not inspected** — reading
them needs a media library, and a guess would be worse than nothing.

## Bring your own style

figspec deliberately has no aesthetic opinion. Register your own look and
apply it to any journal:

```r
register_house_style(
  "mylab",
  theme_minimal() + theme(panel.grid.minor = element_blank()),
  description = "Our group's look"
)

p + theme_journal("frontiers", style = "mylab")
```

Styles persist if you save them:

```r
save_house_styles("~/.figspec-styles.rds")   # once
load_house_styles("~/.figspec-styles.rds")   # from .Rprofile or a setup chunk
```

**A style can never make a figure non-compliant.** Styles are applied
underneath the journal's requirements, so if your style sets 5 pt type and the
journal states a floor of 8 pt, the journal wins and figspec tells you which
elements it had to override:

```
'PLOS ONE' requires type between 8 and 12 pt, so the journal's sizes
override your style for: axis.text.
```

Everything in your style that does not conflict is kept.

## Bring your own journal

For a journal figspec does not ship yet, or an internal format of your own:

```r
register_journal(
  id = "lab_report",
  name = "Our lab report format",
  source_url = "internal handbook v3",
  verified_on = "2026-08-22",
  requirements = list(columns = list(single = 100, double = 170),
                      font_min_pt = 9, formats = list("pdf"))
)
```

`journals()` marks these as `origin = "user"`, so it stays obvious which
entries figspec stands behind. Keep a set under version control and load it
with `load_journals("my-journals.yaml")`.

## How the registry is sourced

Every entry records the publisher page it came from and the date it was read:

```r
journal_spec("frontiers")$source_url
#> "https://www.frontiersin.org/guidelines/author-guidelines"
```

### Three states, not two

A blank field means one of two different things, and conflating them puts a
claim in figspec's mouth that nobody earned:

| In the entry | Reported as | Means |
|---|---|---|
| Value in `requirements:` | graded `pass` / `fail` | The publisher states it |
| Field listed in `not_stated:` | `not specified by publisher` | Somebody read the page and confirmed the rule is absent |
| Field in neither | `not yet harvested for this journal` | **Nobody has looked yet** |

### How hedged wording is recorded

Publishers hedge constantly. What decides is the **main verb of the sentence
stating the rule**, not the presence of a hedge:

| Publisher's wording | Recorded as |
|---|---|
| OUP: whole guide is *"tips rather than strict rules"*, then *"at least 300dpi"* | **Requirement** — the hedge is about achievability, not applicability |
| Elsevier: *"a rule-of-thumb rather than a strict rule"*, then *"no smaller than 6 pt"* | **Requirement** |
| MDPI: *"should be ... preferably no less than 600 dpi"* | **Requirement** — the verb is *should* |
| Sage: *"We recommend having no more than 7 series"* | **Advisory** — the verb is *recommend*. Reported, never graded |
| ACS: *"Helvetica or Arial fonts work well"* | **Not recorded** — excludes nothing |
| PLOS: *"Use only Arial, Times, or Symbol font"* | **Requirement** — a closed set |

When in doubt, don't grade. An unrecorded rule costs a user a check. A wrongly
graded one tells them they broke a rule that does not exist.

The first two are facts about the publisher. The third is a fact about this
registry, and saying so is the difference between a registry you can trust and
one that is confidently wrong. Listing a field in both places is a load-time
error.

Fields a publisher does not state are **omitted**, never filled in from a
sibling journal or from a plausible guess. The registry lives in a single
readable file, [`inst/extdata/journals.yaml`](inst/extdata/journals.yaml), and
load-bearing numbers carry the publisher's own wording alongside them so an
entry can be audited without leaving the file.

Each entry keeps two things strictly apart:

| Block | What it holds | Checked? |
|---|---|---|
| `requirements:` | What the publisher **states** in its guidelines | Yes — this is the only thing `pass`/`fail` refers to |
| `house_style:` | What a journal's figures **look like**. Taste, not rule | Never |

Putting a requirement field inside `house_style` is a load-time error. That
line is what makes a `pass` mean something.

Where a journal is silent and figspec has to supply a working default, it says
so rather than passing the default off as a rule.

Guidelines change. Check the `verified_on` date, and treat the publisher's
current page as the authority.

## Maintaining the registry

Author guidelines change, and an entry read two years ago reads exactly like
one read yesterday unless something says so:

```r
registry_status()
#>          id verified_on age_days stated confirmed_absent unharvested
#>      nature  2026-08-21        1      2                0          15
#>  cell_press  2026-08-21        1     13                0           4

stale_entries(max_age_days = 365)
```

`stated` / `confirmed_absent` / `unharvested` are the three states below, and
they always sum to the full field list, so a half-finished entry cannot pass
as a complete one.

## Contributing a journal

```r
new_journal_entry("plos_biology", "PLOS Biology",
                  "https://journals.plos.org/plosbiology/s/figures")
```

prints a skeleton naming every field figspec understands. Fill in what the
page states, list what you confirmed absent under `not_stated`, and leave the
rest alone — an untouched field reports as not yet harvested, which is true.

```r
validate_registry_file("my-journals.yaml")   # before you open a pull request
load_journals("my-journals.yaml")            # to use it in this session
```

The package refuses to load an entry with no provenance, one that puts a
requirement in `house_style`, or one that claims a field is both stated and
absent.

`data-raw/harvest.R` holds a toolkit for collecting entries at scale: journal
discovery through the DOAJ API, fetching, extraction of the publisher's own
specification sentences, and emission of reviewable candidates. It never
writes to the registry — auto-populating it would destroy the one property
that makes it worth trusting.

## Licence

MIT
