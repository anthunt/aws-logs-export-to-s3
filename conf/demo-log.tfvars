aws = {
    log = {
        region  = "ap-northeast-2"
        profile = "HGI-LOG"
    }
    prd = {
        region  = "ap-northeast-2"
        profile = "HGI-API-PRD"
    }
    stg = {
        region  = "ap-northeast-2"
        profile = "HGI-API-STG"
    }
    dev = {
        region  = "ap-northeast-2"
        profile = "HGI-API-DEV"
    }
}

export = {
    backup_bucket   = "hgi-log-s3-app-logs"
    lambda_bucket   = "hgi-log-s3-logs-collector-lambda"
    kms_key         = "b1d5f8bc-5120-457a-8cb2-f93686d780ee"
    kmsAlias        = "alias/HGI-LOG-KMS"
    events          = {
        prd = {
            schedule = "cron(10 15 ? * * *)"
            prefix   = "HGI-API-PRD"
        }
        stg = {
            schedule = "cron(20 15 ? * * *)"
            prefix   = "HGI-API-STG"
        }
        dev = {
            schedule = "cron(30 15 ? * * *)"
            prefix   = "HGI-API-DEV"
        }
    }
}
