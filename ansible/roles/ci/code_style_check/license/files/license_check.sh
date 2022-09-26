#!/bin/bash

# Copyright 2022 Shadow Robot Company Ltd.
#
# This program is free software: you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the Free
# Software Foundation version 2 of the License.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
# more details.
#
# You should have received a copy of the GNU General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.

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
