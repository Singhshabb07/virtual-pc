# Codevern Cloud PC — Remote Access & User Connection Guide

## 1. Overview

Codevern Cloud PC utilizes **Sunshine** as the cloud-side host streamer and **Moonlight** as the client-side viewer. Moonlight is an open-source, ultra-low-latency streaming client available on virtually every operating system.

Because the infrastructure incorporates an **NVIDIA T4 GPU** and dedicated hardware **NVENC encoders**, you will experience near-zero latency (under 20ms in India) and full 60 FPS desktop fluidity—even when connecting from a low-specification laptop or mobile device.

---

## 2. Client Device Installation (Moonlight)

Download and install the Moonlight client application on your local device:

| Platform | Download Link | Notes |
| :--- | :--- | :--- |
| **Windows** | [moonlight-stream.org](https://moonlight-stream.org/) | Windows 10/11 installer (.exe) |
| **macOS** | [moonlight-stream.org](https://moonlight-stream.org/) | macOS DMG (Apple Silicon & Intel) |
| **Linux / Steam Deck** | Flatpak (`com.moonlight_stream.Moonlight`) | Available in software center |
| **Android / Google TV** | [Google Play Store](https://play.google.com/store/apps/details?id=com.limelight) | Supports bluetooth controllers |
| **iOS / iPadOS / Apple TV** | [Apple App Store](https://apps.apple.com/app/moonlight-game-streaming/id1000551556) | Supports MFi & Xbox/PS controllers |

---

## 3. Pairing Moonlight with Codevern Cloud PC

### Step 1: Obtain Your Cloud PC Public IP
From the Terraform outputs or the AWS EC2 Management Console, locate your instance's public IPv4 address:
```bash
terraform output public_ip
# Example output: 13.233.140.25
```

### Step 2: Access Sunshine Web Management Interface
1. Open your web browser on your local device.
2. Navigate to: `https://<CLOUD_PC_PUBLIC_IP>:47990`
   *(Accept the self-signed SSL certificate warning if prompted)*.
3. On first login, create your secure administrator username and password.

### Step 3: Pair Moonlight Client
1. Launch the **Moonlight** application on your client device.
2. Click the **Add Host** icon (computer with a plus sign) in the top-right corner.
3. Enter your Cloud PC Public IP address.
4. Moonlight will display a **4-digit PIN code** on your client screen (e.g., `4829`).
5. Return to the Sunshine Web UI in your browser:
   * Click on the **PIN** tab in the navigation bar.
   * Enter the 4-digit PIN shown on Moonlight and enter a friendly client name (e.g., `Intern-Laptop`).
   * Click **Send**.
6. The host will immediately appear as **Online** with a green lock icon in Moonlight!

---

## 4. Recommended Moonlight Streaming Settings

To achieve the best balance between visual quality, responsiveness, and AWS data transfer cost, configure Moonlight's settings (gear icon) as follows:

### Video Settings
* **Resolution:** `1920x1080 (1080p)` *(Select 2560x1440 or 3840x2160 only if client display supports it)*
* **Frame Rate:** `60 FPS` *(Set to 120 FPS if using a high-refresh-rate monitor)*
* **Video Bitrate:** `15.0 Mbps to 20.0 Mbps`
  * *Tip:* 15 Mbps produces pristine 1080p video while saving significant AWS data transfer fees compared to 40+ Mbps.
* **Video Codec:** `HEVC (H.265)` or `AV1` (Select *Auto* or *Force HEVC* for best compression).
* **Display Mode:** `Borderless Windowed` or `Full Screen`.
* **Frame Pacing:** `Balanced with Lowest Latency`.

### Audio & Input Settings
* **Audio Configuration:** `Stereo` (2 channels) or `5.1 Surround Sound`.
* **Mute host PC speakers while streaming:** Enabled.
* **Optimize mouse for remote desktop instead of games:**
  * **Enable** this when coding or doing office work (shows native client cursor).
  * **Disable** this when playing GTA V or 3D games (locks mouse to game camera).
* **Gamepad Support:** Automatically mapped via ViGEmBus. Plug in any Xbox or PlayStation controller via USB/Bluetooth.

---

## 5. Starting a Desktop or Gaming Session

1. In Moonlight, click on the **Codevern Cloud PC** host tile.
2. Select **Desktop** (or directly select **Steam** / **GTA V**).
3. The virtual workstation desktop will stream in full screen immediately.
4. Shortcuts during streaming:
   * **Ctrl + Alt + Shift + Q:** Disconnect session (leaves apps running).
   * **Ctrl + Alt + Shift + F:** Toggle fullscreen / windowed mode.
   * **Ctrl + Alt + Shift + S:** Toggle on-screen statistics overlay (FPS, latency, network drop).

---

## 6. Secure Zero-Port Administrative Access (AWS SSM)

Per **PRD Section 9**, public RDP (port 3389) and SSH (port 22) are disabled by default for security.

Administrators and developers can initiate a secure shell directly into the Windows or Linux workstation using **AWS Systems Manager Session Manager**:

### Prerequisites
Install the AWS CLI and Session Manager Plugin on your local machine:
```bash
aws --version
session-manager-plugin
```

### Connect to Windows PowerShell Session:
```bash
aws ssm start-session --target <INSTANCE_ID> --region ap-south-1
```

### Tunneling RDP or Local Ports Privately (Optional):
If you ever require native RDP for administrative troubleshooting without opening public firewall ports, tunnel it through SSM:
```bash
aws ssm start-session \
    --target <INSTANCE_ID> \
    --document-name AWS-StartPortForwardingSession \
    --parameters '{"portNumber":["3389"],"localPortNumber":["13389"]}'
```
Then connect your local Remote Desktop client to `localhost:13389`!
