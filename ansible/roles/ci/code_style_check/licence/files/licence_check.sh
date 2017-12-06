#!/bin/bash

export directory=$1
cd $directory

if [ $(find . -name "LICENSE" | wc -l) == 0 ]; then
    echo "No license file present"
    exit 1
else
    name=$(find . -name "LICENSE")
    if [ $(wc -c < "$name") -le 235 ]; then
        echo -e "License file present but content is different than expected. Please use the following text: \n"
        echo -e "Copyright (C) 2017 Shadow Robot Company Ltd - All Rights Reserved."
        echo -e "Redistribution and use in source and binary forms, with or without modification, are strictly prohibited by anyone without specific permission from Shadow Robot Company.\n"
    else
        echo "License file present"
    fi
    exit 0
fi