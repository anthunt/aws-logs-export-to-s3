import boto3
import botocore

"""
- AWS STS Assume Module
- usage:
    import assume
    import logging
    
    def process():
        logger = logging.getLogger()
        assumedCredentials = assume.credentials(
            logger  =   logger,
            RoleArn =   "Other account assume role arn",
            Prefix  =   "Prefix string for assumed session name"
        )
- output
    {
        'AccessKeyId': "access key id - string",
        'SecretAccessKey': "secret access key - string",
        'SessionToken': "session token - string",
        'Expiration': "expiration - datetime"
    }
"""
def credentials(logger, RoleArn, Prefix):
    sts = boto3.client('sts')
    try:
        assumed = sts.assume_role(
            RoleArn=RoleArn,
            RoleSessionName=Prefix+"_Assume_Collecting"
        )
        logger.debug("Assuemd Credentials = {0}".format(assumed))
    except botocore.exceptions.ClientError as error:
        logger.error("Error = {0}".format(error.response))
        raise error
    return assumed.get("Credentials")