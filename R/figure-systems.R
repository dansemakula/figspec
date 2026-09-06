# Plotting-system adapters -------------------------------------------------
#
# R figures do not share one object model. ggplot2 stores layers, mappings,
# scales and themes; lattice stores a Trellis specification; Plotly stores a
# widget and trace definitions; base graphics normally draws commands straight
# to a device. These adapters give fig_save() one rendering contract while
# preserving those differences instead of claiming capabilities a system does
# not have.

figure_system <- function(x) {
  if (is_ggplot_object(x)) return("ggplot2")
  if (inherits(x, "patchwork")) return("patchwork")
  if (inherits(x, "gtable")) return("gtable")
  if (inherits(x, "plotly")) return("plotly")
  if (inherits(x, "trellis")) return("lattice")
  if (inherits(x, c("grob", "gTree", "gList"))) return("grid")
  if (inherits(x, "recordedplot")) return("recordedplot")
  if (is.function(x) || rlang::is_formula(x, scoped = TRUE)) return("base")
  if (inherits(x, "htmlwidget")) return("htmlwidget")
  figspec_abort(
    c(
      "{.arg plot} is not a supported figure input.",
      "i" = "figspec accepts ggplot2 or patchwork objects, gtables and grid grobs, lattice objects, Plotly or other HTML widgets, recorded base plots, and base-graphics code wrapped in a function or one-sided formula.",
      ">" = "For base R, use {.code function() plot(x, y)} or {.code ~ plot(x, y)} so figspec can open the output device before the plot is drawn."
    ),
    "bad_input", input_class = class(x)
  )
}

panel_capable_system <- function(system) {
  system %in% c("ggplot2", "patchwork", "gtable")
}

transform_capable_system <- function(system) {
  system %in% c("ggplot2", "patchwork", "lattice", "plotly", "grid", "base")
}

figure_system_or_null <- function(x) {
  tryCatch(figure_system(x), error = function(e) NULL)
}

semantic_check_system <- function(system, plot) {
  identical(system, "ggplot2") || identical(system, "patchwork") ||
    (identical(system, "gtable") && !is.null(attr(plot, "figspec_plot")))
}

html_figure_system <- function(system) system %in% c("plotly", "htmlwidget")

figure_system_label <- function(system) {
  switch(system,
    ggplot2 = "ggplot2 plot",
    patchwork = "patchwork composition",
    gtable = "gtable",
    grid = "grid graphic",
    lattice = "lattice plot",
    plotly = "Plotly plot",
    htmlwidget = "HTML widget",
    recordedplot = "recorded base R plot",
    base = "base R drawing function",
    system
  )
}

style_values <- function(spec, family = "") {
  min_pt <- as.numeric(spec$font_min_pt %||% 9)
  max_pt <- if (is.null(spec$font_max_pt)) Inf else as.numeric(spec$font_max_pt)
  base_pt <- min(min_pt, max_pt)
  title_pt <- min(base_pt * 1.2, max_pt)
  line_pt <- as.numeric(spec$min_line_pt %||% 0.75)
  palette <- unlist(spec$house_style$palette %||% list(), use.names = FALSE)
  if (!length(palette)) {
    palette <- figspec_palette(
      if (isTRUE(spec$print_greyscale)) "cividis" else "okabe_ito"
    )
  }
  list(
    family = family,
    base_pt = base_pt,
    title_pt = title_pt,
    line_pt = line_pt,
    base_lwd = line_pt / 0.75,
    palette = unname(palette),
    shapes = figspec_shapes(min(length(palette), 6L)),
    linetypes = figspec_linetypes(min(length(palette), 6L))
  )
}

