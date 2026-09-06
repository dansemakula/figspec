# Public API naming convention

This document records the naming convention adopted for figspec's first public
release. The migration is complete; the map below remains the authoritative
record of former and canonical names and the basis for future API additions.

## Principles

1. Use `snake_case` throughout.
2. Begin a function name with the workflow, result or area it belongs to. This
   groups related functions in autocomplete and makes new names predictable.
3. Use one stable prefix for each area of the package:
   - `fig_` for building, sizing, inspecting, exporting and checking figures;
   - `spec_` for finding and managing specifications;
   - `style_` for house styles;
   - `registry_` for registry maintenance;
   - `submission_` and `media_` for operations on those objects;
   - `colour_` for analysing whether colour choices remain distinguishable;
   - `figspec_` for the package's standalone design resources and document
     integration helpers, rather than operations on one figure.
4. Follow established ggplot2 conventions for `theme_*()` and
   `scale_<aesthetic>_*()` functions.
5. Write words in full in the public API. For example, use `options`, not
   `opts`, and `output_dir`, not `outdir`.
6. Use `spec` for a specification accepted by a function. Do not use
   `journal` when the same argument can accept publisher, project or
   organisational requirements.
7. Keep British spelling as the documented default and provide American
   spelling aliases where users reasonably expect them.
8. Do not retain pre-release names merely as exported aliases. Too many aliases
   make autocomplete and the reference index harder to use. Retain only useful
   spelling aliases unless there is evidence of external use that requires a
   deprecation period.

## Complete exported-function map

The pre-migration package exported 47 ordinary user-facing functions. The
naming migration retained those functions, including the two intentional
American-spelling aliases. The pre-release table expansion then added three
functions, and `spec_save()` added safe persistence for user specifications,
bringing the first public API to 51 exports. S3 print, plot and ggplot-add
methods are registered separately and are not called directly by users.

After the naming migration was completed, `fig_save()` gained the
`transform` argument as part of the pre-release plotting-system expansion. It
does not add another exported name: it controls whether a specification is
applied to the editable features exposed by ggplot2, patchwork, lattice,
Plotly, grid or base graphics before the figure is written.

