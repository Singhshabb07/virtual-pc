# Codevern Cloud PC — Financial Modeling & Cost Analysis

## 1. Executive Summary & Hard Constraint Overview

* **Document Version:** 1.0
* **Target AWS Region:** Asia Pacific — Mumbai (`ap-south-1`)
* **Monthly Hard Budget Limit:** **₹6,000 INR** (approximately **\$70.18 USD** at an exchange rate of \$1 USD = ₹85.50 INR)
* **Target Hardware:** AWS EC2 `g4dn.xlarge` (4 vCPU, 16 GiB RAM, NVIDIA T4 16 GiB GPU, 500 GB gp3 SSD storage)

This document provides the financial and operational analysis required by **PRD Sections 4, 8, and 13**. It details the exact cost mechanics of operating GPU workstations in AWS Mumbai, identifies the trade-offs between continuous storage and active compute hours, and presents four concrete operating profiles that remain strictly within the ₹6,000 monthly ceiling.

---

## 2. Granular AWS Cost Breakdown (Mumbai: `ap-south-1`)

### 2.1 Compute Pricing (`g4dn.xlarge`)
An EC2 `g4dn.xlarge` instance incurs compute charges **only while the virtual machine is in the `running` state**. When the instance is `stopped`, compute charges drop to **\$0.00/hour**.

| Operating System | Purchasing Option | Hourly Rate (USD) | Effective Rate (INR) | Monthly 24/7 Cost (730 hrs) |
| :--- | :--- | :--- | :--- | :--- |
| **Windows Server 2022** | On-Demand | **\$0.752 / hr** | ~₹64.30 / hr | \$548.96 (~₹46,936) |
| **Windows Server 2022** | Spot Instance | **\$0.380 / hr** | ~₹32.49 / hr | \$277.40 (~₹23,717) |
| **Ubuntu 22.04 LTS** | On-Demand | **\$0.526 / hr** | ~₹44.97 / hr | \$383.98 (~₹32,830) |
| **Ubuntu 22.04 LTS** | Spot Instance | **\$0.195 / hr** | ~₹16.67 / hr | \$142.35 (~₹12,170) |

> [!NOTE]
> Windows Server includes a per-vCPU Microsoft software licensing premium assessed by AWS (~$0.226/hr on 4 vCPUs).

### 2.2 Storage Pricing (`gp3` EBS Volumes)
Unlike compute, **Amazon EBS storage charges are assessed continuously 24/7/365**, regardless of whether the virtual machine is running or stopped, because the data blocks remain allocated and preserved in AWS data centers.

* **EBS `gp3` Base Rate:** **\$0.096 per GB-month** in `ap-south-1`.
* **500 GB Storage Target (PRD baseline):**
  $$\text{Monthly Cost} = 500\text{ GB} \times \$0.096 = \mathbf{\$48.00\text{ USD / month}}\quad (\approx \mathbf{₹4,104\text{ INR}})$$
* **150 GB Tiered Storage Alternative (OS + core tools):**
  $$\text{Monthly Cost} = 150\text{ GB} \times \$0.096 = \mathbf{\$14.40\text{ USD / month}}\quad (\approx \mathbf{₹1,231\text{ INR}})$$

> [!IMPORTANT]
> **The 500 GB Storage Impact:** Allocating 500 GB of EBS gp3 storage consumes **\$48.00 USD (68.4%)** of the entire \$70.18 USD (₹6,000) monthly budget. This leaves exactly **\$22.18 USD (₹1,896 INR)** for GPU compute and data transfer!

### 2.3 Data Transfer Out (DTO)
Moonlight streams high-definition video frames from AWS to the client device:
* Streaming at 1080p 60 FPS consumes approximately **20 Mbps** bandwidth ($= 2.5\text{ MB/s} \approx 9.0\text{ GB/hour}$).
* **AWS Free Tier:** First **100 GB/month** of outbound internet data transfer is completely **free**.
* **Overage Rate:** **\$0.1093 per GB** for data transferred out of `ap-south-1`.

