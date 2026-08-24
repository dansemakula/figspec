# Panel sizing: canvas = panel + decoration.
#
# Also the input validation around it, which matters more than usual because a
# graphics device handed a non-positive or non-finite size ends the R session
# rather than raising an error.

skip_if_not_installed("ggplot2")

p_plain <- function() {
  ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg)) + ggplot2::geom_point()
}
# What widens the left-hand decoration is the tick LABELS, not the axis title:
# the title is rotated, so its length adds height, not width.
p_wordy <- function() {
  ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg * 100000)) +
    ggplot2::geom_point()
}
geom_of <- function(x) attr(x, "figspec_geometry")
png_out <- function() tempfile(fileext = ".png")

test_that("a panel width is honoured exactly", {
  out <- png_out(); on.exit(unlink(out))
  g <- geom_of(fig_save(out, p_plain(), panel_width = 62))
  expect_equal(g$panel_width_mm, 62, tolerance = 0.05)
})

test_that("the canvas absorbs the decoration rather than the panel", {
  out <- png_out(); on.exit(unlink(out))
  a <- geom_of(fig_save(out, p_plain(), panel_width = 62))
  b <- geom_of(fig_save(out, p_wordy(), panel_width = 62))

  # Same panel, whatever the labels do.
  expect_equal(a$panel_width_mm, b$panel_width_mm, tolerance = 0.05)
  # The wordier figure needs a wider canvas to hold the same panel.
  expect_gt(b$canvas_width_mm, a$canvas_width_mm)
  # canvas = panel + decoration, exactly.
  expect_equal(b$canvas_width_mm, b$panel_width_mm + b$decoration_width_mm,
               tolerance = 0.05)
})

test_that("a journal pins the canvas even when a panel size is given", {
  out <- png_out(); on.exit(unlink(out))
  col <- fig_width("cell_press", "single", "mm")
  g <- geom_of(suppressWarnings(
    fig_save(out, p_plain(), journal = "cell_press", panel_width = 50)
  ))
  expect_equal(g$canvas_width_mm, col, tolerance = 0.05)
  expect_equal(g$panel_width_mm, 50, tolerance = 0.05)
})

test_that("journal-only sizing is unchanged", {
  out <- png_out(); on.exit(unlink(out))
  g <- geom_of(suppressWarnings(fig_save(out, p_plain(), journal = "cell_press")))
  expect_equal(g$canvas_width_mm, fig_width("cell_press", "single", "mm"),
               tolerance = 0.05)
})

test_that("a canvas and a panel are both honoured when they can be", {
  out <- png_out(); on.exit(unlink(out))
  g <- geom_of(fig_save(out, p_plain(), width = 120, panel_width = 62))
  expect_equal(g$canvas_width_mm, 120, tolerance = 0.05)
  expect_equal(g$panel_width_mm, 62, tolerance = 0.05)
})

test_that("an impossible canvas and panel pair reports both escape values", {
  out <- png_out(); on.exit(unlink(out))
  err <- tryCatch(fig_save(out, p_plain(), width = 70, panel_width = 62),
                  error = conditionMessage)
  expect_match(err, "cannot hold")
  # The message must name a canvas that would work and a panel that would work,
  # because the caller cannot compute either without this measurement.
  expect_match(err, "[Ww]iden the canvas to")
  expect_match(err, "panel_width = ")
})

test_that("a panel too wide for the column is refused, with the width that fits", {
  out <- png_out(); on.exit(unlink(out))
  err <- tryCatch(
    suppressWarnings(fig_save(out, p_plain(), journal = "cell_press",
                              panel_width = 200)),
    error = conditionMessage
  )
  # The journal pins the canvas, so this is a canvas-versus-panel failure and
  # must still name the panel width that would have fitted the column.
  expect_match(err, "cannot hold")
  expect_match(err, "panel_width = ")
})

