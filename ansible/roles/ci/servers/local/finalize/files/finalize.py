#!/usr/bin/env python3

# Copyright 2021 Open Source Robotics Foundation, Inc.
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

import argparse
import os
import subprocess
import sys
from xml.etree import ElementTree


FAIL_COLOUR = '\033[91m'  # Used to make the terminal text red
SUCCESS_COLOUR = '\033[92m'



def main(argv=sys.argv[1:]):
    const_extensions = ['xml']
    parser = argparse.ArgumentParser(
        description='Check XML markup using xmllint.',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument(
        '--path',
        nargs='*',
        default=[os.curdir],
        help='The files or directories to check. For directories files ending '
             'in %s will be considered.' %
             ', '.join(["'.%s'" % e for e in const_extensions]))

    args = parser.parse_args(argv)
    files = gather_files(args.path[0], const_extensions)

    if not files:
        print('No files found', file=sys.stderr)
        return 1
    files = [os.path.abspath(f) for f in files]

    error_count = 0
    failures = []
    for filename in files:
        failed_tests, count = gather_all_failures(filename, error_count)
        error_count += count
        failures = failures + failed_tests

    if error_count == 0:
        success_msg = SUCCESS_COLOUR + 'TESTS SUCCEEDED WITH 0 ERRORS.'
        subprocess.call(['echo', '-e', success_msg])
        exit(0)

    for fail_msg in failures:
        subprocess.call(['echo', '-e', fail_msg])

    total_error_msg = FAIL_COLOUR + "TESTS FAILED WITH {} ERRORS FOUND.".format(error_count)
    subprocess.call(['echo', '-e', total_error_msg])    
    exit(1)


def gather_files(directory, extensions):
    """Walks through the directory and puts all files with the correct
    extensions into a list, exits if empty."""
    all_files = []
    for root, _, files in os.walk(directory):
        for file in files:
            if os.path.splitext(file)[1][1:] in extensions:
                all_files.append(os.path.join(root, file))
    if not all_files:
        print("No files detected.\nExiting test.")
        exit(0)
    return all_files


def gather_all_failures(filename, error_count):
    """Goes through each file and gathers all failures within the file."""
    try:
        tree = ElementTree.parse(filename)
    except ElementTree.ParseError:  # If file doesn't parse it's caught by previous check.
        return None
    root = tree.getroot()
    failures = []
    count = 0
    for testcase in root.findall('testcase'):
        for failure in testcase.findall('failure'):
            fail_msg = failure.text
            if not fail_msg:
                fail_msg = failure.attrib['message']
            count += 1

            fail_msg = FAIL_COLOUR + 'ERROR {}: \n'.format(error_count + count) \
                + fail_msg.strip() + '\n'
            failures.append(fail_msg)
    return failures, count



if __name__ == '__main__':
    sys.exit(main())
