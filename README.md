# figspec

<!-- badges: start -->
<!-- badges: end -->

Journals publish precise rules for the figures you submit: column widths to the
millimetre, minimum resolution, which file formats they take, how small type is
allowed to get. The rules are real, they differ between publishers, and they are
scattered across author-guideline pages that are easy to skim past. Most people
find out they got one wrong at the production stage, after acceptance.

**figspec** keeps those requirements in one place, applies them to your ggplot2
figures, and tells you where a figure would fail.

## Installation

```r
# install.packages("pak")
pak::pak("semakuladaniel/figspec")
```

## What it does

```r
library(ggplot2)
library(figspec)

p <- ggplot(mtcars, aes(wt, mpg)) +
  geom_point() +
  labs(title = "Fuel economy")

check_journal(p, "plos_one")
#> ── PLOS ONE ────────────────────────────────────────────────
#> ✔ Width         66.8 mm       (requires: min 66.8 mm, max 190.5 mm)
#> ✖ Type size     smallest 8.8 pt, largest 13.2 pt
#>                               (requires: min 8 pt, max 12 pt)
#> ! Resolution    could not determine   (requires: min 300 dpi)
```

A default ggplot2 title is 13.2 pt. PLOS ONE caps figure type at 12 pt. That is
the kind of thing nobody checks by hand.

Fix it by building on the journal's own typography, then save at the width the
journal actually asks for:

```r
p <- p + theme_journal("plos_one")

ggsave_journal("figure_1.tiff", p, journal = "plos_one", column = "single")
```

`ggsave_journal()` takes the width from the registry, defaults the resolution to
the journal's stated minimum, picks a device that can render the required font,
and re-checks the file it wrote.

Where a journal is silent, figspec says so rather than inventing a requirement:

```r
figspec_chunk_opts("nature")
#> 'Nature' does not state a minimum resolution. Using 300 dpi as a figspec
#> default - this is not a requirement of the journal.
```

## More than sizing

`theme_journal()` applies every requirement that a theme can express — font
family, type floor and ceiling, and stated minimum line weights. Geom line
widths live on the layer rather than the theme, so pass
`figspec_linewidth()` to layers that draw lines.

## Why the width matters

Type size in a figure is absolute. An 8 pt label is 8 pt. If you save a figure
at 180 mm and the journal drops it into an 85 mm column, everything in it
shrinks by more than half, and your 8 pt label lands at 3.8 pt. Saving at the
journal's real column width is what keeps a compliant figure compliant.

## Where this fits in your workflow

figspec is a checker, not a plotting library. You keep whatever you already
use — ggplot2, patchwork, ggpubr, base R — and add one line at the point that
matters.

**While you are designing the figure.** The most common way a compliant figure
becomes non-compliant is being drawn at laptop size and submitted into an
85 mm column, which shrinks everything by more than half.

```r
figspec_preview(p, "cell_press", "single")   # a window at the real published size
```

**In R Markdown or Quarto**, where the size comes from chunk options and never
touches `ggsave()`:

```r
# setup chunk
figspec_knitr_setup("plos_one", column = "single")
```

**At export:**

```r
ggsave_journal("figure_1.tiff", p, journal = "plos_one", column = "single")
```

**When the submission is assembled** — every figure has to pass, not just the
one you remembered to check:

```r
check_submission("figures/", "plos_one")
#> ✔ figure_1.tiff  single  all requirements met
#> ✖ figure_2.tiff  double  failed: Resolution, File format
```

**When the paper is rejected and goes elsewhere**, with different widths,
formats and type limits:

```r
refit_journal(my_plots, journal = "plos_one", outdir = "figures_plos/")
```

`refit_journal()` works from plot objects, not saved files, and refuses to
pretend otherwise: type size cannot be recovered from a finished TIFF.

### Base R and other plotting systems

Base R graphics produce no object to inspect, so they are checked as files.
Base R's `png()` does not record resolution, so tell figspec what you used:

```r
check_submission("figures/", "plos_one", dpi = 300)
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

## Contributing a journal

Add an entry to `inst/extdata/journals.yaml` with a `source_url` and
`verified_on`, quote the publisher's wording for any width, resolution or type
size, and omit anything they do not state. The package refuses to load a
registry entry that has no provenance.

## Licence

MIT
