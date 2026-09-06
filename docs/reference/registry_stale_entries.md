# Find specifications due for review

Find specifications due for review

## Usage

``` r
registry_stale_entries(max_age_days = 365, as_of = Sys.Date())
```

## Arguments

- max_age_days:

  Age beyond which an entry is flagged for rechecking. Defaults to 365.

- as_of:

  One `Date` to measure against. Defaults to today.

## Value

The ids that are older than `max_age_days`, invisibly, after reporting
them.

## Examples

``` r
registry_stale_entries(max_age_days = 0)
#> ! 29 entries older than 0 days and due a recheck:
#> • aps - read 155 days ago (2026-04-04)
#> • plos_one - read 16 days ago (2026-08-21)
#> • cell_press - read 16 days ago (2026-08-21)
#> • star_protocols - read 16 days ago (2026-08-21)
#> • frontiers - read 16 days ago (2026-08-21)
#> • iop - read 16 days ago (2026-08-21)
#> • cambridge - read 16 days ago (2026-08-21)
#> • copernicus - read 16 days ago (2026-08-21)
#> • wiley - read 16 days ago (2026-08-21)
#> • jss - read 16 days ago (2026-08-21)
#> • royal_society - read 15 days ago (2026-08-22)
#> • science - read 15 days ago (2026-08-22)
#> • elsevier - read 15 days ago (2026-08-22)
#> • taylor_francis - read 15 days ago (2026-08-22)
#> • agu - read 15 days ago (2026-08-22)
#> • mdpi - read 15 days ago (2026-08-22)
#> • sage - read 15 days ago (2026-08-22)
#> • pnas - read 15 days ago (2026-08-22)
#> • acs - read 15 days ago (2026-08-22)
#> • bmj - read 15 days ago (2026-08-22)
#> • ieee_magazines - read 15 days ago (2026-08-22)
#> • rsc_books - read 15 days ago (2026-08-22)
#> • ieee - read 15 days ago (2026-08-22)
#> • springer - read 15 days ago (2026-08-22)
#> • rsc - read 15 days ago (2026-08-22)
#> • oup - read 14 days ago (2026-08-23)
#> • nature - read 3 days ago (2026-09-03)
#> • bmc - read 3 days ago (2026-09-03)
#> • jid - read 3 days ago (2026-09-03)
```
