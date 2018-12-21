# Copyright (C) 2018 Shadow Robot Company Ltd - All Rights Reserved.
# Proprietary and Confidential. Unauthorized copying of the content in this file, via any medium is strictly prohibited.


class Job(object):

    def __init__(self, aws_yml, repo, trunk_name, job_name, project_name):

        self.instance_size = 'BUILD_GENERAL1_SMALL'
        self.ubuntu_version = 'xenial'
        self.ros_release = 'kinetic'
        self.docker_image = 'shadowrobot/build-tools'
        self.docker_tag = 'xenial-kinetic'
        self.template_project_name = ''
        self.toolset_modules = ['code_coverage']

        self.aws_yml = aws_yml
        self.parsed_yaml = yaml.load(aws_yml)
        self.repo = repo
        self.trunk_name = trunk_name
        self.job_name = job_name
        self.project_name = project_name
        self.description = project_name
        self.update_settings(self.parsed_yaml)
        try:
            self.trunks_list = self.parsed_yaml['settings']['trunks']
            for trunk in self.trunks_list:
                if(trunk['name'] == trunk_name):
                    self.update_settings(trunk)
                    self.job_list = trunk['jobs']
                    for job in self.job_list:
                        if (job['name'] == job_name):
                            self.update_settings(job)
        except:
            pass

        self.config = {}
        self.config['source'] = {
            'type': 'GITHUB',
            'location': 'https://github.com/shadow-robot/'+self.repo+'.git',
            'gitCloneDepth': 5,
            'buildspec': """version: 0.2

env:
  variables:
     toolset_branch: "master"
     server_type: "local-docker"
     used_modules: """+",".join(self.toolset_modules)+"""
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
        }
        self.config['artifacts'] = {
            'type': 'S3',
            'location': 'com.shadowrobot.eu-west-2.codebuild.artifacts',
            'namespaceType': 'NONE',
            'name': self.project_name+'_artifacts',
            'packaging': 'ZIP',
            'overrideArtifactName': False,
            'encryptionDisabled': True,
            'path': ''
        }
        self.config['environment'] = {
            'type': 'LINUX_CONTAINER',
            'image': self.exact_image,
            'computeType': self.instance_size,
            'environmentVariables': [],
            'privilegedMode': False,
        }
        self.config['cache'] = {
            'type': 'NO_CACHE'
        }
        self.config['serviceRole'] = 'arn:aws:iam::080653068785:role/service-role/RoleForCentralCodeBuildCreator'
        self.config['timeoutInMinutes'] = 60
        self.config['encryptionKey'] = 'arn:aws:kms:eu-west-2:080653068785:alias/aws/s3'
        self.config['tags'] = []
        self.config['badgeEnabled'] = True
        self.config['webhook_branchFilter'] = '^'+self.trunk_name+'$'

    def update_settings(self, settings):

        try:
            instance_size = settings['settings']['instance_size']
        except:
            pass
        if (instance_size != 'BUILD_GENERAL1_SMALL' and instance_size != 'BUILD_GENERAL1_MEDIUM' and instance_size != 'BUILD_GENERAL1_LARGE'):
            instance_size = 'BUILD_GENERAL1_SMALL'
        try:
            ubuntu_version = settings['settings']['ubuntu']['version']
        except:
            pass
        try:
            ros_release = settings['settings']['ros']['release']
        except:
            pass
        try:
            docker_image = settings['settings']['docker']['image']
        except:
            pass
        try:
            docker_tag = settings['settings']['docker']['tag']
        except:
            pass
        try:
            template_project_name = settings['settings']['template_project_name']
        except:
            pass
        try:
            toolset_modules = settings['settings']['toolset']['modules']
        except:
            pass

        self.instance_size = instance_size
        self.ubuntu_version = ubuntu_version
        self.ros_release = ros_release
        self.docker_image = docker_image
        self.docker_tag = docker_tag
        self.exact_image = docker_image+':'+docker_tag
        self.toolset_modules = toolset_modules
        self.template_project_name = template_project_name
