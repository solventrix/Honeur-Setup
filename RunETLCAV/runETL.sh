if [ $(docker ps --filter "name=etl" | grep -w 'etl' | wc -l) = 1 ]; then
  docker stop -t 1 etl && docker rm etl;
fi

curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/RunETLCAV/docker-compose.yml --output docker-compose.yml

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
read -p "Date format [\"DD/MM/YYYY\"]: " etl_date_format
etl_date_format=${etl_date_format:-\"DD/MM/YYYY\"}
read -p "Source file name - patients [\"3_patients.csv\"]: " file_name_patients
file_name_patients=${file_name_patients:-\"3_patients.csv\"}
read -p "Source file name - appointments [\"1_appointments.csv\"]: " file_name_appointments
file_name_appointments=${file_name_appointments:-\"1_appointments.csv\"}
read -p "Source file name - treatments [\"2_treatments.csv\"]: " file_name_treatments
file_name_treatments=${file_name_treatments:-\"2_treatments.csv\"}
read -p "Source file name - pathology [\"0_pathologytests.csv\"]: " file_name_pathology
file_name_pathology=${file_name_pathology:-\"0_pathologytests.csv\"}
read -p "Output verbosity level [INFO]: " verbosity_level
verbosity_level=${verbosity_level:-INFO}
read -p "Docker Hub image tag [current]: " image_tag
image_tag=${image_tag:-current}
read -p "Date of last export yyyy-mm-dd [\"2022-10-01\"]: " date_last_export
date_last_export=${date_last_export:-\"2022-10-01\"}

sed -i -e "s@data_folder@$data_folder@g" docker-compose.yml
sed -i -e "s/db_schema/$db_schema/g" docker-compose.yml
sed -i -e "s/db_username/$db_username/g" docker-compose.yml
sed -i -e "s/db_password/$db_password/g" docker-compose.yml
sed -i -e "s/source_delimiter/$source_delimiter/g" docker-compose.yml
sed -i -e "s/source_encoding/$source_encoding/g" docker-compose.yml
sed -i -e "s/etl_date_format/$etl_date_format/g" docker-compose.yml
sed -i -e "s/file_name_patients/$file_name_patients/g" docker-compose.yml
sed -i -e "s/file_name_appointments/$file_name_appointments/g" docker-compose.yml
sed -i -e "s/file_name_treatments/$file_name_treatments/g" docker-compose.yml
sed -i -e "s/file_name_pathology/$file_name_pathology/g" docker-compose.yml
sed -i -e "s/verbosity_level/$verbosity_level/g" docker-compose.yml
sed -i -e "s/image_tag/$image_tag/g" docker-compose.yml
sed -i -e "s/date_last_export/$date_last_export/g" docker-compose.yml

docker login harbor.honeur.org
docker-compose pull
docker-compose run --rm --name etl etl
