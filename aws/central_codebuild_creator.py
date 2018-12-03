#!/usr/bin/env python
#
# Copyright (C) 2018 Shadow Robot Company Ltd - All Rights Reserved.
# Proprietary and Confidential. Unauthorized copying of the content in this file, via any medium is strictly prohibited.

import boto3
from botocore.vendored import requests
from base64 import b64decode
import os
import json

#create a CodeBuild client for creating and updating CodeBuild projects
codebuildclient = boto3.client('codebuild')

#build a list of all current CodeBuild projects
codebuildresponse = codebuildclient.batch_get_projects(
    names=['auto_build-servers-check_bionic-melodic','auto_build-servers-check_xenial-kinetic']
)

print (json.dumps(codebuildresponse, indent=4, sort_keys=True))
