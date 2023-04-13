runAllLibraries <- function(){
  library(DatabaseConnector)
  library(SqlRender)
  library(httr)
  library(rjson)
  library(RFeder8)
}

runAllLibraries()

# Try to load the DB connection details from the configuration server
therapeutic_area <- Sys.getenv("THERAPEUTIC_AREA")
if(is.null(therapeutic_area) || therapeutic_area == '') {
  therapeutic_area <- "HONEUR"
}
tryCatch(
  {
    config_server="http://config-server:8080/config-server"
    config_name <- paste0("feder8-config-", tolower(therapeutic_area))
    local_config <- load_configuration(config_server=config_server, config_name=config_name)
    set_configuration(local_config)
    cdm_schema <- local_config$local$datasource$cdm_schema
    databaseConnectionDetails <- get_local_db_connection_details(admin_user=TRUE)
    print("DB connection details loaded from the config server")
  },
  error=function(cond) {
    message("Local configuration could not be retrieved from the config server")
  },
  warning=function(cond) {
    message("Local configuration could not be retrieved from the config server")
  }
)

#--------------------------------------------------------------------------

# Retrieve name of CDM source
cdmSourceName <- ""
tryCatch(
  {
    conn <- connect(databaseConnectionDetails)
    # Query CDM source name
    cdmSourceSQL <- render("select cdm_source_abbreviation from @omop.cdm_source", omop = cdm_schema)
    cdmSourceName <- querySql(conn, cdmSourceSQL)$CDM_SOURCE_ABBREVIATION
    # Close database connection
    disconnect(conn)
    print(paste0('CDM source: ', cdmSourceName))
  },
  error=function(cond) {
    message("CDM source name could not be retrieved from the database")
    print(cond)
  },
  warning=function(cond) {
    message("CDM source name could not be retrieved from the database")
  }
)

# Create results
name <- c("Ann", "Jan", "Tom")
age <- c(23, 41, 32)
df <- data.frame(name, age)
# Write data frame to CSV file
site = cdmSourceName
results_filename = paste0(site, ".csv")
write.csv(df, results_filename, row.names = FALSE)

# Save results
script_version_uuid <- Sys.getenv("SCRIPT_UUID")
if (is.null(script_version_uuid) || script_version_uuid == '') {
  script_version_uuid <- find_script_uuid_in_metadata()
}
if (is.null(script_version_uuid) || script_version_uuid == '') {
  print('No script uuid provided, results cannot be shared!')
} else {
  token_context = get_token_context_from_local_token_endpoint()
  if (is.null(token_context)) {
    print('Token cannot be retrieved, results cannot be shared!')
  } else {
    # Save missing variables
    print(paste0('Save ', results_filename))
    save_script_result(script_version_uuid, results_filename, token_context)
    print('Results successfully saved!')
  }
}


