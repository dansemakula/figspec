# figspec

<!-- badges: start -->
[![R-CMD-check](https://github.com/dansemakula/figspec/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/dansemakula/figspec/actions/workflows/R-CMD-check.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

Journals publish precise rules for the figures you submit: column widths to the
millimetre, minimum resolution, which file formats they take, how small type is
allowed to get. The rules are real, they differ between publishers, and they are
scattered across author-guideline pages that are easy to skim past. Most people
find out they got one wrong at the production stage, after acceptance.

figspec brings the requirements of 27 publishers into your R session as data,
builds your figure to meet them, and exports it at exactly the stated size and
resolution. You can fit a plot to your target journal as you draw it, or check
one you have already finished, without looking those requirements up every
time. Every requirement records the page it came from and the date it was read.

## Installation

```r
# install.packages("pak")
pak::pak("dansemakula/figspec")
```

figspec is **experimental**: the registry is roughly a fifth populated against
the full field grid, and the API may still change. `registry_status()` reports
exactly how much of each entry has been harvested.

## Where this fits in your workflow

Draw your plot the way you always do. Once you know where you are submitting,
bring the journal into the plot and figspec takes care of the requirements, or
hand it a figure you have already finished and it will tell you where that
figure stands.

### 1. Bring the journal in while you are plotting

Add the journal the same way you would add a colour scale, and the figure comes
out built to specification.

```r
library(ggplot2)
library(figspec)

ggplot(mtcars, aes(wt, mpg, colour = factor(cyl), shape = factor(cyl))) +
  geom_point() +
  fit_journal("cell_press")
```

That one line carries the journal's typography, its stated line weights, its
structural rules such as axis lines and tick marks, and colours and shapes
chosen to survive whatever that journal does to a figure in production. Where a
publisher prints in black and white, the palette shifts to one that keeps its
colours apart in greyscale.

Add it last, and keep your own palette if you have already chosen one:

```r
  scale_colour_viridis_d() +
  fit_journal("plos_one", colour = FALSE)
```

Line widths inside a geom live on the layer, so pass those through directly:

```r
  geom_line(linewidth = figspec_linewidth("cell_press"))
```

### 2. Check whether a plot meets a journal's requirements

Pass the plot and the journal, and you get one row per requirement.

```r
p <- ggplot(mtcars, aes(wt, mpg, colour = factor(cyl))) +
  geom_point() +
  labs(title = "Fuel economy")

check_journal(p, "cell_press", column = "single")
#> ✔ Width         85 mm                       (requires: single 85 | double 174 mm)
#> ✖ Type size     smallest 8.8, largest 13.2 pt   (requires: min 6 pt, max 8 pt)
#> ✖ Colour pairs  red and green both used         (requires: not used together)
```

Two failures in an ordinary ggplot, both from defaults nobody thinks about.
ggplot2 runs 8.8 to 13.2 pt where Cell Press allows 6 to 8, and its default
palette pairs a red with a green.

Check the plot object while you still have it. Type size, line width and colour
all disappear into pixels once a figure is written to a TIFF.

### 3. Export at exactly the stated size and resolution

```r
ggsave_journal("figure_1.tiff", p, journal = "cell_press", column = "single")
```

This takes the width from the registry, defaults the resolution to the
journal's minimum, chooses a device that can render the required font, and
re-checks the file it has just written.

Saving at the journal's real column width is what keeps a compliant figure
compliant. Type size is absolute: an 8 pt label stays 8 pt, so a figure drawn
at 180 mm and dropped into an 85 mm column takes that label down to 3.8 pt.

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

Rejected, and the next journal's rules clash with the last one's? Cell Press
allows type between 6 and 8 pt; PLOS ONE wants 8 to 12.

```r
refit_journal(my_plots, journal = "plos_one", outdir = "figures_plos/")
```

This re-themes and re-exports the whole set. It works from plot objects, since
type size cannot be recovered once a figure has been written to a file.

### 7. Use it in Quarto or R Markdown

Where figure size comes from chunk options:

```r
figspec_knitr_setup("cell_press", column = "double")
```

### 8. Add your own style, or your own journal

```r
register_house_style("mylab", theme_minimal())
p + fit_journal("frontiers", style = "mylab")

register_journal("lab_report", "Our lab format",
                 source_url = "internal handbook v3", verified_on = "2026-08-22",
                 requirements = list(columns = list(single = 100, double = 170),
                                     font_min_pt = 9))
```

Your style is applied underneath the journal's requirements, so it can shape
how a figure looks while the journal keeps the final word on anything it has
specified.

### 9. Find out which resolution rule applies

Publishers hold line art to three or four times the general minimum, and line
art means monochrome.

```r
suggest_art_type(p, "bmj")
```

## Journals covered

**27 entries**, 21 of them covering a publisher's whole portfolio, across 20 disciplines.

American Chemical Society journals · American Geophysical Union journals · American Physical Society journals · BMJ journals · Cambridge University Press journals · Cell Press journals · Copernicus Publications journals · Elsevier journals · Frontiers journals · IEEE journals · IEEE magazines · IOP Publishing journals · Journal of Statistical Software · MDPI journals · Nature · Oxford University Press journals · PLOS ONE · PNAS · Royal Society journals · Royal Society of Chemistry books · Royal Society of Chemistry journals · Sage journals · Science · Springer journals · STAR Protocols · Taylor & Francis and Routledge journals · Wiley journals

<details>
<summary><strong>Full table</strong> — ids, coverage, and how much has been harvested</summary>

| Journal or publisher | `id` | Covers | Fields |
|---|---|---|---|
| American Chemical Society journals | `acs` | all its journals | 7 |
| American Geophysical Union journals | `agu` | all its journals | 2 |
| American Physical Society journals | `aps` | all its journals | 2 |
| BMJ journals | `bmj` | all its journals | 4 |
| Cambridge University Press journals | `cambridge` | all its journals | 7 |
| Cell Press journals | `cell_press` | all its journals | 15 |
| Copernicus Publications journals | `copernicus` | all its journals | 4 |
| Elsevier journals | `elsevier` | all its journals | 6 |
| Frontiers journals | `frontiers` | all its journals | 6 |
| IEEE journals | `ieee` | all its journals | 4 |
| IEEE magazines | `ieee_magazines` | all its journals | 4 |
| IOP Publishing journals | `iop` | all its journals | 5 |
| Journal of Statistical Software | `jss` | this journal | 1 |
| MDPI journals | `mdpi` | all its journals | 2 |
| Nature | `nature` | this journal | 14 |
| Oxford University Press journals | `oup` | all its journals | 7 |
| PLOS ONE | `plos_one` | this journal | 11 |
| PNAS | `pnas` | this journal | 10 |
| Royal Society journals | `royal_society` | all its journals | 6 |
| Royal Society of Chemistry books | `rsc_books` | all its journals | 5 |
| Royal Society of Chemistry journals | `rsc` | all its journals | 4 |
| Sage journals | `sage` | all its journals | 4 |
| Science | `science` | this journal | 3 |
| Springer journals | `springer` | all its journals | 11 |
| STAR Protocols | `star_protocols` | this journal | 3 |
| Taylor & Francis and Routledge journals | `taylor_francis` | all its journals | 8 |
| Wiley journals | `wiley` | all its journals | 5 |

`Fields` counts the requirements harvested so far for that entry.

</details>

[The full table of widths, resolutions and type sizes](https://dansemakula.github.io/figspec/articles/journals.html)
is generated from the registry, as is
[the reference to every function and option](https://dansemakula.github.io/figspec/articles/options.html).
Use `journal_spec(id)` for any entry's full specification and its source.

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

When a publisher is silent on maximum height, figspec tells you so and leaves
the judgement with you. Silence gets reported as silence.

## Colour, line weight and the rest

figspec covers every property a journal states and that can be read from your
figure:

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
practice, so figspec shows you the finding and leaves it as advice.

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

### The three states of a field

A blank field means one of two different things, and conflating them puts a
claim in figspec's mouth that nobody earned:

| In the entry | Reported as | Means |
|---|---|---|
| Value in `requirements:` | graded `pass` / `fail` | The publisher states it |
| Field listed in `not_stated:` | `not specified by publisher` | Somebody read the page and confirmed the rule is absent |
| Field in neither | `not yet harvested for this journal` | **Nobody has looked yet** |

### How hedged wording is recorded

Publishers hedge constantly. What decides is the **main verb of the sentence
stating the rule**:

| Publisher's wording | Recorded as |
|---|---|
| OUP: whole guide is *"tips rather than strict rules"*, then *"at least 300dpi"* | **Requirement** — the hedge is about achieving the target, and the target still applies |
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
| `house_style:` | What a journal's figures **look like**. A matter of taste | Never |

Putting a requirement field inside `house_style` is a load-time error. That
line is what makes a `pass` mean something.

Where a journal is silent and figspec has to supply a working default, it says
so, and marks the value as its own.

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
