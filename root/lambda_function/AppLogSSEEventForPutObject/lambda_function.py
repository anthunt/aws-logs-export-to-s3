import re
import logging
import traceback
import boto3
import time
from botocore.exceptions import ClientError

# Logger 설정
logger = logging.getLogger()

# Logging Level 설정
logger.setLevel(logging.DEBUG)

retryCountLimit = 5
retryCount = 0

def lambda_handler(event, context):
    logger.debug("EventMessage = {0}".format(event))
    bucketName = event.get("detail").get("requestParameters").get("bucketName")
    objectKey = event.get("detail").get("requestParameters").get("key")
    
    if objectKey[-20:] == '/aws-logs-write-test':
        
        deleteObject(bucketName, objectKey)
        logger.info("[deleted] " + objectKey)
                
    else:
        
        logger.debug(event)
        logger.debug(context)
        logger.debug(bucketName)
        logger.debug(objectKey)
        
        objectLock = False
        
        try:
            s3 = boto3.client("s3")
            response = s3.get_object_legal_hold(
                Bucket=bucketName,
                Key=objectKey
            )
            if response.get("LegalHold").get("Status") == "ON":
                objectLock = True
        except ClientError as e:
            objectLock = False
        
        logger.debug("ObjectLock : " + str(objectLock))
        
        if not objectLock:
            progressTask(bucketName, objectKey)
        else:
            logger.info("skiped")
            
def progressTask(bucketName, objectKey):
    global retryCount
    try:
        copyedObject = getCopyObjectKey(objectKey)
        logger.debug("copyedObject = " + str(copyedObject))
        copyObject(bucketName, objectKey, copyedObject.get("copyObjectKey"))
        logger.info("copyed")
    except ClientError as e: 
        if e.response['Error']['Code'] == 'NoSuchKey':
            if retryCount <= retryCountLimit:
                time.sleep(2)
                retryCount = retryCount + 1
                progressTask(bucketName, objectKey)
            else:
                logger.error("RetryCount limit exceeded.\nErrorMessage = {0}\nObjectKey = {1}".format(e, objectKey))
        else:
            logger.error("ErrorMessage = {0}\nObjectKey = {1}".format(e, objectKey))
            traceback.print_exc()
    except Exception as e:
        logger.error("ErrorMessage = {0}\nObjectKey = {1}".format(e, objectKey))
        traceback.print_exc()
    
    
    deleteObject(bucketName, objectKey)
    deleteObject(bucketName, copyedObject.get("writeTestObjectKey"))
                
def getCopyObjectKey(objectKey):
    pattern = re.compile('.*/\d{4}/\d{2}/\d{2}/\d{2}/')
    prefix = pattern.search(objectKey).group()
    logger.debug("CopyObjectKey Prefix = " + prefix)
    searchedKey = objectKey[len(prefix):]
    logger.debug(searchedKey)
    copyObjectKey = searchedKey.replace("/", "-")[1:]
    logger.debug("copyObjectKey = " + copyObjectKey)
    #pattern2 = re.compile('/([\w]|-|^/|[.]|[\%]|[\$]|[\[]|[\]])*/\d*.gz')
    #searchedKey = pattern2.search(objectKey).group()
    #logger.debug("searchedKey = " + searchedKey)
    #copyObjectKey = searchedKey.replace("/", "-")[1:]
    #logger.debug("copyObjectKey = " + copyObjectKey)
        
    return {
        "writeTestObjectKey": prefix + "aws-logs-write-test",
        "copyObjectKey" : "".join([
            prefix[:-3],
            prefix.replace("/", "-"),
            copyObjectKey
        ])
    }

def copyObject(bucketName, objectKey, copyObjectKey):
    ssmClient = boto3.client('ssm')
    response = ssmClient.get_parameter(
        Name='/app/cloudwatch/log/export/s3/kms/arn',
        WithDecryption=True
    )

    s3 = boto3.resource("s3")
    s3Object = s3.Object(bucketName, copyObjectKey)
    return s3Object.copy_from(
        CopySource= {
            "Bucket": bucketName,
            "Key": objectKey
        },
        ServerSideEncryption="aws:kms",
        SSEKMSKeyId=response.get("Parameter").get("Value"),
        ObjectLockLegalHoldStatus="ON"
    )

def deleteObject(bucketName, objectKey):
    s3 = boto3.client("s3")
    
    try:
        response = s3.get_object(
            Bucket=bucketName,
            Key=objectKey
        )
        s3.delete_object(
            Bucket=bucketName,
            Key=objectKey,
            VersionId=response.get("VersionId")
        )
    except ClientError as e:
        logger.warn("Delete Object Error = {0}\nObject Key = {1}".format(e, objectKey))
        
    
def isExistObject(s3, bucketName, objectKey):
    
    isExist = False
    
    try:
        response = s3.get_object(
            Bucket=bucketName,
            Key=objectKey
        )
        isExist = True
    except ClientError as e:
        logger.warn({"warning":e})
    
    return isExist