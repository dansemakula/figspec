# Contributing to figspec

The code is small. The registry is the part that makes figspec worth trusting,
and most contributions will be to it.

## The one rule

**Every value in the registry comes from the publisher's own author guidelines,
and the entry records the page and the date it was read.**

The package refuses to load an entry without both. That is a load-time error,
not a warning.

Please do not contribute values from a summary, a blog post, an AI answer, or
another package. During this package's first week, second-hand sources produced
three specific, plausible, wrong numbers that the publishers' own pages
contradicted:

| Claim | What the publisher actually says |
|---|---|
| Taylor & Francis columns 8.2 / 17.1 cm | T&F states no column width at all |
| RSC Advances single column 8.5 cm | RSC's own page says 8.3 cm |
| BMJ line art 600 dpi | BMJ says line art "should be 1200 dpi" |

Each was plausible. Each was wrong. That is why the rule exists.

## Adding a journal

```r
new_journal_entry("plos_biology", "PLOS Biology",
                  "https://journals.plos.org/plosbiology/s/figures")
```

prints a skeleton naming every field figspec understands. Then:

1. Fill in **only** what the page states, and quote the wording for any number
   in a `source_quote_*` field.
2. List under `not_stated:` any field you **read the page for and confirmed is
   absent**. Do not list a field you simply did not check.
3. Leave everything else alone. An untouched field reports as *not yet
   harvested*, which is true and is better than a guess.

```r
validate_registry_file("my-journals.yaml")
```

reports every problem rather than stopping at the first.

## Hedged wording

Publishers hedge constantly. What decides is the **main verb of the sentence
stating the rule**, not the presence of a hedge. The full policy is at the top
of `inst/extdata/journals.yaml`. In short:

* A hedge about the document, or about achievability, does not downgrade a
  rule. OUP calls its whole guide "tips rather than strict rules" and still
  says "at least 300dpi": that is recorded and graded.
* A rule whose main verb **is** a recommendation goes in an advisory field and
  is reported but never graded. Sage's "We recommend having no more than 7
  series" is reported; it never fails.
* A list is recorded only where the publisher closes it. PLOS's "Use only
  Arial, Times, or Symbol font" is recorded; ACS's "Helvetica or Arial fonts
  work well" is not, because it excludes nothing.

When in doubt, **do not grade**. An unrecorded rule costs a user a check. A
wrongly graded one tells them they broke a rule that does not exist.

## Scope of an entry

Name an entry for what you actually read. `rsc_books` and `rsc` are separate
because RSC's book and journal guidance differ substantially, as are
`ieee_magazines` and `ieee`. An entry that claims coverage it does not have is
worse than a narrower one.

## Code contributions

* `devtools::test()` must pass, and `R CMD check --as-cran` must be clean
  before a pull request.
* A new check needs a registry field, a test for the passing case, a test for
  the failing case, and a test that journals stating no such rule raise no
  check at all.
* Prefer reporting to guessing. Several checks deliberately do not exist
  because they would fire on correct figures: axis labels are not required to
  carry units in parentheses, for instance, because a count has no unit.

## Harvesting at scale

`data-raw/harvest.R` holds discovery through the DOAJ API, direct and archived
fetch lanes, extraction of the publisher's own specification sentences, and
emission of reviewable candidates. It never writes to the registry, and it
should stay that way: auto-populating would destroy the property that makes the
registry worth trusting.
