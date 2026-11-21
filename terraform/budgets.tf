# AWS Budget to enforce PRD Section 4 & 8: Hard monthly limit of ₹6,000 (~$70 USD)
resource "aws_budgets_budget" "cloud_pc_budget" {
  name              = "codevern-cloudpc-budget-${var.environment}"
  budget_type       = "COST"
  limit_amount      = tostring(var.monthly_budget_usd)
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2026-01-01_00:00"

  cost_filter {
    name = "TagKeyValue"
    values = [
      "user:Project$Codevern-Cloud-PC"
    ]
  }

  # 50% Threshold Notification (Early Warning: ~$35 USD / ₹3,000 INR)
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 50
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.notification_email]
    subscriber_sns_topic_arns  = [aws_sns_topic.cloud_pc_alerts.arn]
  }

  # 80% Threshold Notification (Urgent Warning: ~$56 USD / ₹4,800 INR)
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.notification_email]
    subscriber_sns_topic_arns  = [aws_sns_topic.cloud_pc_alerts.arn]
  }

  # 100% Forecasted Threshold Notification (Capped Limit: ~$70 USD / ₹6,000 INR)
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "FORECASTED"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.notification_email]
    subscriber_sns_topic_arns  = [aws_sns_topic.cloud_pc_alerts.arn]
  }
}
