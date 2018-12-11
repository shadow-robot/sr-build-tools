#!/usr/bin/env python
#
# Copyright (C) 2018 Shadow Robot Company Ltd - All Rights Reserved.
# Proprietary and Confidential. Unauthorized copying of the content in this file, via any medium is strictly prohibited.


class BuildJobManager(object):

    aws_sns_topic = 'arn:aws:sns:eu-west-2:080653068785:CentralCodeBuildCreatorTopic'
    build_project_name_start = 'auto--'
    email_subjectline = 'AWS Lambda for Central AWS CodeBuild Creator'
    repo_aws_yml_master_branch = 'HEAD'
    configuration_yml_url = 'https://raw.githubusercontent.com/shadow-robot/sr-build-tools-internal/F%23SRC-2549_aws_central_script_now_supports_yaml/aws/configuration.yml'

    def __init__(self, git_username, git_token):
        self.git_username = git_username
        self.git_token = git_token

    def main(self):

        github_api = GitHubApi(self.git_username, self.git_token)

        aws_api = AwsApi()

        # get repo list in yaml format

        (repo_list_yaml_raw, repo_list_response_ok) = github_api.get_file(configuration_yml_url)

        if (repo_list_response_ok):
            # parse yaml
            repo_list_yaml = yaml.load(repo_list_yaml_raw)
            print(repo_list_yaml)
        else:
            print('Error getting a repo list from '+configuration_yml_url+" : "+repo_list_yaml_raw)
