# How to execute the ETL for CLLEAR

## Prerequisites
1. Git client is installed
2. Docker is installed 
3. The user has (read) access to the CLLEAR_SOURCE repository containing the ETL code on GitHub: https://github.com/solventrix/CLLEAR_SOURCE
4. The HONEUR OMOP CDM database is running in a Docker container named 'postgres':
    * See https://github.com/solventrix/Honeur-Setup/blob/release/1.9/standard/HONEUR%20local%20installation%20instructions.pdf for more info

## Execution steps
1. Open a terminal window 
2. Download the installation script:
    * `curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/release/1.9/RunETLCLLEAR/runETL.sh --output runETL.sh && chmod +x runETL.sh`
3. Execute the 'runETL.sh' script
4. The script will request for:
    * the path to the folder that contains the input CSV data files
    * the username and password to connect to the OMOP CDM database (a running Docker container named 'postgres')
5. The script will run the ETL code and show the output of the code
6. The log file will be available in the /CLLEAR/logs folder
