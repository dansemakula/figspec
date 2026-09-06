# Review registry coverage and update dates

Shows when each bundled specification was last checked and how its
fields are accounted for. A field may contain a stated requirement, be
recorded as not stated by the source, or remain to be reviewed. The
result makes older and less complete profiles easy to identify without
implying that a missing field has no requirement.

## Usage

``` r
registry_status(max_age_days = 365, as_of = Sys.Date())
```

## Arguments

- max_age_days:

  Age beyond which an entry is flagged for rechecking. Defaults to 365.

- as_of:

  One `Date` to measure against. Defaults to today.

## Value

A data frame with one row per entry, ordered oldest first.

## Examples

``` r
registry_status()
#>                id verified_on age_days stale stated confirmed_absent
#> 13            aps  2026-04-04      155 FALSE      2                0
#> 1        plos_one  2026-08-21       16 FALSE     15                0
#> 3      cell_press  2026-08-21       16 FALSE     15                0
#> 4  star_protocols  2026-08-21       16 FALSE      3                0
#> 5       frontiers  2026-08-21       16 FALSE      8                1
#> 6             iop  2026-08-21       16 FALSE      5                3
#> 7       cambridge  2026-08-21       16 FALSE      7                2
#> 9      copernicus  2026-08-21       16 FALSE      4                2
#> 10          wiley  2026-08-21       16 FALSE      5                2
#> 11            jss  2026-08-21       16 FALSE      1                2
#> 8   royal_society  2026-08-22       15 FALSE      6                2
#> 12        science  2026-08-22       15 FALSE      3                0
#> 14       elsevier  2026-08-22       15 FALSE      6                0
#> 15 taylor_francis  2026-08-22       15 FALSE      8                1
#> 16            agu  2026-08-22       15 FALSE      2                2
#> 17           mdpi  2026-08-22       15 FALSE      2                1
#> 18           sage  2026-08-22       15 FALSE      4                1
#> 19           pnas  2026-08-22       15 FALSE     10                0
#> 20            acs  2026-08-22       15 FALSE      7                0
#> 21            bmj  2026-08-22       15 FALSE      4                0
#> 23 ieee_magazines  2026-08-22       15 FALSE      5                0
#> 24      rsc_books  2026-08-22       15 FALSE      5                0
#> 25           ieee  2026-08-22       15 FALSE      5                0
#> 26       springer  2026-08-22       15 FALSE     11                0
#> 27            rsc  2026-08-22       15 FALSE      4                0
#> 22            oup  2026-08-23       14 FALSE      7                1
#> 2          nature  2026-09-03        3 FALSE     16                0
#> 28            bmc  2026-09-03        3 FALSE      7                0
#> 29            jid  2026-09-03        3 FALSE      5                0
#>    unharvested  origin
#> 13          33 figspec
#> 1           20 figspec
#> 3           20 figspec
#> 4           32 figspec
#> 5           26 figspec
#> 6           27 figspec
#> 7           26 figspec
#> 9           29 figspec
#> 10          28 figspec
#> 11          32 figspec
#> 8           27 figspec
#> 12          32 figspec
#> 14          29 figspec
#> 15          26 figspec
#> 16          31 figspec
#> 17          32 figspec
#> 18          30 figspec
#> 19          25 figspec
#> 20          28 figspec
#> 21          31 figspec
#> 23          30 figspec
#> 24          30 figspec
#> 25          30 figspec
#> 26          24 figspec
#> 27          31 figspec
#> 22          27 figspec
#> 2           19 figspec
#> 28          28 figspec
#> 29          30 figspec
registry_status(max_age_days = 30)
#>                id verified_on age_days stale stated confirmed_absent
#> 13            aps  2026-04-04      155  TRUE      2                0
#> 1        plos_one  2026-08-21       16 FALSE     15                0
#> 3      cell_press  2026-08-21       16 FALSE     15                0
#> 4  star_protocols  2026-08-21       16 FALSE      3                0
#> 5       frontiers  2026-08-21       16 FALSE      8                1
#> 6             iop  2026-08-21       16 FALSE      5                3
#> 7       cambridge  2026-08-21       16 FALSE      7                2
#> 9      copernicus  2026-08-21       16 FALSE      4                2
#> 10          wiley  2026-08-21       16 FALSE      5                2
#> 11            jss  2026-08-21       16 FALSE      1                2
#> 8   royal_society  2026-08-22       15 FALSE      6                2
#> 12        science  2026-08-22       15 FALSE      3                0
#> 14       elsevier  2026-08-22       15 FALSE      6                0
#> 15 taylor_francis  2026-08-22       15 FALSE      8                1
#> 16            agu  2026-08-22       15 FALSE      2                2
#> 17           mdpi  2026-08-22       15 FALSE      2                1
#> 18           sage  2026-08-22       15 FALSE      4                1
#> 19           pnas  2026-08-22       15 FALSE     10                0
#> 20            acs  2026-08-22       15 FALSE      7                0
#> 21            bmj  2026-08-22       15 FALSE      4                0
#> 23 ieee_magazines  2026-08-22       15 FALSE      5                0
#> 24      rsc_books  2026-08-22       15 FALSE      5                0
#> 25           ieee  2026-08-22       15 FALSE      5                0
#> 26       springer  2026-08-22       15 FALSE     11                0
#> 27            rsc  2026-08-22       15 FALSE      4                0
#> 22            oup  2026-08-23       14 FALSE      7                1
#> 2          nature  2026-09-03        3 FALSE     16                0
#> 28            bmc  2026-09-03        3 FALSE      7                0
#> 29            jid  2026-09-03        3 FALSE      5                0
#>    unharvested  origin
#> 13          33 figspec
#> 1           20 figspec
#> 3           20 figspec
#> 4           32 figspec
#> 5           26 figspec
#> 6           27 figspec
#> 7           26 figspec
#> 9           29 figspec
#> 10          28 figspec
#> 11          32 figspec
#> 8           27 figspec
#> 12          32 figspec
#> 14          29 figspec
#> 15          26 figspec
#> 16          31 figspec
#> 17          32 figspec
#> 18          30 figspec
#> 19          25 figspec
#> 20          28 figspec
#> 21          31 figspec
#> 23          30 figspec
#> 24          30 figspec
#> 25          30 figspec
#> 26          24 figspec
#> 27          31 figspec
#> 22          27 figspec
#> 2           19 figspec
#> 28          28 figspec
#> 29          30 figspec
```
