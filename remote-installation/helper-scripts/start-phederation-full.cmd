@echo off

echo Docker login, Make sure to use an account with access to the honeur docker hub images.
docker login

IF %ERRORLEVEL% NEQ 0 (
    EXIT /b 1
)

:while
set /p HONEUR_SECURITY_METHOD="Use jdbc users or LDAP or No for authentication? Enter jdbc/ldap/none. [none]: " || SET HONEUR_SECURITY_METHOD=none
if "%HONEUR_SECURITY_METHOD%" NEQ "none" if "%HONEUR_SECURITY_METHOD%" NEQ "ldap" if "%HONEUR_SECURITY_METHOD%" NEQ "jdbc" (
   echo enter "none", "jdbc", "ldap" or empty for default "none" value
   goto :while
)

if "%HONEUR_SECURITY_METHOD%" EQU "ldap" (
    set /p HONEUR_SECURITY_LDAP_URL="security.ldap.url [ldap://ldap.forumsys.com:389]: " || SET "HONEUR_SECURITY_LDAP_URL=ldap://ldap.forumsys.com:389"
    set /p HONEUR_SECURITY_LDAP_SYSTEM_USERNAME="security.ldap.system.username [cn=read-only-admin,dc=example,dc=com]: " || SET "HONEUR_SECURITY_LDAP_SYSTEM_USERNAME=cn=read-only-admin,dc=example,dc=com"
    set /p HONEUR_SECURITY_LDAP_SYSTEM_PASSWORD="security.ldap.system.password [password]: " || SET HONEUR_SECURITY_LDAP_SYSTEM_PASSWORD=password
    set /p HONEUR_SECURITY_LDAP_BASE_DN="security.ldap.baseDn [dc=example,dc=com]: " || SET "HONEUR_SECURITY_LDAP_BASE_DN=dc=example,dc=com"
    set /p HONEUR_SECURITY_LDAP_DN="security.ldap.dn [uid={0},dc=example,dc=com]: " || SET "HONEUR_SECURITY_LDAP_DN=uid={0},dc=example,dc=com"
)
if "%HONEUR_SECURITY_METHOD%" EQU "jdbc" (
    set "HONEUR_SECURITY_LDAP_URL=ldap://localhost:389"
    set "HONEUR_SECURITY_LDAP_SYSTEM_USERNAME=username"
    set "HONEUR_SECURITY_LDAP_SYSTEM_PASSWORD=password"
    set "HONEUR_SECURITY_LDAP_BASE_DN=dc=example,dc=org"
    set "HONEUR_SECURITY_LDAP_DN=cn={0},dc=example,dc=org"
)

set /p HONEUR_HOST_MACHINE="Enter the FQDN(Fully Qualified Domain Name eg. www.example.com) or public IP address(eg. 125.24.44.18) of the host machine. Use localhost to for testing [localhost]: " || SET HONEUR_HOST_MACHINE=localhost
set /p HONEUR_ZEPPELIN_LOGS="Enter the directory where the zeppelin logs will kept on the host machine [%CD%\zeppelin\logs]: " || SET HONEUR_ZEPPELIN_LOGS=%CD%\zeppelin\logs
set /p HONEUR_ZEPPELIN_NOTEBOOKS="Enter the directory where the zeppelin notebooks will kept on the host machine [%CD%\zeppelin\notebook]: " || SET HONEUR_ZEPPELIN_NOTEBOOKS=%CD%\zeppelin\notebook
set /p HONEUR_ANALYTICS_SHARED_FOLDER="Enter the directory where Zeppelin/HONEUR Studio will save the prepared distributed analytics data [%CD%\distributed-analytics]: " || SET HONEUR_ANALYTICS_SHARED_FOLDER=%CD%\distributed-analytics
set /p HONEUR_ANALYTICS_ORGANIZATION="Enter your HONEUR organization [Janssen]: " || SET HONEUR_ANALYTICS_ORGANIZATION=Janssen
set /p HONEUR_HONEUR_STUDIO_FOLDER="Enter the directory where HONEUR Studio will store its data [%CD%\honeurstudio]: " || SET HONEUR_HONEUR_STUDIO_FOLDER=%CD%\honeurstudio

