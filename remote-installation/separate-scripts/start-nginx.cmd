@echo off

SET VERSION=2.0.0
SET TAG=%VERSION%

echo. 2>nginx.env

for /f "delims=" %%A in ('docker container inspect -f "{{.State.Running}}" webapi') do (
    if "%%A" == "true" (
        echo ATLAS_ENABLED=true>> nginx.env
        echo ATLAS_URL=/atlas>> nginx.env
    )
)

for /f "delims=" %%A in ('docker container inspect -f "{{.State.Running}}" zeppelin') do (
    if "%%A" == "true" (
        echo ZEPPELIN_ENABLED=true>> nginx.env
        echo ZEPPELIN_URL=/zeppelin/>> nginx.env
    )
)

for /f "delims=" %%A in ('docker container inspect -f "{{.State.Running}}" user-mgmt') do (
    if "%%A" == "true" (
        echo USER_MANAGEMENT_ENABLED=true>> nginx.env
        echo USER_MANAGEMENT_URL=/user-mgmt/>> nginx.env
    )
)

for /f "delims=" %%A in ('docker container inspect -f "{{.State.Running}}" honeur-studio') do (
    if "%%A" == "true" (
        echo HONEUR_STUDIO_ENABLED=true>> nginx.env
        echo RSTUDIO_URL=/honeur-studio/app/rstudio>> nginx.env
        echo VSCODE_URL=/honeur-studio/app/vscode>> nginx.env
        echo REPORTS_URL=/honeur-studio/app/reports>> nginx.env
        echo PERSONAL_URL=/honeur-studio/app/personal>> nginx.env
        echo DOCUMENTS_URL=/honeur-studio/app/documents>> nginx.env
    )
)

echo Stop and remove nginx container if exists
docker stop nginx > /dev/null >nul 2>&1
docker rm nginx > /dev/null >nul 2>&1

echo Create honeur-net network if it does not exists
docker network create --driver bridge honeur-net >nul 2>&1

echo Pull honeur/nginx:%TAG% from docker hub. This could take a while if not present on machine
docker pull honeur/nginx:%TAG%

echo Run honeur/nginx:%TAG% container. This could take a while...
docker run ^
--name "nginx" ^
-p "80:80" ^
--restart always ^
--security-opt no-new-privileges ^
--env-file nginx.env ^
--network honeur-net ^
-m "500m" ^
--cpus "1" ^
--pids-limit 100 ^
--cpu-shares 1024 ^
--ulimit nofile=1024:1024 ^
-d ^
honeur/nginx:%TAG% >nul 2>&1

echo Clean up helper files
DEL /Q nginx.env

echo Done