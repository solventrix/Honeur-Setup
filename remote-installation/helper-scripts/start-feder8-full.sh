curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/remote-installation/separate-scripts/start-config-server.sh --output start-config-server.sh
chmod +x start-config-server.sh
./start-config-server.sh
rm -rf start-config-server.sh

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/remote-installation/separate-scripts/start-postgres.sh --output start-postgres.sh
chmod +x start-postgres.sh
./start-postgres.sh
rm -rf start-postgres.sh

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/remote-installation/separate-scripts/start-local-portal.sh --output start-local-portal.sh
chmod +x start-local-portal.sh
./start-local-portal.sh
rm -rf start-local-portal.sh

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/remote-installation/separate-scripts/start-atlas-webapi.sh --output start-atlas-webapi.sh
chmod +x start-atlas-webapi.sh
./start-atlas-webapi.sh
rm -rf start-atlas-webapi.sh

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/remote-installation/separate-scripts/start-zeppelin.sh --output start-zeppelin.sh
chmod +x start-zeppelin.sh
./start-zeppelin.sh
rm -rf start-zeppelin.sh

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/remote-installation/separate-scripts/start-user-management.sh --output start-user-management.sh
chmod +x start-user-management.sh
./start-user-management.sh
rm -rf start-user-management.sh

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/remote-installation/separate-scripts/start-distributed-analytics.sh --output start-distributed-analytics.sh
chmod +x start-distributed-analytics.sh
./start-distributed-analytics.sh
rm -rf start-distributed-analytics.sh

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/remote-installation/separate-scripts/start-feder8-studio.sh --output start-feder8-studio.sh
chmod +x start-feder8-studio.sh
./start-feder8-studio.sh
rm -rf start-feder8-studio.sh

curl -fsSL https://raw.githubusercontent.com/solventrix/Honeur-Setup/develop/remote-installation/separate-scripts/start-nginx.sh --output start-nginx.sh
chmod +x start-nginx.sh
./start-nginx.sh
rm -rf start-nginx.sh
