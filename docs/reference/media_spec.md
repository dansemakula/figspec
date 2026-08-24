# Supplementary media requirements for a journal

Journals publish separate rules for video and audio submitted as
supplementary material: container format, codec, frame size and file
size. These are not figure requirements and are not checked by
[`fig_check()`](https://dansemakula.github.io/figspec/reference/fig_check.md).

## Usage

``` r
media_spec(journal)
```

## Arguments

- journal:

  Registry id, for example `"science"`.

## Value

A list of the stated media requirements, or `NULL` with a message when
the registry records none for that journal.

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
```