if "%HONEUR_SECURITY_METHOD%" NEQ "none" (
    set /p HONEUR_USERMGMT_ADMIN_USERNAME="User Management administrator username [admin]: " || SET HONEUR_USERMGMT_ADMIN_USERNAME=admin
    set /p HONEUR_USERMGMT_ADMIN_PASSWORD="User Management administrator password [admin]: " || SET HONEUR_USERMGMT_ADMIN_PASSWORD=admin
)

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/remote-installation/separate-scripts/start-postgres-phederation.cmd --output start-postgres.cmd
CALL .\start-postgres.cmd
DEL start-postgres.cmd

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/remote-installation/separate-scripts/start-atlas-webapi.cmd --output start-atlas-webapi.cmd
CALL .\start-atlas-webapi.cmd "%HONEUR_HOST_MACHINE%" "%HONEUR_SECURITY_METHOD%" "%HONEUR_SECURITY_LDAP_URL%" "%HONEUR_SECURITY_LDAP_SYSTEM_USERNAME%" "%HONEUR_SECURITY_LDAP_SYSTEM_PASSWORD%" "%HONEUR_SECURITY_LDAP_BASE_DN%" "%HONEUR_SECURITY_LDAP_DN%"
DEL start-atlas-webapi.cmd

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/remote-installation/separate-scripts/start-zeppelin.cmd --output start-zeppelin.cmd
CALL .\start-zeppelin.cmd "%HONEUR_ZEPPELIN_LOGS%" "%HONEUR_ZEPPELIN_NOTEBOOKS%" "%HONEUR_ANALYTICS_SHARED_FOLDER%" "%HONEUR_SECURITY_METHOD%" "%HONEUR_SECURITY_LDAP_URL%" "%HONEUR_SECURITY_LDAP_SYSTEM_USERNAME%" "%HONEUR_SECURITY_LDAP_SYSTEM_PASSWORD%" "%HONEUR_SECURITY_LDAP_BASE_DN%" "%HONEUR_SECURITY_LDAP_DN%"
DEL start-zeppelin.cmd

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/remote-installation/separate-scripts/start-distributed-analytics.cmd --output start-distributed-analytics.cmd
CALL .\start-distributed-analytics.cmd "%HONEUR_ANALYTICS_SHARED_FOLDER%" "%HONEUR_ANALYTICS_ORGANIZATION%"
DEL start-distributed-analytics.cmd

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/remote-installation/separate-scripts/start-honeur-studio.cmd --output start-honeur-studio.cmd
CALL .\start-honeur-studio.cmd "%HONEUR_HOST_MACHINE%" "%HONEUR_HONEUR_STUDIO_FOLDER%" "%HONEUR_ANALYTICS_SHARED_FOLDER%" "%HONEUR_SECURITY_METHOD%" "%HONEUR_SECURITY_LDAP_URL%" "%HONEUR_SECURITY_LDAP_SYSTEM_USERNAME%" "%HONEUR_SECURITY_LDAP_SYSTEM_PASSWORD%" "%HONEUR_SECURITY_LDAP_BASE_DN%" "%HONEUR_SECURITY_LDAP_DN%"
DEL start-honeur-studio.cmd

if "%HONEUR_SECURITY_METHOD%" NEQ "none" (
    curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/remote-installation/separate-scripts/start-user-management.cmd --output start-user-management.cmd
    CALL .\start-user-management.cmd "%HONEUR_USERMGMT_ADMIN_USERNAME%" "%HONEUR_USERMGMT_ADMIN_PASSWORD%"
    DEL start-user-management.cmd
)

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/remote-installation/separate-scripts/start-nginx.cmd --output start-nginx.cmd
CALL .\start-nginx.cmd
DEL start-nginx.cmd

echo postgresql is available on %HONEUR_HOST_MACHINE%:5444
echo Atlas/WebAPI is available on http://%HONEUR_HOST_MACHINE%/atlas and http://%HONEUR_HOST_MACHINE%/webapi respectively
echo Zeppelin is available on http://%HONEUR_HOST_MACHINE%/zeppelin
echo Zeppelin logs are available in directory %HONEUR_ZEPPELIN_LOGS%
echo Zeppelin notebooks are available in directory %HONEUR_ZEPPELIN_NOTEBOOKS%
IF "%HONEUR_SECURITY_METHOD%" NEQ "none" echo User Management is available on http://%HONEUR_HOST_MACHINE%/user-mgmt
echo HONEUR Studio VSCode is available on http://%HONEUR_HOST_MACHINE%/honeur-studio/app/vscode
echo HONEUR Studio RStudio is available on http://%HONEUR_HOST_MACHINE%/honeur-studio/app/rstudio
echo HONEUR Studio local Shiny apps are available on http://%HONEUR_HOST_MACHINE%/honeur-studio/app/reports
echo HONEUR Studio documents is available on http://%HONEUR_HOST_MACHINE%/honeur-studio/app/documents
echo HONEUR Studio personal space is available on http://%HONEUR_HOST_MACHINE%/honeur-studio/app/personal
