
import json
import urllib.parse
import boto3

print('Loading s3_upload_email_lambda_function')

s3 = boto3.client('s3')

snsclient = boto3.client('sns')
topic_arn = 'arn:aws:sns:eu-west-2:080653068785:S3UploadTopic'

def lambda_handler(event, context):
    bucket = event['Records'][0]['s3']['bucket']['name']
    eventname = event['Records'][0]['eventName']
    eventtime = event['Records'][0]['eventTime']
    objectname = event['Records'][0]['s3']['object']['key']
    size =  event['Records'][0]['s3']['object']['size']
    
    email_text = (
        f"New S3 upload for Shadow Robot\n"
        f"Date and time: "+eventtime+"\n"
        f"Bucket: "+bucket+"\n"
        f"Event: "+eventname+"\n"
        f"Object: "+objectname+"\n"
        f"Size (in MB): "+str(size/1024/1024)+"\n"
        f"Link to tar.gz: https://s3.eu-west-2.amazonaws.com/com.shadowrobot.eu-west-2.clients.fileupload/"+objectname+"\n"
        )
                 
    snsclient.publish(TopicArn=topic_arn, Message=email_text, Subject='New S3 upload for Shadow Robot')