# Apply the requirements and accessibility defaults that the input system
# exposes. Explicitly drawn base commands and completed recorded plots cannot
# be rewritten reliably; the return value records that distinction for the
# export report.
transform_figure <- function(plot, spec, system, family = "") {
  values <- style_values(spec, family)

  if (identical(system, "ggplot2")) {
    out <- plot + fig_apply_spec(spec)
    if (nzchar(family)) {
      out <- out + ggplot2::theme(text = ggplot2::element_text(family = family))
    }
    attr(out, "figspec_transformation") <- "full"
    return(out)
  }

  if (identical(system, "patchwork")) {
    # `&` is patchwork's supported way to apply one theme to every component.
    out <- plot & theme_spec(spec, base_family = family)
    attr(out, "figspec_transformation") <- "requirements"
    return(out)
  }

  if (identical(system, "lattice")) {
    settings <- list(
      fontsize = list(text = values$base_pt, points = values$base_pt),
      add.text = list(fontfamily = family),
      axis.text = list(fontfamily = family, cex = 1),
      par.main.text = list(fontfamily = family,
                           cex = values$title_pt / values$base_pt),
      par.sub.text = list(fontfamily = family, cex = 1),
      par.xlab.text = list(fontfamily = family, cex = 1),
      par.ylab.text = list(fontfamily = family, cex = 1),
      plot.symbol = list(col = values$palette[[1]], pch = values$shapes[[1]],
                         lwd = values$base_lwd),
      plot.line = list(col = values$palette[[1]], lwd = values$base_lwd),
      superpose.symbol = list(
        col = values$palette, pch = values$shapes,
        lwd = rep(values$base_lwd, length(values$palette))
      ),
      superpose.line = list(
        col = values$palette, lty = values$linetypes,
        lwd = rep(values$base_lwd, length(values$palette))
      ),
      reference.line = list(lwd = values$base_lwd)
    )
    out <- stats::update(plot, par.settings = settings)
    attr(out, "figspec_transformation") <- "full"
    return(out)
  }

  if (identical(system, "plotly")) {
    if (!has_package("plotly")) {
      figspec_abort(
        c("Transforming a Plotly figure needs the {.pkg plotly} package.",
          ">" = "Install it with {.code install.packages(\"plotly\")}.") ,
        "needs_package", package = "plotly"
      )
    }
    out <- plotly::plotly_build(plot)
    font <- list(family = family, size = values$base_pt * 96 / 72,
                 color = "#1A1A1A")
    out$x$layout$font <- utils::modifyList(out$x$layout$font %||% list(), font)
    if (!is.list(out$x$layout$title)) {
      out$x$layout$title <- list(text = as.character(out$x$layout$title %||% ""))
    }
    out$x$layout$title$font <- utils::modifyList(
      out$x$layout$title$font %||% list(),
      list(family = family, size = values$title_pt * 96 / 72)
    )
    out$x$layout$legend$font <- utils::modifyList(
      out$x$layout$legend$font %||% list(), font
    )
    axes <- grep("^[xyz]axis[0-9]*$", names(out$x$layout), value = TRUE)
    for (axis in axes) {
      cfg <- out$x$layout[[axis]] %||% list()
      cfg$tickfont <- utils::modifyList(cfg$tickfont %||% list(), font)
      if (is.list(cfg$title)) {
        cfg$title$font <- utils::modifyList(cfg$title$font %||% list(), font)
      }
      if (isTRUE(spec$axis_lines_and_ticks)) {
        cfg$showline <- TRUE
        cfg$ticks <- "outside"
        cfg$linewidth <- max(as.numeric(cfg$linewidth %||% 0),
                             values$line_pt * 96 / 72)
        cfg$linecolor <- cfg$linecolor %||% "#1A1A1A"
      }
      out$x$layout[[axis]] <- cfg
    }
    for (i in seq_along(out$x$data)) {
      trace <- out$x$data[[i]]
      colour <- values$palette[[(i - 1L) %% length(values$palette) + 1L]]
      shape <- values$shapes[[(i - 1L) %% length(values$shapes) + 1L]]
      dash <- values$linetypes[[(i - 1L) %% length(values$linetypes) + 1L]]
      if (!is.null(trace$marker) || grepl("markers", trace$mode %||% "")) {
        trace$marker <- trace$marker %||% list()
        if (is.null(trace$marker$color) || length(trace$marker$color) == 1L) {
          trace$marker$color <- colour
        }
        trace$marker$symbol <- plotly_symbol(shape)
        trace$marker$line <- trace$marker$line %||% list()
        trace$marker$line$width <- max(
          as.numeric(trace$marker$line$width %||% 0),
          values$line_pt * 96 / 72
        )
      }
      if (grepl("lines", trace$mode %||% "")) {
        trace$line <- trace$line %||% list()
        trace$line$color <- colour
        trace$line$dash <- plotly_dash(dash)
        trace$line$width <- max(as.numeric(trace$line$width %||% 0),
                                values$line_pt * 96 / 72)
      }
      out$x$data[[i]] <- trace
    }
    attr(out, "figspec_transformation") <- "full"
    return(out)
  }

  if (identical(system, "grid")) {
    out <- grid::grobTree(
      plot,
      gp = grid::gpar(
        fontfamily = family,
        fontsize = values$base_pt,
        lwd = values$base_lwd
      )
    )
    attr(out, "figspec_transformation") <- "defaults"
    return(out)
  }

  if (identical(system, "base")) {
    attr(plot, "figspec_base_style") <- values
    attr(plot, "figspec_transformation") <- "defaults"
    return(plot)
  }

  if (system %in% c("recordedplot", "gtable", "htmlwidget")) {
    warning(
      figure_system_label(system),
      " can be exported and verified, but its completed drawing instructions ",
      "cannot be restyled safely. For base R, pass the plotting commands as a ",
      "function or one-sided formula to make them editable at render time.",
      call. = FALSE
    )
    attr(plot, "figspec_transformation") <- "unavailable"
    return(plot)
  }

  plot
}

