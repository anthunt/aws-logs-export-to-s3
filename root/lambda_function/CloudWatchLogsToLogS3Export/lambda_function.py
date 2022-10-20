import boto3
import botocore
import json
import logging
import math
import time
from datetime import timezone, timedelta, datetime

# Custom module import
import assume
import consumer
import sqsQueue

# Logger 설정
logger = logging.getLogger()

# Logging Level 설정
logger.setLevel(logging.INFO)

def lambda_handler(event, context):
    global QueueOptions

    loggingBucketName   = event.get("loggingBucketName")
    QueueOptions        = event.get("QueueOptions")
    consumerRoleArn     = boto3.client("lambda").get_function_configuration(FunctionName=context.function_name).get("Role")
    aws_region_id       = context.invoked_function_arn.split(":")[3]
    aws_account_id      = context.invoked_function_arn.split(":")[4]
    roleArn             = event.get("roleArn")
    Prefix              = event.get("Prefix")
    collectDate         = event.get("collectDate")
    queueName           = "log-sqs-" + Prefix.lower() + "-collect.fifo"
    
    QueueOptions.update({
        "Name"          : queueName,
        "aws_region_id" : aws_region_id,
        "aws_account_id": aws_account_id
    })
    
    QueueOptions.get("ConsumerOptions").update({
        "RoleArn": consumerRoleArn
    })
    
    logger.debug("QueueOptions = {0}".format(QueueOptions))
    
    if collectDate == None:
        # UTC를 한국시간으로 변환하기 위해 9시간을 더해준다.
        now = datetime.now() + timedelta(hours=9)
        collectDate = (now + timedelta(days=-1)).strftime("%Y-%m-%d")
    
    logger.info("Collecting Date = {0}".format(collectDate))
    
    assumedCredentials = assume.credentials(
        logger  = logger,
        RoleArn = roleArn,
        Prefix  = Prefix
    )
    
    logGroupNames = getLogGroupNames(assumedCredentials)
    
    logger.info("LogGroupNames Count = {0}".format(len(logGroupNames)))
    
    dateForStart = datetime.fromisoformat(collectDate + ' 00:00:00.000+09:00')
    dateForEnd = datetime.fromisoformat(collectDate + ' 23:59:59.000+09:00')
    logger.info("Collecting Start Date with TimeZone = {0}".format(dateForStart))
    logger.info("Collecting End Date with TimeZone = {0}".format(dateForEnd))
        
    queue = sqsQueue.get(
        logger = logger,
        QueueOptions = QueueOptions
    )
    
    entryCount = 0
    queueEntries = []
    entries = []

    for logGroupName in logGroupNames:
        if len(entries) == 10:
            queueEntries.append(entries)
            entries = []
        
        startTimestamp = str(dateForStart.timestamp())
        endTimestamp = str(dateForEnd.timestamp())
        entryCount = entryCount + 1
        entries.append(
            {
                "Id": str(len(entries)),
                "MessageGroupId": logGroupName.replace("/", "").replace("-", ""),
                "MessageDeduplicationId": logGroupName.replace("/", "").replace("-", "") + startTimestamp + context.aws_request_id.replace("-", ""),
                "MessageBody": str(dateForStart) + " - " + str(dateForEnd) + " export job queue",
                "MessageAttributes": {
                    "startDate": {
                        "StringValue": startTimestamp,
                        "DataType": "String"
                    },
                    "endDate": {
                        "StringValue": endTimestamp,
                        "DataType": "String"
                    },
                    "roleArn": {
                        "StringValue": roleArn,
                        "DataType": "String"
                    },
                    "logGroupName": {
                        "StringValue": logGroupName,
                        "DataType": "String"
                    },
                    "bucketName": {
                        "StringValue": loggingBucketName,
                        "DataType": "String"
                    },
                    "bucketPrefix": {
                        "StringValue": Prefix,
                        "DataType": "String"
                    }
                }
            }
        )
        
    if len(entries) > 0:
        queueEntries.append(entries)
    
    
    for queueEntry in queueEntries:
        response = queue.send_messages(
            Entries=queueEntry
        )
        logger.info(response)
        time.sleep(1.5)
    
    logger.info("Messages Count = {0}".format(entryCount))

def getLogGroupNames(assumedCredentials):
    client = boto3.client(
        'logs',
        aws_access_key_id       =   assumedCredentials.get("AccessKeyId"),
        aws_secret_access_key   =   assumedCredentials.get("SecretAccessKey"),
        aws_session_token       =   assumedCredentials.get("SessionToken")
    )
    
    logGroupNames = []
    
    response = client.describe_log_groups()
    nextToken = response.get("nextToken")
    
    for logGroup in response.get("logGroups"):
            logGroupNames.append(logGroup.get("logGroupName"))
            
    while nextToken:
        response = client.describe_log_groups(
            nextToken=nextToken
        )
        
        for logGroup in response.get("logGroups"):
            logGroupNames.append(logGroup.get("logGroupName"))
        
        nextToken = response.get("nextToken")
        
    return logGroupNames
