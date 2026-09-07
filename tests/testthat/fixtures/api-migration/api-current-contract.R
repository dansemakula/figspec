# Immutable contract for the last pre-rename API. Migration tests combine this
# with api-final-contract.R according to the two migration manifests. Do
# not edit this file while the rename is in progress.

figspec_current_api_contract <- list(
  exports = list(
    check_color_safety = alist(plot = , journal = , threshold = 10),
    check_colour_safety = alist(plot = , journal = , threshold = 10),
    check_media = alist(path = , journal = ),
    check_sources = alist(ids = NULL, timeout = 10),
    check_submission = alist(
      x = , journal = NULL, column = NULL, dpi = NULL,
      pattern = "\\.(tiff?|png|jpe?g|pdf|eps|ps|svg)$", recursive = FALSE,
      art_type = c("auto", "colour", "bw", "line", "combination")
    ),
    fig_check = alist(
      x = , journal = NULL, column = NULL, width = NULL, height = NULL,
      units = c("mm", "cm", "in"), dpi = NULL, format = NULL,
      colour_mode = NULL, color_mode = NULL,
      art_type = c("auto", "colour", "bw", "line", "combination")
    ),
    fig_columns = alist(journal = ),
    fig_geometry = alist(x = ),
    fig_panel_size = alist(
      plot = , width = NULL, height = NULL, units = c("mm", "cm", "in")
    ),
    fig_panel_width = alist(
      plots = , journal = NULL, column = NULL, width = NULL,
      units = c("mm", "cm", "in"), format = NULL
    ),
    fig_save = alist(
      filename = , plot = ggplot2::last_plot(), journal = NULL, column = NULL,
      width = NULL, height = NULL, panel_width = NULL, panel_height = NULL,
      units = c("mm", "cm", "in"), dpi = NULL, check = TRUE,
      art_type = c("auto", "colour", "bw", "line", "combination"), ... =
    ),
    fig_width = alist(
      journal = , column = "single", units = c("mm", "cm", "in")
    ),
    figspec_chunk_opts = alist(
      journal = , column = NULL, height = NULL, units = c("mm", "cm", "in"),
      width = NULL,
      art_type = c("auto", "colour", "bw", "line", "combination")
    ),
    figspec_knitr_setup = alist(
      journal = , column = NULL, height = NULL, units = c("mm", "cm", "in"),
      width = NULL,
      art_type = c("auto", "colour", "bw", "line", "combination")
    ),
    figspec_linetypes = alist(n = ),
    figspec_linewidth = alist(journal = ),
    figspec_palette = alist(palette = "okabe_ito", n = NULL),
    figspec_palettes = pairlist(),
    figspec_preview = alist(
      plot = ggplot2::last_plot(), journal = , column = "single",
      height = NULL, units = c("mm", "cm", "in")
    ),
    figspec_shapes = alist(n = , style = c("solid", "hollow", "filled")),
    fit_journal = alist(
      journal = , colour = TRUE, shapes = TRUE, style = NULL,
      base_size = NULL, color = NULL
    ),
    graphical_abstract_spec = alist(journal = ),
    house_styles = pairlist(),
    journal_palette = alist(journal = ),
    journal_spec = alist(journal = ),
    journals = alist(discipline = NULL),
    load_house_styles = alist(path = , allow_functions = FALSE),
    load_journals = alist(path = ),
    spec_save = alist(
      spec = , path = , id = NULL, source_url = NULL,
      verified_on = NULL, overwrite = FALSE
    ),
    media_spec = alist(journal = ),
    new_journal_entry = alist(id = , name = , source_url = ),
    refit_journal = alist(
      plots = , journal = , outdir = , column = NULL,
      retheme = TRUE, format = NULL
    ),
    register_house_style = alist(name = , theme = , description = NULL),
    register_journal = alist(
      id = , name = , source_url = , verified_on = , requirements = list(),
      house_style = NULL, ... =
    ),
    registry_status = alist(max_age_days = 365, as_of = Sys.Date()),
    remove_house_style = alist(name = ),
    save_house_styles = alist(path = ),
    scale_color_figspec = alist(palette = "okabe_ito", ... = ),
    scale_colour_figspec = alist(palette = "okabe_ito", ... = ),
    scale_fill_figspec = alist(palette = "okabe_ito", ... = ),
    scale_shape_figspec = alist(... = , style = c("solid", "hollow", "filled")),
    stale_entries = alist(max_age_days = 365, as_of = Sys.Date()),
    submission_detail = alist(x = , file = ),
    suggest_art_type = alist(plot = , journal = NULL),
    table_spec = alist(journal = ),
    table_apply_spec = alist(table = , spec = ),
    table_check = alist(x = , spec = NULL),
    table_save = alist(
      filename = , table = , spec = NULL, transform = TRUE,
      check = TRUE, ... =
    ),
    tag_panels = alist(
      plot = , journal = NULL, level = NULL, open = "(", close = ")",
      strips = FALSE, x = -Inf, y = Inf, hjust = -0.6, vjust = 1.4, ... =
    ),
    theme_journal = alist(
      journal = , base = NULL, style = NULL, base_size = NULL,
      base_family = NULL
    ),
    validate_registry_file = alist(path = )
  ),
  s3 = c(
    "[.figspec_report", "[.figspec_submission", "ggplot_add.figspec_fit",
    "plot.figspec_geometry", "print.figspec_abstract_spec",
    "print.figspec_geometry", "print.figspec_media_spec",
    "print.figspec_report", "print.figspec_sources", "print.figspec_spec",
    "print.figspec_submission", "print.figspec_table_report",
    "print.figspec_table_spec"
  ),
  exact_aliases = c(
    check_color_safety = "check_colour_safety",
    scale_color_figspec = "scale_colour_figspec"
  ),
  fit_config = c("journal", "colour", "shapes", "style", "base_size"),
  report_attributes = c(
    "names", "row.names", "class", "no_spec", "journal", "journal_id",
    "source_url", "verified_on", "publication_stage", "input"
  ),
  merged_report_attributes = c(
    "names", "row.names", "class", "journal", "journal_id", "source_url",
    "verified_on", "publication_stage", "input"
  ),
  colour_report_attributes = c(
    "names", "row.names", "class", "journal", "journal_id", "source_url",
    "verified_on", "input", "colours"
  ),
  submission_attributes = c(
    "names", "row.names", "class", "reports", "journal", "source_url",
    "verified_on", "from_plots"
  ),
  submission_columns = c(
    "file", "asset", "column", "result", "failed", "unresolved",
    "unspecified", "panel_mm"
  ),
  table_report_attributes = c(
    "names", "row.names", "class", "no_spec", "spec_name", "spec_id",
    "source_url", "verified_on", "publication_stage", "input",
    "table_system"
  ),
  spec_list_columns = c(
    "id", "name", "publisher", "disciplines", "single_mm", "double_mm",
    "dpi_min", "font_min_pt", "max_file_mb", "table_requirements",
    "publication_stage", "verified_on", "origin"
  ),
  registry_status_columns = c(
    "id", "verified_on", "age_days", "stale", "stated",
    "confirmed_absent", "unharvested", "table_stated",
    "table_confirmed_absent", "table_unreviewed", "origin"
  ),
  table_report_columns = c("check", "requirement", "actual", "status"),
  table_status_values = c("pass", "fail", "unspecified", "unknown", "invalid"),
  submission_result_values = c(
    "pass", "fail", "incomplete", "invalid", "inspection"
  ),
  table_registry_fields = c(
    "formats", "editable", "orientation", "width_max_mm", "font_families",
    "font_min_pt", "font_max_pt", "title_style", "title_position",
    "header_bold", "vertical_rules", "horizontal_rules", "decimal_alignment",
    "footnotes", "abbreviations", "repeat_header", "split_rows"
  ),
  asset_spec_name_field = "journal",
  table_spec_fields = c(
    "orientation", "title_style", "source_quote", "notes", "journal",
    "source_url", "verified_on"
  ),
  media_spec_fields = c(
    "video_formats", "video_codec", "frame_max", "frame_preferred",
    "max_file_mb", "audio_formats", "audio_bitrate_kbps",
    "source_quote_frame", "source_quote_format", "journal", "source_url",
    "verified_on", "publication_stage"
  ),
  abstract_spec_fields = c(
    "width_mm", "height_mm", "dpi_min", "formats", "max_characters",
    "source_quote", "journal", "source_url", "verified_on"
  ),
  column_condition_classes = c(
    "figspec_column_without_journal", "figspec_error", "rlang_error",
    "error", "condition"
  ),
  column_condition_fields = c(
    "message", "trace", "parent", "column", "body", "rlang", "call",
    "use_cli_format"
  ),
  report_subset_behavior = list(class = "data.frame", removed_attribute = "journal"),
  report_print_behavior = list(profile_label = "Nature")
)

figspec_current_api_contract$exports <- lapply(
  figspec_current_api_contract$exports,
  as.pairlist
)
