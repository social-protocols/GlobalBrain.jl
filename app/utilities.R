surprisal <- function(p, unit = 2) {
  # unit determines the unit of information at which we measure surprisal
  # base 2 is the default and it measures information in bits
  return(log(1 / p, unit))
}

entropy <- function(p) {
  return(
    ifelse(
      p == 1,
      0,
      p * surprisal(p, 2) + (1 - p) * surprisal(1 - p, 2)
    )
  )
}

cross_entropy <- function(p, q, unit = 2) {
  return(
    ifelse(
      ((p == 1) & (q == 1)) | ((p == 0) & (q == 0)),
      0,
      p * surprisal(q, unit) + (1 - p) * surprisal(1 - q, unit)
    )
  )
}

relative_entropy <- function(p, q) {
  return(cross_entropy(p, q) - entropy(p))
}

data_to_json <- function(data) {
  return(
    jsonlite::toJSON(
      data,
      dataframe = "rows",
      null = "null", na = "null",
      auto_unbox = TRUE, digits = getOption("shiny.json.digits", 16),
      use_signif = TRUE, force = TRUE,
      POSIXt = "ISO8601", UTC = TRUE,
      rownames = FALSE, keep_vec_names = FALSE,
      json_verabitm = TRUE
    )
  )
}
