docker stop etl
docker rm etl

curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/RunETL12doctubre/docker-compose.yml --output docker-compose.yml

read -p "Input Data folder [./data]: " data_folder
data_folder=${data_folder:-./data}
read -p "DB username [honeur_admin]: " db_username
db_username=${db_username:-honeur_admin}
read -p "DB password [honeur_admin]: " db_password
db_password=${db_password:-honeur_admin}
read -p "Output verbosity level [INFO]: " verbosity_level
verbosity_level=${verbosity_level:-INFO}
read -p "Docker Hub image tag: " image_tag

sed -i -e "s@data_folder@$data_folder@g" docker-compose.yml
sed -i -e "s/db_username/$db_username/g" docker-compose.yml
sed -i -e "s/db_password/$db_password/g" docker-compose.yml
sed -i -e "s/verbosity_level/$verbosity_level/g" docker-compose.yml
sed -i -e "s/image_tag/$image_tag/g" docker-compose.yml

docker login
docker-compose run --rm etl
