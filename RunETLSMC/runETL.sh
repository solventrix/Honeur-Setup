if [ $(docker ps --filter "name=etl" | grep -w 'etl' | wc -l) = 1 ]; then
  docker stop -t 1 etl && docker rm etl;
fi

curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/RunETLSMC/docker-compose.yml --output docker-compose.yml

read -p "Input Data folder [./data]: " data_folder
data_folder=${data_folder:-./data}

read -p "DB schema [omopcdm]: " db_schema
db_schema=${db_schema:-omopcdm}

read -p "DB username [feder8_admin]: " db_username
db_username=${db_username:-feder8_admin}

read -p "DB password: " db_password

read -p "Source data delimiter [\",\"]: " source_delimiter
source_delimiter=${source_delimiter:-\",\"}

read -p "Source file name - demographics [\"demographics.csv\"]: " file_name_demographics
file_name_demographics=${file_name_demographics:-\"demographics.csv\"}

read -p "Source file name - disease admission [\"disease_admission.csv\"]: " file_name_disease_admission
file_name_disease_admission=${file_name_disease_admission:-\"disease_admission.csv\"}

read -p "Source file name - disease ambulatory [\"disease_ambulatory.csv\"]: " file_name_disease_ambulatory
file_name_disease_ambulatory=${file_name_disease_ambulatory:-\"disease_ambulatory.csv\"}

read -p "Source file name - disease characteristics myeloma [\"disease_characteristics_myeloma.csv\"]: " file_name_disease_char
file_name_disease_char=${file_name_disease_char:-\"disease_characteristics_myeloma.csv\"}

read -p "Source file name - disease chronic diagnosis [\"disease_chronicdiagnosis.csv\"]: " file_name_disease_chronic
file_name_disease_chronic=${file_name_disease_chronic:-\"disease_chronicdiagnosis.csv\"}

read -p "Source file name - disease hemato diagnosis [\"disease_hematodiagnosis.csv\"]: " file_name_disease_hema
file_name_disease_hema=${file_name_disease_hema:-\"disease_hematodiagnosis.csv\"}

read -p "Source file name - lab data cytogenetics [\"lab_data_cytogenetics.csv\"]: " file_name_lab_cytogenetics
file_name_lab_cytogenetics=${file_name_lab_cytogenetics:-\"lab_data_cytogenetics.csv\"}

read -p "Source file name - lab data fish [\"lab_data_fish.csv\"]: " file_name_lab_fish
file_name_lab_fish=${file_name_lab_fish:-\"lab_data_fish.csv\"}

read -p "Source file name - lab data test [\"lab_data_test.csv\"]: " file_name_lab_test
file_name_lab_test=${file_name_lab_test:-\"lab_data_test.csv\"}

read -p "Source file name - treatment cato [\"treatment_cato.csv\"]: " file_name_treatment_cato
file_name_treatment_cato=${file_name_treatment_cato:-\"treatment_cato.csv\"}

read -p "Source file name - treatment map [\"treatment_map.csv\"]: " file_name_treatment_map
file_name_treatment_map=${file_name_treatment_map:-\"treatment_map.csv\"}

read -p "Source file name - treatment medication [\"treatment_medication.csv\"]: " file_name_treatment_medication
file_name_treatment_medication=${file_name_treatment_medication:-\"treatment_medication.csv\"}

read -p "Source file name - body measurements [\"body_measurements.csv\"]: " file_name_body_meas
file_name_body_meas=${file_name_body_meas:-\"body_measurements.csv\"}

read -p "Source file name - immunofixation [\"immunofixation.csv\"]: " file_name_immunofixation
file_name_immunofixation=${file_name_immunofixation:-\"immunofixation.csv\"}

read -p "File encoding - demographics [\"utf-8\"]: " encoding_demographics
encoding_demographics=${encoding_demographics:-\"utf-8\"}

read -p "File encoding - disease admission [\"utf-8\"]: " encoding_disease_admission
encoding_disease_admission=${encoding_disease_admission:-\"utf-8\"}

read -p "File encoding - disease ambulatory [\"utf-8\"]: " encoding_disease_ambulatory
encoding_disease_ambulatory=${encoding_disease_ambulatory:-\"utf-8\"}

read -p "File encoding - disease characteristics myeloma [\"utf-8\"]: " encoding_disease_char
encoding_disease_char=${encoding_disease_char:-\"utf-8\"}

read -p "File encoding - disease chronic diagnosis [\"utf-8\"]: " encoding_disease_chronic
encoding_disease_chronic=${encoding_disease_chronic:-\"utf-8\"}

read -p "File encoding - disease hemato diagnosis [\"utf-8\"]: " encoding_disease_hema
encoding_disease_hema=${encoding_disease_hema:-\"utf-8\"}

read -p "File encoding - lab data cytogenetics [\"utf-8\"]: " encoding_lab_cytogenetics
encoding_lab_cytogenetics=${encoding_lab_cytogenetics:-\"utf-8\"}

read -p "File encoding - lab data fish [\"utf-8\"]: " encoding_lab_fish
encoding_lab_fish=${encoding_lab_fish:-\"utf-8\"}

read -p "File encoding - lab data test [\"utf-8\"]: " encoding_lab_test
encoding_lab_test=${encoding_lab_test:-\"utf-8\"}

read -p "File encoding - treatment cato [\"utf-8\"]: " encoding_treatment_cato
encoding_treatment_cato=${encoding_treatment_cato:-\"utf-8\"}

read -p "File encoding - treatment map [\"utf-8\"]: " encoding_treatment_map
encoding_treatment_map=${encoding_treatment_map:-\"utf-8\"}

read -p "File encoding - treatment medication [\"utf-8\"]: " encoding_treatment_medication
encoding_treatment_medication=${encoding_treatment_medication:-\"utf-8\"}

read -p "File encoding - body measurements [\"utf-8\"]: " encoding_body_meas
encoding_body_meas=${encoding_body_meas:-\"utf-8\"}

read -p "File encoding - immunofixation [\"utf-8\"]: " encoding_immunofixation
encoding_immunofixation=${encoding_immunofixation:-\"utf-8\"}

read -p "Output verbosity level [INFO]: " verbosity_level
verbosity_level=${verbosity_level:-INFO}

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

sed -i -e "s/file_name_demographics/$file_name_demographics/g" docker-compose.yml
sed -i -e "s/file_name_disease_admission/$file_name_disease_admission/g" docker-compose.yml
sed -i -e "s/file_name_disease_ambulatory/$file_name_disease_ambulatory/g" docker-compose.yml
sed -i -e "s/file_name_disease_char/$file_name_disease_char/g" docker-compose.yml
sed -i -e "s/file_name_disease_chronic/$file_name_disease_chronic/g" docker-compose.yml
sed -i -e "s/file_name_disease_hema/$file_name_disease_hema/g" docker-compose.yml
sed -i -e "s/file_name_lab_cytogenetics/$file_name_lab_cytogenetics/g" docker-compose.yml
sed -i -e "s/file_name_lab_fish/$file_name_lab_fish/g" docker-compose.yml
sed -i -e "s/file_name_lab_test/$file_name_lab_test/g" docker-compose.yml
sed -i -e "s/file_name_treatment_cato/$file_name_treatment_cato/g" docker-compose.yml
sed -i -e "s/file_name_treatment_map/$file_name_treatment_map/g" docker-compose.yml
sed -i -e "s/file_name_treatment_medication/$file_name_treatment_medication/g" docker-compose.yml
sed -i -e "s/file_name_body_meas/$file_name_body_meas/g" docker-compose.yml
sed -i -e "s/file_name_immunofixation/$file_name_immunofixation/g" docker-compose.yml

sed -i -e "s/encoding_demographics/$encoding_demographics/g" docker-compose.yml
sed -i -e "s/encoding_disease_admission/$encoding_disease_admission/g" docker-compose.yml
sed -i -e "s/encoding_disease_ambulatory/$encoding_disease_ambulatory/g" docker-compose.yml
sed -i -e "s/encoding_disease_char/$encoding_disease_char/g" docker-compose.yml
sed -i -e "s/encoding_disease_chronic/$encoding_disease_chronic/g" docker-compose.yml
sed -i -e "s/encoding_disease_hema/$encoding_disease_hema/g" docker-compose.yml
sed -i -e "s/encoding_lab_cytogenetics/$encoding_lab_cytogenetics/g" docker-compose.yml
sed -i -e "s/encoding_lab_fish/$encoding_lab_fish/g" docker-compose.yml
sed -i -e "s/encoding_lab_test/$encoding_lab_test/g" docker-compose.yml
sed -i -e "s/encoding_treatment_cato/$encoding_treatment_cato/g" docker-compose.yml
sed -i -e "s/encoding_treatment_map/$encoding_treatment_map/g" docker-compose.yml
sed -i -e "s/encoding_treatment_medication/$encoding_treatment_medication/g" docker-compose.yml
sed -i -e "s/encoding_body_meas/$encoding_body_meas/g" docker-compose.yml
sed -i -e "s/encoding_immunofixation/$encoding_immunofixation/g" docker-compose.yml

sed -i -e "s/verbosity_level/$verbosity_level/g" docker-compose.yml
sed -i -e "s/image_tag/$image_tag/g" docker-compose.yml
sed -i -e "s/date_last_export/$date_last_export/g" docker-compose.yml

docker login harbor.honeur.org
docker compose pull
docker compose run --rm --name etl etl
