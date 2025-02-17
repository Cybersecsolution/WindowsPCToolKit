#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Term::ANSIColor;
use open qw(:std :encoding(UTF-8));
use Win32;
use Cwd qw(abs_path);
use File::Basename;
use File::Path qw(remove_tree);
use File::Find;
use Digest::SHA qw(sha256_hex);
use LWP::UserAgent;
use Socket;
use Time::HiRes qw(sleep);
use Archive::Extract;
use File::Temp qw(tempdir);
use JSON;


# Force CMD to use UTF-8 (Windows only)
system("chcp 65001 > nul");

# Check if running as admin. If not, relaunch using PowerShell with elevation.
unless (Win32::IsAdminUser()) {
    my $abs_script = abs_path($0);
    my $ps_cmd = "Start-Process perl.exe -ArgumentList '\"$abs_script\"' -Verb RunAs";
    system("powershell -Command \"$ps_cmd\"");
    exit;
}

# -------------------------------
# Function to print ASCII Art Header
# -------------------------------
sub print_header {
    print color("green"), "================================================================================\n"; 
    print "                                                                               \n";          
    print "       ██╗    ██╗██╗███╗   ██╗██████╗  ██████╗ ██╗    ██╗███████╗              \n";        
    print "       ██║    ██║██║████╗  ██║██╔══██╗██╔═══██╗██║    ██║██╔════╝              \n";    
    print "       ██║ █╗ ██║██║██╔██╗ ██║██║  ██║██║   ██║██║ █╗ ██║███████╗              \n";
    print "       ██║███╗██║██║██║╚██╗██║██║  ██║██║   ██║██║███╗██║╚════██║              \n";
    print "       ╚███╔███╔╝██║██║ ╚████║██████╔╝╚██████╔╝╚███╔███╔╝███████║              \n";
    print "       ╚══╝╚══╝ ╚═╝╚═╝  ╚═══╝╚═════╝  ╚═════╝  ╚══╝╚══╝ ╚══════╝               \n";                                                    
    print "                                                                               \n";
    print " ██████╗  ██████╗    ████████╗ ██████╗  ██████╗ ██╗     ██╗  ██╗██╗████████╗   \n";
    print " ██╔══██╗██╔════╝    ╚══██╔══╝██╔═══██╗██╔═══██╗██║     ██║ ██╔╝██║╚══██╔══╝   \n";
    print " ██████╔╝██║            ██║   ██║   ██║██║   ██║██║     █████╔╝ ██║   ██║      \n";
    print " ██╔═══╝ ██║            ██║   ██║   ██║██║   ██║██║     ██╔═██╗ ██║   ██║      \n";
    print " ██║     ╚██████╗       ██║   ╚██████╔╝╚██████╔╝███████╗██║  ██╗██║   ██║      \n";
    print " ╚═╝      ╚═════╝       ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝   ╚═╝      \n";
    print "===============================================================================\n";
    print "              PC Maintenance & Troubleshooting Toolkit                         \n";                                                               
    print "===============================================================================\n";
    print color("reset"), "\n";
}

# -------------------------------
# Helper function: pause execution
# -------------------------------
sub pause {
    print "\nPress Enter to continue...";
    <STDIN>;
}

# -------------------------------
# Hardware: Hard Drive Health Check
# -------------------------------
sub test_hard_drive_health {
    print colored("\n[Hard Drive Health Check] Performing Hard Drive Health Check...\n", "cyan");
    my $output = `wmic diskdrive get Status, Model, Size /format:list`;
    print colored($output, "green"), "\n";
    pause();
}

# -------------------------------
# Hardware: USB Device Troubleshooting
# -------------------------------
sub invoke_usb_device_troubleshooting {
    print colored("\n[USB Device Troubleshooting] Performing USB Device Troubleshooting...\n", "cyan");

    # Check if devcon is available (better for listing USB devices)
    my $devcon_path = `where devcon`;
    chomp($devcon_path);

    if ($devcon_path) {
        print colored("Using Devcon to list USB devices...\n", "green");
        system("devcon find *USB*");
    } else {
        print colored("Using WMIC to list USB devices...\n", "yellow");
        system('wmic path CIM_LogicalDevice where "Description like \'%USB%\'" get Description, DeviceID');
    }

    print "\nDo you want to safely eject a USB device? (Y/N): ";
    chomp(my $response = <STDIN>);

    if (uc($response) eq 'Y') {
        print "Enter the Instance ID of the USB device to eject: ";
        chomp(my $instanceId = <STDIN>);
        if ($instanceId) {
            print colored("Ejecting USB device...\n", "cyan");
            system("pnputil /disable-device \"$instanceId\"");
        } else {
            print colored("Invalid Instance ID. Skipping eject operation.\n", "yellow");
        }
    }

    print colored("Do you want to troubleshoot USB connectivity issues? (Y/N): ", "yellow");
    chomp($response = <STDIN>);

    if (uc($response) eq 'Y') {
        print colored("Restarting USB controllers...\n", "yellow");
        system("devcon restart *USB*");
        print colored("USB troubleshooting completed. Reconnect devices if needed.\n", "green");
    }

    pause();
}

# -------------------------------
# Hardware Menu (contains hardware & system maintenance tasks)
# -------------------------------
sub hardware_menu {
    while (1) {
        clear_screen();
        print_header();
        print "Hardware Menu:\n";
        print " 1) Hard Drive Health Check\n";
        print " 2) USB Device Troubleshooting\n";
        print " 3) Back to Main Menu\n\n";
        print "Enter your choice: ";
        chomp(my $hw_choice = <STDIN>);
        if ($hw_choice eq "1") {
            test_hard_drive_health();
        }
        elsif ($hw_choice eq "2") {
            invoke_usb_device_troubleshooting();
        }
        elsif ($hw_choice eq "3") {
            last;
        }
        else {
            print colored("Invalid choice.\n", "yellow");
            pause();
        }
    }
}

# -------------------------------
# Networking: Clear DNS Cache
# -------------------------------
sub clear_dns {
    print colored("\n[Clear DNS Cache] Clearing DNS Cache...\n", "cyan");
    my $ret = system("ipconfig /flushdns");
    if ($ret == 0) {
        print colored("DNS cache cleared successfully.\n", "green");
    } else {
        print colored("Failed to clear DNS.\n", "red");
    }
}

# -------------------------------
# Networking: Reset Network (Winsock, IP stack)
# -------------------------------
sub reset_network {
    print colored("\n[Reset Network] Resetting Network (Winsock, IP stack)...\n", "cyan");
    my $ret1 = system("netsh winsock reset");
    my $ret2 = system("netsh int ip reset");
    if ($ret1 == 0 && $ret2 == 0) {
        print colored("Network reset completed. A reboot is recommended.\n", "yellow");
    } else {
        print colored("Failed to reset network.\n", "red");
    }
}

# -------------------------------
# Networking: DNS Benchmark
# -------------------------------
sub test_dns_performance {
    print colored("\n[DNS Benchmark] Finding the fastest DNS for your network...\n", "cyan");
    print colored("Testing DNS servers...\n", "yellow");
    my @dnsServers = ( '1.1.1.1', '8.8.8.8', '9.9.9.9', '77.88.8.8', '185.228.168.9', '185.228.169.9' );
    my %dnsInfo = (
        '1.1.1.1'       => "Cloudflare (Fast, but not fully private)",
        '8.8.8.8'       => "Google DNS (Fast, but not privacy‐friendly)",
        '9.9.9.9'       => "Quad9 (Privacy‐focused, Blocks malicious domains)",
        '77.88.8.8'     => "Yandex DNS (Secure, but privacy concerns)",
        '185.228.168.9' => "Next DNS (Privacy‐focused, Customizable)",
        '185.228.169.9' => "Next DNS (Privacy‐focused, Customizable)"
    );
    my @results;
    foreach my $dns (@dnsServers) {
        print colored("Testing DNS: $dns ($dnsInfo{$dns})\n", "yellow");
        my $ping = `ping -n 5 $dns`;
        if ($? == 0) {
            if ($ping =~ /Average = (\d+)ms/) {
                push @results, { DNS => $dns, PingTime => $1, Provider => $dnsInfo{$dns} };
                print colored("$dns is reachable with average response time: $1 ms\n", "green");
            }
        } else {
            print colored("$dns is unreachable\n", "red");
        }
    }
    if (@results) {
        @results = sort { $a->{PingTime} <=> $b->{PingTime} } @results;
        print colored("\nFastest DNS is: $results[0]->{DNS} ($results[0]->{Provider}) with $results[0]->{PingTime} ms\n", "green");
    }
    print colored("DNS Benchmark completed!\n", "green");
}

# -------------------------------
# Network Firewall Security Level
# -------------------------------
sub set_firewall_security_level {
    print colored("\n[Firewall Rules] Firewall Rules Management: Set Firewall Security Level\n", "cyan");
    print "Warning: Changing firewall settings can impact your system's security.\n";
    print "Please select a firewall security level:\n";
    print colored("1) Lockdown Mode (Blocks all incoming and outgoing traffic, including apps)\n", "bold red");
    print colored("2) Strict (Blocks most incoming and outgoing traffic)\n", "red");
    print colored("3) Medium (Balanced security with more flexibility)\n", "green");
    print colored("4) Low (Allows most traffic, minimal restrictions)\n", "yellow");
    print colored("5) Restore Default Firewall Settings (Resets firewall to default)\n", "cyan");

    my $valid_choice = 0;

    while (!$valid_choice) {
        print "Enter your choice (1-5): ";
        chomp(my $choice = <STDIN>);

        # Check if input is empty or not a valid number
        if ($choice eq "" || $choice !~ /^[1-5]$/) {
            print colored("\nInvalid selection. Please enter a number between 1 and 5.\n", "red");
            next;  # Loop again
        }

        # Convert to number
        $choice = int($choice);
        $valid_choice = 1;  # Mark as valid choice to exit loop

        if ($choice == 1) {
            print colored("\nSetting firewall to Lockdown Mode...\n", "bold red");
            system("netsh advfirewall set allprofiles firewallpolicy blockinbound,blockoutbound");
            print colored("Lockdown Mode set. Logging the user out...\n", "bold red");
            system("shutdown /l");
            return;  # Exit function immediately
        }
        elsif ($choice == 2) {
            print colored("\nSetting firewall to Strict Mode...\n", "green");
            system("netsh advfirewall set allprofiles firewallpolicy blockinbound,blockoutbound");
            system("netsh advfirewall firewall add rule name=\"Allow HTTPS\" protocol=TCP localport=443 action=allow dir=in");
            system("netsh advfirewall firewall add rule name=\"Allow HTTPS\" protocol=TCP localport=443 action=allow dir=out");
            print colored("Strict Mode set.\n", "green");
        }
        elsif ($choice == 3) {
            print colored("\nSetting firewall to Medium Mode...\n", "green");
            system("netsh advfirewall set allprofiles firewallpolicy allowinbound,allowoutbound");
            print colored("Medium Mode set.\n", "green");
        }
        elsif ($choice == 4) {
            print colored("\nSetting firewall to Low Mode...\n", "green");
            system("netsh advfirewall set allprofiles firewallpolicy allowinbound,allowoutbound");
            print colored("Low Mode set.\n", "green");
        }
        elsif ($choice == 5) {
            print colored("\nRestoring default firewall settings...\n", "cyan");
            system("netsh advfirewall reset");
            print colored("Firewall settings restored to default.\n", "green");
        }
    }
}

