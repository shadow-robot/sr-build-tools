#!/usr/bin/env python
#
# Copyright (C) 2018 Shadow Robot Company Ltd - All Rights Reserved.
# Proprietary and Confidential. Unauthorized copying of the content in this file, via any medium is strictly prohibited.

import json
import urllib.parse
import boto3
from botocore.client import Config
from base64 import b64decode
import os

print('Loading s3_upload_email_lambda_function')

access_key_id_enc = os.environ['access_key_id']
access_key_id_dec = boto3.client('kms').decrypt(CiphertextBlob=b64decode(access_key_id_enc))['Plaintext']
access_key_id_dec=access_key_id_dec.decode('utf-8')

secret_access_key_enc = os.environ['secret_access_key']
secret_access_key_dec = boto3.client('kms').decrypt(CiphertextBlob=b64decode(secret_access_key_enc))['Plaintext']
secret_access_key_dec=secret_access_key_dec.decode('utf-8')

s3 = boto3.client('s3', aws_access_key_id=access_key_id_dec,aws_secret_access_key=secret_access_key_dec,config=Config(signature_version='s3v4'))

snsclient = boto3.client('sns')
topic_arn = 'arn:aws:sns:eu-west-2:080653068785:S3UploadTopic'

def lambda_handler(event, context):
    bucket = event['Records'][0]['s3']['bucket']['name']
    eventname = event['Records'][0]['eventName']
    eventtime = event['Records'][0]['eventTime']
    objectname = event['Records'][0]['s3']['object']['key']
    filename = objectname.split("/")[1]
    
    customername = filename.split("_")[0]
    customername = customername.replace("-"," ")
    customername = customername.replace("%26","&")
    timestamp = filename.split("_")[1].split(".")[0]
    year = timestamp.split("-")[0]
    month = timestamp.split("-")[1]
    day = timestamp.split("-")[2]
    hour = timestamp.split("-")[3]
    minute = timestamp.split("-")[4]
    second = timestamp.split("-")[5]
    timestamp = year+"-"+month+"-"+day+"T"+hour+":"+minute+":"+second
    
    corrected_object_name = objectname.replace("%3A",":")
    corrected_object_name = corrected_object_name.replace("%25","")
    presigned_url=s3.generate_presigned_url('get_object', Params = {'Bucket': bucket, 'Key': corrected_object_name}, ExpiresIn = 604800)
    
    
    size = "{:.2f}".format(event['Records'][0]['s3']['object']['size']/1024.0/1024.0)
    
    subjectline = "New ROS Logs upload for Shadow from "+customername
    email_text = (
        f"New ROS Logs upload for Shadow\n"
        f"Customer: "+customername+"\n"
        f"File timestamp: "+timestamp+"\n"
        f"Upload timestamp: "+eventtime+"\n"
        f"Bucket: "+bucket+"\n"
        f"Event: "+eventname+"\n"
        f"Filename: "+filename+"\n"
        f"Size (in MB): "+size+"\n"
        f"Link to tar.gz (valid for 7 days): "+presigned_url+"\n"
        )
                 
    snsclient.publish(TopicArn=topic_arn, Message=email_text, Subject=subjectline)
