# IAM Role for Codevern Cloud PC Instance
# Provides AWS Systems Manager (SSM) access, CloudWatch metrics, and S3 driver access
resource "aws_iam_role" "cloud_pc_role" {
  name = "codevern-cloudpc-instance-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "codevern-cloudpc-role-${var.environment}"
  }
}

# Attach AWS Systems Manager Core policy for secure agent-based shell access
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.cloud_pc_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach CloudWatch Agent policy for RAM, GPU, and disk metrics telemetry
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.cloud_pc_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Custom Least-Privilege Policy: S3 NVIDIA Driver Access & Self Stop capability
resource "aws_iam_policy" "cloud_pc_custom" {
  name        = "codevern-cloudpc-custom-policy-${var.environment}"
  description = "Allows access to AWS NVIDIA driver S3 bucket and EC2 status checks"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "AllowNvidiaDriverS3Download"
        Effect   = "Allow"
        Action   = [
          "s3:GetObject"
        ]
        Resource = [
          "arn:aws:s3:::ec2-windows-nvidia-drivers/*",
          "arn:aws:s3:::ec2-linux-nvidia-drivers/*"
        ]
      },
      {
        Sid      = "AllowEC2SelfStopAndDescribe"
        Effect   = "Allow"
        Action   = [
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceStatus"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "custom_attach" {
  role       = aws_iam_role.cloud_pc_role.name
  policy_arn = aws_iam_policy.cloud_pc_custom.arn
}

# EC2 Instance Profile
resource "aws_iam_instance_profile" "cloud_pc_profile" {
  name = "codevern-cloudpc-profile-${var.environment}"
  role = aws_iam_role.cloud_pc_role.name
}
