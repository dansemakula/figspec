# Build a minimal MP4 carrying a tkhd box with a known display size, so the
# parser is tested against bytes we control rather than a file we hope about.
write_fake_mp4 <- function(path, width, height, version = 0L) {
  be32 <- function(x) as.raw(c(
    bitwAnd(bitwShiftR(x, 24), 255L), bitwAnd(bitwShiftR(x, 16), 255L),
    bitwAnd(bitwShiftR(x, 8), 255L), bitwAnd(x, 255L)
  ))
  fixed <- function(x) be32(as.integer(x * 65536))
  body <- c(
    as.raw(version), as.raw(c(0, 0, 0)),                  # version + flags
    as.raw(rep(0, if (version == 1L) 32L else 20L)),      # times, id, duration
    as.raw(rep(0, 16L)),                                  # reserved, layer, volume
    as.raw(rep(0, 36L)),                                  # transform matrix
    fixed(width), fixed(height)
  )
  box <- c(be32(length(body) + 8L), charToRaw("tkhd"), body)
  writeBin(c(be32(20L), charToRaw("ftyp"), charToRaw("isom"), as.raw(rep(0, 8)), box),
           path)
}

write_fake_gif <- function(path, width, height) {
  le16 <- function(x) as.raw(c(bitwAnd(x, 255L), bitwAnd(bitwShiftR(x, 8), 255L)))
  writeBin(c(charToRaw("GIF89a"), le16(width), le16(height), as.raw(rep(0, 20))), path)
}

test_that("media requirements are surfaced where recorded and absent otherwise", {
  m <- media_spec("science")
  expect_s3_class(m, "figspec_media_spec")
  expect_equal(m$frame_max$width, 1920)
  expect_equal(m$max_file_mb, 50)
  expect_message(media_spec("plos_one"), "No supplementary media")
})

test_that("MP4 frame size is read from the tkhd box", {
  f <- withr::local_tempfile(fileext = ".mp4")
  write_fake_mp4(f, 1280, 720)
  expect_equal(read_mp4_frame(f), list(width = 1280, height = 720))

  f2 <- withr::local_tempfile(fileext = ".mp4")
  write_fake_mp4(f2, 1920, 1080, version = 1L)
  expect_equal(read_mp4_frame(f2), list(width = 1920, height = 1080))
})

test_that("GIF frame size is read from the header", {
  f <- withr::local_tempfile(fileext = ".gif")
  write_fake_gif(f, 800, 600)
  expect_equal(read_gif_frame(f), list(width = 800, height = 600))
})

test_that("an oversized frame fails Science's stated maximum", {
  f <- withr::local_tempfile(fileext = ".mp4")
  write_fake_mp4(f, 3840, 2160)
  r <- check_media(f, "science")
  expect_equal(r[r$check == "Frame size", ]$status, "fail")
  expect_equal(r[r$check == "Format", ]$status, "pass")
})

test_that("a frame inside the maximum passes", {
  f <- withr::local_tempfile(fileext = ".mp4")
  write_fake_mp4(f, 1280, 720)
  r <- check_media(f, "science")
  expect_equal(r[r$check == "Frame size", ]$status, "pass")
  expect_equal(r[r$check == "File size", ]$status, "pass")
})

test_that("a format the journal does not accept fails", {
  f <- withr::local_tempfile(fileext = ".avi")
  writeBin(as.raw(rep(0, 100)), f)
  r <- check_media(f, "science")
  expect_equal(r[r$check == "Format", ]$status, "fail")
})

test_that("codec is reported as not inspected rather than guessed", {
  f <- withr::local_tempfile(fileext = ".mp4")
  write_fake_mp4(f, 640, 480)
  r <- check_media(f, "science")
  expect_equal(r[r$check == "Codec", ]$status, "unknown")
  expect_match(r[r$check == "Codec", ]$actual, "does not decode")
})

test_that("checking media against a journal with no media rules is refused", {
  f <- withr::local_tempfile(fileext = ".mp4")
  write_fake_mp4(f, 640, 480)
  expect_error(check_media(f, "plos_one"), "No supplementary media")
})
