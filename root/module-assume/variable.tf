variable enabled {
    type    = bool
    default = true
}

variable aws {
    type = object({
        region  = string
        profile = string
    })
}

variable export {
    type = object({
        log_account_id  = string
        backup_bucket   = string
        prefix          = string
    })
}