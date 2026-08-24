# Check a figure against a journal's requirements

Accepts either a ggplot object, checked before it is saved, or the path
to a figure file that has already been written.

## Usage

``` r
fig_check(
  x,
  journal = NULL,
  column = "single",
  width = NULL,
  height = NULL,
  units = c("mm", "cm", "in"),
  dpi = NULL,
  format = NULL,
  art_type = c("colour", "bw", "line", "combination")
)
```

## Arguments

- x:

  A ggplot object, or a path to a figure file.

- journal:

  Registry id, for example `"frontiers"`.

- column:

  Which column width the figure is intended for. One of `"single"`,
  `"onehalf"` or `"double"`.

- width, height:

  Intended output size. Defaults to the journal's width for `column`.
  Ignored when `x` is a file, whose real size is measured.

- units:

  Units for `width` and `height`.

- dpi:

  Resolution. For a ggplot object, the resolution you intend to save at.
  For a file, the resolution it was written at, which lets figspec judge
  physical size for files that do not record it themselves - base R's
  [`png()`](https://rdrr.io/r/grDevices/png.html) and
  [`tiff()`](https://rdrr.io/r/grDevices/png.html) devices do not,
  whereas ragg does.

- format:

  Output format, for example `"tiff"`. Only used when `x` is a ggplot
  object.

- art_type:

  Which resolution rule applies. Publishers set different minimums for
  different kinds of artwork: Cell Press asks 300 dpi for colour or
  greyscale, 500 for black and white, and 1000 for line art. figspec
  cannot tell which one your figure is, so it checks against `"colour"`
  by default and names the other thresholds in the report rather than
  quietly applying the most lenient one. `"color"` is accepted too.

## Value

An object of class `figspec_report`, a data frame of one row per
requirement.

## Details

Each requirement is reported with one of four outcomes. `pass` and
`fail` mean what they say. `unspecified` means the publisher does not
state that requirement, so nothing can be concluded. `unknown` means the
requirement exists but this input cannot answer it, for example type
size in a raster file. Only `fail` is a problem you must fix;
`unspecified` and `unknown` are prompts to check by hand.

Type size is read back from PDF, EPS and SVG files, which record the
size each string was set at. This is worth doing rather than trusting
the plot object, because R's
[`pdf()`](https://rdrr.io/r/grDevices/pdf.html) and
[`postscript()`](https://rdrr.io/r/grDevices/postscript.html) devices
round text to whole points: a theme asking for 8.8 pt writes 9 pt into
the file, and one asking for 5.2 pt writes 5. The file is what a
publisher receives. Reading a PDF needs the pdftools package. A raster
carries no type sizes at all, and is reported as `unknown` rather than
estimated.

## Examples

``` r
library(ggplot2)
p <- ggplot(mtcars, aes(wt, mpg)) + geom_point()
fig_check(p, "frontiers")
#> 
#> ── Frontiers journals ──────────────────────────────────────────────────────────
#> checked: ggplot object
#> 
#> ✔ Width         85 mm
#>                 requires: single 85 mm | double 180 mm
#> ! Height        -
#>                 requires: not yet harvested for this journal
#> ! Resolution    could not determine         requires: min 300 dpi for colour
#> ! File format   could not determine         requires: TIFF, JPEG, EPS
#> ✔ Type size     smallest     8.8 pt, largest      11 pt  requires: min 8 pt
#> ! Font          -
#>                 requires: not yet harvested for this journal
#> ! Line width    could not determine         requires: min 2 pt
#> ✔ Colour mode   RGB                         requires: RGB
#> ℹ Colour pairs  no red/green pairing        requires: not specified by publisher
#> ℹ Greyscale     all colours separable in greyscale
#>                 requires: not specified by publisher
#> ℹ Colour vision separable under deuteranopia, protanopia and tritanopia
#>                 requires: not specified by publisher
#> ℹ File size     -                           requires: not specified by publisher
#> 
#> ✔ No failures against the requirements on record.
#> ℹ 9 requirements could not be judged automatically - check by hand.
#> Source: <https://www.frontiersin.org/guidelines/author-guidelines> (verified
#> 2026-08-21)
```
