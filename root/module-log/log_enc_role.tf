resource "aws_iam_role" "AppLogSSEEventForPutObjectRole" {
    
    name        = "AppLogSSEEventForPutObjectRole"
    path        = "/service-role/"
    description = "lambda role for AppLogSSEEventForPutObjectRole"

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

resource "aws_iam_role_policy" "AppLogSSEEventForPutObjectRole_AWSLambdaS3ExecutionRole" {

    name        = "AWSLambdaS3ExecutionRole"
    role        = aws_iam_role.AppLogSSEEventForPutObjectRole.name
    policy      = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "s3:GetObject"
                ],
                "Resource": "arn:aws:s3:::*"
            }
        ]
    }
    EOF
}

resource "aws_iam_role_policy" "AppLogSSEEventForPutObjectRole_AWSLambdaBasicExecutionRole" {

    name        = "AWSLambdaBasicExecutionRole"
    role        = aws_iam_role.AppLogSSEEventForPutObjectRole.name
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
                    "arn:aws:logs:${var.aws.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/AppLogSSEEventForPutObject:*"
                ]
            }
        ]
    }
    EOF
}

resource "aws_iam_role_policy" "AppLogSSEEventForPutObjectRole_S3CopyAndDeletePolicy" {
    
    name        = "S3CopyAndDeletePolicy"
    role        = aws_iam_role.AppLogSSEEventForPutObjectRole.name
    policy      = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "s3:PutObject",
                    "s3:GetObjectAcl",
                    "s3:GetObject",
                    "s3:DeleteObjectVersion",
                    "s3:PutObjectVersionAcl",
                    "s3:GetObjectVersionAcl",
                    "s3:PutObjectLegalHold",
                    "s3:GetObjectLegalHold",
                    "s3:DeleteObject",
                    "s3:PutObjectAcl",
                    "s3:GetObjectVersion",
                    "s3:ListBucket"
                ],
                "Resource": [
                    "arn:aws:s3:::${var.export.backup_bucket}",
                    "arn:aws:s3:::${var.export.backup_bucket}/*"
                ]
            }
        ]
    }
    EOF
}

resource "aws_iam_role_policy" "AppLogSSEEventForPutObjectRole_SSEKMSPolicy" {
    
    name        = "SSEKMSPolicy"
    role        = aws_iam_role.AppLogSSEEventForPutObjectRole.name
    policy      = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "kms:Decrypt",
                    "kms:Encrypt",
                    "kms:ReEncrypt*",
                    "kms:GenerateDataKey*",
                    "kms:DescribeKey"
                ],
                "Resource": "arn:aws:kms:${var.aws.region}:${data.aws_caller_identity.current.account_id}:key/${var.export.kms_key}"
            }
        ]
    }
    EOF
}

resource "aws_iam_role_policy" "AppLogSSEEventForPutObjectRole_ParameterStorePolicy" {
    
    name        = "ParameterStorePolicy" 
    role        = aws_iam_role.AppLogSSEEventForPutObjectRole.name
    policy      = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "ssm:DescribeParameters"
                ],
                "Resource": "*"
            },
            {
                "Effect": "Allow",
                "Action": [
                    "ssm:GetParameter"
                ],
                "Resource": "${aws_ssm_parameter.log_kms_arn.arn}"
            }
        ]
    }
    EOF
}