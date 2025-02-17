<h1 align="center" style="font-size: 150%;">
  Windows PC $${\color{Aquamarine}{Toolkit}}$$
</h1>

<h2 align="center" style="font-size: 150%;">
  ★ Coming Soon! ★
</h2>

<p align="center">
  Hardware, networking, and software tools, modifications, and plugins for an enhanced Windows experience for gamers.
</p>

---

## 🚀 How to Install

### 🔹 Step 1: Run `Install-Dependencies.ps1`
1. Open **`Install-Dependencies.ps1`**.
2. Select **Yes** when prompted to run the script.
3. The script will check your system for missing dependencies and automatically install them if needed.

   The following components will be installed or updated:

   - ✅ **Python**: Installed  
   - ✅ **pip**: Upgraded  
   - ✅ **psutil** and **colorama**: Installed  
   - ✅ **winget**: Installed  
   - ✅ **Speedtest CLI**: Installed  
   - ✅ **Nmap**: Installed  
   - ✅ **WSL (Windows Subsystem for Linux)**: Installed  
   - ✅ **MTR (WinMTR)**: Installed  
   - ✅ **Paping**: Installed  
   - ✅ **tshark**: Installed  

> ⚠ **Important:** If WSL is not already enabled on your system, you must enable it in Windows settings. This is required for tools that rely on the Linux subsystem. If WSL is enabled, proceed as usual. Otherwise, enable it and re-run `Install-Dependencies.ps1`.

---

### 🔹 Step 2: Install Strawberry Perl
Download and install [Strawberry Perl](https://github.com/StrawberryPerl/Perl-Dist-Strawberry/releases/download/SP_54001_64bit_UCRT/strawberry-perl-5.40.0.1-64bit.msi).  

> ⚠ **Critical Requirement:** The program will **not run** without Strawberry Perl.

---

### 🔹 Step 3: Run `WindowsPCToolKit.pl`
After installing all dependencies, run the main script:

📌 **Option 1:** Double-click `WindowsPCToolKit.pl` to launch it.  

📌 **Option 2:** Run via **Command Prompt**:
   ```sh
   cd path\to\directory
   perl WindowsPCToolKit.pl
   ```

---

🎉 **You're all set!** Enjoy using your toolkit to enhance your Windows experience.

<hr>

---

## 📌 Frequently Asked Questions (FAQ)

### 💻 General Questions
<details>
  <summary><strong>1. What is this toolkit used for?</strong></summary>
  This toolkit is designed for **PC maintenance, troubleshooting, and optimization**. It includes tools for hardware diagnostics, network troubleshooting, software repair, system security, and overall system performance enhancement.
</details>

<details>
  <summary><strong>2. Do I need administrator privileges to run this script?</strong></summary>
  Yes. The script **automatically checks for admin rights** and, if necessary, relaunches itself using PowerShell with elevated privileges.
</details>

<details>
  <summary><strong>3. Does this toolkit work on all versions of Windows?</strong></summary>
  The toolkit is optimized for **Windows 10 and Windows 11**. Some features **may not work** on older Windows versions.
</details>

---

### 🛠 Hardware Troubleshooting
<details>
  <summary><strong>4. How does the Hard Drive Health Check work?</strong></summary>
  It utilizes **Windows Management Instrumentation (WMI)** to analyze connected disk drives and determine their health status. If any issues are detected, you’ll receive a report.
</details>

<details>
  <summary><strong>5. Can the USB Device Troubleshooting tool fix all USB issues?</strong></summary>
  This tool helps diagnose and resolve **common USB issues**, such as driver conflicts and connectivity errors. However, it **cannot fix** physically damaged USB devices.
</details>

---

### 🌐 Network Troubleshooting & Optimization
<details>
  <summary><strong>6. What does the "Clear DNS Cache" feature do?</strong></summary>
  It **flushes outdated DNS records** stored in your system, helping resolve network connectivity problems caused by incorrect domain name resolution.
</details>

<details>
  <summary><strong>7. How does the "Reset Network" feature work?</strong></summary>
  This function **resets the Winsock catalog and the TCP/IP stack**, fixing many common internet connection problems and restoring network functionality.
</details>

<details>
  <summary><strong>8. How does the DNS Benchmark tool help me?</strong></summary>
  The **DNS Benchmark tool** tests multiple DNS servers (e.g., **Google, Cloudflare, NextDNS**) and **recommends the fastest and most reliable option** for your connection.
</details>

---

### 🔒 Security & Maintenance
<details>
  <summary><strong>9. Can this script scan for malware?</strong></summary>
  Yes. The toolkit provides options for **quick and full system virus scans** and integrates with online malware analysis tools like **VirusTotal**.
</details>

<details>
  <summary><strong>10. What does "Check System Logs for Past Events" do?</strong></summary>
  This feature **retrieves and analyzes recent system logs**, helping you diagnose issues related to system performance, crashes, and security events.
</details>

---

### 📞 Contact & Support
<details>
  <summary><strong>11. How can I get support or report an issue?</strong></summary>
  If you need assistance, have feedback, or encounter any issues, you can reach out through:

  - 📧 **Email**: [your-email@example.com](mailto:your-email@example.com)
  - 🛠 **GitHub Issues**: [GitHub Repository](https://github.com/your-repo)
  - 💬 **Join our Discord Community for Live Support**:  
    [![Discord](https://img.shields.io/badge/Join-Discord-7289DA?logo=discord&logoColor=white&style=flat-square)](https://discord.gg/btPcajnDs5)
</details>

---

