#!/usr/bin/env python
#
# Copyright (C) 2018 Shadow Robot Company Ltd - All Rights Reserved.
# Proprietary and Confidential. Unauthorized copying of the content in this file, via any medium is strictly prohibited.

import boto3
from botocore.vendored import requests
from base64 import b64decode
import os

git_username_enc = os.environ['git_username']
git_username_dec = boto3.client('kms').decrypt(CiphertextBlob=b64decode(git_username_enc))['Plaintext']
git_username_dec = git_username_dec.decode('utf-8')

git_token_enc = os.environ['git_token']
git_token_dec = boto3.client('kms').decrypt(CiphertextBlob=b64decode(git_token_enc))['Plaintext']
git_token_dec = git_token_dec.decode('utf-8')
    
enabled = "yes"

snsclient = boto3.client('sns')
topic_arn = 'arn:aws:sns:eu-west-2:080653068785:CentralCodeBuildCreatorTopic'

build_project_name_start = "auto_"

codebuildclient = boto3.client('codebuild')

list_of_repos_url = "https://raw.githubusercontent.com/shadow-robot/sr-build-tools-internal/F%23SRC-2474_central_AWS_script/aws/configuration.yml"

subjectline = "Automatic trigger for central_codebuild_creator"
    
status_text = ""
    
list_of_repos_response = requests.get(list_of_repos_url, auth=(git_username_dec,git_token_dec))
list_of_repos_text = list_of_repos_response.text

codebuildresponse = codebuildclient.list_projects(
    sortBy='NAME',
    sortOrder='ASCENDING'
)

dict_repo_projects = {}
list_of_project_names = codebuildresponse['projects']
for project_name in list_of_project_names:
    repo_name_in_project_name = project_name[5:-15]
    dict_repo_projects.setdefault(repo_name_in_project_name,[]).append(project_name)
    
for repo_line in list_of_repos_text.splitlines():
    if (repo_line.startswith("  - ")):
        repo_name = repo_line.strip()[2:]
        repo_aws_yml_master_branch = "master"
        repo_aws_yml_url = "https://raw.githubusercontent.com/shadow-robot/build-servers-check/"+repo_aws_yml_master_branch+"/aws.yml"
        repo_aws_yml_response = requests.get(repo_aws_yml_url, auth=(git_username_dec,git_token_dec))
        if (repo_aws_yml_response == '200'):
            repo_aws_yml_text = list_of_repos_response.text
            status_text += "got this aws.yml text from "+repo_name+":" +repo_aws_yml_text+"\n"+repo_aws_yml_response+"\n"
        else:
            status_text += repo_name+" does not have aws.yml in "+repo_aws_yml_master_branch+" branch" +"\n"+repo_aws_yml_response+"\n"
            if repo_name in dict_repo_projects:
                project_candidates_for_deletion = dict_repo_projects[repo_name]
                status_text += "project candidates for deletion: "+ ', '.join(project_candidates_for_deletion)+"\n"
        
        build_project_name = build_project_name_start+repo_name
        if build_project_name in list_of_project_names:
            status_text += "project found! : "+build_project_name+"\n"
        else:
            status_text += "project NOT found! -> needs creating : "+build_project_name+"\n"

email_text = (
    f"1 minute has passed\n"
    f"so central_codebuild_creator has been triggered\n"
    f"and the status text is this:"+"\n"+status_text+"\n"
)


if (enabled=="yes"):
    snsclient.publish(TopicArn=topic_arn, Message=email_text, Subject=subjectline)
