
#------------- LOGGING
resource "aws_s3_bucket" "log_bucket" {
  bucket = "${var.vpc_name}-data-bucket-with-versioning-log"
  tags = {
    Purpose = "s3 bucket log bucket"
  }
}

resource "aws_s3_bucket" "data_bucket" {
  bucket = "${var.vpc_name}-data-bucket-with-versioning"
  versioning {
    enabled = true
  }

  lifecycle_rule {
    enabled = true
    noncurrent_version_expiration {
        days = "${var.noncurrent_version_expiration_days}"
    }
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  logging {
    target_bucket = "${aws_s3_bucket.log_bucket.id}"
    target_prefix = "log/"
  }

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET","POST"]
    # CORS requires the full URL including protocol so adding it here
    allowed_origins = ["https://${element(var.gearbox_allowed_origins,0)}"]
    expose_headers = ["Access-Control-Allow-Origin","ETag","x-csrf-token","Content-Security-Policy"]
    max_age_seconds = 3000
  }

  tags = { 
    Name        = "${var.vpc_name}-data-bucket-with-versioning"
    Environment = "${var.environment}"
    Purpose     = "${var.purpose}"
  }

}

#------------ RESTRICT PUBLIC ACCESS
resource "aws_s3_bucket_public_access_block" "data_bucket_privacy" {
  bucket = "${aws_s3_bucket.data_bucket.id}"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

