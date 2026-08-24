# Entries that need rechecking

Entries that need rechecking

## Usage

``` r
stale_entries(max_age_days = 365, as_of = Sys.Date())
```

## Arguments

- max_age_days:

  Age beyond which an entry is flagged for rechecking. Defaults to 365.

- as_of:

  Date to measure against. Defaults to today.

## Value

The ids that are older than `max_age_days`, invisibly, after reporting
them.

## Examples

``` r
stale_entries(max_age_days = 0)
#> ! 28 entries older than 0 days and due a recheck:
#> • aps - read 142 days ago (2026-04-04)
#> • plos_one - read 3 days ago (2026-08-21)
#> • cell_press - read 3 days ago (2026-08-21)
#> • star_protocols - read 3 days ago (2026-08-21)
#> • frontiers - read 3 days ago (2026-08-21)
#> • iop - read 3 days ago (2026-08-21)
#> • cambridge - read 3 days ago (2026-08-21)
#> • copernicus - read 3 days ago (2026-08-21)
#> • wiley - read 3 days ago (2026-08-21)
#> • jss - read 3 days ago (2026-08-21)
#> • nature - read 2 days ago (2026-08-22)
#> • royal_society - read 2 days ago (2026-08-22)
#> • science - read 2 days ago (2026-08-22)
#> • elsevier - read 2 days ago (2026-08-22)
#> • taylor_francis - read 2 days ago (2026-08-22)
#> • agu - read 2 days ago (2026-08-22)
#> • mdpi - read 2 days ago (2026-08-22)
#> • sage - read 2 days ago (2026-08-22)
#> • pnas - read 2 days ago (2026-08-22)
#> • acs - read 2 days ago (2026-08-22)
#> • bmj - read 2 days ago (2026-08-22)
#> • ieee_magazines - read 2 days ago (2026-08-22)
#> • rsc_books - read 2 days ago (2026-08-22)
#> • ieee - read 2 days ago (2026-08-22)
#> • springer - read 2 days ago (2026-08-22)
#> • rsc - read 2 days ago (2026-08-22)
#> • lab_report - read 2 days ago (2026-08-22)
#> • oup - read 1 days ago (2026-08-23)
```
