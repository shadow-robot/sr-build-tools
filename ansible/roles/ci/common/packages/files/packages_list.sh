#!/usr/bin/env bash

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

export result="["
export has_packages=0

cd $directory

for file in $(find -type f -name 'package.xml');
do
    if [ $has_packages -eq 1 ]; then
        export result="$result,"
    fi
    # Extracting package name from package.xml file using sed
    export package_name=$(grep -e '<name>' $file | sed -e 's,.*<name>\([^<]*\)</name>.*,\1,g')
    export result="$result \"$package_name\""
    export has_packages=1
done

echo "$result]"
