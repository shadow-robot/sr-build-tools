#!/usr/bin/env python
#
# Copyright (C) 2018 Shadow Robot Company Ltd - All Rights Reserved.
# Proprietary and Confidential. Unauthorized copying of the content in this file, via any medium is strictly prohibited.

import json
import urllib.parse
import boto3
from botocore.client import Config
from base64 import b64decode
import os

enabled = "yes"

git_username_enc = os.environ['git_username']
git_username_dec = boto3.client('kms').decrypt(CiphertextBlob=b64decode(git_username_enc))['Plaintext']
git_username_enc=git_username_enc.decode('utf-8')

git_password_enc = os.environ['git_password']
git_password_dec = boto3.client('kms').decrypt(CiphertextBlob=b64decode(git_password_enc))['Plaintext']
git_password_dec=git_password_dec.decode('utf-8')

snsclient = boto3.client('sns')
topic_arn = 'arn:aws:sns:eu-west-2:080653068785:CentralCodeBuildCreatorTopic'

build_project_name_start = "auto_"

codebuildclient = boto3.client('codebuild')

list_of_repos_url = "https://raw.githubusercontent.com/shadow-robot/sr-build-tools-internal/F%23SRC-2474_central_AWS_script/aws/configuration.yml"

def lambda_handler(event, context):
    
    subjectline = "Automatic trigger for central_codebuild_creator"
    
    #process repo_list one by one
    
    status_text = ""
    
    #get list of repos from sr-build-tools-internal
    
    list_of_repos = ""
    
    #get real list of CodeBuild projects
    codebuildresponse = codebuildclient.list_projects(
            sortBy='NAME',
            sortOrder='ASCENDING'
        )
    list_of_project_names = codebuildresponse['projects']
    
    for repo in list_of_repos.split(","):
        #check if it was aws.yml in the root or not
        
        build_project_name = build_project_name_start+repo
        #check if this build project exists
        if build_project_name in list_of_project_names:
            status_text += "project found! : "+build_project_name+"\n"
        else:
            status_text += "project NOT found! -> needs creating : "+build_project_name+"\n"
    
    email_text = (
        f"1 minute has passed\n"
        f"so central_codebuild_creator has been triggered\n"
        f"and the status text is this: "+status_text+"\n"
        )
    if (should_email_be_sent=="yes"):
        snsclient.publish(TopicArn=topic_arn, Message=email_text, Subject=subjectline)
