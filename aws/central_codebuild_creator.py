#!/usr/bin/env python
#
# Copyright (C) 2018 Shadow Robot Company Ltd - All Rights Reserved.
# Proprietary and Confidential. Unauthorized copying of the content in this file, via any medium is strictly prohibited.

import boto3
from botocore.vendored import requests
from base64 import b64decode
import os
import json

#get git credentials
git_username_enc = os.environ['git_username']
git_username_dec = boto3.client('kms').decrypt(CiphertextBlob=b64decode(git_username_enc))['Plaintext']
git_username_dec = git_username_dec.decode('utf-8')
git_token_enc = os.environ['git_token']
git_token_dec = boto3.client('kms').decrypt(CiphertextBlob=b64decode(git_token_enc))['Plaintext']
git_token_dec = git_token_dec.decode('utf-8')

#create a AWS SNS client for sending emails
snsclient = boto3.client('sns')
topic_arn = 'arn:aws:sns:eu-west-2:080653068785:CentralCodeBuildCreatorTopic'

#create a CodeBuild client for creating and updating CodeBuild projects
codebuildclient = boto3.client('codebuild')

#hardcoded stuff
build_project_name_start = "auto_script_"
email_subjectline = "AWS Lambda for Central AWS CodeBuild Creator"
# when repo to be built with aws.json has been merged to default branch
# repo_aws_json_master_branch = "HEAD"
repo_aws_json_master_branch = "F%23SRC-2345_setup_aws_build_of_build-servers-check"

#list of repos JSON
#this will be sr-build-tools-internal in the future
list_of_repos_json = """{
    "repositories": [
        "sgs_restful",
        "isee",
        "beko_demo",
        "chiron",
        "planners",
        "ros_control_robot",
        "sr_blockly",
        "sr-demo",
        "sr-visualization",
        "sr_vision",
        "sr_tools",
        "sr_demos",
        "sr_standalone",
        "sr-ros-interface",
        "sr-ros-interface-ethercat",
        "sr-ronex",
        "sr_ur_arm",
        "ramcip",
        "build-servers-check",
        "sr_interface",
        "sr_core",
        "sr_common",
        "autopic",
        "fh_config",
        "fh_core",
        "sr_manipulation",
        "fh_common",
        "fh_interface",
        "sr_vision_internal",
        "sat",
        "robust_grasping",
        "shadow_flexible_hand",
        "series_ethercat_robot",
        "ros_ethercat",
        "common_resources",
        "sr_demos",
        "sr_grasping",
        "sr_ur_arm",
        "sr_visualization_common",
        "sr_object_tools",
        "sr_benchmarking",
        "common_resources_private",
        "serfow",
        "fh_tests",
        "mujoco_ros_pkgs",
        "sr_utl_demos",
        "sr_duplo_demos",
        "smart_grasping_sandbox",
        "iplanr",
        "fh_demos",
        "sr_teleop_demos",
        "sr_mujoco_demos",
        "shadow_flexible_hand_mujoco"
    ]
}"""

#build a list of all current CodeBuild projects
codebuildresponse = codebuildclient.list_projects(
    sortBy='NAME',
    sortOrder='ASCENDING'
)

#build a dictionary of dict[repo]=[list of project_names]

dict_repo_projects = {}
list_of_project_names = codebuildresponse['projects']
for project_name in list_of_project_names:
    repo_name_in_project_name = project_name[5:-15]
    dict_repo_projects.setdefault(repo_name_in_project_name,[]).append(project_name)

#parse json of the list of repos
parsed_json_repos = json.loads(list_of_repos_json)
repo_list = parsed_json_repos["repositories"]

for repo in repo_list:
    repo_aws_json_url = "https://raw.githubusercontent.com/shadow-robot/"+repo+"/"+repo_aws_json_master_branch+"/aws.json"
    #access repo's aws.json file, authenticate via GitHub credentials
    repo_aws_json_response = requests.get(repo_aws_json_url, auth=(git_username_dec,git_token_dec))
    
    if (str(repo_aws_json_response) == "<Response [200]>"):
        #if we can access repo ok and find the aws.json file inside it

        repo_aws_json_text = repo_aws_json_response.text
        parsed_json = json.loads(repo_aws_json_text)
        #TODO: add extracting json parameters here

        #for every trunk
        #populate the create_project method
        trunk_name = 'kinetic-devel'
        createProjectResponse = codebuildclient.create_project(
            name=build_project_name_start+repo+'_'+trunk_name,
            description='Created by Central AWS CodeBuild Script. This project is to check status of the build servers used in build tools for Ubuntu Xenial and ROS Kinetic\nNOTE: change BRANCH FILTER to ^kinetic-devel$ before merging everything for this user story',
            source={
                'type': 'GITHUB',
                'location': 'https://github.com/shadow-robot/'+repo+'.git',
                'gitCloneDepth': 5,
                'buildspec': """version: 0.2
 
env:
  variables:
     toolset_branch: "master"
     server_type: "local-docker"
     used_modules: "check_cache,code_coverage"
     relative_job_path: "/home/user"
     unit_tests_result_dir: "/home/user/unit_tests"
     coverage_tests_result_dir: "/home/user/code_coverage"
phases:
  build:
    commands:
      - chown -R $MY_USERNAME:$MY_USERNAME $CODEBUILD_SRC_DIR
      - export remote_shell_script="https://raw.githubusercontent.com/shadow-robot/sr-build-tools/$toolset_branch/bin/sr-run-ci-build.sh"
      - wget -O /tmp/oneliner "$( echo "$remote_shell_script" | sed 's/#/%23/g' )"
      - chmod 755 /tmp/oneliner
      - gosu $MY_USERNAME /tmp/oneliner $toolset_branch $server_type $used_modules $CODEBUILD_SRC_DIR
artifacts:
  files:
    - '$unit_tests_result_dir/**/*'
    - '$coverage_tests_result_dir/**/*'""",
                'auth': {
                    'type': 'OAUTH'
                    },
                'reportBuildStatus': True,
                'insecureSsl': False
                },
            artifacts={
                'type': 'S3',
                'location': 'com.shadowrobot.eu-west-2.codebuild.build-servers-check',
                'namespaceType': 'NONE',
                'name': 'auto_build-servers-check_xenial-kinetic_artifacts',
                'packaging': 'ZIP',
                'overrideArtifactName': False,
                'encryptionDisabled': True,
                'path': ''
                },
            environment={
                'type': 'LINUX_CONTAINER',
                'image': 'shadowrobot/build-tools:xenial-kinetic',
                'computeType': 'BUILD_GENERAL1_SMALL',
                'environmentVariables': [],
                'privilegedMode': False,
                },
            cache={
                'type':'NO_CACHE'                
            },
            serviceRole='arn:aws:iam::080653068785:role/service-role/RoleForCentralCodeBuildCreator',
            timeoutInMinutes=60,
            encryptionKey='arn:aws:kms:eu-west-2:080653068785:alias/aws/s3',
            tags=[],
            badgeEnabled=True)
            

            #now create the webhook
        createProjectResponse = codebuildclient.create_webhook(
            projectName=build_project_name_start+repo+'_'+trunk_name,
            branchFilter='^F#SRC-2345_setup_aws_build_of_build-servers-check$'
        )

email_text = (
    f"AWS Lambda central_codebuild_creator has run\n"
)

snsclient.publish(TopicArn=topic_arn, Message=email_text, Subject=email_subjectline)
