
output "gearbox-bot_secret" {
  value = "${aws_iam_access_key.gearbox-bot_user_key.secret}"
}

output "gearbox-bot_id" {
  value = "${aws_iam_access_key.gearbox-bot_user_key.id}"
}

output "prod_promotion_role_arn" {
  value = var.is_gearbox_prod ? aws_iam_role.staging_promotion_role[0].arn : ""
  description = "ARN of the staging promotion role, empty if not created"
}