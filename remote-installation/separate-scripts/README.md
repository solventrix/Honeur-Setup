# Separate scripts

Table of Contents
=================
  * [Requirements](#requirements)
    * [Hardware](#hardware)
    * [Operating system](#operating-system)
    * [Docker](#docker)
    * [Docker images for HONEUR](#docker-images-for-honeur)
  * [Important Note](#important-note)
  * [Postgres installation instructions](#postgres-installation-instructions)
  * [Atlas/WebAPI installation instructions](#atlas-webapi-separate)
  * [Zeppelin installation instructions](#zeppelin-installation-instructions)
  * [User Management installation instructions](#user-management-installation-instructions)
  * [Distributed Analytics installation instructions](#distributed-analytics-installation-instructions)
  * [FEDER8 Studio installation instructions](#feder8-studio-installation-instructions)
  * [HONEUR Proxy](#proxy)

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

## Important Note
Components like [Atlas/WebAPI](#atlas/webapi-installation-instructions), [Zeppelin](#zeppelin-installation-instructions), [User Management](#user-management-installation-instructions) and [FEDER8 Studio](#feder8-studio-installation-instructions) are only accessible through a web browser when installing the [Proxy](#proxy). Please run the installation script of the [Proxy](#proxy) after installing or updating one of the previous mentioned components.

## Postgres installation instructions
Postgres database can be installed by running the installation script..

1. download the installation script **_start-postgres.sh_** for MacOS/Linux or **_start-postgres.cmd_** for Windows. You can download this script using the following command:

MacOS/Linux
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/remote-installation/separate-scripts/start-postgres.sh --output start-postgres.sh && chmod +x start-postgres.sh
```

Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/remote-installation/separate-scripts/start-postgres.cmd --output start-postgres.cmd
```

2. You can run this script using the following command:

MacOS/Linux
```
./start-postgres.sh
```

Windows
```
.\start-postgres.cmd
```

3. The script will prompt you to enter the therapeutic area.
4. The script will promt you to enter your email address that you use as your login on our central platform for the chosen therapeutic area.
5. The script will prompt you to enter your CLI secret for pulling our images. This secret can be found on our central image repository. Surf to:
    * https://harbor-uat.honeur.org for HONEUR
    * https://harbor-uat.phederation.org for PHederation
    * https://harbor-uat.esfurn.org for Esfurn
    * https://harbor-uat.athenafederation.org for Athena
6. login using the button "LOGIN VIA OIDC PROVIDER". Then click your account name on the top right corner of the screen and click "User Profile". Copy the CLI secret by clicking the copy symbol next to the text field.
7. The script will prompt you to enter a new password for standard database user.
8. The script will prompt you to enter a new password for admin database user.

Once done, the script will download the Postgres docker image and will create the docker container.

## <a id="atlas-webapi-separate"></a>Atlas/WebAPI installation instructions
The Postgres database installed in the previous step is required for Atlas/WebAPI to function.

Atlas/WebAPI can be installed by running the installation script.

1. download the installation script **_start-atlas-webapi.sh_** for MacOS/Linux or **_start-atlas-webapi.cmd_** for Windows. You can download this script using the following command:

MacOS/Linux
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/remote-installation/separate-scripts/start-atlas-webapi.sh --output start-atlas-webapi.sh && chmod +x start-atlas-webapi.sh
```

Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/remote-installation/separate-scripts/start-atlas-webapi.cmd --output start-atlas-webapi.cmd
```

2. You can run this script using the following command:

MacOS/Linux
```
./start-atlas-webapi.sh
```

Windows
```
.\start-atlas-webapi.cmd
```

3. The script will prompt you to enter the therapeutic area.
4. The script will promt you to enter your email address that you use as your login on our central platform for the chosen therapeutic area.
5. The script will prompt you to enter your CLI secret for pulling our images. This secret can be found on our central image repository. Surf to:
    * https://harbor-uat.honeur.org for HONEUR
    * https://harbor-uat.phederation.org for PHederation
    * https://harbor-uat.esfurn.org for Esfurn
    * https://harbor-uat.athenafederation.org for Athena
6. login using the button "LOGIN VIA OIDC PROVIDER". Then click your account name on the top right corner of the screen and click "User Profile". Copy the CLI secret by clicking the copy symbol next to the text field.
7. The script will prompt you to enter a Fully Qualified Domain Name (FQDN) or IP Address of the host machine. Atlas/WebAPI will only be accessible on the host machine (via localhost) if you accept the default ‘localhost’ value.
8. The script will prompt you to enter the security options for Atlas/WebAPI. If you have existing HONEUR Components like Postgres/Zeppelin or FEDER8 Studio. Please use the same security settings as with these previous installation.
9. (OPTIONAL when **_ldap_** is chosen for the installation security) Additional connections details will be asked to connect to the existing LDAP Server.

Once done, the script will download the Atlas/WebAPI docker image and will create the docker container.

:warning: Please run the installation script of the [Proxy](#proxy) after installing or updating Atlas/WebAPI. The proxy is necessary for accessing Atlas/WebAPI through the browser.

## Zeppelin installation instructions
Zeppelin can be installed by running the installation script.

1. download the installation script **_start-zeppelin.sh_** for MacOS/Linux or **_start-zeppelin.cmd_** for Windows. You can download this script using the following command:

MacOS/Linux
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/remote-installation/separate-scripts/start-zeppelin.sh --output start-zeppelin.sh && chmod +x start-zeppelin.sh
```

Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/remote-installation/separate-scripts/start-zeppelin.cmd --output start-zeppelin.cmd
```

2. You can run this script using the following command:

MacOS/Linux
```
./start-zeppelin.sh
```

Windows
```
.\start-zeppelin.cmd
```

3. The script will prompt you to enter the therapeutic area.
4. The script will promt you to enter your email address that you use as your login on our central platform for the chosen therapeutic area.
5. The script will prompt you to enter your CLI secret for pulling our images. This secret can be found on our central image repository. Surf to:
    * https://harbor-uat.honeur.org for HONEUR
    * https://harbor-uat.phederation.org for PHederation
    * https://harbor-uat.esfurn.org for Esfurn
    * https://harbor-uat.athenafederation.org for Athena
6. login using the button "LOGIN VIA OIDC PROVIDER". Then click your account name on the top right corner of the screen and click "User Profile". Copy the CLI secret by clicking the copy symbol next to the text field.
7. The script will prompt you to enter a Directory on the host machine to save the Zeppelin logs, notebooks and prepared distributed analytics data. Please provide an absolute path.
8. The script will prompt you to enter the security options for Zeppelin. If you have existing HONEUR Components like Postgres/Atlas/WebAPI or FEDER8 Studio. Please use the same security settings as with these previous installation.
9. (OPTIONAL when **_ldap_** is chosen for the installation security) Additional connections details will be asked to connect to the existing LDAP Server.

Once done, the script will download the Zeppelin docker image and will create the docker container.

:warning: Please run the installation script of the [Proxy](#proxy) after installing or updating Zeppelin. The proxy is necessary for accessing Zeppelin through the browser.

## User Management installation instructions
:warning: User Management should only be installed when other components are installed with the **_secure_** version. When other components are installed with the standard version, you can skip this installation.

User Management can be installed by running the installation script.

1. download the installation script **_start-user-management.sh_** for MacOS/Linux or **_start-user-management.cmd_** for Windows. You can download this script using the following command:

MacOS/Linux
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/remote-installation/separate-scripts/start-user-management.sh --output start-user-management.sh && chmod +x start-user-management.sh
```

Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/remote-installation/separate-scripts/start-user-management.cmd --output start-user-management.cmd
```

2. You can run this script using the following command:

MacOS/Linux
```
./start-user-management.sh
```

Windows
```
.\start-user-management.cmd
```

3. The script will prompt you to enter the therapeutic area.
4. The script will promt you to enter your email address that you use as your login on our central platform for the chosen therapeutic area.
5. The script will prompt you to enter your CLI secret for pulling our images. This secret can be found on our central image repository. Surf to:
    * https://harbor-uat.honeur.org for HONEUR
    * https://harbor-uat.phederation.org for PHederation
    * https://harbor-uat.esfurn.org for Esfurn
    * https://harbor-uat.athenafederation.org for Athena
6. login using the button "LOGIN VIA OIDC PROVIDER". Then click your account name on the top right corner of the screen and click "User Profile". Copy the CLI secret by clicking the copy symbol next to the text field.
7. The script will prompt you to enter credentials for the administrator user that can manage users and roles.

Once done, the script will download the User Management docker image and will create the docker container.

:warning: Please run the installation script of the [Proxy](#proxy) after installing or updating User Management. The proxy is necessary for accessing User Management through the browser.

## Distributed Analytics installation instructions
:warning: Distributed Analytics requires you to install the [Zeppelin](#zeppelin-installation-instructions) component.

Distributed Analytics can be installed by running the installation script.

1. download the installation script **_start-distributed-analytics.sh_** for MacOS/Linux or **_start-distributed-analytics.cmd_** for Windows. You can download this script using the following command:

MacOS/Linux
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/remote-installation/separate-scripts/start-distributed-analytics.sh --output start-distributed-analytics.sh && chmod +x start-distributed-analytics.sh
```

Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/remote-installation/separate-scripts/distributed-analytics.cmd --output start-distributed-analytics.cmd
```

2. You can run this script using the following command:

MacOS/Linux
```
./start-distributed-analytics.sh
```

Windows
```
.\start-distributed-analytics.cmd
```

3. The script will prompt you to enter the therapeutic area.
4. The script will promt you to enter your email address that you use as your login on our central platform for the chosen therapeutic area.
5. The script will prompt you to enter your CLI secret for pulling our images. This secret can be found on our central image repository. Surf to:
    * https://harbor-uat.honeur.org for HONEUR
    * https://harbor-uat.phederation.org for PHederation
    * https://harbor-uat.esfurn.org for Esfurn
    * https://harbor-uat.athenafederation.org for Athena
6. login using the button "LOGIN VIA OIDC PROVIDER". Then click your account name on the top right corner of the screen and click "User Profile". Copy the CLI secret by clicking the copy symbol next to the text field.
7. The script will prompt you to enter the directory where zeppelin will save its prepared distributed analytics data. Use the same directory as with the installation of Zeppelin.
8. The script will prompt you to enter the name of your organization. :warning: The name of the organization is given by the HONEUR Team.

Once done, the script will download the Distributed Analytics docker images and will create the docker containers.

## FEDER8 Studio installation instructions
FEDER8 Studio can be downloaded right next to an existing installation. Please follow the installation steps:

1. download the installation script **_start-feder8-studio.sh_** for MacOS/Linux or **_start-feder8-studio.cmd_** for Windows. You can download this script using the following command:

MacOS/Linux
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/remote-installation/separate-scripts/start-feder8-studio.sh --output start-feder8-studio.sh && chmod +x start-feder8-studio.sh
```

Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/remote-installation/separate-scripts/start-feder8-studio.cmd --output start-feder8-studio.cmd
```

2. You can run this script using the following command:

MacOS/Linux
```
./start-feder8-studio.sh
```

Windows
```
.\start-feder8-studio.cmd
```

3. The script will prompt you to enter the therapeutic area.
4. The script will promt you to enter your email address that you use as your login on our central platform for the chosen therapeutic area.
5. The script will prompt you to enter your CLI secret for pulling our images. This secret can be found on our central image repository. Surf to:
    * https://harbor-uat.honeur.org for HONEUR
    * https://harbor-uat.phederation.org for PHederation
    * https://harbor-uat.esfurn.org for Esfurn
    * https://harbor-uat.athenafederation.org for Athena
6. login using the button "LOGIN VIA OIDC PROVIDER". Then click your account name on the top right corner of the screen and click "User Profile". Copy the CLI secret by clicking the copy symbol next to the text field.
7. The script will prompt you to enter a Fully Qualified Domain Name (FQDN) or IP Address of the host machine. FEDER8 Studio will only be accessible on the host machine (via localhost) if you accept the default ‘localhost’ value.
8. The script will prompt you to enter the directory of where the FEDER8 Studio will store its working directory files.
9. The script will prompt you to enter the security options for FEDER8 Studio. If you have existing HONEUR Components like postgres/webapi and zeppelin. Please use the same security settings as with this previous installation.
10. (OPTIONAL when **_ldap_** is chosen for the installation security) Additional connections details will be asked to connect to the existing LDAP Server

Once done, the script will download the FEDER8 Studio docker image and will create the docker container.

:warning: Please run the installation script of the [Proxy](#proxy) after installing or updating FEDER8 Studio. The proxy is necessary for accessing FEDER8 Studio through the browser.

## Proxy
Proxy can be downloaded right next to an existing installation. Please follow the installation steps:

1. download the installation script start-nginx.sh. You can download this script using the following command:

MacOS/Linux
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/remote-installation/separate-scripts/start-nginx.sh --output start-nginx.sh && chmod +x start-nginx.sh
```

Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/remote-installation/separate-scripts/start-nginx.cmd --output start-nginx.cmd
```

2. You can run this script using the following command:

MacOS/Linux
```
./start-nginx.sh
```

Windows
```
.\start-nginx.cmd
```

3. The script will prompt you to enter the therapeutic area.
4. The script will promt you to enter your email address that you use as your login on our central platform for the chosen therapeutic area.
5. The script will prompt you to enter your CLI secret for pulling our images. This secret can be found on our central image repository. Surf to:
    * https://harbor-uat.honeur.org for HONEUR
    * https://harbor-uat.phederation.org for PHederation
    * https://harbor-uat.esfurn.org for Esfurn
    * https://harbor-uat.athenafederation.org for Athena
6. login using the button "LOGIN VIA OIDC PROVIDER". Then click your account name on the top right corner of the screen and click "User Profile". Copy the CLI secret by clicking the copy symbol next to the text field.

Once done, the script will download the HONEUR Proxy docker image and will create the docker container.