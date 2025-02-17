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
  This toolkit is a **comprehensive solution** for **PC maintenance, troubleshooting, and optimization**. It includes tools for:
  - **Hardware diagnostics** (e.g., disk health, USB troubleshooting)
  - **Network optimization** (e.g., DNS benchmarking, clearing cache, resetting connections)
  - **Software repair** (e.g., fixing common system errors)
  - **Security enhancements** (e.g., malware scanning, log analysis)
</details>

<details>
  <summary><strong>2. Do I need administrator privileges to run this script?</strong></summary>
  Yes. The script **automatically detects if it’s running with admin rights**. If not, it will relaunch itself with **elevated permissions** in PowerShell.
</details>

<details>
  <summary><strong>3. What Windows versions does this support?</strong></summary>
  The toolkit is **fully compatible** with **Windows 10 and Windows 11**. Some features may not function properly on older versions like Windows 7 or 8.
</details>

---

### 🛠 Hardware Troubleshooting
<details>
  <summary><strong>4. How does the Hard Drive Health Check work?</strong></summary>
  The script uses **Windows Management Instrumentation (WMI)** to analyze disk health and status. It reports if any issues are detected, such as **bad sectors or potential failures**.
</details>

<details>
  <summary><strong>5. Can the USB Device Troubleshooting tool fix all USB issues?</strong></summary>
  This tool can **diagnose and resolve software-related USB issues**, such as:
  - **Driver conflicts**
  - **Power management issues**
  - **Device detection errors**
  
  However, **physical damage to USB ports or devices cannot be fixed** with software.
</details>

---

### 🌐 Network Troubleshooting & Optimization
<details>
  <summary><strong>6. What does the "Clear DNS Cache" feature do?</strong></summary>
  It **flushes outdated DNS records** stored on your system, which can:
  - Speed up domain name resolution  
  - Fix connectivity issues caused by **stale DNS entries**
  - Improve overall browsing performance
</details>

<details>
  <summary><strong>7. How does the "Reset Network" feature work?</strong></summary>
  This option **resets the Winsock catalog and TCP/IP stack**, which can resolve:
  - Persistent **internet connectivity issues**
  - **Unresponsive network adapters**
  - Problems caused by **corrupt network configurations**
</details>

<details>
  <summary><strong>8. How does the DNS Benchmark tool help?</strong></summary>
  The DNS Benchmark tool **tests multiple DNS providers** (e.g., **Google, Cloudflare, NextDNS**) and determines:
  - **Which DNS server is the fastest** for your location  
  - **Which provides better reliability and security**  
  - If your **current DNS settings need improvement**  
</details>

---

### 🔒 Security & Maintenance
<details>
  <summary><strong>9. Can this script scan for malware?</strong></summary>
  Yes. The toolkit includes **quick and full system virus scans** and also integrates with:
  - **Windows Defender** (built-in)
  - **VirusTotal** (for online file scanning)
</details>

<details>
  <summary><strong>10. What does "Check System Logs for Past Events" do?</strong></summary>
  This feature retrieves and analyzes **recent system logs** to help:
  - Identify **crashes and error events**
  - Troubleshoot **performance slowdowns**
  - Detect **security-related warnings**
</details>

---

### 📞 Contact & Support
<details>
  <summary><strong>11. Where can I get support or report an issue?</strong></summary>
  If you need help, have feedback, or found a bug, you can reach us through:
  
  - 📧 **Email**: [your-email@example.com](mailto:your-email@example.com)  
  - 🛠 **GitHub Issues**: [Submit a bug report](https://github.com/your-repo)  
  - 💬 **Join our Discord community for real-time support**:  
    [![Discord](https://img.shields.io/badge/Join-Discord-7289DA?logo=discord&logoColor=white&style=flat-square)](https://discord.gg/btPcajnDs5)  
</details>

---

### 🚀 **Need More Help?**
If your question isn’t listed here, feel free to **reach out via Discord** or **open a support request** on GitHub!  

---

</details>

---