plotly_symbol <- function(shape) {
  switch(as.character(shape),
    `15` = "square", `16` = "circle", `17` = "triangle-up",
    `18` = "diamond", `3` = "cross", `7` = "x", "circle"
  )
}

plotly_dash <- function(linetype) {
  switch(as.character(linetype),
    solid = "solid", dashed = "dash", dotted = "dot",
    dotdash = "dashdot", longdash = "longdash",
    twodash = "longdashdot", "solid"
  )
}

draw_r_figure <- function(plot, system) {
  if (identical(system, "base")) {
    draw <- if (is.function(plot)) plot else rlang::as_function(plot)
    values <- attr(plot, "figspec_base_style", exact = TRUE)
    old_palette <- grDevices::palette()
    on.exit(grDevices::palette(old_palette), add = TRUE)
    if (!is.null(values)) {
      grDevices::palette(values$palette)
      graphics::par(
        family = values$family,
        ps = values$base_pt,
        cex = 1,
        cex.axis = 1,
        cex.lab = 1,
        cex.main = values$title_pt / values$base_pt,
        lwd = values$base_lwd
      )
    }
    value <- draw()
    if (is_ggplot_object(value)) print(value)
    else if (inherits(value, "trellis")) print(value)
    else if (inherits(value, c("grob", "gTree", "gList"))) grid::grid.draw(value)
    return(invisible(value))
  }
  if (identical(system, "recordedplot")) {
    grDevices::replayPlot(plot)
    return(invisible(plot))
  }
  if (identical(system, "lattice")) {
    print(plot)
    return(invisible(plot))
  }
  if (identical(system, "grid")) {
    grid::grid.newpage()
    grid::grid.draw(plot)
    return(invisible(plot))
  }
  figspec_abort("No R graphics renderer is registered for {.val {system}}.",
                "unsupported", system = system)
}

base_device <- function(ext, colour_mode = NULL) {
  selected <- select_device(ext, colour_mode = colour_mode)
  if (!is.null(selected)) return(selected)
  switch(ext,
    png = grDevices::png,
    jpeg = grDevices::jpeg,
    jpg = grDevices::jpeg,
    tiff = grDevices::tiff,
    tif = grDevices::tiff,
    pdf = grDevices::pdf,
    eps = grDevices::postscript,
    ps = grDevices::postscript,
    svg = grDevices::svg,
    figspec_abort("R has no graphics device for {.val {toupper(ext)}}.",
                  "unsupported", format = ext)
  )
}

merge_named_args <- function(defaults, dots) {
  if (!length(dots)) return(defaults)
  if (is.null(names(dots)) || any(!nzchar(names(dots)))) {
    figspec_abort(
      "Additional device arguments for this plotting system must be named.",
      "bad_input"
    )
  }
  for (name in names(dots)) defaults[[name]] <- dots[[name]]
  defaults
}

write_r_figure <- function(plot, system, filename, ext, width_mm, height_mm,
                           dpi, spec = NULL, family = "", dots = list()) {
  modes <- tolower(unlist(spec$colour_mode %||% list()))
  cmyk <- "cmyk" %in% modes &&
    !any(modes %in% c("rgb", "grayscale", "greyscale"))
  device <- base_device(ext, if (cmyk) "cmyk" else NULL)
  raster <- ext %in% c("png", "jpeg", "jpg", "tiff", "tif")
  args <- list(
    filename,
    width = width_mm / MM_PER_IN,
    height = height_mm / MM_PER_IN
  )
  if (raster) {
    args$units <- "in"
    args$res <- dpi
  } else if (ext %in% c("pdf", "eps", "ps")) {
    args$onefile <- FALSE
  }
  if (ext %in% c("eps", "ps")) {
    args$horizontal <- FALSE
    args$paper <- "special"
  }
  if (nzchar(family) && ext %in% c("pdf", "eps", "ps")) args$family <- family
  if (!is.null(spec)) {
    if (ext %in% c("tiff", "tif") && !is.null(spec$tiff_compression)) {
      args$compression <- spec$tiff_compression
    }
    if (identical(spec$allow_alpha, FALSE)) args$bg <- "white"
  }
  args <- merge_named_args(args, dots)

  before <- grDevices::dev.cur()
  do.call(device, args)
  opened <- grDevices::dev.cur()
  if (identical(opened, before)) {
    figspec_abort("The graphics device did not open.", "device_failed")
  }
  on.exit({
    if (opened %in% grDevices::dev.list()) grDevices::dev.off(opened)
  }, add = TRUE)
  draw_r_figure(plot, system)
  grDevices::dev.off(opened)
  invisible(filename)
}

