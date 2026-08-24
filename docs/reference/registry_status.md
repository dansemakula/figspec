# How current is each registry entry, and how complete

Author guidelines change, and an entry read two years ago reads exactly
like one read yesterday unless something says otherwise. This reports
the age of every entry and how much of it has actually been harvested,
so a registry that is quietly going stale is visible rather than merely
wrong.

## Usage

``` r
registry_status(max_age_days = 365, as_of = Sys.Date())
```

## Arguments

- max_age_days:

  Age beyond which an entry is flagged for rechecking. Defaults to 365.

- as_of:

  Date to measure against. Defaults to today.

## Value

A data frame with one row per entry, ordered oldest first.

## Examples

``` r
registry_status()
#>                id verified_on age_days stale stated confirmed_absent
#> 13            aps  2026-04-04      142 FALSE      2                0
#> 1        plos_one  2026-08-21        3 FALSE     11                0
#> 3      cell_press  2026-08-21        3 FALSE     15                0
#> 4  star_protocols  2026-08-21        3 FALSE      3                0
#> 5       frontiers  2026-08-21        3 FALSE      6                1
#> 6             iop  2026-08-21        3 FALSE      5                3
#> 7       cambridge  2026-08-21        3 FALSE      7                2
#> 9      copernicus  2026-08-21        3 FALSE      4                2
#> 10          wiley  2026-08-21        3 FALSE      5                2
#> 11            jss  2026-08-21        3 FALSE      1                2
#> 2          nature  2026-08-22        2 FALSE     14                0
#> 8   royal_society  2026-08-22        2 FALSE      6                2
#> 12        science  2026-08-22        2 FALSE      3                0
#> 14       elsevier  2026-08-22        2 FALSE      6                0
#> 15 taylor_francis  2026-08-22        2 FALSE      8                1
#> 16            agu  2026-08-22        2 FALSE      2                2
#> 17           mdpi  2026-08-22        2 FALSE      2                1
#> 18           sage  2026-08-22        2 FALSE      4                1
#> 19           pnas  2026-08-22        2 FALSE     10                0
#> 20            acs  2026-08-22        2 FALSE      7                0
#> 21            bmj  2026-08-22        2 FALSE      4                0
#> 23 ieee_magazines  2026-08-22        2 FALSE      4                0
#> 24      rsc_books  2026-08-22        2 FALSE      5                0
#> 25           ieee  2026-08-22        2 FALSE      4                0
#> 26       springer  2026-08-22        2 FALSE     11                0
#> 27            rsc  2026-08-22        2 FALSE      4                0
#> 28     lab_report  2026-08-22        2 FALSE      3                0
#> 22            oup  2026-08-23        1 FALSE      7                1
#>    unharvested  origin
#> 13          26 figspec
#> 1           17 figspec
#> 3           13 figspec
#> 4           25 figspec
#> 5           21 figspec
#> 6           20 figspec
#> 7           19 figspec
#> 9           22 figspec
#> 10          21 figspec
#> 11          25 figspec
#> 2           14 figspec
#> 8           20 figspec
#> 12          25 figspec
#> 14          22 figspec
#> 15          19 figspec
#> 16          24 figspec
#> 17          25 figspec
#> 18          23 figspec
#> 19          18 figspec
#> 20          21 figspec
#> 21          24 figspec
#> 23          24 figspec
#> 24          23 figspec
#> 25          24 figspec
#> 26          17 figspec
#> 27          24 figspec
#> 28          25    user
#> 22          20 figspec
registry_status(max_age_days = 30)
#>                id verified_on age_days stale stated confirmed_absent
#> 13            aps  2026-04-04      142  TRUE      2                0
#> 1        plos_one  2026-08-21        3 FALSE     11                0
#> 3      cell_press  2026-08-21        3 FALSE     15                0
#> 4  star_protocols  2026-08-21        3 FALSE      3                0
#> 5       frontiers  2026-08-21        3 FALSE      6                1
#> 6             iop  2026-08-21        3 FALSE      5                3
#> 7       cambridge  2026-08-21        3 FALSE      7                2
#> 9      copernicus  2026-08-21        3 FALSE      4                2
#> 10          wiley  2026-08-21        3 FALSE      5                2
#> 11            jss  2026-08-21        3 FALSE      1                2
#> 2          nature  2026-08-22        2 FALSE     14                0
#> 8   royal_society  2026-08-22        2 FALSE      6                2
#> 12        science  2026-08-22        2 FALSE      3                0
#> 14       elsevier  2026-08-22        2 FALSE      6                0
#> 15 taylor_francis  2026-08-22        2 FALSE      8                1
#> 16            agu  2026-08-22        2 FALSE      2                2
#> 17           mdpi  2026-08-22        2 FALSE      2                1
#> 18           sage  2026-08-22        2 FALSE      4                1
#> 19           pnas  2026-08-22        2 FALSE     10                0
#> 20            acs  2026-08-22        2 FALSE      7                0
#> 21            bmj  2026-08-22        2 FALSE      4                0
#> 23 ieee_magazines  2026-08-22        2 FALSE      4                0
#> 24      rsc_books  2026-08-22        2 FALSE      5                0
#> 25           ieee  2026-08-22        2 FALSE      4                0
#> 26       springer  2026-08-22        2 FALSE     11                0
#> 27            rsc  2026-08-22        2 FALSE      4                0
#> 28     lab_report  2026-08-22        2 FALSE      3                0
#> 22            oup  2026-08-23        1 FALSE      7                1
#>    unharvested  origin
#> 13          26 figspec
#> 1           17 figspec
#> 3           13 figspec
#> 4           25 figspec
#> 5           21 figspec
#> 6           20 figspec
#> 7           19 figspec
#> 9           22 figspec
#> 10          21 figspec
#> 11          25 figspec
#> 2           14 figspec
#> 8           20 figspec
#> 12          25 figspec
#> 14          22 figspec
#> 15          19 figspec
#> 16          24 figspec
#> 17          25 figspec
#> 18          23 figspec
#> 19          18 figspec
#> 20          21 figspec
#> 21          24 figspec
#> 23          24 figspec
#> 24          23 figspec
#> 25          24 figspec
#> 26          17 figspec
#> 27          24 figspec
#> 28          25    user
#> 22          20 figspec
```
