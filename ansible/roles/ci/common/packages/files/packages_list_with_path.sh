#!/usr/bin/env bash

export directory=$1

export result="["
export has_packages=0

cd $directory

for file in $(find -type f -name 'package.xml');
do
    if [ $has_packages -eq 1 ]; then
        export result="$result,"
    fi
    export package_name=$(grep -e '<name>' $file | sed -e 's,.*<name>\([^<]*\)</name>.*,\1,g')
    export result="$result {\"path\": \"$(dirname $file)\", \"name\" : \"$package_name\"}"
    export has_packages=1
done

echo "$result]"
