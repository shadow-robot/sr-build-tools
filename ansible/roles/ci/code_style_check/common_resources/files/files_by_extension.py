#!/usr/bin/env python3

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

import sys
import re
import os
import argparse


LINT_IGNORE_FILE = "lint_exclusions.cfg"
CPP_HEADERS = [".cpp", ".c", ".h", ".hpp"]
PYTHON_HEADERS = ["#!/usr/bin/env python", "#! /usr/bin/env python", "#!/usr/bin/python", "#! /usr/bin/python",
                  "#!/usr/bin/env python3", "#! /usr/bin/env python3", "#!/usr/bin/python3", "#! /usr/bin/python3"]


def argparser():
    """This function handles the arguments passed into the script"""
    parser = argparse.ArgumentParser(description='Process some integers.')
    parser.add_argument('-p', '--path', type=str, required=True)
    parser.add_argument('-ft', '--file_type', type=str, required=True)
    args = parser.parse_args()
    if not os.path.exists(args.path):
        print(f"THIS PATH DOES NOT EXIST. {args.path}")
        sys.exit(1)
    return args.path, args.file_type


def gather_all_python_files(file_path):
    """This function walks through the given path collects all python files (with and without extension based on
       header). It will exclude all python files found in the lint ignore file."""
    output = []
    for dirpath, _, filenames in os.walk(file_path):
        excluded_files = gather_excluded_files(dirpath, "python")  # Gathers all the files to be ignored in this folder
        for filename in filenames:
            if filename in excluded_files:  # Skip excluded files
                continue
            full_file_path = os.path.join(dirpath, filename)
            valid_file = check_is_python_file(full_file_path)
            if valid_file:
                output.append(full_file_path)
    return output


def gather_all_cpp_files(file_path):
    """This function walks through the given path collects all c, cpp, h, hpp files It will exclude all python files
       found in the lint ignore file."""
    output = []
    for dirpath, _, filenames in os.walk(file_path):
        excluded_files = gather_excluded_files(dirpath, "cpp")  # Gathers all the files to be ignored in this folder
        for filename in filenames:
            if filename in excluded_files:  # Skip excluded files
                continue
            if os.path.splitext(filename)[1] in CPP_HEADERS:
                output.append(os.path.join(dirpath, filename))
    return output

def gather_excluded_files(folder_path, filetype):
    """Gatheres all of the files to ignore in the lint ignore file (if it exists). If the file contains
       `exclude_files=*` then all files will be ignored, or you can list indiviual files like
       `exclude_files=test.py,hello.cpp,hi.h`."""
    folder_files = [f for f in os.listdir(folder_path) if os.path.isfile(os.path.join(folder_path, f))]
    folder_files_filtered = []

    if LINT_IGNORE_FILE in folder_files:  # Check there are actually files to skip
        for folder_file in folder_files:
            if check_is_python_file(os.path.join(folder_path, folder_file)):
                folder_files_filtered.append(folder_file)
            if os.path.splitext(folder_file)[1] in CPP_HEADERS:
                folder_files_filtered.append(folder_file)

        re_pattern = re.compile(r'exclude_files=((?:[^,]*,)*[^,]*)')
        with open(os.path.join(folder_path, LINT_IGNORE_FILE)) as ignore_file:
            content = ignore_file.readline()

        excluded_files = re_pattern.search(content).group(1)
        if "*" in excluded_files:  # Tells us to skip all files
            return folder_files_filtered
        return [f.strip() for f in excluded_files.split(",")]

    return []

def check_is_python_file(file_path):
    """This function is used to check if a file is a python file. It first checks the extension, if this doesn't return
       .py then it will check the first line of the file against the python headers. Returns true if the file is a
       python file."""
    if os.path.splitext(file_path)[1] == ".py":
        return True

    fline = ""
    try:  # Used to catch files that won't open or have the wrong encoding type.
        with open(file_path) as python_file:
            fline = python_file.readline().strip()
    except:
        return False

    if any(fline in head for head in PYTHON_HEADERS) and fline != "" and fline != "#":
        return True

    return False

if __name__ == "__main__":
    path, filetype = argparser()
    files = []
    if filetype == "python":
        files = gather_all_python_files(path)
    elif filetype == "cpp":
        files = gather_all_cpp_files(path)
    for code_file in files:
        print(code_file)
