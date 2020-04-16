#!/usr/bin/env bash

# This script is based on this article
# http://www.zephyrizing.net/presentations/reimplementing-gitignore-in-15-lines-of-bash/

# Ignore file will work based on "-path pattern" rules of find command
# More details could be found here http://man7.org/linux/man-pages/man1/find.1.html

set -e # fail on errors
#set -x # echo commands run

repository_dir=$(realpath $1)
package_dir=$(realpath $2)
regexp="$3"
rules_file_name=$4

exclude_regexp=$5

{
    find $package_dir -type f -regextype posix-extended ! -regex $exclude_regexp -exec grep -R -I -P "$regexp" -l {} \;

    # Concatenate a listing of all ignore files, with the path to the
    # ignore file it came from prefixed to each pattern
    {
        # Process all directories within ignore file
        find $repository_dir -type f -name $rules_file_name | xargs -n1 --no-run-if-empty dirname |
        while read dir
        do
            # 1. Append new line to end of file
            # 2. Remove all empty lines
            # 3. Prefix the contents of each ignore file with the path to the file it came from
            sed '$a\' "$dir/$rules_file_name" | sed '/^[ \t]*$/d' | sed 's|^|'"$dir/"'|'
        done

	# And finally, print out all of the files that match each of the
	# patterns from all ignore files.
    } | xargs --no-run-if-empty -n1 find $repository_dir -type f --regextype posix-extended ! -regex $exclude_regexp -a -path | grep "^$package_dir"

    # Now, sort and then print only the unique lines.
} | sort | uniq -u