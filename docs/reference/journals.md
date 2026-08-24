# List the journals in the registry

Returns one row per registry entry, with the figure requirements that
are most often needed at a glance. Requirements a publisher does not
state are returned as `NA`, which means *unspecified*, not *unlimited*.

## Usage

``` r
journals(discipline = NULL)
```

## Arguments

- discipline:

  Optional character vector. Keep only entries tagged with at least one
  of these disciplines, for example `"physics"`.

## Value

A data frame with one row per journal.

## Examples

``` r
journals()
#>                id                                    name
#> 1        plos_one                                PLOS ONE
#> 2          nature                                  Nature
#> 3      cell_press                     Cell Press journals
#> 4  star_protocols                          STAR Protocols
#> 5       frontiers                      Frontiers journals
#> 6             iop                 IOP Publishing journals
#> 7       cambridge     Cambridge University Press journals
#> 8   royal_society                  Royal Society journals
#> 9      copernicus        Copernicus Publications journals
#> 10          wiley                          Wiley journals
#> 11            jss         Journal of Statistical Software
#> 12        science                                 Science
#> 13            aps      American Physical Society journals
#> 14       elsevier                       Elsevier journals
#> 15 taylor_francis Taylor & Francis and Routledge journals
#> 16            agu     American Geophysical Union journals
#> 17           mdpi                           MDPI journals
#> 18           sage                           Sage journals
#> 19           pnas                                    PNAS
#> 20            acs      American Chemical Society journals
#> 21            bmj                            BMJ journals
#> 22            oup        Oxford University Press journals
#> 23 ieee_magazines                          IEEE magazines
#> 24      rsc_books        Royal Society of Chemistry books
#> 25           ieee                           IEEE journals
#> 26       springer                       Springer journals
#> 27            rsc     Royal Society of Chemistry journals
#>                                publisher
#> 1                                   PLOS
#> 2                        Springer Nature
#> 3                  Cell Press (Elsevier)
#> 4                  Cell Press (Elsevier)
#> 5                        Frontiers Media
#> 6                         IOP Publishing
#> 7             Cambridge University Press
#> 8                      The Royal Society
#> 9                       Copernicus (EGU)
#> 10                                 Wiley
#> 11 Foundation for Open Access Statistics
#> 12                                  AAAS
#> 13             American Physical Society
#> 14                              Elsevier
#> 15                      Taylor & Francis
#> 16                           AGU (Wiley)
#> 17                                  MDPI
#> 18                       Sage Publishing
#> 19          National Academy of Sciences
#> 20                                   ACS
#> 21                                   BMJ
#> 22               Oxford University Press
#> 23                                  IEEE
#> 24            Royal Society of Chemistry
#> 25                                  IEEE
#> 26                       Springer Nature
#> 27            Royal Society of Chemistry
#>                                          disciplines single_mm double_mm
#> 1                                  multidisciplinary      66.8     190.5
#> 2                                  multidisciplinary      90.0     180.0
#> 3                          life-sciences, biomedical      85.0     174.0
#> 4                             life-sciences, methods     134.0     172.0
#> 5                                  multidisciplinary      85.0     180.0
#> 6                               physics, engineering      85.0     150.0
#> 7     multidisciplinary, humanities, social-sciences        NA        NA
#> 8                                  multidisciplinary        NA        NA
#> 9  earth-sciences, atmospheric-sciences, environment      80.0        NA
#> 10                                 multidisciplinary      80.0     180.0
#> 11                             statistics, computing        NA        NA
#> 12                                 multidisciplinary      57.0     121.0
#> 13                                           physics      85.0        NA
#> 14                                 multidisciplinary      90.0     190.0
#> 15    multidisciplinary, social-sciences, humanities        NA        NA
#> 16        earth-sciences, space-science, environment        NA        NA
#> 17                                 multidisciplinary        NA        NA
#> 18        social-sciences, multidisciplinary, health        NA        NA
#> 19                                 multidisciplinary        NA        NA
#> 20                      chemistry, materials-science      84.7     177.8
#> 21                                  medicine, health        NA        NA
#> 22           multidisciplinary, medicine, humanities        NA        NA
#> 23                     engineering, computer-science      88.9     181.9
#> 24                                         chemistry        NA     200.0
#> 25        engineering, computer-science, electronics      88.9     182.0
#> 26                                 multidisciplinary      84.0     174.0
#> 27                      chemistry, materials-science      83.0     171.0
#>    dpi_min font_min_pt max_file_mb verified_on  origin
#> 1      300         8.0          10  2026-08-21 figspec
#> 2      300         5.0          NA  2026-08-22 figspec
#> 3      300         6.0          20  2026-08-21 figspec
#> 4       NA          NA          20  2026-08-21 figspec
#> 5      300         8.0          NA  2026-08-21 figspec
#> 6       NA         8.0          NA  2026-08-21 figspec
#> 7      300         9.0          NA  2026-08-21 figspec
#> 8       NA         7.5          NA  2026-08-22 figspec
#> 9      300          NA           5  2026-08-21 figspec
#> 10     300          NA          10  2026-08-21 figspec
#> 11      NA          NA          NA  2026-08-21 figspec
#> 12     300         5.0          NA  2026-08-22 figspec
#> 13      NA          NA          NA  2026-04-04 figspec
#> 14     300         6.0          NA  2026-08-22 figspec
#> 15     300          NA          NA  2026-08-22 figspec
#> 16      NA          NA          NA  2026-08-22 figspec
#> 17     600          NA          NA  2026-08-22 figspec
#> 18     300          NA          NA  2026-08-22 figspec
#> 19     300         6.0          NA  2026-08-22 figspec
#> 20     300         4.5          NA  2026-08-22 figspec
#> 21     300          NA          NA  2026-08-22 figspec
#> 22     300         7.0          NA  2026-08-23 figspec
#> 23     300          NA          NA  2026-08-22 figspec
#> 24     600          NA          NA  2026-08-22 figspec
#> 25     300          NA          NA  2026-08-22 figspec
#> 26     300         8.0          NA  2026-08-22 figspec
#> 27     600          NA          NA  2026-08-22 figspec
journals(discipline = "physics")
#>    id                               name                 publisher
#> 1 iop            IOP Publishing journals            IOP Publishing
#> 2 aps American Physical Society journals American Physical Society
#>            disciplines single_mm double_mm dpi_min font_min_pt max_file_mb
#> 1 physics, engineering        85       150      NA           8          NA
#> 2              physics        85        NA      NA          NA          NA
#>   verified_on  origin
#> 1  2026-08-21 figspec
#> 2  2026-04-04 figspec
```
