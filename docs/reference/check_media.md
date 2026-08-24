# Check a supplementary media file against a journal's requirements

Checks container format, frame size and file size. Codec and bit rate
are recorded in the registry but are not inspected: reading them
reliably needs a media library, and reporting a guess would be worse
than reporting nothing.

## Usage

``` r
check_media(path, journal)
```

## Arguments

- path:

  Path to a media file.

- journal:

  Registry id.

## Value

A `figspec_report`.

## Examples

``` r
# check_media("movie_s1.mp4", "science")
```
