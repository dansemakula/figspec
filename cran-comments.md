## Test environments

* local macOS, R 4.6.1

## R CMD check results

0 errors | 0 warnings | 1 note

> New submission

This is a first submission.

## Notes for the reviewer

The package ships a data file, `inst/extdata/journals.yaml`, holding figure
requirements taken from journal author guidelines. Each entry records the URL
it was read from and the date it was read, and quotes the publisher's own
wording for load-bearing numbers, so any value can be audited against its
source. Nothing in it is inferred: where a publisher states no requirement, the
field is omitted and reported to users as unspecified rather than as a pass.

Examples and tests write only to `tempdir()`.

Vignettes build without network access.
