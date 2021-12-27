# Separate scripts

Table of Contents
=================
  * [Requirements](#requirements)
    * [Hardware](#hardware)
    * [Operating system](#operating-system)
    * [Docker](#docker)
    * [Docker images](#docker-images)
  * [Important Note](#important-note)
  * [Postgres installation instructions](#postgres-installation-instructions)
  * [Configuration server](#configuration-server)
  * [Local Portal](#local-portal)
  * [Atlas/WebAPI installation instructions](#atlas-webapi-separate)
  * [Zeppelin installation instructions](#zeppelin-installation-instructions)
  * [User Management installation instructions](#user-management-installation-instructions)
  * [Distributed Analytics installation instructions](#distributed-analytics-installation-instructions)
  * [Feder8 Studio installation instructions](#feder8-studio-installation-instructions)
  * [Proxy server](#proxy-server)
  * [Post ETL installation steps](#post-etl-installation-steps)
    * [Add constraints and indexes](#add-constraints-and-indexes)
    * [Update custom concepts](#update-custom-concepts)
  * [QA database](#qa-database)
    * [Installation](#qa-database-installation)
    * [Removal](#qa-database-removal)
  * [Backup and restore of the database](#backup-and-restore-of-the-database)
  * [Vocabulary update](#vocabulary-update)

## Requirements

### Hardware
Modern 64 bit (x86) dual core processor (or better)
8 GB RAM, 16 GB RAM recommended
100 GB free disk space (or more)

### Operating system
Linux (Ubuntu, CentOS, Debian, …), Windows 10 or MacOS
Linux is recommended

### Docker
Linux: https://docs.docker.com/install/linux/docker-ce/ubuntu/
Windows: https://docs.docker.com/docker-for-windows/install/
MacOS: https://docs.docker.com/docker-for-mac/install/
Assign 2 or more CPU’s, 8 GB of RAM and 100 GB of disk space to Docker in Docker Desktop.
On Linux Docker compose (v1.24 or higher) should be installed separately.

### Docker images
The docker images are located on a central repository. Make sure you have a central platform account before trying to run the local setup installation scripts:

* For HONEUR: https://portal-dev.honeur.org
* For PHederation: https://portal-dev.phederation.org
* For ESFURN: https://portal-dev.esfurn.org

Please request access by sending a mail to Michel Van Speybroeck (mvspeybr@its.jnj.com)

## Important Note
Components like [Atlas/WebAPI](#atlas/webapi-installation-instructions), [Zeppelin](#zeppelin-installation-instructions), [User Management](#user-management-installation-instructions) and [FEDER8 Studio](#feder8-studio-installation-instructions) are only accessible through a web browser when installing the [Proxy server](#proxy-server). Please run the installation script of the [Proxy server](#proxy-server) after installing or updating one of the previous mentioned components.

## Postgres installation instructions
The Postgres database can be installed by running the installation script.

1. Download the installation script (**_start-postgres.sh_** for Linux/MacOS or **_start-postgres.cmd_** for Windows) using the following command:

Linux/MacOS
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/local-installation/separate-scripts/start-postgres.sh --output start-postgres.sh && chmod +x start-postgres.sh
```

Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/local-installation/separate-scripts/start-postgres.cmd --output start-postgres.cmd
```

2. You can run this script using the following command:

Linux/MacOS
```
./start-postgres.sh
```

Windows
```
.\start-postgres.cmd
```

3. The script will prompt to select the applicable therapeutic area.
4. The script will prompt to enter the email address of the account you use to login on the central platform.
5. The script will prompt to enter your CLI secret for pulling our images. This secret can be found on our central image repository. Surf to:
    * https://harbor-dev.honeur.org for HONEUR
    * https://harbor-dev.phederation.org for PHederation
    * https://harbor-dev.esfurn.org for Esfurn
6. Login using the button "LOGIN VIA OIDC PROVIDER". Then click your account name on the top right corner of the screen and click "User Profile". Copy the CLI secret by clicking the copy symbol next to the text field.
7. The script will prompt to enter a new password for standard database user.
8. The script will prompt to enter a new password for admin database user.

Once done, the script will download the Postgres docker image and will create the docker container.

## Configuration server
The configuration server can be installed by downloading and running the installation script.

1. Download the installation script (**_start-config-server.sh_** for Linux/MacOS or **_start-config-server.cmd_** for Windows) using the following command:

Linux/MacOS
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/local-installation/separate-scripts/start-config-server.sh --output start-config-server.sh && chmod +x start-config-server.sh
```

Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/local-installation/separate-scripts/start-config-server.cmd --output start-config-server.cmd
```

2. Run the script using the following command:

Linux/MacOS
```
./start-config-server.sh
```

Windows
```
.\start-config-server.cmd
```

3. The script will prompt to select the applicable therapeutic area.
4. The script will prompt to enter the email address of the account you use to login on the central platform.
5. The script will prompt to enter your CLI secret for pulling our images. This secret can be found on our central image repository. Surf to:
    * https://harbor-dev.honeur.org for HONEUR
    * https://harbor-dev.phederation.org for PHederation
    * https://harbor-dev.esfurn.org for Esfurn
6. Login using the button "LOGIN VIA OIDC PROVIDER". Then click your account name on the top right corner of the screen and click "User Profile". Copy the CLI secret by clicking the copy symbol next to the text field.

Once done, the script will download the configuration server docker image and will create the docker container.

## Local Portal
The Local Portal can be installed by downloading and running the installation script.

1. Download the installation script (**_start-local-portal.sh_** for Linux/MacOS or **_start-local-portal.cmd_** for Windows) using the following command:

Linux/MacOS
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/local-installation/separate-scripts/start-local-portal.sh --output start-local-portal.sh && chmod +x start-local-portal.sh
```

Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/local-installation/separate-scripts/start-local-portal.cmd --output start-local-portal.cmd
```

2. Run the script using the following command:

Linux/MacOS
```
./start-local-portal.sh
```

Windows
```
.\start-local-portal.cmd
```

3. The script will prompt to select the applicable therapeutic area.
4. The script will prompt to enter the email address of the account you use to login on the central platform.
5. The script will prompt to enter your CLI secret for pulling our images. This secret can be found on our central image repository. Surf to:
    * https://harbor-dev.honeur.org for HONEUR
    * https://harbor-dev.phederation.org for PHederation
    * https://harbor-dev.esfurn.org for Esfurn
6. Login using the button "LOGIN VIA OIDC PROVIDER". Then click your account name on the top right corner of the screen and click "User Profile". Copy the CLI secret by clicking the copy symbol next to the text field.

Once done, the script will download the local portal docker image and will create the docker container.

## <a id="atlas-webapi-separate"></a>Atlas/WebAPI installation instructions
The Postgres database installed in the previous step is required for Atlas/WebAPI to function.

Atlas/WebAPI can be installed by running the installation script.

1. Download the installation script (**_start-atlas-webapi.sh_** for Linux/MacOS or **_start-atlas-webapi.cmd_** for Windows) using the following command:

Linux/MacOS
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/local-installation/separate-scripts/start-atlas-webapi.sh --output start-atlas-webapi.sh && chmod +x start-atlas-webapi.sh
```

Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/local-installation/separate-scripts/start-atlas-webapi.cmd --output start-atlas-webapi.cmd
```

2. You can run this script using the following command:

Linux/MacOS
```
./start-atlas-webapi.sh
```

Windows
```
.\start-atlas-webapi.cmd
```

3. The script will prompt to select the applicable therapeutic area.
4. The script will prompt to enter the email address of the account you use to login on the central platform.
5. The script will prompt you to enter your CLI secret for pulling our images. This secret can be found on our central image repository. Surf to:
    * https://harbor-dev.honeur.org for HONEUR
    * https://harbor-dev.phederation.org for PHederation
    * https://harbor-dev.esfurn.org for Esfurn
6. Login using the button "LOGIN VIA OIDC PROVIDER". Then click your account name on the top right corner of the screen and click "User Profile". Copy the CLI secret by clicking the copy symbol next to the text field.
7. The script will prompt to enter a Fully Qualified Domain Name (FQDN) or IP Address of the host machine. Atlas/WebAPI will only be accessible on the host machine (via localhost) if you accept the default ‘localhost’ value.
8. The script will prompt to enable authentication.  Choose "None" if authentication is not required. The same authentication mechanism should be selected for all local components.
9. (OPTIONAL when **_ldap_** is chosen for the installation security) Additional connections details will be asked to connect to the existing LDAP Server.

Once done, the script will download the Atlas/WebAPI docker image and will create the docker container.

:warning: Please run the installation script of the [Proxy server](#proxy-server) after installing or updating Atlas/WebAPI. The proxy is necessary for accessing Atlas/WebAPI through the browser.

## Zeppelin installation instructions
Zeppelin can be installed by running the installation script.

1. Download the installation script (**_start-zeppelin.sh_** for Linux/MacOS or **_start-zeppelin.cmd_** for Windows) using the following command:

Linux/MacOS
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/local-installation/separate-scripts/start-zeppelin.sh --output start-zeppelin.sh && chmod +x start-zeppelin.sh
```

Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/local-installation/separate-scripts/start-zeppelin.cmd --output start-zeppelin.cmd
```

2. You can run this script using the following command:

Linux/MacOS
```
./start-zeppelin.sh
```

Windows
```
.\start-zeppelin.cmd
```

3. The script will prompt to select the applicable therapeutic area.
4. The script will prompt to enter the email address of the account you use to login on the central platform.
5. The script will prompt to enter your CLI secret for pulling our images. This secret can be found on our central image repository. Surf to:
    * https://harbor-dev.honeur.org for HONEUR
    * https://harbor-dev.phederation.org for PHederation
    * https://harbor-dev.esfurn.org for Esfurn
6. Login using the button "LOGIN VIA OIDC PROVIDER". Then click your account name on the top right corner of the screen and click "User Profile". Copy the CLI secret by clicking the copy symbol next to the text field.
7. The script will prompt to enter a directory on the host machine to save the zeppelin logs and notebooks. Please provide an absolute path.
8. The script will prompt you to enter the security options for Zeppelin. If you have existing HONEUR Components like Postgres/Atlas/WebAPI or Feder8 Studio. Please use the same security settings as with these previous installation.
9. (OPTIONAL when **_ldap_** is chosen for the installation security) Additional connections details will be asked to connect to the existing LDAP Server.

Once done, the script will download the Zeppelin docker image and will create the docker container.

:warning: Please run the installation script of the [Proxy server](#proxy-server) after installing or updating Zeppelin. The proxy is necessary for accessing Zeppelin through the browser.

## User Management installation instructions
:warning: User Management should only be installed when other components are installed with the **_secure_** version. When other components are installed with the standard version, you can skip this installation.

User Management can be installed by running the installation script.

1. Download the installation script (**_start-user-management.sh_** for Linux/MacOS or **_start-user-management.cmd_** for Windows) using the following command:

Linux/MacOS
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/local-installation/separate-scripts/start-user-management.sh --output start-user-management.sh && chmod +x start-user-management.sh
```

Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/local-installation/separate-scripts/start-user-management.cmd --output start-user-management.cmd
```

2. Run this script using the following command:

Linux/MacOS
```
./start-user-management.sh
```

Windows
```
.\start-user-management.cmd
```

3. The script will prompt to select the applicable therapeutic area.
4. The script will prompt to enter the email address of the account you use to login on the central platform.
5. The script will prompt you to enter your CLI secret for pulling our images. This secret can be found on our central image repository. Surf to:
    * https://harbor-dev.honeur.org for HONEUR
    * https://harbor-dev.phederation.org for PHederation
    * https://harbor-dev.esfurn.org for Esfurn
6. Login using the button "LOGIN VIA OIDC PROVIDER". Then click your account name on the top right corner of the screen and click "User Profile". Copy the CLI secret by clicking the copy symbol next to the text field.
7. The script will prompt to enter credentials for the administrator user that can manage users and roles.

Once done, the script will download the User Management docker image and will create the docker container.

:warning: Please run the installation script of the [Proxy server](#proxy-server) after installing or updating User Management. The proxy is necessary for accessing User Management through the browser.

## Distributed Analytics installation instructions
:warning: Distributed Analytics requires you to install the [Zeppelin](#zeppelin-installation-instructions) component.

Distributed Analytics can be installed by downloading and running the installation script.

1. Download the installation script (**_start-distributed-analytics.sh_** for Linux/MacOS or **_start-distributed-analytics.cmd_** for Windows) using the following command:

Linux/MacOS
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/local-installation/separate-scripts/start-distributed-analytics.sh --output start-distributed-analytics.sh && chmod +x start-distributed-analytics.sh
```

Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/local-installation/separate-scripts/distributed-analytics.cmd --output start-distributed-analytics.cmd
```

2. Run this script using the following command:

Linux/MacOS
```
./start-distributed-analytics.sh
```

Windows
```
.\start-distributed-analytics.cmd
```

3. The script will prompt to select the applicable therapeutic area.
4. The script will prompt to enter the email address of the account you use to login on the central platform.
5. The script will prompt you to enter your CLI secret for pulling our images. This secret can be found on our central image repository. Surf to:
    * https://harbor-dev.honeur.org for HONEUR
    * https://harbor-dev.phederation.org for PHederation
    * https://harbor-dev.esfurn.org for Esfurn
6. Login using the button "LOGIN VIA OIDC PROVIDER". Then click your account name on the top right corner of the screen and click "User Profile". Copy the CLI secret by clicking the copy symbol next to the text field.
7. The script will prompt to select the name of your organization.

Once done, the script will download the Distributed Analytics docker images and will create the docker containers.

## Feder8 Studio installation instructions
Feder8 Studio can be installed by downloading and running the installation script.

1. Download the installation script (**_start-feder8-studio.sh_** for Linux/MacOS or **_start-feder8-studio.cmd_** for Windows) using the following command:

Linux/MacOS
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/local-installation/separate-scripts/start-feder8-studio.sh --output start-feder8-studio.sh && chmod +x start-feder8-studio.sh
```

Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/local-installation/separate-scripts/start-feder8-studio.cmd --output start-feder8-studio.cmd
```

2. Run the script using the following command:

Linux/MacOS
```
./start-feder8-studio.sh
```

Windows
```
.\start-feder8-studio.cmd
```

3. The script will prompt to select the applicable therapeutic area.
4. The script will prompt to enter the email address of the account you use to login on the central platform.
5. The script will prompt to enter your CLI secret for pulling our images. This secret can be found on our central image repository. Surf to:
    * https://harbor-dev.honeur.org for HONEUR
    * https://harbor-dev.phederation.org for PHederation
    * https://harbor-dev.esfurn.org for Esfurn
6. Login using the button "LOGIN VIA OIDC PROVIDER". Then click your account name on the top right corner of the screen and click "User Profile". Copy the CLI secret by clicking the copy symbol next to the text field.
7. The script will prompt to enter a Fully Qualified Domain Name (FQDN) or IP Address of the host machine. Feder8 Studio will only be accessible on the host machine (via localhost) if you enter ‘localhost’ as host name.
8. The script will prompt to enter the directory of where the Feder8 Studio will store its working directory files.
9. The script will prompt to enter the security options for FEDER8 Studio. If you have existing HONEUR Components like postgres/webapi and zeppelin. Please use the same security settings as with this previous installation.
10. (OPTIONAL when **_ldap_** is chosen for the installation security) Additional connections details will be asked to connect to the existing LDAP Server

Once done, the script will download the Feder8 Studio docker image and will create the docker container.

:warning: Please run the installation script of the [Proxy server](#proxy-server) after installing or updating FEDER8 Studio. The proxy is necessary for accessing FEDER8 Studio through the browser.

## Proxy server
The proxy server can be installed by downloading and running the installation script.

### Prerequisite for HTTPS support during installation
During the installation, the script will ask you if you want to enable HTTPS support for the local toolbox. To enable HTTPS during the installation process, you should provide the certificate and private key beforehand. The files should be placed in a folder on the host machine where the installation will run and the files should be named the following:
* Public certificate (file starting with -----BEGIN CERTIFICATE-----): feder8.crt
* Private Key (file starting with -----BEGIN PRIVATE KEY-----): feder8.key

1. Download the installation script (**_start-nginx.sh_** for Linux/MacOS or **_start-nginx.cmd_** for Windows) using the following command:

Linux/MacOS
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/local-installation/separate-scripts/start-nginx.sh --output start-nginx.sh && chmod +x start-nginx.sh
```

Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/local-installation/separate-scripts/start-nginx.cmd --output start-nginx.cmd
```

2. Run the script using the following command:

Linux/MacOS
```
./start-nginx.sh
```

Windows
```
.\start-nginx.cmd
```

3. The script will prompt to select the applicable therapeutic area.
4. The script will prompt to enter the email address of the account you use to login on the central platform.
5. The script will prompt to enter your CLI secret for pulling our images. This secret can be found on our central image repository. Surf to:
    * https://harbor-dev.honeur.org for HONEUR
    * https://harbor-dev.phederation.org for PHederation
    * https://harbor-dev.esfurn.org for Esfurn
6. Login using the button "LOGIN VIA OIDC PROVIDER". Then click your account name on the top right corner of the screen and click "User Profile". Copy the CLI secret by clicking the copy symbol next to the text field.
7. The script will prompt to ask wheter you want to enable HTTPS support. :warning: Before you can enable HTTPS support, you should have a folder containing a public key certificate file named "feder8.crt" and a private key file named "feder8.key".
8. The script will prompt to enter a directory on the host machine where the public key certificate file named "feder8.crt" and a private key file named "feder8.key" are located.

Once done, the script will download the proxy server docker image and will create the docker container.

## Post ETL installation steps
### Add constraints and indexes
After the ETL is successfully executed, it’s recommended to add the constraints and indexes to the OMOP CDM tables. It will improve the performance and reduce the risk of corrupt data in the database.
Installation steps:
1.	Open a terminal window (Command Prompt on Windows)
2.	Download the installation file

Linux/MacOS
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/local-installation/separate-scripts/start-omop-indexes-and-constraints.sh --output start-omop-indexes-and-constraints.sh && chmod +x start-omop-indexes-and-constraints.sh
```
Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/local-installation/separate-scripts/start-omop-indexes-and-constraints.cmd --output start-omop-indexes-and-constraints.cmd
```
3.	Run the script

Linux/MacOS
```
./start-omopcdm-indexes-and-constraints.sh
```
Windows
```
.\start-omop-indexes-and-constraints.cmd
```

### Update custom concepts
When new custom concepts are available, they can be easily loaded in the OMOP CDM database.
Installation steps:
1.	Open a terminal window (Command Prompt on Windows)
2.	Download the installation script

Linux/MacOS
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/local-installation/separate-scripts/start-custom-concepts-update.sh --output start-custom-concepts-update.sh && chmod +x start-custom-concepts-update.sh
```
Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/local-installation/separate-scripts/start-custom-concepts-update.cmd --output start-custom-concepts-update.cmd
```
3.	Run the script

Linux/MacOS
```
./start-custom-concepts-update.sh
```
Windows
```
.\start-custom-concepts-update.cmd
```

## QA database
QA database can be used as a test database. It's an exact replica of the full database installed with the script start-postgres.sh (on Linux or Mac) or start-postgres.cmd (on Windows). It is primarily used for testing scripts on data in the "omopcdm" db schema.
### QA database installation
Installation steps:
1.	Open a terminal window (Command Prompt on Windows)
2.	Download the installation script

Linux/MacOS
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/local-installation/separate-scripts/start-qa-database.sh --output start-qa-database.sh && chmod +x start-qa-database.sh
```
Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/local-installation/separate-scripts/start-qa-database.cmd --output start-qa-database.cmd
```
3.	Run the script

Linux/MacOS
```
./start-qa-database.sh
```
Windows
```
.\start-qa-database.cmd
```
### QA database removal
Removal steps:
1.	Open a terminal window (Command Prompt on Windows)
2.	Download the removal script

Linux/MacOS
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/local-installation/separate-scripts/remove-qa-database.sh --output remove-qa-database.sh && chmod +x remove-qa-database.sh
```
Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/local-installation/separate-scripts/remove-qa-database.cmd --output remove-qa-database.cmd
```
3.	Run the script

Linux/MacOS
```
./remove-qa-database.sh
```
Windows
```
.\remove-qa-database.cmd
```

## Backup and restore of the database

### Database backup
1. Download the backup script:

Linux/MacOS
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/local-installation/separate-scripts/backup-database.sh --output backup-database.sh && chmod +x backup-database.sh
```
Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/local-installation/separate-scripts/backup-database.cmd --output backup-database.cmd
```
2. Run the script

Linux/MacOS
```
./backup-database.sh
```
Windows
```
.\backup-database.cmd
```
The backup script will create a tar file name '<db_name>_<date_time>.tar.bz2' in the current directory. Creating the backup file can take a long time depending on the size of the database.
Copy the backup file to a save location for long term storage.

### Database restore
1. Download the restore script:

Linux/MacOS
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/local-installation/separate-scripts/restore-database.sh  --output restore-database.sh  && chmod +x restore-database.sh
```
Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/local-installation/separate-scripts/restore-database.cmd --output restore-database.cmd
```
2. Run the script and provide the name of the backup file as parameter. The backup file should be present in the folder where the script is executed.

Linux/MacOS
```
./restore-database.sh <db_name>_<date_time>.tar.bz2
```
Windows
```
.\restore-database.cmd <db_name>_<date_time>.tar.bz2
```

### Hot snapshot of the database volume
The database volume can be copied to a new volume (with a different name) to take a snapshot of the current database state.

1. Download the script

```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/local-installation/separate-scripts/clone-docker-volume.sh --output clone-docker-volume.sh && chmod +x clone-volume.sh
```

2. Run the script, provide the source volume as first parameter and the target volume as second parameter.
```
./clone-docker-volume.sh pgdata pgdata_snapshot1
```

## Vocabulary update
When a new vocabulary is available, it can be easily loaded in the OMOP CDM database.
Installation steps:
1.	Open a terminal window (Command Prompt on Windows)
2.	Download the installation script

Linux/MacOS
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/local-installation/separate-scripts/start-vocabulary-update.sh --output start-vocabulary-update.sh && chmod +x start-vocabulary-update.sh
```
Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/local-installation/separate-scripts/start-vocabulary-update.cmd --output start-vocabulary-update.cmd
```
3.	Run the script

Linux/MacOS
```
./start-vocabulary-update.sh
```
Windows
```
.\start-vocabulary-update.cmd
```