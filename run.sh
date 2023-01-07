#!/bin/sh
set -euo pipefail

TASK=${TASK:-sync}
GIT_DIR=${GIT_DIR:-/tmp/target}
SOURCE_UID=${SOURCE_UID:-root}
SOURCE_GID=${SOURCE_GID:-$SOURCE_UID}

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

echo "Configured to sync from ${SOURCE_DIR} to ${TARGET_GIT_URL}"
if [ ! -d ${GIT_DIR} ]
then
    echo "Cloning repo ${TARGET_GIT_URL} to ${GIT_DIR}..."
    git clone ${TARGET_GIT_URL} ${GIT_DIR}
else
    echo "Repo already exists at ${GIT_DIR}."
fi
cd ${GIT_DIR}

sync() {
    rsync -av --chown root:root --delete --exclude=.git ${SOURCE_DIR}/ ${GIT_DIR}
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
    rsync -av --chown ${SOURCE_UID}:${SOURCE_GID} --delete --exclude=.git ${GIT_DIR}/ ${SOURCE_DIR}
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
