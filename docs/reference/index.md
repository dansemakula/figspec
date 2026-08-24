# Package index

## Checking a figure

What a specification requires, and whether this figure meets it.

- [`fig_check()`](https://dansemakula.github.io/figspec/reference/fig_check.md)
  : Check a figure against a journal's requirements
- [`check_colour_safety()`](https://dansemakula.github.io/figspec/reference/check_colour_safety.md)
  [`check_color_safety()`](https://dansemakula.github.io/figspec/reference/check_colour_safety.md)
  : Check a figure's colours for safety in print and for colour-blind
  readers
- [`check_submission()`](https://dansemakula.github.io/figspec/reference/check_submission.md)
  : Check a whole set of figures together
- [`submission_detail()`](https://dansemakula.github.io/figspec/reference/submission_detail.md)
  : The full report for one file in a submission check
- [`suggest_art_type()`](https://dansemakula.github.io/figspec/reference/suggest_art_type.md)
  : Which resolution rule applies to this figure

## Sizing and exporting

Set the plot panel as well as the image, and export at exactly that size
and resolution.

- [`fig_save()`](https://dansemakula.github.io/figspec/reference/fig_save.md)
  : Save a figure at an exact size and resolution
- [`fig_panel_size()`](https://dansemakula.github.io/figspec/reference/fig_panel_size.md)
  : Set the size of a plot's panels
- [`fig_panel_width()`](https://dansemakula.github.io/figspec/reference/fig_panel_width.md)
  : The panel width a set of figures can share
- [`fig_geometry()`](https://dansemakula.github.io/figspec/reference/fig_geometry.md)
  [`plot(`*`<figspec_geometry>`*`)`](https://dansemakula.github.io/figspec/reference/fig_geometry.md)
  : What size a figure actually is

## Building a compliant figure

- [`fit_journal()`](https://dansemakula.github.io/figspec/reference/fit_journal.md)
  : Bring a journal's requirements into a plot as you build it
- [`theme_journal()`](https://dansemakula.github.io/figspec/reference/theme_journal.md)
  : A ggplot2 theme that satisfies a journal's typography rules
- [`tag_panels()`](https://dansemakula.github.io/figspec/reference/tag_panels.md)
  : Label the panels of a figure
- [`figspec_preview()`](https://dansemakula.github.io/figspec/reference/figspec_preview.md)
  : Preview a figure at the size it will actually be published
- [`figspec_linewidth()`](https://dansemakula.github.io/figspec/reference/figspec_linewidth.md)
  : Line width that satisfies a journal's minimum
- [`figspec_shapes()`](https://dansemakula.github.io/figspec/reference/figspec_shapes.md)
  : Point shapes that stay legible at journal size
- [`figspec_linetypes()`](https://dansemakula.github.io/figspec/reference/figspec_linetypes.md)
  : Line types that stay distinct in print

## Colour

- [`figspec_palettes()`](https://dansemakula.github.io/figspec/reference/figspec_palettes.md)
  : Colour palettes that survive print and colour-blind readers
- [`figspec_palette()`](https://dansemakula.github.io/figspec/reference/figspec_palette.md)
  : The colours in a figspec palette
- [`scale_colour_figspec()`](https://dansemakula.github.io/figspec/reference/scale_colour_figspec.md)
  [`scale_color_figspec()`](https://dansemakula.github.io/figspec/reference/scale_colour_figspec.md)
  [`scale_fill_figspec()`](https://dansemakula.github.io/figspec/reference/scale_colour_figspec.md)
  : Discrete colour and fill scales using a figspec palette
- [`scale_shape_figspec()`](https://dansemakula.github.io/figspec/reference/scale_shape_figspec.md)
  : A discrete shape scale using shapes that stay legible at journal
  size
- [`journal_palette()`](https://dansemakula.github.io/figspec/reference/journal_palette.md)
  : The palette recorded for a journal's house style

## R Markdown and Quarto

- [`figspec_chunk_opts()`](https://dansemakula.github.io/figspec/reference/figspec_chunk_opts.md)
  : Chunk options that produce journal-compliant figures in R Markdown
  or Quarto
- [`figspec_knitr_setup()`](https://dansemakula.github.io/figspec/reference/figspec_knitr_setup.md)
  : Set knitr chunk options for a journal

## Looking things up

- [`journals()`](https://dansemakula.github.io/figspec/reference/journals.md)
  : List the journals in the registry
- [`journal_spec()`](https://dansemakula.github.io/figspec/reference/journal_spec.md)
  : Look up one journal's figure specification
- [`fig_width()`](https://dansemakula.github.io/figspec/reference/fig_width.md)
  : Figure width for a journal column
- [`fig_columns()`](https://dansemakula.github.io/figspec/reference/fig_columns.md)
  : The column widths a journal states
- [`table_spec()`](https://dansemakula.github.io/figspec/reference/table_spec.md)
  : Table requirements for a journal
- [`media_spec()`](https://dansemakula.github.io/figspec/reference/media_spec.md)
  : Supplementary media requirements for a journal
- [`check_media()`](https://dansemakula.github.io/figspec/reference/check_media.md)
  : Check a supplementary media file against a journal's requirements
- [`graphical_abstract_spec()`](https://dansemakula.github.io/figspec/reference/graphical_abstract_spec.md)
  : Graphical abstract requirements for a journal

## Moving between journals

- [`refit_journal()`](https://dansemakula.github.io/figspec/reference/refit_journal.md)
  : Re-export a set of figures for a different journal

## Your own styles and journals

- [`register_house_style()`](https://dansemakula.github.io/figspec/reference/register_house_style.md)
  : Register a house style of your own
- [`house_styles()`](https://dansemakula.github.io/figspec/reference/house_styles.md)
  : House styles registered in this session
- [`remove_house_style()`](https://dansemakula.github.io/figspec/reference/remove_house_style.md)
  : Remove a registered house style
- [`save_house_styles()`](https://dansemakula.github.io/figspec/reference/save_house_styles.md)
  [`load_house_styles()`](https://dansemakula.github.io/figspec/reference/save_house_styles.md)
  : Save and reload your house styles
- [`register_journal()`](https://dansemakula.github.io/figspec/reference/register_journal.md)
  : Add your own journal to the registry
- [`load_journals()`](https://dansemakula.github.io/figspec/reference/load_journals.md)
  : Load journal entries from your own registry file

## Maintaining the registry

- [`registry_status()`](https://dansemakula.github.io/figspec/reference/registry_status.md)
  : How current is each registry entry, and how complete
- [`stale_entries()`](https://dansemakula.github.io/figspec/reference/stale_entries.md)
  : Entries that need rechecking
- [`check_sources()`](https://dansemakula.github.io/figspec/reference/check_sources.md)
  : Are the pages the registry cites still there
- [`new_journal_entry()`](https://dansemakula.github.io/figspec/reference/new_journal_entry.md)
  : A skeleton for a new registry entry
- [`validate_registry_file()`](https://dansemakula.github.io/figspec/reference/validate_registry_file.md)
  : Validate a registry file before loading it
