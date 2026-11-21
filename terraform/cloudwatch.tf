# CloudWatch Alarm for Automated Idle Shutdown
# If average CPU utilization stays below 3% for 2 consecutive 5-minute periods (10 mins),
# automatically stop the EC2 instance to prevent unnecessary compute charges.
resource "aws_cloudwatch_metric_alarm" "idle_shutdown_alarm" {
  alarm_name          = "codevern-cloudpc-idle-shutdown-${var.environment}"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300 # 5 minutes per period
  statistic           = "Average"
  threshold           = 3   # 3% CPU utilization
  alarm_description   = "Stops Codevern Cloud PC when idle to enforce monthly budget constraints"

  dimensions = {
    InstanceId = aws_instance.cloud_pc.id
  }

  alarm_actions = [
    "arn:aws:automate:${var.aws_region}:ec2:stop",
    aws_sns_topic.cloud_pc_alerts.arn
  ]
}

# SNS Topic for Infrastructure and Cost Alerts
resource "aws_sns_topic" "cloud_pc_alerts" {
  name = "codevern-cloudpc-alerts-${var.environment}"
}

# Email subscription for admin notifications
resource "aws_sns_topic_subscription" "email_alerts" {
  topic_arn = aws_sns_topic.cloud_pc_alerts.arn
  protocol  = "email"
  endpoint  = var.notification_email
}
