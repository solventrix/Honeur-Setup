# Update custom concepts in the OMOP CDM DB
When new custom concepts are available, they can be easily loaded in the OMOP CDM database.

## Installation steps
1. Open a terminal window (Command Prompt on Windows)
2. Download the installation file
   * For Windows: `curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/UAT/start-omopcdm-custom-concepts-update.cmd --output start-omopcdm-custom-concepts-update.cmd`
   * For Linux and Mac: `curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/UAT/start-omopcdm-custom-concepts-update.sh --output start-omopcdm-custom-concepts-update.sh && chmod +x start-omopcdm-custom-concepts-update.sh`
3. Run *start-omopcdm-custom-concepts-update.sh* (on Linux or Mac) or *start-omopcdm-custom-concepts-update.cmd* (on Windows)
4. The script will prompt for a username and password for Docker Hub. Make sure this docker account has read access on the HONEUR images. If you are already logged in to docker, the program will automatically use the existing credentials.
5. Press Enter to remove the existing omop-cdm-custom-concepts container.
6. After the script has downloaded the required files, it will start importing the custom concepts in the OMOP CDM database.
