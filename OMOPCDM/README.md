# How to install the OMOP CDM database for HONEUR

## Prerequisites:

Docker hub account with access to 
* https://hub.docker.com/r/honeur/postgres 
* https://hub.docker.com/r/honeur/postgres-omop-cdm-constraints-and-indexes

## Installation steps
* Open a terminal window (Command Prompt on Windows)
* Download the installation file
    * For Windows: `curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/release/1.10/OMOPCDM/start-omopcdm-db.cmd --output start-omopcdm-db.cmd`
    * For Linux and Mac: `curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/release/1.10/OMOPCDM/start-omopcdm-db.sh --output start-omopcdm-db.sh && chmod +x start-omopcdm-db.sh`
* Run start-omopcdm-db.sh (on Linux or Mac) or start-omopcdm-db.cmd (on Windows)
* The program will prompt you for username and password for your docker account. Make sure this docker account has read access on the HONEUR postgres image. If you are already logged in to docker, the program will automatically use the existing credentials.
* Press Enter to remove the existing HONEUR OMOP CDM postgres container (if any).
* The Postgres database will be downloaded and started as Docker container.
* You can connect to the Postgres database at 'jdbc:postgresql://localhost:5444/OHDSI' (on host machine) or 'jdbc:postgresql://<server-ip>:5444/OHDSI' (from another host)
    * Admin username / password = honeur_admin / honeur_admin
    * Database schema: omopcdm

## Post ETL steps

After the ETL is done, it is recommended to add constraints and indexes to the OMOP CDM DB.

* Open a terminal window (Command Prompt on Windows)
* Download the installation file
    * For Windows: `curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/release/1.10/start-omopcdm-indexes-and-constraints.cmd --output start-omopcdm-indexes-and-constraints.cmd`
    * For Linux and Mac: `curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/release/1.10/start-omopcdm-indexes-and-constraints.sh --output start-omopcdm-indexes-and-constraints.sh && chmod +x start-omopcdm-indexes-and-constraints.sh`
* Run start-omopcdm-indexes-and-constraints.sh (on Linux or Mac) or start-omopcdm-indexes-and-constraints.cmd(on Windows)
* The program will prompt you for username and password for your docker account. Make sure this docker account has read access on the HONEUR ‘honeur/postgres-omop-cdm-constraints-and-indexes’ image. If you are already logged in to docker, the program will automatically use the existing credentials.
* Press Enter to remove existing omop-indexes-and-constraints container.
* A new container will be started to import the indexes and constraints.
