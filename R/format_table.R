#' @title Format freq_table and mean_table Output for Publication and Dissemination
#'
#' @description The format_table function is an S3 generic. It currently has
#'   methods for formatting the output of the freq_table and mean_table
#'   functions. For example, a mean and 95% confidence interval would be
#'   formatted as 24.00 (21.00 - 27.00) by default.
#'
#' @param .data A data frame of an accepted class.
#'
#' @param ... Other parameters to be passed on.
#'
#' @param digits Determines the number of decimal places to display. Passed to
#'   the "nsmall =" parameter of the format function.
#'
#'   Note: Changing the digits argument to format_table will change the number
#'   of digits displayed, but does not change the underlying rounding of the
#'   value. That must be changed in the digits argument to mean_table or
#'   freq_table.
#'
#' @param stats Options for this parameter control which formatted statistics
#'   are returned.
#'
#'   For mean_table and mean_table_grouped classes, the options are
#'   "mean and ci" (default) and "n and mean".
#'
#'   For the freq_table_one_way class, the options are "percent and ci" and
#'   "n and percent".
#'
#'   For the freq_table_two_way class, the options are "row percent and ci"
#'   (default), "n and row percent", "percent and ci", "n and percent".
#'
#' @return A tibble.
#'
#' @import magrittr
#' @export
#'
#' @examples
#' library(tidyverse)
#' library(bfuncs)
#'
#' data(mtcars)
#'
#' # Overall mean table with defaults
#'
#' mtcars %>%
#'   mean_table(mpg) %>%
#'   format_table()
#'
#' #> # A tibble: 1 x 2
#' #>   response_var               mean_95
#' #>          <chr>                 <chr>
#' #> 1          mpg 20.09 (17.92 - 22.26)
#'
#' # Grouped means table with defaults
#'
#' mtcars %>%
#'   group_by(cyl) %>%
#'   mean_table(mpg) %>%
#'   format_table()
#'
#' #> # A tibble: 3 x 4
#' #>   response_var group_var group_cat               mean_95
#' #>          <chr>     <chr>     <dbl>                 <chr>
#' #> 1          mpg       cyl         4 26.66 (23.63 - 29.69)
#' #> 2          mpg       cyl         6 19.74 (18.40 - 21.09)
#' #> 3          mpg       cyl         8 15.10 (13.62 - 16.58)
#'
#' # One-way frequency tables with defaults
#'
#' mtcars %>%
#' group_by(cyl) %>%
#'   mean_table(mpg) %>%
#'   format_table()
#' #> # A tibble: 2 x 3
#' #>     var   cat            percent_95
#' #>   <chr> <dbl>                 <chr>
#' #> 1    am     0 59.38 (40.94 - 75.50)
#' #> 2    am     1 40.62 (24.50 - 59.06)
#'
#' # Two-way frequency tables with defaults
#'
#' mtcars %>%
#'   group_by(am, cyl) %>%
#'   freq_table() %>%
#'   format_table()
#'
#' #> # A tibble: 6 x 5
#' #>   row_var row_cat col_var col_cat        percent_row_95
#' #>     <chr>   <dbl>   <chr>   <dbl>                 <chr>
#' #> 1      am       0     cyl       4  15.79 (4.78 - 41.20)
#' #> 2      am       0     cyl       6  21.05 (7.58 - 46.44)
#' #> 3      am       0     cyl       8 63.16 (38.76 - 82.28)
#' #> 4      am       1     cyl       4 61.54 (32.30 - 84.29)
#' #> 5      am       1     cyl       6  23.08 (6.91 - 54.82)
#' #> 6      am       1     cyl       8  15.38 (3.43 - 48.18)
#'
#' #' # Two-way frequency tables with with stats = "n and row percent"
#'
#' mtcars %>%
#'   group_by(am, cyl) %>%
#'   freq_table(output = all) %>% # Don't forget output = all
#'   format_table(stats = "n and row percent")
#'
#' #> # A tibble: 6 x 5
#' #>   row_var row_cat col_var col_cat n_percent_row
#' #>     <chr>   <dbl>   <chr>   <dbl>         <chr>
#' #> 1      am       0     cyl       4     3 (15.79)
#' #> 2      am       0     cyl       6     4 (21.05)
#' #> 3      am       0     cyl       8    12 (63.16)
#' #> 4      am       1     cyl       4     8 (61.54)
#' #> 5      am       1     cyl       6     3 (23.08)
#' #> 6      am       1     cyl       8     2 (15.38)

