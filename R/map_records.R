xda_env <- new.env()
#' Map VA records to coding algorithm.
#'
#' \code{map_records} transform data collected with the WHO VA instrument
#'   to serve different alogrithms for coding cause of death.
#'
#' @param records A dataframe, obtained from reading an ODKBriefcase
#'   export of records collected with the WHO questionnaire.
#' @param mapping Name of an algorithm to map to (one of "interva4" or "tariff2""),
#'   or name of a mapping file.
#' @param csv_outfile Path to a file to write transformed data to.
#'   Defaults to empty string, in which case no file is written.
#' @return A dataframe, with the VA records mapped to the variables required
#'   by a coding algorithm, as specified in the mapping file.
#'
#' @examples
#'
#' record_f_name <- system.file('sample', 'who_va_output.csv', package = 'xva')
#' records <- read.csv(record_f_name)
#' output_data <- map_records(records, 'interva4')
#' mapping_file <- system.file('mapping', 'interva4_mapping.txt', package = 'xva')
#' output_data <- map_records(records, mapping_file)
#' output_f_name <- "output_for_interva4.csv"
#' write.table(
#' output_data,
#' output_f_name,
#' row.names = FALSE,
#' na = "",
#' qmethod = "escape",
#' sep = ","
#' )
#'
#' @export
#'
map_records <- function(records, mapping, csv_outfile = "") {
  if (mapping %in% c('interva4', 'tariff2')){
    mapping_f_name <- system.file('mapping', paste(mapping, '_mapping.txt', sep = ''), package = 'xva')
  }else{
    mapping_f_name <- mapping
  }
  map_def <- read.delim(mapping_f_name)
  records[is.na(records)] <- ""
  headers <- names(records)

  # number of variables required by coding algorithm
  target_n <- nrow(map_def)
  output_data <- data.frame(matrix(ncol = target_n))
  colnames(output_data) <- map_def[, 1]
  for (rec_count in 1:nrow(records)) {
    assign("rec_id", rec_count, envir = xda_env)
    record <- records[rec_count,]
    for (j in 1:length(headers)) {
      value <- as.character(record[1, j])
      header <- headers[j]
      header_cleaned <-
        regmatches(header, regexpr("[^\\.]*$", header))
      assign(header_cleaned, value, envir = xda_env)
    }
    current_data <- data.frame(matrix(ncol = target_n))
    for (i in 1:target_n) {
      target_var <- as.character(map_def[i, 1])
      expr <- as.character(map_def[i, 2])
      current_data[i] <- eval_expr(expr)
      # make the value available for reference later in the destination var set
      name <-
        regmatches(target_var, regexpr("[^\\-]*$", target_var))
      name <- paste("t_", name, sep = "")
      assign(name, current_data[i][[1]], envir = xda_env)
    }
    output_data[rec_count,] <- current_data
  }
  if (csv_outfile != "") {
    write.table(
      output_data,
      csv_outfile,
      row.names = FALSE,
      na = "",
      qmethod = "escape",
      sep = ","
    )
  }
  return(output_data)
}
