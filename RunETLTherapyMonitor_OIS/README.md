# How to execute the ETL for OIS TherapyMonitor

## Prerequisites
1. Docker is installed and running.
2. The user has read access to the ois Docker Hub repository containing the ETL image.
3. The HONEUR OMOP CDM database is running in a Docker container named `postgres`:
    * Check this by running `docker ps`. You should see the `postgres` container listed as running and healthy.
    * See [https://github.com/solventrix/Honeur-Setup/blob/develop/OMOPCDM/README.md](https://github.com/solventrix/Honeur-Setup/blob/develop/README.md) for more info.

## Execution steps
1. Open a terminal window 
2. Create a new directory for the ETL script execution, e.g.:
   * `mkdir etl_therapymonitor`
   * `cd etl_therapymonitor`
2. Download the installation script:
    * `curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/RunETLTherapyMonitor_OIS/runETL.sh --output runETL.sh && chmod +x runETL.sh`
3. Execute the `runETL.sh` script by running `./runETL.sh` from inside the directory where the script is located.
4. The script will request for:
    * the path to the folder that contains the input CSV data file
    * the username and password to connect to the OMOP CDM database (a running Docker container named `postgres`)
    * the tag name for the Docker Hub image
    * the verbosity level [DEBUG, INFO, WARNING, ERROR]
5. The script will run the ETL code and show the output of the code
6. The `etl.log` log file will be available in the `log` folder
