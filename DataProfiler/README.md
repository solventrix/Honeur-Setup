# How to execute the Data Profiler

## Prerequisites
1. The local installation for HONEUR is installed and running
2. The user has access to the HONEUR Harbor repository

## Execution steps
1. Open a terminal window
2. Download the 'Data Profiler' run script:
    * Linux:
      ```curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/DataProfiler/run-data-profiler.sh --output run-data-profiler.sh  && chmod +x run-data-profiler.sh```
    * Windows:
      ```curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/DataProfiler/run-data-profiler.cmd --output run-data-profiler.cmd```
3. Execute the script (from the directory where the script is downloaded)
    * Linux:
      ```./run-data-profiler.sh```
    * Windows:
      ```run-data-profiler.cmd```
4. The script will run the Data Profiler and show the output of the code
5. The result files will be available in a subfolder 'data_profiler_results'
