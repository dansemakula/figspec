# check_sources() reaches the network, so what is tested here is the judgement
# it applies to a response, not the fetching. The judgement is the part that
# matters: seven of the registry's 27 publishers answer 403 to a scripted
# request while their page is perfectly alive, so reading a refusal as a death
# would produce seven false alarms for every true one.

test_that("a refusal to serve a robot is not a dead link", {
  for (code in c(401L, 403L, 405L, 406L, 429L, 451L, 501L)) {
    expect_equal(source_verdict(code), "blocked",
                 info = paste("HTTP", code))
  }
})

test_that("only gone means gone", {
  expect_equal(source_verdict(404L), "dead")
  expect_equal(source_verdict(410L), "dead")
})

test_that("a 403 is never reported as dead, whatever else changes", {
  # The single assertion this whole function exists to satisfy.
  expect_false(source_verdict(403L) == "dead")
})

test_that("a response that arrives is ok, and silence is not an error code", {
  for (code in c(200L, 201L, 204L, 299L)) expect_equal(source_verdict(code), "ok")
  expect_equal(source_verdict(NA_integer_), "unreachable")
  expect_equal(source_verdict(500L), "server error")
  expect_equal(source_verdict(503L), "server error")
  expect_equal(source_verdict(418L), "unexpected")
})

test_that("an unknown id is a figspec_not_found error, not a fetch", {
  skip_if_not_installed("curl")
  expect_error(check_sources("no_such_journal"), class = "figspec_not_found")
})

# A stand-in for what a live run returns, so the report can be tested without
# asking seven publishers whether they are still there.
fake_sources <- function() {
  structure(
    data.frame(
      id = c("gone", "blocked_one", "blocked_two", "fine"),
      url = c("https://example.org/a", "https://example.org/b",
              "https://example.org/c", "https://example.org/d"),
      http = c(404L, 403L, 429L, 200L),
      verdict = c("dead", "blocked", "blocked", "ok"),
      final_url = c(NA_character_, NA_character_, NA_character_, NA_character_),
      stringsAsFactors = FALSE
    ),
    class = c("figspec_sources", "data.frame")
  )
}

test_that("the report counts blocked separately from gone", {
  out <- capture.output(print(fake_sources()), type = "message")
  txt <- paste(out, collapse = " ")
  expect_match(txt, "1 source is gone")
  expect_match(txt, "gone")
  expect_match(txt, "2 blocked the request")
  expect_match(txt, "not a failure")
})

test_that("a blocked source is not named among the gone", {
  out <- capture.output(print(fake_sources()), type = "message")
  header <- grep("sources? (is|are) gone", out)
  expect_length(header, 1)
  # Only entries whose verdict is "dead" may appear in the list under it.
  bullets <- grep("^[^A-Za-z0-9]* ", out[seq(header + 1L, length(out))],
                  value = TRUE)
  bullets <- bullets[grepl("https://example.org", bullets)]
  expect_true(any(grepl("gone", bullets)))
  expect_false(any(grepl("blocked_one|blocked_two", bullets)))
})

test_that("a clean sweep says so rather than staying silent", {
  clean <- fake_sources()[4, , drop = FALSE]
  class(clean) <- c("figspec_sources", "data.frame")
  out <- capture.output(print(clean), type = "message")
  expect_match(paste(out, collapse = " "), "No source is gone")
})

test_that("a redirect is reported without being called a failure", {
  moved <- fake_sources()[4, , drop = FALSE]
  moved$final_url <- "https://example.org/moved"
  class(moved) <- c("figspec_sources", "data.frame")
  out <- capture.output(print(moved), type = "message")
  txt <- paste(out, collapse = " ")
  expect_match(txt, "redirected")
  expect_match(txt, "No source is gone")
})
