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
import os
import argparse


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
    output = []
    for dirpath, _, filenames in os.walk(file_path):
        for filename in filenames:
            file_path = f"{dirpath}/{filename}"
            try:
                fline = ""
                with open(file_path) as python_file:
                    fline = python_file.readline().strip()
                if any(fline in head for head in PYTHON_HEADERS) and fline != "" and fline != "#":
                    output.append(file_path)
            except Exception:  # We don't actually care about the exception as it wont fail on python files.
                continue
    return output


def gather_all_cpp_files(file_path):
    output = []
    for dirpath, _, filenames in os.walk(file_path):
        for filename in filenames:
            if os.path.splitext(filename)[1] in CPP_HEADERS:
                output.append(f"{dirpath}/{filename}")
    return output


if __name__ == "__main__":
    path, filetype = argparser()
    files = []
    if filetype == "python":
        files = gather_all_python_files(path)
    elif filetype == "cpp":
        files = gather_all_cpp_files(path)
    for code_file in files:
        print(code_file)