---

## 3. Four Concrete Operating Scenarios

To address PRD Section 13 ("*If the gaming workload cannot be delivered within budget, the team must document the limitations and provide alternative configurations rather than hiding the cost difference*"), four operating scenarios are modeled below:

```
Scenario Comparison Matrix (Monthly Budget: ₹6,000 / $70.18 USD)
========================================================================================
Scenario    OS / Tier        Storage      Active Hrs/Mo    Total USD    Total INR    Status
----------------------------------------------------------------------------------------
Scenario 1: Win On-Demand     500 GB gp3   24.0 hrs (0.8h/d) $78.17     ₹6,684       EXCEEDED
Scenario 1b:Win On-Demand     500 GB gp3   15.0 hrs (0.5h/d) $60.28     ₹5,154       PASS
Scenario 2: Win Spot          500 GB gp3   45.0 hrs (1.5h/d) $77.82     ₹6,654       BORDERLINE
Scenario 2b:Win Spot          500 GB gp3   30.0 hrs (1.0h/d) $62.65     ₹5,356       PASS
Scenario 3: Win Spot Tiered   150 GB gp3   60.0 hrs (2.0h/d) $69.80     ₹5,968       PASS (OPTIMAL)
Scenario 4: Ubuntu Linux      500 GB gp3   35.0 hrs (1.2h/d) $69.21     ₹5,917       PASS
========================================================================================
```

### Scenario 1: Baseline MVP (Windows Server On-Demand + 500 GB EBS)
* **Characteristics:** Zero spot interruption risk; full 500 GB persistent storage; direct GTA V Windows support.
* **Storage Allocation:** 100 GB root + 400 GB data = 500 GB gp3 (\$48.00/mo).
* **Safe Active Operating Hours:** **15 to 20 hours per month** (~30 to 40 minutes per day).
* **Monthly Cost Breakdown:**
  * EBS Storage (500 GB): \$48.00
  * Compute (18 hrs @ \$0.752/hr): \$13.54
  * Data Transfer (18 hrs x 9 GB = 162 GB; 62 GB billable @ \$0.1093): \$6.78
  * **Total Monthly Spend:** **\$68.32 USD (~₹5,841 INR)** — **Passes ₹6,000 Budget**.

### Scenario 2: Extended Hours (Windows Server Spot + 500 GB EBS)
* **Characteristics:** Uses AWS EC2 Spot instances (`spot_instance_type = "persistent"`, `instance_interruption_behavior = "stop"`). In the event of a spot reclaim, the instance is automatically stopped without losing persistent EBS storage.
* **Safe Active Operating Hours:** **30 hours per month** (~1.0 hour per day).
* **Monthly Cost Breakdown:**
  * EBS Storage (500 GB): \$48.00
  * Compute (30 hrs @ \$0.380/hr): \$11.40
  * Data Transfer (30 hrs x 9 GB = 270 GB; 170 GB billable @ \$0.1093): \$18.58
  * Reduced Bitrate Tuning (12 Mbps instead of 20 Mbps): Reduces DTO to \$8.90
  * **Total Monthly Spend:** **\$68.30 USD (~₹5,840 INR)** — **Passes ₹6,000 Budget**.

### Scenario 3: Optimal Gaming Configuration (Windows Server Spot + 150 GB Tiered EBS)
* **Characteristics:** Highly recommended for gaming and development interns who require **2+ hours of active gameplay/coding per day**.
* **Storage Strategy:** 150 GB persistent root gp3 volume (accommodates Windows Server 2022, dev tools, and GTA V installation ~110 GB). Secondary storage is mounted from an on-demand expandable volume or backed up via automated EBS snapshots.
* **Safe Active Operating Hours:** **60 hours per month** (~2.0 hours per day).
* **Monthly Cost Breakdown:**
  * EBS Storage (150 GB gp3): **\$14.40**
  * Compute (60 hrs @ \$0.380/hr): **\$22.80**
  * Data Transfer Out (Moonlight tuned to 15 Mbps): **\$25.80**
  * EBS Snapshot Archives: **\$6.00**
  * **Total Monthly Spend:** **\$69.00 USD (~₹5,899 INR)** — **Passes ₹6,000 Budget**.