test_that("column without a journal is refused and says what to use instead", {
  out <- png_out(); on.exit(unlink(out))
  err <- tryCatch(fig_save(out, p_plain(), column = "double"),
                  error = conditionMessage)
  expect_match(err, "needs a `journal`")
  expect_match(err, "panel_width")
})

test_that("fig_panel_width takes the narrowest figure as the constraint", {
  figs <- list(plain = p_plain(), wordy = p_wordy())
  pw <- fig_panel_width(figs, journal = "cell_press", format = "png")
  per <- attr(pw, "per_figure")

  expect_equal(as.numeric(pw), min(per), tolerance = 1e-8)
  expect_lt(per[["wordy"]], per[["plain"]])
})

test_that("a shared panel width makes a set match at one canvas", {
  out <- png_out(); on.exit(unlink(out))
  figs <- list(plain = p_plain(), wordy = p_wordy())
  pw <- fig_panel_width(figs, journal = "cell_press", format = "png")

  got <- vapply(figs, function(f) {
    geom_of(suppressWarnings(
      fig_save(out, f, journal = "cell_press", panel_width = pw)
    ))$panel_width_mm
  }, numeric(1))

  expect_equal(diff(range(got)), 0, tolerance = 0.05)
  expect_equal(unname(got[[1]]), as.numeric(pw), tolerance = 0.05)
})

test_that("panel size applies to each panel of a faceted plot", {
  out <- png_out(); on.exit(unlink(out))
  faceted <- p_plain() + ggplot2::facet_wrap(~cyl)
  g <- geom_of(fig_save(out, faceted, panel_width = 30))

  expect_equal(g$panels_across, 3L)
  expect_equal(g$panel_width_mm, 30, tolerance = 0.05)
  # Three 30 mm panels plus decoration, not one 30 mm panel in total.
  expect_gt(g$canvas_width_mm, 90)
})

test_that("panel_width = \"max\" fills the column it is given", {
  out <- png_out(); on.exit(unlink(out))
  g <- geom_of(suppressWarnings(
    fig_save(out, p_plain(), journal = "cell_press", panel_width = "max")
  ))
  expect_equal(g$canvas_width_mm, g$panel_width_mm + g$decoration_width_mm,
               tolerance = 0.05)
  expect_equal(g$canvas_width_mm, fig_width("cell_press", "single", "mm"),
               tolerance = 0.05)
})

test_that("panel_width = \"max\" needs something to fit inside", {
  out <- png_out(); on.exit(unlink(out))
  expect_error(fig_save(out, p_plain(), panel_width = "max"),
               "needs a canvas")
})

test_that("fig_panel_size sets a panel without saving", {
  g <- fig_panel_size(p_plain(), width = 62, height = 45)
  expect_s3_class(g, "gtable")
  geom <- fig_geometry(g)
  expect_equal(geom$panel_width_mm, 62, tolerance = 0.1)
  expect_equal(geom$panel_height_mm, 45, tolerance = 0.1)
})

test_that("fig_geometry reports a plot that has not been sized", {
  geom <- fig_geometry(p_plain())
  expect_s3_class(geom, "data.frame")
  expect_gt(geom$decoration_width_mm, 0)
})

test_that("units are respected", {
  out <- png_out(); on.exit(unlink(out))
  g <- geom_of(fig_save(out, p_plain(), panel_width = 6.2, units = "cm"))
  expect_equal(g$panel_width_mm, 62, tolerance = 0.05)
})

test_that("fig_save still works and matches fig_save", {
  out1 <- png_out(); out2 <- png_out()
  on.exit(unlink(c(out1, out2)))
  a <- geom_of(suppressWarnings(fig_save(out1, p_plain(), journal = "cell_press")))
  b <- geom_of(suppressWarnings(fig_save(out2, p_plain(), journal = "cell_press")))
  expect_equal(a$canvas_width_mm, b$canvas_width_mm)
  expect_equal(a$panel_width_mm, b$panel_width_mm)
})

