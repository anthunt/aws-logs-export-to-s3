resource "aws_cloudwatch_event_rule" "CloudWatchLogsToLogS3EventRule" {
    for_each    = var.export.events

    name        = "CloudWatchLogsToLogS3EventRule_${each.key}"
    description = "CloudWatchLogsToLogS3EventRule_${each.key}"

    schedule_expression = each.value.schedule

    depends_on = [
        aws_lambda_function.CloudWatchLogsToLogS3Export_lambda
    ]
}

resource "aws_cloudwatch_event_target" "CloudWatchLogsToLogS3EventRule_LambdaFunctionTarget" {
    for_each    = var.export.events

    rule        = aws_cloudwatch_event_rule.CloudWatchLogsToLogS3EventRule[each.key].name
    arn         = aws_lambda_function.CloudWatchLogsToLogS3Export_lambda.arn
    input       = <<EOF
    {
        "loggingBucketName" : "${var.export.backup_bucket}",
        "roleArn"           : "${lookup(var.assume_role_arns, each.key, "")}",
        "Prefix"            : "${each.value.prefix}",
        "QueueOptions"      : {
            "VisibilityTimeout"             : 120,
            "MessageRetentionPeriod"        : 86400,
            "KmsMasterKeyId"                : "${var.export.kmsAlias}",
            "KmsDataKeyReusePeriodSeconds"  : 300,
            "ConsumerOptions" : {
                "BucketName"   : "${var.export.lambda_bucket}",
                "ObjectKey"    : "Consumer/lambda_function.zip",
                "LayerArn"     : "${aws_lambda_layer_version.ConsumerLayer.arn}",
                "BatchSize"    : 10
            }
        }
    }
    EOF
}

resource "aws_lambda_permission" "CloudWatchLogsToLogS3Export_Lambda_Permission" {
    for_each    = var.export.events

    statement_id  = "AllowExecutionFromCloudWatch_${each.key}"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.CloudWatchLogsToLogS3Export_lambda.arn
    principal     = "events.amazonaws.com"
    source_arn    = aws_cloudwatch_event_rule.CloudWatchLogsToLogS3EventRule[each.key].arn

}