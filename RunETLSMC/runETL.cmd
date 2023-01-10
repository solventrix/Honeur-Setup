@echo off

set "data_folder=./data"
set /p "data_folder=Input Data folder [%data_folder%]: "

set "db_schema=omopcdm"
set /p "db_schema=DB schema [%db_schema%]: "

set "db_username=honeur_admin"
set /p "db_username=DB username [%db_username%]: "

set "db_password="
set /p "db_password=DB password [%db_password%]: "

set "source_delimiter=,"
set /p "source_delimiter=Source data delimiter [%source_delimiter%]: "

set "file_name_demographics=demographics.csv"
set /p "file_name_demographics=Source file name - demographics [%file_name_demographics%]: "

set "file_name_disease_admission=disease_admission.csv"
set /p "file_name_disease_admission=Source file name - disease admission [%file_name_disease_admission%]: "

set "file_name_disease_ambulatory=disease_ambulatory.csv"
set /p "file_name_disease_ambulatory=Source file name - disease ambulatory [%file_name_disease_ambulatory%]: "

set "file_name_disease_char=disease_characteristics_myeloma.csv"
set /p "file_name_disease_char=Source file name - disease characteristics myeloma [%file_name_disease_char%]: "

set "file_name_disease_chronic=disease_chronicdiagnosis.csv"
set /p "file_name_disease_chronic=Source file name - disease chronic diagnosis [%file_name_disease_chronic%]: "

set "file_name_disease_hema=disease_hematodiagnosis.csv"
set /p "file_name_disease_hema=Source file name - disease hemato diagnosis [%file_name_disease_hema%]: "

set "file_name_lab_cytogenetics=lab_data_cytogenetics.csv"
set /p "file_name_lab_cytogenetics=Source file name - lab data cytogenetics [%file_name_lab_cytogenetics%]: "

set "file_name_lab_fish=lab_data_fish.csv"
set /p "file_name_lab_fish=Source file name - lab data fish [%file_name_lab_fish%]: "

set "file_name_lab_test_1015=lab_data_test2010_2015.csv"
set /p "file_name_lab_test_1015=Source file name - lab data test 2010 - 2015 [%file_name_lab_test_1015%]: "

set "file_name_lab_test_1618=lab_data_test2016_2018.csv"
set /p "file_name_lab_test_1618=Source file name - lab data test 2016 - 2018 [%file_name_lab_test_1618%]: "

set "file_name_lab_test_1920=lab_data_test2019_2020.csv"
set /p "file_name_lab_test_1920=Source file name - lab data test 2019 - 2020 [%file_name_lab_test_1920%]: "

set "file_name_lab_test_2122=lab_data_test2021_2022.csv"
set /p "file_name_lab_test_2122=Source file name - lab data test 2021 - 2022 [%file_name_lab_test_2122%]: "

set "file_name_treatment_cato=treatment_cato.csv"
set /p "file_name_treatment_cato=Source file name - treatment cato [%file_name_treatment_cato%]: "

set "file_name_treatment_map=treatment_map.csv"
set /p "file_name_treatment_map=Source file name - treatment map [%file_name_treatment_map%]: "

set "file_name_treatment_medication=treatment_medication.csv"
set /p "file_name_treatment_medication=Source file name - treatment medication [%file_name_treatment_medication%]: "

set "encoding_demographics=Windows-1255"
set /p "encoding_demographics=File encoding - demographics [%encoding_demographics%]: "

set "encoding_disease_admission=Windows-1255"
set /p "encoding_disease_admission=File encoding - disease admission [%encoding_disease_admission%]: "

set "encoding_disease_ambulatory=Windows-1255"
set /p "encoding_disease_ambulatory=File encoding - disease ambulatory [%encoding_disease_ambulatory%]: "

set "encoding_disease_char=Windows-1255"
set /p "encoding_disease_char=File encoding - disease characteristics myeloma [%encoding_disease_char%]: "

set "encoding_disease_chronic=Windows-1255"
set /p "encoding_disease_chronic=File encoding - disease chronic diagnosis [%encoding_disease_chronic%]: "

set "encoding_disease_hema=Windows-1255"
set /p "encoding_disease_hema=File encoding - disease hemato diagnosis [%encoding_disease_hema%]: "