# =============================================================================
# S3 Generic function
# =============================================================================
format_table <- function(.data, ...) {
  UseMethod("format_table")
}




# =============================================================================
# Method for class mean_table
# Overall means
# =============================================================================
#' @inheritParams format_table
#' @export
#' @rdname format_table

format_table.mean_table <- function(.data, digits = 2, stats = "mean and ci", ...) {

  # ------------------------------------------------------------------
  # Prevents R CMD check: "no visible binding for global variable ‘.’"
  # ------------------------------------------------------------------
  lcl = ucl = n = var = mean_95 = n_mean = response_var = NULL

  # Format statistics
  out <- .data %>%
    dplyr::mutate(
      n       = format(n, big.mark = ","),
      mean    = format(mean, nsmall = digits),
      mean    = trimws(mean),
      lcl     = format(lcl,  nsmall = digits),
      lcl     = trimws(lcl),
      ucl     = format(ucl,  nsmall = digits),
      ucl     = trimws(ucl),
      mean_95 = paste0(mean, " (", lcl, " - ", ucl, ")"),
      n_mean  = paste0(n, " (", mean, ")")
    )

  # Control output
  if (stats == "mean and ci") {
    out <- out %>%
      dplyr::select(response_var, mean_95)

  } else if (stats == "n and mean") {
    out <- out %>%
      dplyr::select(response_var, n_mean )
  }

  # Return result
  out
}




# =============================================================================
# Method for class mean_table_grouped
# Grouped means
# =============================================================================
#' @inheritParams format_table
#' @export
#' @rdname format_table

format_table.mean_table_grouped <- function(.data, digits = 2, stats = "mean and ci", ...) {

  # ------------------------------------------------------------------
  # Prevents R CMD check: "no visible binding for global variable ‘.’"
  # ------------------------------------------------------------------
  lcl = ucl = n = var = mean_95 = n_mean = sem = NULL


  # Format statistics
  out <- .data %>%
    dplyr::mutate(
      n       = format(n, big.mark = ","),
      mean    = format(mean, nsmall = digits),
      mean    = trimws(mean),
      lcl     = format(lcl,  nsmall = digits),
      lcl     = trimws(lcl),
      ucl     = format(ucl,  nsmall = digits),
      ucl     = trimws(ucl),
      mean_95 = paste0(mean, " (", lcl, " - ", ucl, ")"),
      n_mean  = paste0(n, " (", mean, ")")
    )

  # Control output
  # Dropping everything except the variable names, categories, and
  # "mean and ci" or "n and mean"
  if (stats == "mean and ci") {
    out <- out %>%
      dplyr::select(-c(n, mean, sem, lcl, ucl, min, max, n_mean))

  } else if (stats == "n and mean") {
    out <- out %>%
      dplyr::select(-c(n, mean, sem, lcl, ucl, min, max, mean_95))
  }

  # Return result
  out
}




# =============================================================================
# Method for class freq_table_one_way
# One-way frequency tables
# =============================================================================
#' @inheritParams format_table
#' @export
#' @rdname format_table

