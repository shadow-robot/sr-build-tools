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

import argparse
import os
import subprocess
import sys
from xml.etree import ElementTree


def main(argv=None):
    if not argv:
        argv=sys.argv[1:]

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
    failure_count = 0
    failures = []
    for filename in files:
        failed_tests, count_e, count_f = gather_all_failures(filename, error_count, failure_count)
        if failed_tests is None:
            continue
        error_count += count_e
        failure_count += count_f
        failures = failures + failed_tests
    if error_count == 0 and failure_count == 0:
        output_to_cmd('TESTS SUCCEEDED. NO FAILURES OR ERRORS DETECTED.')
        return 0

    output_to_cmd('\n')
    for fail_msg in failures:
        output_to_cmd(fail_msg)

    if error_count > 0 and failure_count == 0:
        total_error_msg = "\nERRORS FOUND IN TEST. {} ERRORS FOUND.".format(error_count)
    elif failure_count > 0 and error_count == 0:
        total_error_msg = "\nFAILURES FOUND IN TEST. {} FAILURES FOUND.".format(failure_count)
    else:
        total_error_msg = "\nISSUES FOUND IN TEST. {} ERRORS AND {} FAILURES FOUND.".format(error_count, failure_count)
    output_to_cmd(total_error_msg)
    return 1


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
        sys.exit(0)
    return all_files


def gather_all_failures(filename, error_count, failure_count):
    """Goes through each file and gathers all failures within the file."""
    try:
        tree = ElementTree.parse(filename)
    except ElementTree.ParseError:  # If file doesn't parse it's caught by previous check.
        return None, None, None
    root = tree.getroot()
    failures = []
    count_e = 0
    count_f = 0
    for testcase in root.findall('testcase'):
        for failure in testcase.findall('failure'):
            fail_msg = failure.text
            if not fail_msg:
                fail_msg = failure.attrib['message']
            count_f += 1
            fail_msg = 'FAILURE {}: \n'.format(failure_count + count_f) \
                + fail_msg.strip() + '\n'
            sys_err = root.find('system-err')
            if sys_err is not None:
                message = sys_err.text
                # Range [10:-8] cuts out the ![CDATA[& and [0m ]]&gt from the end of the string
                fail_msg = fail_msg + message.strip()[10:-8] + '\n'
            failures.append(fail_msg)
        for error in testcase.findall('error'):
            error_msg = error.text
            if not error_msg:
                error_msg = error.attrib['message']
            count_e += 1
            error_msg = 'ERROR {}: \n'.format(error_count + count_e) \
                + error_msg.strip() + '\n'
            sys_err = root.find('system-err')
            if sys_err is not None:
                message = sys_err.text
                error_msg = error_msg + message.strip()[10:-8] + '\n'
            failures.append(error_msg)
    return failures, count_e, count_f


def output_to_cmd(string):
    """Simple function to echo a string to terminal."""
    subprocess.call(['echo', '-e', string])


if __name__ == '__main__':
    sys.exit(main())
