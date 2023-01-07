#!/bin/sh
set -euo pipefail

TASK=${TASK:-sync}

while getopts "osr" option; do
    case $option in
        o)
            TASK=synconce
            ;;
        s)
            TASK=sync
            ;;
        r)
            TASK=restore
            ;;
        \?) # Invalid option
            echo "Error: Invalid option"
            exit
            ;;
   esac
done

echo "Configured to sync from ${SOURCE_FOLDER} to ${TARGET_GIT_URL}"
TARGET_FOLDER=/tmp/target
if [ ! -d ${TARGET_FOLDER} ]
then
    echo "Cloning repo ${TARGET_GIT_URL} to ${TARGET_FOLDER}..."
    git clone ${TARGET_GIT_URL} ${TARGET_FOLDER}
else
    echo "Repo already exists at ${TARGET_FOLDER}."
fi
cd ${TARGET_FOLDER}

sync() {
    rsync -av --chown root:root --delete --exclude=.git ${SOURCE_FOLDER}/ ${TARGET_FOLDER}
    if [ $(git status --porcelain | wc -l) -eq "0" ]; then
        echo "No changes to commit"
    else
        echo "Updating local target git repo"
        git pull
        echo "Pushing changes to ${TARGET_GIT_URL}"
        git add .
        git commit -m "Sync from ${HOSTNAME}"
        git push
    fi
}

restore() {
    echo "Restoring..."
    rsync -av --chown ${UID:-root}:${GID:-root} --delete --exclude=.git ${TARGET_FOLDER}/ ${SOURCE_FOLDER}
}

case $TASK in
    synconce)
        sync
        ;;
    sync)
        while true; do
            sleep 3600
            sync || echo "Sync failed"
        done
        ;;
    restore)
        restore
        ;;
    *)
        echo "Usage: $0 {-s|-r}"
        exit 1
        ;;
esac
