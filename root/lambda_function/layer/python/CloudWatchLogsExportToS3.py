import botocore
import boto3
import collections
from datetime import datetime, timedelta, timezone
import math
import time
import logging

class CloudWatchLogsExportToS3:

    def __init__(self, records, logger):
        self.records = records
        self.taskNumber = 0
        
        # Logging Level 설정
        self.logger = logger
    
    def export(self):

        self.logger.info("Record Count = {0}".format(len(self.records)))

        try:
            for record in self.records:
                self.logger.info("MessageRecord = {0}".format(record))
                messageAttributes = record.get("messageAttributes")
                self.logger.info(messageAttributes)
                attributes = {
                    "messageId": record.get("messageId"),
                    "bucketName": messageAttributes.get("bucketName").get("stringValue"),
                    "bucketPrefix": messageAttributes.get("bucketPrefix").get("stringValue"),
                    "roleArn": messageAttributes.get("roleArn").get("stringValue"),
                    "logGroupName": messageAttributes.get("logGroupName").get("stringValue"),
                    "startTimestamp": float(messageAttributes.get("startDate").get("stringValue")),
                    "endTimestamp": float(messageAttributes.get("endDate").get("stringValue")),
                    "messageBody": record.get("body")
                }
                self.logger.info("MessageAttributes = {0}".format(attributes))
                self.export_task(attributes)
                time.sleep(2)
        except botocore.exceptions.ClientError as error:
            self.logger.error("Error = {0}".format(error))

        return True

    def export_task(self, attributes):

        messageId = attributes.get("messageId")
        bucketName = attributes.get("bucketName")
        bucketPrefix = attributes.get("bucketPrefix")
        groupName = attributes.get("logGroupName")
        startOfDate = datetime.fromtimestamp(attributes.get("startTimestamp"), tz=timezone(timedelta(hours=9)))
        endOfDate = datetime.fromtimestamp(attributes.get("endTimestamp"), tz=timezone(timedelta(hours=9)))

        self.taskNumber = self.taskNumber + 1
        taskName = 'export_task_' + groupName.replace("/", "_") + str(self.taskNumber)

        groupNameTemp = groupName
        if groupNameTemp[:1] != "/":
            groupNameTemp = "/" + groupNameTemp

        destinationPrefix = bucketPrefix + '/'.join([
            groupNameTemp,
            str(startOfDate.year),
            str(startOfDate.month).zfill(2),
            str(startOfDate.day).zfill(2),
            str(startOfDate.hour).zfill(2)
        ])

        try:
            assumedCredentials = self.getAssumedCredentials(attributes.get("roleArn"), bucketPrefix)
            log_client = boto3.client(
                'logs',
                aws_access_key_id       =   assumedCredentials.get("AccessKeyId"),
                aws_secret_access_key   =   assumedCredentials.get("SecretAccessKey"),
                aws_session_token       =   assumedCredentials.get("SessionToken")
            )

            response = log_client.create_export_task(
                taskName=taskName,
                logGroupName=groupName,
                fromTime=math.floor(startOfDate.timestamp() * 1000),
                to=math.floor(endOfDate.timestamp() * 1000),
                destination=bucketName,
                destinationPrefix= destinationPrefix
            )
            self.logger.info("{0} Exported : {1}".format(messageId, response))
            self.checkExportTask(log_client, response.get("taskId"))

        except botocore.exceptions.ClientError as error:
            if error.response.get('Error').get('Code') == 'LimitExceededException':
                time.sleep(2)
                self.logger.warn("{0} Retry for LimitexceedException".format(messageId))
                self.export_task(attributes)
            elif error.response.get('Error').get('Code') == 'ThrottlingException':
                time.sleep(2)
                self.logger.warn("{0} Retry for ThrottlingException".format(messageId))
                self.export_task(attributes)
            else:
                self.logger.error("{0} Error = {1}\n{2}".format(messageId, error, attributes))


    def checkExportTask(self, log_client, taskId):
        response = log_client.describe_export_tasks(
            taskId=taskId
        )
        self.logger.debug("DescribeExportTask = {0}".format(response))
        status = response.get("exportTasks")[0].get("status").get("code")
        if status == "RUNNING" or status == "PAUSE":
            self.checkExportTask(log_client, taskId)
            time.sleep(2)


    def getAssumedCredentials(self, roleArn, Prefix):
        sts = boto3.client('sts')
        assumed = sts.assume_role(
            RoleArn=roleArn,
            RoleSessionName=Prefix+"_Assume_Collecting"
        )
        return assumed.get("Credentials")
