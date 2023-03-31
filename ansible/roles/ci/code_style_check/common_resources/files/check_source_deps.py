#!/usr/bin/env python3

import argparse
import logging
import os
import re
import subprocess
import sys

# We want to use f-strings for logging. Very minor performance hit, better consistency.
# pylint: disable=logging-fstring-interpolation


class SourceDependencyChecker:
    """ Checks that source dependencies listed in ROS packages' package.xml are also listed in the package's parent
    repository repository.rosinstall file. """

    def __init__(self, log_level: int = logging.WARNING) -> None:
        """ Initialise the SourceDependencyChecker class.

        Args:
            log_level: The logging level to use. Defaults to logging.WARNING.
        """
        logging.basicConfig(level=log_level)
        self._logger = logging.getLogger('Source Dep Check')
        self._n_problems = 0
        self._checked_packages = {}
        self.collect_packages()

    def collect_packages(self):
        """ Collect all packages on the system, and split them into binary and source packages. """
        self._all_package_paths = {}
        for line in subprocess.check_output(['rospack', 'list']).decode('utf-8').splitlines():
            self._all_package_paths[line.split()[0]] = line.split()[1]
        self._binary_packages = {k: v for k, v in self._all_package_paths.items() if v.startswith('/opt/')}
        self._source_packages = {k: v for k, v in self._all_package_paths.items() if not v.startswith('/opt/')}

    def find_path_packages(self, path: str):
        """ Find all source packages below the given path, and stores them for later checking.

        Args:
            path: The path to search for packages below."""
        for package_name, package_path in self._source_packages.items():
            if package_path.startswith(path):
                self._checked_packages[package_name] = package_path

    def check_package_dependencies(self):
        """ Check all source packages found by find_path_packages for source dependencies, and check that any source
        dependencies are also listed in the package's parent repository's repository.rosinstall file."""
        for package_name, package_path in self._checked_packages.items():
            self._logger.info(f"Checking {package_name} ({package_path}")
            # Get all dependencies of the package
            dependencies = subprocess.check_output(['rosdep', 'keys', package_name]).decode('utf-8').splitlines()
            # Find which ones are source dependencies
            source_dependencies = {}
            for dependency in dependencies:
                if dependency in self._source_packages.keys():
                    # Find the location of the dependency in the package.xml while we're here
                    source_dependencies[dependency] = {
                        "location": SourceDependencyChecker.find_in_file(
                            f'{package_path}/package.xml', f'>{dependency}')}
            # If there are no source dependencies, we're done
            if not source_dependencies:
                continue
            # Pre-populate an error string to use if there are problems with the repository.rosinstall file
            first_source_dependency = list(source_dependencies.values())[0]
            location_string = (f'{package_path}/package.xml:{first_source_dependency["location"][0] + 1}:'
                               f'{first_source_dependency["location"][1] + 2}')
            # Find the parent repository of the package being checked
            package_repository = subprocess.check_output(
                ['git', '-C', f'{package_path}', 'rev-parse', '--show-toplevel']).decode('utf-8').strip()
            # And check it has a rosinstall file
            repository_rosinstall_path = f'{package_repository}/repository.rosinstall'
            if not os.path.isfile(repository_rosinstall_path):
                self._logger.warning(
                    f"{location_string}: {package_name} has dependencies on source packages "
                    f"({list(source_dependencies.keys())}) but no repository.rosinstall file!")
                self._n_problems += 1
                continue
            rosinstall_contents = ""
            try:
                with open(repository_rosinstall_path, 'r', encoding='utf-8') as rosinstall_file:
                    rosinstall_contents = rosinstall_file.read()
            except IOError:
                self._logger.error(f"{location_string}: Could not read {repository_rosinstall_path}!")
                self._n_problems += 1
                continue
            for source_dependency_name, source_dependency in source_dependencies.items():
                # Check that the source dependency is not in the same repository as the package being checked
                dependency_repository_path = subprocess.check_output(
                    ['git', '-C', f'{self._source_packages[source_dependency_name]}', 'rev-parse',
                     '--show-toplevel']).decode('utf-8').strip()
                if dependency_repository_path == package_repository:
                    continue
                # Pre-populate an error string to use if there are problems with this source dependency
                location_string = (f'{package_path}/package.xml:{source_dependency["location"][0] + 1}:'
                                   f'{source_dependency["location"][1] + 2}')
                source_dependency_repositories = subprocess.check_output(
                    ['git', '-C', f'{self._source_packages[source_dependency_name]}', 'remote',
                     '-v']).decode('utf-8').strip()
                regex = r'origin\s*\S*\.com(?:\:|\/)([\S]+)(?:\.git)*'
                match = re.findall(regex, source_dependency_repositories, re.MULTILINE)
                if not match:
                    self._logger.error(
                        f'{location_string}: Could not parse repository URL for {source_dependency_name} (in '
                        f'{self._source_packages[source_dependency_name]})!')
                    self._n_problems += 1
                    continue
                source_dependency_repository = match[0]
                if source_dependency_repository not in rosinstall_contents:
                    self._logger.warning(
                        f'{location_string}: {package_name} has source dependency {source_dependency_name} '
                        f'but {package_repository}/repository.rosinstall does not contain '
                        f'{source_dependency_repository}!')
                    self._n_problems += 1
                else:
                    self._logger.info(
                        f'{location_string}: {package_name} has source dependency {source_dependency_name} and '
                        f'repository.rosinstall contains {source_dependency_repository}!')

    @staticmethod
    def find_in_file(file_path: str, string_to_find: str) -> "tuple(int, int)":
        """ Find the first occurrence of a string in a file, and return the line number and column number."""
        with open(file_path, 'r', encoding='utf-8') as file_to_search:
            for line_number, line in enumerate(file_to_search):
                if string_to_find in line:
                    return (line_number, line.find(string_to_find))
        return None

    def summary(self):
        """ Print a summary of the results of the checks, and exit with a non-zero exit code if any problems were
        found."""
        self._logger.info(f'Checked {len(self._checked_packages)} packages and found {self._n_problems} problems.')
        if self._n_problems == 0:
            sys.exit(0)
        sys.exit(1)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.description = ("Finds all source packages below a given path, and checks that those packages' source "
                          "dependencies are listed in their parent repository's repository.rosinstall file.")
    parser.add_argument('-p', '--path', required=True, help='Path to check')
    parser.add_argument('-v', '--verbose', dest='verbosity', action='count', help='Increase verbosity', default=0)
    parser.add_argument('-q', '--quiet', dest='quiet', action='store_true', help='Check files ignored by git')
    args = parser.parse_args()
    logging_level = logging.ERROR if args.quiet else logging.WARNING - (args.verbosity) * 10
    source_dependency_checker = SourceDependencyChecker(logging_level)
    source_dependency_checker.find_path_packages(args.path)
    source_dependency_checker.check_package_dependencies()
    source_dependency_checker.summary()
