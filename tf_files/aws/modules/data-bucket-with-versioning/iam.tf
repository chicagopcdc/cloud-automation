
## Role and Policies for the bucket

resource "aws_iam_role" "data_bucket" {
  name = "${var.vpc_name}-data-bucket-with-versioning-access"
  path = "/"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": "sts:AssumeRole",
            "Principal": {
               "Service": "ec2.amazonaws.com"
            },
            "Effect": "Allow",
            "Sid": ""
        }
    ]
}
EOF
}


## Policies data 

data "aws_iam_policy_document" "data_bucket_with_versioning_reader" {
  statement {
    actions = [
      "s3:Get*",
      "s3:List*"
    ]

    effect    = "Allow"
    resources = ["${aws_s3_bucket.data_bucket.arn}", "${aws_s3_bucket.data_bucket.arn}/*"]
  }
}

data "aws_iam_policy_document" "data_bucket_with_versioning_writer" {
  statement {
    actions = [
      "s3:PutObject"
    ]

    effect    = "Allow"
    resources = ["${aws_s3_bucket.data_bucket.arn}", "${aws_s3_bucket.data_bucket.arn}/*"]
  }
}



## Policies

resource "aws_iam_policy" "data_bucket_with_versioning_reader" {
  name        = "data_bucket_with_versioning_read_${var.vpc_name}"
  description = "Data Bucket access for ${var.vpc_name}"
  policy      = "${data.aws_iam_policy_document.data_bucket_with_versioning_reader.json}"
}

resource "aws_iam_policy" "data_bucket_with_versioning_writer" {
  name        = "data_bucket_with_versioning_write_${var.vpc_name}"
  description = "Data Bucket access for ${var.vpc_name}"
  policy      = "${data.aws_iam_policy_document.data_bucket_with_versioning_writer.json}"
}



## Policies attached to roles

resource "aws_iam_role_policy_attachment" "data_bucket_with_versioning_reader" {
  role       = "${aws_iam_role.data_bucket.name}"
  policy_arn = "${aws_iam_policy.data_bucket_with_versioning_reader.arn}"
}

resource "aws_iam_role_policy_attachment" "data_bucket_with_versioning_writer" {
  role       = "${aws_iam_role.data_bucket.name}"
  policy_arn = "${aws_iam_policy.data_bucket_with_versioning_writer.arn}"
}


