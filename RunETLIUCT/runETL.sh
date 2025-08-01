if [ $(docker ps --filter "name=etl" | grep -w 'etl' | wc -l) = 1 ]; then
  docker stop -t 1 etl && docker rm etl;
fi

curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/RunETLIUCT/docker-compose.yml --output docker-compose.yml

read -p "Input Data folder [./data]: " data_folder
data_folder=${data_folder:-./data}
read -p "CDM schema [omopcdm]: " db_schema
db_schema=${db_schema:-omopcdm}
read -p "Vocabulary schema [omopcdm]: " vocab_schema
vocab_schema=${vocab_schema:-omopcdm}
read -p "DB username [honeur_admin]: " db_username
db_username=${db_username:-honeur_admin}
read -p "DB password: " db_password
read -p "Source file [EXTRACT_2022-04-25.xlsx]: " source_file
source_file=${source_file:-EXTRACT_2022-04-25.xlsx}
read -p "Output verbosity level [INFO]: " verbosity_level
verbosity_level=${verbosity_level:-INFO}
read -p "Docker Hub image tag [current]: " image_tag
image_tag=${image_tag:-current}
read -p "Date of last export yyyy-mm-dd [\"2022-04-01\"]: " date_last_export
date_last_export=${date_last_export:-\"2022-04-01\"}

sed -i -e "s@data_folder@$data_folder@g" docker-compose.yml
sed -i -e "s/db_schema/$db_schema/g" docker-compose.yml
sed -i -e "s/vocab_schema/$vocab_schema/g" docker-compose.yml
sed -i -e "s/db_username/$db_username/g" docker-compose.yml
sed -i -e "s/db_password/$db_password/g" docker-compose.yml
sed -i -e "s/source_file/$source_file/g" docker-compose.yml
sed -i -e "s/verbosity_level/$verbosity_level/g" docker-compose.yml
sed -i -e "s/image_tag/$image_tag/g" docker-compose.yml
sed -i -e "s/date_last_export/$date_last_export/g" docker-compose.yml

docker login harbor.honeur.org
docker compose pull
docker compose run --rm --name etl etl