test_that("a patchwork composition is measured through its sub-plots", {
  skip_if_not_installed("patchwork")
  comp <- patchwork::wrap_plots(p_plain(), p_plain())

  # Unsized, the panels are still free to stretch, so there is no panel width
  # to report -- but the decoration is real and measurable through the nesting.
  loose <- fig_geometry(comp)
  expect_gt(loose$decoration_width_mm, 0)
  expect_true(is.na(loose$panel_width_mm))

  # Sized, every leaf panel takes the width and the total falls out of it.
  sized <- fig_geometry(fig_panel_size(comp, width = 40))
  expect_equal(sized$panel_width_mm, 40, tolerance = 0.1)
  expect_gt(sized$canvas_width_mm, 80)
})

test_that("an unsized plot reports no panel width rather than zero", {
  geom <- fig_geometry(p_plain())
  expect_true(is.na(geom$panel_width_mm))
  expect_true(is.na(geom$canvas_width_mm))
  expect_gt(geom$decoration_width_mm, 0)
})

test_that("column and width together are refused, naming both", {
  out <- png_out(); on.exit(unlink(out))
  err <- tryCatch(
    fig_save(out, p_plain(), journal = "cell_press", column = "double",
             width = 100),
    error = conditionMessage
  )
  expect_match(err, "only one can apply")
  expect_match(err, "double")
  expect_match(err, "100")
})

test_that("a specification can be given without the registry", {
  out <- png_out(); on.exit(unlink(out))
  fig_save(out, p_plain(), panel_width = 62)
  r <- fig_check(out, list(name = "House style", dpi_min = 600))
  expect_equal(r$status[r$check == "Resolution"], "fail")
  # A field the author did not state is their omission, not a registry gap.
  expect_true(all(r$requirement[r$status == "unspecified"] == "not specified"))
})

test_that("with no specification nothing passes and nothing fails", {
  out <- png_out(); on.exit(unlink(out))
  fig_save(out, p_plain(), panel_width = 62)
  r <- fig_check(out)
  expect_true(all(r$status == "unspecified"))
  expect_true(all(r$requirement == "no specification given"))
})

test_that("check_submission reports panel spread without calling it a failure", {
  figs <- list(a = p_plain(), b = p_wordy())
  res <- suppressWarnings(check_submission(figs, "frontiers"))

  expect_true(all(!is.na(res$panel_mm)))
  expect_gt(diff(range(res$panel_mm)), 0.5)
  # Differing plot areas must never be counted as a breach.
  expect_false(any(res$result == "fail"))

  pw <- fig_panel_width(figs, journal = "frontiers")
  matched <- suppressWarnings(
    check_submission(lapply(figs, fig_panel_size, width = pw), "frontiers")
  )
  expect_equal(diff(range(matched$panel_mm)), 0, tolerance = 0.05)
})

test_that("a sized figure can still be checked in full", {
  g <- fig_panel_size(p_plain(), width = 62)
  r <- suppressWarnings(fig_check(g, "cell_press"))
  # Type size lives on the plot, not the layout, so it must survive sizing.
  expect_true("Type size" %in% r$check)
  expect_false(r$status[r$check == "Type size"] == "unknown")
})


# Input validation -------------------------------------------------------
# Graphics devices abort the R session rather than raise an error when handed a
# non-positive or non-finite size, so these must never reach one.

test_that("a size that would crash the device is refused first", {
  out <- png_out(); on.exit(unlink(out))
  for (bad in list(0, -5, NA_real_, Inf, NaN, c(1, 2), "wide", TRUE)) {
    expect_error(fig_save(out, p_plain(), panel_width = bad),
                 class = "figspec_bad_size")
    expect_error(fig_save(out, p_plain(), width = bad),
                 class = "figspec_bad_size")
  }
  expect_error(fig_save(out, p_plain(), dpi = -300), class = "figspec_bad_size")
  expect_error(fig_save(out, p_plain(), dpi = 0), class = "figspec_bad_size")
  expect_error(fig_panel_size(p_plain(), width = -1), class = "figspec_bad_size")
})