| # | Former export | Canonical name | Family | Decision |
|---:|---|---|---|---|
| 1 | `check_color_safety()` | `color_safety_check()` | Colour | Rename; American spelling alias |
| 2 | `check_colour_safety()` | `colour_safety_check()` | Colour | Rename; documented canonical name |
| 3 | `check_media()` | `media_check()` | Media | Rename |
| 4 | `check_sources()` | `registry_check_sources()` | Registry | Rename |
| 5 | `check_submission()` | `submission_check()` | Submission | Rename |
| 6 | `fig_check()` | `fig_check()` | Figure | Keep |
| 7 | `fig_columns()` | `fig_columns()` | Figure | Keep |
| 8 | `fig_geometry()` | `fig_geometry()` | Figure | Keep |
| 9 | `fig_panel_size()` | `fig_panel_size()` | Figure | Keep |
| 10 | `fig_panel_width()` | `fig_panel_width()` | Figure | Keep |
| 11 | `fig_save()` | `fig_save()` | Figure | Keep |
| 12 | `fig_width()` | `fig_width()` | Figure | Keep |
| 13 | `figspec_chunk_opts()` | `figspec_knitr_options()` | Documents | Rename; spell out `options` and pair it with `figspec_knitr_setup()` |
| 14 | `figspec_knitr_setup()` | `figspec_knitr_setup()` | Documents | Keep; the package prefix prevents it being mistaken for a knitr function |
| 15 | `figspec_linetypes()` | `figspec_linetypes()` | Figure aesthetics | Keep; package-supplied design resource |
| 16 | `figspec_linewidth()` | `spec_linewidth()` | Specification | Rename; value comes from a specification |
| 17 | `figspec_palette()` | `figspec_palette()` | Figure aesthetics | Keep; package-supplied design resource |
| 18 | `figspec_palettes()` | `figspec_palettes()` | Figure aesthetics | Keep; plural lists available palettes |
| 19 | `figspec_preview()` | `fig_preview()` | Figure | Rename |
| 20 | `figspec_shapes()` | `figspec_shapes()` | Figure aesthetics | Keep; package-supplied design resource |
| 21 | `fit_journal()` | `fig_apply_spec()` | Figure | Rename; it returns a specification component to add to a plot |
| 22 | `graphical_abstract_spec()` | `graphical_abstract_spec()` | Graphical abstract | Keep |
| 23 | `house_styles()` | `style_list()` | House style | Rename |
| 24 | `journal_palette()` | `spec_style_palette()` | Specification | Rename; the value is an optional house-style preference, not a requirement |
| 25 | `journal_spec()` | `spec_get()` | Specification | Rename |
| 26 | `journals()` | `spec_list()` | Specification | Rename |
| 27 | `load_house_styles()` | `style_load()` | House style | Rename |
| 28 | `load_journals()` | `spec_load()` | Specification | Rename |
| 29 | `media_spec()` | `media_spec()` | Media | Keep |
| 30 | `new_journal_entry()` | `registry_entry_template()` | Registry | Rename; it prints a template rather than registering an entry |
| 31 | `refit_journal()` | `fig_refit()` | Figure | Rename |
| 32 | `register_house_style()` | `style_register()` | House style | Rename |
| 33 | `register_journal()` | `spec_register()` | Specification | Rename |
| 34 | `registry_status()` | `registry_status()` | Registry | Keep |
| 35 | `remove_house_style()` | `style_remove()` | House style | Rename |
| 36 | `save_house_styles()` | `style_save()` | House style | Rename |
| 37 | `scale_color_figspec()` | `scale_color_figspec()` | ggplot2 scale | Keep; American spelling alias |
| 38 | `scale_colour_figspec()` | `scale_colour_figspec()` | ggplot2 scale | Keep; documented canonical name |
| 39 | `scale_fill_figspec()` | `scale_fill_figspec()` | ggplot2 scale | Keep |
| 40 | `scale_shape_figspec()` | `scale_shape_figspec()` | ggplot2 scale | Keep |
| 41 | `stale_entries()` | `registry_stale_entries()` | Registry | Rename; the result is a collection of entry ids, not a logical test |
| 42 | `submission_detail()` | `submission_detail()` | Submission | Keep |
| 43 | `suggest_art_type()` | `fig_suggest_art_type()` | Figure | Rename |
| 44 | `table_spec()` | `table_spec()` | Table | Keep |
| 45 | `tag_panels()` | `fig_tag_panels()` | Figure | Rename |
| 46 | `theme_journal()` | `theme_spec()` | ggplot2 theme | Rename; retain ggplot2's `theme_*` convention |
| 47 | `validate_registry_file()` | `registry_validate_file()` | Registry | Rename; make the file input explicit |
| 48 | — | `table_apply_spec()` | Table | Add; apply measurable table requirements while editable |
| 49 | — | `table_check()` | Table | Add; inspect a live table or completed table file |
| 50 | — | `table_save()` | Table | Add; export transactionally and verify the result |
| 51 | — | `spec_save()` | Specification | Add; write and safely update reusable specification files |

## How the functions are grouped

The first part of each name identifies the workflow, result or part of figspec
the function belongs to. The remaining words describe what the function does.
For example, `fig_save()` saves a figure, `spec_get()` resolves a specification
and `style_register()` registers a house style. This makes related functions
appear together in autocomplete and helps users predict a function name
without first consulting the reference index.

The groups are based on the following practical areas of work:

- `fig_` covers the figure workflow and its results, including building,
  sizing, inspecting, previewing, exporting and checking. A `fig_` function
  does not necessarily receive a completed figure as its first argument; for
  example, `fig_apply_spec()` creates the component added while a plot is being
  built.
- `spec_` covers the requirements applied to the work, whether they come from
  a publisher, an individual journal, an organisation or a project.
- `table_` covers the table workflow: retrieving table requirements,
  applying them to an editable table, exporting and checking.
- `style_` covers reusable house styles and the functions used to register,
  list, save, load and remove them.
- `registry_` covers maintenance of the specification registry, including
  checking sources, finding entries that need review and validating proposed
  additions.
