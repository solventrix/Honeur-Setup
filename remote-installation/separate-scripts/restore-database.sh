read -p "Enter the absolute file path of the database backup (.tar.gz): " DATABASE_BACKUP_FILE

CURRENT_TIME=$(date "+%Y_%m_%d_%H_%M_%S")
RESTORE_FOLDER=${PWD}/restore/${CURRENT_TIME}

mkdir -p ${RESTORE_FOLDER}

export LANG=en_US.UTF-8
export LC_ALL=$LANG
tar -C ${RESTORE_FOLDER} -zxvf ${DATABASE_BACKUP_FILE}

for sql_script in ${RESTORE_FOLDER}/*.sql; do
    sql_script_name=$(basename -- "$sql_script")
    DB_NAME="${sql_script_name%%.*}"
    echo "Restore database $DB_NAME"
    cat $sql_script | docker exec -i postgres bash -c "source /var/lib/postgresql/envfile/honeur.env; export PGPASSWORD=${POSTGRES_PW}; psql $DB_NAME -U postgres"
done
