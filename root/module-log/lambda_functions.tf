resource "aws_lambda_function" "AppLogSSEEventForPutObject_lambda" {
    filename      = "./lambda_function/AppLogSSEEventForPutObject.zip"
    function_name = "AppLogSSEEventForPutObject"
    role          = aws_iam_role.AppLogSSEEventForPutObjectRole.arn
    handler       = "lambda_function.lambda_handler"

    publish = true

    source_code_hash = filebase64sha256("./lambda_function/AppLogSSEEventForPutObject.zip")

    runtime = "python3.8"

    memory_size = 128
    timeout = 30

    reserved_concurrent_executions = -1

    tracing_config {
        mode = "PassThrough"
    }

    depends_on = [
        aws_iam_role.AppLogSSEEventForPutObjectRole,
        aws_iam_role_policy.AppLogSSEEventForPutObjectRole_AWSLambdaS3ExecutionRole,
        aws_iam_role_policy.AppLogSSEEventForPutObjectRole_AWSLambdaBasicExecutionRole,
        aws_iam_role_policy.AppLogSSEEventForPutObjectRole_S3CopyAndDeletePolicy,
        aws_iam_role_policy.AppLogSSEEventForPutObjectRole_SSEKMSPolicy
    ]
}

resource "aws_lambda_function" "CloudWatchLogsToLogS3Export_lambda" {
    filename        = "./lambda_function/CloudWatchLogsToLogS3Export.zip"
    function_name   = "CloudWatchLogsToLogS3Export"
    role            = aws_iam_role.CloudWatchLogsToLogS3ExportRole.arn
    handler         = "lambda_function.lambda_handler"

    publish = true

    source_code_hash = filebase64sha256("./lambda_function/CloudWatchLogsToLogS3Export.zip")

    runtime = "python3.8"
    
    memory_size = 128
    timeout = 180

    reserved_concurrent_executions = -1

    tracing_config {
        mode = "PassThrough"
    }

    depends_on = [
        aws_iam_role.CloudWatchLogsToLogS3ExportRole,
        aws_iam_role_policy_attachment.CloudWatchLogsToLogS3ExportRole_AmazonSQSFullAccess,
        aws_iam_role_policy_attachment.CloudWatchLogsToLogS3ExportRole_AWSLambdaFullAccess,
        aws_iam_role_policy.CloudWatchLogsToLogS3ExportRole_AWSLambdaBasicExecutionRole,
        aws_iam_role_policy.CloudWatchLogsToLogS3ExportRole_CloudWatchLogsAssumeRolePolicy,
        aws_iam_role_policy.CloudWatchLogsToLogS3ExportRole_CloudWatchLogsToLogS3ExportPolicy,
        aws_iam_role_policy.CloudWatchLogsToLogS3ExportRole_KMSKeyPolicy,
        aws_lambda_layer_version.ConsumerLayer
    ]
}

resource "aws_lambda_layer_version" "ConsumerLayer" {
    s3_bucket           = var.export.lambda_bucket
    s3_key              = aws_s3_bucket_object.layerObject.key
    s3_object_version   = aws_s3_bucket_object.layerObject.version_id
    layer_name          = "CloudWatchLogsExportToS3"
    description         = "Consumer Layer for CloudWatchLogsToLogS3Export Consumer functions"
    compatible_runtimes = ["python3.8"]
}