if [ $(docker ps --filter "name=etl" | grep -w 'etl' | wc -l) = 1 ]; then
  docker stop -t 1 etl && docker rm etl;
fi

#curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/RunETLLille/docker-compose.yml --output docker-compose.yml

read -p "Input Data folder [./data]: " data_folder
data_folder=${data_folder:-./data}
read -p "DB schema [omopcdm]: " db_schema
db_schema=${db_schema:-omopcdm}
read -p "DB username [honeur_admin]: " db_username
db_username=${db_username:-honeur_admin}
read -p "DB password: " db_password
read -p "Source data delimiter [\",\"]: " source_delimiter
source_delimiter=${source_delimiter:-\",\"}
read -p "Source encoding [\"utf-8\"]: " source_encoding
source_encoding=${source_encoding:-\"utf-8\"}
read -p "Output verbosity level [INFO]: " verbosity_level
verbosity_level=${verbosity_level:-INFO}
read -p "Display all unmapped drugs: " all_unmapped_drugs
all_unmapped_drugs=${all_unmapped_drugs:-False}
read -p "Docker Hub image tag [current]: " image_tag
image_tag=${image_tag:-current}
until read -r -p "Date of last export yyyy-mm-dd: " date_last_export && test "$date_last_export" != ""; do
  continue
done

sed -i -e "s@data_folder@$data_folder@g" docker-compose.yml
sed -i -e "s/db_schema/$db_schema/g" docker-compose.yml
sed -i -e "s/db_username/$db_username/g" docker-compose.yml
sed -i -e "s/db_password/$db_password/g" docker-compose.yml
sed -i -e "s/source_delimiter/$source_delimiter/g" docker-compose.yml
sed -i -e "s/source_encoding/$source_encoding/g" docker-compose.yml
sed -i -e "s/verbosity_level/$verbosity_level/g" docker-compose.yml
sed -i -e "s/image_tag/$image_tag/g" docker-compose.yml
sed -i -e "s/date_last_export/$date_last_export/g" docker-compose.yml
sed -i -e "s/all_unmapped_drugs/$all_unmapped_drugs/g" docker-compose.yml

docker login harbor.honeur.org
docker-compose pull
docker-compose run --rm --name etl etl
