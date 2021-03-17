@echo off

SET "FEDER8_THERAPEUTIC_AREA=honeur"
for /f "usebackq delims=" %%I in (`powershell "\"%str%\".toUpper()"`) do set "FEDER8_THERAPEUTIC_AREA_UPPERCASE=%%~I"
SET "FEDER8_THERAPEUTIC_AREA_DOMAIN=honeur.org"
SET "FEDER8_THERAPEUTIC_AREA_URL=harbor-uat.honeur.org"

SET /p FEDER8_EMAIL_ADDRESS="Enter email address used to login to https://portal-uat.%FEDER8_THERAPEUTIC_AREA_DOMAIN%: "
:while-email-address-not-correct
if "%FEDER8_EMAIL_ADDRESS%" == "" (
   echo Email address can not be empty
   SET /p FEDER8_EMAIL_ADDRESS="Enter email address used to login to https://portal-uat.%FEDER8_THERAPEUTIC_AREA_DOMAIN%: "
   goto :while-email-address-not-correct
)

echo Surf to https://%FEDER8_THERAPEUTIC_AREA_URL% and login using the button "LOGIN VIA OIDC PROVIDER". Then click your account name on the top right corner of the screen and click "User Profile". Copy the CLI secret by clicking the copy symbol next to the text field.
SET /p FEDER8_CLI_SECRET="Enter the CLI Secret: "
:while-cli-secret-not-correct
if "%FEDER8_CLI_SECRET%" == "" (
   echo Email address can not be empty
   SET /p FEDER8_CLI_SECRET="Enter email address used to login to https://portal-uat.%FEDER8_THERAPEUTIC_AREA_DOMAIN%: "
   goto :while-cli-secret-not-correct
)

:while
set /p FEDER8_SECURITY_METHOD="Use jdbc users or LDAP or No for authentication? Enter jdbc/ldap/none. [none]: " || SET FEDER8_SECURITY_METHOD=none
if "%FEDER8_SECURITY_METHOD%" NEQ "none" if "%FEDER8_SECURITY_METHOD%" NEQ "ldap" if "%FEDER8_SECURITY_METHOD%" NEQ "jdbc" (
   echo enter "none", "jdbc", "ldap" or empty for default "none" value
   goto :while
)

if "%FEDER8_SECURITY_METHOD%" EQU "ldap" (
    set /p FEDER8_SECURITY_LDAP_URL="security.ldap.url [ldap://ldap.forumsys.com:389]: " || SET "FEDER8_SECURITY_LDAP_URL=ldap://ldap.forumsys.com:389"
    set /p FEDER8_SECURITY_LDAP_SYSTEM_USERNAME="security.ldap.system.username [cn=read-only-admin,dc=example,dc=com]: " || SET "FEDER8_SECURITY_LDAP_SYSTEM_USERNAME=cn=read-only-admin,dc=example,dc=com"
    set /p FEDER8_SECURITY_LDAP_SYSTEM_PASSWORD="security.ldap.system.password [password]: " || SET FEDER8_SECURITY_LDAP_SYSTEM_PASSWORD=password
    set /p FEDER8_SECURITY_LDAP_BASE_DN="security.ldap.baseDn [dc=example,dc=com]: " || SET "FEDER8_SECURITY_LDAP_BASE_DN=dc=example,dc=com"
    set /p FEDER8_SECURITY_LDAP_DN="security.ldap.dn [uid={0},dc=example,dc=com]: " || SET "FEDER8_SECURITY_LDAP_DN=uid={0},dc=example,dc=com"
)
if "%FEDER8_SECURITY_METHOD%" EQU "jdbc" (
    set "FEDER8_SECURITY_LDAP_URL=ldap://localhost:389"
    set "FEDER8_SECURITY_LDAP_SYSTEM_USERNAME=username"
    set "FEDER8_SECURITY_LDAP_SYSTEM_PASSWORD=password"
    set "FEDER8_SECURITY_LDAP_BASE_DN=dc=example,dc=org"
    set "FEDER8_SECURITY_LDAP_DN=cn={0},dc=example,dc=org"
)

