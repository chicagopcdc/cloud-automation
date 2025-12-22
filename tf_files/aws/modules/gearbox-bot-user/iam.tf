

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



## FOR STAGING ACCOUNT TO PUSH TO PROD
# START

### later terraform version
#resource "aws_iam_policy" "allow_assume_prod_role" {
#  count = var.is_gearbox_staging ? 1 : 0
#
#  name = "${var.vpc_name}-allow-assume-prod-promotion-role"
#
#  policy = jsonencode({
#    Version = "2012-10-17",
#    Statement = [
#      {
#        Effect   = "Allow",
#        Action   = "sts:AssumeRole",
#        Resource = var.prod_promotion_role_arn
#      }
#    ]
#  })
#}
#
#resource "aws_iam_user_policy_attachment" "gearbox_bot_assume_prod" {
#  count = var.is_gearbox_staging ? 1 : 0
#
#  user       = aws_iam_user.gearbox-bot.name
#  policy_arn = aws_iam_policy.allow_assume_prod_role[0].arn
#}


resource "aws_iam_policy" "allow_assume_prod_role" {
  count = "${var.is_gearbox_staging ? 1 : 0}"

  name = "${var.vpc_name}-allow-assume-prod-promotion-role"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "${var.prod_promotion_role_arn}"
    }
  ]
}
POLICY
}

resource "aws_iam_user_policy_attachment" "gearbox_bot_assume_prod" {
  count = "${var.is_gearbox_staging ? 1 : 0}"

  user       = "${aws_iam_user.gearbox-bot.name}"
  policy_arn = "${aws_iam_policy.allow_assume_prod_role[0].arn}"
}

# END







### FOR PROD account to allow staging to get access to the role
# START

### later terraform version
#resource "aws_iam_role" "staging_promotion_role" {
#  count = var.is_gearbox_prod ? 1 : 0
#
#  name = "${var.vpc_name}-staging-promote-to-prod-role"
#
#  assume_role_policy = jsonencode({
#    Version = "2012-10-17"
#    Statement = [
#      {
#        Effect = "Allow"
#        Principal = {
#          AWS = "arn:aws:iam::${var.staging_account_id}:root"
#        }
#        Action = "sts:AssumeRole"
#      }
#    ]
#  })
#}
#
#resource "aws_iam_policy" "staging_promotion_policy" {
#  count = var.is_gearbox_prod ? 1 : 0
#
#  name = "${var.vpc_name}-staging-promote-to-prod-policy"
#
#  policy = jsonencode({
#    Version = "2012-10-17"
#    Statement = [
#      {
#        Effect = "Allow"
#        Action = [
#          "s3:ListBucket"
#        ]
#        Resource = "arn:aws:s3:::${var.bucket_name}"
#      },
#      {
#        Effect = "Allow"
#        Action = [
#          "s3:GetObject",
#          "s3:GetObjectVersion",
#          "s3:PutObject",
#          "s3:DeleteObject"
#        ]
#        Resource = "arn:aws:s3:::${var.bucket_name}/*"
#      }
#    ]
#  })
#}
#
#resource "aws_iam_role_policy_attachment" "attach_promote_policy" {
#  count = var.is_gearbox_prod ? 1 : 0
#
#  role       = aws_iam_role.staging_promotion_role[0].name
#  policy_arn = aws_iam_policy.staging_promotion_policy[0].arn
#}
*/

resource "aws_iam_role" "staging_promotion_role" {
  count = "${var.is_gearbox_prod ? 1 : 0}"

  name = "${var.vpc_name}-staging-promote-to-prod-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${var.staging_account_id}:root"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_policy" "staging_promotion_policy" {
  count = "${var.is_gearbox_prod ? 1 : 0}"

  name = "${var.vpc_name}-staging-promote-to-prod-policy"

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:ListBucket"],
      "Resource": "arn:aws:s3:::${var.bucket_name}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:PutObject",
        "s3:DeleteObject"
      ],
      "Resource": "arn:aws:s3:::${var.bucket_name}/*"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "attach_promote_policy" {
  count = "${var.is_gearbox_prod ? 1 : 0}"

  role       = "${aws_iam_role.staging_promotion_role[0].name}"
  policy_arn = "${aws_iam_policy.staging_promotion_policy[0].arn}"
}

# END


