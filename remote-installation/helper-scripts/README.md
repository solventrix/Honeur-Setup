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
      * [HONEUR](#essential-honeur)
      * [PHederation](#essential-phederation)
      * [Esfurn](#essential-esfurn)
      * [Athena](#essential-athena)
  * [Full](#full)
    * [Installation instructions](#full-installation-instruction)
      * [HONEUR](#full-honeur)
      * [PHederation](#full-phederation)
      * [Esfurn](#full-esfurn)
      * [Athena](#full-athena)

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
  * Postgres database v9.6.18 running on port 5444
  * Atlas/WebAPI v2.7.1 running on Apache Tomcat 9.0.20
  * Zeppelin running Jetty v9.4.14
  * User Management running on Apache Tomcat 9.0.33 (Only secure installation)
  * Proxy

### <a id="essential-installation-instruction"></a>Installation instructions
Essential remote installation can be installed by running the installation helper script. :warning: Please run the correct installation script for your disease area (e.g. [HONEUR](#essential-honeur), [PHederation](#essential-phederation) or [Esfurn](#essential-esfurn)).

#### <a id="essential-honeur"></a>HONEUR
1. download the installation helper script **_start-honeur.sh_** for MacOS/Linux or **_start-honeur.cmd_** for Windows. You can download this script using the following command:

MacOS/Linux
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/UAT/remote-installation/helper-scripts/start-honeur.sh --output start-honeur.sh && chmod +x start-honeur.sh
```

Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/UAT/remote-installation/helper-scripts/start-honeur.cmd --output start-honeur.cmd
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
3. The script will promt you to enter your email address that you use as your login on our central platform https://portal-uat.honeur.org.
4. The script will prompt you to enter your CLI secret for pulling our images. This secret can be found on our central image repository. Surf to https://harbor-uat.honeur.org and login using the button \"LOGIN VIA OIDC PROVIDER\". Then click your account name on the top right corner of the screen and click \"User Profile\". Copy the CLI secret by clicking the copy symbol next to the text field.
5. The script will prompt you to enter the security options for Atlas/WebAPI. If you have existing HONEUR Components like Postgres/Zeppelin or HONEUR studio. Please use the same security settings as with these previous installation.
6. (OPTIONAL when **_ldap_** is chosen for the installation security) Additional connections details will be asked to connect to the existing LDAP Server.
7. The script will prompt you to enter a Fully Qualified Domain Name (FQDN) or IP Address of the host machine. Atlas/WebAPI will only be accessible on the host machine (via localhost) if you accept the default ‘localhost’ value.
8. The script will prompt you to enter a Directory on the host machine to save the Zeppelin logs, notebooks and prepared distributed analytics data. Please provide an absolute path.
9. The script will prompt you to enter a new password for honeur database user.
10. The script will prompt you to enter a new password for honeur_admin database user.

Once done, the script will download all essential docker images and will create the docker containers.

#### <a id="essential-phederation"></a>PHederation
1. download the installation helper script **_start-phederation.sh_** for MacOS/Linux or **_start-phederation.cmd_** for Windows. You can download this script using the following command:

MacOS/Linux
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/UAT/remote-installation/helper-scripts/start-phederation.sh --output start-phederation.sh && chmod +x start-phederation.sh
```

Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/UAT/remote-installation/helper-scripts/start-phederation.cmd --output start-phederation.cmd
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

3. The script will promt you to enter your email address that you use as your login on our central platform https://portal-uat.phederation.org.
4. The script will prompt you to enter your CLI secret for pulling our images. This secret can be found on our central image repository. Surf to https://harbor-uat.phederation.org and login using the button \"LOGIN VIA OIDC PROVIDER\". Then click your account name on the top right corner of the screen and click \"User Profile\". Copy the CLI secret by clicking the copy symbol next to the text field.
5. The script will prompt you to enter the security options for Atlas/WebAPI. If you have existing PHederation Components like Postgres/Zeppelin or PHEDERATION studio. Please use the same security settings as with these previous installation.
6. (OPTIONAL when **_ldap_** is chosen for the installation security) Additional connections details will be asked to connect to the existing LDAP Server.
7. The script will prompt you to enter a Fully Qualified Domain Name (FQDN) or IP Address of the host machine. Atlas/WebAPI will only be accessible on the host machine (via localhost) if you accept the default ‘localhost’ value.
8. The script will prompt you to enter a Directory on the host machine to save the Zeppelin logs, notebooks and prepared distributed analytics data. Please provide an absolute path.
9. The script will prompt you to enter a new password for phederation database user.
10. The script will prompt you to enter a new password for phederation_admin database user.

Once done, the script will download all essential docker images and will create the docker containers.

#### <a id="essential-esfurn"></a>Esfurn
1. download the installation helper script **_start-esfurn.sh_** for MacOS/Linux or **_start-esfurn.cmd_** for Windows. You can download this script using the following command:

MacOS/Linux
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/UAT/remote-installation/helper-scripts/start-esfurn.sh --output start-esfurn.sh && chmod +x start-esfurn.sh
```

Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/UAT/remote-installation/helper-scripts/start-esfurn.cmd --output start-esfurn.cmd
```

2. You can run this script using the following command:

MacOS/Linux
```
./start-esfurn.sh
```

Windows
```
.\start-esfurn.cmd
```

3. The script will promt you to enter your email address that you use as your login on our central platform https://portal-uat.esfurn.org.
4. The script will prompt you to enter your CLI secret for pulling our images. This secret can be found on our central image repository. Surf to https://harbor-uat.esfurn.org and login using the button \"LOGIN VIA OIDC PROVIDER\". Then click your account name on the top right corner of the screen and click \"User Profile\". Copy the CLI secret by clicking the copy symbol next to the text field.
5. The script will prompt you to enter the security options for Atlas/WebAPI. If you have existing Esfurn Components like Postgres/Zeppelin or ESFURN studio. Please use the same security settings as with these previous installation.
6. (OPTIONAL when **_ldap_** is chosen for the installation security) Additional connections details will be asked to connect to the existing LDAP Server.
7. The script will prompt you to enter a Fully Qualified Domain Name (FQDN) or IP Address of the host machine. Atlas/WebAPI will only be accessible on the host machine (via localhost) if you accept the default ‘localhost’ value.
8. The script will prompt you to enter a Directory on the host machine to save the Zeppelin logs, notebooks and prepared distributed analytics data. Please provide an absolute path.
9. The script will prompt you to enter a new password for esfurn database user.
10. The script will prompt you to enter a new password for esfurn_admin database user.

Once done, the script will download all essential docker images and will create the docker containers.

#### <a id="essential-athena"></a>Athena
1. download the installation helper script **_start-athena.sh_** for MacOS/Linux or **_start-athena.cmd_** for Windows. You can download this script using the following command:

MacOS/Linux
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/UAT/remote-installation/helper-scripts/start-athena.sh --output start-athena.sh && chmod +x start-athena.sh
```

Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/UAT/remote-installation/helper-scripts/start-athena.cmd --output start-athena.cmd
```

2. You can run this script using the following command:

MacOS/Linux
```
./start-athena.sh
```

Windows
```
.\start-athena.cmd
```

3. The script will promt you to enter your email address that you use as your login on our central platform https://portal-uat.uat.athenafederation.org.
4. The script will prompt you to enter your CLI secret for pulling our images. This secret can be found on our central image repository. Surf to https://harbor-uat.athenafederation.org and login using the button \"LOGIN VIA OIDC PROVIDER\". Then click your account name on the top right corner of the screen and click \"User Profile\". Copy the CLI secret by clicking the copy symbol next to the text field.
5. The script will prompt you to enter the security options for Atlas/WebAPI. If you have existing Athena Components like Postgres/Zeppelin or Athena studio. Please use the same security settings as with these previous installation.
6. (OPTIONAL when **_ldap_** is chosen for the installation security) Additional connections details will be asked to connect to the existing LDAP Server.
7. The script will prompt you to enter a Fully Qualified Domain Name (FQDN) or IP Address of the host machine. Atlas/WebAPI will only be accessible on the host machine (via localhost) if you accept the default ‘localhost’ value.
8. The script will prompt you to enter a Directory on the host machine to save the Zeppelin logs, notebooks and prepared distributed analytics data. Please provide an absolute path.
9. The script will prompt you to enter a new password for athena database user.
10. The script will prompt you to enter a new password for athena_admin database user.

Once done, the script will download all essential docker images and will create the docker containers.

## Full
following components will be installed:
  * Postgres database v9.6.18 running on port 5444
  * Atlas/WebAPI v2.7.1 running on Apache Tomcat 9.0.20
  * Zeppelin running Jetty v9.4.14
  * Distributed analytics
  * FEDER8 Studio
  * User Management running on Apache Tomcat 9.0.33 (Only secure installation)
  * Proxy

### <a id="full-installation-instruction"></a>Installation instructions
Full remote installation can be installed by running the installation helper script. :warning: Please install the correct installation script for your disease area (e.g. [HONEUR](#full-honeur), [PHederation](#full-phederation) or [Esfurn](#full-esfurn)).

#### <a id="full-honeur"></a>HONEUR
1. download the installation helper script **_start-honeur-full.sh_** for MacOS/Linux or **_start-honeur-full.cmd_** for Windows. You can download this script using the following command:

MacOS/Linux
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/UAT/remote-installation/helper-scripts/start-honeur-full.sh --output start-honeur.sh && chmod +x start-honeur.sh
```

Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/UAT/remote-installation/helper-scripts/start-honeur-full.cmd --output start-honeur.cmd
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
3. The script will promt you to enter your email address that you use as your login on our central platform https://portal-uat.honeur.org.
4. The script will prompt you to enter your CLI secret for pulling our images. This secret can be found on our central image repository. Surf to https://harbor-uat.honeur.org and login using the button \"LOGIN VIA OIDC PROVIDER\". Then click your account name on the top right corner of the screen and click \"User Profile\". Copy the CLI secret by clicking the copy symbol next to the text field.
5. The script will prompt you to enter the security options for Atlas/WebAPI. If you have existing HONEUR Components like Postgres/Zeppelin or HONEUR studio. Please use the same security settings as with these previous installation.
6. (OPTIONAL when **_ldap_** is chosen for the installation security) Additional connections details will be asked to connect to the existing LDAP Server.
7. The script will prompt you to enter a Fully Qualified Domain Name (FQDN) or IP Address of the host machine. Atlas/WebAPI will only be accessible on the host machine (via localhost) if you accept the default ‘localhost’ value.
8. The script will prompt you to enter a Directory on the host machine to save the Zeppelin logs, notebooks and prepared distributed analytics data. Please provide an absolute path.
9. The script will prompt you to enter the name of your organization. :warning: The name of the organization is given by the HONEUR Team.
10. The script will prompt you to enter the directory of where the HONEUR Studio will store its working directory files.
11. The script will prompt you to enter a new password for honeur database user.
12. The script will prompt you to enter a new password for honeur_admin database user.

Once done, the script will download all docker images and will create the docker containers.

#### <a id="full-phederation"></a>PHederation
1. download the installation helper script **_start-phederation-full.sh_** for MacOS/Linux or **_start-phederation-full.cmd_** for Windows. You can download this script using the following command:

MacOS/Linux
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/UAT/remote-installation/helper-scripts/start-phederation-full.sh --output start-phederation.sh && chmod +x start-phederation.sh
```

Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/UAT/remote-installation/helper-scripts/start-phederation-full.cmd --output start-phederation.cmd
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
3. The script will promt you to enter your email address that you use as your login on our central platform https://portal-uat.phederation.org.
4. The script will prompt you to enter your CLI secret for pulling our images. This secret can be found on our central image repository. Surf to https://harbor-uat.phederation.org and login using the button \"LOGIN VIA OIDC PROVIDER\". Then click your account name on the top right corner of the screen and click \"User Profile\". Copy the CLI secret by clicking the copy symbol next to the text field.
5. The script will prompt you to enter the security options for Atlas/WebAPI. If you have existing PHederation Components like Postgres/Zeppelin or PHederation studio. Please use the same security settings as with these previous installation.
6. (OPTIONAL when **_ldap_** is chosen for the installation security) Additional connections details will be asked to connect to the existing LDAP Server.
7. The script will prompt you to enter a Fully Qualified Domain Name (FQDN) or IP Address of the host machine. Atlas/WebAPI will only be accessible on the host machine (via localhost) if you accept the default ‘localhost’ value.
8. The script will prompt you to enter a Directory on the host machine to save the Zeppelin logs, notebooks and prepared distributed analytics data. Please provide an absolute path.
9. The script will prompt you to enter the name of your organization. :warning: The name of the organization is given by the PHederation Team.
10. The script will prompt you to enter the directory of where the PHEDERATION Studio will store its working directory files.
11. The script will prompt you to enter a new password for phederation database user.
12. The script will prompt you to enter a new password for phederation_admin database user.

Once done, the script will download all docker images and will create the docker containers.

#### <a id="full-esfurn"></a>Esfurn
1. download the installation helper script **_start-esfurn-full.sh_** for MacOS/Linux or **_start-esfurn-full.cmd_** for Windows. You can download this script using the following command:

MacOS/Linux
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/UAT/remote-installation/helper-scripts/start-esfurn-full.sh --output start-esfurn.sh && chmod +x start-esfurn.sh
```

Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/UAT/remote-installation/helper-scripts/start-esfurn-full.cmd --output start-esfurn.cmd
```

2. You can run this script using the following command:

MacOS/Linux
```
./start-esfurn.sh
```

Windows
```
.\start-esfurn.cmd
```
3. The script will promt you to enter your email address that you use as your login on our central platform https://portal-uat.esfurn.org.
4. The script will prompt you to enter your CLI secret for pulling our images. This secret can be found on our central image repository. Surf to https://harbor-uat.esfurn.org and login using the button \"LOGIN VIA OIDC PROVIDER\". Then click your account name on the top right corner of the screen and click \"User Profile\". Copy the CLI secret by clicking the copy symbol next to the text field.
5. The script will prompt you to enter the security options for Atlas/WebAPI. If you have existing Esfurn Components like Postgres/Zeppelin or ESFURN studio. Please use the same security settings as with these previous installation.
6. (OPTIONAL when **_ldap_** is chosen for the installation security) Additional connections details will be asked to connect to the existing LDAP Server.
7. The script will prompt you to enter a Fully Qualified Domain Name (FQDN) or IP Address of the host machine. Atlas/WebAPI will only be accessible on the host machine (via localhost) if you accept the default ‘localhost’ value.
8. The script will prompt you to enter a Directory on the host machine to save the Zeppelin logs, notebooks and prepared distributed analytics data. Please provide an absolute path.
9. The script will prompt you to enter the name of your organization. :warning: The name of the organization is given by the Esfurn Team.
10. The script will prompt you to enter the directory of where the ESFURN Studio will store its working directory files.
11. The script will prompt you to enter a new password for esfurn database user.
12. The script will prompt you to enter a new password for esfurn_admin database user.

Once done, the script will download all docker images and will create the docker containers.

#### <a id="full-athena"></a>Athena
1. download the installation helper script **_start-athena-full.sh_** for MacOS/Linux or **_start-athena-full.cmd_** for Windows. You can download this script using the following command:

MacOS/Linux
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/UAT/remote-installation/helper-scripts/start-athena-full.sh --output start-athena.sh && chmod +x start-athena.sh
```

Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/UAT/remote-installation/helper-scripts/start-athena-full.cmd --output start-athena.cmd
```

2. You can run this script using the following command:

MacOS/Linux
```
./start-athena.sh
```

Windows
```
.\start-athena.cmd
```
3. The script will promt you to enter your email address that you use as your login on our central platform https://portal-uat.uat.athenafederation.org.
4. The script will prompt you to enter your CLI secret for pulling our images. This secret can be found on our central image repository. Surf to https://harbor-uat.uat.athenafederation.org and login using the button \"LOGIN VIA OIDC PROVIDER\". Then click your account name on the top right corner of the screen and click \"User Profile\". Copy the CLI secret by clicking the copy symbol next to the text field.
5. The script will prompt you to enter the security options for Atlas/WebAPI. If you have existing Athena Components like Postgres/Zeppelin or Athena studio. Please use the same security settings as with these previous installation.
6. (OPTIONAL when **_ldap_** is chosen for the installation security) Additional connections details will be asked to connect to the existing LDAP Server.
7. The script will prompt you to enter a Fully Qualified Domain Name (FQDN) or IP Address of the host machine. Atlas/WebAPI will only be accessible on the host machine (via localhost) if you accept the default ‘localhost’ value.
8. The script will prompt you to enter a Directory on the host machine to save the Zeppelin logs, notebooks and prepared distributed analytics data. Please provide an absolute path.
9. The script will prompt you to enter the name of your organization. :warning: The name of the organization is given by the Athena Team.
10. The script will prompt you to enter the directory of where the Athena Studio will store its working directory files.
11. The script will prompt you to enter a new password for athena database user.
12. The script will prompt you to enter a new password for athena_admin database user.

Once done, the script will download all docker images and will create the docker containers.
