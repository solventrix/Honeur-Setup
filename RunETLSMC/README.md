# How to execute the ETL for Sourasky Medical Center - Tel Aviv (SMC)

## Prerequisites
1. Docker is installed and running.
2. The user has access to the Honeur Sourasky Harbor repository containing the ETL image.
3. The HONEUR OMOP CDM database is running in a Docker container named `postgres`:
    * Check this by running `docker ps`. You should see the `postgres` container listed as running and healthy.
    * See [https://github.com/solventrix/Honeur-Setup/blob/master/OMOPCDM/README.md](https://github.com/solventrix/Honeur-Setup/blob/master/README.md) for more info.

## Execution steps (Mac/Linux)
1. Open a terminal window 
2. Create a new directory for the ETL script execution, e.g.:
   * `mkdir etl_smc`
   * `cd etl_smc`
2. Download the installation script:
    * `curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/RunETLSMC/runETL.sh --output runETL.sh && chmod +x runETL.sh`
3. Execute the `runETL.sh` script by running `./runETL.sh` from inside the directory where the script is located.
4. The script will request for:
    * the path to the folder that contains the input data files
    * the username and password to connect to the OMOP CDM database (a running Docker container named `postgres`)
    * the tag name for the Docker Hub image
    * the delimiter used in the source files (if different from default, make sure to quote the string as in ";")
    * the name of the source files, if different from the default names (see below). 
    * the encoding used for the source files
    * the verbosity level [DEBUG, INFO, WARNING, ERROR]
    * the date of last update of the data-export, double-quoted, example: "2022-10-30"
5. The script will run the ETL code and show the output of the code
7. The `etl_<datetime>.log` log file will be available in the `log` folder. 


## Execution steps (Windows)

1. Open a terminal window 
2. Create a new directory for the ETL script execution, e.g.:
   * `mkdir etl_smc`
   * `cd etl_smc`
3. Download the installation script:
   * `curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/RunETLSMC/runETL.cmd --output runETL.cmd`
4. Execute the `runETL.cmd` script by running `.\runETL.cmd` from inside the directory where the script is located.
5. The script will request for:
   * the path to the folder that contains the input data files
   * the username and password to connect to the OMOP CDM database (a running Docker container named `postgres`)
   * the tag name for the Docker Hub image
   * the delimiter used in the source files (if different from default, make sure to quote the string as in ";")
   * the name of the source files, if different from the default names (see below). 
   * the encoding used for the source files
   * the verbosity level [DEBUG, INFO, WARNING, ERROR]
   * the date of last update of the data-export, double-quoted, example: "2022-10-30"
6. The script will run the ETL code and show the output of the code
7. The `etl_<datetime>.log` log file will be available in the `log` folder. 


Please review the log files to confirm that no patient-level information was written out before sharing them.



*The default file names are:*

```
    demographics.csv
    disease_admission.csv
    disease_ambulatory.csv
    disease_characteristics_myeloma.csv
    disease_chronicdiagnosis.csv
    disease_hematodiagnosis.csv
    lab_data_cytogenetics.csv
    lab_data_fish.csv
    lab_data_test2010_2015.csv
    lab_data_test2016_2018.csv
    lab_data_test2019_2020.csv
    lab_data_test2021_2022.csv
    treatment_cato.csv
    treatment_map.csv
    treatment_medication.csv
```

