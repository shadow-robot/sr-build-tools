#!/usr/bin/env python3

# Copyright 2021 Shadow Robot Company Ltd.
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

# Maintained by devops@shadowrobot.com

import sys
import os
import subprocess
import argparse
from xml.etree import ElementTree as et


def run_roslaunch_check(launch_files, test_dir):
    """
    Iterates through launch files and preforms roslaunch-check on them.
    Puts produced xmls in a specified output folder.
    """
    for path_to_file in launch_files:
        file_name = path_to_file.split("/")[-1].split(".")[0]
        path = os.path.join(test_dir, file_name + ".xml")
        try:
            subprocess.run(["rosrun", "roslaunch", "roslaunch-check", path_to_file, "-o", path])
        except:
            print("Subprocess failed unexpectently when running roslaunch-check.")
            print("Failed on file: {}".format(path))
            exit(1)


def gather_launch_files(directory):
    """Walks through the directory and puts all launch files into a folder, exits if empty."""
    launch_files = []
    for root, _, files in os.walk(directory):
        for file in files:
            if os.path.splitext(file)[1] == ".launch":
                launch_files.append(os.path.join(root, file))
    if not launch_files:
        print("No launch files detected.\nExiting test.")
        exit(0)
    return launch_files


def check_argument():
    """Checks the given directory argument to search for the launch files. Ensure it exists."""
    parser = argparse.ArgumentParser()
    parser.add_argument('-r', '--repo', help='Repo directory folder.', required=True)
    parser.add_argument('-t', '--test', help='Test directory folder.', required=True)
    args = parser.parse_args()
    repository_dir = args.repo
    test_location = args.test
    if not os.path.exists(repository_dir):
        print("The given repo directory does not exist.\nExiting test.")
        exit(1)
    return repository_dir, test_location


def setup_test_env(test_location):
    """This function checks if test folder exists, if it does, it creates it."""
    if not os.path.exists(test_location):
        os.mkdir(test_location)


if __name__ == "__main__":
    repository_dir, test_location = check_argument()
    setup_test_env(test_location)
    launch_files = gather_launch_files(repository_dir)
    run_roslaunch_check(launch_files, test_location)
