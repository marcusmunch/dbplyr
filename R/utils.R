deparse_all <- function(x) {
  x <- purrr::map_if(x, is_formula, f_rhs)
  purrr::map_chr(x, expr_text, width = 500L)
}

#' Provides comma-separated string out of the parameters
#' @export
#' @keywords internal
named_commas <- function(x) {
  if (is.list(x)) {
    x <- purrr::map_chr(x, as_label)
  } else {
    x <- as.character(x)
  }

  nms <- names2(x)
  out <- ifelse(nms == "", x, paste0(nms, " = ", x))
  paste0(out, collapse = ", ")
}

commas <- function(...) paste0(..., collapse = ", ")

unique_table_name <- function() {
  # Needs to use option to unique names across reloads while testing
  i <- getOption("dbplyr_table_name", 0) + 1
  options(dbplyr_table_name = i)
  sprintf("dbplyr_%03i", i)
}
unique_subquery_name <- function() {
  # Needs to use option so can reset at the start of each query
  i <- getOption("dbplyr_subquery_name", 0) + 1
  options(dbplyr_subquery_name = i)
  sprintf("q%02i", i)
}
unique_column_name <- function() {
  # Needs to use option so can reset at the start of each query
  i <- getOption("dbplyr_column_name", 0) + 1
  options(dbplyr_column_name = i)
  sprintf("col%02i", i)
}
unique_subquery_name_reset <- function() {
  options(dbplyr_subquery_name = 0)
}
unique_column_name_reset <- function() {
  options(dbplyr_column_name = 0)
}

succeeds <- function(x, quiet = FALSE) {
  tryCatch(
    {
      x
      TRUE
    },
    error = function(e) {
      if (!quiet)
        message("Error: ", e$message) # nocov
      FALSE
    }
  )
}

c_character <- function(...) {
  x <- c(...)
  if (length(x) == 0) {
    return(character())
  }

  if (!is.character(x)) {
    cli_abort("Character input expected")
  }

  x
}

cat_line <- function(...) cat(paste0(..., "\n"), sep = "")

# nocov start
res_warn_incomplete <- function(res, hint = "n = -1") {
  if (dbHasCompleted(res)) return()

  rows <- big_mark(dbGetRowCount(res))
  cli::cli_warn("Only first {rows} results retrieved. Use {hint} to retrieve all.")
}

hash_temp <- function(name) {
  name <- paste0("#", name)
  cli::cli_inform(
    paste0("Created a temporary table named ", name),
    class = c("dbplyr_message_temp_table", "dbplyr_message")
  )
  name
}
# nocov end

# Helper for testing
local_methods <- function(..., .frame = caller_env()) {
  local_bindings(..., .env = global_env(), .frame = .frame)
}

local_db_table <- function(con, value, name, ..., temporary = TRUE, envir = parent.frame()) {
  if (inherits(con, "Microsoft SQL Server") && temporary) {
    name <- paste0("#", name)
  }

  withr::defer(DBI::dbRemoveTable(con, name), envir = envir)
  copy_to(con, value, name, temporary = temporary, ...)
  tbl(con, name)
}

local_sqlite_connection <- function(envir = parent.frame()) {
  withr::local_db_connection(
    DBI::dbConnect(RSQLite::SQLite(), ":memory:"),
    .local_envir = envir
  )
}