set /p FEDER8_HOST_MACHINE="Enter the FQDN(Fully Qualified Domain Name eg. www.example.com) or public IP address(eg. 125.24.44.18) of the host machine. Use localhost to for testing [localhost]: " || SET FEDER8_HOST_MACHINE=localhost
set /p FEDER8_ZEPPELIN_LOGS="Enter the directory where the zeppelin logs will kept on the host machine [%CD%\zeppelin\logs]: " || SET FEDER8_ZEPPELIN_LOGS=%CD%\zeppelin\logs
set /p FEDER8_ZEPPELIN_NOTEBOOKS="Enter the directory where the zeppelin notebooks will kept on the host machine [%CD%\zeppelin\notebook]: " || SET FEDER8_ZEPPELIN_NOTEBOOKS=%CD%\zeppelin\notebook
set /p FEDER8_ANALYTICS_SHARED_FOLDER="Enter the directory where Zeppelin/HONEUR Studio will save the prepared distributed analytics data [%CD%\distributed-analytics]: " || SET FEDER8_ANALYTICS_SHARED_FOLDER=%CD%\distributed-analytics
set /p FEDER8_ANALYTICS_ORGANIZATION="Enter your HONEUR organization [Janssen]: " || SET FEDER8_ANALYTICS_ORGANIZATION=Janssen
set /p FEDER8_STUDIO_FOLDER="Enter the directory where HONEUR Studio will store its data [%CD%\%FEDER8_THERAPEUTIC_AREA%studio]: " || SET FEDER8_STUDIO_FOLDER=%CD%\%FEDER8_THERAPEUTIC_AREA%studio

if "%FEDER8_SECURITY_METHOD%" NEQ "none" (
    set /p FEDER8_USERMGMT_ADMIN_USERNAME="User Management administrator username [admin]: " || SET FEDER8_USERMGMT_ADMIN_USERNAME=admin
    set /p FEDER8_USERMGMT_ADMIN_PASSWORD="User Management administrator password [admin]: " || SET FEDER8_USERMGMT_ADMIN_PASSWORD=admin
)

CALL :generate-random-password FEDER8_USER_PW
CALL :generate-random-password FEDER8_ADMIN_USER_PW

SET /p FEDER8_USER_PW="Enter password for %FEDER8_THERAPEUTIC_AREA% database user [%FEDER8_USER_PW%]: " || SET FEDER8_USER_PW=%FEDER8_USER_PW%
SET /p FEDER8_ADMIN_USER_PW="Enter password for %FEDER8_THERAPEUTIC_AREA%_admin database user [%FEDER8_ADMIN_USER_PW%]: " || SET FEDER8_ADMIN_USER_PW=%FEDER8_ADMIN_USER_PW%

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/remote-installation/separate-scripts/start-postgres.cmd --output start-postgres.cmd
CALL .\start-postgres.cmd "%FEDER8_THERAPEUTIC_AREA%" "%FEDER8_EMAIL_ADDRESS%" "%FEDER8_CLI_SECRET%" "%FEDER8_USER_PW%" "%FEDER8_ADMIN_USER_PW%"
DEL start-postgres.cmd

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/remote-installation/separate-scripts/start-atlas-webapi.cmd --output start-atlas-webapi.cmd
CALL .\start-atlas-webapi.cmd "%FEDER8_THERAPEUTIC_AREA%" "%FEDER8_EMAIL_ADDRESS%" "%FEDER8_CLI_SECRET%" "%FEDER8_HOST_MACHINE%" "%FEDER8_SECURITY_METHOD%" "%FEDER8_SECURITY_LDAP_URL%" "%FEDER8_SECURITY_LDAP_SYSTEM_USERNAME%" "%FEDER8_SECURITY_LDAP_SYSTEM_PASSWORD%" "%FEDER8_SECURITY_LDAP_BASE_DN%" "%FEDER8_SECURITY_LDAP_DN%"
DEL start-atlas-webapi.cmd

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/remote-installation/separate-scripts/start-zeppelin.cmd --output start-zeppelin.cmd
CALL .\start-zeppelin.cmd "%FEDER8_THERAPEUTIC_AREA%" "%FEDER8_EMAIL_ADDRESS%" "%FEDER8_CLI_SECRET%" "%FEDER8_ZEPPELIN_LOGS%" "%FEDER8_ZEPPELIN_NOTEBOOKS%" "%FEDER8_ANALYTICS_SHARED_FOLDER%" "%FEDER8_SECURITY_METHOD%" "%FEDER8_SECURITY_LDAP_URL%" "%FEDER8_SECURITY_LDAP_SYSTEM_USERNAME%" "%FEDER8_SECURITY_LDAP_SYSTEM_PASSWORD%" "%FEDER8_SECURITY_LDAP_BASE_DN%" "%FEDER8_SECURITY_LDAP_DN%"
DEL start-zeppelin.cmd

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/remote-installation/separate-scripts/start-distributed-analytics.cmd --output start-distributed-analytics.cmd
CALL .\start-distributed-analytics.cmd "%FEDER8_THERAPEUTIC_AREA%" "%FEDER8_EMAIL_ADDRESS%" "%FEDER8_CLI_SECRET%" "%FEDER8_ANALYTICS_SHARED_FOLDER%" "%FEDER8_ANALYTICS_ORGANIZATION%"
DEL start-distributed-analytics.cmd

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/remote-installation/separate-scripts/start-feder8-studio.cmd --output start-feder8-studio.cmd
CALL .\start-feder8-studio.cmd "%FEDER8_THERAPEUTIC_AREA%" "%FEDER8_EMAIL_ADDRESS%" "%FEDER8_CLI_SECRET%" "%FEDER8_HOST_MACHINE%" "%FEDER8_STUDIO_FOLDER%" "%FEDER8_ANALYTICS_SHARED_FOLDER%" "%FEDER8_SECURITY_METHOD%" "%FEDER8_SECURITY_LDAP_URL%" "%FEDER8_SECURITY_LDAP_SYSTEM_USERNAME%" "%FEDER8_SECURITY_LDAP_SYSTEM_PASSWORD%" "%FEDER8_SECURITY_LDAP_BASE_DN%" "%FEDER8_SECURITY_LDAP_DN%"
DEL start-feder8-studio.cmd

