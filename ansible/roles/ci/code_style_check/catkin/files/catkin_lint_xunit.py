#!/usr/bin/env python3
#
# Copyright 2020 Shadow Robot Company Ltd.
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
    parser.add_argument(
        '--xunit-file',
        help='The path where a xunit compliant XML file should be created')
    parser.add_argument(
        '--lintignore',
        help='Name of the lintignore file for catkin (normally .catkin_lint_ignore)')
    args = parser.parse_args(argv)
    packages = args.paths
    if not packages:
        print('No packages found', file=sys.stderr)
        return 1
    packages = [os.path.abspath(package) for package in packages]
    catkinlint_bin = shutil.which('catkin_lint')
    if not catkinlint_bin:
        print("Could not find 'catkin_lint' executable", file=sys.stderr)
        return 1
    error_report=run_catkin_lint(packages,args.lintignore,catkinlint_bin)
    if args.xunit_file:
        start_time = time.time()
    generate_xunit_file(error_report,args.xunit_file,start_time)


def run_catkin_lint(packages, lintignore,catkinlint_bin):
    report = []
    for packagename in packages:
        skip_package=False
        cmd = [catkinlint_bin, '-W0', '-q', packagename]
        if lintignore:
            lintignore_path = packagename+'/'+lintignore
            if os.path.isfile(lintignore_path):
                if os.stat(lintignore_path).st_size == 0:
                    skip_package=True
                else:
                    with open(lintignore_path) as lintignore_file:
                        lintignore_lines = lintignore_file.read().splitlines()
                    full_ignore=','.join(lintignore_lines)
                    cmd = [catkinlint_bin, '-W0', '-q', '--ignore', full_ignore, packagename]
        if skip_package:
            continue
        try:
            subprocess.check_output(
                cmd, cwd=os.path.dirname(packagename), stderr=subprocess.STDOUT)
        except subprocess.CalledProcessError as process_error:
            errors = process_error.output.decode()
        else:
            errors = None
        report.append((packagename, errors))
    return report


def generate_xunit_file(report, xunit_file_path, start_time):
    if xunit_file_path:
        folder_name = os.path.basename(os.path.dirname(xunit_file_path))
        file_name = os.path.basename(xunit_file_path)
        suffix = '.xml'
        if file_name.endswith(suffix):
            file_name = file_name[0:-len(suffix)]
            suffix = '.xunit'
            if file_name.endswith(suffix):
                file_name = file_name[0:-len(suffix)]
        testname = '%s.%s' % (folder_name, file_name)
        xunit_xml = get_xunit_content(report, testname, time.time() - start_time)
        xunit_folder = os.path.dirname(os.path.abspath(xunit_file_path))
        if not os.path.exists(xunit_folder):
            os.makedirs(xunit_folder)
        with open(xunit_file_path, 'w') as xunit_file:
            xunit_file.write(xunit_xml)


def get_xunit_content(report, testname, elapsed):
    test_count = len(report)
    xunit_xml_content = {
        'testname': testname,
        'test_count': test_count,
        'time': '%.3f' % round(elapsed, 3),
    }
    xunit_xml = """<?xml version="1.0" encoding="UTF-8"?>
<testsuite
  name="%(testname)s"
  tests="%(test_count)d"
  time="%(time)s"
>
""" % xunit_xml_content
    xunit_xml+=get_failure_messages(report, testname, xunit_xml)
    return xunit_xml

def get_failure_messages(report, testname, elapsed):
    failure_messages=""
    for (packagename, lines) in report:
        if lines:
            xunit_xml_content = {
                'quoted_location': quoteattr(packagename),
                'testname': testname,
                'quoted_message': quoteattr('catkin_lint report has %d line(s)' % len(lines.splitlines())),
                'cdata': "\n".join([os.path.dirname(packagename)+'/'+line for line in lines.splitlines()]),
            }
            failure_messages += """  <testcase
    name=%(quoted_location)s
    classname="%(testname)s"
  >
      <failure message=%(quoted_message)s><![CDATA[%(cdata)s]]></failure>
  </testcase>
""" % xunit_xml_content
        else:
            xunit_xml_content = {
                'quoted_location': quoteattr(packagename),
                'testname': testname,
            }
            failure_messages += """  <testcase
    name=%(quoted_location)s
    classname="%(testname)s"/>
""" % xunit_xml_content
    xunit_xml_content = {
        'escaped_packages': escape(''.join(['\n* %s' % lines[0] for lines in report])),
    }
    failure_messages += """  <system-out>Checked packages:%(escaped_packages)s</system-out>
""" % xunit_xml_content
    failure_messages += '</testsuite>\n'
    return failure_messages


if __name__ == '__main__':
    sys.exit(main())
