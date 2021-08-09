#!/usr/bin/env python3

# Copyright 2014-2018, 2021 Open Source Robotics Foundation, Inc.
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
import rospkg
from xml.etree import ElementTree
from xml.sax import make_parser
from xml.sax import SAXParseException
from xml.sax.handler import ContentHandler
from xml.sax.saxutils import escape
from xml.sax.saxutils import quoteattr


def main(argv=sys.argv[1:]):
    extensions = ['xml', 'launch', 'xacro']

    parser = argparse.ArgumentParser(
        description='Check XML markup using xmllint.',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument(
        '--path',
        nargs='*',
        default=[os.curdir],
        help='The files or directories to check. For directories files ending '
             'in %s will be considered.' %
             ', '.join(["'.%s'" % e for e in extensions]))
    parser.add_argument(
        '--exclude',
        nargs='*',
        default=[],
        help='Exclude specific file names and directory names from the check')
    # not using a file handle directly
    # in order to prevent leaving an empty file when something fails early
    parser.add_argument(
        '--xunit-file',
        help='Generate a xunit compliant XML file')
    parser.add_argument(
        '--debug',
        default=False,
        help='Enabled debug mode. Adds more prints.'
    )
    args = parser.parse_args(argv)

    if args.xunit_file:
        start_time = time.time()
    files = gather_files(args.path[0], extensions)
    if not files:
        print('No files found', file=sys.stderr)
        return 1
    files = [os.path.abspath(f) for f in files]

    xmllint_bin = shutil.which('xmllint')
    if not xmllint_bin:
        return "Could not find 'xmllint' executable"

    report = []

    # invoke xmllint on all files
    for filename in files:
        # parse file to extract desired validation information
        parser = make_parser()
        handler = CustomHandler()
        parser.setContentHandler(handler)
        try:
            parser.parse(filename)
        except SAXParseException:
            pass

        dependencies = gather_all_dependencies(filename)
        if dependencies:
            errors = test_dependencies(dependencies, filename)
        else:
            errors = None

        filename = os.path.relpath(filename, start=os.getcwd())
        report.append((filename, errors))
    if args.debug:
        for (filename, errors) in report:
            if errors is not None:
                errormsg = "File '{}' is invalid: ".format(filename)
                for line in errors.splitlines():
                    errormsg += line.strip() + " "
                print(errormsg, file=sys.stderr)
                print('', file=sys.stderr)
        # output summary
    error_count = sum(1 if r[1] else 0 for r in report)
    if not error_count:
        if args.debug:
            print('No problems found')
        rc = 0
    else:
        if args.debug:
            print('%d files are invalid' % error_count, file=sys.stderr)
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


def gather_all_dependencies(filename):
    """Goes through each file and gathers all includes within the file."""
    try:
        tree = ElementTree.parse(filename)
    except ElementTree.ParseError:  # If file doesn't parse it's caught by previous check.
        return None
    root = tree.getroot()
    dependencies = []
    for dep in root.findall('include'):
        fulldep = ElementTree.tostring(dep).decode("utf-8").split('\n')[0]
        dependencies.append((fulldep, dep.attrib['file']))
    for dep in root.findall('xacro:include'):
        fulldep = ElementTree.tostring(dep).decode("utf-8").split('\n')[0]
        dependencies.append((fulldep, dep.attrib['filename']))
    return dependencies


def test_dependencies(dependencies, path):
    """Goes through the gatered deps and checks they are valid. Checks with default values for launch
    files which contain arguments. Returns an error string for the given file."""
    errors = None
    for (fulldepstr, dep) in dependencies:
        path_string = ''
        for path_element in dep.split('/'):
            if "$(find" in path_element:
                continue  # Gathered later
            elif "$(arg" in path_element:
                defaultval = get_dependency_args(dep, path)
                rest_of_string = path_element.split(')')[1]
                path_string += "/" + defaultval + rest_of_string
            else:
                path_string += "/" + path_element
        package_path = dep.split('$(find ')[1].split(')')[0]
        rp = rospkg.RosPack()
        try:
            package_path = rp.get_path(package_path)
            full_path = package_path + path_string
            if not os.path.exists(full_path):
                if errors:
                    errors += " THIS FILE WAS NOT FOUND '{}' ERROR ON THE LINE: {}".format(full_path, fulldepstr)
                else:
                    errors = "{} THIS FILE WAS NOT FOUND '{}' ERROR ON THE LINE: {}".format(path, full_path, fulldepstr)
        except rospkg.ResourceNotFound as e:
            if errors:
                errors += " ROS PACKAGE NOT FOUND '{}' ERROR ON THE LINE: {}".format(
                    str(e).split('\n')[0], fulldepstr)
            else:
                errors = "{} ROS PACKAGE NOT FOUND: '{}' ERROR ON THE LINE: {}".format(
                    path, str(e).split('\n')[0], fulldepstr)
    return errors


def get_dependency_args(dependency, path):
    """This function is used to get the default value of a dependencies argument."""
    try:
        tree = ElementTree.parse(path)
    except ElementTree.ParseError:  # If file doesn't parse it's caught by previous check.
        return None
    root = tree.getroot()
    argument = dependency.split("$(arg ")[1].split(")")[0]
    for arg in root.findall('arg'):
        if arg.attrib["name"] == argument:
            return arg.attrib["default"]


class CustomHandler(ContentHandler):

    def __init__(self):
        super().__init__()
        self.xml_model_attributes = []
        self.root_attributes = {}
        self._first_node = False

    def processingInstruction(self, target, data):
        if target != 'xml-model':
            return

        root = ElementTree.fromstring('<data ' + data + '/>')
        self.xml_model_attributes.append(root.attrib)

    def startDocument(self):
        self._first_node = True

    def startElement(self, name, attrs):
        if not self._first_node:
            return
        self._first_node = False
        for attr_name in attrs.getNames():
            self.root_attributes[attr_name] = attrs.getValue(attr_name)


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

    for (filename, diff_lines) in report:

        if diff_lines:
            # report any diff as a failing testcase
            data = {
                'quoted_location': quoteattr(filename),
                'testname': testname,
                'quoted_message': quoteattr(
                    'Diff with %d lines' % len(diff_lines)
                ),
                'cdata': ''.join(diff_lines),
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
                'quoted_location': quoteattr(filename),
                'testname': testname,
            }
            xml += """  <testcase
    name=%(quoted_location)s
    classname="%(testname)s"/>
""" % data

    # output list of checked files
    data = {
        'escaped_files': escape(''.join(['\n* %s' % r[0] for r in report])),
    }
    xml += """  <system-out>Checked files:%(escaped_files)s</system-out>
""" % data

    xml += '</testsuite>\n'
    return xml


if __name__ == '__main__':
    sys.exit(main())
