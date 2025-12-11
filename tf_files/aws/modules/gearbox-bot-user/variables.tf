
variable "vpc_name" {
}

variable "bucket_name" {
}

variable "bucket_access_arns" {
  description = "When gearbox bot has to access another bucket that wasn't created by the VPC module"
  type        = "list"
  default     = []
}


variable "prod_promotion_role_arn" {
  type        = string
  default     = null
  description = "Role ARN in PROD that staging can assume. Null in prod."
}