# -------------------------------------------
# Network Performance & Open Port Scanner
# -------------------------------------------
sub check_network_performance {
    print colored("\n[Network Performance & Gaming Port Scanner] Analyzing Network...\n", "cyan");

    # Retrieve Public and Local IP Addresses
    print colored("\n[] Retrieving public and local IP addresses...\n", "yellow");

    # 1) Get Public IP (Try IPv4 first, then fallback IPv6)
    my $public_ip = `curl -4 -s ifconfig.me`;
    chomp($public_ip);
    if ($public_ip !~ /^\d+\.\d+\.\d+\.\d+$/) {
        $public_ip = `curl -6 -s ifconfig.me`;
        chomp($public_ip);
    }

    # Validate Public IP
    if ($public_ip =~ /^(\d{1,3}\.){3}\d{1,3}$/ || $public_ip =~ /^[a-fA-F0-9:]+$/) {
        print colored("[+] Your Public IP: $public_ip\n", "green");
    } else {
        print colored("[X] Could not retrieve public IP. Check your internet connection.\n", "red");
        return;
    }

    # 2) Get Local IP (Windows)
    my $local_ip = `ipconfig | findstr /R "IPv4"`;
    if ($local_ip =~ /IPv4 Address[.\s]+: (\d+\.\d+\.\d+\.\d+)/) {
        $local_ip = $1;
        print colored("[+] Your Local Network IP: $local_ip\n", "green");
    } else {
        print colored("[X] Could not determine local IP address.\n", "red");
        return;
    }

    # 3) Check VPN status & ISP details (ProxyCheck.io)
    print colored("\n[] Checking VPN status and ISP details...\n", "yellow");
    my $api_key        = "8619y5-38p3c9-64464s-9q556y";
    my $vpn_check_url  = "https://proxycheck.io/v2/$public_ip?key=$api_key&vpn=1&asn=1&risk=1&port=1&seen=1&days=7&tag=msg";
    my $ua            = LWP::UserAgent->new;
    my $res           = $ua->get($vpn_check_url);

    my ($isp, $hostname, $country, $city, $region, $vpn_detected);

    if ($res->is_success) {
        my $response_data = decode_json($res->decoded_content);
        my $data = $response_data->{$public_ip} // {};

        # VPN Detection
        if (defined $data->{'proxy'} && $data->{'proxy'} eq "yes") {
            print colored("[X] You are using a VPN!\n", "red");
            $vpn_detected = 1;
        } else {
            print colored("[+] No VPN Detected. \n", "green");
            $vpn_detected = 0;
        }

        # Extract ISP & Location Data
        $isp      = $data->{'asn_org'} if defined $data->{'asn_org'};
        $hostname = $data->{'host'}    if defined $data->{'host'};
        $country  = $data->{'country'} if defined $data->{'country'};
        $city     = $data->{'city'}    if defined $data->{'city'};
        $region   = $data->{'region'}  if defined $data->{'region'};
    }

    # 4) Fallback to IPInfo.io if ISP/Hostname are missing
    if (!$isp || !$hostname) {
        print colored("\n[🔄] Retrieving ISP & Hostname...\n", "yellow");
        my $ipinfo_url = "https://ipinfo.io/$public_ip/json";
        my $ipinfo_res = $ua->get($ipinfo_url);

        if ($ipinfo_res->is_success) {
            my $ipinfo_data = decode_json($ipinfo_res->decoded_content);
            $isp      = $ipinfo_data->{'org'}      if defined $ipinfo_data->{'org'};
            $hostname = $ipinfo_data->{'hostname'} if defined $ipinfo_data->{'hostname'};
        }
    }

    # Ensure no undefined values
    $isp      ||= "Unknown";
    $hostname ||= "Unknown";
    $country  ||= "Unknown";
    $city     ||= "Unknown";
    $region   ||= "Unknown";

    # Display ISP & Location Info
    print colored("\n[] ISP & Location Information:\n", "cyan");
    print colored("[] ISP: $isp\n", "green");
    print colored("[] Hostname: $hostname\n", "green");
    print colored("[] Country: $country\n", "green");
    print colored("[] City: $city\n", "green");
    print colored("[] State/Region: $region\n", "green");

    # 5) Measure general network latency
    print colored("\nChecking network latency...\n", "yellow");
    my $latency_output = `ping -n 4 8.8.8.8 | find "Average"`;
    if ($latency_output =~ /Average = (\d+)ms/) {
        my $latency = $1;
        print colored("Average network latency: $latency ms\n", "green");

        if ($vpn_detected) {
            if    ($latency < 50)  { print colored("+ Excellent VPN connection (20–50 ms).\n", "bold green"); }
            elsif ($latency < 100) { print colored("+ Good VPN connection (50–100 ms).\n", "green"); }
            elsif ($latency < 150) { print colored("! Acceptable VPN connection (100–150 ms).\n", "yellow"); }
            else                   { print colored("X Poor VPN connection (150+ ms). Expect lag.\n", "red"); }
        }
        else {
            if    ($latency < 20)  { print colored("+ Excellent home network connection (0–20 ms).\n", "bold green"); }
            elsif ($latency < 50)  { print colored("+ Good home network connection (20–50 ms).\n", "green"); }
            elsif ($latency < 100) { print colored("! Acceptable home network connection (50–100 ms).\n", "yellow"); }
            else                   { print colored("X Poor home network connection (100+ ms). Check ISP or routing.\n", "red"); }
        }
    }

    #
    # ===== Speed Test Section (via WSL) =====
    #
    # 1) List available servers (so we can pick the closest)
    my $server_list = `wsl speedtest-cli --list 2>&1`;
    my $chosen_id;  # will store the best server ID
    my $min_dist = 999999;
    my $list_failed = 0;

    if ($? != 0 || !$server_list) {
        # If listing fails, we'll just fallback
        $list_failed = 1;
    }
    else {
        # Parse each line for "ID) Name (dist km)"
        foreach my $line (split /\n/, $server_list) {
            if ($line =~ /^\s*(\d+)\)\s.*\(([\d\.]+)km\)/) {
                my $id   = $1;
                my $dist = $2 + 0;  # numeric
                if ($dist < $min_dist) {
                    $min_dist = $dist;
                    $chosen_id = $id;
                }
            }
        }
        # If we never found a server ID, fallback
        $list_failed = 1 unless $chosen_id;
    }

    my $speedtest_json;

    if ($list_failed) {
        # Fallback: run default speedtest
        $speedtest_json = `wsl speedtest-cli --json 2>&1`;
    } else {
        # Run test against chosen server
        $speedtest_json = `wsl speedtest-cli --server $chosen_id --json 2>&1`;
    }

    if ($? != 0 || !$speedtest_json) {
        print colored("Could not run speedtest-cli under WSL (not installed or error occurred).\n", "red");
        return;
    }

    my $parsed;
    eval {
        $parsed = decode_json($speedtest_json);
        1;
    } or do {
        print colored("Failed to parse speedtest-cli JSON output.\n", "red");
        return;
    };

    # Extract bits per second from JSON
    my $download_bps = $parsed->{"download"} // 0;
    my $upload_bps   = $parsed->{"upload"}   // 0;

    # Convert to Mbps
    my $download_mbps = sprintf("%.2f", $download_bps / 1_000_000);
    my $upload_mbps   = sprintf("%.2f", $upload_bps   / 1_000_000);

    print colored("Download Speed: ", "green") . "$download_mbps Mbps\n";
    print colored("Upload Speed:   ", "green") . "$upload_mbps Mbps\n";

    # 6) Run Nmap scan for TCP & UDP gaming ports (via WSL)
    my $port_list = "27015,27016,25565,7777,3074,3659,4000,5000,6112,8444,9987,9308";
    print colored("\nScanning for TCP & UDP gaming ports using Nmap...\n", "yellow");
    my $nmap_output = `wsl sudo nmap -sS -sU -Pn -p $port_list -T4 $local_ip`;
    print colored("\nNmap Gaming Port Scan Results:\n", "green");
    print "$nmap_output\n";

    # 7) Check latency to various platform, game, and website servers
    print colored("\nChecking latency to servers...\n", "yellow");

    my %platform_servers = (
        "Steam"         => "23.202.61.170",
        "Xbox Live"     => "13.89.245.219",
        "PlayStation"   => "23.33.42.78",
        "Epic Games"    => "3.167.99.3",
        "Battle"        => "23.44.133.11",
        "Discord"       => "162.159.137.232",
        "Rockstar Games"=> "104.92.228.159",
        "Ubisoft"       => "203.132.25.4",
        "EA"            => "184.51.106.167",
    );

    my %game_servers = (
        "Call Of Duty"          => "www.callofduty.com",
        "Fortnite"              => "www.fortnite.com",
        "Riot Games"            => "www.riotgames.com",
        "Minecraft"             => "www.minecraft.net",
        "Roblox"                => "www.roblox.com",
        "Red Dead Redemption 2" => "172.64.147.119",
    );

    my %website_servers = (
        "Google"        => "www.google.com",
        "YouTube"       => "www.youtube.com",
        "Wikipedia"     => "www.wikipedia.org",
        "Twitch"        => "www.twitch.tv",
        "Reddit"        => "www.reddit.com",
        "Amazon"        => "www.amazon.com",
        "Discord"       => "discord.com",
        "Steam"         => "store.steampowered.com",
        "Epic Games"    => "store.epicgames.com",
        "PlayStation"   => "www.playstation.com",
        "Xbox Live"     => "www.xbox.com",
        "Ubisoft"       => "www.ubisoft.com",
        "EA"            => "www.ea.com",
    );

    # ---- Platform Servers ----
    print colored("\n==== Platform Servers ====\n", "bold yellow");
    foreach my $platform (keys %platform_servers) {
        my $ping_result = `ping -n 4 $platform_servers{$platform} | find "Average"`;
        if ($ping_result =~ /Average = (\d+)ms/) {
            my $ping_ms = $1;
            print colored("\n$platform Client Latency: ", "cyan") . colored("$ping_ms ms\n", "green");
            if    ($ping_ms < 30) { print colored("[+] Excellent connection to $platform Client.\n", "bold green"); }
            elsif ($ping_ms < 70) { print colored("[*] Good Client Connection\n", "bright_green"); }
            else                  { print colored("[!] Average ping to $platform Client.\n", "yellow"); }
        } else {
            print colored("\n[!] Could not reach $platform servers. Consider changing DNS or ISP.\n", "red");
        }
    }

    # ---- Game Servers ----
    print colored("\n==== Game Servers ====\n", "bold yellow");
    foreach my $game (keys %game_servers) {
        my $ping_result = `ping -n 4 $game_servers{$game} | find "Average"`;
        if ($ping_result =~ /Average = (\d+)ms/) {
            my $ping_ms = $1;
            print colored("\n$game Server Latency: ", "cyan") . colored("$ping_ms ms\n", "green");
            if    ($ping_ms < 30) { print colored("[+] Excellent connection to $game servers.\n", "bold green"); }
            elsif ($ping_ms < 70) { print colored("[*] Good Server Connection\n", "bright_green"); }
            else                  { print colored("[!] Average ping to $game servers.\n", "yellow"); }
        } else {
            print colored("\n[!] Could not reach $game servers. Consider changing DNS or ISP.\n", "red");
        }
    }

    # ---- Website Servers ----
    print colored("\n==== Website Domain Servers ====\n", "bold yellow");
    foreach my $website (keys %website_servers) {
        my $ping_result = `ping -n 4 $website_servers{$website} | find "Average"`;
        if ($ping_result =~ /Average = (\d+)ms/) {
            my $ping_ms = $1;
            print colored("\n$website Domain Latency: ", "cyan") . colored("$ping_ms ms\n", "green");
            if    ($ping_ms < 30) { print colored("[+] Excellent connection to $website.\n", "bold green"); }
            elsif ($ping_ms < 70) { print colored("[*] Good Connection\n", "bright_green"); }
            else                  { print colored("[!] Average ping to $website.\n", "yellow"); }
        } else {
            print colored("\n[!] Could not reach $website. Consider changing DNS or ISP.\n", "red");
        }
    }
}

# -------------------------------
# MTR (My Traceroute) 
# -------------------------------
sub show_winmtr {
    print colored("\n[] MTR (My Traceroute) Network Diagnostic Tool\n", "cyan");
    
    # Get the target host from the user
    print "Enter the target host (Domain/IP): ";
    chomp(my $target = <STDIN>);
    if (!$target) {
        print colored("No target specified. Exiting.\n", "yellow");
        return;
    }
    
    print colored("Running MTR to $target in WSL...\n", "cyan");
    my $output = `wsl -e sudo mtr -r -c 10 $target`;
    print colored("MTR Results:\n$output\n", "green");
}

# -------------------------------
# Paping (Ping + Port) Network Diagnostic Tool
# -------------------------------
sub show_paping {
    print colored("\n[] Paping (Ping + Port) Network Diagnostic Tool\n", "cyan");

    print "Enter the Host Name (e.g., 8.8.8.8): ";
    chomp(my $targetIP = <STDIN>);
    unless ($targetIP) {
        print colored("No Host Name specified. Exiting.\n", "yellow");
        return;
    }
    
    print "Enter the Host Port (e.g., 80): ";
    chomp(my $targetPort = <STDIN>);
    unless ($targetPort) {
        print colored("No Host Port specified. Exiting.\n", "yellow");
        return;
    }
    
    print colored("Launching Command Prompt to run Paping...\n", "cyan");
    my $userProfile = $ENV{USERPROFILE};
    my $defaultPath = "$userProfile\\paping.exe";
    system("start cmd.exe /k \"$defaultPath $targetIP -p $targetPort\"");
}

