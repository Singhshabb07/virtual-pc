output "instance_id" {
  description = "EC2 Instance ID of Codevern Cloud PC"
  value       = aws_instance.cloud_pc.id
}

output "public_ip" {
  description = "Public IP address of Codevern Cloud PC"
  value       = aws_instance.cloud_pc.public_ip
}

output "sunshine_web_ui" {
  description = "Direct URL to Sunshine Web Management and Pairing Portal (HTTPS)"
  value       = "https://${aws_instance.cloud_pc.public_ip}:47990"
}

output "ssm_connect_command" {
  description = "Secure zero-open-port CLI connection command using AWS Systems Manager"
  value       = "aws ssm start-session --target ${aws_instance.cloud_pc.id} --region ${var.aws_region}"
}

output "storage_configuration" {
  description = "Persistent storage breakdown (Total 500 GB target)"
  value = {
    root_volume_id = aws_instance.cloud_pc.root_block_device[0].volume_id
    root_size_gb   = var.root_volume_size
    data_volume_id = aws_ebs_volume.cloud_pc_data.id
    data_size_gb   = var.data_volume_size
    total_size_gb  = var.root_volume_size + var.data_volume_size
  }
}

output "cost_budget_info" {
  description = "Monthly budget and cost control guidelines"
  value = {
    monthly_budget_usd       = var.monthly_budget_usd
    approx_inr_equivalent    = "₹${var.monthly_budget_usd * 85}"
    storage_cost_approx_usd  = "$48.00 / month (500 GB gp3)"
    compute_budget_left_usd  = "$${var.monthly_budget_usd - 48.00} / month"
    recommended_idle_timeout = "${var.idle_timeout_minutes} minutes"
  }
}
