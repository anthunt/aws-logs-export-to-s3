module assumeModule_PRD {
    source  = "./module-assume"

    enabled = lookup(var.aws, "prd", null) == null ? false : true
    aws     = lookup(var.aws, "prd", var.aws.log)
    export  = {
        log_account_id  = "${data.aws_caller_identity.current.account_id}"
        backup_bucket   = var.export.backup_bucket
        prefix          = var.export.events.prd.prefix
    }
}

module assumeModule_STG {
    source  = "./module-assume"

    enabled = lookup(var.aws, "stg", null) == null ? false : true
    aws     = lookup(var.aws, "stg", var.aws.log)
    export  = {
        log_account_id  = "${data.aws_caller_identity.current.account_id}"
        backup_bucket   = var.export.backup_bucket
        prefix          = var.export.events.stg.prefix
    }
}

module assumeModule_DEV {
    source  = "./module-assume"

    enabled = lookup(var.aws, "dev", null) == null ? false : true
    aws     = lookup(var.aws, "dev", var.aws.log)
    export  = {
        log_account_id  = "${data.aws_caller_identity.current.account_id}"
        backup_bucket   = var.export.backup_bucket
        prefix          = var.export.events.dev.prefix
    }
}

module assumeModule_API_PRD {
    source  = "./module-assume"

    enabled = lookup(var.aws, "api_prd", null) == null ? false : true
    aws     = lookup(var.aws, "api_prd", var.aws.log)
    export  = {
        log_account_id  = "${data.aws_caller_identity.current.account_id}"
        backup_bucket   = var.export.backup_bucket
        prefix          = lookup(var.export.events, "api_prd", null) == null ? "" : var.export.events.api_prd.prefix
    }
}

module assumeModule_API_STG {
    source  = "./module-assume"

    enabled = lookup(var.aws, "api_stg", null) == null ? false : true
    aws     = lookup(var.aws, "api_stg", var.aws.log)
    export  = {
        log_account_id  = "${data.aws_caller_identity.current.account_id}"
        backup_bucket   = var.export.backup_bucket
        prefix          = lookup(var.export.events, "api_stg", null) == null ? "" : var.export.events.api_stg.prefix
    }
}

module assumeModule_API_DEV {
    source  = "./module-assume"

    enabled = lookup(var.aws, "api_dev", null) == null ? false : true
    aws     = lookup(var.aws, "api_dev", var.aws.log)
    export  = {
        log_account_id  = "${data.aws_caller_identity.current.account_id}"
        backup_bucket   = var.export.backup_bucket
        prefix          = lookup(var.export.events, "api_dev", null) == null ? "" : var.export.events.api_dev.prefix
    }
}

locals {
    assume_roles = {for key, val in {
        prd     = module.assumeModule_PRD.roleArn.arn
        stg     = module.assumeModule_STG.roleArn.arn
        dev     = module.assumeModule_DEV.roleArn.arn
        api_prd = lookup(var.aws, "api_prd", null) == null ? null : module.assumeModule_API_PRD.roleArn.arn
        api_stg = lookup(var.aws, "api_stg", null) == null ? null : module.assumeModule_API_STG.roleArn.arn
        api_dev = lookup(var.aws, "api_dev", null) == null ? null : module.assumeModule_API_DEV.roleArn.arn
    }: key => val if val != null}    
}

module logModule {
    source              = "./module-log"

    aws                 = var.aws.log
    export              = var.export
    assume_role_arns    = local.assume_roles

    providers = {
        aws = aws
    }

    depends_on = [
        module.assumeModule_PRD,
        module.assumeModule_STG,
        module.assumeModule_DEV,
        module.assumeModule_API_PRD,
        module.assumeModule_API_STG,
        module.assumeModule_API_DEV
    ]
}