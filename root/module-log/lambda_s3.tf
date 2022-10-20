resource "aws_s3_bucket" "collector_lambda_bucket" {
    bucket      = var.export.lambda_bucket
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

resource "aws_s3_bucket_object" "layerObject" {
    bucket      = var.export.lambda_bucket
    key         = "Layer/python.zip"
    source      = "./lambda_function/layer/python.zip"

    etag = filemd5("./lambda_function/layer/python.zip")

    depends_on = [
        aws_s3_bucket.collector_lambda_bucket
    ]
}

resource "aws_s3_bucket_object" "consumerObject" {
    bucket      = var.export.lambda_bucket
    key         = "Consumer/lambda_function.zip"
    source      = "./lambda_function/Consumer/lambda_function.zip"

    etag = filemd5("./lambda_function/Consumer/lambda_function.zip")
    
    depends_on = [
        aws_s3_bucket.collector_lambda_bucket
    ]
}