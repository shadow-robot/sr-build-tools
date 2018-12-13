# Copyright (C) 2018 Shadow Robot Company Ltd - All Rights Reserved.
# Proprietary and Confidential. Unauthorized copying of the content in this file, via any medium is strictly prohibited.


class AwsApi(object):

    def __init__(self):
        self.codebuildclient = boto3.client('codebuild')

    def get_projects(self):
        project_names=''
        codebuildresponse = self.codebuildclient.list_projects(
            sortBy='NAME',
            sortOrder='ASCENDING'
        )
        project_names = codebuildresponse['projects']
        return project_names
