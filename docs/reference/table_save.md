# Export and verify a table

Writes a supported R table to a format available from that table system.
When a specification is supplied, figspec first applies the requirements
it can enforce, writes to a temporary file in the destination directory,
reopens that file for verification and only then replaces the requested
output.

## Usage

``` r
table_save(filename, table, spec = NULL, transform = TRUE, check = TRUE, ...)
```

## Arguments

- filename:

  Destination file. The extension selects the output format.

- table:

  A supported table object.

- spec:

  The specification to apply and check, or NULL.

- transform:

  Whether to call
  [`table_apply_spec()`](https://dansemakula.github.io/figspec/reference/table_apply_spec.md)
  before export.

- check:

  Whether to reopen and check the completed file.

- ...:

  Arguments passed to the table system's exporter.

## Value

Invisibly, the output path. A table report is attached when checking was
requested.

## Details

gt tables support HTML, DOCX, RTF, TeX, PDF and PNG. Flextable objects
support HTML, DOCX, RTF and PNG. HTML or LaTeX kable objects support
their native format and browser- or LaTeX-rendered PDF and images. Grid
tables support PDF, PNG and JPEG. Data frames and matrices use gt,
except that DOCX and RTF use flextable when it is installed. Formats
that need a browser, Pandoc or LaTeX also need those local rendering
tools.

## Examples

``` r
if (FALSE) { # \dontrun{
report_spec <- list(
  name = "Research report",
  tables = list(formats = "html", font_min_pt = 9,
                header_bold = TRUE, vertical_rules = FALSE)
)
out <- file.path(tempdir(), "summary-table.html")
table_save(out, head(mtcars), report_spec)
attr(out, "figspec_table_report")
} # }
```
