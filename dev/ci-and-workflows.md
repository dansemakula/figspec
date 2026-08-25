# Workflows

There are none, for two reasons that are both about this account rather than
about the package.

**GitHub Actions is unavailable here**, so a workflow file would describe
checks that never run. A green tick nobody earns is worse than no tick.

**Pushing a workflow needs a token with `workflow` scope**, which the
credential in use does not have. Adding one is refused by the remote, not by
git.

The site is not built here either. `docs/` is committed and GitHub Pages serves
it from the branch, so `dev/check.sh --full` rebuilds it locally and committing
the result is the deploy.

## Restoring them

Both files are in history. When Actions works and the token has `workflow`
scope:

    gh auth refresh -h github.com -s workflow      # grant the scope
    git show 8597b3b -- .github/workflows/ | git apply
    git show 2696ac3 -- .github/workflows/ | git apply

Then add the badge back to README.md:

    [![R-CMD-check](https://github.com/dansemakula/figspec/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/dansemakula/figspec/actions/workflows/R-CMD-check.yaml)

If you would rather the site were built by Actions than committed, switch Pages
to deploy from `gh-pages` and restore the pkgdown workflow as well.
