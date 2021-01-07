# Helper scripts

Table of Contents
=================
  * [Requirements](#requirements)
    * [Hardware](#hardware)
    * [Operating system](#operating-system)
    * [Docker](#docker)
    * [Docker images for HONEUR](#docker-images-for-honeur)
  * [Essentials](#essentials)
    * [Installation instructions](#essential-installation-instruction)
      * [HONEUR](#essential-honeur)
      * [PHederation](#essential-phederation)
  * [Full](#full)
    * [Installation instructions](#full-installation-instruction)
      * [HONEUR](#full-honeur)
      * [PHederation](#full-phederation)

Helper scripts combines the installation of HONEUR Components. You can choose to fully install all components or only install the essential components.

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

### Docker images for HONEUR
A Docker Hub account with read access on the HONEUR Docker image repository (https://hub.docker.com/u/honeur) is required.

Please create a Docker hub account or use an existing account and request access by sending a mail to Michel Van Speybroeck (mvspeybr@its.jnj.com)

## Essentials
following components will be installed:
  * Postgres database v9.6.18 running on port 5444
  * Atlas/WebAPI v2.7.1 running on Apache Tomcat 9.0.20
  * Zeppelin running Jetty v9.4.14
  * User Management running on Apache Tomcat 9.0.33 (Only secure installation)
  * Proxy

### <a id="essential-installation-instruction"></a>Installation instructions
Essential remote installation can be installed by running the installation helper script. :warning: Please run the correct installation script for your disease area (e.g. [HONEUR](#essential-honeur) or [PHederation](#essential-phederation)).

#### <a id="essential-honeur"></a>HONEUR
1. download the installation helper script **_start-honeur.sh_** for MacOS/Linux or **_start-honeur.cmd_** for Windows. You can download this script using the following command:

MacOS/Linux
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/remote-installation/helper-scripts/start-honeur.sh --output start-honeur.sh && chmod +x start-honeur.sh
```

Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/remote-installation/helper-scripts/start-honeur.cmd --output start-honeur.cmd
```

2. You can run this script using the following command:

MacOS/Linux
```
./start-honeur.sh
```

Windows
```
.\start-honeur.cmd
```

3. The script will prompt you to enter the security options for Atlas/WebAPI. If you have existing HONEUR Components like Postgres/Zeppelin or HONEUR studio. Please use the same security settings as with these previous installation.
4. (OPTIONAL) when **_ldap_** is chosen for the installation security, additional connections details will be asked to connect to the existing LDAP Server.
5. The script will prompt you to enter a Fully Qualified Domain Name (FQDN) or IP Address of the host machine. Atlas/WebAPI will only be accessible on the host machine (via localhost) if you accept the default ‘localhost’ value.
6. The script will prompt you to enter a Directory on the host machine to save the Zeppelin logs, notebooks and prepared distributed analytics data. Please provide an absolute path.

Once done, the script will download all essential docker images and will create the docker containers.

#### <a id="essential-phederation"></a>PHederation
1. download the installation helper script **_start-phederation.sh_** for MacOS/Linux or **_start-phederation.cmd_** for Windows. You can download this script using the following command:

MacOS/Linux
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/remote-installation/helper-scripts/start-phederation.sh --output start-phederation.sh && chmod +x start-phederation.sh
```

Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/remote-installation/helper-scripts/start-phederation.cmd --output start-phederation.cmd
```

2. You can run this script using the following command:

MacOS/Linux
```
./start-honeur.sh
```

Windows
```
.\start-honeur.cmd
```

3. The script will prompt you to enter the security options for Atlas/WebAPI. If you have existing HONEUR Components like Postgres/Zeppelin or HONEUR studio. Please use the same security settings as with these previous installation.
4. (OPTIONAL) when **_ldap_** is chosen for the installation security, additional connections details will be asked to connect to the existing LDAP Server.
5. The script will prompt you to enter a Fully Qualified Domain Name (FQDN) or IP Address of the host machine. Atlas/WebAPI will only be accessible on the host machine (via localhost) if you accept the default ‘localhost’ value.
6. The script will prompt you to enter a Directory on the host machine to save the Zeppelin logs, notebooks and prepared distributed analytics data. Please provide an absolute path.

Once done, the script will download all essential docker images and will create the docker containers.

## Full
following components will be installed:
  * Postgres database v9.6.18 running on port 5444
  * Atlas/WebAPI v2.7.1 running on Apache Tomcat 9.0.20
  * Zeppelin running Jetty v9.4.14
  * Distributed analytics
  * HONEUR Studio
  * User Management running on Apache Tomcat 9.0.33 (Only secure installation)
  * Proxy

### <a id="full-installation-instruction"></a>Installation instructions
Full remote installation can be installed by running the installation helper script. :warning: Please install the correct installation script for your disease area (e.g. [HONEUR](#full-honeur) or [PHederation](#full-phederation)).

#### <a id="full-honeur"></a>HONEUR
1. download the installation helper script **_start-phederation-full.sh_** for MacOS/Linux or **_start-phederation-full.cmd_** for Windows. You can download this script using the following command:

MacOS/Linux
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/remote-installation/helper-scripts/start-honeur-full.sh --output start-honeur.sh && chmod +x start-honeur.sh
```

Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/remote-installation/helper-scripts/start-honeur-full.cmd --output start-honeur.cmd
```

2. You can run this script using the following command:

MacOS/Linux
```
./start-honeur.sh
```

Windows
```
.\start-honeur.cmd
```

3. The script will prompt you to enter the security options for Atlas/WebAPI. If you have existing HONEUR Components like Postgres/Zeppelin or HONEUR studio. Please use the same security settings as with these previous installation.
4. (OPTIONAL) when **_ldap_** is chosen for the installation security, additional connections details will be asked to connect to the existing LDAP Server.
5. The script will prompt you to enter a Fully Qualified Domain Name (FQDN) or IP Address of the host machine. Atlas/WebAPI will only be accessible on the host machine (via localhost) if you accept the default ‘localhost’ value.
6. The script will prompt you to enter a Directory on the host machine to save the Zeppelin logs, notebooks and prepared distributed analytics data. Please provide an absolute path.
7. The script will prompt you to enter the name of your organization. :warning: The name of the organization is given by the HONEUR Team.
8. The script will prompt you to enter the directory of where the HONEUR Studio will store its working directory files.

Once done, the script will download all docker images and will create the docker containers.

#### <a id="full-phederation"></a>PHederation
1. download the installation helper script **_start-phederation-full.sh_** for MacOS/Linux or **_start-phederation-full.cmd_** for Windows. You can download this script using the following command:

MacOS/Linux
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/remote-installation/helper-scripts/start-phederation-full.sh --output start-phederation.sh && chmod +x start-phederation.sh
```

Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/remote-installation/helper-scripts/start-phederation-full.cmd --output start-phederation.cmd
```

2. You can run this script using the following command:

MacOS/Linux
```
./start-phederation.sh
```

Windows
```
.\start-phederation.cmd
```

3. The script will prompt you to enter the security options for Atlas/WebAPI. If you have existing HONEUR Components like Postgres/Zeppelin or HONEUR studio. Please use the same security settings as with these previous installation.
4. (OPTIONAL) when **_ldap_** is chosen for the installation security, additional connections details will be asked to connect to the existing LDAP Server.
5. The script will prompt you to enter a Fully Qualified Domain Name (FQDN) or IP Address of the host machine. Atlas/WebAPI will only be accessible on the host machine (via localhost) if you accept the default ‘localhost’ value.
6. The script will prompt you to enter a Directory on the host machine to save the Zeppelin logs, notebooks and prepared distributed analytics data. Please provide an absolute path.
7. The script will prompt you to enter the name of your organization. :warning: The name of the organization is given by the HONEUR Team.
8. The script will prompt you to enter the directory of where the HONEUR Studio will store its working directory files.

Once done, the script will download all docker images and will create the docker containers.