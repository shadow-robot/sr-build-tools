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
from xml.etree import ElementTree as et

OUTPUT_PATH = "/home/user/testxml"


def print_dictonary(dep_dict):
    """Test function, may be removed later."""
    error_count = 0
    for key in dep_dict.keys():
        print("Within the file {} include:".format(key))
        for dep in dep_dict[key]:
            print(dep)
            error_count += 1
        print()
    print("Total errors found {}".format(error_count))
    if error_count > 0:
        exit(1)


def strip_dependecies(dependency_list):
    """Takes in a list of dependency and strips each string value."""
    stripped_list = []
    for dep in dependency_list:
        stripped_list.append(dep.strip())
    return stripped_list


def gather_errors_from_produced_xmls():
    """Goes through the testcase xmls and gathers all of the errors located. Places them in a dict."""
    missing_dependencies = {"other_errors": []}
    xml_files = [os.path.join(OUTPUT_PATH, f) for f in os.listdir(OUTPUT_PATH)]
    for xml_file in xml_files:
        tree = et.parse(xml_file)
        root = tree.getroot()
        testcase_name = root.find("testcase").attrib["name"]
        for element in root.findall('system-out'):  # Use this incase there are many entries
            missing_dependencies[testcase_name] = strip_dependecies(element.text.split("\n")[1:-1])
    print_dictonary(missing_dependencies)


def run_roslaunch_check(launch_files, test_dir):
    """
    Iterates through launch files and preforms roslaunch-check on them.
    Puts produced xmls in a specified output folder.
    """
    for count, path_to_file in enumerate(launch_files):
        file_name = path_to_file.split("/")[-1].split(".")[0]
        path = os.path.join(test_dir, file_name + ".xml")
        completed_process = subprocess.run(["rosrun", "roslaunch", "roslaunch-check", path_to_file, "-o", path])


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


def check_argument(arguments):
    """Checks the given directory argument to search for the launch files. Ensure it exists."""
    if len(arguments) < 2:
        print("Needs both repo_dir and output_dir parameters.\nExiting test.")
        exit(1)
    elif len(arguments) > 2:
        print("Too many arguments.\nExiting test.")
        exit(1)
    if not os.path.exists(arguments[0]) and not os.path.exists(arguments[1]):
        print("This path does not exist.\nExiting test.")
        exit(1)
    return arguments[0], arguments[1]


def setup_test_env(test_location):
    """This function checks if test folder exists, if it does, it creates it."""
    if not os.path.exists(test_location):
        os.mkdir(test_location)


if __name__ == "__main__":
    repository_dir, test_location = check_argument(sys.argv[1:])
    setup_test_env(test_location)
    launch_files = gather_launch_files(repository_dir)
    run_roslaunch_check(launch_files, test_location)
    gather_errors_from_produced_xmls()
