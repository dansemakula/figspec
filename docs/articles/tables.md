# Build and check tables from R

Tables often have requirements of their own. A report may require 9
point Arial text and no vertical lines. A journal may require an
editable Word table, a portrait page, a short title and abbreviations
explained below the table. These are not figure rules, and figspec keeps
them separate.

This guide shows the complete table workflow: describe the table you
need, apply the requirements while it is editable, export it, and check
the file that was actually written.

## Describe the table you need

A table specification uses a `tables` section. This example defines the
requirements for a research report directly in R, so you can see exactly
what will be applied:

`report_spec`` ``<-`` `[`list`](https://rdrr.io/r/base/list.html)`(`` `` name ``=`` ``"Clinical research report"``,`` `` source_url ``=`` ``"internal:report-table-guide"``,`` `` verified_on ``=`` `[`as.character`](https://rdrr.io/r/base/character.html)`(`[`Sys.Date`](https://rdrr.io/r/base/Sys.time.html)`(``)``)``,`` `` tables ``=`` `[`list`](https://rdrr.io/r/base/list.html)`(`` `` formats ``=`` `[`c`](https://rdrr.io/r/base/c.html)`(``"html"``, ``"docx"``)``,`` `` orientation ``=`` ``"portrait"``,`` `` font_families ``=`` ``"Arial"``,`` `` font_min_pt ``=`` ``9``,`` `` header_bold ``=`` ``TRUE``,`` `` vertical_rules ``=`` ``FALSE``,`` `` horizontal_rules ``=`` ``"minimal"``,`` `` repeat_header ``=`` ``TRUE`` `` ``)`` ``)`` `` `[`table_spec`](https://dansemakula.github.io/figspec/reference/table_spec.md)`(``report_spec``)`` ``#> `` ``#> ``──`` ``Clinical research report - tables`` ``───────────────────────────────────────────`` ``#> • ``Formats:`` html and docx`` ``#> • ``Orientation:`` portrait`` ``#> • ``Font families:`` Arial`` ``#> • ``Font min pt:`` 9`` ``#> • ``Header bold:`` TRUE`` ``#> • ``Vertical rules:`` FALSE`` ``#> • ``Horizontal rules:`` minimal`` ``#> • ``Repeat header:`` TRUE`` ``#> `` ``#> ``Source:`` ``<internal:report-table-guide>`` (verified 2026-09-06)`

The same specification can be kept with the project and reused in later
R sessions:

`table_spec_file`` ``<-`` `[`file.path`](https://rdrr.io/r/base/file.path.html)`(`[`tempdir`](https://rdrr.io/r/base/tempfile.html)`(``)``, ``"clinical-report-specifications.yml"``)`` `[`spec_save`](https://dansemakula.github.io/figspec/reference/spec_save.md)`(``report_spec``, ``table_spec_file``, id ``=`` ``"clinical_research_report"``)`` `[`spec_load`](https://dansemakula.github.io/figspec/reference/spec_load.md)`(``table_spec_file``)`

The saved entry retains both table and figure requirements. Loading it
makes the project specification available in the current R session while
leaving the installed package unchanged.

Bundled publication profiles can be used in the same way when their
table requirements have been reviewed.
[`registry_status()`](https://dansemakula.github.io/figspec/reference/registry_status.md)
shows table coverage separately from figure coverage; an empty table
section means that figspec has not yet reviewed that profile’s table
guidance.

## Apply the requirements before export

We will use 12 real observations from
[`ggplot2::mpg`](https://ggplot2.tidyverse.org/reference/mpg.html). The
plain data frame is useful data, but it does not yet record a font size,
header treatment or rule style.

`vehicle_table`` ``<-`` ``mpg``[``1``:``12``, `[`c`](https://rdrr.io/r/base/c.html)`(`` `` ``"manufacturer"``, ``"model"``, ``"displ"``, ``"year"``, ``"hwy"`` ``)``]`` `` ``knitr``::`[`kable`](https://rdrr.io/pkg/knitr/man/kable.html)`(``vehicle_table``)`

| manufacturer | model      | displ | year | hwy |
|:-------------|:-----------|------:|-----:|----:|
| audi         | a4         |   1.8 | 1999 |  29 |
| audi         | a4         |   1.8 | 1999 |  29 |
| audi         | a4         |   2.0 | 2008 |  31 |
| audi         | a4         |   2.0 | 2008 |  30 |
| audi         | a4         |   2.8 | 1999 |  26 |
| audi         | a4         |   2.8 | 1999 |  26 |
| audi         | a4         |   3.1 | 2008 |  27 |
| audi         | a4 quattro |   1.8 | 1999 |  26 |
| audi         | a4 quattro |   1.8 | 1999 |  25 |
| audi         | a4 quattro |   2.0 | 2008 |  28 |
| audi         | a4 quattro |   2.0 | 2008 |  27 |
| audi         | a4 quattro |   2.8 | 1999 |  25 |

[`table_apply_spec()`](https://dansemakula.github.io/figspec/reference/table_apply_spec.md)
turns the data frame into an editable gt table and applies the
requirements the table system can express:

`styled_table`` ``<-`` `[`table_apply_spec`](https://dansemakula.github.io/figspec/reference/table_apply_spec.md)`(``vehicle_table``, ``report_spec``)`` ``styled_table`

| manufacturer | model      | displ | year | hwy |
|--------------|------------|-------|------|-----|
| audi         | a4         | 1.8   | 1999 | 29  |
| audi         | a4         | 1.8   | 1999 | 29  |
| audi         | a4         | 2.0   | 2008 | 31  |
| audi         | a4         | 2.0   | 2008 | 30  |
| audi         | a4         | 2.8   | 1999 | 26  |
| audi         | a4         | 2.8   | 1999 | 26  |
| audi         | a4         | 3.1   | 2008 | 27  |
| audi         | a4 quattro | 1.8   | 1999 | 26  |
| audi         | a4 quattro | 1.8   | 1999 | 25  |
| audi         | a4 quattro | 2.0   | 2008 | 28  |
| audi         | a4 quattro | 2.0   | 2008 | 27  |
| audi         | a4 quattro | 2.8   | 1999 | 25  |

The rows and values have not changed. The difference is that the
editable table now carries the required type size, font, header emphasis
and rule choices.
[`table_check()`](https://dansemakula.github.io/figspec/reference/table_check.md)
can inspect those properties before any file is written:

[`table_check`](https://dansemakula.github.io/figspec/reference/table_check.md)`(``styled_table``, ``report_spec``)`` ``#> `` ``#> ``──`` ``Clinical research report`` ``────────────────────────────────────────────────────`` ``#> ``checked: gt table object`` ``#> `` ``#> ``✔`` File validity valid requires: readable table object`` ``#> ``!`` File format could not determine requires: HTML, DOCX`` ``#> ``✔`` Font family Arial requires: Arial`` ``#> ``!`` Orientation could not determine requires: portrait`` ``#> ``✔`` Minimum type size 9 requires: 9`` ``#> ``✔`` Bold header TRUE requires: TRUE`` ``#> ``✔`` Vertical rules FALSE requires: FALSE`` ``#> ``✔`` Horizontal rules minimal requires: minimal`` ``#> ``!`` Repeated header could not determine requires: TRUE`` ``#> `` ``#> ``!`` No failures were found, but this assessment is incomplete.`` ``#> ``ℹ`` 3 requirements or registry fields could not be judged automatically - check`` ``#> by hand.`` ``#> ``Source:`` ``<internal:report-table-guide>`` (verified 2026-09-06)`

At this stage, the live-table report covers the styling and structure
that can already be inspected. The file format is checked after export,
when a completed file is available.

## Export and check the completed file

[`table_save()`](https://dansemakula.github.io/figspec/reference/table_save.md)
exports through the table’s own system. It first writes a temporary file
in the destination directory, reopens and checks it, and only then
places it at the requested path.

`html_path`` ``<-`` `[`file.path`](https://rdrr.io/r/base/file.path.html)`(`[`tempdir`](https://rdrr.io/r/base/tempfile.html)`(``)``, ``"vehicle-summary.html"``)`` ``saved_table`` ``<-`` `[`table_save`](https://dansemakula.github.io/figspec/reference/table_save.md)`(`` `` ``html_path``,`` `` ``styled_table``,`` `` spec ``=`` ``report_spec``,`` `` transform ``=`` ``FALSE`` ``)`` `` `[`attr`](https://rdrr.io/r/base/attr.html)`(``saved_table``, ``"figspec_table_report"``)`` ``#> `` ``#> ``──`` ``Clinical research report`` ``────────────────────────────────────────────────────`` ``#> ``checked:`` ``#> ``/var/folders/nr/p09jj77n7jn9606qt_2m77nc0000gn/T//RtmpTnmpMS/vehicle-summary.html`` ``#> `` ``#> ``✔`` File validity valid requires: readable table object`` ``#> ``✔`` Font family Arial requires: Arial`` ``#> ``!`` Orientation could not determine requires: portrait`` ``#> ``✔`` Minimum type size 9 requires: 9`` ``#> ``✔`` Bold header TRUE requires: TRUE`` ``#> ``✔`` Vertical rules FALSE requires: FALSE`` ``#> ``✔`` Horizontal rules minimal requires: minimal`` ``#> ``!`` Repeated header could not determine requires: TRUE`` ``#> ``✔`` File format html requires: HTML, DOCX`` ``#> `` ``#> ``!`` No failures were found, but this assessment is incomplete.`` ``#> ``ℹ`` 2 requirements or registry fields could not be judged automatically - check`` ``#> by hand.`` ``#> ``Source:`` ``<internal:report-table-guide>`` (verified 2026-09-06)`

The combined report now contains both kinds of evidence: styling from
the editable table and HTML format and validity from the completed file.
Use DOCX instead when an editable Word file is required:

`word_path`` ``<-`` `[`file.path`](https://rdrr.io/r/base/file.path.html)`(`[`tempdir`](https://rdrr.io/r/base/tempfile.html)`(``)``, ``"vehicle-summary.docx"``)`` `[`table_save`](https://dansemakula.github.io/figspec/reference/table_save.md)`(``word_path``, ``vehicle_table``, ``report_spec``)`

## Use the table system you already work with

Continue using the table system that suits your work. figspec accepts:

- data frames and matrices, which become gt tables;
- existing gt tables;
- flextable objects, including Word-oriented workflows;
- knitr and kableExtra tables; and
- grid tables, which can be exported as PDF or images.

The same public calls are used for all of them:

[`table_apply_spec`](https://dansemakula.github.io/figspec/reference/table_apply_spec.md)`(``my_table``, ``report_spec``)`` `[`table_save`](https://dansemakula.github.io/figspec/reference/table_save.md)`(``"my-table.docx"``, ``my_table``, ``report_spec``)`` `[`table_check`](https://dansemakula.github.io/figspec/reference/table_check.md)`(``"my-table.docx"``, ``report_spec``)`

The output formats still depend on the table system:

| Table supplied to figspec | Available output                    |
|---------------------------|-------------------------------------|
| data frame or matrix      | HTML, DOCX, RTF, TeX, PDF or PNG    |
| gt                        | HTML, DOCX, RTF, TeX, PDF or PNG    |
| flextable                 | HTML, DOCX, RTF or PNG              |
| HTML or LaTeX kable       | its native format, PDF, PNG or JPEG |
| grid table                | PDF, PNG or JPEG                    |

HTML-to-PDF or image conversion uses a local browser, while LaTeX-to-PDF
or image conversion uses a local LaTeX installation. figspec checks that
the required renderer and output combination are available before
writing the file, so the extension always matches its contents.

## Review figures and tables together

A manuscript usually contains both. Put them in one named list and let
[`submission_check()`](https://dansemakula.github.io/figspec/reference/submission_check.md)
select the appropriate checks:

`figure`` ``<-`` `[`ggplot`](https://ggplot2.tidyverse.org/reference/ggplot.html)`(``mpg``, `[`aes`](https://ggplot2.tidyverse.org/reference/aes.html)`(``displ``, ``hwy``, colour ``=`` ``drv``, shape ``=`` ``drv``)``)`` ``+`` `` `[`geom_point`](https://ggplot2.tidyverse.org/reference/geom_point.html)`(``)`` ``+`` `` `[`labs`](https://ggplot2.tidyverse.org/reference/labs.html)`(`` `` x ``=`` ``"Engine displacement (litres)"``,`` `` y ``=`` ``"Highway fuel economy"``,`` `` colour ``=`` ``"Drive layout"``,`` `` shape ``=`` ``"Drive layout"`` `` ``)`` `` ``mixed_spec`` ``<-`` ``report_spec`` ``mixed_spec``$``columns`` ``<-`` `[`list`](https://rdrr.io/r/base/list.html)`(``single ``=`` ``85``)`` ``mixed_spec``$``dpi_min`` ``<-`` ``300`` ``mixed_spec``$``formats`` ``<-`` ``"png"`` `` ``mixed_review`` ``<-`` `[`submission_check`](https://dansemakula.github.io/figspec/reference/submission_check.md)`(`` `` `[`list`](https://rdrr.io/r/base/list.html)`(`` `` fuel_economy_figure ``=`` ``figure``,`` `` vehicle_table ``=`` ``styled_table`` `` ``)``,`` `` spec ``=`` ``mixed_spec``,`` `` column ``=`` ``"single"`` ``)`` `` ``mixed_review``[``, `[`c`](https://rdrr.io/r/base/c.html)`(``"file"``, ``"asset"``, ``"result"``)``]`` ``#> file asset result`` ``#> 1 fuel_economy_figure figure incomplete`` ``#> 2 vehicle_table table incomplete`

The summary labels each item as a figure or table.
[`submission_detail()`](https://dansemakula.github.io/figspec/reference/submission_detail.md)
opens the full report for either one.

## Complete the editorial review

Some requirements are measurements: file format, page orientation,
width, font size, header emphasis or the presence of vertical rules.
figspec can apply or inspect those when the table system exposes
reliable evidence.

Other requirements ask whether a title is sufficiently short, every
abbreviation is defined or a footnote is clear. Read those parts of the
table in the context of the surrounding report or manuscript. figspec
keeps each one in the report so the editorial review can be completed
before delivery.
