

# Gearbox bot

## Gearbox bot user
resource "aws_iam_user" "gearbox-bot" {
  name = "${var.vpc_name}_gearbox-bot"
}

## Gearbox bot key/secret
resource "aws_iam_access_key" "gearbox-bot_user_key" {
  user = "${aws_iam_user.gearbox-bot.name}"
}

## Gearbox bot access policy
resource "aws_iam_user_policy" "gearbox-bot_policy" {
  name = "${var.vpc_name}_gearbox-bot_policy"
  user = "${aws_iam_user.gearbox-bot.name}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:PutObject",
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": ["${data.aws_s3_bucket.data-bucket.arn}/*"]
    },
    {
       "Action": [
         "s3:List*",
         "s3:Get*"
       ],
      "Effect": "Allow",
      "Resource": ["${data.aws_s3_bucket.data-bucket.arn}/*", "${data.aws_s3_bucket.data-bucket.arn}"]
    }
  ]
}
EOF


  lifecycle {
    ignore_changes = ["policy"]
  }

}

resource "aws_iam_user_policy" "gearbox-bot_extra_policy" {
  count = "${length(var.bucket_access_arns)}"
  name  = "${var.vpc_name}_gearbox-bot_policy_${count.index}"
  user  = "${aws_iam_user.gearbox-bot.name}"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:PutObject",
        "s3:GetObject"
      ],
      "Effect": "Allow",
      "Resource": ["${var.bucket_access_arns[count.index]}/*"]
    },
    {
       "Action": [
         "s3:List*",
         "s3:Get*"
       ],
      "Effect": "Allow",
      "Resource": ["${var.bucket_access_arns[count.index]}/*", "${var.bucket_access_arns[count.index]}"]
    }
  ]
}
EOF
}


resource "aws_iam_policy" "allow_assume_prod_role" {
  count = var.prod_promotion_role_arn == null ? 0 : 1

  name = "${var.vpc_name}-allow-assume-prod-promotion-role"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "sts:AssumeRole",
        Resource = var.prod_promotion_role_arn
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "gearbox_bot_assume_prod" {
  count = var.prod_promotion_role_arn == null ? 0 : 1

  user       = aws_iam_user.gearbox-bot.name
  policy_arn = aws_iam_policy.allow_assume_prod_role[0].arn
}




