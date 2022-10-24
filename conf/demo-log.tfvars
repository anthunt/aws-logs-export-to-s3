aws = {
    log = {
        region  = "ap-northeast-2"
        profile = "DEMO-LOG"
    }
    prd = {
        region  = "ap-northeast-2"
        profile = "DEMO-API-PRD"
    }
    stg = {
        region  = "ap-northeast-2"
        profile = "DEMO-API-STG"
    }
    dev = {
        region  = "ap-northeast-2"
        profile = "DEMO-API-DEV"
    }
}

export = {
    backup_bucket   = "demo-log-s3-app-logs"
    lambda_bucket   = "demo-log-s3-logs-collector-lambda"
    kms_key         = "xxxxx-xxxx-457a-8cb2-f93686d780ee"
    kmsAlias        = "alias/DEMO-LOG-KMS"
    events          = {
        prd = {
            schedule = "cron(10 15 ? * * *)"
            prefix   = "DEMO-API-PRD"
        }
        stg = {
            schedule = "cron(20 15 ? * * *)"
            prefix   = "DEMO-API-STG"
        }
        dev = {
            schedule = "cron(30 15 ? * * *)"
            prefix   = "DEMO-API-DEV"
        }
    }
}