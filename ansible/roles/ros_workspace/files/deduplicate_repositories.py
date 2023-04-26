#!/usr/bin/env python3

import argparse
import logging
import os
import re
import subprocess
import sys

# We want to use f-strings for logging. Very minor performance hit, better consistency.
# pylint: disable=logging-fstring-interpolation


class RepoDeduplicator:
    """ Class for checking Shadow copyright and license information in git repositories. """

    methods = ["closest", "furthest"]
    method_explanations = [
        "delete the repositories closest to the root directory",
        "delete the repositories furthest from the root directory"]
    method_help = ", ".join(
        [f"'{method}' ({explanation})" for method, explanation in zip(methods, method_explanations)])

    def __init__(self, log_level: int = logging.WARNING, wet_run: bool = False) -> None:
        """ Initialise the RepoDeduplicator class.

        Args:
            log_level: Logging level; 10 = debug, 20 = info, 30 = warning, 40 = error
            untracked: Whether to check untracked files.
            ignored: Whether to check ignored files.
        """
        logging.basicConfig(level=log_level)
        self._logger = logging.getLogger('Copyright Check')
        self._wet_run = wet_run
        self._repositories = []
        self._duplicates = []

    def find_path_repositories(self, path: str) -> None:
        """ Find all Git repositories below a given path and store them in the class member variable _repositories.

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
        url_regex = re.compile(r'(?:(?:git@github\.com:)|(?:https:\/\/github.com\/))(\S*?)(?:\.git)*$')
        for repository_path in repository_paths:
            repository_name = os.path.basename(repository_path)
            full_repository_url = subprocess.check_output(
                ['git', '-C', repository_path, 'config', '--get', 'remote.origin.url']).decode('utf-8').strip()
            match = url_regex.search(full_repository_url)
            if not match:
                self._logger.error(f"Could not find repository name in {full_repository_url}")
                sys.exit(1)
            repository_url = match.group(1)
            self._repositories.append({
                "path": repository_path, "name": repository_name,
                "full_url": full_repository_url, "url": repository_url})
        self._logger.debug(f"Found {len(self._repositories)} repositories in {path}: {self._repositories}")

    def find_duplicates(self) -> None:
        """ Find duplicate repositories in the class member variable _repositories and store them in the class member
        variable _duplicates.

        Duplicates are defined as repositories with the same URL.
        """
        all_repo_urls = list(set([repo['url'] for repo in self._repositories]))
        for repo_url in all_repo_urls:
            repos = [repo for repo in self._repositories if repo['url'] == repo_url]
            if len(repos) > 1:
                self._duplicates.append(repos)
        if self._duplicates:
            self._logger.info(f"Found {len(self._duplicates)} duplicates: {self._duplicates}")

    def delete_duplicates(self, method: str = "closest"):
        """ Delete duplicate repositories in the class member variable _duplicates.

        Args:
            method: Method to decide which repos to delete. Valid options are: closest, furthest.
        """
        if method not in RepoDeduplicator.methods:
            self._logger.error(f"Invalid method: {method}")
            sys.exit(1)
        for duplicate in self._duplicates:
            if method == "closest":
                duplicate.sort(key=lambda repo: repo['path'].count('/'), reverse=True)
            elif method == "furthest":
                duplicate.sort(key=lambda repo: repo['path'].count('/'), reverse=False)
            for repo in duplicate[1:]:
                if self._wet_run:
                    self._logger.info(f"Deleting {repo['path']}")
                    # subprocess.run(['rm', '-rf', repo['path']])
                else:
                    self._logger.info(f"Would delete {repo['path']}")


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.description = ('Deletes duplicate repositories in a directory.')
    parser.add_argument('-p', '--path', required=True, help='Path to check')
    parser.add_argument('-v', '--verbose', dest='verbosity', action='count', help='Increase verbosity', default=0)
    parser.add_argument('-w', '--wetrun', dest='wet_run', action='store_true',
                        help='Actually delete duplicates, i.e. not a dry run')
    parser.add_argument('-q', '--quiet', dest='quiet', action='store_true', help='Suppress all output')
    parser.add_argument('-m', '--method', dest='method', action='store',
                        help='Method to decide which repos to delete. Valid options are: '
                        f'{RepoDeduplicator.method_help}. Defaults to \'{RepoDeduplicator.methods[0]}\'.',
                        choices=RepoDeduplicator.methods, default=RepoDeduplicator.methods[0])
    args = parser.parse_args()
    logging_level = logging.ERROR if args.quiet else logging.WARNING - (args.verbosity) * 10
    repo_deduplicator = RepoDeduplicator(logging_level, args.wet_run)
    repo_deduplicator.find_path_repositories(args.path)
    repo_deduplicator.find_duplicates()
    repo_deduplicator.delete_duplicates(args.method)
