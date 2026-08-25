#!/usr/bin/env bash
#
# Local check for figspec: everything a continuous-integration server would run,
# on this machine.
#
# vitest and friends are JavaScript tooling and cannot run R. R's equivalent is
# this: regenerate the documentation, run the test suite, build a tarball and
# check it the way CRAN will. Run it before every commit that touches R/.
#
#   ./dev/check.sh            documentation, tests, completeness audit, R CMD check
#   ./dev/check.sh --fast     tests only, for a tight edit loop
#   ./dev/check.sh --full     the above plus coverage and the pkgdown site
#
# Exits non-zero on the first failure, so it can gate a commit.

set -euo pipefail
cd "$(dirname "$0")/.."

MODE="${1:-}"
step() { printf '\n\033[1m── %s\033[0m\n' "$1"; }
fail() { printf '\033[31mFAILED: %s\033[0m\n' "$1"; exit 1; }

step "Documentation"
Rscript -e 'roxygen2::roxygenise(".")' || fail "roxygen"

step "Tests"
Rscript -e '
  pkgload::load_all(".", quiet = TRUE)
  res <- testthat::test_dir("tests/testthat", stop_on_failure = FALSE)
  df <- as.data.frame(res)
  bad <- sum(df$failed) + sum(df$error)
  cat(sprintf("\n%d passed, %d failed, %d errors, %d skipped\n",
              sum(df$passed), sum(df$failed), sum(df$error), sum(df$skipped)))
  if (bad > 0) quit(status = 1)
' || fail "tests"

if [ "$MODE" = "--fast" ]; then
  printf '\n\033[32mFast check passed.\033[0m\n'; exit 0
fi

step "Completeness"
Rscript dev/audit.R || fail "audit - something generated has drifted from its source"

step "R CMD check"
R CMD build . > /dev/null || fail "build"
TARBALL=$(ls -t figspec_*.tar.gz | head -1)
set +e
R CMD check --as-cran --no-manual "$TARBALL" > /tmp/figspec-check.log 2>&1
STATUS=$?
set -e
grep -E '^Status|^\* checking.*(NOTE|WARNING|ERROR)' /tmp/figspec-check.log || true
rm -rf figspec.Rcheck "$TARBALL"
# Only "New submission" and its unreachable URLs are tolerated: those clear
# when the repository exists and cannot be fixed before then.
if grep -qE '^Status:.*(ERROR|WARNING)' /tmp/figspec-check.log; then
  fail "R CMD check - see /tmp/figspec-check.log"
fi
[ $STATUS -ne 0 ] && printf '\033[33m(check exited %d; notes above)\033[0m\n' "$STATUS"

if [ "$MODE" = "--full" ]; then
  step "Coverage"
  Rscript -e '
    Sys.setenv(NOT_CRAN = "true")
    cov <- covr::package_coverage(quiet = TRUE, type = "tests")
    pct <- covr::percent_coverage(cov)
    cat(sprintf("coverage: %.1f%%\n", pct))
    fc <- sort(covr::coverage_to_list(cov)$filecoverage)
    for (i in seq_along(fc)) if (fc[i] < 80) cat(sprintf("  low: %-22s %.1f%%\n", names(fc)[i], fc[i]))
    if (pct < 85) { cat("coverage below 85%\n"); quit(status = 1) }
  ' || fail "coverage"

  step "Site"
  Rscript -e 'pkgdown::clean_site(quiet = TRUE); pkgdown::build_site(preview = FALSE, devel = FALSE)' \
    > /tmp/figspec-pkgdown.log 2>&1 || fail "pkgdown - see /tmp/figspec-pkgdown.log"
  touch docs/.nojekyll
  echo "site rebuilt into docs/"
  Rscript dev/audit.R --site || fail "site is stale after rebuilding, which should not happen"
fi

printf '\n\033[32mAll checks passed.\033[0m\n'
