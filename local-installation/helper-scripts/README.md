# Helper scripts

Table of Contents
=================
  * [Requirements](#requirements)
    * [Hardware](#hardware)
    * [Operating system](#operating-system)
    * [Docker](#docker)
    * [Docker images](#docker-images)
    * [Installation instructions](#installation-instruction)

Helper scripts combines the installation of Feder8 components. You can choose to fully install all components or only install the essential components.

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
The docker images required to run the full setup are located on a central repository. Make sure you have an account on our central platform before trying to run the local setup installation scripts:

  * For HONEUR: https://portal.honeur.org
  * For PHederation: https://portal.phederation.org
  * For Esfurn: https://portal.esfurn.org

Please request access by sending a mail to Michel Van Speybroeck (mvspeybr@its.jnj.com)

### Important!
The Feder8 local installation should only be accessible on the local network.  All inbound traffic from the public internet should be blocked.
Only the Feder8 central services should be accessible from within the local installation:

* For HONEUR: 
  * https://cas.honeur.org
  * https://harbor.honeur.org
  * https://catalogue.honeur.org
  * https://distributed-analytics.honeur.org
* For PHederation: 
  * https://cas.phederation.org
  * https://harbor.phederation.org
  * https://catalogue.phederation.org
  * https://distributed-analytics.phederation.org
* For Esfurn: 
  * https://cas.esfurn.org
  * https://harbor.esfurn.org
  * https://catalogue.esfurn.org
  * https://distributed-analytics.esfurn.org

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

The full local installation can be installed by downloading and running the installation helper script.

1. Download the installation helper script **_start-feder8.sh_** for MacOS/Linux or **_start-feder8.cmd_** for Windows using the following command:

MacOS/Linux
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/local-installation/helper-scripts/start-feder8.sh --output start-feder8.sh && chmod +x start-feder8.sh
```

Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/local-installation/helper-scripts/start-feder8.cmd --output start-feder8.cmd
```

2. Run the script using the following command:

MacOS/Linux
```
./start-feder8.sh
```

Windows
```
.\start-feder8.cmd
```
3. The script will ask for the applicable therapeutic area. Please choose the therapeutic area that corresponds with the credentials you received:
    1. HONEUR for https://portal.honeur.org
    2. PHederation for https://portal.phederation.org
    3. ESFURN for https://portal.esfurn.org
4. If a previous installation is present, the script will ask to remove the previous installation.  Choose Yes if the ETL will be re-executed after the re-installation.
5. If a previous installation is present, the script will ask to create a backup of the Postgres database.  Choose Yes if there is no recent backup of the database.
6. The script will prompt to enter the email address of the account you use to login on the central platform.
7. The script will prompt to enter your CLI secret for pulling our Docker images. This secret can be found on our central image repository. Surf to the central registry (https://harbor.honeur.org for HONEUR, https://harbor.phederation.org for PHederation, https://harbor.esfurn.org for Esfurn) and login using the button \"LOGIN VIA OIDC PROVIDER\". Then click your account name in the top right corner of the screen and click \"User Profile\". Copy the CLI secret by clicking the copy symbol next to the text field.
8. The script will prompt to enter a new password for feder8 database user.
9. The script will prompt to enter a new password for feder8 admin database user.
10. The script will prompt to enter a Fully Qualified Domain Name (FQDN) or IP Address of the host machine. Atlas/WebAPI will only be accessible on the host machine if localhost is entered as hostname.
11. The script will prompt to enable authentication.  Choose "None" if authentication is not required.  
12. (OPTIONAL when **_ldap_** is chosen for the installation security) Additional connections details will be asked to connect to the existing LDAP Server.
13. The script will prompt to enter a directory on the host machine to save the Zeppelin logs and notebooks. Please provide an absolute path.
14. The script will prompt to ask whether Feder8 Studio should be installed. When confirmed to install, the script will prompt to enter a directory on the host machine to save the data for Feder8 Studio. Please provide an absolute path.
15. The script will prompt to ask whether distributed analytics should be installed. When confirmed to install, the script will prompt to select the name of your organization.  It's recommended to enable this functionality to collaborate on research questions.
16. The script will prompt to enter a username and password for an administrator account.  The admin account is required to modify the local configuration in the local portal.
17. The script will prompt to ask whether you want to enable support for Docker based analysis scripts.  It's recommended to enable this functionality to collaborate on research questions.
18. The script will prompt to ask whether the Postgres database should be made accessible via the host machine on port 5444 or not. Choose No if there is no need to make the database accessible on the local network.

Once done, the script will download all docker images and will create the docker volumes and containers.
