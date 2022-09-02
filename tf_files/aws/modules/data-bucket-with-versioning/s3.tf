
## The actual data bucket

resource "aws_s3_bucket" "data_bucket" {
  bucket = "${var.vpc_name}-data-bucket-with-versioning"

  tags = {
    Name        = "${var.vpc_name}-data-bucket-with-versioning"
    Environment = "${var.environment}"
    Purpose     = "${var.purpose}"
  }

}

#------------ ENCRYPT
resource "aws_s3_bucket_server_side_encryption_configuration" "encrypt" {
  bucket = aws_s3_bucket.data_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

#------------ ACL
resource "aws_s3_bucket_acl" "data_bucket_acl" {
  bucket = aws_s3_bucket.data_bucket.id
  acl    = "private"
}

#------------ VERSIONING
resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.data_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# - SET NONCURRENT VERSIONS OF MATCH CONDITIONS FILE TO EXPIRE 
resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecycle_versioned" {
  depends_on = [aws_s3_bucket_versioning.bucket_versioning]
  bucket     = aws_s3_bucket.data_bucket.bucket
  rule {
    id = "data_bucket_expiration"
    filter {
      # empty filter applies lifecycle config to all objects in the bucket
      prefix = "${var.bucket_lifecycle_filter_prefix}" #EMPTY FILTER APPLIES LIFECYCLE CONFIG TO ALL OBJECTS IN THE BUCKET
    }
    noncurrent_version_expiration {
      noncurrent_days = "${var.nonconcurrent_version_expiration}"
    }
    status = "Enabled"
  }
}


#------------- LOGGING
resource "aws_s3_bucket" "log_bucket" {
  bucket = "${var.vpc_name}-data-bucket-with-versioning-log"
  tags = {
    Purpose = "data release s3 bucket log bucket"
  }
}

resource "aws_s3_bucket_acl" "log_bucket_acl" {
  bucket = aws_s3_bucket.log_bucket.id
  acl    = "log-delivery-write"
}

resource "aws_s3_bucket_logging" "bucket_logging" {
  bucket        = aws_s3_bucket.data_bucket.id
  target_bucket = aws_s3_bucket.log_bucket.id
  target_prefix = "log/"
}

#------------ RESTRICT PUBLIC ACCESS
resource "aws_s3_bucket_public_access_block" "data_bucket_privacy" {
  bucket = aws_s3_bucket.data_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
