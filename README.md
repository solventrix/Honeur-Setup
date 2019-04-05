# HONEUR-Setup

[![Build Status](https://travis-ci.org/joemccann/dillinger.svg?branch=master)](https://travis-ci.org/joemccann/dillinger)

HONEUR-Setup is a public repository. This repository is used for files that can be downloaded without restrictions

## HONEUR - Remote setup with Docker
### Prerequisites
#### 1. Operating System (OS)
One of the following operating systems should be installed on the host machine:
* Windows 10, or
* Linux (Ubuntu, Debian, CentOS or Fedora), or
* MacOS

#### 2. Docker
Docker should be installed on the host machine
* Windows 10: https://docs.docker.com/docker-for-windows/install/
* Linux: https://docs.docker.com/install/linux/docker-ce/ubuntu/
* MacOS: https://docs.docker.com/docker-for-mac/install/
* Cloud:
    * AWS: https://docs.docker.com/docker-for-aws/
    * Azure: https://docs.docker.com/docker-for-azure/

#### 3. Docker Hub Account
The installer should have a Docker Hub account with read access on the HONEUR repository:
https://hub.docker.com/u/honeur

### Installation Steps

#### Standard Version
1. Open a terminal window (Command Prompt on Windows)
2. Download the installation file
   * For Windows:
         * curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/standard/start-honeur.cmd --output start-honeur.cmd
   * For Linux and Mac
         * curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/standard/start-honeur.sh --output start-honeur.sh && chmod +x start-honeur.sh*
3. Run *start-honeur.sh* (on Linux or Mac) or *start-honeur.cmd* (on Windows)
4. The program will prompt you for username and password for your docker account. Make sure this docker account has read access on the honeur images. If you are already logged in to docker, the program will automatically use the existing credentials.
5. Press Enter to remove existing webapi, zeppelin and postgres container.
6. After the program has downloaded the *docker-compose.yml* file, it will prompt you to give a Fully Qualified Domain Name(FQDN) or IP Address of the host machine. Atlas will only be accessible on the host machine (via localhost) if you fill in localhost.
7. The program will prompt you to give the directory of where to store the zeppelin log files and notebooks.
8. The Postgres database, Atlas, Zeppelin will be downloaded and started as Docker container.

#### Secure Version
1. Open a terminal window (Command Prompt on Windows)
2. Download the installation file
**For Windows**
*curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/secure/start-honeur-secure.cmd --output start-honeur.cmd*
**For Linux and Mac**
*curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/secure/start-honeur-secure.sh --output start-honeur.sh && chmod +x start-honeur.sh*
3. Run *start-honeur-secure.sh* (on Linux or Mac) or *start-honeur-secure.cmd* (on Windows)
4. The program will prompt you for username and password for your docker account. Make sure this docker account has read access on the honeur images. If you are already logged in to docker, the program will automatically use the existing credentials.
5. Press Enter to remove existing webapi, zeppelin and postgres container.
6. After the program has downloaded the docker-compose.yml file, it will prompt you to give a Fully Qualified Domain Name(FQDN) or IP Address of the host machine. Atlas and user management will only be accessible on the host machine (via localhost) if you fill in localhost.
7. The program will prompt you to give the directory of where to store the zeppelin log files and notebooks.
8. The program will prompt you for choosing between ldap or jdbc connection for authentication. if you choose jdbc skip 8. if you choose ldap, the program will prompt you to give the following ldap properties:
    * security.ldap.url: *ldap://ldap.forumsys.com:389* 
    * security.ldap.system.username: *cn=read-onlyadmin,dc=example,dc=com*
    * security.ldap.system.password: *password*
    * security.ldap.baseDn: *dc=example,dc=com*
    * security.ldap.dn: *uid={0},dc=example,dc=com*
9. The program will prompt you for the following user management properties:
    * usermgmt admin username: *admin*
    * usermgmt admin password: *admin*
  10. The Postgres database, Atlas, Zeppelin and a User Mgmt applications will be downloaded and started as Docker containers

### Optional

#### Import constraints and indexes on OMOP CDM Tables
when all custom data is imported, it is recommended that the constraints and indexes are imported on the OMOP CDM tables. This will improve the speed and decrease the risk of corrupt data in the database.

##### Installation steps
1. Open a terminal window (Command Prompt on Windows)
2. Download the installation file
**For Windows**
*curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/start-omopcdm-indexes-and-constraints.cmd --output start-omopcdm-indexes-and-constraints.cmd*
**For Linux and Mac**
*curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/start-omopcdm-indexes-and-constraints.sh --output start-omopcdm-indexes-and-constraints.sh && chmod +x start-omopcdm-indexes-and-constraints.sh*
3. Run *start-omopcdm-indexes-and-constraints.sh* (on Linux or Mac) or *start-omopcdm-indexes-and-constraints.cmd* (on Windows)
4. The program will prompt you for username and password for your docker account. Make sure this docker account has read access on the honeur images. If you are already logged in to docker, the program will automatically use the existing credentials.
5. Press Enter to remove existing omop-indexes-and-constraints container.
6. After the program has downloaded the *docker-compose.yml* and *setup-conf/setup.yml* files, it will start importing the indexes and constraints on the OMOP CDM tables.

#### QA database
QA database can be used as a test database. It's an exact replica of the full database installed with the script start-honeur.cmd (on windows) or start-honeur.sh (on Linux or Mac). It is primarily used for testing scripts on the data in OMOP CDM schema.

##### Installation steps
1. Open a terminal window (Command Prompt on Windowssh
2. Download the installation file
**For Windows**
*curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/start-qa-database.cmd --output start-qa-database.cmd*
**For Linux and Mac**
*curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/start-qa-database.sh --output start-qa-database.sh && chmod +x start-qa-database.sh*
3. Run *start-qa-database.sh* (on Linux or Mac) or *start-qa-database.cmd* (on Windows)
4. The program will prompt you for username and password for your docker account. Make sure this docker account has read access on the honeur images. If you are already logged in to docker, the program will automatically use the existing credentials.
5. Press Enter to remove existing postgres-qa and webapi-source-qa-enable container.
6. After the program has downloaded the docker-compose.yml and setup-conf/setup.yml files, it will start initializing the QA database and insert the source of the QA database inside the original database.
7. Restart webapi/atlas container to make the source available in the webapi/atlas instance. Do this using the following command:
*docker restart webapi*

##### Removal steps
1. Open a terminal window (Command Prompt on Windows)
2. Download the installation file
**For Windows**
*curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/remove-qa-database.cmd --output remove-qa-database.cmd*
**For Linux and Mac**
*curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/remove-qa-database.sh --output remove-qa-database.sh && chmod +x remove-qa-database.sh*
3. Run remove-qa-database.sh (on Linux or Mac) or remove-qa-database.cmd (on Windows)
4. The program will prompt you for username and password for your docker account. Make sure this docker account has read access on the honeur images. If you are already logged in to docker, the program will automatically use the existing credentials.
5. Press Enter to remove existing postgres-qa and webapi-source-qa-disable container.
6. After the program has downloaded the docker-compose.yml and setup-conf/setup.yml files, it will start removing the QA database and removing the source of the QA database inside the original database.