set "encoding_lab_cytogenetics=Windows-1255"
set /p "encoding_lab_cytogenetics=File encoding - lab data cytogenetics[%encoding_lab_cytogenetics%]: "

set "encoding_lab_fish=Windows-1255"
set /p "encoding_lab_fish=File encoding - lab data fish [%encoding_lab_fish%]: "

set "encoding_lab_test_1015=Windows-1255"
set /p "encoding_lab_test_1015=File encoding - lab data test 2010 - 2015 [%encoding_lab_test_1015%]: "

set "encoding_lab_test_1618=Windows-1255"
set /p "encoding_lab_test_1618=File encoding - lab data test 2016 - 2018 [%encoding_lab_test_1618%]: "

set "encoding_lab_test_1920=Windows-1255"
set /p "encoding_lab_test_1920=File encoding - lab data test 2019 - 2020 [%encoding_lab_test_1920%]: "

set "encoding_lab_test_2122=Windows-1255"
set /p "encoding_lab_test_2122=File encoding - lab data test 2021 - 2022 [%encoding_lab_test_2122%]: "

set "encoding_treatment_cato=Windows-1255"
set /p "encoding_treatment_cato=File encoding - treatment cato [%encoding_treatment_cato%]: "

set "encoding_treatment_map=Windows-1255"
set /p "encoding_treatment_map=File encoding - treatment map [%encoding_treatment_map%]: "

set "encoding_treatment_medication=Windows-1255"
set /p "encoding_treatment_medication=File encoding - treatment medication [%encoding_treatment_medication%]: "

set "verbosity_level=INFO"
set /p "verbosity_level=Output verbosity level [%verbosity_level%]: "

set "image_tag=current"
set /p "image_tag=Docker Hub image tag [%image_tag%]: "

set "date_last_export=2022-10-01"
set /p "date_last_export=Date of last export yyyy-mm-dd [%date_last_export%]: "

curl -L https://raw.githubusercontent.com/solventrix/Honeur-Setup/master/RunETLSMC/docker-compose.yml --output docker-compose.yml

