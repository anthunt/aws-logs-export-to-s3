import boto3
import botocore
import consumer

"""
- SQS Queue handler module
- usage:
    import sqsQueue
    import logging
    
    def process():
        logger = logging.getLogger()
        sqsQueue.get(
            logger = logger,
            QueueOptions = {
                "aws_region_id"                : "AWS region id - string",
                "aws_account_id"               : "AWS account id - string",    
                "Name"                         : "SQS queue name - string",
                "VisibilityTimeout"            : "visibility timeout - int",
                "MessageRetentionPeriod"       : "message retention period - int",
                "KmsMasterKeyId"               : "kms key alias - string",
                "KmsDataKeyReusePeriodSeconds" : "kms data key reuse period seconds - int",
                "ConsumerOptions" : {
                    "RoleArn"       : "consumer lambda function execution role arn - string",
                    "BucketName"    : "consumer lambda function code bucket name - string",
                    "ObjectKey"     : "consumer lambda function code object key - string",
                    "LayerArn"      : "consumer lambda function layer arn - string",
                    "BatchSize"     : "consumer lambda function sqs consumer batch size - int"
                }
            }
        )
    
- output:
    sqs.Queue

"""
def get(logger, QueueOptions):
    sqs = boto3.resource('sqs')

    aws_region_id                       = QueueOptions.get("aws_region_id")
    aws_account_id                      = QueueOptions.get("aws_account_id")    
    queueName                           = QueueOptions.get("Name")
    queueVisibilityTimeout              = QueueOptions.get("VisibilityTimeout")
    queueMessageRetentionPeriod         = QueueOptions.get("MessageRetentionPeriod")
    queueKmsMasterKeyId                 = QueueOptions.get("KmsMasterKeyId")
    queueKmsDataKeyReusePeriodSeconds   = QueueOptions.get("KmsDataKeyReusePeriodSeconds")
    ConsumerOptions                     = QueueOptions.get("ConsumerOptions")
    consumerRoleArn                     = ConsumerOptions.get("RoleArn")
    consumerBucketName                  = ConsumerOptions.get("BucketName")
    consumerObjectKey                   = ConsumerOptions.get("ObjectKey")
    consumerLayerArn                    = ConsumerOptions.get("LayerArn")
    consumerBatchSize                   = ConsumerOptions.get("BatchSize")
                    
    try:
        queue = sqs.get_queue_by_name(
            QueueName=queueName
        )
        
        response = queue.set_attributes(
            Attributes={
                "VisibilityTimeout": str(queueVisibilityTimeout),
                "MessageRetentionPeriod": str(queueMessageRetentionPeriod)
            }
        )
    except botocore.exceptions.ClientError as error:
        if error.response.get("Error").get("Code") == "AWS.SimpleQueueService.NonExistentQueue":
            queue = sqs.create_queue(
                QueueName=queueName,
                Attributes={
                    "VisibilityTimeout": str(queueVisibilityTimeout),
                    "MessageRetentionPeriod": str(queueMessageRetentionPeriod),
                    "Policy": "{\"Version\":\"2008-10-17\",\"Id\":\"__default_policy_ID\",\"Statement\":[{\"Sid\":\"__owner_statement\",\"Effect\":\"Allow\",\"Principal\":{\"AWS\":\"arn:aws:iam::" + aws_account_id + ":root\"},\"Action\":\"SQS:*\",\"Resource\":\"arn:aws:sqs:" + aws_region_id + ":" + aws_account_id + ":" + queueName + "\"}]}",
                    "KmsMasterKeyId": queueKmsMasterKeyId,
                    "KmsDataKeyReusePeriodSeconds": str(queueKmsDataKeyReusePeriodSeconds),
                    "FifoQueue": "true",
                    "ContentBasedDeduplication": "false"
                }
            )

    consumer.validate(
        logger = logger,
        ConsumerOptions = {
            "aws_region_id"     : aws_region_id,
            "aws_account_id"    : aws_account_id,
            "queueName"         : queueName,
            "roleArn"           : consumerRoleArn,
            "s3BucketName"      : consumerBucketName,
            "s3ObjectKey"       : consumerObjectKey,
            "layerArn"          : consumerLayerArn,
            "batchSize"         : consumerBatchSize,
            "timeOut"           : queueVisibilityTimeout
        }
    )
    
    return queue