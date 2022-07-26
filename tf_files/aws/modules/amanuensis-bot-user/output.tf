
output "amanuensis-bot_secret" {
  value = "${aws_iam_access_key.amanuensis-bot_user_key.secret}"
}

output "amanuensis-bot_id" {
  value = "${aws_iam_access_key.amanuensis-bot_user_key.id}"
}

