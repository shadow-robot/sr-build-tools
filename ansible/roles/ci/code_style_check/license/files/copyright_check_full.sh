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

filetypes=(py c h cpp hpp yml yaml sh xml xacro dae launch sdf world config)

exclusions_py=("__init__" "setup.py")

exclusions_c=()

exclusions_xml=()

year_regex="(?:(?:[0-9]{4}){1}(?:-[0-9]{4})?)+(?:, (?:[0-9]{4}){1}(?:-[0-9]{4})?)*"

regexify () {
    regexified=$1
    regexified=${regexified//"."/"\."}
    regexified=${regexified//"/"/"\/"}
    regexified=${regexified//"("/"\("}
    regexified=${regexified//")"/"\)"}
    regexified=${regexified//" "/"(?: |(?:(?:\r*\n$2)*? ))"}
    regexified=${regexified//"<Year>"/${year_regex}}
    echo ${regexified}
}

# C, C++, H, H++ file templates
copyright_c_public_gpl="Copyright <Year> Shadow Robot Company Ltd. \
This program is free software: you can redistribute it and/or modify it \
under the terms of the GNU General Public License as published by the Free \
Software Foundation version 2 of the License. \
This program is distributed in the hope that it will be useful, but WITHOUT \
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or \
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for \
more details. \
You should have received a copy of the GNU General Public License along \
with this program. If not, see <http://www.gnu.org/licenses/>."
copyright_c_public_gpl="$(regexify "$copyright_c_public_gpl" "\*")"

copyright_c_public_bsd="Software License Agreement (BSD License) \
Copyright © <Year> belongs to Shadow Robot Company Ltd. \
All rights reserved. \
\
Redistribution and use in source and binary forms, with or without modification, \
are permitted provided that the following conditions are met: \
  1. Redistributions of source code must retain the above copyright notice, \
     this list of conditions and the following disclaimer. \
  2. Redistributions in binary form must reproduce the above copyright notice, \
     this list of conditions and the following disclaimer in the documentation \
     and/or other materials provided with the distribution. \
  3. Neither the name of Shadow Robot Company Ltd nor the names of its contributors \
     may be used to endorse or promote products derived from this software without \
     specific prior written permission. \
\
This software is provided by Shadow Robot Company Ltd \"as is\" and any express \
or implied warranties, including, but not limited to, the implied warranties of \
merchantability and fitness for a particular purpose are disclaimed. In no event \
shall the copyright holder be liable for any direct, indirect, incidental, special, \
exemplary, or consequential damages (including, but not limited to, procurement of \
substitute goods or services; loss of use, data, or profits; or business interruption) \
however caused and on any theory of liability, whether in contract, strict liability, \
or tort (including negligence or otherwise) arising in any way out of the use of this \
software, even if advised of the possibility of such damage."
copyright_c_public_bsd="$(regexify "$copyright_c_public_bsd" "\*")"

copyright_c_private="Copyright (C) <Year> Shadow Robot Company Ltd - All Rights Reserved. Proprietary and Confidential. \
Unauthorized copying of the content in this file, via any medium is strictly prohibited."
copyright_c_private="$(regexify "$copyright_c_private" "\*")"

# py, msg, yml, yaml, sh file templates
copyright_py_public_gpl="Copyright <Year> Shadow Robot Company Ltd. \
This program is free software: you can redistribute it and/or modify it \
under the terms of the GNU General Public License as published by the Free \
Software Foundation version 2 of the License. \
This program is distributed in the hope that it will be useful, but WITHOUT \
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or \
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for \
more details. \
You should have received a copy of the GNU General Public License along \
with this program. If not, see <http://www.gnu.org/licenses/>."
copyright_py_public_gpl="$(regexify "${copyright_py_public_gpl}" "#")"

copyright_py_public_bsd="Software License Agreement (BSD License) \
Copyright © <Year> belongs to Shadow Robot Company Ltd. \
All rights reserved. \
\
Redistribution and use in source and binary forms, with or without modification, \
are permitted provided that the following conditions are met: \
  1. Redistributions of source code must retain the above copyright notice, \
     this list of conditions and the following disclaimer. \
  2. Redistributions in binary form must reproduce the above copyright notice, \
     this list of conditions and the following disclaimer in the documentation \
     and/or other materials provided with the distribution. \
  3. Neither the name of Shadow Robot Company Ltd nor the names of its contributors \
     may be used to endorse or promote products derived from this software without \
     specific prior written permission. \
\
This software is provided by Shadow Robot Company Ltd \"as is\" and any express \
or implied warranties, including, but not limited to, the implied warranties of \
merchantability and fitness for a particular purpose are disclaimed. In no event \
shall the copyright holder be liable for any direct, indirect, incidental, special, \
exemplary, or consequential damages (including, but not limited to, procurement of \
substitute goods or services; loss of use, data, or profits; or business interruption) \
however caused and on any theory of liability, whether in contract, strict liability, \
or tort (including negligence or otherwise) arising in any way out of the use of this \
software, even if advised of the possibility of such damage."
copyright_py_public_bsd="$(regexify "$copyright_py_public_bsd" "#")"

copyright_py_private="Copyright (C) <Year> Shadow Robot Company Ltd - All Rights Reserved. Proprietary and Confidential. \
Unauthorized copying of the content in this file, via any medium is strictly prohibited."
copyright_py_private="$(regexify "${copyright_py_private}" "#")"

# xml, xacro, dae, launch file templates
copyright_xml_public_gpl="Copyright <Year> Shadow Robot Company Ltd. \
This program is free software: you can redistribute it and/or modify it \
under the terms of the GNU General Public License as published by the Free \
Software Foundation version 2 of the License. \
This program is distributed in the hope that it will be useful, but WITHOUT \
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or \
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for \
more details. \
You should have received a copy of the GNU General Public License along \
with this program. If not, see <http://www.gnu.org/licenses/>."
copyright_xml_public_gpl="$(regexify "${copyright_xml_public_gpl}" "")"

copyright_xml_public_bsd="Software License Agreement (BSD License) \
Copyright © <Year> belongs to Shadow Robot Company Ltd. \
All rights reserved. \
\
Redistribution and use in source and binary forms, with or without modification, \
are permitted provided that the following conditions are met: \
  1. Redistributions of source code must retain the above copyright notice, \
     this list of conditions and the following disclaimer. \
  2. Redistributions in binary form must reproduce the above copyright notice, \
     this list of conditions and the following disclaimer in the documentation \
     and/or other materials provided with the distribution. \
  3. Neither the name of Shadow Robot Company Ltd nor the names of its contributors \
     may be used to endorse or promote products derived from this software without \
     specific prior written permission. \
\
This software is provided by Shadow Robot Company Ltd \"as is\" and any express \
or implied warranties, including, but not limited to, the implied warranties of \
merchantability and fitness for a particular purpose are disclaimed. In no event \
shall the copyright holder be liable for any direct, indirect, incidental, special, \
exemplary, or consequential damages (including, but not limited to, procurement of \
substitute goods or services; loss of use, data, or profits; or business interruption) \
however caused and on any theory of liability, whether in contract, strict liability, \
or tort (including negligence or otherwise) arising in any way out of the use of this \
software, even if advised of the possibility of such damage."
copyright_xml_public_bsd="$(regexify "$copyright_xml_public_bsd" "")"

copyright_xml_private="Copyright (C) <Year> Shadow Robot Company Ltd - All Rights Reserved. Proprietary and Confidential. \
Unauthorized copying of the content in this file, via any medium is strictly prohibited."
copyright_xml_private="$(regexify "${copyright_xml_private}" "")"

any_copyright_regex="Copyright"

# Check if the repository is gnu, bsd or private
gpl_repo_license_regex="(GNU GENERAL PUBLIC LICENSE)|(GNU LESSER GENERAL PUBLIC LICENSE)"
bsd_repo_license_regex="(BSD 2-Clause License)|(BSD 3-Clause License)"
grep -Pz "$gpl_repo_license_regex" "LICENSE" > /dev/null
gpl_repo_license=$?
grep -Pz "$bsd_repo_license_regex" "LICENSE" > /dev/null
bsd_repo_license=$?
if [[ $gpl_repo_license == 0 ]]; then
    repo_licence_type="gpl"
elif [[ $bsd_repo_license == 0 ]]; then
    repo_licence_type="bsd"
else
    repo_licence_type="private"
fi

total_num_files=0
total_num_files_no_copyright=0
total_num_files_bad_copyright=0
total_num_files_private_copyright_in_public=0
total_num_files_public_copyright_in_private=0
total_num_files_bsd_in_gpl=0
total_num_files_gpl_in_bsd=0
declare -a bad_copyright_file_list
declare -a no_copyright_file_list
declare -a private_copyright_in_public_file_list
declare -a public_copyright_in_private_file_list
declare -a bsd_copyright_in_gpl_file_list
declare -a gpl_copyright_in_bsd_file_list

for filetype in "${filetypes[@]}"; do
    case $filetype in 
        c|h|cpp|hpp)
            private_copyright="${copyright_c_private}"
            public_gpl_copyright="${copyright_c_public_gpl}"
            public_bsd_copyright="${copyright_c_public_bsd}"
            exclusions=("${exclusions_c[@]}")
            ;;
        py|msg|yml|yaml|sh)
            private_copyright=${copyright_py_private}
            public_gpl_copyright=${copyright_py_public_gpl}
            public_bsd_copyright="${copyright_py_public_bsd}"
            exclusions=("${exclusions_py[@]}")
            ;;
        xml|xacro|dae|launch)
            private_copyright="${copyright_xml_private}"
            public_gpl_copyright="${copyright_xml_public_gpl}"
            public_bsd_copyright="${copyright_xml_public_bsd}"
            exclusions=("${exclusions_xml[@]}")
            ;;
        *)
            echo "Unknown filetype ${filetype}"
            continue
    esac

    IFS=$'\n' # Allows for filenames with spaces
    for file_path in $(find . -name "*.$filetype" -type f); do
        accept_file=true
        # See if the file is excluded by global exclude patterns (defined above)
        for exclusion in "${exclusions[@]}"; do
            if [[ $(echo -n $exclusion | wc -m) > 0 ]] && [[ $file_path == *$exclusion* ]] ; then
                accept_file=false
            fi
        done
        
        if $accept_file; then
            # See if the file is excluded by a local (same directory) CPPLINT.cfg or copyright_exclusions.cfg
            dir_name=$(dirname "${file_path}")
            exclusion_filenames=("CPPLINT.cfg" "copyright_exclusions.cfg")
            for exclusion_filename in "${exclusion_filenames[@]}"; do
                if [[ -f "${dir_name}/${exclusion_filename}" ]]; then
                    exclude_regex="^exclude_files=\K(.*)"
                    exclude_pattern="$(grep -oP ${exclude_regex} ${dir_name}/${exclusion_filename})"
                    if [[ ! -z ${exclude_pattern} ]]; then
                        file_name=$(basename ${file_path})
                        if [[ ${file_name} =~ ${exclude_pattern} ]]; then
                            accept_file=false
                        fi
                    fi
                fi
            done
        fi

        if $accept_file; then
            (( total_num_files++ ))
            if [[ $repo_licence_type == "private" ]]; then
                grep -Pz "$private_copyright" "$file_path" > /dev/null
                if [[ $? != 0 ]]; then
                    grep -Pz "$public_gpl_copyright" "$file_path" > /dev/null
                    public_gpl_result=$?
                    grep -Pz "$public_bsd_copyright" "$file_path" > /dev/null
                    public_gpl_result=$?
                    if [[ public_gpl_result == 0 || public_bsd_result == 0 ]]; then
                        public_copyright_in_private_file_list+=("${file_path}")
                        (( total_num_files_public_copyright_in_private++ ))
                    else
                        grep -Pz "$any_copyright_regex" "$file_path" > /dev/null
                        if [[ $? == 0 ]]; then
                            bad_copyright_file_list+=("${file_path}")
                            (( total_num_files_bad_copyright++ ))
                        else
                            no_copyright_file_list+=("${file_path}")
                            (( total_num_files_no_copyright++ ))
                        fi
                    fi
                fi
            elif [[ $repo_licence_type == "bsd" ]]; then
                grep -Pz "$public_bsd_copyright" "$file_path" > /dev/null
                if [[ $? != 0 ]]; then
                    grep -Pz "$public_gpl_copyright" "$file_path" > /dev/null
                    public_gpl_result=$?
                    grep -Pz "$private_copyright" "$file_path" > /dev/null
                    private_result=$?
                    if [[ $private_result == 0 ]]; then
                        private_copyright_in_public_file_list+=("${file_path}")
                        (( total_num_files_private_copyright_in_public++ ))
                    elif [[ $public_gpl_result == 0 ]]; then
                        gpl_copyright_in_bsd_file_list+=("${file_path}")
                        (( total_num_files_gpl_in_bsd++ ))
                    else
                        grep -Pz "$any_copyright_regex" "$file_path" > /dev/null
                        if [[ $? == 0 ]]; then
                            bad_copyright_file_list+=("${file_path}")
                            (( total_num_files_bad_copyright++ ))
                        else
                            no_copyright_file_list+=("${file_path}")
                            (( total_num_files_no_copyright++ ))
                        fi
                    fi
                fi
            else
                grep -Pz "$public_gpl_copyright" "$file_path" > /dev/null
                if [[ $? != 0 ]]; then
                    grep -Pz "$public_bsd_copyright" "$file_path" > /dev/null
                    public_bsd_result=$?
                    grep -Pz "$private_copyright" "$file_path" > /dev/null
                    private_result=$?
                    if [[ $private_result == 0 ]]; then
                        private_copyright_in_public_file_list+=("${file_path}")
                        (( total_num_files_private_copyright_in_public++ ))
                    elif [[ $public_bsd_result == 0 ]]; then
                        bsd_copyright_in_gpl_file_list+=("${file_path}")
                        (( total_num_files_bsd_in_gpl++ ))
                    else
                        grep -Pz "$any_copyright_regex" "$file_path" > /dev/null
                        if [[ $? == 0 ]]; then
                            bad_copyright_file_list+=("${file_path}")
                            (( total_num_files_bad_copyright++ ))
                        else
                            no_copyright_file_list+=("${file_path}")
                            (( total_num_files_no_copyright++ ))
                        fi
                    fi
                fi
            fi
        fi
    done
done

fail=false
if [[ $total_num_files_no_copyright > 0 ]]; then
    echo $'\n'"Copyright check failure: There are $total_num_files_no_copyright files without copyright notices:"
    for file_path in "${no_copyright_file_list[@]}"; do
        echo "${file_path}"
    done
    fail=true
fi
if [[ $total_num_files_bad_copyright > 0 ]]; then
    echo $'\n'"Copyright check failure: There are $total_num_files_bad_copyright files with malformed copyright notices:"
    for file_path in "${bad_copyright_file_list[@]}"; do
        echo "${file_path}"
    done
    fail=true
fi
if [[ $total_num_files_public_copyright_in_private > 0 ]]; then
    echo $'\n'"Copyright check failure: There are $total_num_files_public_copyright_in_private private files with public copyright notices:"
    for file_path in "${public_copyright_in_private_file_list[@]}"; do
        echo "${file_path}"
    done
    fail=true
fi
if [[ $total_num_files_private_copyright_in_public > 0 ]]; then
    echo $'\n'"Copyright check failure: There are $total_num_files_private_copyright_in_public public files with private copyright notices:"
    for file_path in "${private_copyright_in_public_file_list[@]}"; do
        echo "${file_path}"
    done
    fail=true
fi
if [[ $total_num_files_gpl_in_bsd > 0 ]]; then
    echo $'\n'"Copyright check failure: There are $total_num_files_gpl_in_bsd public files with GPL licenses, please use BSD:"
    for file_path in "${gpl_copyright_in_bsd_file_list[@]}"; do
        echo "${file_path}"
    done
    fail=true
fi
if [[ $total_num_files_bsd_in_gpl > 0 ]]; then
    echo $'\n'"Copyright check failure: There are $total_num_files_bsd_in_gpl public files with BSD licenses, please use GPL:"
    for file_path in "${bsd_copyright_in_gpl_file_list[@]}"; do
        echo "${file_path}"
    done
    fail=true
fi
if [[ $fail == true ]]; then
    echo $'\n'"Our ${repo_licence_type} copyright notice templates are here:"
    echo "https://shadowrobot.atlassian.net/wiki/spaces/SDSR/pages/594411521/Licenses"
    echo $'\n'"For more information, such as how to exclude files from this check, see this readme:"
    echo "https://github.com/shadow-robot/sr-build-tools/tree/master/ansible/roles/ci/code_style_check/license/README.md"
    exit 1
fi
echo "All ${total_num_files} copyright notices are compliant."
exit 0
