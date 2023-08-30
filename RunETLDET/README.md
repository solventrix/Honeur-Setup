# How to execute the ETL for the Data Entry Tool (DET)

## Prerequisites
1. Docker is installed and running.
2. A HONEUR local installation is up and running
3. The Data Entry Tool (DET) for HONEUR is up and running
4. The user has access to the HONEUR DET Harbor repository containing the ETL image.
5. The HONEUR OMOP CDM database is running in a Docker container named `postgres`:
    * Check this by running `docker ps`. You should see the `postgres` container listed as running and healthy.
    * See [https://github.com/solventrix/Honeur-Setup/tree/master/local-installation](https://github.com/solventrix/Honeur-Setup/tree/master/local-installation) for more info.
6. An empty OMOP CDM v5.4 schema is present in the Postgres database

## Optional: add an OMOP CDM v5.4 schema to an existing postgres database with OMOP CDM v5.3 
1. Open a terminal window
2. Download the sh (Linux/MacOS) or cmd (Windows) script:
    * Linux/MacOS: `curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/RunETLDET/create-target-schema.sh --output create-target-schema.sh && chmod +x create-target-schema.sh`
    * Windows: `curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/RunETLDET/create-target-schema.cmd --output create-target-schema.cmd`
3. Execute the script 
    * Linux/MacOS: `./create-target-schema.sh`
    * Windows: `.\create-target-schema.cmd`
   
## Steps to execute the DET ETL
1. Open a terminal window
2. Create a new directory for the ETL script execution, e.g.:
    * `mkdir etl_det`
    * `cd etl_det`
2. Download the ETL run script:
    * Linux/MacOS: `curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/RunETLDET/runETL.sh --output runETL.sh && chmod +x runETL.sh`
    * Windows: `curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/RunETLDET/runETL.cmd --output runETL.cmd`
3. Execute the script by running
    * Linux/MacOS: `./runETL.sh`
    * Windows: `.\runETL.cmd`
4. The script will request input for the 
    * the ETL version 
    * the source dataase (Opal)
    * the target database (OMOP CDM)
5. The script will run the ETL code and show the output of the code
7. The `etl_<datetime>.log` log file will be available in the `log` folder.

Please review the log files to confirm that no patient-level information was written out before sharing them.
