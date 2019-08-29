#!/bin/bash

export directory=$1
cd $directory

filetypes=(py c h cpp hpp)

exclusions_py=("__init__" "setup.py")

exclusions_c=()

year_regex="(([0-9]{4}){1}(-[0-9]{4})?)+(, ([0-9]{4}){1}(-[0-9]{4})?)*"

copyright_c_public="\* Copyright ${year_regex} Shadow Robot Company Ltd.\n\*\n\* This program is free software: you can redistribute it and\/or modify it\n\
\* under the terms of the GNU General Public License as published by the Free\n\
\* Software Foundation version 2 of the License.\n\
\*\n\
\* This program is distributed in the hope that it will be useful, but WITHOUT\n\
\* ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or\n\
\* FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for\n\
\* more details.\n\
\*\n\
\* You should have received a copy of the GNU General Public License along\n\
\* with this program. If not, see <http://www.gnu.org/licenses/>.\n"

copyright_c_private="\* Copyright \(C\) ${year_regex} Shadow Robot Company Ltd - All Rights Reserved\. Proprietary and Confidential.\n\
\* Unauthorized copying of the content in this file, via any medium is strictly prohibited\.\n"

copyright_py_public="# Copyright ${year_regex} Shadow Robot Company Ltd.\n\#\n\# This program is free software: you can redistribute it and\/or modify it\n\
# under the terms of the GNU General Public License as published by the Free\n\
# Software Foundation version 2 of the License\.\n\
#\n\
# This program is distributed in the hope that it will be useful, but WITHOUT\n\
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or\n\
# FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for\n\
# more details\.\n\
#\n\
# You should have received a copy of the GNU General Public License along\n\
# with this program\. If not, see <http://www.gnu.org/licenses/>\."

copyright_py_private="# Copyright \(C\) ${year_regex} Shadow Robot Company Ltd - All Rights Reserved\. Proprietary and Confidential\.\n\
# Unauthorized copying of the content in this file, via any medium is strictly prohibited\."

any_copyright_regex="Copyright"

# Check if the repository is private
private_repo_license_regex="Copyright \(C\) ${year_regex} Shadow Robot Company Ltd - All Rights Reserved\."
repo_privacy=public
grep -Pz "$private_repo_license_regex" "LICENSE" > /dev/null
if [[ $? == 0 ]]; then
    repo_privacy=private
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
    for file_path in $(find . -name "*.$filetype" -type f); do
        accept_file=true
        # See if the file is excluded by global exclude patterns (defined above)
        for exclusion in "${exclusions[@]}"; do
            if [[ $(echo -n $exclusion | wc -m) > 0 ]] && [[ $file_path == *$exclusion* ]] ; then
                accept_file=false
            fi
        done
        if $accept_file; then
            # See if the file is excluded by a local (same directory) CPPLINT.cfg
            dir_name=$(dirname "${file_path}")
            if [[ -f "${dir_name}/CPPLINT.cfg" ]]; then
                exclude_regex="^exclude_files=\K(.*)"
                exclude_pattern="$(grep -oP ${exclude_regex} ${dir_name}/CPPLINT.cfg)"
                if [[ ! -z ${exclude_pattern} ]]; then
                    file_name=$(basename ${file_path})
                    if [[ ${file_name} =~ ${exclude_pattern} ]]; then
                        echo "Excluding file ${file_path} from copyright check as it matches CPPLINT.cfg exclude=${exclude_pattern}"
                        accept_file=false
                    fi
                fi
            fi
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
