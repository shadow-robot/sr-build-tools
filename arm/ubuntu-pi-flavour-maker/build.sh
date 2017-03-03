#!/usr/bin/env bash

./link-settings.sh ${1}
if [ $? != 0 ]; then
    echo "ERROR! Failed to link build settings file build-settings-${1}.sh."
    exit 1
fi

./build-image.sh
