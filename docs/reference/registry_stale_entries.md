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
#> • aps - read 156 days ago (2026-04-04)
#> • plos_one - read 17 days ago (2026-08-21)
#> • cell_press - read 17 days ago (2026-08-21)
#> • star_protocols - read 17 days ago (2026-08-21)
#> • frontiers - read 17 days ago (2026-08-21)
#> • iop - read 17 days ago (2026-08-21)
#> • cambridge - read 17 days ago (2026-08-21)
#> • copernicus - read 17 days ago (2026-08-21)
#> • wiley - read 17 days ago (2026-08-21)
#> • jss - read 17 days ago (2026-08-21)
#> • royal_society - read 16 days ago (2026-08-22)
#> • science - read 16 days ago (2026-08-22)
#> • elsevier - read 16 days ago (2026-08-22)
#> • taylor_francis - read 16 days ago (2026-08-22)
#> • agu - read 16 days ago (2026-08-22)
#> • mdpi - read 16 days ago (2026-08-22)
#> • sage - read 16 days ago (2026-08-22)
#> • pnas - read 16 days ago (2026-08-22)
#> • acs - read 16 days ago (2026-08-22)
#> • bmj - read 16 days ago (2026-08-22)
#> • ieee_magazines - read 16 days ago (2026-08-22)
#> • rsc_books - read 16 days ago (2026-08-22)
#> • ieee - read 16 days ago (2026-08-22)
#> • springer - read 16 days ago (2026-08-22)
#> • rsc - read 16 days ago (2026-08-22)
#> • oup - read 15 days ago (2026-08-23)
#> • nature - read 4 days ago (2026-09-03)
#> • bmc - read 4 days ago (2026-09-03)
#> • jid - read 4 days ago (2026-09-03)
```