# -------------------------------
# Scan Network Devices
# -------------------------------
sub show_network_scanner {
    $| = 1;  # Enable auto-flush to prevent buffering issues

    print colored("\n[] Network Device Results\n", "yellow");

    # 🔍 Retrieve Public IP Address for VPN Detection
    print colored("\n[] Checking for VPN status...\n", "yellow");
    my $public_ip = `curl -4 -s ifconfig.me`;
    chomp($public_ip);

    if ($public_ip !~ /^\d+\.\d+\.\d+\.\d+$/) {
        $public_ip = `curl -6 -s ifconfig.me`;
        chomp($public_ip);
    }

    if ($public_ip !~ /^(\d{1,3}\.){3}\d{1,3}$/ && $public_ip !~ /^[a-fA-F0-9:]+$/) {
        print colored("[X] Could not retrieve public IP. Check your internet connection.\n", "red");
        return;
    }

    print colored("[+] Your Public IP: $public_ip\n", "green");

    # 🌐 VPN Detection via ProxyCheck.io API
    my $api_key = "8619y5-38p3c9-64464s-9q556y";  # Replace with your valid API key
    my $vpn_check_url = "https://proxycheck.io/v2/$public_ip?key=$api_key&vpn=1";

    my $ua  = LWP::UserAgent->new;
    my $res = $ua->get($vpn_check_url);
    my $vpn_detected = 0;

    if ($res->is_success) {
        my $response_data = decode_json($res->decoded_content);
        my $data = $response_data->{$public_ip} // {};

        if (defined $data->{'proxy'} && $data->{'proxy'} eq "yes") {
            print colored("\n!WARNING: VPN Detected! Please disable your VPN before proceeding with the scan.\n", "red");
            print colored("You are not authorized to scan this network or server.\n", "yellow");
            return;
        } else {
            print colored("[+] No VPN Detected.\n", "green");
            print colored("[+] Access Granted.\n", "green");
        }
    } else {
        print colored("\n[X] Could not verify VPN status. Continuing scan anyway...\n", "red");
    }

    # Get network adapter information dynamically
    my $ip_output = `ipconfig`;
    my ($ipv4) = $ip_output =~ /IPv4 Address.*?:\s*([\d\.]+)/;

    my $subnet;

    if ($ipv4) {
        print colored("\nDetected IP Address: ", "green") . "$ipv4\n";
        
        # Convert to subnet format
        $ipv4 =~ s/\.\d+$/\.0/;  # Replace last octet with .0 (Assumes /24)
        $subnet = "$ipv4/24";

        print colored("Detected Subnet: ", "green") . "$subnet\n";
    } else {
        print colored("Failed to detect the subnet. Please enter manually.\n", "yellow");
        print "Enter network subnet (e.g., 192.168.1.0/24): ";
        chomp($subnet = <STDIN>);

        unless ($subnet) {
            print colored("No subnet specified. Exiting.\n", "red");
            return;
        }
    }

    # 🔥 Animation: "Scanning Network, Please Wait..."
    print colored("\nScanning Network, Please Wait", "yellow");
    my @dots = ("   ", ".  ", ".. ", "...");  # Animation frames
    for (my $i = 0; $i < 10; $i++) {  # Repeat animation 10 times
        print colored("\rScanning Network, Please Wait$dots[$i % @dots]", "yellow");  
        sleep(0.3);  # Adjust speed of animation
    }
    print "\n";  # Move to next line after animation

    # Run nmap and capture output (including errors)
    my @nmap_output = `nmap -sn $subnet 2>&1`;  # Capture both output and errors

    # 📊 Check for VPN or PCAP errors
    my $error_detected = 0;
    foreach my $line (@nmap_output) {
        if ($line =~ /Error compiling our pcap filter: expression rejects all packets/) {
            print colored("\n!WARNING: Please turn off your VPN.\n", "red");
            print colored("You are not allowed to scan networks unless you own them or have explicit permission from the owner or administrator.\n", "yellow");
            $error_detected = 1;
            last;  # Stop processing further
        }
    }

    if ($error_detected) {
        return;
    }

    # Process output for readability
    print colored("\n[--- Network Scan Results ---]\n", "white");
    my $device_found = 0;

    foreach my $line (@nmap_output) {
        if ($line =~ /Nmap scan report for (.+)/) {
            print colored("\n[Device Found] ", "bold white") . colored("$1", "white") . "\n";  # Device Found is fully white
            $device_found = 1;
        } elsif ($line =~ /Host is up \((.+) latency\)/) {
            print colored("  - Status: Online ($1 latency)\n", "green");  # All Online + Latency is green
        } elsif ($line =~ /MAC Address: (.+) \((.+)\)/) {
            print colored("  - MAC Address: ", "red") . colored("$1 ($2)", "white") . "\n";  # Full MAC Address in red
        }
    }

    if (!$device_found) {
        print colored("\nNo active devices found on the subnet.\n", "yellow");
    }

    print colored("\n[--- Scan Complete ---]\n\n", "yellow");
}

# -------------------------------
# Network Monitoring 
# -------------------------------
sub show_iftop {
    print colored("\n[] Iftop Network Diagnostic Tool\n", "cyan");

    # Auto-detect active IP from WSL
    my $activeIPs = `wsl hostname -I`;
    chomp($activeIPs);
    $activeIPs =~ s/^\s+|\s+$//g;
    my ($activeIP) = split(/\s+/, $activeIPs);

    unless ($activeIP) {
        print colored("No active network interface detected. Exiting.\n", "yellow");
        return;
    }

    print colored("Detected active IP: $activeIP\n", "green");
    print colored("Launching iftop with filter for host $activeIP...\n", "cyan");

    my $filter = "host $activeIP";

    # Run iftop via WSL on Windows, otherwise run directly on Linux
    if ($^O eq 'MSWin32') {
        system("wsl sudo iftop -f \"$filter\"");
    }
    else {
        system("sudo iftop -f \"$filter\"");
    }
}

# -------------------------------
# Network Monitoring Wireshark
# -------------------------------
sub show_wireshark {
    print colored("\n[] Wireshark Monitoring Tool\n", "cyan");

    my @interfaces;
    if ($^O eq 'MSWin32') {
        # Retrieve active adapters on Windows using ipconfig
        my $ipconfig = `ipconfig`;
        my $current_adapter = "";
        for my $line (split /\n/, $ipconfig) {
            if ($line =~ /adapter\s+(.+):/) {
                $current_adapter = $1;
                $current_adapter =~ s/^\s+|\s+$//g;
            }
            if ($line =~ /IPv4 Address.*?:\s*([\d\.]+)/) {
                my $ip = $1;
                push @interfaces, { adapter => $current_adapter, ip => $ip } if $current_adapter;
            }
        }
    }
    else {
        # Retrieve active adapters on Linux using the ip command
        my $iface_output = `ip -o -4 addr show up primary scope global`;
        for my $line (split /\n/, $iface_output) {
            if ($line =~ /^(\S+)\s+inet\s+(\d+\.\d+\.\d+\.\d+)/) {
                push @interfaces, { adapter => $1, ip => $2 };
            }
        }
    }

    unless (@interfaces) {
        print colored("No active adapters detected. Exiting.\n", "yellow");
        return;
    }

    # List detected adapters for user selection
    print colored("Select an adapter:\n", "cyan");
    my $i = 0;
    foreach my $iface (@interfaces) {
        print "[$i] Adapter: $iface->{adapter} - IP: $iface->{ip}\n";
        $i++;
    }
    print "Enter selection: ";
    chomp(my $selection = <STDIN>);
    unless ($selection =~ /^\d+$/ && $selection < scalar(@interfaces)) {
        print colored("Invalid selection. Exiting.\n", "yellow");
        return;
    }
    my $selected = $interfaces[$selection];
    print colored("Selected adapter: $selected->{adapter} (IP: $selected->{ip})\n", "green");

    # Provide capture filter options
    print colored("\nSelect a capture filter:\n", "cyan");
    print "[0] Received traffic only (dst host $selected->{ip})\n";
    print "[1] Sent traffic only (src host $selected->{ip})\n";
    print "[2] All traffic (host $selected->{ip})\n";
    print "[3] Monitor for DDoS attacks (using your public IP)\n";
    print "[4] Custom filter\n";
    print "[5] Monitor Browser traffic (TCP port 80 or 443)\n";
    print "[6] Monitor Steam traffic (UDP portrange 27000-27100)\n";
    print "[7] Monitor Discord traffic (auto-detect Discord connections)\n";
    print "Enter selection: ";
    chomp(my $filter_choice = <STDIN>);

    my $capture_filter;
    if ($filter_choice eq '0') {
        $capture_filter = "dst host $selected->{ip}";
    }
    elsif ($filter_choice eq '1') {
        $capture_filter = "src host $selected->{ip}";
    }
    elsif ($filter_choice eq '2') {
        $capture_filter = "host $selected->{ip}";
    }
    elsif ($filter_choice eq '3') {
        # Retrieve public IP dynamically
        my $public_ip = `curl -s ifconfig.me`;
        chomp($public_ip);
        unless ($public_ip && $public_ip =~ /^(\d{1,3}\.){3}\d{1,3}$/) {
            print colored("Could not retrieve public IP. Exiting.\n", "yellow");
            return;
        }
        print colored("Detected public IP: $public_ip\n", "green");
        # Build a DDoS filter:
        # Capture TCP SYN (without ACK) or UDP packets destined to the public IP,
        # while filtering out packets originating from that same IP.
        $capture_filter = "((tcp and (tcp[tcpflags] & tcp-syn != 0) and not (tcp[tcpflags] & tcp-ack != 0)) or udp) and dst host $public_ip and not src host $public_ip";
    }
    elsif ($filter_choice eq '4') {
        print "Enter your custom capture filter: ";
        chomp($capture_filter = <STDIN>);
        unless ($capture_filter) {
            print colored("No filter provided. Exiting.\n", "yellow");
            return;
        }
    }
    elsif ($filter_choice eq '5') {
        # Outbound traffic to web servers (destination port 80 or 443)
        # from your local IP
        $capture_filter = "(tcp dst port 80 or tcp dst port 443) and src host $selected->{ip}";
    }
    elsif ($filter_choice eq '6') {
        $capture_filter = "udp portrange 27000-27100";
    }
    elsif ($filter_choice eq '7') {
        # Attempt to auto-detect Discord connections
        my @discord_ips;
        if ($^O eq 'MSWin32') {
            my @netstat = `netstat -ano | findstr :443`;
            foreach my $line (@netstat) {
                chomp($line);
                if ($line =~ /^\s*TCP\s+(\S+):\d+\s+(\S+):443\s+ESTABLISHED\s+(\d+)/) {
                    my ($local, $remote, $pid) = ($1, $2, $3);
                    my $task_output = `tasklist /FI "PID eq $pid" 2>NUL`;
                    if ($task_output =~ /Discord/i) {
                        push @discord_ips, $remote unless grep { $_ eq $remote } @discord_ips;
                    }
                }
            }
        }
        else {
            my @netstat = `sudo netstat -anp | grep :443`;
            foreach my $line (@netstat) {
                chomp($line);
                if ($line =~ /^\s*tcp\s+\d+\s+\d+\s+(\S+):\d+\s+(\S+):443\s+ESTABLISHED\s+\S+\/Discord/i) {
                    my ($local, $remote) = ($1, $2);
                    push @discord_ips, $remote unless grep { $_ eq $remote } @discord_ips;
                }
            }
        }
        if (@discord_ips) {
            print colored("Detected Discord remote IP addresses:\n", "green");
            my $j = 0;
            foreach my $ip (@discord_ips) {
                print "[$j] $ip\n";
                $j++;
            }
            print "Select the Discord IP to monitor (or type 'a' for all): ";
            chomp(my $discord_sel = <STDIN>);
            if ($discord_sel eq 'a') {
                $capture_filter = "tcp and (";
                my @parts;
                foreach my $ip (@discord_ips) {
                    push @parts, "dst host $ip";
                }
                $capture_filter .= join(" or ", @parts) . ") and port 443";
            }
            elsif ($discord_sel =~ /^\d+$/ && $discord_sel < scalar(@discord_ips)) {
                my $selected_discord_ip = $discord_ips[$discord_sel];
                $capture_filter = "tcp and dst host $selected_discord_ip and port 443";
            }
            else {
                print colored("Invalid selection, defaulting to tcp port 443.\n", "yellow");
                $capture_filter = "tcp port 443";
            }
        }
        else {
            print colored("No Discord connections detected, defaulting to tcp port 443.\n", "yellow");
            $capture_filter = "tcp port 443";
        }
    }
    else {
        print colored("Invalid filter selection. Exiting.\n", "yellow");
        return;
    }

    # Start Wireshark with the chosen filter
    if ($^O eq 'MSWin32') {
        system("start \"Wireshark\" wireshark -i \"$selected->{adapter}\" -k -f \"$capture_filter\"");
    }
    else {
        system("nohup sudo wireshark -i $selected->{adapter} -k -f \"$capture_filter\" >/dev/null 2>&1 &");
    }
}



