@echo off

SET VERSION=2.0.1
SET TAG=HONEUR-9.6-omopcdm-5.3.1-webapi-2.7.1-%VERSION%

set argumentCount=0
for %%x in (%*) do (
    set /A argumentCount+=1
    set "argVec[!argumentCount!]=%%~x"
)

if "%~1" NEQ "" (
    if "%argumentCount%" LSS "2" (
        echo Give all arguments or none to use the interactive script.
        EXIT 1
    )
    SET "HONEUR_USER_PW=%~1"
    SET "HONEUR_ADMIN_USER_PW=%~2"
    goto installation
)

CALL :generate-random-password HONEUR_USER_PW
CALL :generate-random-password HONEUR_ADMIN_USER_PW

SET /p HONEUR_USER_PW="Enter password for honeur database user [%HONEUR_USER_PW%]: " || SET HONEUR_USER_PW=%HONEUR_USER_PW%
SET /p HONEUR_ADMIN_USER_PW="Enter password for honeur admin database user [%HONEUR_ADMIN_USER_PW%]: " || SET HONEUR_ADMIN_USER_PW=%HONEUR_ADMIN_USER_PW%

:installation
echo. 2>postgres.env

echo HONEUR_USER_USERNAME=honeur> postgres.env
echo HONEUR_USER_PW=%HONEUR_USER_PW%>> postgres.env
echo HONEUR_ADMIN_USER_USERNAME=honeur_admin>> postgres.env
echo HONEUR_ADMIN_USER_PW=%HONEUR_ADMIN_USER_PW%>> postgres.env

echo Stop and remove postgres container if exists
docker stop postgres >nul 2>&1
docker rm postgres >nul 2>&1

echo Removing existing helper volumes
docker volume rm shared >nul 2>&1

echo Create honeur-net network if it does not exists
docker network create --driver bridge honeur-net >nul 2>&1

echo Pull honeur/postgres:%TAG% from docker hub. This could take a while if not present on machine
docker pull honeur/postgres:%TAG%

echo Creating helper volumes
docker volume create shared >nul 2>&1
docker volume create pgdata >nul 2>&1

echo Run honeur/postgres:%TAG% container. This could take a while...
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
honeur/postgres:%TAG% >nul 2>&1

echo Connect postgres to honeur-net network
docker network connect honeur-net postgres >nul 2>&1

echo Clean up helper files
DEL /Q postgres.env

echo Done
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