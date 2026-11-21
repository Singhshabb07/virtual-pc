# Codevern Cloud PC — Security Architecture & Configuration

## 1. Security Overview

Codevern Cloud PC adheres to the AWS Well-Architected Security Pillar and strictly satisfies all requirements outlined in **PRD Section 9**. The platform is designed around the principles of **Least Privilege**, **Zero Inbound Management Attack Surface**, and **Encryption in Transit & at Rest**.

---

## 2. Threat Vector Mitigation Matrix

| PRD Security Requirement | Threat Vector / Risk | Mitigation Architecture Implemented |
| :--- | :--- | :--- |
| **No Publicly Exposed RDP** | Brute force RDP credential stuffing, ransomware scanners, BlueKeep (CVE-2019-0708) exploits. | Port 3389 is completely disabled in `security_groups.tf`. Administrative access is exclusively brokered via **AWS Systems Manager (SSM) Session Manager** over outbound HTTPS (443). |
| **Restricted SSH Access** | Unauthorized SSH login attempts and brute force attacks on Linux instances. | Port 22 is closed to the public internet. SSH connections, if needed, are tunneled via SSM Session Manager. |
| **IAM Least Privilege** | Overprivileged instances accessing sensitive cloud assets across AWS accounts. | IAM role `codevern-cloudpc-role` grants strictly scoped permissions: `AmazonSSMManagedInstanceCore`, CloudWatch metrics publishing, and read-only S3 access to official AWS NVIDIA driver buckets. |
| **Credential Management** | AWS Access Keys leaked in code repositories or VM local storage. | Zero static AWS credentials. IAM Instance Profile provides automatic temporary STS credentials rotated every 6 hours. AWS credentials are never hardcoded. |
| **Encryption at Rest** | Physical theft of disk media or unauthorized snapshot cloning. | Both root (100 GB) and data (400 GB) EBS gp3 volumes are encrypted with AES-256 via AWS Key Management Service (`kms`). |
| **Encrypted Communication** | Man-in-the-middle (MitM) eavesdropping on desktop display, keystrokes, and audio. | Sunshine uses TLS 1.3 for Web Admin and AES-128/256-GCM encryption with DTLS for Moonlight video, audio, and gamepad input channels. |
| **Session Access Logs** | Unaudited remote desktop access and unauthorized instance modifications. | SSM Session Manager records all shell commands to AWS CloudWatch Logs. Sunshine logs pairing certificates and client IPs in `C:\Program Files\Sunshine\config\sunshine.log`. |
| **Backup and Recovery** | Data loss from disk corruption or ransomware infection. | Secondary EBS persistent volume runs independently of EC2 lifecycle. Automated EBS snapshots can be scheduled using AWS Data Lifecycle Manager (DLM). |

---

## 3. Network Security Group Specification

The Security Group (`codevern-cloudpc-sg`) implements strict ingress whitelisting:

```hcl
# Ingress Rules Summary:
- Port 47990 (TCP): Sunshine Web Management Portal (HTTPS only)
- Port 47984, 47989, 48010 (TCP): Moonlight Pairing & RTSP handshake
- Port 47998-48002, 48010 (UDP): Low-latency AV streaming data channels
- Port 8443 (TCP/UDP): NICE DCV Fallback (Optional)
- Port 3389 (TCP/UDP): BLOCKED (RDP)
- Port 22 (TCP): BLOCKED (SSH)
```

> [!TIP]
> **Production Best Practice:** To achieve the maximum security posture, update `allowed_client_cidr` in `terraform.tfvars` from `0.0.0.0/0` to your specific ISP public IP address (e.g. `203.0.113.50/32`).

---

## 4. In-Guest Operating System Hardening

The automated Windows bootstrap script (`bootstrap.ps1`) enforces:
1. **Windows Defender Antivirus:** Enabled and updated with latest cloud definitions.
2. **Network Level Authentication (NLA):** Enforced on local terminal services.
3. **Dedicated Admin Account:** Auto-generated credentials for local admin; no default passwords.
4. **Firewall Scope:** Local Windows Defender Firewall mirrors the AWS Security Group rules, denying all unneeded ports.
5. **Scheduled Task Isolation:** The Inactivity Daemon runs under the `NT AUTHORITY\SYSTEM` account to ensure non-administrative users cannot terminate the cost guardrail.