format_table.freq_table_one_way <- function(.data, digits = 2, stats = "percent and ci", ...) {

  # ------------------------------------------------------------------
  # Prevents R CMD check: "no visible binding for global variable ‘.’"
  # ------------------------------------------------------------------
  percent = lcl = ucl = n = percent_95 = n_percent = var = NULL

  # Format statistics
  out <- .data %>%
    dplyr::mutate(
      n          = format(n, big.mark = ","),
      percent    = format(percent, nsmall = digits),
      percent    = trimws(percent),
      lcl        = format(lcl,  nsmall = digits),
      lcl        = trimws(lcl),
      ucl        = format(ucl,  nsmall = digits),
      ucl        = trimws(ucl),
      percent_95 = paste0(percent, " (", lcl, " - ", ucl, ")"),
      n_percent  = paste0(n, " (", percent, ")")
    )

  # Control output
  if (stats == "percent and ci") {
    out <- out %>%
      dplyr::select(var, cat, percent_95)

  } else if (stats == "n and percent") {
    out <- out %>%
      dplyr::select(var, cat, n_percent )
  }

  # Return result
  out
}




# =============================================================================
# Method for class freq_table_two_way
# Two-way frequency tables
# =============================================================================
#' @inheritParams format_table
#' @export
#' @rdname format_table

format_table.freq_table_two_way <- function(.data, digits = 2, stats = "row percent and ci", ...) {

  # ------------------------------------------------------------------
  # Prevents R CMD check: "no visible binding for global variable ‘.’"
  # ------------------------------------------------------------------
  percent_row = lcl_row = ucl_row = n = percent_total = lcl_total = NULL
  ucl_total = percent_row_95 = n_percent_row = percent_total_95 = NULL
  n_percent_total = row_var = row_cat = col_var = col_cat = NULL


  # Figure out if .data includes overall percentages or not
  # --------------------------------------------------------
  # This depends whether the argument to the "output" parameter of freq_table
  # was "default" or "all".
  # If not, then stats = "percent and ci" or "n and percent" won't work and
  # should return an informative error.
  if ("percent_total" %in% names(.data)) {
    has_overall_percent <- TRUE
  } else {
    has_overall_percent <- FALSE
  }

  # Format row statistics
  # ---------------------
  out <- .data %>%
    dplyr::mutate(
      n              = format(n, big.mark = ","),
      percent_row    = format(percent_row, nsmall = digits),
      percent_row    = trimws(percent_row),
      lcl_row        = format(lcl_row,  nsmall = digits),
      lcl_row        = trimws(lcl_row),
      ucl_row        = format(ucl_row,  nsmall = digits),
      percent_row_95 = paste0(percent_row, " (", lcl_row, " - ", ucl_row, ")"),
      ucl_row        = trimws(ucl_row),
      n_percent_row  = paste0(n, " (", percent_row, ")")
    )

  # Format overall statistics
  # -------------------------
  if ((stats == "percent and ci" || stats == "n and percent") && has_overall_percent) {
    out <- out %>%
      dplyr::mutate(
        n                = format(n, big.mark = ","),
        percent_total    = format(percent_total, nsmall = digits),
        percent_total    = trimws(percent_total),
        lcl_total        = format(lcl_total,  nsmall = digits),
        lcl_total        = trimws(lcl_total),
        ucl_total        = format(ucl_total,  nsmall = digits),
        ucl_total        = trimws(ucl_total),
        percent_total_95 = paste0(percent_total, " (", lcl_total, " - ", ucl_total, ")"),
        n_percent_total  = paste0(n, " (", percent_total, ")")
      )
  }


  # Control output
  # --------------
  if (stats == "row percent and ci") {
    out <- out %>%
      dplyr::select(row_var, row_cat, col_var, col_cat, percent_row_95)

  } else if (stats == "n and row percent") {
    out <- out %>%
      dplyr::select(row_var, row_cat, col_var, col_cat, n_percent_row)

  } else if ((stats == "percent and ci" || stats == "n and percent") && !has_overall_percent) {
    stop("In order to pass stats = 'percent and ci' or 'n and percent' to format_table ",
         "you must first pass 'output = all' to freq_table.")

  } else if (stats == "percent and ci" && has_overall_percent) {
    out <- out %>%
      dplyr::select(row_var, row_cat, col_var, col_cat, percent_total_95)

  } else if (stats == "n and percent" && has_overall_percent) {
    out <- out %>%
      dplyr::select(row_var, row_cat, col_var, col_cat, n_percent_total)
  }

  # Return result
  out
}





