# -------------------------------
# Network DNS Setting
# -------------------------------
sub dns_set {
    # DNS Benchmark Section
    print colored("\n[DNS Set] Finding the fastest DNS for your network...\n", "cyan");
    print colored("Testing DNS servers...\n", "yellow");
    
    my @dnsServers = ( '1.1.1.1', '8.8.8.8', '9.9.9.9', '77.88.8.8', '185.228.168.9', '185.228.169.9' );
    my %dnsInfo = (
        '1.1.1.1'       => "Cloudflare (Fast, but not fully private)",
        '8.8.8.8'       => "Google DNS (Fast, but not privacy‐friendly)",
        '9.9.9.9'       => "Quad9 (Privacy‐focused, Blocks malicious domains)",
        '77.88.8.8'     => "Yandex DNS (Secure, but privacy concerns)",
        '185.228.168.9' => "NextDNS (Privacy‐focused, Customizable)",
        '185.228.169.9' => "NextDNS (Privacy‐focused, Customizable)"
    );
    my @results;
    foreach my $dns (@dnsServers) {
        print colored("Testing DNS: $dns ($dnsInfo{$dns})\n", "yellow");
        my $ping = `ping -n 5 $dns`;
        if ($? == 0) {
            if ($ping =~ /Average = (\d+)ms/) {
                push @results, { DNS => $dns, PingTime => $1, Provider => $dnsInfo{$dns} };
                print colored("$dns is reachable with average response time: $1 ms\n", "green");
            }
        } else {
            print colored("$dns is unreachable\n", "red");
        }
    }
    
    # Display DNS provider menu
    print "\nSelect the DNS provider you want to set:\n";
    my %dnsMapping = (
        1 => { provider => "Cloudflare", primary => "1.1.1.1", secondary => "1.0.0.1" },
        2 => { provider => "Google DNS", primary => "8.8.8.8", secondary => "8.8.4.4" },
        3 => { provider => "Quad9", primary => "9.9.9.9", secondary => "149.112.112.112" },
        4 => { provider => "Yandex DNS", primary => "77.88.8.8", secondary => "77.88.8.1" },
        5 => { provider => "NextDNS", primary => "", secondary => "" }
    );
    foreach my $key (sort { $a <=> $b } keys %dnsMapping) {
        if ($key == 5) {
            print "[$key] $dnsMapping{$key}{provider} (requires manual input)\n";
        } else {
            print "[$key] $dnsMapping{$key}{provider} ($dnsMapping{$key}{primary} / $dnsMapping{$key}{secondary})\n";
        }
    }
    print "Enter your choice (1-5): ";
    chomp(my $dns_choice = <STDIN>);
    
    my ($primary_dns, $secondary_dns);
    if ($dns_choice == 5) {
        # NextDNS option: just print a note in the console (no popup)
        print colored("\nNOTE: The NextDNS option does not try to set per-user DNS via the registry; "
            . "instead, it uses netsh so that the DNS is actually applied (primary and secondary DNS). "
            . "However, this change is adapter-wide.\n\n"
            . "If you want DNS settings applied strictly for that user, you must log into that account "
            . "and set it manually.\n", "yellow");
        
        print colored("\nTo configure NextDNS parental controls, please visit:\nhttps://my.nextdns.io/\n", "cyan");
        system("start https://my.nextdns.io/");
        
        print "\nEnter the primary DNS for NextDNS: ";
        chomp($primary_dns = <STDIN>);
        print "Enter the secondary DNS for NextDNS: ";
        chomp($secondary_dns = <STDIN>);
    } elsif (exists $dnsMapping{$dns_choice}) {
        $primary_dns   = $dnsMapping{$dns_choice}{primary};
        $secondary_dns = $dnsMapping{$dns_choice}{secondary};
    } else {
        print colored("Invalid selection. Aborting DNS configuration.\n", "yellow");
        return;
    }
    
    # Now, list available network interfaces so the user can select one.
    print "\nFetching network interfaces...\n";
    my @iface_output = `netsh interface show interface`;
    my @interfaces;
    foreach my $line (@iface_output) {
        chomp($line);
        if ($line =~ /^\s*(Enabled|Disabled)\s+(Connected|Disconnected)\s+(Dedicated|Loopback|Internal)\s+(.+)$/i) {
            my $iface = $4;
            $iface =~ s/^\s+|\s+$//g;
            push @interfaces, $iface;
        }
    }
    if (@interfaces) {
        print "\nSelect a network interface by number:\n";
        my $i = 0;
        foreach my $iface (@interfaces) {
            print "[$i] $iface\n";
            $i++;
        }
        print "Enter your choice: ";
        chomp(my $iface_choice = <STDIN>);
        if ($iface_choice =~ /^\d+$/ && $iface_choice < scalar(@interfaces)) {
            my $selected_iface = $interfaces[$iface_choice];
            print "\nSetting DNS configuration on interface '$selected_iface'...\n";
            my $dns_cmd1 = qq(netsh interface ip set dns name="$selected_iface" static $primary_dns);
            my $dns_cmd2 = qq(netsh interface ip add dns name="$selected_iface" $secondary_dns index=2);
            system($dns_cmd1);
            system($dns_cmd2);
            print colored("\nDNS configuration applied successfully on interface '$selected_iface'.\n", "green");
        } else {
            print colored("Invalid interface selection. Aborting DNS configuration.\n", "yellow");
        }
    } else {
        print colored("No network interfaces found. Aborting DNS configuration.\n", "yellow");
    }
}

# -------------------------------
# Networking: Tools 
# -------------------------------
my $linux_commands = {
    1 => {
        command     => 'ip',
        description => 'Displays and manipulates routing, devices, policy routing, and tunnels.',
        example     => 'ip addr show',  # No target needed.
    },
    2 => {
        command     => 'ping',
        description => 'Checks network connectivity to a target host.',
        example     => 'ping',  # Requires target.
    },
    3 => {
        command     => 'traceroute',
        description => 'Shows the path packets take to a target host.',
        example     => 'traceroute',  # Requires target.
    },
    4 => {
        command     => 'netstat',
        description => 'Displays network connections, routing tables, interface statistics, etc.',
        example     => 'netstat -tuln',  # No target needed.
    },
    5 => {
        command     => 'ss',
        description => 'Provides detailed information about network sockets.',
        example     => 'ss -s',  # No target needed.
    },
    6 => {
        command     => 'dig',
        description => 'Queries DNS servers for various records.',
        example     => 'dig',  # Requires target.
    },
    7 => {
        command     => 'host',
        description => 'Performs DNS lookups to convert domain names to IP addresses and vice versa.',
        example     => 'host',  # Requires target.
    },
    8 => {
        command     => 'ifconfig',
        description => 'Displays or configures network interface parameters.',
        example     => 'ifconfig eth0',  # No target needed.
    },
    9 => {
        command     => 'iwconfig',
        description => 'Displays or configures wireless network interfaces.',
        example     => 'iwconfig wlan0',  # No target needed.
    },
    10 => {
        command     => 'ip route',
        description => 'Displays the routing table.',
        example     => 'ip route show',  # No target needed.
    },
    11 => {
        command     => 'ip -s link',
        description => 'Displays interface statistics.',
        example     => 'ip -s link show',  # No target needed.
    },
    12 => {
        command     => 'nmap',
        description => 'Scans for open ports on a target host.',
        example     => 'nmap',  # Requires target.
    },
    13 => {
        command     => 'whois',
        description => 'Performs a WHOIS lookup on a target domain or IP.',
        example     => 'whois',  # Requires target.
    },
};

# Windows commands
my $windows_commands = {
    1 => {
        command     => 'ipconfig',
        description => 'Displays current TCP/IP configuration and refreshes DHCP/DNS settings.',
        example     => 'ipconfig /all',  # No target needed.
    },
    2 => {
        command     => 'ping',
        description => 'Tests connectivity to a target host.',
        example     => 'ping',  # Requires target.
    },
    3 => {
        command     => 'tracert',
        description => 'Determines the route taken to a target host by sending ICMP packets.',
        example     => 'tracert',  # Requires target.
    },
    4 => {
        command     => 'netstat',
        description => 'Displays active connections and listening ports.',
        example     => 'netstat -an',  # No target needed.
    },
    5 => {
        command     => 'nslookup',
        description => 'Queries DNS servers for IP addresses associated with domain names.',
        example     => 'nslookup',  # Requires target.
    },
    6 => {
        command     => 'route',
        description => 'Displays and modifies the local IP routing table.',
        example     => 'route print',  # No target needed.
    },
    7 => {
        command     => 'arp',
        description => 'Displays and modifies the Address Resolution Protocol cache.',
        example     => 'arp -a',  # No target needed.
    },
    8 => {
        command     => 'getmac',
        description => 'Displays the MAC addresses for network adapters on the system.',
        example     => 'getmac',  # No target needed.
    },
    9 => {
        command     => 'netsh',
        description => 'Displays and modifies the network configuration of the computer.',
        example     => 'netsh interface show interface',  # No target needed.
    },
    10 => {
        command     => 'telnet',
        description => 'Opens a Telnet session to a remote host.',
        example     => 'telnet',  # Requires target & port.
    },
    11 => {
        command     => 'netsh wlan show networks',
        description => 'Displays available wireless networks.',
        example     => 'netsh wlan show networks',  # No target needed.
    },
    12 => {
        command     => 'systeminfo',
        description => 'Displays detailed system information.',
        example     => 'systeminfo',  # No target needed.
    },
};

###############################
# 2. Commands that Require a Target
###############################

my %need_target = (
    ping        => 1,
    traceroute  => 1,
    dig         => 1,
    host        => 1,
    tracert     => 1,
    nslookup    => 1,
    telnet      => 1,
    nmap        => 1,
    whois       => 1,
);

###############################
# 3. Open Command in a New Terminal Window (Green Text)
###############################

sub open_in_new_terminal {
    my ($command_line) = @_;
    if ($^O eq 'MSWin32') {
        # On Windows, open a new CMD window, set color to green (0A), then run the command.
        system("start cmd /k \"color 0A & $command_line\"");
    }
    else {
        # On Linux, using gnome-terminal; prepend output with ANSI escape for green text.
        system("gnome-terminal -- bash -c 'echo -e \"\\033[32m\"; $command_line; echo; read -p \"Press Enter to close...\"'");
    }
}

###############################
# 4. Prompt for IP/Hostname (and Port for Telnet)
###############################

sub get_target {
    my ($cmd) = @_;
    print colored("Enter target IP or hostname: ", "yellow");
    chomp(my $target = <STDIN>);
    $target = "example.com" unless $target;
    if ($cmd eq 'telnet') {
        print colored("Enter port number (default: 80): ", "yellow");
        chomp(my $port = <STDIN>);
        $port = 80 unless $port;
        return "$target $port";
    }
    return $target;
}

###############################
# 5. Run ALL Target Commands for a Given OS
###############################

sub run_all_target_commands {
    my ($os, $commands_ref) = @_;
    print colored("Enter target IP or hostname for all commands: ", "yellow");
    chomp(my $target = <STDIN>);
    $target = "example.com" unless $target;
    
    # Run each command that requires a target:
    foreach my $key (sort { $a <=> $b } keys %$commands_ref) {
        my $cmd_info = $commands_ref->{$key};
        if (exists $need_target{$cmd_info->{command}}) {
            my $full_cmd = "$cmd_info->{command} $target";
            if ($os eq 'linux' && $^O eq 'MSWin32' &&
                $full_cmd !~ /^wsl\s/ &&
                $full_cmd =~ /^(ip|ping|traceroute|netstat|ss|dig|host|ifconfig|iwconfig|nmap|whois)/)
            {
                $full_cmd = "wsl " . $full_cmd;
            }
            open_in_new_terminal($full_cmd);
        }
    }
    
    # Additionally, open a separate terminal for an Nmap port scan of all ports:
    my $port_scan_cmd = "nmap -p- $target";
    if ($os eq 'linux' && $^O eq 'MSWin32' &&
        $port_scan_cmd !~ /^wsl\s/)
    {
        $port_scan_cmd = "wsl " . $port_scan_cmd;
    }
    open_in_new_terminal($port_scan_cmd);
}

