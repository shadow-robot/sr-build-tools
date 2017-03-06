#!/usr/bin/env bash

if [ ! -f build-settings-${1}.sh ]; then
    echo "ERROR! Could not find build-settings-${1}.sh."
    exit 1
fi

rm build-settings.sh 2>/dev/null
ln -s build-settings-${1}.sh build-settings.sh