powershell -Command "(Get-Content docker-compose.yml) -creplace 'data_folder', '%data_folder%' | Set-Content docker-compose.yml"
powershell -Command "(Get-Content docker-compose.yml) -creplace 'db_schema', '%db_schema%' | Set-Content docker-compose.yml"
powershell -Command "(Get-Content docker-compose.yml) -creplace 'db_username', '%db_username%' | Set-Content docker-compose.yml"
powershell -Command "(Get-Content docker-compose.yml) -creplace 'db_password', '%db_password%' | Set-Content docker-compose.yml"
powershell -Command "(Get-Content docker-compose.yml) -creplace 'source_delimiter', '''%source_delimiter%''' | Set-Content docker-compose.yml"
powershell -Command "(Get-Content docker-compose.yml) -creplace 'file_name_demographics', '%file_name_demographics%' | Set-Content docker-compose.yml"
powershell -Command "(Get-Content docker-compose.yml) -creplace 'file_name_disease_admission', '%file_name_disease_admission%' | Set-Content docker-compose.yml"
powershell -Command "(Get-Content docker-compose.yml) -creplace 'file_name_disease_ambulatory', '%file_name_disease_ambulatory%' | Set-Content docker-compose.yml"
powershell -Command "(Get-Content docker-compose.yml) -creplace 'file_name_disease_char', '%file_name_disease_char%' | Set-Content docker-compose.yml"
powershell -Command "(Get-Content docker-compose.yml) -creplace 'file_name_disease_chronic', '%file_name_disease_chronic%' | Set-Content docker-compose.yml"
powershell -Command "(Get-Content docker-compose.yml) -creplace 'file_name_disease_hema', '%file_name_disease_hema%' | Set-Content docker-compose.yml"
powershell -Command "(Get-Content docker-compose.yml) -creplace 'file_name_lab_cytogenetics', '%file_name_lab_cytogenetics%' | Set-Content docker-compose.yml"
powershell -Command "(Get-Content docker-compose.yml) -creplace 'file_name_lab_fish', '%file_name_lab_fish%' | Set-Content docker-compose.yml"
powershell -Command "(Get-Content docker-compose.yml) -creplace 'file_name_lab_test_1015', '%file_name_lab_test_1015%' | Set-Content docker-compose.yml"
powershell -Command "(Get-Content docker-compose.yml) -creplace 'file_name_lab_test_1618', '%file_name_lab_test_1618%' | Set-Content docker-compose.yml"
powershell -Command "(Get-Content docker-compose.yml) -creplace 'file_name_lab_test_1920', '%file_name_lab_test_1920%' | Set-Content docker-compose.yml"
powershell -Command "(Get-Content docker-compose.yml) -creplace 'file_name_lab_test_2122', '%file_name_lab_test_2122%' | Set-Content docker-compose.yml"
powershell -Command "(Get-Content docker-compose.yml) -creplace 'file_name_treatment_cato', '%file_name_treatment_cato%' | Set-Content docker-compose.yml"
powershell -Command "(Get-Content docker-compose.yml) -creplace 'file_name_treatment_map', '%file_name_treatment_map%' | Set-Content docker-compose.yml"
powershell -Command "(Get-Content docker-compose.yml) -creplace 'file_name_treatment_medication', '%file_name_treatment_medication%' | Set-Content docker-compose.yml"
powershell -Command "(Get-Content docker-compose.yml) -creplace 'encoding_demographics', '%encoding_demographics%' | Set-Content docker-compose.yml"
powershell -Command "(Get-Content docker-compose.yml) -creplace 'encoding_disease_admission', '%encoding_disease_admission%' | Set-Content docker-compose.yml"
powershell -Command "(Get-Content docker-compose.yml) -creplace 'encoding_disease_ambulatory', '%encoding_disease_ambulatory%' | Set-Content docker-compose.yml"
powershell -Command "(Get-Content docker-compose.yml) -creplace 'encoding_disease_char', '%encoding_disease_char%' | Set-Content docker-compose.yml"
powershell -Command "(Get-Content docker-compose.yml) -creplace 'encoding_disease_chronic', '%encoding_disease_chronic%' | Set-Content docker-compose.yml"
powershell -Command "(Get-Content docker-compose.yml) -creplace 'encoding_disease_hema', '%encoding_disease_hema%' | Set-Content docker-compose.yml"
powershell -Command "(Get-Content docker-compose.yml) -creplace 'encoding_lab_cytogenetics', '%encoding_lab_cytogenetics%' | Set-Content docker-compose.yml"
powershell -Command "(Get-Content docker-compose.yml) -creplace 'encoding_lab_fish', '%encoding_lab_fish%' | Set-Content docker-compose.yml"
powershell -Command "(Get-Content docker-compose.yml) -creplace 'encoding_lab_test_1015', '%encoding_lab_test_1015%' | Set-Content docker-compose.yml"
powershell -Command "(Get-Content docker-compose.yml) -creplace 'encoding_lab_test_1618', '%encoding_lab_test_1618%' | Set-Content docker-compose.yml"
powershell -Command "(Get-Content docker-compose.yml) -creplace 'encoding_lab_test_1920', '%encoding_lab_test_1920%' | Set-Content docker-compose.yml"
powershell -Command "(Get-Content docker-compose.yml) -creplace 'encoding_lab_test_2122', '%encoding_lab_test_2122%' | Set-Content docker-compose.yml"
powershell -Command "(Get-Content docker-compose.yml) -creplace 'encoding_treatment_cato', '%encoding_treatment_cato%' | Set-Content docker-compose.yml"
powershell -Command "(Get-Content docker-compose.yml) -creplace 'encoding_treatment_map', '%encoding_treatment_map%' | Set-Content docker-compose.yml"
powershell -Command "(Get-Content docker-compose.yml) -creplace 'encoding_treatment_medication', '%encoding_treatment_medication%' | Set-Content docker-compose.yml"
powershell -Command "(Get-Content docker-compose.yml) -creplace 'verbosity_level', '%verbosity_level%' | Set-Content docker-compose.yml"
powershell -Command "(Get-Content docker-compose.yml) -creplace 'image_tag', '%image_tag%' | Set-Content docker-compose.yml"
powershell -Command "(Get-Content docker-compose.yml) -creplace 'date_last_export', '%date_last_export%' | Set-Content docker-compose.yml"

docker login harbor.honeur.org
docker-compose pull
docker-compose run --rm --name etl etl
