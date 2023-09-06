# How to execute the ETL for the conversion from OMOP v5.3 to v5.4

## Prerequisites
1. Docker is installed and running.
2. A HONEUR local installation is up and running
3. The user has access to the Harbor repository containing the ETL image ('etl-omop54').
4. The HONEUR OMOP CDM database is running in a Docker container named `postgres`:
    * Check this by running `docker ps`. You should see the `postgres` container listed as running and healthy.
    * See [https://github.com/solventrix/Honeur-Setup/tree/master/local-installation](https://github.com/solventrix/Honeur-Setup/tree/master/local-installation) for more info.
 
## Steps to execute the OMOP conversion ETL
1. Open a terminal window
2. Create a new directory for the ETL script execution, e.g.:
    * `mkdir etl_omop54`
    * `cd etl_omop54`
3. Download the ETL run script:
    * Linux/MacOS: `curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/RunETLOMOP54Conversion/runETL.sh --output runETL.sh && chmod +x runETL.sh`
    * Windows: `curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/RunETLOMOP54Conversion/runETL.cmd --output runETL.cmd`
4. Execute the script by running
    * Linux/MacOS: `./runETL.sh`
    * Windows: `.\runETL.cmd`
5. The script will request input for 
    * the ETL version 
    * the source database schema's (OMOP CDM v5.3)
    * the target database schema's (OMOP CDM v5.4)
6. The script will run the ETL code and show the output of the code
7. The `etl_<datetime>.log` log file will be available in the `log` folder. The results of the Data Quality Pipeline will be available in the `qa` folder

Please review the log files to confirm that no patient-level information was written out before sharing them.
