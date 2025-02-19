if [ $(docker ps --filter "name=etl" | grep -w 'etl' | wc -l) = 1 ]; then
  docker stop -t 1 etl && docker rm etl;
fi

curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/RunETLTherapyMonitor_OIS/docker-compose.yml --output docker-compose.yml

read -p "Input Data folder [./data]: " data_folder
data_folder=${data_folder:-./data}
read -p "Filename [TM_MM_DE_OIS_OMOP_Testdata.csv]: " filename
filename=${filename:-TM_MM_DE_OIS_OMOP_Testdata.csv}
read -p "DB username [feder8_admin]: " db_username
db_username=${db_username:-feder8_admin}
read -p "DB password [feder8_admin]: " db_password
db_password=${db_password:-feder8_admin}
read -p "Output verbosity level [INFO]: " verbosity_level
verbosity_level=${verbosity_level:-INFO}
read -p "Docker Hub image tag [current]: " image_tag
image_tag=${image_tag:-current}

sed -i -e "s@data_folder@$data_folder@g" docker-compose.yml
sed -i -e "s/db_username/$db_username/g" docker-compose.yml
sed -i -e "s/db_password/$db_password/g" docker-compose.yml
sed -i -e "s/verbosity_level/$verbosity_level/g" docker-compose.yml
sed -i -e "s/image_tag/$image_tag/g" docker-compose.yml
sed -i -e "s/filename/$filename/g" docker-compose.yml

docker exec -it postgres psql -U postgres -d OHDSI -c "
ALTER TABLE omopcdm.cost DROP CONSTRAINT IF EXISTS xpk_visit_cost;
ALTER TABLE omopcdm.cost DROP CONSTRAINT IF EXISTS xpk_cost;"

docker exec -it postgres psql -U postgres -d OHDSI -c "
ALTER TABLE omopcdm.cohort_definition DROP CONSTRAINT IF EXISTS xpk_cohort_definition;
ALTER TABLE omopcdm.cohort_definition ADD CONSTRAINT xpk_cohort_definition PRIMARY KEY (cohort_definition_id);"

docker exec -it postgres psql -U postgres -d OHDSI -c "
ALTER TABLE omopcdm.attribute_definition DROP CONSTRAINT IF EXISTS xpk_attribute_definition;
ALTER TABLE omopcdm.attribute_definition ADD CONSTRAINT xpk_attribute_definition PRIMARY KEY (attribute_definition_id);"

docker login harbor.honeur.org
docker compose pull
docker compose run --rm -d --name etl etl
