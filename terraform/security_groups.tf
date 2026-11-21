# Security Group for Codevern Cloud PC GPU Workstation
# Per PRD Section 9: "No publicly exposed RDP access without appropriate restrictions"
# Remote administration is secured via AWS SSM Session Manager (zero open inbound ports required)
resource "aws_security_group" "cloud_pc_sg" {
  name        = "codevern-cloudpc-sg-${var.environment}"
  description = "Security group for Sunshine streaming and secured Cloud PC access"
  vpc_id      = aws_vpc.main.id

  # Sunshine Web Configuration UI (HTTPS)
  ingress {
    description = "Sunshine Web Management UI"
    from_port   = 47990
    to_port     = 47990
    protocol    = "tcp"
    cidr_blocks = [var.allowed_client_cidr]
  }

  # Sunshine Pairing & Control Protocols (TCP)
  ingress {
    description = "Sunshine Moonlight Pairing & Control TCP"
    from_port   = 47984
    to_port     = 47984
    protocol    = "tcp"
    cidr_blocks = [var.allowed_client_cidr]
  }

  ingress {
    description = "Sunshine Moonlight Control TCP"
    from_port   = 47989
    to_port     = 47989
    protocol    = "tcp"
    cidr_blocks = [var.allowed_client_cidr]
  }

  ingress {
    description = "Sunshine Moonlight RTSP TCP"
    from_port   = 48010
    to_port     = 48010
    protocol    = "tcp"
    cidr_blocks = [var.allowed_client_cidr]
  }

  # Sunshine Streaming Data Channels (UDP: Video, Audio, Control, Ping)
  ingress {
    description = "Sunshine Moonlight Video/Audio/Control UDP Stream"
    from_port   = 47998
    to_port     = 48002
    protocol    = "udp"
    cidr_blocks = [var.allowed_client_cidr]
  }

  ingress {
    description = "Sunshine Moonlight RTSP UDP"
    from_port   = 48010
    to_port     = 48010
    protocol    = "udp"
    cidr_blocks = [var.allowed_client_cidr]
  }

  # Optional NICE DCV port (PRD Section 5.6 alternative)
  ingress {
    description = "NICE DCV Streaming Protocol (Optional Fallback)"
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = [var.allowed_client_cidr]
  }

  ingress {
    description = "NICE DCV QUIC Protocol (Optional Fallback)"
    from_port   = 8443
    to_port     = 8443
    protocol    = "udp"
    cidr_blocks = [var.allowed_client_cidr]
  }

  # All outbound traffic allowed (updates, drivers, downloads, AWS APIs)
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "codevern-cloudpc-sg-${var.environment}"
  }
}
