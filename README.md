# Codevern Cloud PC

> **Cloud-Based Virtual Desktop & Gaming Workstation**  
> Built for Codevern Private Limited | PRD Version 1.0

[![Infrastructure](https://img.shields.io/badge/IaC-Terraform-623CE4.svg)](https://www.terraform.io/)
[![Cloud Provider](https://img.shields.io/badge/Cloud-AWS%20(ap--south--1)-FF9900.svg)](https://aws.amazon.com/)
[![GPU](https://img.shields.io/badge/GPU-NVIDIA%20T4%20(16GB)-76B900.svg)](https://www.nvidia.com/en-us/data-center/tesla-t4/)
[![Streaming](https://img.shields.io/badge/Streaming-Sunshine%20%2B%20Moonlight-blue.svg)](https://moonlight-stream.org/)
[![Monthly Budget](https://img.shields.io/badge/Budget-₹6%2C000%20Limit-success.svg)](#cost-optimization--budget-control)

---

## 1. Overview

**Codevern Cloud PC** provides a powerful, cloud-hosted Windows Server or Ubuntu desktop accessible from low-specification laptops, desktops, or mobile devices. Powered by an AWS EC2 `g4dn.xlarge` instance featuring an **NVIDIA T4 GPU**, the platform allows developers, interns, and gamers to execute heavy compilation, 3D rendering, and PC gaming (including GTA V) with interactive sub-25ms latency.

### Key Capabilities
* **GPU-Accelerated Interactive Desktop:** Ultra-low-latency 60 FPS streaming powered by **Sunshine** (host) and **Moonlight** (client) using hardware NVENC encoding.
* **Strict Cost Governance:** Automated in-guest inactivity detection daemon and CloudWatch alarms shut down instances after 15 minutes of idle time to stay within the **₹6,000 INR (~$70 USD) monthly budget constraint**.
* **Zero-Open-RDP Security:** Elimination of open public RDP (3389) and SSH (22) ports; out-of-band administration is secured via **AWS Systems Manager (SSM) Session Manager**.
* **500 GB Persistent Storage:** Modular EBS `gp3` storage with independent secondary disk safeguarding code and game assets across power cycles.
* **Full Developer & Gaming Suite:** Automated provisioning of VS Code, Git, Python 3, Node.js, OpenJDK 17, Google Chrome, LibreOffice, Steam, Epic Games, and DirectX runtimes.

---

## 2. Repository Layout

```
cloud-pc/
├── README.md                                # Project overview, quick start, prerequisites
├── terraform/                               # Infrastructure as Code (Terraform)
│   ├── main.tf                              # AWS Provider configuration (ap-south-1 Mumbai)
│   ├── variables.tf                         # Tunable parameters (region, budget, storage)
│   ├── vpc.tf                               # Isolated VPC, Subnet, and Internet Gateway
│   ├── security_groups.tf                   # Restricted Sunshine rules; zero open RDP/SSH
│   ├── iam.tf                               # Least-privilege IAM roles (SSM, CloudWatch, S3)
│   ├── ec2.tf                               # g4dn.xlarge instance, Spot toggle, 500GB EBS
│   ├── cloudwatch.tf                        # Low-CPU auto-stop alarm & SNS notifications
│   ├── budgets.tf                           # AWS Budget resource ($70 limit, threshold alerts)
│   ├── outputs.tf                           # Public IP, Sunshine URLs, and SSM commands
│   └── terraform.tfvars.example             # Sample environment variables
├── scripts/                                 # In-Guest Automated Provisioning
│   ├── windows/
│   │   ├── bootstrap.ps1                    # Master UserData initialization script
│   │   ├── install-nvidia-grid.ps1          # NVIDIA GRID Cloud Gaming driver installer
│   │   ├── install-virtual-display.ps1      # Headless IddSampleDriver virtual monitor
│   │   ├── configure-audio.ps1              # Windows Audio Service & VB-Cable loopback
│   │   ├── install-sunshine.ps1             # Sunshine host service & NVENC configuration
│   │   ├── install-devtools.ps1             # Developer toolchain & gaming launchers
│   │   └── idle-shutdown-daemon.ps1         # Real-time keyboard/mouse/GPU inactivity monitor
│   └── linux/
│       ├── bootstrap.sh                     # Ubuntu setup (XFCE, NVIDIA, Sunshine, Dev tools)
├── cost/                                    # Financial Modeling & Simulator
│   ├── cost_calculator.py                   # Python CLI tool to simulate usage scenarios
│   └── cost_breakdown.json                  # Granular AWS ap-south-1 pricing dataset
└── docs/                                    # Comprehensive Technical Documentation
    ├── ARCHITECTURE.md                      # Network topology, streaming protocols, data flow
    ├── COST_ANALYSIS.md                     # Detailed financial analysis, ₹6,000 budget plans
    ├── REMOTE_ACCESS_GUIDE.md               # Step-by-step Moonlight client pairing guide
    ├── SECURITY_CONFIG.md                   # Threat model, IAM policies, and hardening
    ├── PRD_MAPPING.md                       # Full mapping of all 16 PRD v1.0 sections
    └── TESTING_REPORT_TEMPLATE.md           # 14 functional test cases & benchmark template
```

---

## 3. Quick Start Deployment

### Prerequisites
1. [AWS CLI](https://aws.amazon.com/cli/) installed and configured with credentials:
   ```bash
   aws configure
   ```
2. [Terraform](https://www.terraform.io/downloads) (>= 1.5.0) installed.
3. [Moonlight Client](https://moonlight-stream.org/) installed on your local laptop, desktop, or mobile device.

### Step 1: Configure Variables
```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
```
Edit `terraform.tfvars`:
```hcl
aws_region          = "ap-south-1"           # Mumbai region
os_type             = "windows"              # "windows" or "ubuntu"
notification_email  = "intern@codevern.com"  # Your email for budget alerts
allowed_client_cidr = "203.0.113.50/32"      # (Optional) Restrict to your home/office IP
use_spot_instance   = false                  # Set to true for 60%+ compute savings
```

### Step 2: Deploy Infrastructure
```bash
terraform init
terraform plan
terraform apply
```

### Step 3: Connect via Moonlight
1. Open your browser and navigate to the Sunshine Web Portal:
   ```
   https://<PUBLIC_IP>:47990
   ```
2. Set your admin credentials, open Moonlight on your client device, add the host IP, and enter the displayed 4-digit PIN in the Sunshine web interface.
3. Launch your 60 FPS remote desktop session!
4. *(Detailed connection instructions: see [Remote Access Guide](docs/REMOTE_ACCESS_GUIDE.md))*

---

## 4. Cost Simulation & Modeling Tool

To simulate monthly costs and determine safe operating hours under the ₹6,000 INR limit:

```bash
# Simulate 1 hour per day on Windows On-Demand with 500GB storage:
python cost/cost_calculator.py --hours 1.0 --storage 500 --os windows

# Simulate 2 hours per day on Windows Spot with 150GB tiered storage:
python cost/cost_calculator.py --hours 2.0 --storage 150 --spot --os windows

# Simulate Linux developer workload:
python cost/cost_calculator.py --hours 1.5 --os ubuntu
```

---

## 5. Documentation Directory

* [**Architecture & Protocol Design**](docs/ARCHITECTURE.md): Network flow, GPU pipeline, Sunshine vs NICE DCV comparison.
* [**Financial & Cost Analysis**](docs/COST_ANALYSIS.md): Mumbai pricing breakdown, EBS storage trade-offs, operating schedules.
* [**Remote Access Guide**](docs/REMOTE_ACCESS_GUIDE.md): Client setup for Windows, macOS, Android, iOS, and AWS SSM access.
* [**Security Architecture**](docs/SECURITY_CONFIG.md): Zero-port perimeter, least-privilege IAM, volume encryption.
* [**PRD Implementation Mapping**](docs/PRD_MAPPING.md): Traceability matrix confirming 100% compliance with PRD v1.0.
* [**Testing & Acceptance Runbook**](docs/TESTING_REPORT_TEMPLATE.md): 14 test protocols and performance benchmarks.

---

## 6. License & Ownership

Confidential • Project Deliverable for **Codevern Private Limited**.  
Developed by Codevern Engineering Team.
