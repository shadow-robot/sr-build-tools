#!/bin/bash

export directory=$1
cd $directory

filetypes=(py c h cpp hpp)

exclusions_py=("__init__" "setup.py")

exclusions_c=()

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

copyright_c_public="Copyright <Year> Shadow Robot Company Ltd. \
This program is free software: you can redistribute it and/or modify it \
under the terms of the GNU General Public License as published by the Free \
Software Foundation version 2 of the License. \
This program is distributed in the hope that it will be useful, but WITHOUT \
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or \
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for \
more details. \
You should have received a copy of the GNU General Public License along \
with this program. If not, see <http://www.gnu.org/licenses/>."
copyright_c_public="$(regexify "$copyright_c_public" "\*")"

copyright_c_private="Copyright (C) <Year> Shadow Robot Company Ltd - All Rights Reserved. Proprietary and Confidential. \
Unauthorized copying of the content in this file, via any medium is strictly prohibited."
copyright_c_private="$(regexify "$copyright_c_private" "\*")"

copyright_py_public="Copyright <Year> Shadow Robot Company Ltd. \
This program is free software: you can redistribute it and/or modify it \
under the terms of the GNU General Public License as published by the Free \
Software Foundation version 2 of the License. \
This program is distributed in the hope that it will be useful, but WITHOUT \
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or \
FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for \
more details. \
You should have received a copy of the GNU General Public License along \
with this program. If not, see <http://www.gnu.org/licenses/>."
copyright_py_public="$(regexify "${copyright_py_public}" "#")"

copyright_py_private="Copyright (C) <Year> Shadow Robot Company Ltd - All Rights Reserved. Proprietary and Confidential. \
Unauthorized copying of the content in this file, via any medium is strictly prohibited."
copyright_py_private="$(regexify "${copyright_py_private}" "#")"

any_copyright_regex="Copyright"

# Check if the repository is private
public_repo_license_regex="(GNU GENERAL PUBLIC LICENSE)|(BSD 2-Clause License)"
repo_privacy=private
grep -Pz "$public_repo_license_regex" "LICENSE" > /dev/null
if [[ $? == 0 ]]; then
    repo_privacy=public
fi

total_num_files=0
total_num_files_no_copyright=0
total_num_files_bad_copyright=0
total_num_files_private_copyright_in_public=0
total_num_files_public_copyright_in_private=0
declare -a bad_copyright_file_list
declare -a no_copyright_file_list
declare -a private_copyright_in_public_file_list
declare -a public_copyright_in_private_file_list
for filetype in "${filetypes[@]}"; do
    case $filetype in 
        c|h|cpp|hpp)
            private_copyright="${copyright_c_private}"
            public_copyright="${copyright_c_public}"
            exclusions=("${exclusions_c[@]}")
            ;;
        py)
            private_copyright=${copyright_py_private}
            public_copyright=${copyright_py_public}
            exclusions=("${exclusions_py[@]}")
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
            if [[ $repo_privacy == "private" ]]; then
                grep -Pz "$private_copyright" "$file_path" > /dev/null
                if [[ $? != 0 ]]; then
                    grep -Pz "$public_copyright" "$file_path" > /dev/null
                    if [[ $? == 0 ]]; then
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
            else
                grep -Pz "$public_copyright" "$file_path" > /dev/null
                if [[ $? != 0 ]]; then
                    grep -Pz "$private_copyright" "$file_path" > /dev/null
                    if [[ $? == 0 ]]; then
                        private_copyright_in_public_file_list+=("${file_path}")
                        (( total_num_files_private_copyright_in_public++ ))
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
if [[ $fail == true ]]; then
    echo $'\n'"Our ${repo_privacy} copyright notice templates are here: https://shadowrobot.atlassian.net/wiki/spaces/SDSR/pages/594411521/Licenses."
    exit 1
fi
echo "All ${total_num_files} copyright notices are compliant."
exit 0
