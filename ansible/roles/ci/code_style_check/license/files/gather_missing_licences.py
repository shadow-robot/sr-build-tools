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
import sys
import argparse
import subprocess
from datetime import date

PYTHON_HEADERS = ["#!/usr/bin/env python", "#!/usr/bin/python"]
ACCEPTED_EXTENSIONS = ["py", "c", "h", "cpp", "hpp"]
MASTER_BRANCHES = ["noetic-devel", "melodic-devel", "kinetic-devel", "jade-devel", "indigo-devel", "devel", "master", "main"]


class Data:
    changed_files = []
    def __init__(self, path, src_vers) -> None:
        self.path = path
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

    with open('/tmp/git_source', 'r') as tmp_file:
        source = tmp_file.read().strip()
    print("\n", source)
    return Data(args.path, source)


def get_changes_in_pr(data):
    """Takes in the data class and uses it to get the differences in the pr. It uses subprocess to
       get all of the changes using github cli (gh). Then gets all the files changed by getting
       a list of all strings containing '+++' or '---'."""
    # Get commit branch and checkout to it
    command = ["git", "branch", "-a", "--contains", data.source]
    active_branch_process = subprocess.run(command, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    active_branch = ""
    if active_branch_process.returncode != 0:
        print(f"ERROR WITH COMMAND:\nstderr:{active_branch_process.stderr}\nstdout:{active_branch_process.stdout}")
        exit(1)
    print(active_branch_process.stdout.split("\n"))
    for branch in active_branch_process.stdout.split("\n"):
        if "remotes/origin/" in branch:
            branch_name = branch.split("remotes/origin/")[-1]
            if branch_name in MASTER_BRANCHES:
                exit(0)
            active_branch = branch_name
            break
    command = ["git", "checkout", active_branch]
    checkout_branch_process = subprocess.run(command, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if checkout_branch_process.returncode != 0:
        print(f"ERROR WITH COMMAND:\nstderr:{checkout_branch_process.stderr}\nstdout:{checkout_branch_process.stdout}")
        exit(1)

    # Gets the master branch
    command = ["git", "branch"]
    master_branch_process = subprocess.run(command, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if master_branch_process.returncode != 0:
        print(f"ERROR WITH COMMAND:\nstderr:{master_branch_process.stderr}\nstdout:{master_branch_process.stdout}")
        exit(1)
    devel_branches = ""
    list_of_accepted_master_branches = master_branch_process.stdout.split("\n")
    print(master_branch_process.stdout.split("\n"))
    all_branches = [branch.strip() for branch in list_of_accepted_master_branches]
    for branch in MASTER_BRANCHES:
        if branch in all_branches:
            devel_branches = branch
            break
    if devel_branches == "":
        print(f"Could not find the master branch: checks for {MASTER_BRANCHES}")
        exit(1)

    # Get the differences between the PR and master.
    command = ["git", "diff", "--name-only", devel_branches, active_branch]
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
