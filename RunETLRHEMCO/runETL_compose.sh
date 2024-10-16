#!/usr/bin/env bash
set -ex

if [ $(docker ps --filter "name=etl" | grep -w 'etl' | wc -l) = 1 ]; then
  docker stop -t 1 etl && docker rm etl;
fi

curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/RunETLRHEMCO/docker-compose.yml --output docker-compose.yml

read -p "Input Data folder [./data]: " data_folder
data_folder=${data_folder:-./data}
read -p "DB username [honeur_admin]: " db_username
db_username=${db_username:-honeur_admin}
read -p "DB password [honeur_admin]: " db_password
db_password=${db_password:-honeur_admin}
read -p "Output verbosity level [INFO]: " verbosity_level
verbosity_level=${verbosity_level:-INFO}
read -p "Docker Hub image tag [current]: " image_tag
image_tag=${image_tag:-current}
read -p "Molecule source file name [1_rhemco_21_tt_molecule_1980_2020.txt]: " mol_file
mol_file=${mol_file:-1_rhemco_21_tt_molecule_1980_2020.txt}
read -p "Hemo source file name [rhemco_21_hemo_1980_2020.txt]: " hemo_file
hemo_file=${hemo_file:-rhemco_21_hemo_1980_2020.txt}
read -p "Indiv source file name [rhemco_21_indiv_1980_2020.txt]: " indiv_file
indiv_file=${indiv_file:-rhemco_21_indiv_1980_2020.txt}
file_names="${mol_file}:${hemo_file}:${indiv_file}"
until read -r -p "Date of last export yyyy-mm-dd: " date_last_export && test "$date_last_export" != ""; do
  continue
done
until read -r -p "Date of last follow-up yyyy-mm-dd: " date_last_observation && test "$date_last_observation" != ""; do
  continue
done

sed -i -e "s@data_folder@$data_folder@g" docker-compose.yml
sed -i -e "s/db_username/$db_username/g" docker-compose.yml
sed -i -e "s/db_password/$db_password/g" docker-compose.yml
sed -i -e "s/verbosity_level/$verbosity_level/g" docker-compose.yml
sed -i -e "s/image_tag/$image_tag/g" docker-compose.yml
sed -i -e "s@file_names@$file_names@g" docker-compose.yml
sed -i -e "s@date_last_export@$date_last_export@g" docker-compose.yml
sed -i -e "s@date_last_observation@$date_last_observation@g" docker-compose.yml

docker login harbor.honeur.org
docker-compose pull
docker-compose run --rm --name etl etl
