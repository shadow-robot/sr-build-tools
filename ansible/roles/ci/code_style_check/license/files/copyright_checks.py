#!/usr/bin/env python3

import argparse
import datetime
import logging
import os
import re
import subprocess
import sys

# We want to use f-strings for logging. Very minor performance hit, better consistency.
# pylint: disable=logging-fstring-interpolation


class CopyrightChecker:
    """ Class for checking Shadow copyright and license information in git repositories. """

    exclusion_regex = r'^exclude_files=(.*)'
    confluence_url = r"https://shadowrobot.atlassian.net/wiki/spaces/SDSR/pages/594411521/Licenses"
    any_copy_right_regex = r"(Copyright)"

    def __init__(self, log_level: int = logging.WARNING, untracked: bool = False, ignored: bool = False) -> None:
        """ Initialise the CopyrightChecker class.

        Args:
            log_level: Logging level; 10 = debug, 20 = info, 30 = warning, 40 = error
            untracked: Whether to check untracked files.
            ignored: Whether to check ignored files.
        """
        logging.basicConfig(level=log_level)
        self._logger = logging.getLogger('Copyright Check')
        self._check_untracked = untracked
        self._check_ignored = ignored
        self._repositories = {}
        self._comment_style_file_extensions = {
            "python": {"extensions": ["py", "msg", "yml", "yaml", "sh"], "exclusions": ["__init__.py", "setup.py"],
                       "comment": "#"},
            "c": {"extensions": ["cpp", "hpp", "h", "c"], "exclusions": [], "comment": "*"},
            "xml": {"extensions": ["xml", "xacro", "dae", "launch"], "exclusions": [], "comment": ""}}
        for comment_style in self._comment_style_file_extensions.values():
            comment_style["regexes"] = {
                "Private": CopyrightChecker.build_regex(comment_style["comment"], "Private"),
                "BSD": CopyrightChecker.build_regex(comment_style["comment"], "BSD"),
                "GPL": CopyrightChecker.build_regex(comment_style["comment"], "GPL")}

    def find_path_repositories(self, path: str) -> None:
        """ Find all Git repositories below a given path and store them in the class dictionary of repositories.

        Also establishes and stores the license type and lists of all, untracked and ignored files in the repositories.

        Args:
            path: Path to search for Git repositories.
        """
        path = os.path.abspath(path)
        # Check path exists
        if not os.path.exists(path):
            self._logger.error(f"Path {path} does not exist")
            sys.exit(1)
        repository_paths = subprocess.check_output(['find', path, '-type', 'd', '-exec', 'test', '-e',
                                                    r'{}/.git', ';', '-print', '-prune']).decode('utf-8').splitlines()
        if not repository_paths:
            self._logger.error(f"No repositories found in {path}")
            sys.exit(1)
        for repository_path in repository_paths:
            repository_name = os.path.basename(repository_path)
            self._repositories[repository_name] = {"path": repository_path}
        self._logger.info(f"Found {len(self._repositories)} repositories in {path}: {self._repositories}")
        for repository in self._repositories.values():
            repository["ignored_files"] = self.get_ignored_files(repository["path"])
            repository["untracked_files"] = self.get_untracked_files(repository["path"])
            self.get_repository_copyright(repository)
            self.get_files(repository)

    def get_repository_copyright(self, repository: dict) -> None:
        """ Get the copyright information for a repository by reading the LICENSE file.

        License type is stored in the supplied repository dictionary.

        Args:
            repository: Dictionary containing the repository path.
        """
        repository["license"] = None
        license_file_path = os.path.join(repository["path"], "LICENSE")
        if not os.path.isfile(license_file_path):
            self.report_issue(license_file_path, f"No license file found for {repository['path']}")
            repository["license"] = None
            return
        try:
            with open(license_file_path, 'r', encoding='utf-8') as license_file:
                repository_license = license_file.read()
                regexes = {"GPL": r"(GNU GENERAL PUBLIC LICENSE)|(GNU LESSER GENERAL PUBLIC LICENSE)",
                           "BSD": r"(BSD 2-Clause License)|(BSD 3-Clause License)",
                           "Private": r"Copyright[\(\)C 0-9]+ Shadow Robot Company Ltd"}
                for license_type, regex in regexes.items():
                    if re.search(regex, repository_license):
                        repository["license"] = license_type
                        self._logger.info(f"Found {repository['license']} license in {license_file_path}")
                        return
                self.report_issue(license_file_path, f"Unknown license type for {repository['path']}")
        except Exception as exception:
            self.report_issue(license_file_path, f"Failed to open license file for {repository['path']}. "
                                                 f"Exception: '{exception}'")

    def report_issue(self, file_path: str, message: str, line: int = 0, column: int = 0) -> None:
        """ Report an issue with a file by printing in a standard format (in order to be problem matcher friendly).

        Args:
            file_path: Path to the file with an issue.
            message: Message describing the issue.
            line: Line number at which the issue occurs.
            column: Column number at which the issue occurs.
        """
        self._logger.warning(f"{file_path}: {line}: {column}: {message}. See {CopyrightChecker.confluence_url}")

    def get_files(self, repository: dict) -> None:
        """ Get files to be checked in a repository and store them in the supplied repository dictionary.

        Ignore files specified in the static type exclusions and file-local `CPPLINT.cfg`, `copyright_exclusions.cfg`
        files. Also ignore Git untracked and ignored files if the corresponding flags are set.

        Args:
            repository: Dictionary containing the repository path.
        """
        repository["files"] = []
        for file_type_name, file_type in self._comment_style_file_extensions.items():
            for file_extension in file_type["extensions"]:
                files = subprocess.check_output(['find', repository["path"], '-type', 'f', '-name',
                                                 f'*.{file_extension}']).decode('utf-8').splitlines()
                for file_path in files:
                    if os.path.basename(file_path) in file_type["exclusions"]:
                        self._logger.info(f"Skipping excluded file {file_path}")
                        continue
                    if not self._check_untracked and file_path in repository["untracked_files"]:
                        self._logger.debug(f"Skipping untracked file {file_path}")
                        continue
                    if (not self._check_ignored) and file_path in repository["ignored_files"]:
                        self._logger.debug(f"Skipping ignored file {file_path}")
                        continue
                    if self.file_excluded(file_path):
                        continue
                    repository["files"].append({"path": file_path, "type": file_type_name, "extension": file_extension})

    def get_ignored_files(self, repository_path: str) -> "list[str]":
        """ Get a list of ignored files in a repository.

        Args:
            repository_path: Path to the repository.
        """
        files = subprocess.check_output(['git', '-C', repository_path, 'ls-files', '--ignored', '--exclude-standard',
                                         '--others']).decode('utf-8').splitlines()
        file_paths = [os.path.join(repository_path, file_path) for file_path in files]
        if file_paths:
            log_string = f"Found {len(file_paths)} ignored files in {repository_path}:"
            for file_path in file_paths:
                log_string = f"{log_string}\n\t{os.path.relpath(file_path, repository_path)}"
            self._logger.info(log_string)
        else:
            self._logger.info(f"Found no ignored files in {repository_path}")
        return file_paths

    def get_untracked_files(self, repository_path: str) -> "list[str]":
        """ Get a list of untracked files in a repository.

        Args:
            repository_path: Path to the repository.
        """
        files = subprocess.check_output(['git', '-C', repository_path, 'ls-files', '--exclude-standard',
                                         '--others']).decode('utf-8').splitlines()
        file_paths = [os.path.join(repository_path, file_path) for file_path in files]
        if file_paths:
            log_string = f"Found {len(file_paths)} untracked files in {repository_path}:"
            for file_path in file_paths:
                log_string = f"{log_string}\n\t{os.path.relpath(file_path, repository_path)}"
            self._logger.info(log_string)
        else:
            self._logger.info(f"Found no untracked files in {repository_path}")
        return file_paths

    def file_excluded(self, file_path: str) -> bool:
        """ Check if a file is excluded by a file-local exclusion file. Return True if the file is excluded."""
        exclusion_filenames = ["CPPLINT.cfg", "copyright_exclusions.cfg"]
        file_directory = os.path.dirname(file_path)
        # For each potential exclusion file
        for exclusion_filename in exclusion_filenames:
            exclusion_file_path = os.path.join(file_directory, exclusion_filename)
            # If the exclusion file exists
            if os.path.isfile(exclusion_file_path):
                # Open it and find the exclusion regex specified by 'exclude_files='
                with open(exclusion_file_path, 'r', encoding='utf-8') as exclusion_file:
                    exclusion_file_contents = exclusion_file.read()
                    match = re.match(CopyrightChecker.exclusion_regex, exclusion_file_contents)
                    # If the exclusion regex is found
                    if match:
                        exclusion_regex = match.group(1)
                        # Compile the regex and check if the tested file path matches it. This implementation matches
                        # the behavior of the cpplint.py script (see
                        # https://github.com/google/styleguide/blob/gh-pages/cpplint/cpplint.py#L5983)
                        exclusion = re.compile(exclusion_regex)
                        if exclusion.match(os.path.basename(file_path)):
                            self._logger.info(f"Info: Skipping file {file_path} excluded by {exclusion_file_path}")
                            return True
        return False

    def check_all_copyright(self, check_years: bool = True) -> bool:
        """ Check copyright for all files in all repositories. Return true if all files are copyright compliant."""
        n_files_checked = 0
        n_files_with_issues = 0
        for repository in self._repositories.values():
            for file_dict in repository["files"]:
                if not self.check_file_copyright(repository, file_dict, check_years):
                    n_files_with_issues += 1
                n_files_checked += 1
        self._logger.info(f"Checked {n_files_checked} files in {len(self._repositories)} repositories, found "
                          f"{n_files_with_issues} files with issues.")
        if not check_years:
            self._logger.info("Ignored years in copyright checks.")
        return n_files_with_issues == 0

    def check_file_copyright(self, repository: dict, file_dict: dict, check_years: bool = True) -> bool:
        """ Check copyright for a file in a repository. Return true if the file is copyright compliant.

        Args:
            repository: Dictionary containing the repository path and license type.
            file_dict: Dictionary containing the file path and type."""
        self._logger.debug(f"Checking {file_dict['path']}")
        # Read file contents ahead of time to avoid opening the file multiple times
        file_contents = ""
        try:
            with open(file_dict["path"], 'r', encoding='utf-8') as open_file:
                file_contents = open_file.read()
        except Exception as exception:
            self.report_issue(file_dict["path"], f"Failed to open file. Exception: '{exception}'")
            return False
        # Check against all regexes for the file type
        for license_type_name, regex in self._comment_style_file_extensions[file_dict["type"]]["regexes"].items():
            match = re.findall(regex, file_contents)
            if match:
                matched_line, matched_char = CopyrightChecker.find_in_string(file_contents, match[0][0])
                # Check if the license type matches the repository license type
                correct = True
                if license_type_name != repository["license"]:
                    self.report_issue(file_dict["path"], f"License type mismatch: {license_type_name} "
                                                         f"license in a {repository['license']} repository",
                                      line=matched_line, column=matched_char)
                    correct = False
                # Check if the years are correct, and return true if both the type and years are correct
                if check_years:
                    correct = self.check_years(match[0][1], file_dict, repository, file_contents) and correct
                return correct
        # If none of the regexes match, check for a malformed copyright notice
        match = re.findall(CopyrightChecker.any_copy_right_regex, file_contents)
        if match:
            matched_line, matched_char = CopyrightChecker.find_in_string(file_contents, match[0][0])
            self.report_issue(file_dict["path"], "Malformed copyright notice", line=matched_line,
                              column=matched_char)
            return False
        # If none of the regexes match, and there is no copyright notice, report an issue
        self.report_issue(file_dict["path"], "No copyright notice found. This file should have a "
                                             f"{repository['license']} copyright notice")
        return False

    @staticmethod
    def find_in_string(string: str, substring: str) -> "tuple[int, int]":
        """ Find the line and column of a substring in a string. Return a tuple containing the line and column."""
        # If the string to be found has multiple lines, only use the first line
        substring = substring.splitlines()[0]
        lines = string.splitlines()
        for line_number, line in enumerate(lines):
            char = line.find(substring)
            if char != -1:
                return line_number + 1, char + 1
        return None, None

    def check_years(self, file_years_string: str, file_dict: dict, repository: dict, file_contents: str) -> bool:
        """ Check if the years in a file's copyright notice are correct. Return true if the years are correct.

        The years that are considered correct are the superset of the years in the file and the years that the file
        was modified.

        Args:
            file_years_string: String containing the years in the file's copyright notice.
            file_dict: Dictionary containing the file path and type.
            repository: Dictionary containing the repository path and license type.
            file_contents: String containing the file contents.
        """
        years = set(CopyrightChecker.string_to_years(file_years_string))
        required_years = set(self.get_file_modified_years(file_dict["path"], repository["path"]))
        required_years = list(years.union(required_years))
        required_years.sort()
        required_years_string = CopyrightChecker.years_to_string(required_years)
        if not file_years_string == required_years_string:
            # If we're proposing modifying the file, then the current year should be added to the list of required years
            current_year = datetime.datetime.now().year
            if current_year not in required_years:
                required_years.append(datetime.datetime.now().year)
                required_years_string = CopyrightChecker.years_to_string(required_years)
            matched_line, matched_char = CopyrightChecker.find_in_string(file_contents, file_years_string)
            self.report_issue(file_dict["path"], f"Incorrect years; \"{file_years_string}\" "
                                                 f"should be: \"{required_years_string}\"",
                              line=matched_line, column=matched_char)
            return False
        self._logger.info(f"Found compliant copyright for {file_dict['path']}.")
        return True

    @staticmethod
    def build_regex(comment_regex: str, license_type: str) -> str:
        """ Build a regex for a given license type and comment style. Return the regex.

        Args:
            comment_regex: Regex for the comment style, e.g. \"#\" for Python.
            license_type: License type, e.g. \"BSD\"."""
        regex = ""
        if license_type == "BSD":
            regex = ("Software License Agreement (BSD License) Copyright © <Year> belongs to Shadow Robot Company "
                     "Ltd. All rights reserved. Redistribution and use in source and binary forms, with or without "
                     "modification, are permitted provided that the following conditions are met: "
                     "1. Redistributions of source code must retain the above copyright notice, this list of "
                     "conditions and the following disclaimer. "
                     "2. Redistributions in binary form must reproduce the above copyright notice, this list of "
                     "conditions and the following disclaimer in the documentation and/or other materials provided "
                     "with the distribution. "
                     "3. Neither the name of Shadow Robot Company Ltd nor the names of its contributors may be used to "
                     "endorse or promote products derived from this software without specific prior written "
                     "permission. "
                     "This software is provided by Shadow Robot Company Ltd \"as is\" and any express or implied "
                     "warranties, including, but not limited to, the implied warranties of merchantability and fitness "
                     "for a particular purpose are disclaimed. In no event shall the copyright holder be liable for "
                     "any direct, indirect, incidental, special, exemplary, or consequential damages (including, but "
                     "not limited to, procurement of substitute goods or services; loss of use, data, or profits; or "
                     "business interruption) however caused and on any theory of liability, whether in contract, "
                     "strict liability, or tort (including negligence or otherwise) arising in any way out of the use "
                     "of this software, even if advised of the possibility of such damage.")
        elif license_type == "GPL":
            regex = ("Copyright <Year> Shadow Robot Company Ltd. This program is free software: you can redistribute "
                     "it and/or modify it under the terms of the GNU General Public License as published by the Free "
                     "Software Foundation version 2 of the License. This program is distributed in the hope that it "
                     "will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY "
                     "or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details. You "
                     "should have received a copy of the GNU General Public License along with this program. If not, "
                     "see <http://www.gnu.org/licenses/>.")
        else:
            regex = ("Copyright (C) <Year> Shadow Robot Company Ltd - All Rights Reserved. Proprietary and "
                     "Confidential. Unauthorized copying of the content in this file, via any medium is strictly "
                     "prohibited.")
        # Escape regex special characters
        regex = re.escape(regex)
        # Replace whitespace with a regex that matches whitespace, newlines and comments
        regex = regex.replace(r"\ ", r"[\s" + comment_regex + r']+')
        # Replace forward slashes with a regex that matches forward slashes
        regex = regex.replace(r"\/", r"\\/")
        # Replace <Year> with a regex that matches <Year> or a string of 4 or more digits, dashes, commas or spaces
        regex = regex.replace(r'<Year>', r"(<Year>|[\d,\-\s]{4,})")
        # Surround the regex with parentheses such that the entire regex is captured
        regex = f"({regex})"
        return regex

    @staticmethod
    def years_to_string(years: "list[int]", min_range_length: int = 2) -> str:
        """ Convert a list of years to a string. Return the string.

        Merges consecutive years of more than min_range_length into a range, e.g. [2015, 2016, 2017] becomes
        "2015-2017" if min_range_length is <=2.

        Args:
            years: List of years.
            min_range_length: Minimum length of a range of consecutive years to be merged into a range.
        """
        if len(years) == 0:
            return ""
        if len(years) == 1:
            return str(years[0])
        years.sort()
        years_string = ""
        current_range_start_index = 0
        for i in range(0, len(years)):
            previous_consecutive = i != 0 and years[i] == years[i - 1] + 1
            next_consecutive = i != len(years) - 1 and years[i] == years[i + 1] - 1
            # If this year is consecutive to the previous one
            if previous_consecutive:
                # If this year is consecutive to the next year
                if next_consecutive:
                    # We're in the middle of a range, continue
                    continue
                else:
                    # We're at the end of a range
                    # If the range is long enough, add it as a range
                    if years[i] - years[current_range_start_index] >= min_range_length:
                        years_string += f"{years[current_range_start_index]}-{years[i]}, "
                    else:
                        # Otherwise, add each year individually
                        for year in years[current_range_start_index:i + 1]:
                            years_string += f"{year}, "
            else:
                # Not consecutive to the previous
                # If consecutive to the next, we're at the start of a range
                if next_consecutive:
                    current_range_start_index = i
                    continue
                else:
                    # Not consecutive to the next, add this year individually
                    years_string += f"{years[i]}, "
        return years_string[:-2]

    @staticmethod
    def string_to_years(years_string: str) -> "list[int]":
        """ Convert a string of years to a list of integer years. Return the list.

        Handles ranges of years, e.g. "2011, 2015-2017" becomes [2011, 2015, 2016, 2017].

        Args:
            years_string: String of years, e.g. "2011, 2015-2017".
        """
        years = []
        for year_range in years_string.split(","):
            # If the string is just a placeholder, skip it
            if year_range == "<Year>":
                continue
            if "-" in year_range:
                year_range = year_range.split("-")
                years.extend(range(int(year_range[0]), int(year_range[1]) + 1))
                continue
            years.append(int(year_range))
        return years

    def get_file_modified_years(self, file_path: str, repo_path: str) -> "list[int]":
        """ Get the years in which a file was modified. Return the list of years.

        Uses git to get the years in which a file was modified. If the file is locally modified, the current year is
        added to the list of years in which the file was modified.

        Args:
            file_path: Path to the file.
            repo_path: Path to the repository.
        """
        file_path = os.path.relpath(file_path, repo_path)
        git_years = subprocess.check_output(
            ["git", "-C", repo_path, "log", "--follow", "--format=%as", "--", file_path]).decode(
                "utf-8").splitlines()
        git_years = list(set([int(line.split("-")[0]) for line in git_years]))
        git_years.sort()
        self._logger.debug(f"File {file_path} git modified years: {git_years}")
        git_file_status = subprocess.check_output(
            ["git", "-C", repo_path, "status", "--porcelain", "--", file_path]).decode("utf-8").splitlines()
        if git_file_status:
            current_year = datetime.datetime.now().year
            if current_year not in git_years:
                git_years.append(current_year)
                self._logger.info(f"File {file_path} locally modified, adding current year to requred years.")
        return git_years


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.description = ("Finds all source files below a given path, and checks that those files' copyright "
                          "notices, including years.")
    parser.add_argument('-p', '--path', required=True, help='Path to check')
    parser.add_argument('-v', '--verbose', dest='verbosity', action='count', help='Increase verbosity', default=0)
    parser.add_argument('-u', '--untracked', dest='untracked', action='store_true', help='Check files untracked by git')
    parser.add_argument('-i', '--ignored', dest='ignored', action='store_true', help='Check files ignored by git')
    parser.add_argument('-q', '--quiet', dest='quiet', action='store_true', help='Check files ignored by git')
    parser.add_argument('--no-year-check', dest='check_years', action='store_false',
                        help='Don\'t check copyright years')
    args = parser.parse_args()
    logging_level = logging.ERROR if args.quiet else logging.WARNING - (args.verbosity) * 10
    copyright_checker = CopyrightChecker(logging_level, args.untracked, args.ignored)
    copyright_checker.find_path_repositories(args.path)
    if copyright_checker.check_all_copyright(args.check_years):
        sys.exit(0)
    sys.exit(1)
