# How to execute the ETL for IUCT (Toulouse)

## Prerequisites
1. Docker is installed and running.
2. The user has access to the Honeur IUCT Harbor repository containing the ETL image.
3. The HONEUR OMOP CDM database is running in a Docker container named `postgres`:
    * Check this by running `docker ps`. You should see the `postgres` container listed as running and healthy.
    * See [https://github.com/solventrix/Honeur-Setup/blob/master/OMOPCDM/README.md](https://github.com/solventrix/Honeur-Setup/blob/master/README.md) for more info.

## Execution steps
1. Open a terminal window 
2. Create a new directory for the ETL script execution, e.g.:
   * `mkdir etl_iuct`
   * `cd etl_iuct`
2. Download the installation script:
    * `curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/RunETLIUCT/runETL.sh --output runETL.sh && chmod +x runETL.sh`
3. Execute the `runETL.sh` script by running `./runETL.sh` from inside the directory where the script is located.
4. The script will request for:
    * the path to the folder that contains the input data files
    * the username and password to connect to the OMOP CDM database (a running Docker container named `postgres`)
    * the tag name for the Docker Hub image
    * the verbosity level [DEBUG, INFO, WARNING, ERROR]
    * the file name of the input data file
    * the date of last update of the data-export, double-quoted, example: "2021-06-30"
5. The script will run the ETL code and show the output of the code
7. The `etl_<datetime>.log` log file will be available in the `log` folder. 

Please review the log files to confirm that no patient-level information was written out before sharing them.