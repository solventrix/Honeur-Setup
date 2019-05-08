# How to execute the ETL for CMG

1. Open a terminal window 
2. Download the installation script:
    * `curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/RunETLCMG/runETL.sh --output runETL.sh && chmod +x runETL.sh`
3. Execute the 'runETL.sh' script
4. The script will request for:
    * the path to the folder that contains the input CSV data files
    * the username and password to connect to the OMOP CDM database (a running Docker container named 'postgres')
5. The script will run the ETL code and show the output of the code
6. The log file will be available in the /CMG/logs folder
