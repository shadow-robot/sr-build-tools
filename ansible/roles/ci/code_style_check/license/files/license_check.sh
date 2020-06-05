#!/bin/bash

export directory=$1
cd $directory

if [ $(find . -maxdepth 1 -name "LICENSE" | wc -l) == 0 ]; then
    echo "No license file present"
    exit 1
fi
name=$(find . -maxdepth 1 -name "LICENSE")
if [ $(wc -c < "$name") -le 235 ]; then
    echo -e "License file present but content is different than expected.\n"
    echo $'\n'"Our License templates are here:"
    echo "https://shadowrobot.atlassian.net/wiki/spaces/SDSR/pages/594411521/Licenses"
    exit 1
fi
echo "License file present"
exit 0
