# Offline helper scripts

Table of Contents
=================
  * [Requirements](#requirements)
    * [Offline install package](#offline-install-package)
    * [Hardware](#hardware)
    * [Operating system](#operating-system)
    * [Docker](#docker)
    * [Docker images](#docker-images)
    * [Installation instructions](#installation-instruction)

Offline helper scripts combines the installation of Feder8 components and provides all the necessary components in a download package. You can choose to fully install all components or only install the essential components.

## Requirements

### Offline install package
1. Please download the offline install package from a machine with internet access:
   * https://download-uat.honeur.org/honeur/feder8-local-install-2.0.19.tar.gz
    > You will need to login with your central account credentials.

2. Copy the install package to the installation system
3. Unpack archive
   * Windows: Use [7Zip](https://www.7-zip.org/) to extract the `.tar.gz` file and then unpack the `.tar` file
   * Linux: `tar -xvf feder8-local-install-2.0.19.tar.gz`
   * MacOS: Finder can unpack the `.tar.gz` file by double-clicking it.

4. The unpacked archive should contain the following files:
    * `start-feder8-offline.cmd`
    * `start-feder8-offline.sh`
    * `images.tar`

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
The docker images required to run the full setup are located on a central repository. Make sure you have an account on our central platform before trying to run the local setup installation scripts:

  * For HONEUR: https://portal-uat.honeur.org
  * For PHederation: https://portal-uat.phederation.org
  * For ESFURN: https://portal-uat.esfurn.org
  * For ATHENA: https://portal-uat.athenafederation.org
  * For LupusNet: https://portal-uat.lupusnet.org

Please request access by sending a mail to Michel Van Speybroeck (mvspeybr@its.jnj.com)
    
### Prerequisite for installations on Linux
On Linux, please download and run the following 2 scripts before running the installation script:

Download the "Docker certificates generation script":
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/release/1.10.1/local-installation/separate-scripts/generate-docker-certificates.sh --output generate-docker-certificates.sh && chmod +x generate-docker-certificates.sh
```

Run the "Docker certificates generation script":
```
./generate-docker-certificates.sh
```

Download the "enable Docker TLS security script":
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/release/1.10.1/local-installation/separate-scripts/enable-docker-tls-security.sh --output enable-docker-tls-security.sh && chmod +x enable-docker-tls-security.sh
```

Run the "enable Docker TLS security script":
```
./enable-docker-tls-security.sh
```

### Prerequisite for HTTPS support during installation
During the installation, the script will ask you if you want to enable HTTPS support for the local toolbox. To enable HTTPS during the installation process, you should provide the certificate and private key beforehand. The files should be placed in a folder on the host machine where the installation will run and the files should be named the following:
* Public certificate (file starting with -----BEGIN CERTIFICATE-----): feder8.crt
* Private Key (file starting with -----BEGIN PRIVATE KEY-----): feder8.key

## <a id="installation-instruction"></a>Installation instructions
The following components will be installed:
* Postgres v13 database with OMOP CDM pre-loaded (port 5444 can optionally be exposed on the host machine during the installation)
* Configuration server
* Local Portal
* Atlas/WebAPI v2.9 running on Apache Tomcat 9.0.20
* Zeppelin v0.8.2
* FEDER8 Studio (including R Studio server, Shiny server and Visual Studio Code)(Only when confirmed for installation)
* Distributed analytics (Only when confirmed for installation)
* User Management (only in case authentication is enabled)
* Proxy server (NGINX)

The local installation can be installed by downloading and running the installation helper script.

1. Navigate to the unpacked archive which contains the  offline installation helper script **_start-feder8-offline.sh_** for MacOS/Linux or **_start-feder8-offline.cmd_** for Windows


2. Run the script using the following command:

MacOS/Linux
```
chmod +x start-feder8-offline.sh && ./start-feder8-offline.sh
```

Windows
```
.\start-feder8-offline.cmd
```
1. The script will ask for the applicable therapeutic area. Please choose the therapeutic area that corresponds with the credentials you received:
    1. HONEUR for https://portal-uat.honeur.org
    2. PHederation for https://portal-uat.phederation.org
    3. ESFURN for https://portal-uat.esfurn.org
    4. ATHENA for https://portal-uat.athenafederation.org
    5. LupusNet for https://portal-uat.lupusnet.org
2. If a previous installation is present, the script will ask to remove the previous installation.  Choose Yes if the ETL will be re-executed after the re-installation.
3. If a previous installation is present, the script will ask to create a backup of the Postgres database.  Choose Yes if there is no recent backup of the database.
4. The script will prompt to enter a new password for feder8 database user.
5. The script will prompt to enter a new password for feder8 admin database user.
6.  The script will prompt to enter a Fully Qualified Domain Name (FQDN) or IP Address of the host machine. Atlas/WebAPI will only be accessible on the host machine if localhost is entered as hostname.
7.  The script will prompt to enable authentication.  If authentication is enabled (recommended), a username and password will be required to logon into Atlas, Zeppelin, ...  If a LDAP server is available, it is possible to link the local installation to the LDAP server.  It allows users to use the same username and password they use for other local applications. If a LDAP server is not available or cannot be used, it is possible to create local users in the database that is part of the local installation. A User Management application will be installed to manage these local users.  Choose JDBC to enable this authentication type.
    If the host machine is only accessible to authorized users, "None" can be selected to disable authentication.
8.  (OPTIONAL when **_ldap_** is chosen for the installation security) Additional connections details will be asked to connect to the existing LDAP Server.
9.  The script will prompt to enter a directory on the host machine to save the Zeppelin logs and notebooks. Please provide an absolute path.
10. The script will prompt to ask whether Feder8 Studio should be installed. Feder8 studio provides R Studio server and Visual Studio Code server to allow users to run R and Python code from within a browser.  It's recommended to install Feder8 studio because it allows better integration with the other components. When confirmed to install, the script will prompt to enter a directory on the host machine to save the data for Feder8 Studio. Please provide an absolute path.
11. The script will prompt to ask whether distributed analytics should be installed. Distributed analytics is required to participate in studies that depend on iterative algorithms on virtually pooled (multi site) data sets.  These components will not be able to run anything without explicit approval for each study where this kind of analysis is used.  It's recommended to install these components. When confirmed to install, the script will prompt to select the name of your organization.
12. The script will prompt to enter a username and password for an administrator account.  The admin account is required to modify the local configuration in the local portal and to create local users in the User Management app.
13. The script will prompt to ask whether you want to enable support for Docker based analysis scripts.  By enabling this capability, local analysis scripts can be executed as Docker containers.  It makes it much easier to run local analyses.  This feature is also used by the distributed analytics components.  It's recommended to enable this Docker capability.
14. The script will prompt to ask whether the Postgres database should be made accessible via the host machine on port 5444 or not. Choose No if there is no need to make the database accessible on the local network.
15. The script will prompt to ask wheter you want to enable HTTPS support. :warning: Before you can enable HTTPS support, you should have a folder containing a public key certificate file named "feder8.crt" and a private key file named "feder8.key".
16. The script will prompt to enter a directory on the host machine where the public key certificate file named "feder8.crt" and a private key file named "feder8.key" are located.

Once done, the script will download all docker images and will create the docker volumes and containers.