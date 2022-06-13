docker stop run-etl-uhl
docker rm run-etl-uhl

rm -rf ./UHL

git clone https://github.com/solventrix/UHL ./UHL

curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/release/1.10.1/RunETLUHL/docker-compose.yml --output docker-compose.yml

read -p "Input data folder [./UHL/UHL-ETL/input]: " data_folder
data_folder=${data_folder:-./UHL/UHL-ETL/input}
read -p "Input data file [HONEUR_EXTRACT_20200306.xlsx]: " data_file
data_file=${data_file:-HONEUR_EXTRACT_20200306.xlsx}
read -p "Input data sheet [Sheet1]: " data_sheet
data_sheet=${data_sheet:-Sheet1}
read -p "DB host [postgres]: " db_host
db_host=${db_host:-postgres}
read -p "DB port [5432]: " db_port
db_port=${db_port:-5432}
read -p "DB name [OHDSI]: " db_name
db_name=${db_name:-OHDSI}
read -p "DB username [honeur_admin]: " db_username
db_username=${db_username:-honeur_admin}
read -p "DB password [honeur_admin]: " db_password
db_password=${db_password:-honeur_admin}

sed -i -e "s@<data_folder>@$data_folder@g" docker-compose.yml
sed -i -e "s@<data_file>@$data_file@g" docker-compose.yml
sed -i -e "s@<data_sheet>@$data_sheet@g" docker-compose.yml
sed -i -e "s@<db_host>@$db_host@g" docker-compose.yml
sed -i -e "s@<db_port>@$db_port@g" docker-compose.yml
sed -i -e "s@<db_name>@$db_name@g" docker-compose.yml
sed -i -e "s@<db_username>@$db_username@g" docker-compose.yml
sed -i -e "s@<db_password>@$db_password@g" docker-compose.yml

docker-compose up