write_html_figure <- function(plot, system, filename, ext, width_mm, height_mm,
                              dpi, spec = NULL, dots = list()) {
  if (!has_package("htmlwidgets")) {
    figspec_abort(
      c("Exporting this {figure_system_label(system)} needs {.pkg htmlwidgets}.",
        ">" = "Install it with {.code install.packages(\"htmlwidgets\")}.") ,
      "needs_package", package = "htmlwidgets"
    )
  }
  if (identical(system, "plotly") && !has_package("plotly")) {
    figspec_abort(
      c("Exporting a Plotly figure needs the {.pkg plotly} package.",
        ">" = "Install it with {.code install.packages(\"plotly\")}.") ,
      "needs_package", package = "plotly"
    )
  }
  modes <- tolower(unlist(spec$colour_mode %||% list()))
  if ("cmyk" %in% modes && !any(modes %in% c("rgb", "grayscale", "greyscale"))) {
    figspec_abort(
      c(
        "A browser-rendered figure cannot guarantee CMYK output.",
        "i" = "The file was not written because an RGB browser export would not meet the specification.",
        ">" = "Export through a colour-managed prepress tool, or use an R graphics system with a supported CMYK PDF/EPS device."
      ),
      "unsupported", colour_mode = modes
    )
  }

  vector <- ext %in% c("svg", "pdf")
  if (vector) {
    if (!identical(system, "plotly")) {
      figspec_abort(
        c(
          "Vector export is not available for a generic HTML widget.",
          ">" = "Use PNG, JPEG or TIFF, or use the widget package's own vector exporter."
        ),
        "unsupported", system = system, format = ext
      )
    }
    size_px <- c(width_mm, height_mm) / MM_PER_IN * 96
    result <- tryCatch(
      do.call(
        plotly::save_image,
        c(list(
          p = plot, file = filename,
          width = as.integer(round(size_px[[1]])),
          height = as.integer(round(size_px[[2]])), scale = 1
        ), dots)
      ),
      error = function(e) e
    )
    if (inherits(result, "error")) {
      figspec_abort(
        c(
          "Plotly could not create the {toupper(ext)} file.",
          "i" = "Plotly vector export uses its optional Python Kaleido renderer: {conditionMessage(result)}",
          ">" = "Install and configure Plotly's Kaleido requirements, or export a PNG, JPEG or TIFF through figspec's local browser renderer."
        ),
        "needs_package", package = "plotly/Kaleido", parent = result
      )
    }
    return(invisible(filename))
  }

  if (!ext %in% c("png", "jpeg", "jpg", "tiff", "tif")) {
    figspec_abort(
      "Browser-rendered figures support PNG, JPEG and TIFF raster output.",
      "unsupported", format = ext
    )
  }
  if (!has_package("webshot2")) {
    figspec_abort(
      c(
        "Exporting this {figure_system_label(system)} needs {.pkg webshot2} and Chrome or Chromium.",
        ">" = "Install it with {.code install.packages(\"webshot2\")} and make Chrome or Chromium available."
      ),
      "needs_package", package = "webshot2"
    )
  }

  px <- pmax(1L, as.integer(round(c(width_mm, height_mm) / MM_PER_IN * dpi)))
  work <- tempfile("figspec-widget-")
  dir.create(work)
  on.exit(unlink(work, recursive = TRUE, force = TRUE), add = TRUE)
  html <- file.path(work, "figure.html")
  screenshot <- if (ext %in% c("tiff", "tif")) {
    file.path(work, "figure.png")
  } else {
    filename
  }
  plot$width <- paste0(px[[1]], "px")
  plot$height <- paste0(px[[2]], "px")
  htmlwidgets::saveWidget(plot, html, selfcontained = FALSE)
  webshot_args <- merge_named_args(list(
    url = html,
    file = screenshot,
    vwidth = px[[1]],
    vheight = px[[2]],
    selector = ".html-widget",
    delay = 0.5,
    zoom = 1,
    quiet = TRUE
  ), dots)
  do.call(webshot2::webshot, webshot_args)

  if (ext %in% c("tiff", "tif")) {
    if (!has_package("magick")) {
      figspec_abort(
        c("Writing a browser-rendered TIFF needs the {.pkg magick} package.",
          ">" = "Install it with {.code install.packages(\"magick\")}.") ,
        "needs_package", package = "magick"
      )
    }
    compression <- spec$tiff_compression %||% "lzw"
    image <- magick::image_read(screenshot)
    magick::image_write(
      image, path = filename, format = "tiff",
      density = paste0(dpi, "x", dpi), compression = compression
    )
  }
  invisible(filename)
}
