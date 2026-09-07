# Verify a supplementary media file

Checks container format, frame size, file size, video codec and audio
bit rate. Codec and bit rate are read with the system `ffprobe`
executable when it is available; without it those rows are reported as
`unknown`, never guessed.

## Usage

``` r
media_check(path, spec)
```

## Arguments

- path:

  One path to an existing media file.

- spec:

  A registry id, a `figspec_spec`, or a named list containing
  supplementary media requirements.

## Value

A `figspec_report`.

## Examples

``` r
# A real, valid 1 x 1 pixel GIF written to a temporary file.
gif_hex <- c(
  "47", "49", "46", "38", "39", "61", "01", "00", "01", "00",
  "80", "00", "00", "00", "00", "00", "ff", "ff", "ff", "21",
  "f9", "04", "01", "00", "00", "00", "00", "2c", "00", "00",
  "00", "00", "01", "00", "01", "00", "00", "02", "02", "44",
  "01", "00", "3b"
)
media_file <- tempfile(fileext = ".gif")
writeBin(as.raw(strtoi(gif_hex, 16L)), media_file)

project_media_spec <- list(
  name = "Project media handoff",
  media = list(
    video_formats = "gif",
    frame_max = list(width = 1280, height = 720),
    max_file_mb = 1
  )
)
media_check(media_file, project_media_spec)
#>
#> ── Project media handoff ───────────────────────────────────────────────────────
#> checked:
#> /var/folders/nr/p09jj77n7jn9606qt_2m77nc0000gn/T//Rtmpfw8GmK/file1506bbdeb79f.gif
#>
#> ✔ File validity valid                       requires: valid media container
#> ✔ Format        GIF                         requires: GIF
#> ✔ Frame size    1 x 1                       requires: max 1280 x 720
#> ✔ File size     0 MB                        requires: max 1 MB
#> ! Video codec   gif
#>                 requires: not yet reviewed for this specification
#>
#> ! No failures were found, but this assessment is incomplete.
#> ℹ 1 requirement or registry field could not be judged automatically - check by
#>   hand.
unlink(media_file)
```
