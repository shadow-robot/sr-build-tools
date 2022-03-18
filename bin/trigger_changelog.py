#!/usr/bin/env python3

# Copyright (C) 2022 Shadow Robot Company Ltd - All Rights Reserved.
# Proprietary and Confidential. Unauthorized copying of the content in this file, via any medium is strictly prohibited.
import json
import argparse
import requests
import re
import time


class Constants:
    URL_BEGINNING = "https://raw.githubusercontent.com/"
    REPOSITORY_ROSINSTALL = "repository.rosinstall"
    REGEXP_IMAGE_NAME = "image="
    REGEXP_BRANCH_STORY = "SRC-[^_]+(?=_)"
    REGEXP_OWNER_REPO = "github.com\/(.*)\/(.*)\.git"
    REGEXP_TITLE_CONTINUED = "^(.*?)\\r"
    GITHUB_API_URL = "https://api.github.com"
    GIT_USERNAME = ""
    GIT_TOKEN = ""


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
    parser.add_argument('--image_repo', '-ir', type=str, required=True, help=help)
    help = "This is the image branch you want to use."
    parser.add_argument('--image_branch', '-ib', type=str, help=help, default="noetic-devel")
    help = "This is the date you want to query from."
    parser.add_argument('--start_date', '-sd', type=str, required=True, help=help)
    help = "This is the date you want to end your query too."
    parser.add_argument('--end_date', '-ed', type=str, required=False, help=help)
    args = parser.parse_args()
    Constants.GIT_USERNAME = args.username
    Constants.GIT_TOKEN = args.token
    return args.start_date, args.end_date, args.image_repo, args.image_branch


def main():
    start_date, end_date, repo_name, branch = gather_args()
    print("Gathering all repos used within the image.\nThis script may take awhile.\n")
    repos_dict = recursive_get_repos_from_rosinstall(
        'shadow-robot', repo_name, branch, {})
    repo_prs = {}
    print("Gathering all pr's within timeframe.\n")
    for repo in repos_dict:
        repo_prs[repo] = get_prs_since_date(repo, start_date, end_date)
    format_message(repo_prs)


def get_prs_since_date(repo, start_date, end_date):
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
        pr_query = Constants.GITHUB_API_URL + \
            "/repos/shadow-robot/"+repo+"/pulls/"+pr_number
        pr_query_result = requests.get(pr_query, auth=(
            Constants.GIT_USERNAME, Constants.GIT_TOKEN))
        pr = json.loads(pr_query_result.text)
        pr_branch = pr['head']['ref']
        pr_body = pr['body']
        pr_title_continued = ""
        try:
            pr_title_continued = re.search(
                Constants.REGEXP_TITLE_CONTINUED, pr_body).group(1)
        except AttributeError:
            pass
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
    repository_rosinstall_url = Constants.URL_BEGINNING + \
        owner+'/'+repo+'/'+branch+'/'+Constants.REPOSITORY_ROSINSTALL
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


def format_message(data_dict):
    for repo, prs in data_dict.items():
        if not prs:
            continue
        string = ("=" * 100) + "\n"
        print(f"{string}The repo is {repo}")
        for pr_url, array in prs.items():
            pr_title = array[0]
            pr_branch = array[1]
            pr_jira_link = array[2]
            string = f"PR Title: {pr_title}\nPR Url: {pr_url}\n" + \
                f"PR Branch: {pr_branch}\nPR Jira Link: {pr_jira_link}\n"
            print(string)


if __name__ == "__main__":
    main()