- `submission_` covers operations on a set of files prepared together for
  delivery or submission.
- `media_` covers supplementary media requirements and checks.
- `colour_` covers checks of colour contrast, colour-vision safety and
  redundant visual coding. The documented spelling is British;
  `color_safety_check()` is the American-spelling alias.
- `figspec_` is retained for reusable resources supplied by the package, such
  as its tested palettes, shapes and line types, and for document-integration
  helpers whose names should not appear to belong to knitr itself.

Names such as `theme_spec()` and `scale_colour_figspec()` are deliberate
exceptions. They follow ggplot2's established `theme_*()` and
`scale_<aesthetic>_*()` conventions, which will already be familiar to many R
users.

Two names need especially clear documentation. `spec_get()` means “obtain the
specification represented by this input”: it retrieves a registered profile
when given an id and validates and normalises a specification supplied as a
list. `spec_resolve()` would describe the implementation more literally, but
`spec_get()` is shorter and easier to discover alongside `spec_list()`. Also,
`fig_apply_spec()` is used as `plot + fig_apply_spec(spec)`. It returns ggplot2
components for the `+` operation; it does not take a completed plot as its
first argument. Its help page and examples must show that call shape plainly.

With this convention, autocomplete would present the functions in recognisable
groups:

```text
fig_apply_spec()          spec_get()                 style_list()
fig_check()               spec_list()                style_load()
fig_columns()             spec_load()                style_register()
fig_geometry()            spec_register()            style_remove()
fig_panel_size()          spec_save()                style_save()
fig_panel_width()         spec_linewidth()
fig_preview()             spec_style_palette()
fig_refit()               registry_check_sources()   submission_check()
fig_save()                registry_entry_template()  submission_detail()
fig_suggest_art_type()    registry_stale_entries()
fig_tag_panels()          registry_status()          media_check()
fig_width()               registry_validate_file()   media_spec()

figspec_knitr_options()
figspec_knitr_setup()
figspec_linetypes()
figspec_palette()
figspec_palettes()
figspec_shapes()
```

The remaining artifact and ggplot2 names are deliberately descriptive rather
than forced into one of these prefixes:

```text
colour_safety_check()     graphical_abstract_spec()
color_safety_check()      table_spec()
table_apply_spec()        table_check()
table_save()
theme_spec()
scale_colour_figspec()
scale_color_figspec()
scale_fill_figspec()
scale_shape_figspec()
```

## Argument vocabulary to apply with the rename

- Use `spec` wherever a publisher, journal, project or organisational
  specification is accepted.
- Use `plot` for one plot, `plots` for several plots and `x` only for genuinely
  polymorphic inputs.
- Use `path` for an existing file or registry file and `filename` for the file
  created by `fig_save()`.
- Use `output_dir` instead of `outdir`.
- Present size arguments in the order `width`, `height`, `units`.
- Keep `colour` canonical while accepting `color` where relevant.

## Related public names that must migrate with the functions

Changing only the function declarations would leave the API internally
inconsistent. The migration must also cover the following user-visible names:

- Change the generic function argument `journal` to `spec` wherever the value
  may also describe a publisher, project or organisation. Keep the word
  *journal* in prose and data only when an individual journal is genuinely
  meant.
- Change `outdir` to `output_dir` in `fig_refit()`.
- Put `width` before `height` in both document-integration functions.
- Rename public report attributes `journal` and `journal_id` to `spec_name` and
  `spec_id`, including submission objects and reports combined by
  `merge_figspec_reports()`.
- Rename the `journal` field returned by `table_spec()`, `media_spec()` and
  `graphical_abstract_spec()` to `spec_name`.
- Rename internal cache fields such as `user_journals` to `user_specs`, so the
  implementation uses the same concepts as the public API.
- Decide explicitly whether the public error subclass
  `figspec_column_without_journal` becomes `figspec_column_without_spec`. If it
  changes, test the new class and record the break in the migration note; if a
  compatibility release is chosen, give the condition both subclasses during
  that period.
- Keep the existing `journals:` YAML key, schema version and bundled
  `journals.yaml` filename during this API refactor. They describe the bundled
  publication-profile data and are already used throughout the validation and
  contributor workflow. A storage-schema migration would be a separate change
  requiring dual-key handling and its own compatibility tests.