if "%FEDER8_SECURITY_METHOD%" NEQ "none" (
    curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/remote-installation/separate-scripts/start-user-management.cmd --output start-user-management.cmd
    CALL .\start-user-management.cmd "%FEDER8_THERAPEUTIC_AREA%" "%FEDER8_EMAIL_ADDRESS%" "%FEDER8_CLI_SECRET%" "%FEDER8_USERMGMT_ADMIN_USERNAME%" "%FEDER8_USERMGMT_ADMIN_PASSWORD%"
    DEL start-user-management.cmd
)

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/remote-installation/separate-scripts/start-nginx.cmd --output start-nginx.cmd
CALL .\start-nginx.cmd "%FEDER8_THERAPEUTIC_AREA%" "%FEDER8_EMAIL_ADDRESS%" "%FEDER8_CLI_SECRET%"
DEL start-nginx.cmd

echo postgresql is available on %FEDER8_HOST_MACHINE%:5444
echo Atlas/WebAPI is available on http://%FEDER8_HOST_MACHINE%/atlas and http://%FEDER8_HOST_MACHINE%/webapi respectively
echo Zeppelin is available on http://%FEDER8_HOST_MACHINE%/zeppelin
echo Zeppelin logs are available in directory %FEDER8_ZEPPELIN_LOGS%
echo Zeppelin notebooks are available in directory %FEDER8_ZEPPELIN_NOTEBOOKS%
IF "%FEDER8_SECURITY_METHOD%" NEQ "none" echo User Management is available on http://%FEDER8_HOST_MACHINE%/user-mgmt
echo HONEUR Studio VSCode is available on http://%FEDER8_HOST_MACHINE%/%FEDER8_THERAPEUTIC_AREA%-studio/app/vscode
echo HONEUR Studio RStudio is available on http://%FEDER8_HOST_MACHINE%/%FEDER8_THERAPEUTIC_AREA%-studio/app/rstudio
echo HONEUR Studio local Shiny apps are available on http://%FEDER8_HOST_MACHINE%/%FEDER8_THERAPEUTIC_AREA%-studio/app/reports
echo HONEUR Studio documents is available on http://%FEDER8_HOST_MACHINE%/%FEDER8_THERAPEUTIC_AREA%-studio/app/documents
echo HONEUR Studio personal space is available on http://%FEDER8_HOST_MACHINE%/%FEDER8_THERAPEUTIC_AREA%-studio/app/personal
EXIT /B %ERRORLEVEL%

:generate-random-password
@echo off
Setlocal EnableDelayedExpansion
Set _RNDLength=16
Set _Alphanumeric=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789
Set _Str=%_Alphanumeric%987654321
:_LenLoop
IF NOT "%_Str:~18%"=="" SET _Str=%_Str:~9%& SET /A _Len+=9& GOTO :_LenLoop
SET _tmp=%_Str:~9,1%
SET /A _Len=_Len+_tmp
Set _count=0
SET _RndAlphaNum=
:_loop
Set /a _count+=1
SET _RND=%Random%
Set /A _RND=_RND%%%_Len%
SET _RndAlphaNum=!_RndAlphaNum!!_Alphanumeric:~%_RND%,1!
If !_count! lss %_RNDLength% goto _loop
ENDLOCAL & SET %~1=%_RndAlphaNum%
EXIT /B 0