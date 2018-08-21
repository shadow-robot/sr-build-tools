
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
    customername = objectname.split("/")[1].split("_")[0]
    customername = customername.replace("_"," ")
    timestamp = objectname.split("/")[1].split("_")[1].split(".")[0]
    year = timestamp.split("-")[0]
    month = timestamp.split("-")[1]
    day = timestamp.split("-")[2]
    hour = timestamp.split("-")[3]
    minute = timestamp.split("-")[4]
    second = timestamp.split("-")[6]
    timestamp = year+"-"month+"-"+day+"-"+hour+":"+minute+":"+second
    filename = objectname.split("/")[1]
    size =  str(event['Records'][0]['s3']['object']['size']/1024.0/1024.0)
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
        f"Link to tar.gz: https://s3.eu-west-2.amazonaws.com/com.shadowrobot.eu-west-2.clients.fileupload/"+objectname+"\n"
        )
                 
    snsclient.publish(TopicArn=topic_arn, Message=email_text, Subject=subjectline)
