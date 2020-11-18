# Installation Scripts

## HONEUR Studio installation instructions
HONEUR Studio can be downloaded right next to an existing installation. Please follow the installation steps:

1. download the installation script **_start-honeur-studio.sh_** for MacOS or **_start-honeur-studio.cmd_** for Windows. You can download this script using the following command:

MacOS/Linux
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/v2.0.0/remote-installation/scripts/start-honeur-studio.sh --output start-honeur-studio.sh && chmod +x start-honeur-studio.sh
```

Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/v2.0.0/remote-installation/scripts/start-honeur-studio.cmd --output start-honeur-studio.cmd
```

2. You can run this script using the following command:

MacOS/Linux
```
./start-honeur-studio.sh
```

Windows
```
.\start-honeur-studio.cmd
```

3. The script will prompt you to enter a Fully Qualified Domain Name (FQDN) or IP Address of the host machine. HONEUR Studio will only be accessible on the host machine (via localhost) if you accept the default ‘localhost’ value.
4. The script will prompt you to enter the directory of where the HONEUR Studio will store its working directory files.
5. The script will prompt you to enter the security options for HONEUR Studio. If you have existing HONEUR Components like postgres/webapi and zeppelin. Please use the same security settings as with this previous installation.
6. (OPTIONAL) when **_ldap_** is chosen for the installation security, additional connections details will be asked to connect to the existing LDAP Server

Once done, the script will download the HONEUR Studio docker image and will create the docker container.


## HONEUR Proxy
HONEUR Proxy can be downloaded right next to an existing installation. Please follow the installation steps:

1. download the installation script start-nginx.sh. You can download this script using the following command:

MacOS/Linux
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/v2.0.0/remote-installation/scripts/start-nginx.sh --output start-nginx.sh && chmod +x start-nginx.sh
```

Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/v2.0.0/remote-installation/scripts/start-nginx.cmd --output start-nginx.cmd
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

Once done, the script will download the HONEUR Studio docker image and will create the docker container.
