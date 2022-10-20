import logging
import CloudWatchLogsExportToS3 as cl

def lambda_handler(event, context):

    logger = logging.getLogger()
    logger.setLevel(logging.INFO)
    
    cls = cl.CloudWatchLogsExportToS3(
        event.get("Records"),
        logger
    )

    cls.export()

    return True
