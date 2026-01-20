# How to execute the ETL for Würzburg

## Prerequisites
1. Docker is installed and running.
2. The user has access to the HONEUR Harbor repository containing the ETL image.
3. The HONEUR OMOP CDM database is running in a Docker container named `postgres`:
    * Check this by running `docker ps`. You should see the `postgres` container listed as running and healthy.

## Execution steps (Windows)

1. Open a terminal window
2. Create a new directory for the ETL script execution, e.g.:
   * `mkdir etl_wurzburg`
   * `cd etl_wurzburg`
3. Download the installation script:
   * `curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/RunETLWurzburg/runETL.cmd --output runETL.cmd`
4. Execute the `runETL.cmd` script by running `.\runETL.cmd` from inside the directory where the script is located.
5. The script will request for:
   * the name and tag of the ETL Docker image
   * the path to the folder that contains the input data files
6. The script will run the ETL code and show the output of the code
7. The ETL log file will be available in the `qa` folder.

Please review the log files to confirm that no patient-level information was written out before sharing them.


## Execution steps (Mac/Linux)
1. Open a terminal window
2. Create a new directory for the ETL script execution, e.g.:
   * `mkdir etl_wurzburg`
   * `cd etl_wurzburg`
2. Download the installation script:
   * ```
     curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/RunETLWurzburg/runETL.sh --output runETL.sh && chmod +x runETL.sh
     ```
3. Execute the `runETL.sh` script by running `./runETL.sh` from inside the directory where the script is located.
4. The script will request for:
   * the name and tag of the ETL Docker image
   * the path to the folder that contains the input data files
5. The script will run the ETL code and show the output of the code
7. The ETL log file will be available in the `qa` folder. 

Please review the log files to confirm that no patient-level information was written out before sharing them.


# How to export treatment counts for Würzburg

## Execution steps (Mac/Linux)
1. Open a terminal window
2. Download the export script:
   * ```
     curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/RunETLWurzburg/export-treatment-counts.sh --output export-treatment-counts.sh && chmod +x export-treatment-counts.sh
     ```
3. Execute the `export-treatment-counts.sh` script by running `./export-treatment-counts.sh` from inside the directory where the script is located.
4. The script will request for:
   * the path to the folder that contains the source data files
5. The script will export treatment data counts and show the output of the code
7. The result files will be available in the `output` folder.

Please review the result files to confirm that no patient-level information was written out before sharing them.


