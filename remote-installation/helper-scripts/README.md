# Helper scripts

Table of Contents
=================
  * [Requirements](#requirements)
    * [Hardware](#hardware)
    * [Operating system](#operating-system)
    * [Docker](#docker)
    * [Docker images](#docker-images)
  * [Essentials](#essentials)
    * [Installation instructions](#essential-installation-instruction)
  * [Full](#full)
    * [Installation instructions](#full-installation-instruction)

Helper scripts combines the installation of Feder8 Components. You can choose to fully install all components or only install the essential components.

## Requirements

### Hardware
Modern 64 bit AMD dual core processor (or better)
8 GB RAM, 16 GB RAM recommended
100 GB free disk space (or more)

### Operating system
Windows 10, MacOS or Linux (Ubuntu, CentOS, Debian, …)

### Docker
Windows: https://docs.docker.com/docker-for-windows/install/
MacOS: https://docs.docker.com/docker-for-mac/install/
Linux: https://docs.docker.com/install/linux/docker-ce/ubuntu/
Assign 2 or more CPU’s, 8 GB of RAM and 100 GB of disk space to Docker in Docker Desktop.
On Linux Docker compose (v1.24 or higher) should be installed separately.

### Docker images
The docker images required to run the full setup are located on a central repository. Make sure you have an account on our central platform before trying to run the local setup installation scripts:

  * For HONEUR: https://portal-uat.honeur.org
  * For PHederation: https://portal-uat.phederation.org
  * For Esfurn: https://portal-uat.esfurn.org
  * For Athena: https://portal-uat.athenafederation.org

Please request access by sending a mail to Michel Van Speybroeck (mvspeybr@its.jnj.com)

## Essentials
following components will be installed:
  * Configuration Server running on Apache Tomcat 9.0.33
  * Postgres database v9.6.18 running on port 5444
  * Portal running on Apache Tomcat 9.0.33
  * Atlas/WebAPI v2.7.1 running on Apache Tomcat 9.0.20
  * Zeppelin running Jetty v9.4.14
  * User Management running on Apache Tomcat 9.0.33 (Only secure installation)
  * Proxy

### <a id="essential-installation-instruction"></a>Installation instructions
Essential remote installation can be installed by running the installation helper script.

1. download the installation helper script **_start-feder8.sh_** for MacOS/Linux or **_start-feder8.cmd_** for Windows. You can download this script using the following command:

MacOS/Linux
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/release/1.9/remote-installation/helper-scripts/start-feder8.sh --output start-feder8.sh && chmod +x start-feder8.sh
```

Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/release/1.9/remote-installation/helper-scripts/start-feder8.cmd --output start-feder8.cmd
```

2. You can run this script using the following command:

MacOS/Linux
```
./start-feder8.sh
```

Windows
```
.\start-feder8.cmd
```
3. The script will ask you for which therapeutic area you will install the installation. Please choose the therapeutic area where you received your credentials for:
   1. HONEUR for https://portal-uat.honeur.org
   2. PHederation for https://portal-uat.phederation.org
   3. Esfurn for https://portal-uat.esfurn.org
   4. Athena for https://portal-uat.athenafederation.org
4. The script will promt you to enter your email address that you use as your login on our central platform.
5. The script will prompt you to enter your CLI secret for pulling our images. This secret can be found on our central image repository. Surf to the central registry (https://harbor-uat.honeur.org for HONEUR, https://harbor-uat.phederation.org for PHederation, https://harbor-uat.esfurn.org for Esfurn, https://harbor-uat.athenafederation.org for Athena) and login using the button \"LOGIN VIA OIDC PROVIDER\". Then click your account name on the top right corner of the screen and click \"User Profile\". Copy the CLI secret by clicking the copy symbol next to the text field.
6. The script will prompt you to enter the security options for Atlas/WebAPI. If you have existing Feder8 Components like Postgres/Zeppelin or Feder8 studio. Please use the same security settings as with these previous installation.
7. (OPTIONAL when **_ldap_** is chosen for the installation security) Additional connections details will be asked to connect to the existing LDAP Server.
8. The script will prompt you to enter a Fully Qualified Domain Name (FQDN) or IP Address of the host machine. Atlas/WebAPI will only be accessible on the host machine (via localhost) if you accept the default ‘localhost’ value.
9. The script will prompt you to enter a Directory on the host machine to save the Zeppelin logs, notebooks and prepared distributed analytics data. Please provide an absolute path.
10. The script will prompt you to enter a new password for feder8 database user.
11. The script will prompt you to enter a new password for feder8 admin database user.

Once done, the script will download all essential docker images and will create the docker containers.

## Full
following components will be installed:
  * Configuration Server running on Apache Tomcat 9.0.33
  * Postgres database v9.6.18 running on port 5444
  * Portal running on Apache Tomcat 9.0.33
  * Atlas/WebAPI v2.7.1 running on Apache Tomcat 9.0.20
  * Zeppelin running Jetty v9.4.14
  * Distributed analytics
  * FEDER8 Studio
  * User Management running on Apache Tomcat 9.0.33 (Only secure installation)
  * Proxy

### <a id="full-installation-instruction"></a>Installation instructions
Full remote installation can be installed by running the installation helper script.

1. download the installation helper script **_start-feder8-full.sh_** for MacOS/Linux or **_start-feder8-full.cmd_** for Windows. You can download this script using the following command:

MacOS/Linux
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/release/1.9/remote-installation/helper-scripts/start-feder8-full.sh --output start-feder8.sh && chmod +x start-feder8.sh
```

Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/release/1.9/remote-installation/helper-scripts/start-feder8-full.cmd --output start-feder8.cmd
```

2. You can run this script using the following command:

MacOS/Linux
```
./start-feder8.sh
```

Windows
```
.\start-feder8.cmd
```
3. The script will ask you for which therapeutic area you will install the installation. Please choose the therapeutic area where you received your credentials for:
   1. HONEUR for https://portal-uat.honeur.org
   2. PHederation for https://portal-uat.phederation.org
   3. Esfurn for https://portal-uat.esfurn.org
   4. Athena for https://portal-uat.athenafederation.org
4. The script will promt you to enter your email address that you use as your login on our central platform.
5. The script will prompt you to enter your CLI secret for pulling our images. This secret can be found on our central image repository. Surf to the central registry (https://harbor-uat.honeur.org for HONEUR, https://harbor-uat.phederation.org for PHederation, https://harbor-uat.esfurn.org for Esfurn, https://harbor-uat.athenafederation.org for Athena) and login using the button \"LOGIN VIA OIDC PROVIDER\". Then click your account name on the top right corner of the screen and click \"User Profile\". Copy the CLI secret by clicking the copy symbol next to the text field.
6. The script will prompt you to enter the security options for Atlas/WebAPI. If you have existing Feder8 Components like Postgres/Zeppelin or Feder8 studio. Please use the same security settings as with these previous installation.
7. (OPTIONAL when **_ldap_** is chosen for the installation security) Additional connections details will be asked to connect to the existing LDAP Server.
8. The script will prompt you to enter a Fully Qualified Domain Name (FQDN) or IP Address of the host machine. Atlas/WebAPI will only be accessible on the host machine (via localhost) if you accept the default ‘localhost’ value.
9. The script will prompt you to enter a Directory on the host machine to save the Zeppelin logs, notebooks and prepared distributed analytics data. Please provide an absolute path.
10. The script will prompt you to enter the name of your organization. :warning: The name of the organization is given by the Feder8 Team.
11. The script will prompt you to enter the directory of where the Feder8 Studio will store its working directory files.
12. The script will prompt you to enter a new password for feder8 database user.
13. The script will prompt you to enter a new password for feder8 admin database user.

Once done, the script will download all docker images and will create the docker containers.