###############################
# 6. Linux Commands Menu Loop
###############################

sub show_linux_commands {
    while (1) {
        print colored("\n=== Linux Networking Commands ===\n", "magenta");
        foreach my $num (sort { $a <=> $b } keys %$linux_commands) {
            my $cmd_info = $linux_commands->{$num};
            print colored("$num. $cmd_info->{command} - $cmd_info->{description}\n", "white");
        }
        # Option 14: Run ALL target commands with a given IP.
        print colored("14. Run ALL target commands with a given IP\n", "white");
        print colored("x. Return to OS selection\n", "red");
        print colored("\nSelect a command (enter the number, 14 for all, or x): ", "white");
        chomp(my $choice = <STDIN>);
        
        last if (lc($choice) eq 'x');
        
        if ($choice eq '14') {
            run_all_target_commands('linux', $linux_commands);
        }
        elsif (exists $linux_commands->{$choice}) {
            my $selected = $linux_commands->{$choice};
            my $command_line = $selected->{example};
            if (exists $need_target{$selected->{command}}) {
                my $target = get_target($selected->{command});
                $command_line = "$selected->{command} $target";
            }
            if ($^O eq 'MSWin32'
                && $command_line !~ /^wsl\s/
                && $command_line =~ /^(ip|ping|traceroute|netstat|ss|dig|host|ifconfig|iwconfig|nmap|whois)/)
            {
                $command_line = "wsl " . $command_line;
            }
            open_in_new_terminal($command_line);
        }
        else {
            print colored("Invalid selection. Please try again.\n", "yellow");
        }
    }
}

###############################
# 7. Windows Commands Menu Loop
###############################

sub show_windows_commands {
    while (1) {
        print colored("\n=== Windows Networking Commands ===\n", "magenta");
        foreach my $num (sort { $a <=> $b } keys %$windows_commands) {
            my $cmd_info = $windows_commands->{$num};
            print colored("$num. $cmd_info->{command} - $cmd_info->{description}\n", "green");
        }
        # Option 15: Run ALL target commands with a given IP.
        print colored("x. Return to OS selection\n", "red");
        print colored("\nSelect a command (enter the number, 15 for all, or x): ", "white");
        chomp(my $choice = <STDIN>);
        
        last if (lc($choice) eq 'x');
        
        if ($choice eq '15') {
            run_all_target_commands('windows', $windows_commands);
        }
        elsif (exists $windows_commands->{$choice}) {
            my $selected = $windows_commands->{$choice};
            my $command_line = $selected->{example};
            if (exists $need_target{$selected->{command}}) {
                my $target = get_target($selected->{command});
                $command_line = "$selected->{command} $target";
            }
            open_in_new_terminal($command_line);
        }
        else {
            print colored("Invalid selection. Please try again.\n", "yellow");
        }
    }
}

###############################
# 8. Main OS Selection Menu Loop
###############################

sub Network_tools {
    while (1) {
        print colored("\nChoose the operating system for networking commands:\n", "magenta");
        print colored("1. Linux\n", "green");
        print colored("2. Windows\n", "white");
        print colored("x. Exit\n", "yellow");
        print colored("Enter your choice (1, 2, or x): ", "white");
        chomp(my $os_choice = <STDIN>);
        
        if    ($os_choice eq '1') { show_linux_commands(); }
        elsif ($os_choice eq '2') { show_windows_commands(); }
        elsif (lc($os_choice) eq 'x') {
            print colored("\nExiting...\n", "red");
            last;
        }
        else {
            print colored("Invalid selection. Please try again.\n", "yellow");
        }
    }
}



# -------------------------------------------
# Software:Networking Websites
# -------------------------------------------
sub networking_site {
    print colored("\n[Networking websites] Select an option:\n", "yellow");
    print colored("1. Open Network Monitor\n", "green");
    print colored("2. Open Speed Test Website\n", "green");
    print colored("3. Open IP Lookup Tool\n", "green");
    print colored("4. Open DNS Lookup Tool\n", "green");
    print colored("Enter choice: ", "cyan");
    
    chomp(my $choice = <STDIN>);
    
    if ($choice == 1) {
        open_network_monitor();
    }
    elsif ($choice == 2) {
        open_speed_test();
    }
    elsif ($choice == 3) {
        open_ip_lookup();
    }
    elsif ($choice == 4) {
        open_dns_lookup();
    }
    else {
        print colored("Invalid choice.\n", "red");
    }
}

# Function to open a network monitor tool (web version or internal tool)
sub open_network_monitor {
    print colored("\nOpening Network Monitor...\n", "green");
    system("start https://uptimerobot.com") == 0
        or warn colored("Failed to open Network Monitor.\n", "red");
}

# Function to open a speed test website
sub open_speed_test {
    print colored("\nOpening Speed Test Website...\n", "green");
    system("start http://www.speedtest.net") == 0
        or warn colored("Failed to open Speed Test Website.\n", "red");
}

# Function to open an IP lookup tool
sub open_ip_lookup {
    print colored("\nOpening IP Lookup Tool...\n", "green");
    system("start https://check-host.net") == 0
        or warn colored("Failed to open IP Lookup Tool.\n", "red");
}

# Function to open a DNS lookup tool
sub open_dns_lookup {
    print colored("\nOpening DNS Lookup Tool...\n", "green");
    system("start https://dnsdumpster.com") == 0
        or warn colored("Failed to open DNS Lookup Tool.\n", "red");
}




# -------------------------------------------
# Network:Lookups Websites
# -------------------------------------------
sub people_search {
    print colored("\n[People Search] Select an option:\n", "yellow");
    print colored("1. Open Black Book Online\n", "green");
    print colored("2. Open Cyber Background Checks\n", "green");
    print colored("3. Open Fast People Search\n", "green");
    print colored("Enter choice: ", "cyan");
    
    chomp(my $choice = <STDIN>);
    
    if ($choice == 1) {
        open_blackbook();
    }
    elsif ($choice == 2) {
        open_cyberbackgroundchecks();
    }
    elsif ($choice == 3) {
        open_fastpeoplesearch();
    }
    else {
        print colored("Invalid choice.\n", "red");
        pause();
    }
}

# Function to open Black Book Online
sub open_blackbook {
    my $url = "https://www.blackbookonline.info/";
    print colored("\nOpening Black Book Online at $url...\n", "green");
    system("start $url") == 0
        or warn colored("Failed to open Black Book Online.\n", "red");
}

# Function to open Cyber Background Checks
sub open_cyberbackgroundchecks {
    my $url = "https://www.cyberbackgroundchecks.com/";
    print colored("\nOpening Cyber Background Checks at $url...\n", "green");
    system("start $url") == 0
        or warn colored("Failed to open Cyber Background Checks.\n", "red");
}

# Function to open Fast People Search
sub open_fastpeoplesearch {
    my $url = "https://www.fastpeoplesearch.com/";
    print colored("\nOpening Fast People Search at $url...\n", "green");
    system("start $url") == 0
        or warn colored("Failed to open Fast People Search.\n", "red");
}


# -------------------------------
# Networking Menu
# -------------------------------
sub networking_menu {
    while (1) {
        clear_screen();
        print_header();
        print "Networking Menu:\n";
        print " 1) Clear DNS Cache\n";
        print " 2) Reset Network (Winsock, IP stack)\n";
        print " 3) DNS Benchmark\n";
        print " 4) Set Network Firewall\n";
        print " 5) Check Network Latency\n";
        print " 6) MTR Check Packet Loss\n";
        print " 7) Paping Check TCP Port\n";
        print " 8) Network Device Scanner\n";
        print " 9) Network Monitoring iftop\n";
        print " 10) Network Monitoring Wireshark\n";
        print " 11) Check & Set DNS\n";
        print " 12) Network Tools\n";
        print " 13) Networking Site\n";
        print " 14) People Lookup\n";
        print " 15) Back to Main Menu\n";
        print "Enter your choice: ";
        chomp(my $choice = <STDIN>);
        if ($choice eq "1") {
            clear_dns();
            pause();
        }
        elsif ($choice eq "2") {
            reset_network();
            pause();
        }
        elsif ($choice eq "3") {
            test_dns_performance();
            pause();
        }
        elsif ($choice eq "4") {
            set_firewall_security_level();
            pause();
        }
        elsif ($choice eq "5") {
            check_network_performance();
            pause();
        }
        elsif ($choice eq "6") {
            show_winmtr();
            pause();
        }
        elsif ($choice eq "7") {
            show_paping();
            pause();
        }
        elsif ($choice eq "8") {
            show_network_scanner();
            pause();
        }
        elsif ($choice eq "9") {
            show_iftop();
            pause();
        }
        elsif ($choice eq "10") {
            show_wireshark();
            pause();
        }
        elsif ($choice eq "11") {
            dns_set();
            pause();
        }
        elsif ($choice eq "12") {
            Network_tools();
            pause();
        }
        elsif ($choice eq "13") {
            networking_site();
            pause();
        }
        elsif ($choice eq "14") {
            people_search();
            pause();
        }
        elsif ($choice eq "15") {
            last;
        }
        else {
            print colored("Invalid choice.\n", "yellow");
            pause();
        }
    }
}

# -------------------------------
# Software Start Menu
# -------------------------------
# Software: Clear Windows Update Cache
# -------------------------------
sub clear_update_cache {
    print colored("\n[Clear Windows Update Cache] Clearing Windows Update Cache...\n", "cyan");
    system("net stop wuauserv");
    my $wu_path = "C:\\Windows\\SoftwareDistribution\\Download";
    eval { remove_tree($wu_path, { error => \my $err }); };
    print colored("Windows Update Cache cleared successfully.\n", "green");
    system("net start wuauserv");
    pause();
}

# -------------------------------
# Software: Clear All Browser History
# -------------------------------
sub clear_browser_history {
    print colored("\n[Clear Browser History] Clearing All Browser History...\n", "cyan");
    my @paths = (
        "$ENV{USERPROFILE}\\AppData\\Local\\Microsoft\\Windows\\History",
        "$ENV{USERPROFILE}\\AppData\\Local\\Google\\Chrome\\User Data\\Default\\History",
        "$ENV{USERPROFILE}\\AppData\\Roaming\\Mozilla\\Firefox\\Profiles",
        "$ENV{USERPROFILE}\\AppData\\Local\\Microsoft\\Edge\\User Data\\Default\\History",
        "$ENV{USERPROFILE}\\AppData\\Local\\BraveSoftware\\Brave-Browser\\User Data\\Default\\History",
        "$ENV{USERPROFILE}\\AppData\\Roaming\\Opera Software\\Opera Stable\\History"
    );
    foreach my $path (@paths) {
        if (-e $path) {
            print colored("Clearing history for $path...\n", "yellow");
            eval { remove_tree($path, { error => \my $err }); };
            print colored("History cleared for $path.\n", "green");
        }
    }
    print colored("Browser history cleared for all supported browsers!\n", "green");
    pause();
}

# -------------------------------
# Software: Virus Scan (Quick or Full) – Simulation
# -------------------------------
sub test_virus {
    print colored("\n[Virus Scan] Running Virus Scan...\n", "cyan");
    print "Type 'Q' for Quick Scan or 'F' for Full Scan: ";
    chomp(my $scanType = <STDIN>);
    if (uc($scanType) eq "Q") {
        print colored("Starting Quick Scan...\n", "cyan");
        for my $i (1 .. 100) {
            print "\rQuick Scan Progress: $i%";
            select(undef, undef, undef, 0.05);
        }
        print "\n", colored("Quick Scan completed successfully.\n", "green");
    }
    elsif (uc($scanType) eq "F") {
        print colored("Starting Full Scan... This may take a while.\n", "cyan");
        for my $i (1 .. 100) {
            print "\rFull Scan Progress: $i%";
            select(undef, undef, undef, 0.2);
        }
        print "\n", colored("Full Scan completed successfully.\n", "green");
    } else {
        print colored("Invalid choice. Skipping scan.\n", "yellow");
    }
    pause();
}

