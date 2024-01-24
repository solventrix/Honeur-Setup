# How to execute the DiTrAn data pipeline

## Prerequisites
1. The local installation for HONEUR is installed and running
2. The user has access to the HONEUR Harbor repository for DiTrAn
3. DiTrAn is installed
   1. If DiTrAn is not yet installed, follow the instructions <a href="https://github.com/solventrix/Honeur-Setup/tree/master/local-installation/separate-scripts#ditran" target="_blank">here</a>

## Execution steps
1. Open a terminal window
2. Download the 'DiTrAn data pipeline' run script:
    * Linux:
      ```curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/DiTrAn/prepare-ditran-data.sh --output prepare-ditran-data.sh  && chmod +x prepare-ditran-data.sh```
    * Windows:
      ```curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/DiTrAn/prepare-ditran-data.cmd --output prepare-ditran-data.cmd```
3. Execute the script (from the directory where the script is downloaded)
    * Linux:
      ```./prepare-ditran-data.sh```
    * Windows:
      ```prepare-ditran-data.cmd```
4. The script will run the DiTrAn Data Pipeline and show the output of the code

