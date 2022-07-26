
## The actual data bucket

resource "aws_s3_bucket" "data_bucket" {
  bucket = "${var.vpc_name}-data-release-bucket"
  acl    = "private"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  tags = {
    Name        = "${var.vpc_name}-data-release-bucket"
    Environment = "${var.environment}"
    Purpose     = "data bucket"
  }

  lifecycle = {
    ignore_changes = ["cors_rule"]
  }
}


resource "aws_s3_bucket_public_access_block" "data_bucket_privacy" {
  bucket                      = "${aws_s3_bucket.data_bucket.id}"

  block_public_acls           = true
  block_public_policy         = true
  ignore_public_acls          = true
  restrict_public_buckets     = true
}



