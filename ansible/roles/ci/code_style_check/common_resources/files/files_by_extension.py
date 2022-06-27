#!/usr/bin/env python3

# Copyright 2022 Open Source Robotics Foundation, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
        exit(1)
    return args.path, args.file_type


def gather_all_python_files(path):
    output = []
    for dirpath, _, filenames in os.walk(path):
        for filename in filenames:
            file_path = f"{dirpath}/{filename}"
            try:
                fline=open(file_path).readline().strip()
                if any(fline in head for head in PYTHON_HEADERS) and fline != "" and fline != "#":
                    output.append(file_path)
            except Exception:  # We don't actually care about the exception as it wont fail on python files.
                continue
    return output 


def gather_all_cpp_files(path):
    output = []
    for dirpath, _, filenames in os.walk(path):
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