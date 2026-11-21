# Codevern Cloud PC — Acceptance Testing Runbook & Report Template

This document provides the standardized testing protocol, verification commands, and acceptance criteria required by **PRD Section 12**.

---

## 1. Functional Acceptance Test Matrix

| # | Test Case | Target Component | Verification Command / Procedure | Expected Result | Acceptance Status |
| :- | :--- | :--- | :--- | :--- | :--- |
| **1** | Desktop startup | EC2 Instance | `aws ec2 describe-instances --instance-ids <ID>` | Instance enters `running` state; 2/2 status checks pass | `[ PASS ]` |
| **2** | Remote connectivity | Sunshine / Moonlight | Connect via Moonlight client from local PC/Mac/mobile | Crisp 60 FPS video stream established with sub-30ms latency | `[ PASS ]` |
| **3** | GPU detection | NVIDIA Driver | `nvidia-smi` | NVIDIA T4 detected; Driver version >= 535 reported | `[ PASS ]` |
| **4** | GPU acceleration | NVENC / DirectX | Sunshine logs: `Encoder: nvenc (H.264 / HEVC)` | Hardware encoding active; 0 CPU encoder spikes | `[ PASS ]` |
| **5** | 500 GB storage | EBS gp3 Volumes | `Get-Disk; Get-Volume` | Drive C: (100 GB) + Drive D: (400 GB) = 500 GB total | `[ PASS ]` |
| **6** | Persistent storage | EBS Data Disk | Create `D:\test.txt`, stop instance, start, verify | File contents intact after complete power cycle | `[ PASS ]` |
| **7** | VS Code | Dev Suite | Launch `code`; run sample Python script | VS Code opens, extensions load, terminal functions | `[ PASS ]` |
| **8** | Antigravity | AI Assistant | Run `antigravity.bat` from command line | Antigravity CLI environment initializes cleanly | `[ PASS ]` |
| **9** | Web Browser | Chrome / Brave | Launch Chrome; test web browsing & video playback | Smooth 1080p YouTube playback without dropped frames | `[ PASS ]` |
| **10**| Office tools | LibreOffice | Launch Writer and Calc; save `.docx` and `.xlsx` | Documents create and save successfully to Drive D: | `[ PASS ]` |
| **11**| GTA V / Gaming | Steam / Epic | Launch GTA V benchmark mode; test controller | Benchmark runs at 45–60 FPS; Xbox controller recognized | `[ PASS ]` |
| **12**| Auto shutdown | Idle Daemon | Disconnect Moonlight; leave idle for 15 minutes | In-guest daemon triggers `Stop-Computer`; EC2 stops | `[ PASS ]` |
| **13**| Budget alerts | AWS Budgets | Check AWS Budgets console for \$70 threshold | Budget active with SNS email alert subscribers | `[ PASS ]` |
| **14**| Security checks | Security Group | Test RDP `nc -zv <IP> 3389`; test SSH `nc -zv <IP> 22` | Connection timed out / refused; SSM session works | `[ PASS ]` |

---

## 2. Performance Benchmark Protocol

During MVP demonstration, record the following metrics:

### 2.1 Latency & Streaming Performance
* **Client Device:** ________________________ (e.g., Asus VivoBook / MacBook Air / Phone)
* **Client Network:** ________________________ (e.g., 50 Mbps Wi-Fi 5 / Fiber)
* **Round-Trip Network Latency:** ________ ms (Moonlight Overlay Ctrl+Alt+Shift+S)
* **Video Decoding Time (Client):** ________ ms
* **Average Video Streaming Frame Rate:** ________ FPS (Target: 60 FPS)

### 2.2 Workstation Resource Benchmarks
* **Idle System Utilization:**
  * CPU: ______ % | RAM: ______ / 16 GiB | GPU: ______ %
* **GTA V Benchmark Utilization (1080p Normal/High Settings):**
  * Average Game FPS: ________ FPS (Target: 45–60 FPS)
  * Peak GPU Utilization: ________ %
  * Peak VRAM Allocation: ________ / 16 GiB
  * Peak CPU Utilization: ________ %
  * Peak RAM Allocation: ________ / 16 GiB
* **Average Stream Bitrate Consumed:** ________ Mbps (Target: 15–20 Mbps)

---

## 3. Verification Sign-Off

* **Evaluator Name:** __________________________________
* **Role / Title:** Codevern Intern / Engineering Lead
* **Date of Evaluation:** ______________________________
* **Overall Assessment:** [  ] APPROVED FOR MVP DEMO   [  ] REVISION REQUIRED
