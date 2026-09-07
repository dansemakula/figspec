# Publication profiles sometimes require proprietary fonts that are not
# installed on clean Linux systems. Tests whose subject is sizing, export,
# resolution, compression, or panel geometry should not depend on those fonts.
# Keep every other recorded requirement while removing only the font rule.
font_neutral_spec <- function(id) {
  spec <- spec_get(id)
  spec$font_families <- NULL
  spec
}
