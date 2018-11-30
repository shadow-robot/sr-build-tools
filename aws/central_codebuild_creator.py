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

#hard coded stuff
build_project_name_start = "auto_"
email_subjectline = "AWS Lambda for Central AWS CodeBuild Creator"
# when repo to be built with aws.json has been merged to default branch
# repo_aws_json_master_branch = "HEAD"
repo_aws_json_master_branch = "F%23SRC-2345_setup_aws_build_of_build-servers-check"

#list of repos JSON
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
    
for repo_line in list_of_repos_text.splitlines():
    if (repo_line.startswith("  - ")):
        repo_name = repo_line.strip()[2:]        
        repo_aws_json_url = "https://raw.githubusercontent.com/shadow-robot/"+repo_name+"/"+repo_aws_json_master_branch+"/aws.json"
        repo_aws_json_response = requests.get(repo_aws_json_url, auth=(git_username_dec,git_token_dec))
        if (str(repo_aws_json_response) == "<Response [200]>"):

            repo_aws_json_text = repo_aws_json_response.text
            parsed_json = json.loads(repo_aws_json_text)
            instance_size = parsed_json["settings"]["instance_size"]
            ubuntu_version = parsed_json["settings"]["ubuntu"]["version"]
            ros_release = parsed_json["settings"]["ros"]["release"]
            docker_image = parsed_json["settings"]["docker"]["image"]
            docker_tag = parsed_json["settings"]["docker"]["tag"]
            template_project_name = parsed_json["settings"]["template_project_name"]
            toolset_module_list = parsed_json["settings"]["toolset"]["modules"]
            trunk_list = parsed_json["settings"]["trunks"]
            for trunk in trunk_list:
                trunk_name = trunk["name"]
                trunk_settings_ubuntu_version = trunk["settings"]["ubuntu"]["version"]
                trunk_settings_ros_release = trunk["settings"]["ros"]["release"]
                trunk_settings_docker_tag = trunk["settings"]["docker"]["tag"]
                trunk_jobs_list = trunk["jobs"]
                for trunk_job in trunk_jobs_list:
                    trunk_job_name = trunk_job["name"]
                    trunk_job_settings_toolset_module_list = trunk_job["settings"]["toolset"]["modules"]

                #for every trunk
                createProjectResponse = codebuildclient.create_project(
                    name=build_project_name_start+repo_name+"_"+trunk_name,
                    description='',
                    source={
                        'type': 'GITHUB',
                        'location': 'https://github.com/shadow-robot/'+repo_name,
                        'gitCloneDepth': 5,
                        'buildspec': 'string',
                        'auth': {
                            'type': 'OAUTH',
                            'resource': 'string'
                        },
                        'reportBuildStatus': True,
                        'insecureSsl': True
                    },
                    artifacts={
                        'type': 'S3',
                        'location': 'com.shadowrobot.eu-west-2.codebuild.build-servers-check',
                        'namespaceType': 'NONE',
                        'name': 'auto_build-servers-check_xenial-kinetic_artifacts',
                        'packaging': 'ZIP',
                        'overrideArtifactName': False,
                        'encryptionDisabled': True
                    },
                    environment={
                        'type': 'LINUX_CONTAINER',
                        'image': 'string',
                        'computeType': 'BUILD_GENERAL1_SMALL'|'BUILD_GENERAL1_MEDIUM'|'BUILD_GENERAL1_LARGE',
                        'environmentVariables': [
                            {
                                'name': 'string',
                                'value': 'string',
                                'type': 'PLAINTEXT'|'PARAMETER_STORE'
                            },
                        ],
                        'privilegedMode': True|False,
                        'certificate': 'string'
                    },
    serviceRole='string',
    timeoutInMinutes=123,
    queuedTimeoutInMinutes=123,
    encryptionKey='string',
    tags=[
        {
            'key': 'string',
            'value': 'string'
        },
    ],
    vpcConfig={
        'vpcId': 'string',
        'subnets': [
            'string',
        ],
        'securityGroupIds': [
            'string',
        ]
    },
    badgeEnabled=True|False,
    logsConfig={
        'cloudWatchLogs': {
            'status': 'ENABLED'|'DISABLED',
            'groupName': 'string',
            'streamName': 'string'
        },
        's3Logs': {
            'status': 'ENABLED'|'DISABLED',
            'location': 'string'
        }
    }
)

            status_text += "got this aws.json text from "+repo_name+":" +repo_aws_json_text+"\n"
        else:
            status_text += repo_name+" does not have aws.json in "+repo_aws_json_master_branch+" branch" +"\n"
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
