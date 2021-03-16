@echo off

SET VERSION=2.0.1
SET TAG=9.6-omopcdm-5.3.1-webapi-2.7.1-%VERSION%

set argumentCount=0
for %%x in (%*) do (
    set /A argumentCount+=1
    set "argVec[!argumentCount!]=%%~x"
)

if "%~1" NEQ "" (
    if "%argumentCount%" LSS "5" (
        echo Give all arguments or none to use the interactive script.
        EXIT 1
    )
    SET "FEDER8_THERAPEUTIC_AREA=%~1"
    SET "FEDER8_EMAIL_ADDRESS=%~2"
    SET "FEDER8_CLI_SECRET=%~3"
    SET "FEDER8_USER_PW=%~4"
    SET "FEDER8_ADMIN_USER_PW=%~5"
    goto installation
)

CALL :generate-random-password FEDER8_USER_PW
CALL :generate-random-password FEDER8_ADMIN_USER_PW

SET /p FEDER8_USER_PW="Enter password for %FEDER8_THERAPEUTIC_AREA% database user [%FEDER8_USER_PW%]: " || SET FEDER8_USER_PW=%FEDER8_USER_PW%
SET /p FEDER8_ADMIN_USER_PW="Enter password for %FEDER8_THERAPEUTIC_AREA%_admin database user [%FEDER8_ADMIN_USER_PW%]: " || SET FEDER8_ADMIN_USER_PW=%FEDER8_ADMIN_USER_PW%

:installation

echo This script will install version 2.0.1 of the %FEDER8_THERAPEUTIC_AREA% database. All %FEDER8_THERAPEUTIC_AREA% docker containers will be restarted after running this script.

echo. 2>postgres.env

echo HONEUR_USER_USERNAME=%FEDER8_THERAPEUTIC_AREA%> postgres.env
echo HONEUR_USER_PW=%FEDER8_USER_PW%>> postgres.env
echo HONEUR_ADMIN_USER_USERNAME=%FEDER8_THERAPEUTIC_AREA%_admin>> postgres.env
echo HONEUR_ADMIN_USER_PW=%FEDER8_ADMIN_USER_PW%>> postgres.env

echo Stop and remove postgres container if exists
docker stop postgres >nul 2>&1
docker rm postgres >nul 2>&1

echo Removing existing helper volumes
docker volume rm shared >nul 2>&1

echo Create %FEDER8_THERAPEUTIC_AREA%-net network if it does not exists
docker network create --driver bridge %FEDER8_THERAPEUTIC_AREA%-net >nul 2>&1

echo Pull %FEDER8_THERAPEUTIC_AREA%/postgres:%TAG% from https://%FEDER8_THERAPEUTIC_AREA_URL%. This could take a while if not present on machine
docker login https://%FEDER8_THERAPEUTIC_AREA_URL% --username %FEDER8_EMAIL_ADDRESS% --password %FEDER8_CLI_SECRET%
docker pull %FEDER8_THERAPEUTIC_AREA_URL%/%FEDER8_THERAPEUTIC_AREA%/postgres:%TAG%

echo Creating helper volumes
docker volume create shared >nul 2>&1
docker volume create pgdata >nul 2>&1

echo Run %FEDER8_THERAPEUTIC_AREA%/postgres:%TAG% container. This could take a while...
docker run ^
--name "postgres" ^
-p "5444:5432" ^
--env-file postgres.env ^
--restart on-failure:5 ^
--security-opt no-new-privileges ^
-v "pgdata:/var/lib/postgresql/data" ^
-v "shared:/var/lib/postgresql/envfileshared" ^
-m "2g" ^
--cpus "2" ^
--pids-limit 100 ^
--cpu-shares 1024 ^
--ulimit nofile=1024:1024 ^
-d ^
%FEDER8_THERAPEUTIC_AREA_URL%/%FEDER8_THERAPEUTIC_AREA%/postgres:%TAG% >nul 2>&1

echo Connect postgres to %FEDER8_THERAPEUTIC_AREA%-net network
docker network connect %FEDER8_THERAPEUTIC_AREA%-net postgres >nul 2>&1

echo Clean up helper files
DEL /Q postgres.env

echo Done

echo Restarting %FEDER8_THERAPEUTIC_AREA% Components
docker restart webapi >nul 2>&1
docker restart user-mgmt >nul 2>&1
docker restart zeppelin >nul 2>&1
docker restart %FEDER8_THERAPEUTIC_AREA%-studio >nul 2>&1
docker restart %FEDER8_THERAPEUTIC_AREA%-studio-chronicle >nul 2>&1

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