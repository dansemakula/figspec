# Package index

## Building, checking and exporting a figure

The main workflow: apply a specification when you have one, export at an
exact canvas or panel size, inspect the resulting geometry, and verify
the plot or finished file. Open any function for its arguments and
runnable examples.

- [`fig_save()`](https://dansemakula.github.io/figspec/reference/fig_save.md)
  : Save a figure at an exact size and resolution
- [`fig_check()`](https://dansemakula.github.io/figspec/reference/fig_check.md)
  : Inspect a figure and verify it against a specification
- [`fig_geometry()`](https://dansemakula.github.io/figspec/reference/fig_geometry.md)
  [`plot(`*`<figspec_geometry>`*`)`](https://dansemakula.github.io/figspec/reference/fig_geometry.md)
  : Measure panel and canvas dimensions
- [`fig_apply_spec()`](https://dansemakula.github.io/figspec/reference/fig_apply_spec.md)
  : Apply a specification while building a plot
- [`fig_preview()`](https://dansemakula.github.io/figspec/reference/fig_preview.md)
  : Preview a figure at its intended output size

## Size and align figures

Control the plotting area itself—not only the surrounding image—and give
a set of figures matching panels even when their labels, legends and
margins differ. Use a published width or supply your own dimensions.

- [`fig_panel_size()`](https://dansemakula.github.io/figspec/reference/fig_panel_size.md)
  : Set exact dimensions for every data panel
- [`fig_panel_width()`](https://dansemakula.github.io/figspec/reference/fig_panel_width.md)
  : Find one panel width that fits every figure

## Apply and reuse visual standards

Combine typographic requirements with a project or organisation’s house
style, choose suitable line weights, and label multi-panel figures
consistently.

- [`theme_spec()`](https://dansemakula.github.io/figspec/reference/theme_spec.md)
  : Apply typography requirements and a visual style
- [`style_register()`](https://dansemakula.github.io/figspec/reference/style_register.md)
  : Register a reusable visual style
- [`style_list()`](https://dansemakula.github.io/figspec/reference/style_list.md)
  : List the visual styles available in this session
- [`style_remove()`](https://dansemakula.github.io/figspec/reference/style_remove.md)
  : Remove a visual style from the current session
- [`style_save()`](https://dansemakula.github.io/figspec/reference/style_save.md)
  : Save visual styles for reuse
- [`style_load()`](https://dansemakula.github.io/figspec/reference/style_load.md)
  : Load saved visual styles
- [`fig_tag_panels()`](https://dansemakula.github.io/figspec/reference/fig_tag_panels.md)
  : Add and format labels for every panel
- [`spec_linewidth()`](https://dansemakula.github.io/figspec/reference/spec_linewidth.md)
  : Use line widths that meet a specification

## Colour and visual distinction

Choose colours, shapes and line types that remain distinguishable in
print and for readers with common colour-vision deficiencies, then check
the choices in a real plot.

- [`colour_safety_check()`](https://dansemakula.github.io/figspec/reference/colour_safety_check.md)
  [`color_safety_check()`](https://dansemakula.github.io/figspec/reference/colour_safety_check.md)
  : Check whether a figure's colours remain distinguishable
- [`figspec_palettes()`](https://dansemakula.github.io/figspec/reference/figspec_palettes.md)
  : List the colour palettes included with figspec
- [`figspec_palette()`](https://dansemakula.github.io/figspec/reference/figspec_palette.md)
  : Get colours from a figspec palette
- [`scale_colour_figspec()`](https://dansemakula.github.io/figspec/reference/scale_colour_figspec.md)
  [`scale_color_figspec()`](https://dansemakula.github.io/figspec/reference/scale_colour_figspec.md)
  : Apply a figspec palette to point and line colours
- [`scale_fill_figspec()`](https://dansemakula.github.io/figspec/reference/scale_fill_figspec.md)
  : Apply a figspec palette to filled areas
- [`scale_shape_figspec()`](https://dansemakula.github.io/figspec/reference/scale_shape_figspec.md)
  : Apply distinct shapes to categorical points
- [`figspec_shapes()`](https://dansemakula.github.io/figspec/reference/figspec_shapes.md)
  : Get a set of distinct point shapes
- [`figspec_linetypes()`](https://dansemakula.github.io/figspec/reference/figspec_linetypes.md)
  : Get a set of distinct line types
- [`spec_style_palette()`](https://dansemakula.github.io/figspec/reference/spec_style_palette.md)
  : Retrieve a recorded house-style palette

## Find and use specifications

Browse the included publisher and journal profiles, inspect their
recorded requirements, retrieve stated widths, or save and load
requirements maintained by your own team. A specification can be a
registry profile or a named set of requirements supplied directly in R.

- [`spec_list()`](https://dansemakula.github.io/figspec/reference/spec_list.md)
  : Browse available specification profiles
- [`spec_get()`](https://dansemakula.github.io/figspec/reference/spec_get.md)
  : Retrieve or create a specification
- [`fig_width()`](https://dansemakula.github.io/figspec/reference/fig_width.md)
  : Look up a figure width
- [`fig_columns()`](https://dansemakula.github.io/figspec/reference/fig_columns.md)
  : List the available figure widths
- [`spec_register()`](https://dansemakula.github.io/figspec/reference/spec_register.md)
  : Register a publication specification for this session
- [`spec_save()`](https://dansemakula.github.io/figspec/reference/spec_save.md)
  : Save a specification for reuse
- [`spec_load()`](https://dansemakula.github.io/figspec/reference/spec_load.md)
  : Load specifications from a YAML registry

## Check collections and publication assets

Review figures and tables together, choose the appropriate resolution
rule, adapt a figure set to another destination, and inspect
requirements for supplementary media and graphical abstracts.

- [`submission_check()`](https://dansemakula.github.io/figspec/reference/submission_check.md)
  : Review figures and tables together
- [`submission_detail()`](https://dansemakula.github.io/figspec/reference/submission_detail.md)
  : Open the full report for one submission item
- [`fig_suggest_art_type()`](https://dansemakula.github.io/figspec/reference/fig_suggest_art_type.md)
  : Choose a resolution category for a figure
- [`fig_refit()`](https://dansemakula.github.io/figspec/reference/fig_refit.md)
  : Re-export a figure set for a new specification
- [`media_spec()`](https://dansemakula.github.io/figspec/reference/media_spec.md)
  : Look up supplementary media requirements
- [`media_check()`](https://dansemakula.github.io/figspec/reference/media_check.md)
  : Verify a supplementary media file
- [`graphical_abstract_spec()`](https://dansemakula.github.io/figspec/reference/graphical_abstract_spec.md)
  : Look up graphical abstract requirements

## Build, export and check tables

Apply table requirements to data frames and tables made with gt,
flextable, kableExtra or grid; export through the table’s own system;
and verify the editable object together with the completed file.

- [`table_spec()`](https://dansemakula.github.io/figspec/reference/table_spec.md)
  : Look up table requirements
- [`table_apply_spec()`](https://dansemakula.github.io/figspec/reference/table_apply_spec.md)
  : Apply a specification to a table
- [`table_save()`](https://dansemakula.github.io/figspec/reference/table_save.md)
  : Export and verify a table
- [`table_check()`](https://dansemakula.github.io/figspec/reference/table_check.md)
  : Verify a table against a specification

## R Markdown and Quarto

Carry the same dimensions and output requirements into reproducible
reports so figures are generated consistently whenever the document is
rebuilt.

- [`figspec_knitr_options()`](https://dansemakula.github.io/figspec/reference/figspec_knitr_options.md)
  : Create figure settings for R Markdown or Quarto
- [`figspec_knitr_setup()`](https://dansemakula.github.io/figspec/reference/figspec_knitr_setup.md)
  : Apply figure settings to R Markdown or Quarto

## Maintain trusted registry data

See how complete and current each bundled profile is, recheck its cited
sources, and validate new or updated registry entries before sharing
them.

- [`registry_status()`](https://dansemakula.github.io/figspec/reference/registry_status.md)
  : Review registry coverage and update dates
- [`registry_stale_entries()`](https://dansemakula.github.io/figspec/reference/registry_stale_entries.md)
  : Find specifications due for review
- [`registry_check_sources()`](https://dansemakula.github.io/figspec/reference/registry_check_sources.md)
  : Check whether registry source pages still respond
- [`registry_entry_template()`](https://dansemakula.github.io/figspec/reference/registry_entry_template.md)
  : Create a registry-entry template
- [`registry_validate_file()`](https://dansemakula.github.io/figspec/reference/registry_validate_file.md)
  : Check a registry file before loading it