The existing `figspec_*` S3 class names are already specification-neutral and
should not change. A class rename would add risk without improving the public
vocabulary.

## Safe migration sequence

This should be performed as a controlled refactor, not as one global text
replacement. The word `journal` remains correct in many descriptions and
registry records, and a global replacement would silently damage those
meanings.

1. **Start from the recorded green baseline.** On 2026-09-05 the repaired
   pre-rename package passed 2,561 expectations with no failures or errors;
   both completeness audits were clean; coverage was 89.6%; the separate real
   250,000-row stress render passed; and `R CMD check --as-cran` on a clean
   source tarball had no errors or warnings. Its sole NOTE was the exact
   pre-launch incoming-feasibility message for a new submission and the
   not-yet-live GitHub Pages URLs. Re-run these gates immediately before the
   first rename and record their totals in the migration log.
2. **Freeze the approved maps and contracts.** Keep the identity columns in
   migration maps under `tests/testthat/fixtures/api-migration/` immutable;
   change only their name, signature and public-data state columns as work is
   completed. Preserve separate immutable old-API and final-API contracts in
   the same test fixture. These contracts cover exact exports, aliases, formal
   names/defaults/order, S3
   registrations, object metadata, returned fields, condition classes and
   print/subset behaviour. The active contract is derived from those files and
   the state columns, so no baseline test is rewritten during the migration.
3. **Rename the specification foundation first.** Implement `spec_get()`, the
   `spec` argument vocabulary and the neutral internal cache names.
   Update and run the specification and registry tests before proceeding.
   Before reordering any formal arguments, convert every internal positional
   call to named arguments; the current knitr setup wrapper is particularly
   vulnerable because it forwards six arguments positionally.
4. **Rename one family at a time.** Migrate specification management, figure
   operations and their `figspec_fit` metadata, styles, registry maintenance,
   submission/media/colour checking and document integration in separate small
   changes. After each family, load the package and run that family's focused
   tests. This keeps any failure close to the change that caused it.
5. **Update authored documentation only.** Edit roxygen comments in `R/`, the
   vignettes, `README.md`, `NEWS.md`, `CONTRIBUTING.md`, `inst/CITATION`,
   `_pkgdown.yml`, `.Rbuildignore`, the options-example source and maintainer
   scripts under `data-raw/`, `dev/`, `.github/` and `inst/`. Do not hand-edit
   `NAMESPACE`, `man/`, the generated options vignette or files under `docs/`.
6. **Advance the family state as the last authored edit.** Once that family's
   code, tests and authored documentation have been changed, update its name,
   signature and public-data states from `planned` to `migrated`. The
   manifest-aware tests cannot validate the candidate API until this state
   reflects it, so the family edits and state change form one checkpoint. If
   any following gate fails, revert that family and its state together.
7. **Regenerate in dependency order.** Run roxygen with `clean = TRUE` to
   rebuild `NAMESPACE` and `man/` without orphan help topics; run the strict
   options-guide generator; render every vignette; then build pkgdown into a
   temporary destination from a temporary installation of the current source.
   Validate the staged site and promote it to `docs/` only after every check
   passes, retaining the previous site until promotion succeeds.
8. **Audit the result.** Run the ordinary completeness audit and the
   manifest-driven migration audit over both authored and generated files.
   Check exact help aliases and pkgdown group membership; reject former-name
   files and URLs except in explicitly approved NEWS, help-alias or redirect
   contexts; parse every R example; and verify links, anchors, images, custom
   assets, `search.json` and `sitemap.xml`.

There are currently about 950 call-like occurrences of the names being
considered in authored code, tests and documentation, plus about 700 in
generated help and website files. The generated occurrences should be replaced
by rebuilding from source rather than editing them individually.

## End-to-end validation before publication

### 1. API and documentation contract

- Confirm that every approved function is exported exactly once.
- Confirm that old pre-release names are no longer exported, except the two
  intentional American-spelling aliases.
- Confirm formal argument names, defaults and order for every export.
- Confirm that every S3 method remains registered and that print, plot and
  subset behaviour still preserves or removes the intended metadata.
