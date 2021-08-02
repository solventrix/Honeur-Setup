@echo off

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/remote-installation/separate-scripts/start-config-server.cmd --output start-config-server.cmd
CALL .\start-config-server.cmd
DEL start-config-server.cmd

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/remote-installation/separate-scripts/start-postgres.cmd --output start-postgres.cmd
CALL .\start-postgres.cmd
DEL start-postgres.cmd

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/remote-installation/separate-scripts/start-local-portal.cmd --output start-local-portal.cmd
CALL .\start-local-portal.cmd
DEL start-local-portal.cmd

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/remote-installation/separate-scripts/start-atlas-webapi.cmd --output start-atlas-webapi.cmd
CALL .\start-atlas-webapi.cmd
DEL start-atlas-webapi.cmd

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/remote-installation/separate-scripts/start-zeppelin.cmd --output start-zeppelin.cmd
CALL .\start-zeppelin.cmd
DEL start-zeppelin.cmd

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/remote-installation/separate-scripts/start-user-management.cmd --output start-user-management.cmd
CALL .\start-user-management.cmd
DEL start-user-management.cmd

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/remote-installation/separate-scripts/start-distributed-analytics.cmd --output start-distributed-analytics.cmd
CALL .\start-distributed-analytics.cmd
DEL start-distributed-analytics.cmd

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/remote-installation/separate-scripts/start-feder8-studio.cmd --output start-feder8-studio.cmd
CALL .\start-feder8-studio.cmd
DEL start-feder8-studio.cmd

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/remote-installation/separate-scripts/start-nginx.cmd --output start-nginx.cmd
CALL .\start-nginx.cmd
DEL start-nginx.cmd
