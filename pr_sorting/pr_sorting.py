#!/usr/bin/env python

from github import Auth, Github
import numpy as np
from getpass import getpass
from collections import OrderedDict

def sort_repos_by_number_of_prs(repo_dict: OrderedDict) -> OrderedDict:
    return OrderedDict(sorted(repo_dict.items(),
                              key=lambda item: item[1].totalCount,
                              reverse=True))

def sort_all_prs_by_date_created(repo_dict: OrderedDict) -> list:
    all_prs_unsorted = []
    for pr_list in repo_dict.values():
        for pr in pr_list:
            all_prs_unsorted.append(pr)

    return sorted(all_prs_unsorted, key=lambda pr: pr.created_at)

if __name__ == "__main__":
    token = getpass("Enter your GitHub Personal Access Token:")
    print("Authenticating...")
    auth = Auth.Token(token)
    github = Github(auth=auth)
    organization = github.get_organization(login="shadow-robot")

    print("Getting repositories...")
    repos = organization.get_repos(sort="name")

    open_prs_per_repo = np.zeros(repos.totalCount)
    all_repo_prs = OrderedDict()

    for i, repo in enumerate(repos):
        print(f"Getting pull requests from repository {i+1} of {repos.totalCount}", end="\r")
        prs = repo.get_pulls(state="open", sort="created")

        if prs.totalCount == 0:
            continue

        all_repo_prs[repo.name] = prs
    print("\n")

    print("{:=^180}".format(" Repositories with Open Pull Requests "))
    for repo_name, pr_list in sort_repos_by_number_of_prs(all_repo_prs).items():
        print(repo_name)
        for pr in pr_list:
            print("\t{:<50.50s}\t{:<20.20s}\t{:<10.10s}\t{}".format(pr.title,
                                                                 pr.user.login,
                                                                 str(pr.created_at),
                                                                 pr.html_url))
        print()

    print("\n{:=^180}".format(" All Open Pull Requests by Date Created "))
    for pr in sort_all_prs_by_date_created(all_repo_prs):
        print("{:<50.50s}\t{:<20.20s}\t{:<10.10s}\t{}".format(pr.title,
                                                           pr.user.login,
                                                           str(pr.created_at),
                                                           pr.html_url))

    github.close()
