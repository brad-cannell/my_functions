#' @title Hypothesis Testing For Frequency Tables
#'
#' @description The freq_test function is an S3 generic. It currently has
#'   methods for conducting hypothesis tests on one-way and two-way frequency
#'   tables. Further, it is made to work in a dplyr pipeline with the
#'   freq_table function.
#'
#' @param x A tibble of class freq_table_one_way or freq_table_two_way.
#'
#' @param ... Other parameters to be passed on.
#'
#' @param method Options for this parameter control the method used to
#'   calculate p-values.
#'
#'   For the freq_table_two_way class, the options are "pearson" (default) -
#'   to use Pearson's chi-square test of independence, and "fisher" - to use
#'   Fisher's exact test.
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
#' # Test equality of proportions
#'
#' mtcars %>%
#'   group_by(am) %>%
#'   freq_table() %>%
#'   freq_test() %>%
#'   select(var:percent, p_chi2_pearson)
#'
#' #>  # A tibble: 2 x 6
#' #>      var   cat     n n_total percent p_chi2_pearson
#' #>    <chr> <dbl> <int>   <int>   <dbl>          <dbl>
#' #>  1    am     0    19      32   59.38      0.2888444
#' #>  2    am     1    13      32   40.62      0.2888444
#'
#' # Chi-square test of independence
#'
#' mtcars %>%
#'   group_by(am, vs) %>%
#'   freq_table() %>%
#'   freq_test() %>%
#'   select(row_var:n, percent_row, p_chi2_pearson)
#'
#' #> # A tibble: 4 x 7
#' #>   row_var row_cat col_var col_cat     n percent_row p_chi2_pearson
#' #>     <chr>   <dbl>   <chr>   <dbl> <int>       <dbl>          <dbl>
#' #> 1      am       0      vs       0    12       63.16      0.3409429
#' #> 2      am       0      vs       1     7       36.84      0.3409429
#' #> 3      am       1      vs       0     6       46.15      0.3409429
#' #> 4      am       1      vs       1     7       53.85      0.3409429

# =============================================================================
# S3 Generic function
# =============================================================================
freq_test <- function(x, ...) {
  UseMethod("freq_test")
}




# =============================================================================
# Method for class freq_table_one_way
# Chi-square test for equal proportions
# =============================================================================
#' @inheritParams freq_test
#' @export
#' @rdname freq_test

freq_test.freq_table_one_way <- function(x, ...) {

  # ------------------------------------------------------------------
  # Prevents R CMD check: "no visible binding for global variable ‘.’"
  # ------------------------------------------------------------------
  n = n_total = n_expected = chi2_contrib = pchisq = chi2_pearson = df = NULL

  # Check to make sure x is a freq_table_one_way
  # --------------------------------------------
  if (!("freq_table_one_way" %in% class(x))) {
    stop("x must be of class freq_table_one_way. It is currently: ", class(x))
  }

  # Calculate chi-square test of equality
  # Test whether population is equally distributed across categories of x
  # ---------------------------------------------------------------------
  out <- x %>%
    dplyr::mutate(
      n_expected     = n_total / nrow(x),
      chi2_contrib   = (n - n_expected)**2 / n_expected,
      chi2_pearson   = sum(chi2_contrib),
      df             = nrow(x) - 1,
      p_chi2_pearson = pchisq(chi2_pearson, df, lower.tail = FALSE)
    )

  # Add class to out that describes the information it contains
  # -----------------------------------------------------------
  class(out) <- c("pearson", "freq_table_one_way", class(out))

  # Return tibble of results
  out
}




# =============================================================================
# Method for class freq_table_two_way
# Pearson's Chi-square test for independence
# Fisher's exact test for independence
# =============================================================================
#' @inheritParams freq_test
#' @export
#' @rdname freq_test

freq_test.freq_table_two_way <- function(x, method = "pearson", ...) {

  # ------------------------------------------------------------------
  # Prevents R CMD check: "no visible binding for global variable ‘.’"
  # ------------------------------------------------------------------
  n_row = n_col = n_total = n_expected = chi2_contrib = r = pchisq = NULL
  chi2_pearson = df = col_cat = n = row_cat = NULL

  # Check to make sure x is a freq_table_two_way
  # --------------------------------------------
  if (!("freq_table_two_way" %in% class(x))) {
    stop("x must be of class freq_table_two_way. It is currently: ", class(x))
  }

  # Calculate Pearson's Chi-square test
  # Test whether population is equally distributed across categories of x
  # ---------------------------------------------------------------------
  out <- x %>%
    dplyr::group_by(col_cat) %>%
    dplyr::mutate(n_col = sum(n)) %>%  # Find marginal totals for "columns"
    dplyr::ungroup() %>%
    dplyr::mutate(
      n_expected     = (n_row * n_col) / n_total,
      chi2_contrib   = (n - n_expected)**2 / n_expected,
      chi2_pearson   = sum(chi2_contrib),
      r              = unique(row_cat) %>% length(),
      c              = unique(col_cat) %>% length(),
      df             = (r -1) * (c - 1),
      p_chi2_pearson = pchisq(chi2_pearson, df, lower.tail = FALSE)
    )

  # Test for expected cell counts <= 5
  # ----------------------------------
  if ( min(out$n_expected) <= 5 ) {
    warning(paste0("One or more expected cell counts are <= 5. Pearson's ",
                   "Chi-square may not be a valid test."))

    # Add Fisher's Exact Test
    # -------------------
    if ("fisher" %in% method) {

      # Convert x to a matrix
      n_s  <- dplyr::pull(x, n)
      mx   <- matrix(n_s, nrow = 2, byrow = TRUE)

      # Use R's built-in fisher.test
      fisher <- stats::fisher.test(mx)

      # Add Fisher's p_value to out
      out <- out %>%
        dplyr::mutate(p_fisher = fisher$p.value)
    }
  }

  # Add class to out that describes the information it contains
  # -----------------------------------------------------------
  if ("fisher" %in% names(out)) {
    class(out) <- c("fisher", "freq_table_two_way", class(out))
  } else {
    class(out) <- c("pearson", "freq_table_two_way", class(out))
  }

  # Return tibble of results
  out
}
