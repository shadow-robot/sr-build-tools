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

import os
import re
import sys
import argparse
import subprocess
import requests
from datetime import date

# Include bash in python files as we also put licences in bash files too.
PYTHON_HEADERS = ["#!/usr/bin/env python", "#!/usr/bin/python", "#!/bin/bash", "#!/usr/bin/env bash"]
ACCEPTED_EXTENSIONS = ["py", "c", "h", "cpp", "hpp", "yml", "yaml", "sh", "xml", "xacro", "dae", "launch"]
MASTER_BRANCHES = ["noetic-devel", "melodic-devel", "kinetic-devel",
                   "jade-devel", "indigo-devel", "devel", "master", "main"]


class Data:
    changed_files = []
    def __init__(self, path, src_vers, user, token) -> None:
        self.path = path
        self.source = src_vers
        self.user = user
        self.token = token
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
    parser.add_argument(
        '--user',
        type=str,
        required=True,
        help='The Github Username.')
    parser.add_argument(
        '--token',
        type=str,
        required=True,
        help='The Github Token.')
    args = parser.parse_args()

    with open('/tmp/git_source', 'r') as tmp_file:
        source = tmp_file.read().strip()
    return Data(args.path, source, args.user, args.token)


def get_changes_in_pr(data):
    """Takes in the data class and uses it to get the differences in the pr. It uses subprocess to
       get all of the changes using github cli (gh). Then gets all the files changed by getting
       a list of all strings containing '+++' or '---'."""
    # Get commit branch and checkout to it
    command = ["git", "branch", "-a", "--contains", data.source]
    active_branch_process = subprocess.run(command, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    active_branch = ""
    if active_branch_process.returncode != 0:
        print(f"ERROR WITH COMMAND {command}:\nstderr:{active_branch_process.stderr}\nstdout:{active_branch_process.stdout}")
        sys.exit(1)
    for branch in active_branch_process.stdout.split("\n"):
        if "remotes/origin/HEAD ->" in branch:
            result = re.search(r"->\s*origin/(.+)", branch)
            branch_name = result.group(1)
            if branch_name in MASTER_BRANCHES:
                sys.exit(0)  # Exit on master branch as its already been merged and checked.
            active_branch = branch_name
            break
        elif "remotes/origin/" in branch:
            result = re.search(r"remotes/origin/(.+)", branch)
            branch_name = result.group(1)
            if branch_name in MASTER_BRANCHES:
                sys.exit(0)  # Exit on master branch as its already been merged and checked.
            active_branch = branch_name
            break

    command = ["git", "checkout", active_branch]
    checkout_branch_process = subprocess.run(command, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if checkout_branch_process.returncode != 0:
        print(f"ERROR WITH COMMAND {command}:\nstderr:{checkout_branch_process.stderr}\nstdout:{checkout_branch_process.stdout}")
        sys.exit(1)

    # Get the URL of the remote repository associated with the local Git repository
    result = subprocess.run(['git', 'config', '--get', 'remote.origin.url'], stdout=subprocess.PIPE)
    repo_name = result.stdout.decode().strip().split(".git")[0].split("/")[-1]
    # Make a GET request to the GitHub API to get information about the repository
    api_url = f'https://api.github.com/repos/shadow-robot/{repo_name}'
    response = requests.get(api_url, auth=(data.user, data.token))
    # Extract the default branch from the response
    default_branch = response.json()['default_branch']

    # Get the differences between the PR and master.
    command = ["git", "diff", "--name-only", default_branch, active_branch]
    git_diff_process = subprocess.run(command, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    for line in git_diff_process.stdout.splitlines():
        file_path = os.path.join(data.path, line)
        _, extension = os.path.splitext(file_path)
        if os.path.exists(file_path) and os.path.isfile(file_path):
            if not extension:  # We sometimes have python files without extensions
                with open(file_path, 'r') as code_file:
                    firstline = code_file.readline().strip()
                    if any(entry in firstline for entry in PYTHON_HEADERS):
                        payload = (file_path, "py")
                        if payload not in data.changed_files:
                            data.changed_files.append(payload)
            elif extension[1:] in ACCEPTED_EXTENSIONS:
                payload = (file_path, extension[1:])
                if payload not in data.changed_files:
                    data.changed_files.append(payload)


def gather_missing_licences(data):
    """This goes through all the found files, looks for all lines starting with a comment.
       Then checks to see if the licence has the current date in it.
       If it doesn't its added to a list of files missing the correct licence."""
    missing_licence = []
    for file_path, extension in data.changed_files:
        start_comment=False
        with open(file_path, "r") as file:
            for line in file.readlines():  # Read file line by line
                line = line.strip()  # Remove whitespaces so we can find lines with just comments
                if extension in ["py", "msg", "yml", "yaml", "sh", "c", "cpp", "h", "hpp"]:
                    if line and len(line) > 1 and line[0] in ["#", "/", "*"]:
                        if "Shadow Robot Company Ltd" in line and "Copyright" in line:
                            if data.current_year not in line:
                                missing_licence.append(file_path)
                else:  # Handles xml xacro dae and launch files.
                    if line and len(line) > 1 and line[0:4] == "<!--":
                        start_comment = True
                    if line and len(line) > 1 and line[0:2] == "-->":
                        start_comment = False
                    if start_comment:
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
            if "shadow-robot" in file:  # For local runs only
                file = file.split("shadow-robot")[1][1:]
            print(f"    {file}")
        sys.exit(1)


def main():
    data = gather_arguments()
    os.chdir(data.path)
    get_changes_in_pr(data)
    do_licence_check(data)


if __name__ == "__main__":
    main()