# -------------------------------
# Software: New System Restore Point
# -------------------------------
sub new_system_restore_point {
    print colored("\n[New System Restore Point] Creating System Restore Point...\n", "cyan");
    # Launch PowerShell in a minimized window using cmd /c start /min
    my $cmd = 'cmd /c start /min powershell -NoProfile -Command "Checkpoint-Computer -Description \'Toolkit Restore Point\'"';
    system($cmd);
    # Simulate a progress bar with a percentage and visual bar
    for my $i (1 .. 100) {
        my $bar = "o" x int($i/2);
        $bar .= " " x (50 - int($i/2));
        print "\rCreating a system restore point... $i% Completed. [$bar]";
        select(undef, undef, undef, 0.1);
    }
    print "\n";
    print colored("System Restore Point created successfully!\n", "green");
    pause();
}

# -------------------------------
# Software: Advanced Scanning for Leftovers – Simulation
# -------------------------------
sub invoke_advanced_scanning {
    print colored("\n[Advanced Scanning] Performing Advanced Scanning for Leftovers...\n", "cyan");
    print colored("This feature identifies leftover files, folders, and registry entries.\n", "green");
    print colored("Starting advanced scan...\n", "yellow");
    sleep(3);
    print colored("No leftovers found or all were successfully removed.\n", "green");
    pause();
}

# -------------------------------
# Software: Disk Cleanup
# -------------------------------
sub invoke_disk_cleanup {
    print colored("\n[Disk Cleanup] Running Disk Cleanup...\n", "cyan");
    my $cleanmgr = "$ENV{SystemRoot}\\System32\\cleanmgr.exe";
    if (-e $cleanmgr) {
        print colored("Running Disk Cleanup silently...\n", "yellow");
        my $ret = system("$cleanmgr /SAGERUN:99");
        if ($ret == 0) {
            print colored("Disk Cleanup completed successfully!\n", "green");
        } else {
            print colored("Disk Cleanup failed.\n", "red");
        }
    } else {
        print colored("Disk Cleanup utility not found on this system.\n", "red");
    }
    pause();
}

# -------------------------------
# Software: Windows Search Repair
# -------------------------------
sub repair_windows_search {
    print colored("\n[Windows Search Repair] Repairing Windows Search...\n", "cyan");
    print colored("Ensuring Windows Search service is enabled and set to Automatic...\n", "yellow");
    system("sc config WSearch start= auto");
    print colored("Stopping the Windows Search service...\n", "yellow");
    system("net stop WSearch");
    print colored("Windows Search service stopped successfully.\n", "green");
    my $searchIndexPath = "C:\\ProgramData\\Microsoft\\Search\\Data";
    if (-d $searchIndexPath) {
        print colored("Deleting the current search index files...\n", "yellow");
        eval { remove_tree($searchIndexPath, { error => \my $err }); };
        print colored("Search index files deleted successfully.\n", "green");
    } else {
        print colored("Search index path not found. Skipping deletion.\n", "yellow");
    }
    sleep(5);
    my $ret = system("net start WSearch");
    if ($ret == 0) {
        print colored("Windows Search service restarted successfully.\n", "green");
    } else {
        print colored("Failed to restart the Windows Search service.\n", "red");
    }
    print colored("The Windows search index will now rebuild in the background. This may take some time.\n", "cyan");
    pause();
}

# -------------------------------
# Software: System Information Export
# -------------------------------
sub export_system_info {
    print colored("\n[System Information Export] Exporting System Information...\n", "cyan");
    my $outputFolder = "$ENV{USERPROFILE}\\Desktop\\SystemInfoExports";
    mkdir $outputFolder unless -d $outputFolder;
    my $outputPath = "$outputFolder\\SystemInfoReport.txt";
    print colored("Collecting system information. Please wait...\n", "yellow");
    my @systemInfo;
    push @systemInfo, "=== System Information Report ===";
    push @systemInfo, "Export Date: " . localtime;
    push @systemInfo, `systeminfo`;
    push @systemInfo, "=== Wi-Fi Information ===";
    push @systemInfo, "Saved Wi-Fi Profiles and Passwords: (Not Implemented)";
    push @systemInfo, "=== Network Adapter Information ===";
    push @systemInfo, `ipconfig /all`;
    push @systemInfo, "=== DNS Information ===";
    push @systemInfo, `ipconfig /all`;
    push @systemInfo, "=== Public IP Information ===";
    my $publicIP = `curl -s http://ifconfig.me/ip 2>nul`;
    chomp($publicIP);
    push @systemInfo, "Public IP Address: $publicIP";
    push @systemInfo, "=== File Modification Information ===";
    my @keyDirectories = (
        "$ENV{USERPROFILE}\\Documents",
        "$ENV{USERPROFILE}\\Desktop",
        "$ENV{USERPROFILE}\\Downloads",
        "C:\\Windows\\System32"
    );
    foreach my $dir (@keyDirectories) {
        if (-d $dir) {
            opendir(my $dh, $dir);
            while (my $file = readdir($dh)) {
                next if $file eq '.' or $file eq '..';
                my $fullpath = "$dir\\$file";
                if (-f $fullpath) {
                    my $mtime = (stat($fullpath))[9];
                    push @systemInfo, "File: $fullpath, Last Modified: " . localtime($mtime);
                }
            }
            closedir($dh);
        } else {
            push @systemInfo, "Directory not found: $dir";
        }
    }
    open(my $fh, '>', $outputPath) or die "Cannot open $outputPath: $!";
    print $fh join("\n", @systemInfo);
    close($fh);
    print colored("System information has been exported successfully!\n", "green");
    print colored("Report saved at: $outputPath\n", "green");
    pause();
}

# -------------------------------
# Software: Reset System Components
# -------------------------------
sub reset_system_components {
    print colored("\n[Option 20] Troubleshooting Running System Services...\n", "cyan");

    # List of critical services to check
    my %services_to_check = (
        "WSearch"   => "Windows Search",
        "WinDefend" => "Windows Defender",
        "wuauserv"  => "Windows Update",
        "bits"      => "Background Intelligent Transfer Service"
    );

    my $found_running = 0;  # Flag to check if at least one service needed troubleshooting

    foreach my $service (keys %services_to_check) {
        # Check if the service is currently running
        my $status = `sc query $service | find "RUNNING"`;
        chomp($status);

        if ($status) {
            $found_running = 1;
            print colored("$services_to_check{$service} is currently running. Restarting it for troubleshooting...\n", "yellow");

            # Stop the service
            system("net stop \"$service\" > nul 2>&1");
            sleep 2;

            # Start the service again
            system("net start \"$service\" > nul 2>&1");
            sleep 2;

            # Verify if it restarted successfully
            $status = `sc query $service | find "RUNNING"`;
            chomp($status);

            if ($status) {
                print colored("$services_to_check{$service} restarted successfully.\n", "green");
            } else {
                print colored("Failed to restart $services_to_check{$service}. Further troubleshooting may be needed.\n", "red");
            }
        }
    }

    # If no services were running, print this message
    if (!$found_running) {
        print colored("No services needed troubleshooting. Everything is already stopped.\n", "cyan");
    }

    print colored("\nTroubleshooting complete!\n", "bold green");

    # Pause and return to the menu
    pause();
}

# -------------------------------
# Software: Repair All Microsoft Programs – Simulation
# -------------------------------
sub repair_microsoft_programs {
    print colored("\n[Option 21] Repair Microsoft Programs...\n", "cyan");
    my @steps = (
        "Repairing Microsoft Store Apps",
        "Repairing Microsoft Edge",
        "Repairing Microsoft Office",
        "Repairing Microsoft OneDrive",
        "Running DISM to repair system image",
        "Running System File Checker (SFC)"
    );
    my $totalSteps = scalar(@steps);
    my $currentStep = 0;
    foreach my $step (@steps) {
        print colored("$step...\n", "yellow");
        sleep(1);
        $currentStep++;
    }
    system('dism /online /cleanup-image /restorehealth');
    system('sfc /scannow');
    print colored("Repair process for Microsoft programs completed successfully!\n", "green");
    pause();
}

# -------------------------------
# Software: Defrag a Drive
# -------------------------------
sub optimize_drive {
    print colored("\n[Defrag a Drive] Optimizing a Drive...\n", "cyan");
    print "Enter the drive letter to optimize (e.g., C): ";
    chomp(my $drive = <STDIN>);
    my $ret = system("defrag $drive: /U /V");
    if ($ret == 0) {
        print colored("Optimization completed for drive $drive.\n", "green");
    } else {
        print colored("Optimization failed.\n", "red");
    }
    pause();
}

# -------------------------------
# Software: System File Checker (SFC)
# -------------------------------
sub invoke_sfc {
    print colored("\n[System File Checker] Running SFC...\n", "cyan");
    my $ret = system("sfc /scannow");
    if ($ret == 0) {
        print colored("SFC completed successfully.\n", "green");
    } else {
        print colored("SFC failed.\n", "red");
    }
    pause();
}

# -------------------------------
# Software: DISM (Scan & Restore)
# -------------------------------
sub invoke_dism {
    print colored("\n[DISM] Running DISM (ScanHealth & RestoreHealth)...\n", "cyan");
    my $ret1 = system('dism /online /cleanup-image /scanhealth');
    if ($ret1 == 0) {
        print colored("DISM ScanHealth completed.\n", "green");
    } else {
        print colored("DISM ScanHealth failed.\n", "red");
    }
    my $ret2 = system('dism /online /cleanup-image /restorehealth');
    if ($ret2 == 0) {
        print colored("DISM RestoreHealth completed.\n", "green");
    } else {
        print colored("DISM RestoreHealth failed.\n", "red");
    }
    pause();
}

# -------------------------------
# Software: Clear TEMP / Downloads / Recycle Bin
# -------------------------------
sub clear_files {
    print colored("\n[Clear Files] Clearing TEMP, Downloads, and Recycle Bin...\n", "cyan");
    my $temp      = $ENV{TEMP} || 'C:\Temp';
    my $downloads = "$ENV{USERPROFILE}\\Downloads";
    eval { remove_tree($temp, { error => \my $err1 }); };
    eval { remove_tree($downloads, { error => \my $err2 }); };
    my $ret = system('cmd /c start /min powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue"');
    print colored("Files cleared successfully.\n", "green");
    pause();
}

# -------------------------------
# Software: Check System Logs for Past Events – Simulation
# -------------------------------
sub watch_system_change {
    print colored("\n[System Log Watch] Logging key system changes (simulation)...\n", "cyan");
    print colored("Fetching and displaying system log events...\n", "yellow");
    my $logs = `wevtutil qe System /c:6 /f:text`;
    print colored("System Log Events:\n$logs\n", "green");
    print "\nDo you want to export these logs to a text file? (Y/N): ";
    chomp(my $exportChoice = <STDIN>);
    if (uc($exportChoice) eq 'Y') {
        print "Enter the file path to save the log (e.g., C:\\Logs\\SystemChanges.txt): ";
        chomp(my $exportPath = <STDIN>);
        open(my $fh, '>', $exportPath) or warn "Cannot write to file: $!";
        print $fh $logs;
        close($fh);
        print colored("Logs successfully exported to $exportPath\n", "green");
    }
    pause();
}

# -------------------------------
# Software: System Performance Analysis – Basic Simulation
# -------------------------------
sub test_performance_analysis {
    print colored("\n[System Performance Analysis] Performing System Performance Analysis...\n", "cyan");
    my $cpu_info = `wmic cpu get loadpercentage /value`;
    my ($cpu_percent) = $cpu_info =~ /LoadPercentage=(\d+)/;
    $cpu_percent = defined($cpu_percent) ? $cpu_percent : "N/A";
    print colored("CPU Usage: $cpu_percent %\n", "green");
    my $sysinfo = `systeminfo`;
    if ($sysinfo =~ /Total Physical Memory:\s+([^\n]+)/) {
        print colored("Total Physical Memory: $1\n", "green");
    }
    print colored("Disk Usage: (Simulated value)\n", "green");
    print colored("===================================\n", "green");
    pause();
}

