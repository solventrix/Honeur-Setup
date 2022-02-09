docker rm -f run-etl-cllear
rm -rf ./CLLEAR

git clone https://github.com/solventrix/CLLEAR_SOURCE ./CLLEAR

curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/release/1.10/RunETLCLLEAR/docker-compose.yml --output docker-compose.yml

read -p "Input Data folder [./data]: " data_folder
data_folder=${data_folder:-./data}
read -p "DB username [honeur_admin]: " db_username
db_username=${db_username:-honeur_admin}
read -p "DB password [honeur_admin]: " db_password
db_password=${db_password:-honeur_admin}

sed -i -e "s@data_folder@$data_folder@g" docker-compose.yml
sed -i -e "s@db_username@$db_username@g" docker-compose.yml
sed -i -e "s@db_password@$db_password@g" docker-compose.yml

docker-compose up