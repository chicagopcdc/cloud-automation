variable "vpc_name" {
  # default "something"
}

variable "environment" {
  # value for 'Environment' key to tag the new resources with
}

variable "purpose" {
  default = "data bucket"
}

variable "bucket_lifecycle_filter_prefix" {
  default = ""
}
variable "noncurrent_version_expiration_days" {
  default = 180
}

variable "gearbox_allowed_origins" {
  # value for CORS allowed origins for gearbox S3 bucket 
}