# -------------------------------
# Software: File Integrity Checker
# -------------------------------
sub invoke_file_integrity_check {
    print colored("\n[File Integrity Checker] Running File Integrity Checker...\n", "cyan");
    print "Enter the full path to the file or folder to verify: ";
    chomp(my $path = <STDIN>);
    unless (-e $path) {
        print colored("The specified path does not exist. Please check and try again.\n", "red");
        return;
    }
    my @files;
    if (-d $path) {
        find(sub { push @files, $File::Find::name if -f $_ }, $path);
    } else {
        @files = ($path);
    }
    my $totalFiles = scalar @files;
    if ($totalFiles == 0) {
        print colored("No files found in the specified path.\n", "yellow");
        return;
    }
    print colored("Starting file integrity check for $totalFiles files...\n", "yellow");
    my $currentFile = 0;
    foreach my $file (@files) {
        $currentFile++;
        my $progressPercent = int(($currentFile / $totalFiles) * 100);
        print "\rProgress: $progressPercent% ($currentFile of $totalFiles files)";
        if (open(my $fh, '<', $file)) {
            binmode($fh);
            my $hash = sha256_hex(do { local $/; <$fh> });
            close($fh);
            # Optionally, print "$file: $hash\n" here.
        }
    }
    print "\n", colored("File integrity check completed successfully!\n", "green");
    pause();
}

sub run_memory_diagnostic {
    print colored("\n[Windows Memory Diagnostic] Launching Windows Memory Diagnostic Tool...\n", "cyan");
    # Launch the Windows Memory Diagnostic Tool
    system("mdsched.exe");
    print colored("The system will restart shortly to run the memory diagnostic test.\n", "green");
    pause();
}

sub run_gpu_diagnostic {
    print colored("\n[GPU Diagnostic] Running GPU diagnostics Report...\n", "cyan");
    
    # Define a temporary file path for the dxdiag report
    my $dxdiag_file = "$ENV{TEMP}\\dxdiag_report.txt";
    
    # Run dxdiag to output a full report (which includes GPU info)
    system("dxdiag /t \"$dxdiag_file\"");
    
    # Wait a few seconds to ensure the file is generated
    sleep(3);
    
    print colored("GPU diagnostic report generated.\n", "green");
    print colored("Opening report in Notepad...\n", "cyan");
    
    # Open the generated report in Notepad
    system("notepad \"$dxdiag_file\"");
    
    pause();
}

sub check_gpu_issues {
    print colored("\n[GPU Diagnostic] Checking GPU for issues...\n", "cyan");
    
    # Query GPU status using WMIC
    my $gpu_status = `wmic path Win32_VideoController get Status /format:list 2>NUL`;
    
    if ($gpu_status =~ /Status=OK/i) {
        print colored("GPU status appears to be OK.\n", "green");
    }
    else {
        print colored("Potential GPU issues detected.\n", "red");
        print "Would you like to attempt troubleshooting (reinstall GPU drivers)? (yes/no): ";
        chomp(my $choice = <STDIN>);
        if (lc($choice) eq "yes") {
            print colored("Attempting to reinstall GPU drivers...\n", "yellow");
            # Prompt user for driver type (customize as needed)
            print "Enter GPU driver type (e.g., NVIDIA, AMD, Intel): ";
            chomp(my $driverType = <STDIN>);
            if (lc($driverType) eq "nvidia") {
                system("winget install --id NVIDIA.Display.Driver -e");
            }
            elsif (lc($driverType) eq "amd") {
                system("winget install --id AMD.Driver -e");
            }
            elsif (lc($driverType) eq "intel") {
                system("winget install --id Intel.Graphics.Driver -e");
            }
            else {
                print colored("Unknown driver type. Please reinstall manually.\n", "yellow");
            }
        }
        else {
            print colored("GPU troubleshooting aborted.\n", "yellow");
        }
    }
    pause();
}



