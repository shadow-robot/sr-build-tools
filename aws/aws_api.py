# Copyright (C) 2018 Shadow Robot Company Ltd - All Rights Reserved.
# Proprietary and Confidential. Unauthorized copying of the content in this file, via any medium is strictly prohibited.


class AwsApi(object):

    def __init__(self):
        self.codebuildclient = boto3.client('codebuild')
        self.snsclient = boto3.client('sns')

    def get_projects(self):
        project_names = ''
        codebuildresponse = self.codebuildclient.list_projects(
            sortBy='NAME',
            sortOrder='ASCENDING'
        )
        project_names = codebuildresponse['projects']
        return project_names

    def update_project(self, project_name, job_config):
        pass

    def create_project(self, project_name, job_config):
        pass

    def project_exists(self, project_name):
        pass

    def delete_project(self, project_name):
        pass

    def send_email(self, subject_line, sns_topic, specified_projects, created_projects, updated_projects, deleted_projects):
        email_text = (
            f"AWS Lambda for Central AWS CodeBuild Creator has run\n\n"
            f"Repos specified in configuration.yml in sr_build_tools_internal:\n"
            f""+"\n".join(specified_projects)+"\n"
            f"AWS CodeBuild projects created:\n"
            f""+"\n".join(created_projects)+"\n"
            f"AWS CodeBuild projects updated:\n"
            f""+"\n".join(updated_projects)+"\n"
            f"AWS CodeBuild projects deleted:\n"
            f""+"\n".join(deleted_projects)+"\n"
        )
        self.snsclient.publish(TopicArn=sns_topic, Message=email_text, Subject=subject_line)
