#!/usr/bin/env python3

# Copyright 2023 Shadow Robot Company Ltd.
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

import re
import sys
import subprocess

# The output from catkin_lint is inconsistent and can't be used with problem matchers, such as that of VS Code.
# This script wraps catkin_lint, and tries to match and re-format its output. All arguments to this script are passed
# to catkin_lint.

try:
    catkin_lint_output = subprocess.check_output(['catkin_lint'] + sys.argv[1:], stderr=subprocess.STDOUT).decode(
        'utf-8')
except subprocess.CalledProcessError as e:
    catkin_lint_output = e.output.decode('utf-8')

print('\nThe following catkin_lint output lines were matched and re-formatted for problem matchers:\n')

# Collect package paths for absolute file path output
package_paths = {}
for line in subprocess.check_output(['rospack', 'list']).decode('utf-8').splitlines():
    package_paths[line.split()[0]] = line.split()[1]


# Retrieve package paths, or fall back to en educated guess
def get_package_path(package_name: str) -> str:
    if package_name not in package_paths:
        print('Could not find package path for package: ' + package_name)
        package_paths[package_name] = f'{sys.argv[-1:][0]}/{package_name}'
        print(f'Falling back to {package_paths[package_name]}')
    return package_paths[package_name]


# To prevent lines being matched multiple times by different patterns, they are removed when they match.
remaining_output = catkin_lint_output

regex = r'(^(.*?):\s(.*?)(?:\((\d+)\))?:\s(.*?):\s(.*?)$)'

for match in re.findall(regex, remaining_output, re.MULTILINE):
    package_path = get_package_path(match[1])
    if match[3] == '':
        print(f'{package_path}/{match[2]}:0:{match[4]}:{match[5]}')
    else:
        print(f'{package_path}/{match[2]}:{match[3]}:{match[4]}:{match[5]}')
    remaining_output = remaining_output.replace(f'\n{match[0]}', '')

regex = r"(^(.*?):\s(.*?): (file '(.*?)'.*)$)"

for match in re.findall(regex, remaining_output, re.MULTILINE):
    package_path = get_package_path(match[1])
    print(f'{package_path}/{match[4]}:0:{match[2]}:{match[3]}')
    remaining_output = remaining_output.replace(f'\n{match[0]}', '')

print('\nThe following catkin_lint output lines were not matched and re-formatted for problem matchers:\n')
print(f'{remaining_output}')
