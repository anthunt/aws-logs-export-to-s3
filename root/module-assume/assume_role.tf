resource "aws_iam_role" "CollectCloudWatchLogsRole" {
    
    count = var.enabled ? 1 : 0

    name        = "CollectCloudWatchLogsRole"
    path        = "/"
    description = "lambda role for AppLogSSEEventForPutObjectRole"

    assume_role_policy = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
            "Effect": "Allow",
            "Principal": {
                "AWS": "arn:aws:iam::${var.export.log_account_id}:role/service-role/CloudWatchLogsToLogS3ExportRole"
            },
            "Action": "sts:AssumeRole",
            "Condition": {}
            }
        ]
    }
    EOF
}

resource "aws_iam_role_policy" "CollectCloudWatchLogsRole_CollectCloudWatchLogsPolicy" {
    
    count = var.enabled ? 1 : 0

    name        = "CollectCloudWatchLogsPolicy"
    role        = aws_iam_role.CollectCloudWatchLogsRole[count.index].name
    policy      = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "logs:DescribeExportTasks",
                    "logs:CancelExportTask"
                ],
                "Resource": "*"
            },
            {
                "Effect": "Allow",
                "Action": [
                    "logs:CreateExportTask",
                    "s3:PutObject",
                    "s3:GetObjectAcl",
                    "s3:GetObject",
                    "logs:DescribeLogGroups",
                    "s3:AbortMultipartUpload",
                    "logs:DescribeSubscriptionFilters",
                    "s3:PutObjectVersionAcl",
                    "s3:PutObjectAcl"
                ],
                "Resource": [
                    "arn:aws:logs:${var.aws.region}:${data.aws_caller_identity.current.account_id}:log-group:*",
                    "arn:aws:s3:::${var.export.backup_bucket}/${var.export.prefix}/*"
                ]
            }
        ]
    }
    EOF
}