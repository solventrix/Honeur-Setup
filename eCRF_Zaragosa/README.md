# eCRF 

## Installation instructions
The eCRF tool can be installed by downloading and running the installation script. 

The tool can be installed stand-alone or can be installed as part of the Feder8 local installation.

The stand-alone version will contain 3 Docker containers: a Postgres database, the eCRF app and a NGINX proxy server.  

If the eCRF tool is installed as part of an existing Feder8 local installation, the NGINX proxy server will be shared with the other components of the Feder8 local installation.

### Feder8 local installation
If you already have a running Feder8 local installation and you want to install the eCRF tool on the same machine.

1. Make sure you have the latest version of the Feder8 local installation. Re-run the Feder8 local installation script to upgrade the current installation if needed.  See https://github.com/solventrix/Honeur-Setup/tree/master/local-installation/helper-scripts#installation-instruction

2. Download the installation script (**_install_ecrf.cmd_** for Windows or **_install_ecrf.sh_** for Linux/MacOS) by use of the following command:

Windows:
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/eCRF_Zaragosa/install_ecrf.cmd --output install_ecrf.cmd
```
Linux/MacOS:
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/eCRF_Zaragosa/install_ecrf.sh --output install_ecrf.sh && chmod +x install_ecrf.sh
```
3. Run the installation script

Windows:
```
.\install_ecrf.cmd
```

Linux/MacOS:
```
./install_ecrf.sh
```


### Stand-alone installation
If you want to install the eCRF tool as a stand-alone app.

1. Download the installation script (**_install_ecrf_stand_alone.cmd_** for Windows or **_install_ecrf_stand_alone.sh_** for Linux/MacOS) by use of the following command:

Windows:
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/eCRF_Zaragosa/install_ecrf_stand_alone.cmd --output install_ecrf_stand_alone.cmd
```
Linux/MacOS:
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/eCRF_Zaragosa/install_ecrf_stand_alone.sh --output install_ecrf_stand_alone.sh && chmod +x install_ecrf_stand_alone.sh
```
2. Run the installation script

Windows:
```
.\install_ecrf_stand_alone.cmd
```

Linux/MacOS:
```
./install_ecrf_stand_alone.sh
```

### <a id="extend-timeout"></a> Extend timeout (for existing installations)
To extend the timeout setting of existing installations.

1. Download the script (**_extend_timeout.sh_**) by use of the following command:

```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/eCRF_Zaragosa/extend_timeout.sh --output extend_timeout.sh && chmod +x extend_timeout.sh
```
2. Run the script

```
./extend_timeout.sh
```

