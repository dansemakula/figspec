# Which journal am I submitting to?

The registry is figspec’s main source of specifications: the published
figure requirements of the publishers below, brought into the R session
as data. It is not the only source — you can write a specification by
hand, load internal formats with
[`load_journals()`](https://dansemakula.github.io/figspec/reference/load_journals.md),
or register a house style — but it is the one the package maintains and
stands behind.

Everything below is generated from the registry itself, so it cannot
drift from what the package actually holds. A dash means the publisher
states nothing, or nobody has harvested it yet —
[`journal_spec()`](https://dansemakula.github.io/figspec/reference/journal_spec.md)
tells you which. That difference is deliberate and figspec keeps it
visible: one is a fact about the publisher, the other a fact about the
registry, and neither is a pass.

| Journal | id | Width (mm) | dpi | Line art | Type (pt) | Formats |
|:---|:---|:---|:---|:---|:---|:---|
| American Chemical Society journals | acs | single 84.7, double 177.8 | 300 | 1200 | 4.5+ | – |
| American Geophysical Union journals | agu | – | – | – | – | JPEG, TIFF, EPS, PS, PDF |
| American Physical Society journals | aps | single 85 | – | – | – | – |
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
| Nature | nature | single 90, double 180 | 300 | – | 5–7 | AI, EPS, PDF, PS, SVG, PSD, TIFF, PNG, JPEG, PPT, CDX |
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
| Wiley journals | wiley | single 80, double 180 | 300 | 600 | – | EPS, PDF, TIFF, PNG |

## Where publishers disagree

The registry makes some conflicts plain, and they are the reason a
single “industry standard” does not exist.

**Panel labels.** Cell Press wants capital letters. AGU, Nature,
Springer and the Royal Society all want lower case. Nature wants them
*upright, not italic*; the Royal Society wants them *italicised*. Same
element, opposite rules.

**Outlining text.** BMJ requires text in EPS files to be outlined.
Nature instructs authors not to outline text.

**Line art resolution.** Twelve entries state a separate figure for line
art, from 600 dpi (IEEE, Wiley) to 1200 dpi (BMJ, ACS, OUP, Springer,
Taylor & Francis) — against a general minimum of 300 almost everywhere.
See
[`suggest_art_type()`](https://dansemakula.github.io/figspec/reference/suggest_art_type.md),
and note that line art means *monochrome*: five publishers define it as
black and white.

**Colour in print.** Frontiers and PLOS say nothing about greyscale. The
Royal Society, Sage and Taylor & Francis print in black and white by
default, so figures must survive it. RSC prints colour free. RSC’s
*books* make it depend on the author’s contract.

## How complete is each entry

| id             | stated | confirmed absent | not yet harvested | read on    |
|:---------------|-------:|-----------------:|------------------:|:-----------|
| cell_press     |     15 |                0 |                13 | 2026-08-21 |
| nature         |     14 |                0 |                14 | 2026-08-22 |
| plos_one       |     11 |                0 |                17 | 2026-08-21 |
| springer       |     11 |                0 |                17 | 2026-08-22 |
| pnas           |     10 |                0 |                18 | 2026-08-22 |
| taylor_francis |      8 |                1 |                19 | 2026-08-22 |
| cambridge      |      7 |                2 |                19 | 2026-08-21 |
| acs            |      7 |                0 |                21 | 2026-08-22 |
| oup            |      7 |                1 |                20 | 2026-08-23 |
| frontiers      |      6 |                1 |                21 | 2026-08-21 |
| royal_society  |      6 |                2 |                20 | 2026-08-22 |
| elsevier       |      6 |                0 |                22 | 2026-08-22 |
| iop            |      5 |                3 |                20 | 2026-08-21 |
| wiley          |      5 |                2 |                21 | 2026-08-21 |
| rsc_books      |      5 |                0 |                23 | 2026-08-22 |
| copernicus     |      4 |                2 |                22 | 2026-08-21 |
| sage           |      4 |                1 |                23 | 2026-08-22 |
| bmj            |      4 |                0 |                24 | 2026-08-22 |
| ieee_magazines |      4 |                0 |                24 | 2026-08-22 |
| ieee           |      4 |                0 |                24 | 2026-08-22 |
| rsc            |      4 |                0 |                24 | 2026-08-22 |
| star_protocols |      3 |                0 |                25 | 2026-08-21 |
| science        |      3 |                0 |                25 | 2026-08-22 |
| aps            |      2 |                0 |                26 | 2026-04-04 |
| agu            |      2 |                2 |                24 | 2026-08-22 |
| mdpi           |      2 |                1 |                25 | 2026-08-22 |
| jss            |      1 |                2 |                25 | 2026-08-21 |

`stated` is what the publisher says. `confirmed absent` is what somebody
read the page for and found missing. `not yet harvested` is what nobody
has checked. The three always sum to the full field list, so a
half-finished entry cannot pass as a complete one.

## Using a specification that is not in here

Anywhere a function takes a `journal`, it will also take a specification
you supply — from
[`journal_spec()`](https://dansemakula.github.io/figspec/reference/journal_spec.md),
or as a plain named list of the same fields:

`house`` ``<-`` `[`list`](https://rdrr.io/r/base/list.html)`(``name ``=`` ``"House style"``, dpi_min ``=`` ``600``, formats ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(``"tiff"``)``)`` `[`fig_check`](https://dansemakula.github.io/figspec/reference/fig_check.md)`(``"figure_1.tiff"``, ``house``)`

A field your specification does not mention is reported as **not
specified**, which is distinct from the registry’s *not yet harvested*:
you wrote the specification, so its silence is your own, not a gap in
figspec’s reading of a publisher’s page.

Pass no specification at all and
[`fig_check()`](https://dansemakula.github.io/figspec/reference/fig_check.md)
becomes an inspection — it reports the figure’s size, resolution, format
and file size, and states plainly that nothing was judged. Nothing
passes and nothing fails, because there was nothing to pass or fail
against.
