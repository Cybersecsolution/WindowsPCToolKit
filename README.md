<h1 align="center" style="font-size: 150%;">
  Windows PC $${\color{Aquamarine}{Toolkit}}$$
</h1>

<h2 align="center" style="font-size: 150%;">
  ★ Coming Soon! ★
</h2>

<p align="center">
  Hardware, networking, and software tools, modifications, and plugins for an enhanced Windows experience for gamers.
</p>



<p align="center">
  Hardware, networking, and software tools, modifications, and plugins for an enhanced Windows experience for gamers.
</p>

## How to Install

### Step 1: Run Install-Dependencies.ps1
1. Open `Install-Dependencies.ps1`.
2. Select **Yes** to run the script and check your system.
3. Ensure you have the required dependencies installed. If not, the script will install the following:

   - **Python**: Installed  
   - **pip**: Upgraded  
   - **psutil** and **colorama**: Installed  
   - **winget**: Installed  
   - **Speedtest CLI**: Installed  
   - **Nmap**: Installed  
   - **WSL (Windows Subsystem for Linux)**: Installed  
   - **MTR (WinMTR)**: Installed  
   - **Paping**: Installed  
   - **tshark**: Installed  

> ⚠ **Note:** If WSL is not enabled on your system, you will need to enable it in your settings. This step is required for certain tools that rely on the Linux subsystem. If you already have it enabled, you can continue. Otherwise, enable it and re-run `Install-Dependencies.ps1`.

### Step 2: Install Strawberry Perl
Download and install [Strawberry Perl](https://github.com/StrawberryPerl/Perl-Dist-Strawberry/releases/download/SP_54001_64bit_UCRT/strawberry-perl-5.40.0.1-64bit.msi).  
> ⚠ **Important:** The program will not run without Strawberry Perl.

### Step 3: Run WindowsPCToolKit.pl
Once dependencies are installed, run the script:

- **Option 1:** Double-click `WindowsPCToolKit.pl` to open it.  
- **Option 2:** Run via **Command Prompt**:
  ```sh
  cd path\to\directory
  perl WindowsPCToolKit.pl










<hr>

## 📌 Frequently Asked Questions (FAQ)

<details>
  <summary>💻 General Questions</summary>

  **Q1: What is this toolkit used for?**  
  A1: This toolkit is designed for PC maintenance, troubleshooting, and optimization. It includes features for hardware diagnostics, network troubleshooting, software repair, system security, and more.

  **Q2: Do I need administrator privileges to run this script?**  
  A2: Yes, the script automatically checks for administrator rights. If it is not run with elevated privileges, it will relaunch itself using PowerShell with elevation.

  **Q3: Does this script work on all versions of Windows?**  
  A3: The toolkit is designed for Windows 10 and Windows 11. Some features may not work on older versions.

</details>

<details>
  <summary>🛠 Hardware Troubleshooting</summary>

  **Q4: How does the Hard Drive Health Check work?**  
  A4: It uses Windows Management Instrumentation (WMI) to check the status of connected disk drives and reports whether they are in good condition.

  **Q5: Can the USB Device Troubleshooting tool fix all USB issues?**  
  A5: It helps identify and resolve common USB problems, such as driver issues and connectivity problems. However, if a USB device is physically damaged, this tool will not fix it.

</details>

<details>
  <summary>🌐 Network Troubleshooting & Optimization</summary>

  **Q6: What does the "Clear DNS Cache" feature do?**  
  A6: It flushes the DNS cache to remove outdated domain name resolution data, which can help resolve connectivity issues.

  **Q7: How does the "Reset Network" feature work?**  
  A7: It resets the Winsock catalog and the TCP/IP stack, which can resolve many internet and connectivity problems.

  **Q8: How does the DNS Benchmark tool help me?**  
  A8: The tool tests multiple DNS servers (e.g., Google, Cloudflare, NextDNS) and recommends the fastest DNS for your internet connection.

</details>

<details>
  <summary>🔒 Security & Maintenance</summary>

  **Q9: Can this script scan for malware?**  
  A9: Yes, it offers options for quick/full virus scans and links to online scanning tools like VirusTotal.

  **Q10: What does "Check System Logs for Past Events" do?**  
  A10: It retrieves recent system logs to help diagnose issues.

</details>

<details>
  <summary>📞 Contact & Support</summary>

  💬 Need help or have questions? Join our official Discord server for support and discussions!  
  👉 [**Join the Discord Community**](https://discord.gg/btPcajnDs5)

</details>
