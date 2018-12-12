# Copyright (C) 2018 Shadow Robot Company Ltd - All Rights Reserved.
# Proprietary and Confidential. Unauthorized copying of the content in this file, via any medium is strictly prohibited.


class BuildJobManager(object):

    def __init__(self):
        self.sns_topic = 'arn:aws:sns:eu-west-2:080653068785:CentralCodeBuildCreatorTopic'
        self.email_subjectline = 'AWS Lambda for Central AWS CodeBuild Creator'
        self.organisation = 'shadow-robot'
        self.config_repo = 'sr-build-tools-internal'
        self.config_branch = 'F#SRC-2549_aws_central_script_now_supports_yaml'
        self.config_path = 'aws/configuration.yml'
        self.aws_branch = 'HEAD'
        self.aws_path = 'aws.yml'
        self.created_projects = []
        self.updated_projects = []
        self.deleted_projects = []
        self.specified_projects = []
        self.existing_projects = []

    def generate_projectname(self, repo_name, trunk_name, job_name):
        project_name = 'auto_'+repo_name+'_'+trunk_name+'_'+job_name
        return project_name

    def main(self):
        aws_api = AwsApi()
        github_api = GitHubApi()

        self.existing_projects = aws_api.get_projects()

        repos_yaml = github_api.get_file(self.organisation, self.config_repo, self.config_branch, self.config_path)
        repo_list = yaml.load(repos_yaml)['repositories']

        for repo in repo_list:
            aws_yaml = github_api.get_file(self.organisation, repo, self.aws_branch, self.aws_path)
            gitrepo = GitRepo(aws_yaml)
            trunk_names = gitrepo.get_trunks()
            for trunk_name in trunk_names:
                job_names = gitrepo.get_jobs(trunk_name)
                for job_name in job_names:
                    project_name = self.generate_projectname(repo, trunk_name, job_name)
                    self.specified_projects.append(project_name)
                    job = Job(aws_yaml, repo, trunk_name, job_name, project_name)
                    if (aws_api.project_exists(project_name)):
                        aws_api.update_project(project_name, job.config)
                        self.updated_projects.append(project_name)
                    else:
                        aws_api.create_project(project_name, job.config)
                        self.created_projects.append(project_name)

        for project in self.existing_projects:
            if project not in self.specified_projects:
                aws_api.delete_project(project)
                self.deleted_projects.append(project)

        aws_api.send_email(self.email_subjectline, self.aws_sns_topic, self.specified_projects,
                           self.created_projects, self.updated_projects, self.deleted_projects)