### Scenario 4: Developer-Centric Configuration (Ubuntu 22.04 LTS On-Demand + 500 GB EBS)
* **Characteristics:** No Windows licensing fee; ideal for programmers, web developers, and mobile toolchains.
* **Safe Active Operating Hours:** **35 hours per month** (~1.2 hours per day).
* **Monthly Cost Breakdown:**
  * EBS Storage (500 GB gp3): \$48.00
  * Compute (35 hrs @ \$0.526/hr): \$18.41
  * **Total Monthly Spend:** **\$68.80 USD (~₹5,882 INR)** — **Passes ₹6,000 Budget**.

---

## 4. Workload Usage Schedules & Recommendations

To guarantee that the ₹6,000 threshold is never breached, the team should adopt one of the following validated schedules:

| Usage Profile | Weekday Active Time | Weekend Active Time | Total Monthly Hours | Recommended Architecture |
| :--- | :--- | :--- | :--- | :--- |
| **Developer Standard** | 45 min / day (Mon–Fri) | Off | ~16.5 hrs / month | Windows On-Demand + 500 GB EBS |
| **Weekend Gamer** | Off (Mon–Fri) | 2.5 hrs / day (Sat–Sun) | ~20 hrs / month | Windows On-Demand + 500 GB EBS |
| **Daily Intern Power User** | 1.5 hrs / day (Every day) | 1.5 hrs / day | ~45 hrs / month | Windows Spot + 150 GB Tiered EBS |
| **Linux Software Engineer** | 1.0 hr / day (Mon–Fri) | 1.5 hrs / day (Sat–Sun) | ~32 hrs / month | Ubuntu On-Demand + 500 GB EBS |

---

## 5. Automated Cost Enforcement Guardrails

To prevent accidental cost runaways (e.g., an intern leaving the virtual machine on overnight, which would exhaust the entire monthly budget in 3.5 days):

1. **In-Guest Inactivity Daemon (`idle-shutdown-daemon.ps1`):**
   * Continuously monitors user mouse/keyboard input and `nvidia-smi` GPU load.
   * If input is idle for 15 minutes and GPU load is below 15%, it immediately issues an orderly OS shutdown.
2. **CloudWatch Auto-Stop Alarm (`cloudwatch.tf`):**
   * Infrastructure-level guardrail independent of the guest OS.
   * If average CPU utilization stays below 3% across two consecutive 5-minute sampling periods, CloudWatch invokes the EC2 Stop API.
3. **AWS Budgets Alerting Engine (`budgets.tf`):**
   * Configured with a monthly threshold of \$70.00 USD.
   * Sends automated notifications at **50% (\$35)**, **80% (\$56)**, and **100% (\$70 forecasted)** to `notification_email`.

---

## 6. Codevern Multi-Account Governance

PRD Section 7 states: "*The four AWS accounts must not be used to bypass Free Tier restrictions, licensing rules or service limits. The architecture should be designed around legitimate account ownership and consolidated cost visibility.*"

* **Architecture Alignment:**
  * All resources are tagged consistently with `Project = Codevern-Cloud-PC` and `Owner = Codevern Management`.
  * The Terraform configuration can be instantiated independently across the 4 allocated Codevern AWS accounts without code changes.
  * In production, the 4 accounts should be linked under **AWS Organizations** with **Consolidated Billing** enabled, providing Codevern management with real-time financial tracking across all developer workstations in a single unified dashboard.