test_that("\"max\" is the only string a size accepts", {
  out <- png_out(); on.exit(unlink(out))
  expect_error(fig_save(out, p_plain(), panel_width = "wide"),
               class = "figspec_bad_size")
  expect_error(fig_save(out, p_plain(), panel_width = "max"),
               class = "figspec_max_without_canvas")
  # width has no "max": there is nothing for a canvas to fit inside.
  expect_error(fig_save(out, p_plain(), width = "max"),
               class = "figspec_bad_size")
})

test_that("refusals carry the numbers, not just a message", {
  out <- png_out(); on.exit(unlink(out))
  e <- tryCatch(fig_save(out, p_plain(), width = 70, panel_width = 62),
                figspec_size_conflict = identity)
  expect_s3_class(e, "figspec_size_conflict")
  # A caller must be able to act on this without parsing English.
  expect_equal(e$canvas_mm, 70)
  expect_equal(e$panel_mm, 62)
  expect_gt(e$decoration_mm, 0)
  expect_equal(e$canvas_that_fits_mm, e$panel_mm + e$decoration_mm,
               tolerance = 0.05)
  expect_equal(e$panel_that_fits_mm, e$canvas_mm - e$decoration_mm,
               tolerance = 0.05)
})

test_that("the column conflict names both widths", {
  out <- png_out(); on.exit(unlink(out))
  e <- tryCatch(
    fig_save(out, p_plain(), journal = "cell_press", column = "double",
             width = 100),
    figspec_column_width_conflict = identity
  )
  expect_s3_class(e, "figspec_column_width_conflict")
  expect_equal(e$column, "double")
  expect_equal(e$width, 100)
  expect_equal(e$column_width, fig_width("cell_press", "double", "mm"))
})

test_that("column without a journal is its own condition", {
  out <- png_out(); on.exit(unlink(out))
  e <- tryCatch(fig_save(out, p_plain(), column = "double"),
                figspec_column_without_journal = identity)
  expect_s3_class(e, "figspec_column_without_journal")
  expect_equal(e$column, "double")
})

test_that("every refusal in this family is catchable as one class", {
  out <- png_out(); on.exit(unlink(out))
  cases <- list(
    function() fig_save(out, p_plain(), panel_width = -1),
    function() fig_save(out, p_plain(), width = 70, panel_width = 62),
    function() fig_save(out, p_plain(), column = "double"),
    function() fig_save(out, p_plain(), panel_width = "max"),
    function() fig_save(out, p_plain(), journal = "cell_press",
                        column = "double", width = 100)
  )
  for (f in cases) expect_error(f(), class = "figspec_error")
})


# The error contract -----------------------------------------------------

test_that("every error figspec raises is catchable as figspec_error", {
  out <- png_out(); on.exit(unlink(out))
  cases <- list(
    bad_input     = function() fig_check(42),
    missing_arg   = function() fig_panel_size(p_plain()),
    not_found     = function() journal_spec("definitely_not_a_journal"),
    unsupported   = function() figspec_shapes(99),
    bad_registry  = function() validate_registry(list(list(id = "x"))),
    bad_size      = function() fig_save(out, p_plain(), panel_width = -1),
    size_conflict = function() fig_save(out, p_plain(), width = 70,
                                        panel_width = 62)
  )
  for (nm in names(cases)) {
    expect_error(cases[[nm]](), class = paste0("figspec_", nm))
    expect_error(cases[[nm]](), class = "figspec_error")
  }
})

