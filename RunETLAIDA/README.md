# How to execute the ETL for AIDA

## Prerequisites
1. Docker is installed 
2. The Feder8 OMOP CDM database is running in a Docker container named 'postgres':
    
## Execution steps
1. Open a terminal window 
2. Download the installation script:
    * `curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/RunETLAIDA/runETL.sh --output runETL.sh && chmod +x runETL.sh`
3. Execute the 'runETL.sh' script
4. The script will request for:
    * the folder and filename of the CSV input file containing the raw data
5. The script will run the ETL code and show the output of the code
6. The log file will be available in a 'logs' folder

