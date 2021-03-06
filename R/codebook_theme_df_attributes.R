#' Format Data Frame Attributes Flextable
#'
#' @param ft A flextable object
#'
#' @return A flextable object
codebook_theme_df_attributes <- function(ft) {

  ft <- ft %>%
    # Delete the header row
    flextable::set_header_labels(key = NULL, value = NULL) %>%
    # Set font to TNR 11
    flextable::font(fontname = "Times New Roman") %>%
    flextable::fontsize(size = 11) %>%
    # Left align text
    flextable::align(align = "left", part = "all") %>%
    # Bold text in first column
    flextable::bold(j = 1) %>%
    # Set the width of both columns
    flextable::width(width = 3.25) %>%
    # Add borders all around
    flextable::border_outer(part = "all", border = officer::fp_border()) %>%
    flextable::border_inner_v(part = "all", border = officer::fp_border())

  # Return formatted flextable
  ft
}
