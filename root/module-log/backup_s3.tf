resource "aws_s3_bucket" "backup_bucket" {
    bucket      = var.export.backup_bucket
    acl         = "private"
    tags        = {}

    object_lock_configuration {
        object_lock_enabled = "Enabled"
    }

    versioning {
        enabled = true
        mfa_delete = false
    }

    lifecycle {
        prevent_destroy = true
    }
}

data "aws_iam_policy_document" "BackupBucketPolicy" {
    version = "2012-10-17"

    statement {
        effect      = "Allow"
        actions     = ["s3:GetBucketAcl"]
        resources   = ["arn:aws:s3:::${aws_s3_bucket.backup_bucket.id}"]
        principals {
            type        = "Service"
            identifiers = ["logs.${var.aws.region}.amazonaws.com"]
        }
    }

    statement {
        effect      = "Allow"
        actions     = ["s3:PutObject"]
        resources   = ["arn:aws:s3:::${aws_s3_bucket.backup_bucket.id}/*"]
        principals {
            type        = "Service"
            identifiers = ["logs.${var.aws.region}.amazonaws.com"]
        }
        condition {
            test     = "StringEquals"
            variable = "s3:x-amz-acl"
            values = ["bucket-owner-full-control"]
        }
    }

    statement {
        effect = "Allow"
        actions = ["s3:PutObject"]
        resources = ["arn:aws:s3:::${aws_s3_bucket.backup_bucket.id}/*"]
        principals {
            type = "AWS"
            identifiers = local.assume_role_arns
        }        
        condition {
            test     = "StringEquals"
            variable = "s3:x-amz-acl"
            values = ["bucket-owner-full-control"]
        }
    }
}

resource "aws_s3_bucket_policy" "backup_bucket_policy" {
    bucket = aws_s3_bucket.backup_bucket.id
    policy = data.aws_iam_policy_document.BackupBucketPolicy.json
}