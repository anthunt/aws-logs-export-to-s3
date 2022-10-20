resource "aws_ssm_parameter" "log_kms_arn" {
    
    name        = "/app/cloudwatch/log/export/s3/kms/arn"
    description = "kms arn for CloudWatchLogsExportToS3/AppLogSSEEventForPutObject lambda function"
    type        = "String"
    value       = "arn:aws:kms:${var.aws.region}:${data.aws_caller_identity.current.account_id}:key/${var.export.kms_key}"

}