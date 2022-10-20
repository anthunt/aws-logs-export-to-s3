locals {
    assume_role_arns = [for key, val in var.assume_role_arns:val]
}