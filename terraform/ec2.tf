# Look up official Windows Server 2022 Datacenter AMI
data "aws_ami" "windows_server_2022" {
  most_recent = true
  owners      = ["80111966130"] # Amazon official owner ID

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Look up official Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu_2204" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  selected_ami = var.custom_ami_id != "" ? var.custom_ami_id : (
    var.os_type == "windows" ? data.aws_ami.windows_server_2022.id : data.aws_ami.ubuntu_2204.id
  )

  user_data_script = var.os_type == "windows" ? templatefile("${path.module}/../scripts/windows/bootstrap.ps1", {
    idle_timeout = var.idle_timeout_minutes
  }) : templatefile("${path.module}/../scripts/linux/bootstrap.sh", {
    idle_timeout = var.idle_timeout_minutes
  })
}

# Primary GPU Compute Instance (g4dn.xlarge: 4 vCPU, 16 GB RAM, NVIDIA T4)
resource "aws_instance" "cloud_pc" {
  ami                  = local.selected_ami
  instance_type        = var.instance_type
  subnet_id            = aws_subnet.public.id
  iam_instance_profile = aws_iam_instance_profile.cloud_pc_profile.name

  vpc_security_group_ids = [aws_security_group.cloud_pc_sg.id]

  # Root Volume (OS & Core Runtimes)
  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    iops                  = 3000
    throughput            = 125
    encrypted             = true
    delete_on_termination = false # Protects operating system drive from accidental loss

    tags = {
      Name = "codevern-cloudpc-root-volume-${var.environment}"
    }
  }

  user_data = local.user_data_script

  # Optional Spot Instance configuration to drastically reduce hourly compute costs
  dynamic "instance_market_options" {
    for_each = var.use_spot_instance ? [1] : []
    content {
      market_type = "spot"
      spot_options {
        max_price          = null # Market price
        spot_instance_type = "persistent"
        instance_interruption_behavior = "stop"
      }
    }
  }

  tags = {
    Name        = "codevern-cloudpc-${var.environment}"
    OS          = var.os_type
    GPU         = "NVIDIA-T4"
    AutoStop    = "true"
  }
}

# Dedicated Persistent Data EBS gp3 Volume (Total Storage Target = 500 GB)
# Managed as an independent volume so user games/data survive any instance lifecycle changes
resource "aws_ebs_volume" "cloud_pc_data" {
  availability_zone = aws_subnet.public.availability_zone
  size              = var.data_volume_size
  type              = "gp3"
  iops              = 3000
  throughput        = 125
  encrypted         = true

  tags = {
    Name = "codevern-cloudpc-data-volume-${var.environment}"
  }
}

# Attach persistent data volume to the instance
resource "aws_volume_attachment" "cloud_pc_data_attach" {
  device_name = var.os_type == "windows" ? "xvdf" : "/dev/sdf"
  volume_id   = aws_ebs_volume.cloud_pc_data.id
  instance_id = aws_instance.cloud_pc.id
}
