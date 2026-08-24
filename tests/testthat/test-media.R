# Supplementary media and graphical abstracts: the requirements a journal
# states for them, and reading a frame size out of a video file.
#
# The frame readers parse container headers by hand, so the fixtures here are
# minimal files built byte by byte rather than real recordings.

# A GIF header is the whole of what the reader needs: the signature, then the
# logical screen width and height as two-byte little-endian integers.
write_gif <- function(width, height) {
  path <- tempfile(fileext = ".gif")
  le <- function(v) as.raw(c(v %% 256, v %/% 256))
  writeBin(c(charToRaw("GIF89a"), le(width), le(height)), path)
  path
}

# An MP4 keeps its track dimensions in a `tkhd` atom, as 16.16 fixed-point
# numbers 76 bytes past the version byte. Everything before and between is
# padding as far as this reader is concerned.
write_mp4 <- function(width, height) {
  path <- tempfile(fileext = ".mp4")
  fixed <- function(v) {
    x <- v * 65536
    as.raw(c(x %/% 16777216, (x %/% 65536) %% 256, (x %/% 256) %% 256, x %% 256))
  }
  buf <- c(
    as.raw(rep(0L, 8L)),          # leading bytes the reader skips over
    charToRaw("tkhd"),            # the atom it searches for
    as.raw(0L),                   # version 0, which sets the field offsets
    as.raw(rep(0L, 75L)),         # flags, timestamps, matrix
    fixed(width), fixed(height),
    as.raw(rep(0L, 8L))
  )
  writeBin(buf, path)
  path
}

test_that("a GIF gives up its frame size", {
  f <- write_gif(640, 480); on.exit(unlink(f))
  expect_equal(read_gif_frame(f), list(width = 640, height = 480))
})

test_that("a file that is not a GIF is refused rather than misread", {
  f <- tempfile(fileext = ".gif"); on.exit(unlink(f))
  writeBin(charToRaw("not a gif at all"), f)
  expect_null(read_gif_frame(f))
})

test_that("a truncated GIF yields nothing rather than a partial size", {
  f <- tempfile(fileext = ".gif"); on.exit(unlink(f))
  writeBin(charToRaw("GIF"), f)
  expect_null(read_gif_frame(f))
})

test_that("an MP4 gives up its frame size", {
  f <- write_mp4(1920, 1080); on.exit(unlink(f))
  got <- read_mp4_frame(f)
  expect_equal(got$width, 1920)
  expect_equal(got$height, 1080)
})

test_that("a file with no track header yields nothing", {
  f <- tempfile(fileext = ".mp4"); on.exit(unlink(f))
  writeBin(as.raw(rep(0L, 200L)), f)
  expect_null(read_mp4_frame(f))
})

test_that("a video within the stated frame size passes", {
  f <- write_mp4(1280, 720); on.exit(unlink(f))
  r <- check_media(f, "science")
  expect_s3_class(r, "figspec_report")
  expect_false(any(r$status == "fail"))
})

test_that("a video above the stated maximum fails on frame size", {
  # Science states 1920 x 1080 as the ceiling.
  f <- write_mp4(3840, 2160); on.exit(unlink(f))
  r <- check_media(f, "science")
  expect_true(any(r$status == "fail"))
})

test_that("a container the journal does not list is reported", {
  f <- write_gif(640, 480); on.exit(unlink(f))
  r <- check_media(f, "science")
  fmt <- r[grepl("format", r$check, ignore.case = TRUE), ]
  expect_gt(nrow(fmt), 0)
})

test_that("media requirements print, and their absence is stated", {
  out <- capture.output(print(media_spec("science")), type = "message")
  txt <- paste(out, collapse = " ")
  expect_match(txt, "Science")
  expect_match(txt, "mp4|MP4")
  expect_message(none <- media_spec("cell_press"), "media")
  expect_null(none)
})

test_that("graphical abstract requirements print, and their absence is stated", {
  out <- capture.output(print(graphical_abstract_spec("rsc")), type = "message")
  expect_gt(length(out), 1)
  expect_message(none <- graphical_abstract_spec("cell_press"), "graphical abstract")
  expect_null(none)
})

test_that("codec is reported as not inspected rather than guessed", {
  # Reading a container header gives the frame size but says nothing about how
  # the video inside it was encoded. A journal that names a codec therefore
  # gets an honest "not determined", never a pass.
  f <- write_mp4(640, 480); on.exit(unlink(f))
  r <- check_media(f, "science")
  codec <- r[r$check == "Codec", ]
  expect_equal(codec$status, "unknown")
  expect_match(codec$actual, "does not decode")
})

test_that("checking media against a journal with no media rules is refused", {
  # There is nothing to check against, and reporting a set of empty rows would
  # read as a figure that met requirements nobody stated.
  f <- write_mp4(640, 480); on.exit(unlink(f))
  expect_error(check_media(f, "plos_one"), "No supplementary media")
})
