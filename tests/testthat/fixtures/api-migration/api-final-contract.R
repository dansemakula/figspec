# Approved target contract for the first public figspec API. Migration tests
# read this file; do not regenerate it from the implementation being changed.

figspec_final_api_contract <- list(
  exports = list(
    color_safety_check = alist(plot = , spec = , threshold = 10),
    colour_safety_check = alist(plot = , spec = , threshold = 10),
    media_check = alist(path = , spec = ),
    registry_check_sources = alist(ids = NULL, timeout = 10),
    submission_check = alist(
      x = , spec = NULL, column = NULL, dpi = NULL,
      pattern = "\\.(tiff?|png|jpe?g|pdf|eps|ps|svg|html?|docx|rtf|tex|latex)$",
      recursive = FALSE,
      art_type = c("auto", "colour", "bw", "line", "combination"),
      asset_type = c("auto", "figure", "table")
    ),
    fig_check = alist(
      x = , spec = NULL, column = NULL, width = NULL, height = NULL,
      units = c("mm", "cm", "in"), dpi = NULL, format = NULL,
      colour_mode = NULL, color_mode = NULL,
      art_type = c("auto", "colour", "bw", "line", "combination")
    ),
    fig_columns = alist(spec = ),
    fig_geometry = alist(x = ),
    fig_panel_size = alist(
      plot = , width = NULL, height = NULL, units = c("mm", "cm", "in")
    ),
    fig_panel_width = alist(
      plots = , spec = NULL, column = NULL, width = NULL,
      units = c("mm", "cm", "in"), format = NULL
    ),
    fig_save = alist(
      filename = , plot = ggplot2::last_plot(), spec = NULL, column = NULL,
      width = NULL, height = NULL, panel_width = NULL, panel_height = NULL,
      units = c("mm", "cm", "in"), dpi = NULL, transform = TRUE, check = TRUE,
      art_type = c("auto", "colour", "bw", "line", "combination"), ... =
    ),
    fig_width = alist(
      spec = , column = "single", units = c("mm", "cm", "in")
    ),
    figspec_knitr_options = alist(
      spec = , column = NULL, width = NULL, height = NULL,
      units = c("mm", "cm", "in"),
      art_type = c("auto", "colour", "bw", "line", "combination")
    ),
    figspec_knitr_setup = alist(
      spec = , column = NULL, width = NULL, height = NULL,
      units = c("mm", "cm", "in"),
      art_type = c("auto", "colour", "bw", "line", "combination")
    ),
    figspec_linetypes = alist(n = ),
    spec_linewidth = alist(spec = ),
    figspec_palette = alist(palette = "okabe_ito", n = NULL),
    figspec_palettes = pairlist(),
    fig_preview = alist(
      plot = ggplot2::last_plot(), spec = , column = "single",
      height = NULL, units = c("mm", "cm", "in")
    ),
    figspec_shapes = alist(n = , style = c("solid", "hollow", "filled")),
    fig_apply_spec = alist(
      spec = , colour = TRUE, shapes = TRUE, style = NULL,
      base_size = NULL, color = NULL
    ),
    graphical_abstract_spec = alist(spec = ),
    style_list = pairlist(),
    spec_style_palette = alist(spec = ),
    spec_get = alist(spec = ),
    spec_list = alist(discipline = NULL),
    style_load = alist(path = , allow_functions = FALSE),
    spec_load = alist(path = ),
    spec_save = alist(
      spec = , path = , id = NULL, source_url = NULL,
      verified_on = NULL, overwrite = FALSE
    ),
    media_spec = alist(spec = ),
    registry_entry_template = alist(id = , name = , source_url = ),
    fig_refit = alist(
      plots = , spec = , output_dir = , column = NULL,
      retheme = TRUE, format = NULL
    ),
    style_register = alist(name = , theme = , description = NULL),
    spec_register = alist(
      id = , name = , source_url = , verified_on = , requirements = list(),
      house_style = NULL, ... =
    ),
    registry_status = alist(max_age_days = 365, as_of = Sys.Date()),
    style_remove = alist(name = ),
    style_save = alist(path = ),
    scale_color_figspec = alist(palette = "okabe_ito", ... = ),
    scale_colour_figspec = alist(palette = "okabe_ito", ... = ),
    scale_fill_figspec = alist(palette = "okabe_ito", ... = ),
    scale_shape_figspec = alist(... = , style = c("solid", "hollow", "filled")),
    registry_stale_entries = alist(max_age_days = 365, as_of = Sys.Date()),
    submission_detail = alist(x = , file = ),
    fig_suggest_art_type = alist(plot = , spec = NULL),
    table_spec = alist(spec = ),
    table_apply_spec = alist(table = , spec = ),
    table_check = alist(x = , spec = NULL),
    table_save = alist(
      filename = , table = , spec = NULL, transform = TRUE,
      check = TRUE, ... =
    ),
    fig_tag_panels = alist(
      plot = , spec = NULL, level = NULL, open = "(", close = ")",
      strips = FALSE, x = -Inf, y = Inf, hjust = -0.6, vjust = 1.4, ... =
    ),
    theme_spec = alist(
      spec = , base = NULL, style = NULL, base_size = NULL,
      base_family = NULL
    ),
    registry_validate_file = alist(path = )
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
    color_safety_check = "colour_safety_check",
    scale_color_figspec = "scale_colour_figspec"
  ),
  fit_config = c("spec", "colour", "shapes", "style", "base_size"),
  report_attributes = c(
    "names", "row.names", "class", "no_spec", "spec_name", "spec_id",
    "source_url", "verified_on", "publication_stage", "input"
  ),
  merged_report_attributes = c(
    "names", "row.names", "class", "spec_name", "spec_id", "source_url",
    "verified_on", "publication_stage", "input"
  ),
  colour_report_attributes = c(
    "names", "row.names", "class", "spec_name", "spec_id", "source_url",
    "verified_on", "input", "colours"
  ),
  submission_attributes = c(
    "names", "row.names", "class", "reports", "spec_name", "source_url",
    "verified_on", "asset_types", "from_plots"
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
  asset_spec_name_field = "spec_name",
  table_spec_fields = c(
    "orientation", "title_style", "source_quote", "notes", "spec_name",
    "source_url", "verified_on"
  ),
  media_spec_fields = c(
    "video_formats", "video_codec", "frame_max", "frame_preferred",
    "max_file_mb", "audio_formats", "audio_bitrate_kbps",
    "source_quote_frame", "source_quote_format", "spec_name", "source_url",
    "verified_on", "publication_stage"
  ),
  abstract_spec_fields = c(
    "width_mm", "height_mm", "dpi_min", "formats", "max_characters",
    "source_quote", "spec_name", "source_url", "verified_on"
  ),
  column_condition_classes = c(
    "figspec_column_without_spec", "figspec_error", "rlang_error",
    "error", "condition"
  ),
  column_condition_fields = c(
    "message", "trace", "parent", "column", "body", "rlang", "call",
    "use_cli_format"
  ),
  report_subset_behavior = list(class = "data.frame", removed_attribute = "spec_name"),
  report_print_behavior = list(profile_label = "Nature")
)

figspec_final_api_contract$exports <- lapply(
  figspec_final_api_contract$exports,
  as.pairlist
)
