#!/bin/sh
set -euo pipefail

echo "Configured to sync from ${SOURCE_FOLDER} to ${TARGET_GIT_URL}"
TARGET_FOLDER=/tmp/target
if [ -d ${TARGET_FOLDER} ]
then
    cd ${TARGET_FOLDER}
    git pull
else
    git clone ${TARGET_GIT_URL} ${TARGET_FOLDER}
    cd ${TARGET_FOLDER}
fi

sync() {
    rsync -av --chown root:root --delete --exclude=.git ${SOURCE_FOLDER}/ ${TARGET_FOLDER}
    if [ $(git status --porcelain | wc -l) -eq "0" ]; then
        echo "No changes to commit"
    else
        echo "Syncing changes to ${TARGET_GIT_URL}"
        git add .
        git commit -m "Sync from ${HOSTNAME}"
        git push
    fi
}

while true; do
    sync || echo "Sync failed"
    sleep 3600
done