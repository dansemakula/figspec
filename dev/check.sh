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
#   ./dev/check.sh --final    full check plus final API and 250,000-row stress gates
#
# Exits non-zero on the first failure, so it can gate a commit.

set -euo pipefail
cd "$(dirname "$0")/.."

MODE="${1:-}"
step() { printf '\n\033[1m── %s\033[0m\n' "$1"; }
fail() { printf '\033[31mFAILED: %s\033[0m\n' "$1"; exit 1; }

case "$MODE" in
  ""|--fast|--full|--final) ;;
  *) fail "unknown mode: $MODE" ;;
esac

if [ "$MODE" = "--final" ]; then
  export FIGSPEC_RUN_STRESS=true
fi

step "Documentation"
# clean = TRUE removes obsolete .Rd files after a topic is renamed. Without it,
# an old help file can survive and pkgdown can quietly rebuild its old page.
Rscript -e 'roxygen2::roxygenise(".", clean = TRUE)' || fail "roxygen"

step "Generated options guide"
Rscript data-raw/make-options-table.R || \
  fail "options guide - exports, help topics and executable examples disagree"

step "Tests"
Rscript -e '
  pkgload::load_all(".", quiet = TRUE)
  res <- testthat::test_dir("tests/testthat", stop_on_failure = FALSE)
  df <- as.data.frame(res)
  bad <- sum(df$failed) + sum(df$error) + sum(df$warning)
  cat(sprintf("\n%d passed, %d failed, %d errors, %d warnings, %d skipped\n",
              sum(df$passed), sum(df$failed), sum(df$error), sum(df$warning),
              sum(df$skipped)))
  if (bad > 0) quit(status = 1)
' || fail "tests"

if [ "$MODE" = "--fast" ]; then
  printf '\n\033[32mFast check passed.\033[0m\n'; exit 0
fi

step "Completeness"
Rscript dev/audit.R || fail "audit - something generated has drifted from its source"
if [ "$MODE" = "--final" ]; then
  Rscript dev/audit-api-migration.R --final || fail "final API migration audit"
else
  Rscript dev/audit-api-migration.R || fail "staged API migration audit"
fi

step "R CMD check"
REPO_ROOT=$(pwd)
CHECK_ROOT=$(mktemp -d /tmp/figspec-r-cmd-check.XXXXXX)
cleanup_check_root() { rm -rf "$CHECK_ROOT"; }
trap cleanup_check_root EXIT
(cd "$CHECK_ROOT" && R CMD build "$REPO_ROOT" > build.log 2>&1) || fail "build"
TARBALL_COUNT=$(find "$CHECK_ROOT" -maxdepth 1 -type f -name 'figspec_*.tar.gz' | wc -l | tr -d ' ')
[ "$TARBALL_COUNT" = "1" ] || fail "build created $TARBALL_COUNT tarballs instead of exactly one"
TARBALL=$(find "$CHECK_ROOT" -maxdepth 1 -type f -name 'figspec_*.tar.gz' -print)
set +e
(cd "$CHECK_ROOT" && R CMD check --as-cran "$TARBALL" > /tmp/figspec-check.log 2>&1)
STATUS=$?
set -e
grep -E '^Status|^\* checking.*(NOTE|WARNING|ERROR)' /tmp/figspec-check.log || true
Rscript dev/check-cran-log.R "$CHECK_ROOT/figspec.Rcheck/00check.log" "$STATUS" || \
  fail "R CMD check - see /tmp/figspec-check.log"

step "Installed-package smoke test"
INSTALL_LIB="$CHECK_ROOT/library"
INSTALL_WORK="$CHECK_ROOT/consumer"
mkdir -p "$INSTALL_LIB" "$INSTALL_WORK"
R CMD INSTALL --library="$INSTALL_LIB" "$TARBALL" > "$CHECK_ROOT/install.log" 2>&1 || \
  fail "installing the built tarball - see $CHECK_ROOT/install.log"
(cd "$INSTALL_WORK" && \
  FIGSPEC_REPO_ROOT="$REPO_ROOT" R_LIBS="$INSTALL_LIB" \
  Rscript "$REPO_ROOT/dev/smoke-installed.R") || \
  fail "installed-package consumer smoke test"

if [ "$MODE" = "--full" ] || [ "$MODE" = "--final" ]; then
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
  Rscript dev/build-site.R > /tmp/figspec-pkgdown.log 2>&1 || \
    fail "staged pkgdown build - see /tmp/figspec-pkgdown.log"
  Rscript dev/audit.R --site || fail "site is stale after rebuilding, which should not happen"
fi

printf '\n\033[32mAll checks passed.\033[0m\n'
