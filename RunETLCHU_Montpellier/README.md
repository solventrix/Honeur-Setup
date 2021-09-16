# How to execute the ETL for CHU Montpellier

## Prerequisites
1. Docker is installed and running.
2. The user has access to the honeur CHU Montpellier Harbor repository containing the ETL image.
3. The HONEUR OMOP CDM database is running in a Docker container named `postgres`:
    * Check this by running `docker ps`. You should see the `postgres` container listed as running and healthy.
    * See [https://github.com/solventrix/Honeur-Setup/blob/master/OMOPCDM/README.md](https://github.com/solventrix/Honeur-Setup/blob/master/README.md) for more info.

## Execution steps
1. Open a terminal window 
2. Create a new directory for the ETL script execution, e.g.:
   * `mkdir etl_chumontpellier`
   * `cd etl_chumontpellier`
2. Download the installation script:
    * `curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/RunETLCHU_Montpellier/runETL.sh --output runETL.sh && chmod +x runETL.sh`
3. Execute the `runETL.sh` script by running `./runETL.sh` from inside the directory where the script is located.
4. The script will request for:
    * the path to the folder that contains the input CSV data file
    * the username and password to connect to the OMOP CDM database (a running Docker container named `postgres`)
    * the tag name for the Docker Hub image
    * the verbosity level [DEBUG, INFO, WARNING, ERROR]
    * the date of last update of the data-export
5. The script will run the ETL code and show the output of the code
6. The `etl_<datetime>.log` log file will be available in the `log` folder. In addition, the following logfiles are also written out:
    * `wrong_dateformat_<datetime>.log`: a list of all the unexpected dateformats and how often they appear.
    * `missingmappings_MM_<datetime>.log`: a list of the all missing medical mappings for MM patients and how often they appear.
    * `missingmappings_NON_MM_<datetime>.log`: a list of all the missing medical mappings for non-MM patients and how often they appear.

Please review the log files to confirm that no patient-level information was written out before sharing them.