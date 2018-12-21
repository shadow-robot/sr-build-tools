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
        createProjectResponse = self.codebuildclient.update_project(
            name=project_name,
            description=project_name,
            source=job_config['source'],
            artifacts=job_config['artifacts'],
            environment=job_config['environment'],
            cache=job_config['cache'],
            serviceRole=job_config['serviceRole'],
            timeoutInMinutes=job_config['timeoutInMinutes'],
            encryptionKey=job_config['encryptionKey'],
            tags=job_config['tags'],
            badgeEnabled=job_config['badgeEnabled'])

        createProjectResponse = self.codebuildclient.update_webhook(
            projectName=project_name,
            branchFilter=job_config['webhook_branchFilter']
        )

    def create_project(self, project_name, job_config):
        createProjectResponse = self.codebuildclient.create_project(
            name=project_name,
            description=project_name,
            source=job_config['source'],
            artifacts=job_config['artifacts'],
            environment=job_config['environment'],
            cache=job_config['cache'],
            serviceRole=job_config['serviceRole'],
            timeoutInMinutes=job_config['timeoutInMinutes'],
            encryptionKey=job_config['encryptionKey'],
            tags=job_config['tags'],
            badgeEnabled=job_config['badgeEnabled'])

        createProjectResponse = self.codebuildclient.create_webhook(
            projectName=project_name,
            branchFilter=job_config['webhook_branchFilter']
        )

    def project_exists(self, project_n):
        exists = False
        project_names = self.get_projects()
        for project_name in project_names:
            if (project_name == project_n):
                exists = True
        return exists

    def delete_project(self, project_n):
        if (self.project_exists(project_n)):
            codebuildresponse = self.codebuildclient.delete_project(
                name=project_n
            )

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
