resource "aws_cloudwatch_event_rule" "AppLogSSEEventRule" {
    name        = "AppLogSSEEventRule"
    description = "AppLogSSEEventRule"

    event_pattern = <<EOF
    {
      "source": [
        "aws.s3"
      ],
      "detail-type": [
        "AWS API Call via CloudTrail"
      ],
      "detail": {
        "eventSource": [
          "s3.amazonaws.com"
        ],
        "eventName": [
          "PutObject"
        ],
        "requestParameters": {
          "bucketName": [
            "${var.export.backup_bucket}"
          ]
        }
      }
    }
    EOF

    depends_on = [
        aws_lambda_function.AppLogSSEEventForPutObject_lambda
    ]
}

resource "aws_cloudwatch_event_target" "AppLogSSEEventRule_LambdaFunctionTarget" {
    rule        = aws_cloudwatch_event_rule.AppLogSSEEventRule.name
    arn         = aws_lambda_function.AppLogSSEEventForPutObject_lambda.arn
}

resource "aws_lambda_permission" "AppLogSSEEventRule_Lambda_Permission" {
    statement_id  = "AllowExecutionFromCloudWatch"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.AppLogSSEEventForPutObject_lambda.arn
    principal     = "events.amazonaws.com"
    source_arn    = aws_cloudwatch_event_rule.AppLogSSEEventRule.arn
}