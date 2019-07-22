#!/bin/bash

export directory=$1
cd $directory

filetypes=(py c h cpp hpp)

copyrights_py=("# Copyright")
exclusions_py=("__init__" "setup.py")

copyright_symbol_utf16=$'\x20\xa9'
copyright_symbol_utf8=$'\xc2\xa9'

copyrights_c=("// "$copyright_symbol_utf16 "//"$copyright_symbol_utf16 "// "$copyright_symbol_utf8 "//"$copyright_symbol_utf8)
exclusions_c=()

copyrights_h=("// "$copyright_symbol_utf16 "//"$copyright_symbol_utf16 "// "$copyright_symbol_utf8 "//"$copyright_symbol_utf8)
exclusions_h=()

copyrights_cpp=("// "$copyright_symbol_utf16 "//"$copyright_symbol_utf16 "// "$copyright_symbol_utf8 "//"$copyright_symbol_utf8)
exclusions_cpp=()
copyrights_hpp=("// "$copyright_symbol_utf16 "//"$copyright_symbol_utf16 "// "$copyright_symbol_utf8 "//"$copyright_symbol_utf8)
exclusions_hpp=()

has_missing_copyrights=false
total_num_files_no_copyright=0
for filetype in "${filetypes[@]}"; do
    num_files_no_copyright=0
    exclusions_name="exclusions_$filetype"[@]
    exclusions=("${!exclusions_name}")
    copyrights_name="copyrights_$filetype"[@]
    copyrights=("${!copyrights_name}")
    for filename in $(find . -name "*.$filetype" -type f); do
        accept_file=true
	for exclusion in "${exclusions[@]}"; do
	    if [[ $(echo -n $exclusion | wc -m) > 0 ]] && [[ $filename == *$exclusion* ]] ; then
	        accept_file=false
            fi
        done
	has_copyright=false
	if $accept_file; then
	    has_copyright=false
	    for copyright in "${copyrights[@]}"; do
	        copyright_line=$(grep -a "$copyright" "$filename")
		if [[ $(echo -n $copyright_line | wc -m) > 0 ]]; then
		    has_copyright=true
		fi
	    done
	    if ! $has_copyright; then
	        echo $'\n'"$filename"
		(( num_files_no_copyright++ ))
		(( total_num_files_no_copyright++ ))
		has_missing_copyrights=true
	    fi
        fi
    done
    if [ $num_files_no_copyright != 0 ]; then
        echo $'\n'"Copyright check failure: There are $num_files_no_copyright $filetype files without copyright. See above for a list of files"
    fi
done
if $has_missing_copyrights; then
    echo $'\n\n'"Copyright check failure: There are $total_num_files_no_copyright files in total without copyright. See above for details."
    exit 1
fi
exit 0
