#!/usr/bin/env python
#
# Copyright (C) 2018 Shadow Robot Company Ltd - All Rights Reserved.
# Proprietary and Confidential. Unauthorized copying of the content in this file, via any medium is strictly prohibited.


class GitHubApi(object):

    def __init__(self):
        self.git_username = git_username_dec = boto3.client('kms').decrypt(CiphertextBlob=b64decode(
            os.environ['git_username']))['Plaintext'].decode('utf-8')
        self.git_token = git_token_dec = boto3.client('kms').decrypt(CiphertextBlob=b64decode(
            os.environ['git_token']))['Plaintext'].decode('utf-8')

    def get_file(self, url):
        response = requests.get(url, auth=(self.git_username, self.git_token))
        if (str(response) == "<Response [200]>"):
            return (response.text, True)
        else:
            return (response, False)