- Confirm public report attributes, returned list fields and condition classes,
  including the objects combined by `merge_figspec_reports()`.
- Run all help-file examples and build every vignette with network access
  disabled.
- Check that every function is present in the correct pkgdown reference group
  and that search results use the new names.
- Re-run the CRAN collision scan with a freshly retrieved index immediately. A
  preliminary scan found no collisions for the revised candidate names, but
  the available index is not current enough to serve as the release check.

### 2. Functional tests with real plots and files

- Exercise small, medium and large datasets, approximately 100, 10,000 and
  250,000 observations. The release gate now includes the 250,000-row stress
  case explicitly rather than inferring large-data behaviour from the routine
  suite, which reaches approximately 100,000 rows.
- Build real scatter, line, bar, faceted and multi-panel figures with short and
  long labels, legends, annotations and different numbers of groups.
- Verify before-and-after panel sizing numerically and visually, including
  patchwork compositions where that optional package is installed.
- Save real PNG, TIFF, JPEG, PDF, SVG and EPS files when the required device is
  available. Test each format separately so one missing optional device cannot
  skip the formats that follow it. Reopen each file and verify its dimensions,
  resolution, format and structural validity. Raster text size must be reported
  as unknowable; recoverable text-size assertions belong only to vector files.
- Exercise bundled publisher and journal profiles, a specification supplied as
  an R list, a specification loaded from YAML and a registered house style.
- Check individual figures, collections, table and graphical-abstract lookups,
  and genuine GIF, audio and video samples. Run codec and bit-rate checks both
  with and without `ffprobe` available.
- Exercise optional integrations both when present and when deliberately made
  unavailable, including `ragg`, `svglite`, `ffprobe`, ExifTool and PDF/QPDF
  tooling.

### 3. Adversarial and security regression tests

- Re-run malformed and oversized YAML tests with expression evaluation
  disabled.
- Re-test unsafe filenames, path traversal attempts, duplicate output names,
  corrupt image/media files, missing tools and hostile metadata.
- Re-test source-checking timeouts, redirects, bot blocks and dead URLs without
  making network access part of CRAN examples or routine offline tests.
- Confirm that failures leave no partly written registry state. `fig_refit()`
  currently writes destinations one at a time, so a later failure can leave an
  earlier output in place. Making the whole set transactional is a separate
  publication-hardening task; do not claim atomic output-set replacement until
  that behaviour has been implemented and tested.

### 4. Clean-package testing

- Build the source tarball and install it into an empty temporary R library.
- From a directory outside the source tree, run a consumer smoke-test script in
  a fresh R process against the installed package, not `pkgload::load_all()`.
  This catches reliance on unexported development files, stale objects or
  undeclared dependencies.
- Run `R CMD check --as-cran` on the tarball and require zero errors, warnings
  and avoidable notes.
- Run the coverage and completeness audits, then compare performance and output
  geometry with the pre-migration baseline.

### 5. Website validation

- Build pkgdown from a clean site directory and check every internal link,
  anchor, image, downloadable file and reference-page URL.
- Preserve the custom JavaScript, CSS and `.nojekyll` marker during the clean
  rebuild.
- Exercise the argument accordions and navigation in a browser.
- Inspect the home page, reference index and every vignette at desktop and
  narrow/mobile widths. Confirm that plots remain legible and no generated
  image is missing.
- Inspect `search.json`, the sitemap and the rendered news page for former
  function names or broken destinations.
- Apply the chosen clean pre-CRAN break: do not export the former names and do
  not retain former canonical function pages. Keep only intentional spelling,
  package-help and S3-help redirects recorded in `dev/site-redirects.csv`, and
  validate their refresh URL, canonical URL and local target.

### 6. Cross-platform release checks

During the GitHub and release phase, run the clean tarball on R old-release,
release and development versions, including Linux, Windows and macOS. Add
GitHub Actions only when phase 6 begins, then use win-builder or an equivalent
CRAN-facing service as a final independent check. Because figspec contains no
compiled code, sanitizer and Valgrind jobs are not necessary; the higher-value
checks are graphics-device, font, file-format and operating-system coverage.
