# Look up supplementary media requirements

Publications and projects may set separate rules for video and audio:
container format, codec, frame size, bit rate and file size. These are
not figure requirements and are therefore kept separate from
[`fig_check()`](https://dansemakula.github.io/figspec/reference/fig_check.md).

## Usage

``` r
media_spec(spec)
```

## Arguments

- spec:

  A registry id such as `"science"`, a `figspec_spec`, or a named list
  of requirements.

## Value

A list of the stated media requirements, or `NULL` with a message when
the selected specification records none.

## Examples

``` r
media_spec("science")
#>
#> ── Science - supplementary media ───────────────────────────────────────────────
#> • Video formats: MP4, MOV
#> • Video codec: H.264
#> • Maximum frame size: 1920 x 1080
#> • Preferred frame sizes: 640 x 480 or 1280 x 720
#> • Maximum file size: 50 MB
#> • Audio formats: WAV, MP3, M4A
#> • Audio bit rate: 160 kb/s
#>
#> Aim to stay within 640 x 480 or 1280 x 720 resolution. Do not exceed full HD
#> frame size (1920 x 1080)
#>
#> Source:
#> <https://www.science.org/content/page/instructions-preparing-initial-manuscript>
#> (verified 2026-08-22)
#> Applies at: initial submission
```
