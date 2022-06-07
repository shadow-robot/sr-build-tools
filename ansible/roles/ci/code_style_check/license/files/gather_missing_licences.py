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
import sys
import argparse
import subprocess
from datetime import date


class Data:
    accepted_extensions = ["py", "c", "h", "cpp", "hpp"]
    changed_files = []

    def __init__(self, path, token, src_vers) -> None:
        self.path = path
        self.token = token
        self.source = src_vers
        self.current_year = str(date.today().year)


def gather_arguments():
    parser = argparse.ArgumentParser(
        description='Used to check all files changed in PR and get a list of files changed.',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument(
        '--path',
        type=str,
        required=True,
        help='The path to the repo to check the licences.')

    args = parser.parse_args()
    token = os.environ['GITHUB_PASSWORD']
    if not token:
        print("GITHUB TOKEN IS MISSING.")
        sys.exit(1)

    source_version = os.environ['CODEBUILD_SOURCE_VERSION']
    if not source_version:
        print("NO SOURCE VERSION DETECTED")
        sys.exit(0)  # Master branch doesn't give a PR version.
    if len(source_version.split("/")) > 1:
        source_version = source_version.split("/")[1]  # Just get the PR number
    return Data(args.path, token, source_version)


def authenticate_login(data):
    """This function is used to login to the github cli using your GitHub token
       which is passed in through the data object."""
    command = ["gh", "auth", "login", "--with-token"]
    process = subprocess.run(command, input=str.encode(data.token), check=True)
    if process.returncode != 0:
        print(f"Failed to authenticate:\nstdout: {process.stdout}\nstderr: {process.stderr}")
        sys.exit(1)


def get_changes_in_pr(data):
    """Takes in the data class and uses it to get the differences in the pr. It uses subprocess to
       get all of the changes using github cli (gh). Then gets all the files changed by getting
       a list of all strings containing '+++' or '---'."""
    command = ["gh", "pr", "diff", data.source]
    with subprocess.Popen(command, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE) as process:
        out, _ = process.communicate()
        if process.returncode != 0:
            print(f"Failed to get changes:\nstdout: {process.stdout}\nstderr: {process.stderr}")
            sys.exit(1)

    for line in out.splitlines():
        if "+++" in line:  # Changed files are marked with +++.
            file_changed = line.split("+++")[1][3:]  # Gets the filename
            file_path = os.path.join(data.path, file_changed)
            _, extension = os.path.splitext(file_path)
            if extension[1:] in data.accepted_extensions:
                payload = (file_path, extension[1:])
                if payload not in data.changed_files:
                    data.changed_files.append(payload)
        if "---" in line:  # Changed files are marked with +++.
            file_changed = line.split("---")[1][3:]  # Gets the filename
            file_path = os.path.join(data.path, file_changed)
            _, extension = os.path.splitext(file_path)
            if extension[1:] in data.accepted_extensions:
                payload = (file_path, extension[1:])
                if payload not in data.changed_files:
                    data.changed_files.append(payload)


def gather_missing_licences(data):
    """This goes through all the found files, looks for all lines starting with a comment.
       Then checks to see if the licence has the current date in it.
       If it doesn't its added to a list of files missing the correct licence."""
    missing_licence = []
    for file_path, extension in data.changed_files:
        if os.path.exists(file_path):
            with open(file_path, "r") as file:
                for line in file.readlines():  # Read file line by line
                    line = line.strip()  # Remove whitespaces so we can find lines with just comments
                    if extension == "py":
                        if line and len(line) > 1 and line[0] == "#":
                            if "Shadow Robot Company Ltd" in line and "Copyright" in line:
                                if data.current_year not in line:
                                    missing_licence.append(file_path)
                    else:
                        if line and len(line) > 1 and line[0] in ["/","*"]:
                            if "Shadow Robot Company Ltd" in line and "Copyright" in line:
                                if data.current_year not in line:
                                    missing_licence.append(file_path)
    return missing_licence


def do_licence_check(data):
    """This script gets all the commented lines in the files found. It then goes through each comment
        checking for the licence line with the year and ensures the current year is somewhere in the string.
        If the current year doesn't isn't in the file its printed and then the script fails."""
    missing_licences = gather_missing_licences(data)

    if len(missing_licences) > 0:
        print("These changed files are missing the current year in their licence:")
        for file in missing_licences:
            print(f"    {file}")
        sys.exit(1)


def main():
    data = gather_arguments()
    authenticate_login(data)
    os.chdir(data.path)
    get_changes_in_pr(data)
    do_licence_check(data)


if __name__ == "__main__":
    main()