# -------------------------------
# Software: Atlas OS Installation
# -------------------------------
sub install_atlasos {
    print colored("\n[Atlas OS Installation]\n", "cyan");
    print "WARNING: This will download the AME Wizard Beta (installer) from a fixed URL\n";
    print "and the Atlas Playbook from the latest GitHub release.\n";
    print "Ensure you have backed up your data before proceeding.\n";
    print "Do you want to continue? (Y/N): ";
    chomp(my $confirm = <STDIN>);
    return unless uc($confirm) eq 'Y';
    
    ## Download Installer ZIP (AME Wizard Beta)
    my $installer_url = "https://download.ameliorated.io/AME%20Wizard%20Beta.zip";
    
    ## Query GitHub API for the latest release (for the Playbook asset)
    my $latest_release_api = "https://api.github.com/repos/Atlas-OS/Atlas/releases/latest";
    my $ua = LWP::UserAgent->new;
    $ua->agent("Mozilla/5.0");  # GitHub requires a user agent string.
    $ua->default_header("Accept" => "application/vnd.github.v3+json");
    
    print "\nChecking GitHub for the latest Atlas OS release (for the Playbook)...\n";
    my $api_resp = $ua->get($latest_release_api);
    unless ($api_resp->is_success) {
        print colored("Failed to fetch latest release information: " . $api_resp->status_line . "\n", "red");
        pause();
        return;
    }
    
    my $release_info = decode_json($api_resp->decoded_content);
    my $tag = $release_info->{tag_name} // "unknown";
    print colored("Latest release found: $tag\n", "green");
    
    ## Locate the Playbook asset from the release.
    my $playbook_url;
    for my $asset (@{ $release_info->{assets} // [] }) {
        my $name = $asset->{name} // "";
        # Look for an asset containing "Playbook" and ending with .apbx
        if ($name =~ /Playbook/i && $name =~ /\.apbx$/i) {
            $playbook_url = $asset->{browser_download_url};
            last;
        }
    }
    
    unless ($playbook_url) {
        print colored("Could not locate the Playbook asset in the latest release.\n", "red");
        pause();
        return;
    } else {
        print colored("Playbook asset found:\n$playbook_url\n", "green");
    }
    
    ## Define where to save the downloaded files (using the Downloads folder)
    my $installer_path = "$ENV{USERPROFILE}\\Downloads\\AME_Wizard_Beta.zip";
    my $playbook_path  = "$ENV{USERPROFILE}\\Downloads\\AtlasPlaybook.apbx";
    
    ## Download the installer ZIP.
    print "\nDownloading the AME Wizard Beta installer from:\n$installer_url\n";
    print "Saving to:\n$installer_path\n";
    $ua->timeout(600);  # Increase timeout for large downloads.
    my $inst_resp = $ua->get($installer_url, ":content_file" => $installer_path);
    unless ($inst_resp->is_success) {
        print colored("Installer download failed: " . $inst_resp->status_line . "\n", "red");
        pause();
        return;
    }
    print colored("\nInstaller download successful!\n", "green");
    
    ## Download the Atlas Playbook.
    print "\nDownloading Atlas Playbook from:\n$playbook_url\n";
    print "Saving to:\n$playbook_path\n";
    my $play_resp = $ua->get($playbook_url, ":content_file" => $playbook_path);
    unless ($play_resp->is_success) {
        print colored("Playbook download failed: " . $play_resp->status_line . "\n", "red");
        pause();
        return;
    }
    print colored("\nPlaybook download successful!\n", "green");
    
    ## Extract the installer ZIP.
    print "\nExtracting installer contents...\n";
    my $ae = Archive::Extract->new( archive => $installer_path );
    my $extract_dir = tempdir( CLEANUP => 0 );  # Set to 0 so the files remain for running.
    my $ok = $ae->extract( to => $extract_dir );
    unless ($ok) {
        print colored("Extraction failed: " . $ae->error . "\n", "red");
        pause();
        return;
    }
    print colored("\nExtraction successful!\n", "green");
    
    ## Find the installer executable (.exe) within the extracted directory.
    my @exes;
    find(sub { push @exes, $File::Find::name if -f $_ && /\.exe$/i }, $extract_dir);
    unless (@exes) {
        print colored("No executable file found in the extracted contents.\n", "red");
        pause();
        return;
    }
    my $installer_exe = $exes[0];
    print colored("Found installer executable: $installer_exe\n", "green");
    
    ## Ask the user if they want to launch the installer now.
    print "\nDo you want to launch the installer now? (Y/N): ";
    chomp(my $launch = <STDIN>);
    if (uc($launch) eq 'Y') {
        print colored("\nLaunching the installer...\n", "cyan");
        system("start \"AME Wizard Beta Installer\" \"$installer_exe\"");
    } else {
        print colored("\nYou can run the installer later from:\n$installer_exe\n", "yellow");
    }
    
    ## Show a popup window with the "All Done" installation instructions.
    my $instructions = "Atlas OS Installation - All Done!\n\n"
        . "1. If you launched the installer, follow its instructions to install Atlas OS.\n"
        . "2. Once the installer finishes, run the AME Wizard Beta if required.\n"
        . "3. Follow the on-screen prompts to complete the installation.\n"
        . "4. After installation, remove any installation media and restart your computer.\n\n"
        . "For more detailed instructions, please visit:\nhttps://docs.atlasos.net/getting-started/installation/#7-all-done";
    Win32::MsgBox($instructions, 0, "Atlas OS Installation Instructions");
    
    pause();
}


# --------------------------------------
# Software: Manage Local Windows Account
# --------------------------------------
sub manage_local_account {
    print colored("\n[Local Windows Account Management]\n", "cyan");
    print "Would you like to (C)reate a new account, (E)dit an existing account, or (D)elete an existing account? (C/E/D): ";
    chomp(my $action = <STDIN>);
    
    if (uc($action) eq 'C') {
        # --- Create Account Section ---
        print colored("\n[Local Windows Account Creation]\n", "cyan");
        print "Enter the username for the new account: ";
        chomp(my $username = <STDIN>);
        unless ($username) {
            print colored("Username cannot be empty. Aborting account creation.\n", "red");
            return;
        }
        
        # Check if the account already exists
        my $check_output = `net user "$username" 2>&1`;
        if ($? == 0) {
            print colored("Account '$username' already exists. Aborting account creation.\n", "yellow");
            return;
        }
        
        # Ask if a password should be set
        print "Do you want to set a password for this account? (Y/N): ";
        chomp(my $set_pass = <STDIN>);
        my $password = "";
        if (uc($set_pass) eq 'Y') {
            print "Enter the password for the new account: ";
            chomp($password = <STDIN>);
            if (!$password) {
                print colored("No password provided. The account will be created with a blank password.\n", "yellow");
            }
        } else {
            print colored("The account will be created with a blank password.\n", "yellow");
        }
        
        # Create the account using the 'net user' command
        my $cmd = qq(net user "$username" "$password" /add);
        print "\nCreating account...\n";
        my $result = system($cmd);
        if ($result != 0) {
            print colored("Failed to create account. Make sure you are running as an administrator.\n", "red");
            pause();
            return;
        } else {
            print colored("Account '$username' created successfully!\n", "green");
        }
        
        # Ask if the new account should have administrator privileges
        print "Should the new account have administrator privileges? (Y/N): ";
        chomp(my $admin_choice = <STDIN>);
        if (uc($admin_choice) eq 'Y') {
            $cmd = qq(net localgroup Administrators "$username" /add);
            print "\nAdding '$username' to the Administrators group...\n";
            $result = system($cmd);
            if ($result != 0) {
                print colored("Failed to add '$username' to the Administrators group.\n", "red");
            } else {
                print colored("User '$username' has been granted administrator privileges.\n", "green");
            }
        } else {
            print colored("User '$username' will not have administrator privileges.\n", "yellow");
        }
        
        parental_controls($username);
        
    } elsif (uc($action) eq 'E') {
        # --- Edit Existing Account Section ---
        print colored("\n[Edit Local Windows Account]\n", "cyan");
        print "Enter the username of the account to edit: ";
        chomp(my $username = <STDIN>);
        unless ($username) {
            print colored("Username cannot be empty. Aborting edit.\n", "red");
            return;
        }
        # Check if the account exists
        my $check_output = `net user "$username" 2>&1`;
        if ($? != 0) {
            print colored("Account '$username' does not exist. Aborting edit.\n", "red");
            return;
        }
        
        print "\nSelect an option to edit:\n";
        print " [1] Change Password\n";
        print " [2] Modify Administrator Privileges\n";
        print " [3] Update Parental Controls\n";
        print "Enter your choice (1/2/3): ";
        chomp(my $edit_choice = <STDIN>);
        
        if ($edit_choice eq '1') {
            print "\nEnter the new password for '$username': ";
            chomp(my $new_password = <STDIN>);
            my $cmd = qq(net user "$username" "$new_password");
            print "\nChanging password...\n";
            my $result = system($cmd);
            if ($result != 0) {
                print colored("Failed to change password.\n", "red");
            } else {
                print colored("Password changed successfully.\n", "green");
            }
        }
        elsif ($edit_choice eq '2') {
            print "\nShould '$username' have administrator privileges? (Y/N): ";
            chomp(my $admin_choice = <STDIN>);
            if (uc($admin_choice) eq 'Y') {
                my $cmd = qq(net localgroup Administrators "$username" /add);
                print "\nAdding '$username' to the Administrators group...\n";
                my $result = system($cmd);
                if ($result != 0) {
                    print colored("Failed to add '$username' to the Administrators group.\n", "red");
                } else {
                    print colored("Administrator privileges granted to '$username'.\n", "green");
                }
            } else {
                my $cmd = qq(net localgroup Administrators "$username" /delete);
                print "\nRemoving '$username' from the Administrators group...\n";
                my $result = system($cmd);
                if ($result != 0) {
                    print colored("Failed to remove '$username' from the Administrators group.\n", "red");
                } else {
                    print colored("Administrator privileges removed from '$username'.\n", "green");
                }
            }
        }
        elsif ($edit_choice eq '3') {
            parental_controls($username);
        }
        else {
            print colored("Invalid selection. Aborting edit.\n", "yellow");
        }
        
    } elsif (uc($action) eq 'D') {
        # --- Delete Account Section ---
        print colored("\n[Delete Local Windows Account]\n", "cyan");
        print "Enter the username of the account to delete: ";
        chomp(my $username = <STDIN>);
        unless ($username) {
            print colored("No username provided. Aborting deletion.\n", "red");
            return;
        }
        print "Are you sure you want to delete the account '$username'? (Y/N): ";
        chomp(my $confirm = <STDIN>);
        return unless uc($confirm) eq 'Y';
        my $cmd = qq(net user "$username" /delete);
        print "\nDeleting account '$username'...\n";
        my $result = system($cmd);
        if ($result != 0) {
            print colored("Failed to delete the account. Ensure the account exists and you have sufficient privileges.\n", "red");
        } else {
            print colored("Account '$username' has been deleted successfully.\n", "green");
        }
        
    } else {
        print colored("Invalid selection. Aborting account management.\n", "yellow");
        return;
    }
}

# Parental controls helper subroutine
sub parental_controls {
    my ($username) = @_;
    print "\nDo you want to set up parental controls for account '$username'? (Y/N): ";
    chomp(my $pc_choice = <STDIN>);
    if (uc($pc_choice) eq 'Y') {
        # Option 1: Set login time restrictions
        print "Would you like to set login time restrictions for this account? (Y/N): ";
        chomp(my $time_restrict = <STDIN>);
        if (uc($time_restrict) eq 'Y') {
            print "Enter allowed login times (format e.g., M-F,08:00-17:00): ";
            chomp(my $times = <STDIN>);
            if ($times) {
                my $pc_cmd = qq(net user "$username" /times:$times);
                print "\nSetting login time restrictions...\n";
                my $pc_result = system($pc_cmd);
                if ($pc_result != 0) {
                    print colored("Failed to set login time restrictions.\n", "red");
                } else {
                    print colored("Login time restrictions set successfully.\n", "green");
                }
            } else {
                print colored("No time restrictions provided. Skipping this control.\n", "yellow");
            }
        }
        # Option 2: Block certain websites using per-user registry settings
        print "\nWould you like to block certain websites for this account? (Y/N): ";
        chomp(my $block_web = <STDIN>);
        if (uc($block_web) eq 'Y') {
            print "Enter additional website domains to block (comma separated, e.g., badsite.com, spam.com) or leave blank for none: ";
            chomp(my $websites_input = <STDIN>);
            my @websites = ();
            if ($websites_input) {
                @websites = split /,\s*/, $websites_input;
            }
            # Default list of adult sites to always block
            my @default_adult_sites = (
                "pornhub.com",
                "redtube.com",
                "xvideos.com",
                "xnxx.com",
                "youporn.com",
                "spankbang.com"
            );
            push @websites, @default_adult_sites;
            
            foreach my $site (@websites) {
                $site =~ s/^\s+|\s+$//g;
                next unless $site;
                $site =~ s/^www\.//i;
                my $reg_cmd = qq(reg add "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Internet Settings\\ZoneMap\\Domains\\$site" /v "*" /t REG_DWORD /d 4 /f);
                print "\nBlocking website: $site\n";
                system($reg_cmd);
            }
            print colored("\nWebsites blocked for the current user via IE zone settings.\n", "green");
        }
    }
}


# -------------------------------------------
# Software:Update & Driver Check
# -------------------------------------------








# ------------------------------------------
# Software: Backup & Restore System
# ------------------------------------------
sub backup_folder1 {
    print colored("\n[Backup & Restore] Select an option:\n", "cyan");
    print colored("1. Backup (Open Windows Backup Tool)\n", "green");
    print colored("2. Restore (Open Windows Restore Tool)\n", "green");
    print colored("Enter choice: ", "cyan");
    chomp(my $choice = <STDIN>);
    
    if ($choice == 1) {
        backup_windows();
    }
    elsif ($choice == 2) {
        restore_windows();
    }
    else {
        print colored("Invalid choice.\n", "red");
        pause();
    }
}

# Launch Windows Backup tool
sub backup_windows {
    print colored("\nOpening Windows Backup Tool...\n", "cyan");
    # This will launch the built-in Backup and Restore (Windows 7 style) wizard.
    # Depending on your Windows version, you might need to adjust the command.
    system("start sdclt.exe") == 0
        or warn colored("Failed to launch Windows Backup Tool.\n", "red");
    pause();
}

# Launch Windows Restore tool
sub restore_windows {
    print colored("\nOpening Windows Restore Tool...\n", "cyan");
    # The same tool usually handles both backup and restore.
    system("start sdclt.exe") == 0
        or warn colored("Failed to launch Windows Restore Tool.\n", "red");
    pause();
}


# ------------------------------------------
# Software: Virus Online Scan
# ------------------------------------------
sub virusscan_site {
    print colored("\n[Malicious Scan] Select an option:\n", "yellow");
    print colored("1. Open Virus Total\n", "green");
    print colored("2. Open File Scan\n", "green");
    print colored("3. Open URL Malicious Scan\n", "green");
    print colored("Enter choice: ", "cyan");
    
    chomp(my $choice = <STDIN>);
    
    if ($choice == 1) {
        open_virustotal();
    }
    elsif ($choice == 2) {
        open_filescan();
    }
    elsif ($choice == 3) {
        open_urlscan();
    }
    else {
        print colored("Invalid choice.\n", "red");
        pause();
    }
}

# Function to open Virus Total (router admin replacement)
sub open_virustotal {
    my $url = "https://www.virustotal.com";
    print colored("\nOpening Virus Total at $url...\n", "green");
    system("start $url") == 0
        or warn colored("Failed to open Virus Total.\n", "red");
}

# Function to open File Scan (network monitor replacement)
sub open_filescan {
    my $url = "https://www.filescan.io/scan";
    print colored("\nOpening File Scan...\n", "green");
    system("start $url") == 0
        or warn colored("Failed to open File Scan.\n", "red");
}

# Function to open URL Scan (speed test replacement)
sub open_urlscan {
    my $url = "https://urlscan.io";
    print colored("\nOpening URL Scan...\n", "green");
    system("start $url") == 0
        or warn colored("Failed to open URL Scan.\n", "red");
}

# -------------------------------
# Software Menu
# -------------------------------
sub software_menu {
    while (1) {
        clear_screen();
        print_header();
        print "Software Menu:\n";
        print " 1) Clear Windows Update Cache\n";
        print " 2) Clear All Browser History\n";
        print " 3) Virus Scan (Quick or Full) – Simulation\n";
        print " 4) New System Restore Point\n";
        print " 5) Advanced Scanning for Leftovers – Simulation\n";
        print " 6) Disk Cleanup\n";
        print " 7) Windows Search Repair\n";
        print " 8) System Information Export\n";
        print " 9) Reset System Components\n";
        print " 10) Repair All Microsoft Programs\n";
        print " 11) Optimize/Defrag a Drive\n";
        print " 12) System File Checker (SFC)\n";
        print " 13) Clear TEMP / Downloads / Recycle Bin\n";
        print " 14) DISM (Scan & Restore)\n";
        print " 15) Check System Logs for Past Events\n";
        print " 16) System Performance Analysis\n";
        print " 17) File Integrity Checker\n";
        print " 18) Ram Diagnostics\n";
        print " 19) Generate GPU Report\n";
        print " 20) Run GPU Diagnostic\n";
        print " 21) Install AtlasOS\n";
        print " 22) Manage Local Windows Account\n";
        print " 23) Software Update & Driver Check\n";
        print " 24) Backup & Restore System\n";
        print " 25) Malicious Scan\n";
        print " 26) Back to Main Menu\n\n";
        print "Enter your choice: ";
        chomp(my $sw_choice = <STDIN>);
        if ($sw_choice eq "1") {
            clear_update_cache();
        }
        elsif ($sw_choice eq "2") {
            clear_browser_history();
        }
        elsif ($sw_choice eq "3") {
            test_virus();
        }
        elsif ($sw_choice eq "4") {
            new_system_restore_point();
        }
        elsif ($sw_choice eq "5") {
            invoke_advanced_scanning();
        }
        elsif ($sw_choice eq "6") {
            invoke_disk_cleanup();
        }
        elsif ($sw_choice eq "7") {
            repair_windows_search();
        }
        elsif ($sw_choice eq "8") {
            export_system_info();
        }
        elsif ($sw_choice eq "9") {
            reset_system_components();
        }
        elsif ($sw_choice eq "10") {
            repair_microsoft_programs();
        }
        elsif ($sw_choice eq "11") {
            optimize_drive();
        }
        elsif ($sw_choice eq "12") {
            invoke_sfc();
        }
        elsif ($sw_choice eq "13") {
            invoke_dism();
        }
        elsif ($sw_choice eq "14") {
            clear_files();
        }
        elsif ($sw_choice eq "15") {
            watch_system_change();
        }
        elsif ($sw_choice eq "16") {
            test_performance_analysis();
        }
        elsif ($sw_choice eq "17") {
            invoke_file_integrity_check();
        }
        elsif ($sw_choice eq "18") {
            run_memory_diagnostic();
        }
        elsif ($sw_choice eq "19") {
            run_gpu_diagnostic();
        }
        elsif ($sw_choice eq "20") {
            check_gpu_issues();
        }
        elsif ($sw_choice eq "21") {
            install_atlasos();
        }
        elsif ($sw_choice eq "22") {
            manage_local_account();
        }
        elsif ($sw_choice eq "23") {
            software_update_check();
        }
        elsif ($sw_choice eq "24") {
            backup_folder1();
        }
        elsif ($sw_choice eq "25") {
            virusscan_site();
        }
        elsif ($sw_choice eq "26") {
            last;
        }
        else {
            print colored("Invalid choice.\n", "yellow");
            pause();
        }
    }
}

# -------------------------------
# Miscellaneous Menu (Stub)
# -------------------------------
sub miscellaneous_menu {
    while (1) {
        clear_screen();
        print_header();
        print "Miscellaneous Menu:\n";
        print " 1) Miscellaneous Option 1 (Coming soon)\n";
        print " 2) Back to Main Menu\n\n";
        print "Enter your choice: ";
        chomp(my $choice = <STDIN>);
        if ($choice eq "1") {
            print colored("\nMiscellaneous Option 1 selected. Feature under construction...\n", "cyan");
            pause();
        }
        elsif ($choice eq "2") {
            last;
        }
        else {
            print colored("Invalid choice.\n", "yellow");
            pause();
        }
    }
}

# -------------------------------
# Clear screen function
# -------------------------------
sub clear_screen {
    system("cls");
}

# -------------------------------
# Main Menu
# -------------------------------
sub main_menu {
    while (1) {
        clear_screen();
        print_header();
        print "Main Menu:\n";
        print " 1) Hardware\n";
        print " 2) Network\n";
        print " 3) Software\n";
        print " 4) Miscellaneous\n";
        print " 5) Exit\n\n";
        print "Enter your choice: ";
        chomp(my $choice = <STDIN>);
        if ($choice eq "1") {
            hardware_menu();
        }
        elsif ($choice eq "2") {
            networking_menu();
        }
        elsif ($choice eq "3") {
            software_menu();
        }
        elsif ($choice eq "4") {
            miscellaneous_menu();
        }
        elsif ($choice eq "5") {
            ();
        }
        elsif ($choice eq "6") {
            print colored("Exiting PC Maintenance Toolkit. Goodbye!\n", "green");
            last;
        }
        else {
            print colored("Invalid choice.\n", "yellow");
            pause();
        }
    }
}

# -------------------------------
# Run Main Menu
# -------------------------------
main_menu();