test_that("no plain stop() is left in the package", {
  # A stop() has no class, so a caller cannot tell one failure from another.
  # This guards the sweep against creeping back.
  src <- unlist(lapply(list.files("../../R", pattern = "[.]R$", full.names = TRUE),
                       readLines, warn = FALSE))
  skip_if(!length(src), "package source not reachable from the test directory")
  offenders <- grep("(^|[^_[:alnum:].])stop\\(", src, value = TRUE)
  offenders <- grep("stop\\(saved\\)|stop\\(e\\)|has_final_stop|stop_on", offenders,
                    value = TRUE, invert = TRUE)
  expect_equal(offenders, character(0))
})


# Where the space goes ---------------------------------------------------

test_that("decoration is reported per side, not only as a total", {
  # A total is enough to compute a canvas but does not say what to change.
  # 26 mm on the right is a legend; 12 mm on the left is axis labels.
  p <- ggplot2::ggplot(mtcars, ggplot2::aes(wt, mpg, colour = factor(cyl))) +
    ggplot2::geom_point()
  g <- fig_geometry(fig_panel_size(p, width = 60, height = 40))

  expect_gt(g$right_mm, g$left_mm)          # the legend is the big consumer
  expect_equal(g$left_mm + g$right_mm + g$gap_x_mm, g$decoration_width_mm,
               tolerance = 0.05)
  expect_equal(g$top_mm + g$bottom_mm + g$gap_y_mm, g$decoration_height_mm,
               tolerance = 0.05)
})

test_that("facet spacing is counted as a gap, not as a margin", {
  faceted <- p_plain() + ggplot2::facet_wrap(~cyl)
  g <- fig_geometry(fig_panel_size(faceted, width = 25))
  expect_gt(g$gap_x_mm, 0)
  expect_equal(g$panels_across, 3L)
  # canvas = every panel + every gap + the margins
  expect_equal(g$canvas_width_mm,
               g$panel_width_mm * 3 + g$gap_x_mm + g$left_mm + g$right_mm,
               tolerance = 0.05)
})

test_that("a composition's sides are measured through the flattened layout", {
  skip_if_not_installed("patchwork")
  # patchwork flattens its plots into one gtable rather than nesting them, so
  # the outer margins are real and the space between the plots lands in the gap.
  comp <- patchwork::wrap_plots(p_plain(), p_plain())
  g <- fig_geometry(fig_panel_size(comp, width = 40))

  expect_equal(g$panels_across, 2L)
  expect_equal(g$panel_width_mm, 40, tolerance = 0.05)
  expect_equal(g$canvas_width_mm,
               40 * 2 + g$left_mm + g$right_mm + g$gap_x_mm,
               tolerance = 0.05)
})

test_that("the geometry prints as a summary, not as a wide data frame", {
  g <- fig_geometry(fig_panel_size(p_plain(), width = 60, height = 40))
  expect_s3_class(g, "figspec_geometry")
  out <- paste(capture.output(print(g), type = "message"), collapse = " ")
  expect_match(out, "Figure geometry")
  expect_match(out, "Decoration")
})

test_that("an unsized figure says so rather than printing a fake canvas", {
  out <- paste(capture.output(print(fig_geometry(p_plain())), type = "message"),
               collapse = " ")
  expect_match(out, "no size of their own")
})

test_that("the geometry can be drawn, and refuses when there is nothing to draw", {
  g <- fig_geometry(fig_panel_size(p_plain(), width = 60, height = 40))
  pl <- plot(g)
  expect_s3_class(pl, "ggplot")
  # One rectangle per panel plus one for the canvas.
  built <- ggplot2::ggplot_build(pl)
  expect_equal(nrow(built$data[[1]]), 2L)

  faceted <- fig_geometry(fig_panel_size(p_plain() + ggplot2::facet_wrap(~cyl),
                                         width = 25, height = 30))
  expect_equal(nrow(ggplot2::ggplot_build(plot(faceted))$data[[1]]), 4L)

  expect_error(plot(fig_geometry(p_plain())), class = "figspec_bad_input")
})
