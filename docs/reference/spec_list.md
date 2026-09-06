# Browse available specification profiles

Lists the publication profiles available to figspec, including profiles
bundled with the package and any loaded for the current session. Most
bundled profiles describe guidance that applies across a publisher's
journal portfolio; others record the requirements of an individual
journal or publication type. A row in this table can therefore represent
many journals.

## Usage

``` r
spec_list(discipline = NULL)
```

## Arguments

- discipline:

  An optional character vector of discipline tags, such as `"physics"`
  or `c("health", "medicine")`. Matching is case-insensitive, and a
  profile is included when it has at least one requested tag.

## Value

A data frame with one row per specification profile.

## Details

The table includes commonly needed figure requirements and the date each
source was last checked. A requirement shown as `NA` was not recorded as
a stated value; it must not be interpreted as having no limit.

## Examples

``` r
spec_list()
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
#> 28            bmc                 BioMed Central journals
#> 29            jid      The Journal of Infectious Diseases
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
#> 28                       Springer Nature
#> 29               Oxford University Press
#>                                          disciplines single_mm double_mm
#> 1                                  multidisciplinary      66.8     190.5
#> 2                                  multidisciplinary      89.0     183.0
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
#> 28               biomedical, life-sciences, medicine      85.0     170.0
#> 29                     infectious-diseases, medicine        NA        NA
#>    dpi_min font_min_pt max_file_mb table_requirements publication_stage
#> 1      300         8.0          10              FALSE              <NA>
#> 2      300         5.0          NA               TRUE             final
#> 3      300         6.0          20              FALSE              <NA>
#> 4       NA          NA          20              FALSE              <NA>
#> 5      300         8.0          NA              FALSE              <NA>
#> 6       NA         8.0          NA              FALSE              <NA>
#> 7      300         9.0          NA              FALSE              <NA>
#> 8       NA         7.5          NA               TRUE              <NA>
#> 9      300          NA           5              FALSE              <NA>
#> 10     300          NA          10              FALSE              <NA>
#> 11      NA          NA          NA              FALSE              <NA>
#> 12     300         5.0          NA              FALSE           initial
#> 13      NA          NA          NA              FALSE              <NA>
#> 14     300         6.0          NA              FALSE              <NA>
#> 15     300          NA          NA              FALSE              <NA>
#> 16      NA          NA          NA              FALSE              <NA>
#> 17     600          NA          NA              FALSE              <NA>
#> 18     300          NA          NA              FALSE              <NA>
#> 19     300         6.0          NA              FALSE              <NA>
#> 20     300         4.5          NA              FALSE              <NA>
#> 21     300          NA          NA              FALSE              <NA>
#> 22     300         7.0          NA              FALSE              <NA>
#> 23     300          NA          NA              FALSE              <NA>
#> 24     600          NA          NA              FALSE              <NA>
#> 25     300          NA          NA              FALSE              <NA>
#> 26     300         8.0          NA              FALSE              <NA>
#> 27     600          NA          NA              FALSE              <NA>
#> 28     300          NA          10              FALSE             final
#> 29     300          NA          NA              FALSE             final
#>    verified_on  origin
#> 1   2026-08-21 figspec
#> 2   2026-09-03 figspec
#> 3   2026-08-21 figspec
#> 4   2026-08-21 figspec
#> 5   2026-08-21 figspec
#> 6   2026-08-21 figspec
#> 7   2026-08-21 figspec
#> 8   2026-08-22 figspec
#> 9   2026-08-21 figspec
#> 10  2026-08-21 figspec
#> 11  2026-08-21 figspec
#> 12  2026-08-22 figspec
#> 13  2026-04-04 figspec
#> 14  2026-08-22 figspec
#> 15  2026-08-22 figspec
#> 16  2026-08-22 figspec
#> 17  2026-08-22 figspec
#> 18  2026-08-22 figspec
#> 19  2026-08-22 figspec
#> 20  2026-08-22 figspec
#> 21  2026-08-22 figspec
#> 22  2026-08-23 figspec
#> 23  2026-08-22 figspec
#> 24  2026-08-22 figspec
#> 25  2026-08-22 figspec
#> 26  2026-08-22 figspec
#> 27  2026-08-22 figspec
#> 28  2026-09-03 figspec
#> 29  2026-09-03 figspec
spec_list(discipline = "physics")
#>    id                               name                 publisher
#> 1 iop            IOP Publishing journals            IOP Publishing
#> 2 aps American Physical Society journals American Physical Society
#>            disciplines single_mm double_mm dpi_min font_min_pt max_file_mb
#> 1 physics, engineering        85       150      NA           8          NA
#> 2              physics        85        NA      NA          NA          NA
#>   table_requirements publication_stage verified_on  origin
#> 1              FALSE              <NA>  2026-08-21 figspec
#> 2              FALSE              <NA>  2026-04-04 figspec
```
