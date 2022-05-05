if [ $(docker ps --filter "name=etl" | grep -w 'etl' | wc -l) = 1 ]; then
  docker stop -t 1 etl && docker rm etl;
fi

curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/RunETLCCL/docker-compose.yml --output docker-compose.yml

read -p "Source server [172.19.4.246]: " source_server
source_server=${source_server:-172.19.4.246}
read -p "Source server port [1433]: " source_port
source_port=${source_port:-1433}
read -p "Source database [TeleoPCSReport]: " source_database
source_database=${source_database:-TeleoPCSReport}
read -p "Source username [MyelomaHONEUR]: " source_username
source_username=${source_username:-MyelomaHONEUR}
read -p "Source password: " source_password
read -p "Target server [postgres]: " target_server
target_server=${target_server:-postgres}
read -p "Target server port [5432]: " target_port
target_port=${target_port:-5432}
read -p "Target database [OHDSI]: " target_database
target_database=${target_database:-OHDSI}
read -p "Target schema [omopcdm]: " target_schema
target_schema=${target_schema:-omopcdm}
read -p "Target username [honeur_admin]: " target_username
target_username=${target_username:-honeur_admin}
read -p "Target password: " target_password
read -p "Output verbosity level [INFO]: " verbosity_level
verbosity_level=${verbosity_level:-INFO}
read -p "Docker Hub image tag [current]: " image_tag
image_tag=${image_tag:-current}

sed -i -e "s/source_server/$source_server/g" docker-compose.yml
sed -i -e "s/source_port/$source_port/g" docker-compose.yml
sed -i -e "s/source_database/$source_database/g" docker-compose.yml
sed -i -e "s/source_username/$source_username/g" docker-compose.yml
sed -i -e "s/source_password/$source_password/g" docker-compose.yml
sed -i -e "s/target_server/$target_server/g" docker-compose.yml
sed -i -e "s/target_port/$target_port/g" docker-compose.yml
sed -i -e "s/target_database/$target_database/g" docker-compose.yml
sed -i -e "s/target_schema/$target_schema/g" docker-compose.yml
sed -i -e "s/target_username/$target_username/g" docker-compose.yml
sed -i -e "s/target_password/$target_password/g" docker-compose.yml
sed -i -e "s/verbosity_level/$verbosity_level/g" docker-compose.yml
sed -i -e "s/image_tag/$image_tag/g" docker-compose.yml

docker login harbor.honeur.org
docker-compose pull
docker-compose run --rm --name etl etl
