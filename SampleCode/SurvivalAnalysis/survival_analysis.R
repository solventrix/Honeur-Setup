#install.packages('RFeder8', repos = 'https://r-package-manager.honeur.org/prod-internal/latest')
library(RFeder8)
library(DBI)
library(sqldf)
library(RPostgreSQL)
library(SqlRender)
library(survminer)
require("survival")

# Environment variables that can be set
therapeuticArea <- Sys.getenv("THERAPEUTIC_AREA", unset="HONEUR")
organization <- Sys.getenv("ORGANIZATION")
db_name <- Sys.getenv("DB_NAME", unset="OHDSI")
db_host <- Sys.getenv("DB_HOST", unset="postgres")
db_port <- Sys.getenv("DB_PORT", unset="5432")
db_user <- Sys.getenv("DB_USER")
db_password <- Sys.getenv("DB_PASSWORD")
cdm_schema <- Sys.getenv("CDM_SCHEMA", unset="omopcdm")
vocabulary_schema <- Sys.getenv("VOCABULARY_SCHEMA", unset="omopcdm")
results_schema <- Sys.getenv("RESULTS_SCHEMA", unset="results")

# Try to load the DB connection details from the configuration server
tryCatch(
  {
    config_server="http://config-server:8080/config-server"
    config_name <- paste0("feder8-config-", tolower(therapeuticArea))
    if(organization != '') {
      config_name <- paste0(config_name, "-", tolower(organization))
    }
    local_config <- load_configuration(config_server=config_server, config_name=config_name)
    set_configuration(local_config)
    db_name <- local_config$local$datasource$name
    db_host <- local_config$local$datasource$host
    db_port <- local_config$local$datasource$port
    db_user <- local_config$local$datasource$admin_username
    db_password <- local_config$local$datasource$admin_password
    cdm_schema <- local_config$local$datasource$cdm_schema
    vocabulary_schema <- local_config$local$datasource$vocabulary_schema
    results_schema <- local_config$local$datasource$results_schema
    print("DB connection details loaded from the config server")
  },
  error=function(cond) {
    message("Local configuration could not be retrieved from the config server")
    message("Using pre-defined DB connection details")
  },
  warning=function(cond) {
    message("Local configuration could not be retrieved from the config server")
    message("Using pre-defined DB connection details")
  }
)

analysis_table_schema <- Sys.getenv("DB_ANALYSIS_TABLE_SCHEMA", unset=results_schema)
analysis_table_name <- Sys.getenv("DB_ANALYSIS_TABLE_name", unset="analysis_table")

# DB connection parameters for SQLDF functions
options(sqldf.RPostgreSQL.user = db_user,
        sqldf.RPostgreSQL.password = db_password,
        sqldf.RPostgreSQL.dbname = db_name,
        sqldf.RPostgreSQL.host = db_host,
        sqldf.RPostgreSQL.port = db_port)

tryCatch(
  {
    # Query analysis table
    analysisTableQuery <- SqlRender::render("select (os_date - diag_date) as days_os, (os_date - diag_date) /365.2 as years_os, status_os, age_diagnosis as age, gender, iss_cat
                                            from @analysis_table_schema.@analysis_table",
                                            analysis_table_schema = analysis_table_schema,
                                            analysis_table = analysis_table_name)
    survivalData <- sqldf(analysisTableQuery)
  },
  error=function(cond) {
    print("Query on analysis table failed")
  },
  warning=function(cond) {
    print("Query on analysis table failed")
  }
)

# Survival analysis

# Kaplan Meier Survival Analysis
km_fit <- survfit(Surv(years_os, status_os) ~ iss_cat, data = survivalData)
ggsurvplot(km_fit, data = survivalData, conf.int = TRUE, risk.table = TRUE, pval = TRUE)

# Cox Proportional Hazards Model
cox <- coxph(Surv(years_os, status_os) ~ iss_cat, data = survivalData)
cox_fit <- survfit(cox)
ggforest(cox)
plot(cox_fit, xlab = "Years", ylab = "Survival")
