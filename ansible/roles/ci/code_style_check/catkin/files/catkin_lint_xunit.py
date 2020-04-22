#!/usr/bin/env python3

# Copyright 2014-2018 Open Source Robotics Foundation, Inc.
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
import shutil
import subprocess
import sys
import time
from xml.sax.saxutils import escape
from xml.sax.saxutils import quoteattr


def main(argv=sys.argv[1:]):
    
    parser = argparse.ArgumentParser(
        description='Check a package using catkin_lint.',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument(
        'paths',
        nargs='*',
        default=[os.curdir],
        help='The package or folder with packages to check with catkin_lint')
    # not using a file handle directly
    # in order to prevent leaving an empty file when something fails early
    parser.add_argument(
        '--xunit-file',
        help='Generate a xunit compliant XML file')
    args = parser.parse_args(argv)

    if args.xunit_file:
        start_time = time.time()

    packages = args.paths
    if not packages:
        print('No packages found', file=sys.stderr)
        return 1
    packages = [os.path.abspath(f) for f in packages]

    catkinlint_bin = shutil.which('catkin_lint')
    if not catkinlint_bin:
        return "Could not find 'catkin_lint' executable"

    report = []

    # invoke catkin_lint on all packages
    for packagename in packages:
        
        cmd = [catkinlint_bin, '-W0','-q', packagename]

        try:
            subprocess.check_output(
                cmd, cwd=os.path.dirname(packagename), stderr=subprocess.STDOUT)
        except subprocess.CalledProcessError as e:
            errors = e.output.decode()
        else:
            errors = None

        report.append((packagename, errors))

    for (packagename, errors) in report:
        if errors is not None:
            print("Package '%s' is invalid:" % packagename, file=sys.stderr)
            for line in errors.splitlines():
                print(os.path.dirname(packagename)+'/'+line, file=sys.stderr)
            print('', file=sys.stderr)
        else:
            print("Package '%s' is valid" % packagename)
            print('')

    # output summary
    error_count = sum(1 if r[1] else 0 for r in report)
    if not error_count:
        print('No problems found')
        rc = 0
    else:
        print('%d package(s) are invalid' % error_count, file=sys.stderr)
        rc = 1

    # generate xunit file
    if args.xunit_file:
        folder_name = os.path.basename(os.path.dirname(args.xunit_file))
        file_name = os.path.basename(args.xunit_file)
        suffix = '.xml'
        if file_name.endswith(suffix):
            file_name = file_name[0:-len(suffix)]
            suffix = '.xunit'
            if file_name.endswith(suffix):
                file_name = file_name[0:-len(suffix)]
        testname = '%s.%s' % (folder_name, file_name)

        xml = get_xunit_content(report, testname, time.time() - start_time)
        path = os.path.dirname(os.path.abspath(args.xunit_file))
        if not os.path.exists(path):
            os.makedirs(path)
        with open(args.xunit_file, 'w') as f:
            f.write(xml)

    return rc


def get_xunit_content(report, testname, elapsed):
    test_count = len(report)
    error_count = len([r for r in report if r[1]])
    data = {
        'testname': testname,
        'test_count': test_count,
        'error_count': error_count,
        'time': '%.3f' % round(elapsed, 3),
    }
    xml = """<?xml version="1.0" encoding="UTF-8"?>
<testsuite
  name="%(testname)s"
  tests="%(test_count)d"
  errors="0"
  failures="%(error_count)d"
  time="%(time)s"
>
""" % data

    for (packagename, diff_lines) in report:
        if diff_lines:
            # report any diff as a failing testcase
            data = {
                'quoted_location': quoteattr(packagename),
                'testname': testname,
                'quoted_message': quoteattr('Diff with %d lines' % len(diff_lines)),
                'cdata': ''.join([os.path.dirname(packagename)+'/'+line for line in diff_lines]),
            }
            xml += """  <testcase
    name=%(quoted_location)s
    classname="%(testname)s"
  >
      <failure message=%(quoted_message)s><![CDATA[%(cdata)s]]></failure>
  </testcase>
""" % data

        else:
            # if there is no diff report a single successful test
            data = {
                'quoted_location': quoteattr(packagename),
                'testname': testname,
            }
            xml += """  <testcase
    name=%(quoted_location)s
    classname="%(testname)s"/>
""" % data

    # output list of checked packages
    data = {
        'escaped_packages': escape(''.join(['\n* %s' % r[0] for r in report])),
    }
    xml += """  <system-out>Checked packages:%(escaped_packages)s</system-out>
""" % data

    xml += '</testsuite>\n'
    return xml


if __name__ == '__main__':
    sys.exit(main())