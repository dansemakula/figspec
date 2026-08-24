# The registry: provenance, and adding your own

[`library`](https://rdrr.io/r/base/library.html)`(`[`figspec`](https://dansemakula.github.io/figspec/)`)`

figspec’s code is small. The registry is the part that makes it worth
trusting, and it is built so that growing it cannot quietly corrupt it.
This vignette covers how it is organised, and how to add to it.

## Every entry names its source

`spec`` ``<-`` `[`journal_spec`](https://dansemakula.github.io/figspec/reference/journal_spec.md)`(``"elsevier"``)`` ``spec``$``source_url`` ``#> [1] "https://www.elsevier.com/about/policies-and-standards/author/artwork-and-media-instructions/artwork-sizing"`` ``spec``$``verified_on`` ``#> [1] "2026-08-22"`

The package **refuses to load** an entry without both. That is a
load-time error, which stops the load outright.

Load-bearing numbers also carry the publisher’s own wording, so an entry
can be audited without leaving the file:

[`writeLines`](https://rdrr.io/r/base/writeLines.html)`(`[`strwrap`](https://rdrr.io/r/base/strwrap.html)`(``spec``$``source_quote_width``)``)`` ``#> Minimal size 30 mm | Single column 90 mm | 1.5 column 140 mm | Double`` ``#> column (full width) 190 mm`

## The three states of a field

A blank field means one of two different things, and conflating them
puts a claim in figspec’s mouth that nobody earned.

| In the entry | Reported as | Means |
|----|----|----|
| A value in `requirements:` | graded `pass` / `fail` | The publisher states it |
| Listed in `not_stated:` | *not specified by publisher* | Someone read the page and confirmed it is absent |
| In neither | *not yet harvested* | **Nobody has looked yet** |

`status`` ``<-`` `[`registry_status`](https://dansemakula.github.io/figspec/reference/registry_status.md)`(``)`` ``status``[``status``$``id`` `[`%in%`](https://rdrr.io/r/base/match.html)` `[`c`](https://rdrr.io/r/base/c.html)`(``"cell_press"``, ``"aps"``)``,`` `` `[`c`](https://rdrr.io/r/base/c.html)`(``"id"``, ``"stated"``, ``"confirmed_absent"``, ``"unharvested"``)``]`` ``#> id stated confirmed_absent unharvested`` ``#> 13 aps 2 0 26`` ``#> 3 cell_press 15 0 13`

The three always sum to the full field list, so a half-finished entry
cannot pass as a complete one. Listing a field in both `requirements:`
and `not_stated:` is a load-time error.

## Hedged wording

Publishers hedge constantly. What decides how a rule is recorded is the
**main verb of the sentence stating it**.

| Wording | Recorded as |
|----|----|
| OUP: whole guide is *“tips rather than strict rules”*, then *“at least 300dpi”* | Requirement. The hedge is about achieving the target, and the target still applies |
| Elsevier: *“a rule-of-thumb rather than a strict rule”*, then *“no smaller than 6 pt”* | Requirement |
| MDPI: *“should be … preferably no less than 600 dpi”* | Requirement. The verb is *should* |
| Sage: *“We recommend having no more than 7 series”* | Advisory. The verb is *recommend*: reported, never graded |
| PLOS: *“Use only Arial, Times, or Symbol font”* | Requirement. A closed set |
| ACS: *“Helvetica or Arial fonts work well”* | Not recorded. It excludes nothing |

The tie-breaker for anything that rule does not settle: **do not
grade**. An unrecorded rule costs a user a check. A wrongly graded one
tells them they broke a rule that does not exist.

## Publisher-wide entries are defaults

Most entries cover a whole portfolio, but publishers say plainly that
individual journals override them. Elsevier’s own page:

> some of our publications have special instructions beyond the common
> guidelines given here. Please check the journal-specific guide for
> authors

Roughly a third of publishers decline to state column widths centrally
at all, because widths depend on a journal’s page layout. Taylor &
Francis, Sage, AGU and MDPI all state resolution and formats but send
you to the journal for size.

[`fig_columns`](https://dansemakula.github.io/figspec/reference/fig_columns.md)`(``"taylor_francis"``)`` ``#> 'Taylor & Francis and Routledge journals' states a width range rather than`` ``#> named columns: ? to ? mm.`

## Guidelines change

An entry read two years ago reads exactly like one read yesterday unless
something says otherwise, and a confidently wrong registry is worse than
no registry.

[`stale_entries`](https://dansemakula.github.io/figspec/reference/stale_entries.md)`(``max_age_days ``=`` ``365``)`` ``#> ``✔`` No registry entry is older than 365 days.`

## Adding a journal

[`new_journal_entry`](https://dansemakula.github.io/figspec/reference/new_journal_entry.md)`(``"plos_biology"``, ``"PLOS Biology"``,`` `` ``"https://journals.plos.org/plosbiology/s/figures"``)`

That prints a skeleton naming every field figspec understands. Fill in
what the page states, list what you confirmed absent under
`not_stated:`, and leave the rest alone — an untouched field reports as
not yet harvested, which is true.

Then validate before opening a pull request:

[`validate_registry_file`](https://dansemakula.github.io/figspec/reference/validate_registry_file.md)`(``"my-journals.yaml"``)`` `[`load_journals`](https://dansemakula.github.io/figspec/reference/load_journals.md)`(``"my-journals.yaml"``)`

Validation reports every problem it finds in one pass, and refuses
entries with no provenance, entries putting a requirement inside
`house_style:`, and entries claiming a field is both stated and absent.

For a journal figspec does not ship, or an internal format of your own:

[`register_journal`](https://dansemakula.github.io/figspec/reference/register_journal.md)`(`` `` id ``=`` ``"lab_report"``, name ``=`` ``"Our lab format"``,`` `` source_url ``=`` ``"internal handbook v3"``, verified_on ``=`` ``"2026-08-22"``,`` `` requirements ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(``columns ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(``single ``=`` ``100``, double ``=`` ``170``)``,`` `` font_min_pt ``=`` ``9``)`` ``)`` `[`fig_width`](https://dansemakula.github.io/figspec/reference/fig_width.md)`(``"lab_report"``, ``"double"``)`` ``#> [1] 170`

[`journals()`](https://dansemakula.github.io/figspec/reference/journals.md)
marks these `origin = "user"`, so it stays visible which entries figspec
stands behind. Provenance is required here too: if the requirements came
from you rather than a publisher, say so in `source_url`.

## Style is separate from compliance

A house style is the visual half of a figure, and it is applied
**underneath** the journal’s requirements so it can never make a figure
non-compliant.

[`library`](https://rdrr.io/r/base/library.html)`(`[`ggplot2`](https://ggplot2.tidyverse.org)`)`` `[`register_house_style`](https://dansemakula.github.io/figspec/reference/register_house_style.md)`(`` `` ``"mylab"``,`` `` `[`theme_minimal`](https://ggplot2.tidyverse.org/reference/ggtheme.html)`(``)`` ``+`` `[`theme`](https://ggplot2.tidyverse.org/reference/theme.html)`(``panel.grid.minor ``=`` `[`element_blank`](https://ggplot2.tidyverse.org/reference/element.html)`(``)``,`` `` axis.text ``=`` `[`element_text`](https://ggplot2.tidyverse.org/reference/element.html)`(``size ``=`` ``5``)``)`` ``)`` ``th`` ``<-`` `[`theme_journal`](https://dansemakula.github.io/figspec/reference/theme_journal.md)`(``"plos_one"``, style ``=`` ``"mylab"``)`` ``#> 'PLOS ONE' requires type between 8 and 12 pt, so the journal's sizes override`` ``#> your style for: axis.text.`

The style asked for 5 pt axis text; PLOS ONE states a floor of 8. The
journal wins, figspec says which elements it overrode, and everything in
the style that does not conflict is kept:

[`class`](https://rdrr.io/r/base/class.html)`(``th``$``panel.grid.minor``)`` ``#> [1] "ggplot2::element_blank" "element_blank" "ggplot2::element" `` ``#> [4] "S7_object" "element"`

Registry entries may also carry a `house_style:` block, which is never
checked and never enforced. Putting a requirement field inside one is a
load-time error. That line is what makes a `pass` mean something.

## Collecting entries at scale

`data-raw/harvest.R` in the package sources holds a toolkit: journal
discovery through the DOAJ API, direct and archived fetch lanes,
extraction of the publisher’s own specification sentences, and emission
of reviewable candidates.

It never writes to the registry. It produces candidates with the
publisher’s wording attached, for a human to accept, correct or discard.
Auto-populating the registry would destroy the one property that makes
it worth trusting, which is that every value in it was read by somebody.
