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

import json
import argparse
import requests
import re
import time


class Constants:
    URL_BEGINNING = "https://raw.githubusercontent.com"
    REPOSITORY_ROSINSTALL = "repository.rosinstall"
    REGEXP_IMAGE_NAME = "image="
    REGEXP_BRANCH_STORY = "SRC-[^_]+(?=_)"
    REGEXP_OWNER_REPO = "github.com\/(.*)\/(.*)\.git"
    REGEXP_TITLE_CONTINUED = "^(.*?)\\r"
    GITHUB_API_URL = "https://api.github.com"
    GIT_USERNAME = ""
    GIT_TOKEN = ""
    EXCLUDED_REPOS = ["sr_hand_config"]


def gather_args():
    """This is used to gather the arguments passed into the script, it also gathers the customer.key file
        Which is generated to the docker container when aurora is run."""
    description = 'Write to slot 1 (by default) of YubiKey and gather response of challenge.'
    parser = argparse.ArgumentParser(description=description)
    help = "This is your github username."
    parser.add_argument('--username', '-u', type=str, required=True, help=help)
    help = "This is your github token."
    parser.add_argument('--token', '-t', type=str, required=True, help=help)
    help = "This is the image repo you want to get the changelog from.\n" + \
        "Choices are shadow_dexterous_hand, shadow_teleop_haptx, shadow_teleop_polhemus."
    parser.add_argument('--repo', '-r', type=str, required=True, help=help)
    help = "This is the image branch you want to use."
    parser.add_argument('--branch', '-b', type=str, help=help, default="noetic-devel")
    help = "This is the date you want to query from."
    parser.add_argument('--start_date', '-sd', type=str, required=True, help=help)
    help = "This is the date you want to end your query too."
    parser.add_argument('--end_date', '-ed', type=str, required=False, help=help)
    args = parser.parse_args()
    Constants.GIT_USERNAME = args.username
    Constants.GIT_TOKEN = args.token
    return args.start_date, args.end_date, args.repo, args.branch


def main():
    start_date, end_date, repo_name, branch = gather_args()
    print("Gathering all repos used within the image.\nThis script may take awhile.\n")
    repos_dict = recursive_get_repos_from_rosinstall(
        'shadow-robot', repo_name, branch, {})
    repo_prs = {}
    print("Gathering all pr's within timeframe.\n")
    for repo in repos_dict:
        repo_data = get_prs_since_date(repo, start_date, end_date)
        if repo_data:
            repo_prs[repo] = repo_data
    format_output_data(repo_prs)


def get_prs_since_date(repo, start_date, end_date):
    """ Format of data given from API Call.
    {
    "sr-ros-interface": {},
    "sr_common": {
        "https: //github.com/shadow-robot/sr_common/pull/126": [
            "F refactoring sr description multi",
            "F_refactoring_sr_description_multi",
            "n/a",
            "2022-01-03T15:59:51Z"
        ],
        "https://github.com/shadow-robot/sr_common/pull/127": [
            "adding DIRECT_PWM_MODE to teach_mode_node",
            "SRC-6613_update_controller_guis",
            "https://shadowrobot.atlassian.net/browse/SRC-6613",
            "2022-01-18T12:17:08Z"
        ]
      }
    }
    """
    if repo in Constants.EXCLUDED_REPOS:
        return None

    if end_date:
        query_url = Constants.GITHUB_API_URL+"/search/issues?q=repo:shadow-robot/" + \
            f"{repo}+is:pr+is:merged+sort:updated-asc+merged:{start_date}..{end_date}"
    else:
        query_url = Constants.GITHUB_API_URL+"/search/issues?q=repo:shadow-robot/" + \
            f"{repo}+is:pr+is:merged+sort:updated-asc+merged:>{start_date}"
        
    time.sleep(2)
    query_result = requests.get(query_url, auth=(
        Constants.GIT_USERNAME, Constants.GIT_TOKEN))
    result_json = json.loads(query_result.text)
    items = result_json['items']
    prs = {}
    for item in items:
        pr_number = str(item['number'])
        pr_url = item['pull_request']['html_url']
        pr_title = item['title']
        pr_query = f"{Constants.GITHUB_API_URL}/repos/shadow-robot/{repo}/pulls/{pr_number}"
        pr_query_result = requests.get(pr_query, auth=(
            Constants.GIT_USERNAME, Constants.GIT_TOKEN))
        pr = json.loads(pr_query_result.text)
        pr_branch = pr['head']['ref']
        pr_body = pr['body']
        pr_title_continued = ""
        try:
            if isinstance(pr_body, str) or isinstance(pr_body, bytes):
                pr_title_continued = re.search(
                    Constants.REGEXP_TITLE_CONTINUED, pr_body).group(1)
        except AttributeError:
            continue
        pr_title += pr_title_continued
        pr_title = pr_title.replace("…", "")
        pr_title = pr_title.replace("## Proposed changes", "")
        user_story = None
        try:
            user_story = re.search(
                Constants.REGEXP_BRANCH_STORY, pr_branch).group(0)
        except AttributeError:
            pass
        jira_link = "n/a"
        if user_story is not None:
            jira_link = "https://shadowrobot.atlassian.net/browse/"+user_story
        pr_merged = item['closed_at']
        prs[pr_url] = [pr_title, pr_branch, jira_link, pr_merged]
    return prs


def recursive_get_repos_from_rosinstall(owner, repo, branch, repo_dict):
    repository_rosinstall_url = f"{Constants.URL_BEGINNING}/{owner}/{repo}/" + \
        f"{branch}/{Constants.REPOSITORY_ROSINSTALL}"
    repository_rosinstall_result = requests.get(
        repository_rosinstall_url, auth=(Constants.GIT_USERNAME, Constants.GIT_TOKEN))
    if repository_rosinstall_result.status_code == 200:
        raw_repos = repository_rosinstall_result.text.split("\n")
        for raw_repo in raw_repos:
            if raw_repo.startswith("    uri: "):
                repo_url = raw_repo.replace("    uri: ", "")
                repo_owner = re.search(
                    Constants.REGEXP_OWNER_REPO, repo_url).group(1)
                if repo_owner == 'shadow-robot':
                    repo_name = re.search(
                        Constants.REGEXP_OWNER_REPO, repo_url).group(2)
                    if repo_name not in repo_dict:
                        repo_dict[repo_name] = ""
                        last = repo_name
                    else:
                        last = ""
                else:
                    last = ""
            if raw_repo.startswith("    version: "):
                repo_branch = raw_repo.replace("    version: ", "")
                if last != "":
                    repo_dict[last] = repo_branch
                    last = ""
                    repo_dict = recursive_get_repos_from_rosinstall(
                        repo_owner, repo_name, repo_branch, repo_dict)
    return repo_dict


def format_output_data(data_dict):
    for _repo, prs in data_dict.items():
        if not prs:
            continue
        for pr_url, array in prs.items():
            pr_title = array[0]
            if array[2] == "n/a":
                string = f"{pr_title} - {pr_url}\n"
            else:
                pr_jira_link = array[2]
                string = f"{pr_title} - {pr_jira_link} {pr_url}\n"
            print(string)


if __name__ == "__main__":
    main()
