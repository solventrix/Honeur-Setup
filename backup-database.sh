#!/bin/bash
date_time=`date +"%m-%d-%Y_%H%M%S"`
backup_file_name="postgres_backup_${date_time}.tar.bz2"
echo "Please be patient, this backup will take a while"
docker run -v pgdata:/volume --rm loomchild/volume-backup backup - > ${backup_file_name}
echo "Backup executed successfully.  You can find the backup file '${backup_file_name}' in the current folder."
