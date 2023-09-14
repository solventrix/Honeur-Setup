# eCRF 

## Instructions for the initial installation

!! Don't run the installation script if you already have an exiting installation!  Use the upgrade script instead: see [Instructions for upgrading an existing installation](#upgrade-installation)

The eCRF tool can be installed by downloading and running the installation script.

1. Download the installation script (**_install_ecrf_oncocologne.cmd_** for Windows or **_install_ecrf_oncocologne.sh_** for Linux/MacOS) by use of the following command:

Windows:
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/eCRF_OncoCologne/install_ecrf_oncocologne.cmd --output install_ecrf_oncocologne.cmd
```
Linux/MacOS:
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/eCRF_OncoCologne/install_ecrf_oncocologne.sh --output install_ecrf_oncocologne.sh && chmod +x install_ecrf_oncocologne.sh
```
2. Run the installation script

Windows:
```
.\install_ecrf_oncocologne.cmd
```

Linux/MacOS:
```
./install_ecrf_oncocologne.sh
```

## <a id="upgrade-installation"></a> Instructions for upgrading an existing installation
To upgrade your existing installation, please follow the steps below.

1. Download the upgrade script (**_upgrade.cmd_** for Windows or **_upgrade.sh_** for Linux/MacOS) by use of the following command:

Windows:
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/eCRF_OncoCologne/upgrade.cmd --output upgrade.cmd
```
Linux/MacOS:
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/eCRF_OncoCologne/upgrade.sh --output upgrade.sh && chmod +x upgrade.sh
```
2. Run the upgrade script

Windows:
```
.\upgrade.cmd
```

Linux/MacOS:
```
./upgrade.sh
```

The upgrade script will ask to enter a password for the database and eCRF tool. Please enter the passwords that were entered during the initial installation.

The script will take a backup of your database.  The backup file will be stored in a 'backup' folder under the current directory.


## <a id="upgrade-installation-feder8"></a> Instructions for upgrading an existing installation to Feder8
To upgrade your existing installation to Feder8, please follow the steps below.

1. Install the local installation for Feder8. See [https://github.com/solventrix/Honeur-Setup/tree/master/local-installation/helper-scripts](https://github.com/solventrix/Honeur-Setup/tree/master/local-installation/helper-scripts) for more information.

2. Download the upgrade script (**_feder8_upgrade.cmd_** for Windows or **_feder8_upgrade.sh_** for Linux/MacOS) by use of the following command:

Windows:
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/eCRF_OncoCologne/feder8_upgrade.cmd --output feder8_upgrade.cmd
```
Linux/MacOS:
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/eCRF_OncoCologne/feder8_upgrade.sh --output feder8_upgrade.sh && chmod +x feder8_upgrade.sh
```
3. Run the upgrade script

Windows:
```
.\feder8_upgrade.cmd
```

Linux/MacOS:
```
./feder8_upgrade.sh
```

The upgrade script will ask to enter a password for the database and eCRF tool. Please enter the passwords that were entered during the initial installation.

The script will take a backup of your database.  The backup file will be stored in a 'backup' folder under the current directory.



## Database backup
A backup of the eCRF database can be taken by use of the backup script.

1. Download the backup script (**_backup_ecrf_db.cmd_** for Linux/MacOS or **_backup_ecrf_db.sh_** for Linux/MacOS) by use of the following command:

Windows:
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/eCRF_OncoCologne/backup_ecrf_db.cmd --output backup_ecrf_db.cmd
```
Linux/MacOS:
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/eCRF_OncoCologne/backup_ecrf_db.sh --output backup_ecrf_db.sh && chmod +x backup_ecrf_db.sh
```
2. Run the backup script

Windows:
```
.\backup_ecrf_db.cmd
```
Linux/MacOS:
```
./backup_ecrf_db.sh
```
3. Store the created backup file in a safe location!

## Database restore
If needed, a backup of the eCRF database can be restored by use of the database restore script.

1. Download the restore script (**_restore_ecrf_db.cmd_** for Linux/MacOS or **_restore_ecrf_db.sh_** for Linux/MacOS) by use of the following command:

Windows:
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/eCRF_OncoCologne/restore_ecrf_db.cmd --output restore_ecrf_db.cmd
```
Linux/MacOS:
```
curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/eCRF_OncoCologne/restore_ecrf_db.sh --output restore_ecrf_db.sh && chmod +x restore_ecrf_db.sh
```
2. Run the restore script

Windows:
```
.\restore_ecrf_db.cmd
```
Linux/MacOS:
```
./restore_ecrf_db.sh
```
3. Check whether the database was successfully restored



