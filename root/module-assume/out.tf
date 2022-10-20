output roleArn {
    value = length(aws_iam_role.CollectCloudWatchLogsRole) == 0 ? null : aws_iam_role.CollectCloudWatchLogsRole[0]
}