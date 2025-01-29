# How to create the analysis table

## Prerequisites
1. The local installation for HONEUR is installed and running
2. The user has access to the HONEUR Harbor repository

## Execution steps
1. Open a terminal window
2. Download the 'Analysis table creation' script:
    * Linux:
      ```curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/AnalysisTable/create-analysis-table.sh --output create-analysis-table.sh  && chmod +x create-analysis-table.sh```
    * Windows:
      ```curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/AnalysisTable/create-analysis-table.cmd --output create-analysis-table.cmd```
3. Execute the script (from the directory where the script is downloaded)
    * Linux:
      ```./create-analysis-table.sh```
    * Windows:
      ```create-analysis-table.cmd```
4. The script will create the analysis table and show the output of the code
