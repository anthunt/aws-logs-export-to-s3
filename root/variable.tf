variable "aws" {
    type = map(object({
        region  = string
        profile = string
    }))
}

variable "export" {
    type = object({
        backup_bucket   = string
        lambda_bucket   = string
        kms_key         = string
        kmsAlias        = string
        events          = map(object({
            schedule = string
            prefix   = string
        }))
    })
}