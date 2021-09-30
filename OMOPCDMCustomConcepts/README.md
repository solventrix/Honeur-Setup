# Update custom concepts in the OMOP CDM DB
When new custom concepts are available, they can be easily loaded in the OMOP CDM database.

## Installation steps
1. download the installation helper script **_start-custom-concepts-update.sh_** for MacOS/Linux or **_start-custom-concepts-update.cmd_** for Windows. You can download this script using the following command:

MacOS/Linux
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/remote-installation/separate-scripts/start-custom-concepts-update.sh --output start-custom-concepts-update.sh && chmod +x start-custom-concepts-update.sh
```

Windows
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/remote-installation/separate-scripts/start-custom-concepts-update.cmd --output start-custom-concepts-update.cmd
```

2. You can run this script using the following command:

MacOS/Linux
```
./start-custom-concepts-update.sh
```

Windows
```
.\start-custom-concepts-update.cmd
```

3. The script will prompt you to enter the therapeutic area.
4. The script will promt you to enter your email address that you use as your login on our central platform for the chosen therapeutic area.
5. The script will prompt you to enter your CLI secret for pulling our images. This secret can be found on our central image repository. Surf to:
    * https://harbor.honeur.org for HONEUR
    * https://harbor.phederation.org for PHederation
    * https://harbor.esfurn.org for Esfurn

Once done, the script will download the custom concepts update image and will create the docker container that will run the update.
