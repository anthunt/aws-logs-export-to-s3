resource "aws_iam_role" "CloudWatchLogsToLogS3ExportRole" {

    name        = "CloudWatchLogsToLogS3ExportRole"
    path        = "/service-role/"
    description = "lambda role for CloudWatchLogsToLogS3Export"

    assume_role_policy = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
            "Effect": "Allow",
            "Principal": {
                "Service": "lambda.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
            }
        ]
    }
    EOF
}

resource "aws_iam_role_policy_attachment" "CloudWatchLogsToLogS3ExportRole_AmazonSQSFullAccess" {
    role        = aws_iam_role.CloudWatchLogsToLogS3ExportRole.name
    policy_arn  = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"
}

resource "aws_iam_role_policy_attachment" "CloudWatchLogsToLogS3ExportRole_AWSLambdaFullAccess" {
    role        = aws_iam_role.CloudWatchLogsToLogS3ExportRole.name
    policy_arn  = "arn:aws:iam::aws:policy/AWSLambdaFullAccess"
}

resource "aws_iam_role_policy" "CloudWatchLogsToLogS3ExportRole_AWSLambdaBasicExecutionRole" {

    name        = "AWSLambdaBasicExecutionRole"
    role        = aws_iam_role.CloudWatchLogsToLogS3ExportRole.name
    policy      = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": "logs:CreateLogGroup",
                "Resource": "arn:aws:logs:${var.aws.region}:${data.aws_caller_identity.current.account_id}:*"
            },
            {
                "Effect": "Allow",
                "Action": [
                    "logs:CreateLogStream",
                    "logs:PutLogEvents"
                ],
                "Resource": [
                    "arn:aws:logs:${var.aws.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/CloudWatchLogsToLogS3Export:*",
                    "arn:aws:logs:${var.aws.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/CloudWatchLogsToLogS3ExportJob:*"
                ]
            }
        ]
    }
    EOF
}

data "aws_iam_policy_document" "CloudWatchLogsAssumeRolePolicy" {
    version = "2012-10-17"
    statement {
        effect = "Allow"
        actions = [
            "sts:AssumeRole"
        ]
        resources = local.assume_role_arns
    }
}

resource "aws_iam_role_policy" "CloudWatchLogsToLogS3ExportRole_CloudWatchLogsAssumeRolePolicy" {
    
    name        = "CloudWatchLogsAssumeRolePolicy"
    role        = aws_iam_role.CloudWatchLogsToLogS3ExportRole.name
    policy      = data.aws_iam_policy_document.CloudWatchLogsAssumeRolePolicy.json
}

resource "aws_iam_role_policy" "CloudWatchLogsToLogS3ExportRole_CloudWatchLogsToLogS3ExportPolicy" {
    
    name        = "CloudWatchLogsToLogS3ExportPolicy"
    role        = aws_iam_role.CloudWatchLogsToLogS3ExportRole.name
    policy      = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": "logs:CancelExportTask",
                "Resource": "*"
            },
            {
                "Effect": "Allow",
                "Action": [
                    "s3:PutObject",
                    "s3:GetObjectAcl",
                    "s3:GetObject",
                    "logs:CreateExportTask",
                    "s3:AbortMultipartUpload",
                    "logs:DescribeLogGroups",
                    "s3:PutObjectVersionAcl",
                    "logs:DescribeSubscriptionFilters",
                    "s3:PutObjectAcl"
                ],
                "Resource": [
                    "arn:aws:s3:::${var.export.backup_bucket}/*",
                    "arn:aws:logs:${var.aws.region}:${data.aws_caller_identity.current.account_id}:log-group:*"
                ]
            }
        ]
    }
    EOF
}

resource "aws_iam_role_policy" "CloudWatchLogsToLogS3ExportRole_KMSKeyPolicy" {
    
    name        = "KMSKeyPolicy"
    role        = aws_iam_role.CloudWatchLogsToLogS3ExportRole.name
    policy      = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "kms:Decrypt",
                    "kms:Encrypt",
                    "kms:GenerateDataKey"
                ],
                "Resource": "arn:aws:kms:${var.aws.region}:${data.aws_caller_identity.current.account_id}:key/${var.export.kms_key}"
            }
        ]
    }
    EOF
}