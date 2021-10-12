#!/usr/bin/env bash
set -e

BACKUP_FOLDER=${PWD}/backup
ZEPPELIN_FOLDER=${PWD}/backup/zeppelin
FEDER8_STUDIO_FOLDER=${PWD}/backup/feder8-studio
DISTRIBUTED_ANALYTICS_FOLDER=${PWD}/backup/distributed-analytics

mkdir -p ${BACKUP_FOLDER}

# Copy Zeppelin files to backup folder
echo "Backup Zeppelin files"
mkdir -p ${ZEPPELIN_FOLDER}
docker cp zeppelin:/notebook ${ZEPPELIN_FOLDER}
docker cp zeppelin:/logs ${ZEPPELIN_FOLDER}

# Copy distributed analytics files to backup folder
echo "Backup distributed analytics files"
mkdir -p ${DISTRIBUTED_ANALYTICS_FOLDER}
docker cp distributed-analytics-remote:/home/feder8/data ${DISTRIBUTED_ANALYTICS_FOLDER}

# Copy Feder8 Studio files to backup folder
echo "Backup Feder8 Studio files"
mkdir -p ${FEDER8_STUDIO_FOLDER}
docker cp honeur-studio:/opt/data ${FEDER8_STUDIO_FOLDER}

# Create tar.gz file
echo "Create backup tar.gz file under ${BACKUP_FOLDER}"
docker run --rm -v ${BACKUP_FOLDER}:/opt/backup alpine sh -c 'set -e; export CURRENT_TIME=$(date "+%Y-%m-%d_%H-%M-%S"); cd opt; tar -czf backup/file_backup_${CURRENT_TIME}.tar.gz backup'
