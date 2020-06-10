install.packages("dplyr", repos="http://cran.us.r-project.org")
install.packages("ParallelLogger", repos="http://cran.us.r-project.org")
install.packages("glue", repos="http://cran.us.r-project.org")

install.packages("https://github.com/solventrix/Honeur-Setup/raw/master/DataQualityDashboard/DataQualityDashboard_1.0.0.tar.gz", repos = NULL, type = "source", INSTALL_opts = c('--no-multiarch'))

library('DataQualityDashboard')

connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "postgresql", 
                                                                user = "honeur_admin", 
                                                                password = "honeur_admin", 
                                                                server = "localhost/OHDSI", 
                                                                port = "5444", 
                                                                extraSettings = "")

cdmDatabaseSchema <- "omopcdm" # the fully qualified database schema name of the CDM

resultsDatabaseSchema <- "results" # the fully qualified database schema name of the results schema (that you can write to)

cdmSourceName <- "CDM_source_name" # a human readable name for your CDM source

numThreads <- 1 

sqlOnly <- FALSE # set to TRUE if you just want to get the SQL scripts and not actually run the queries

outputFolder <- "DataQualityDashboard/output"

verboseMode <- TRUE # set to TRUE if you want to see activity written to the console

writeToTable <- TRUE # set to FALSE if you want to skip writing to a SQL table in the results schema

checkLevels <- c("TABLE", "FIELD", "CONCEPT")
checkNames <- c('conventionSimilarity', 'followsConvention',"wrongDomain", "plausibleValues", 'checkUnit', 'checkAllowedValues', 'isStandardValidConcept','measureValueCompleteness', 'sourceValueCompleteness', 'plausibleTemporalAfter', 'plausibleDuringLife')

tablesToExclude <- c("cost", "payer_plan_period") 

DataQualityDashboard::executeDqChecks(connectionDetails = connectionDetails, 
                                      cdmDatabaseSchema = cdmDatabaseSchema, 
                                      resultsDatabaseSchema = resultsDatabaseSchema,
                                      cdmSourceName = cdmSourceName, 
                                      numThreads = numThreads,
                                      sqlOnly = sqlOnly, 
                                      outputFolder = outputFolder, 
                                      verboseMode = verboseMode,
                                      writeToTable = writeToTable,
                                      checkLevels = checkLevels,
                                      tablesToExclude = tablesToExclude,
                                      checkNames = checkNames)

DataQualityDashboard::viewDqDashboard(jsonPath = file.path(getwd(), outputFolder, cdmSourceName, sprintf("results_%s.json", cdmSourceName)))
