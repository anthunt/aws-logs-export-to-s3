import boto3
import botocore

"""
- Creating SQS Consumer Lambda Function
- Usage:
    import consumer
    
    def process():
        logger = logging.getLogger()
        consumer.validate(
            logger : logger,
            ConsumerOptions = {
                "aws_region_id"     : "AWS Region ID - string",
                "aws_account_id"    : "AWS Account ID - string",
                "queueName"         : "SQS Queue Name - string",
                "roleArn"           : "Role Arn for lambda execution role - string",
                "s3BucketName"      : "S3 Bucket Name for lambda code - string",
                "s3ObjectKey"       : "S3 Object Key for lambda code - string",
                "layerArn"          : "layerArn with version for lambda layer - string",
                "batchSize"         : "batch size - int"
            }
        )
"""
def validate(logger, ConsumerOptions):
    queueName = ConsumerOptions.get("queueName")
    functionName = queueName.replace(".", "-") + "SQSConsumer"
    
    lambda_client = boto3.client("lambda")
    
    # Lambda Consumer Function Check
    try:
        response = lambda_client.get_function(
            FunctionName=functionName
        ) 
        
        response = lambda_client.update_function_configuration(
            FunctionName=functionName,
            Timeout=ConsumerOptions.get("timeOut"),
            MemorySize=128,
            Layers=[
                ConsumerOptions.get("layerArn")
            ]
        )
    except botocore.exceptions.ClientError as error:
        logger.error(error.response)
        if error.response.get("Error").get("Code") == "ResourceNotFoundException":
            logger.debug("start create lambda function [{0}] for SQS [{1}]".format(functionName, queueName))
            response = lambda_client.create_function(
                FunctionName=functionName,
                Runtime='python3.8',
                Role=ConsumerOptions.get("roleArn"),
                Handler='lambda_function.lambda_handler',
                Code={
                    'S3Bucket': ConsumerOptions.get("s3BucketName"),
                    'S3Key': ConsumerOptions.get("s3ObjectKey")
                },
                Description='SQS Consumer Function for ' + queueName,
                Timeout=ConsumerOptions.get("timeOut"),
                MemorySize=128,
                Publish=True,
                Layers=[
                    ConsumerOptions.get("layerArn")
                ]
            )
            logger.debug("created lambda function [{0}] for SQS [{1}]".format(functionName, queueName))
    
    # Consumer Lambda Function Concurrency Check
    response = lambda_client.get_function_concurrency(
        FunctionName=functionName
    )
    
    if response.get("ReservedConcurrentExecutions") != 1:
        logger.debug("start setting up lambda function concurrency to [{0}]".format(functionName))
        response = lambda_client.put_function_concurrency(
            FunctionName=functionName,
            ReservedConcurrentExecutions=1
        )
        logger.debug("lambda function concurrency setup was done to [{0}]".format(functionName))
    
    # Consumer Lambda Function Event Source Mapping Check
    eventSourceArn = "arn:aws:sqs:" + ConsumerOptions.get("aws_region_id") + ":" + ConsumerOptions.get("aws_account_id") + ":" + queueName
    
    response = boto3.client("lambda").list_event_source_mappings(
        FunctionName=functionName
    )
    
    isMapped = False
    for eventSourceMapping in response.get("EventSourceMappings"):
        if eventSourceArn == eventSourceMapping.get("EventSourceArn"):
            isMapped = True
            break;
    
    if not isMapped:
        logger.debug("start create event source mapping on lambda function [{0}] for SQS [{1}]".format(functionName, queueName))
        response = lambda_client.create_event_source_mapping(
            EventSourceArn=eventSourceArn,
            FunctionName=functionName,
            Enabled=True,
            BatchSize=ConsumerOptions.get("batchSize")
        )
        logger.debug("created event source mapping on lambda function [{0}] for SQS [{1}]".format(functionName, queueName))