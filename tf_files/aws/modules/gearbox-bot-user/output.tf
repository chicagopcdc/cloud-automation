
output "gearbox-bot_secret" {
  value = "${aws_iam_access_key.gearbox-bot_user_key.secret}"
}

output "gearbox-bot_id" {
  value = "${aws_iam_access_key.gearbox-bot_user_key.id}"
}

