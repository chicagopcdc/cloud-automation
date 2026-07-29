
variable "vpc_name" {
}

variable "bucket_name" {
}

variable "bucket_access_arns" {
  description = "When gearbox bot has to access another bucket that wasn't created by the VPC module"
  type        = "list"
  default     = []
}

variable "is_gearbox_staging" {
  default = false
}

variable "is_gearbox_prod" {
  default = false
}

variable "prod_promotion_role_arn" {
  default     = ""
  description = "Role ARN in PROD that staging can assume. Null in prod."
}

variable "staging_account_id" {
  default     = ""
  description = "Role ARN in PROD that staging can assume. Null in prod."
}

variable "staging_bucket_name" {
  description = "Name of the staging S3 bucket that the prod promotion role needs read access to"
  default     = ""
}





