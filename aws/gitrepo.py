# Copyright (C) 2018 Shadow Robot Company Ltd - All Rights Reserved.
# Proprietary and Confidential. Unauthorized copying of the content in this file, via any medium is strictly prohibited.


class GitRepo(object):

    def __init__(self, aws_yml):
        self.raw_yaml = aws_yml

    def get_trunks(self):
        trunk_names = []
        parsed_yaml = yaml.load(self.raw_yaml)
        trunks = parsed_yaml['trunks']
        for trunk in trunks:
            trunk_name = trunk['name']
            trunk_names.append(trunk_name)
        return trunk_names

    def get_jobs(self, trunk_n):
        job_names = []
        parsed_yaml = yaml.load(self.raw_yaml)
        trunks = parsed_yaml['trunks']
        for trunk in trunks:
            trunk_name = trunk['name']
            if (trunk_name == trunk_n):
                jobs = trunk['jobs']
                for job in jobs:
                    job_name = job['name']
                    job_names.append(job_name)
        return job_names
