#!/bin/sh

# RMxxx RGMII Toolkit - Offline Installation Script
# This script provides an offline installation solution for the Quectel RMxxx RGMII Toolkit
# All dependencies are bundled locally instead of downloading from the internet

# Define toolkit paths
export PATH=/bin:/sbin:/usr/bin:/usr/sbin:/opt/bin:/opt/sbin:/usrdata/root/bin
TMP_DIR="/tmp"
USRDATA_DIR="/usrdata"
OFFLINE_DIR="/tmp/offline_package"

# Function to remount file system as read-write
remount_rw() {
    mount -o remount,rw /
}

# Function to remount file system as read-only
remount_ro() {
    mount -o remount,ro /
}

# Function to extract offline package
extract_offline_package() {
    echo -e "\e[1;32mExtracting offline package...\e[0m"
    
    # Check if offline package exists
    if [ ! -f "/tmp/offline_package.tar.gz" ]; then
        echo -e "\e[1;31mError: Offline package not found at /tmp/offline_package.tar.gz\e[0m"
        echo -e "\e[1;32mPlease copy the offline_package.tar.gz file to /tmp/ directory first\e[0m"
        exit 1
    fi
    
    # Extract the package
    tar -xzf /tmp/offline_package.tar.gz -C /tmp/
    if [ $? -ne 0 ]; then
        echo -e "\e[1;31mError: Failed to extract offline package\e[0m"
        exit 1
    fi
    
    echo -e "\e[1;32mOffline package extracted successfully\e[0m"
}

# Function to install from local files
install_from_local() {
    local component="$1"
    local script_path="$OFFLINE_DIR/simpleupdates/scripts/update_${component}.sh"
    
    if [ -f "$script_path" ]; then
        echo -e "\e[1;32mInstalling $component from local files...\e[0m"
        chmod +x "$script_path"
        "$script_path"
    else
        echo -e "\e[1;31mError: Local installation script for $component not found\e[0m"
    fi
}

# Basic AT commands without socat bridge for fast responce commands only
start_listening() {
    cat "/dev/smd7" > /tmp/device_readout &
    CAT_PID=$!
}

send_at_command() {
    echo -e "\e[1;31mThis only works for basic quick responding commands!\e[0m"  # Red
    echo -e "\e[1;36mType 'install' to simply type atcmd in shell from now on\e[0m"
    echo -e "\e[1;36mThe installed version is much better than this portable version\e[0m"
    echo -e "\e[1;32mEnter AT command (or type 'exit' to quit): \e[0m"
    read at_command
    if [ "$at_command" = "exit" ]; then
        return 1
    fi
    
    if [ "$at_command" = "install" ]; then
        install_update_at_socat
        echo -e "\e[1;32mInstalled. Type atcmd from adb shell or ssh to start an AT Command session\e[0m"
        return 1
    fi
    echo -e "${at_command}\r" > "/dev/smd7"
}

wait_for_response() {
    local start_time=$(date +%s)
    local current_time
    local elapsed_time

    echo -e "\e[1;32mCommand sent, waiting for response...\e[0m"
    while true; do
        if grep -qe "OK" -e "ERROR" /tmp/device_readout; then
            echo -e "\e[1;32mResponse received:\e[0m"
            cat /tmp/device_readout
            return 0
        fi
        current_time=$(date +%s)
        elapsed_time=$((current_time - start_time))
        if [ "$elapsed_time" -ge "4" ]; then
            echo -e "\e[1;31mError: Response timed out.\e[0m"  # Red
            echo -e "\e[1;32mIf the responce takes longer than a second or 2 to respond this will not work\e[0m"  # Green
            echo -e "\e[1;36mType install to install the better version of this that will work.\e[0m"  # Cyan
            return 1
        fi
        sleep 1
    done
}

cleanup() {
    kill "$CAT_PID" 2>/dev/null
    wait "$CAT_PID" 2>/dev/null
    rm -f /tmp/device_readout
}

send_at_commands() {
    if [ -c "/dev/smd7" ]; then
        while true; do
            start_listening
            send_at_command
            if [ $? -eq 1 ]; then
                cleanup
                break
            fi
            wait_for_response
            cleanup
        done
    else
        echo -e "\e[1;31mError: Device /dev/smd7 does not exist!\e[0m"
    fi
}

# Check for existing Entware/opkg installation, install if not installed
ensure_entware_installed() {
    remount_rw
    if [ ! -f "/opt/bin/opkg" ]; then
        echo -e "\e[1;32mInstalling Entware/OPKG from local package\e[0m"
        if [ -f "$OFFLINE_DIR/installentware.sh" ]; then
            chmod +x "$OFFLINE_DIR/installentware.sh"
            "$OFFLINE_DIR/installentware.sh"
        else
            echo -e "\e[1;31mError: Local Entware installer not found\e[0m"
            exit 1
        fi
    else
        echo -e "\e[1;32mEntware/OPKG is already installed.\e[0m"
    fi
}

# Function to install/update Simple Admin
install_simple_admin() {
    echo -e "\e[1;32mInstalling Simpleadmin 2.0 from offline package\e[0m"
    extract_offline_package
    ensure_entware_installed
    
    echo -e "\e[1;32mInstalling dependencies...\e[0m"
    install_from_local "socat-at-bridge"
    install_from_local "simplefirewall"
    
    # Set simpleadmin password
    set_simpleadmin_passwd
    
    # Install simpleadmin
    install_from_local "simpleadmin"
    
    echo -e "\e[1;32mSimpleadmin installation completed successfully\e[0m"
}

set_simpleadmin_passwd(){
    ensure_entware_installed
    opkg update
    opkg install libaprutil
    
    if [ -f "$OFFLINE_DIR/simpleadmin/htpasswd" ]; then
        cp "$OFFLINE_DIR/simpleadmin/htpasswd" /usrdata/root/bin/htpasswd
        chmod +x /usrdata/root/bin/htpasswd
    fi
    
    if [ -f "$OFFLINE_DIR/simpleadmin/simplepasswd" ]; then
        cp "$OFFLINE_DIR/simpleadmin/simplepasswd" /usrdata/root/bin/simplepasswd
        chmod +x /usrdata/root/bin/simplepasswd
    fi
    
    echo -e "\e[1;32mTo change your simpleadmin (admin) password in the future...\e[0m"
    echo -e "\e[1;32mIn the console type simplepasswd and press enter\e[0m"
    /usrdata/root/bin/simplepasswd
}

set_root_passwd() {
    echo -e "\e[1;31mPlease set the root/console password.\e[0m"
    /opt/bin/passwd
}

# Function to install/update Tailscale
install_update_tailscale() {
    echo -e "\e[1;32mInstalling Tailscale from offline package\e[0m"
    extract_offline_package
    install_from_local "tailscale"
}

# Function to install OpenSSH Server
install_sshd() {
    echo -e "\e[1;32mInstalling OpenSSH Server from offline package\e[0m"
    extract_offline_package
    install_from_local "sshd"
}

# Function to install Speedtest CLI
install_speedtest() {
    echo -e "\e[1;32mInstalling Speedtest.net CLI from offline package\e[0m"
    extract_offline_package
    ensure_entware_installed
    
    if [ -f "$OFFLINE_DIR/binaries/speedtest" ]; then
        remount_rw
        mkdir -p /usrdata/root/bin
        cp "$OFFLINE_DIR/binaries/speedtest" /usrdata/root/bin/
        chmod +x /usrdata/root/bin/speedtest
        ln -sf /usrdata/root/bin/speedtest /bin/speedtest
        remount_ro
        echo -e "\e[1;32mSpeedtest CLI installed successfully\e[0m"
    else
        echo -e "\e[1;31mError: Speedtest binary not found in offline package\e[0m"
    fi
}

# Function to install Fast.com CLI
install_fast() {
    echo -e "\e[1;32mInstalling Fast.com CLI from offline package\e[0m"
    extract_offline_package
    
    if [ -f "$OFFLINE_DIR/binaries/fast" ]; then
        remount_rw
        mkdir -p /usrdata/root/bin
        cp "$OFFLINE_DIR/binaries/fast" /usrdata/root/bin/
        chmod +x /usrdata/root/bin/fast
        ln -sf /usrdata/root/bin/fast /bin/fast
        remount_ro
        echo -e "\e[1;32mFast.com CLI installed successfully\e[0m"
    else
        echo -e "\e[1;31mError: Fast.com binary not found in offline package\e[0m"
    fi
}
# Main menu
ARCH=$(uname -a)
if echo "$ARCH" | grep -q "aarch64"; then
    echo -e "\e[1;31mError: This toolkit is for ARMv7 architecture only\e[0m"
    exit 1
elif echo "$ARCH" | grep -q "armv7l"; then
    echo "Architecture is armv7l, continuing..."
else
    uname -a
    echo "Unsupported architecture."
    exit 1
fi

# Check if offline package is available
if [ ! -f "/tmp/offline_package.tar.gz" ]; then
    echo -e "\e[1;33mWarning: Offline package not found at /tmp/offline_package.tar.gz\e[0m"
    echo -e "\e[1;33mSome features may not work without the offline package\e[0m"
fi

while true; do
    echo "                           .%+:                              "
    echo "                             .*@@@-.                         "
    echo "                                  :@@@@-                     "
    echo "                                     @@@@#.                  "
    echo "                                      -@@@@#.                "
    echo "       :.                               %@@@@: -#            "
    echo "      .+-                                #@@@@%.+@-          "
    echo "      .#- .                               +@@@@# #@-         "
    echo "    -@*@*@%                                @@@@@::@@=        "
    echo ".+%@@@@@@@@@%=.                            =@@@@# #@@- ..    "
    echo "    .@@@@@:                                :@@@@@ =@@@..%=   "
    echo "    -::@-.+.                                @@@@@.=@@@- =@-  "
    echo "      .@-                                  .@@@@@:.@@@*  @@. "
    echo "      .%-                                  -@@@@@:=@@@@  @@# "
    echo "      .#-         .%@@@@@@#.               +@@@@@.#@@@@  @@@."
    echo "      .*-            .@@@@@@@@@@=.         @@@@@@ @@@@@  @@@:"
    echo "       :.             .%@@@@@@@@@@@%.     .@@@@@+:@@@@@  @@@-"
    echo "                        -@@@@@@@@@@@@@@@..@@@@@@.-@@@@@ .@@@-"
    echo "                         -@@@@@@@@@@%.  .@@@@@@. @@@@@+ =@@@="
    echo "                           =@@@@@@@@*  .@@@@@@. @@@@@@..@@@@-"
    echo "                            #@@@@@@@@-*@@@@@%..@@@@@@+ #@@@@-"
    echo "                            @@@@@@:.-@@@@@@.  @@@@@@= %@@@@@."
    echo "                           .@@@@. *@@@@@@- .+@@@@@@-.@@@@@@+ "
    echo "                           %@@. =@@@@@*.  +@@@@@@%.-@@@@@@%  "
    echo "                          .@@ .@@@@@=  :@@@@@@@@..@@@@@@@=   "
    echo "                          =@.+@@@@@. -@@@@@@@*.:@@@@@@@*.    "
    echo "                          %.*@@@@= .@@@@@@@-.:@@@@@@@+.      "
    echo "                          ..@@@@= .@@@@@@: #@@@@@@@:         "
    echo "                           .@@@@  +@@@@..%@@@@@+.            "
    echo "                           .@@@.  @@@@.:@@@@+.               "
    echo "                            @@@.  @@@. @@@*    .@.           "
    echo "                            :@@@  %@@..@@#.    *@            "
    echo "                         -*: .@@* :@@. @@.  -..@@            "
    echo "                       =@@@@@@.*@- :@%  @* =@:=@#            "
    echo "                      .@@@-+@@@@:%@..%- ...@%:@@:            "
    echo "                      .@@.  @@-%@:      .%@@*@@%.            "
    echo "                       :@@ :+   *@     *@@#*@@@.             "
    echo "                                     =@@@.@@@@               "
    echo "                                  .*@@@:=@@@@:               "
    echo "                                .@@@@:.@@@@@:                "
    echo "                              .@@@@#.-@@@@@.                 "
    echo "                             #@@@@: =@@@@@-                  "
    echo "                           .@@@@@..@@@@@@*                   "
    echo "                          -@@@@@. @@@@@@#.                   "
    echo "                         -@@@@@  @@@@@@%                     "
    echo "                         @@@@@. #@@@@@@.                     "
    echo "                        :@@@@# =@@@@@@%                      "
    echo "                        @@@@@: @@@@@@@:                      "
    echo "                        *@@@@  @@@@@@@.                      "
    echo "                        .@@@@  @@@@@@@                       "
    echo "                         #@@@. @@@@@@*                       "
    echo "                          @@@# @@@@@@@                       "
    echo "                           .@@+=@@@@@@.                      "
    echo "                                *@@@@@@                      "
    echo "                                 :@@@@@=                     "
    echo "                                  .@@@@@@.                   "
    echo "                                    :@@@@@*.                 "
    echo "                                      .=@@@@@-               "
    echo "                                           :+##+.            "

    echo -e "\e[92m"
    echo "Welcome to iamromulan's RGMII Toolkit - OFFLINE VERSION"
    echo "Visit https://github.com/iamromulan for more!"
    echo -e "\e[0m"
    echo "Select an option:"
    echo -e "\e[0m"
    echo -e "\e[96m1) Send AT Commands\e[0m" # Cyan
    echo -e "\e[93m2) Install Simple Admin (Offline)\e[0m" # Yellow
    echo -e "\e[95m3) Set Simpleadmin (admin) password\e[0m" # Light Purple
    echo -e "\e[94m4) Set Console/ttyd (root) password\e[0m" # Light Blue
    echo -e "\e[91m5) Uninstall Simple Admin\e[0m" # Light Red    
    echo -e "\e[95m6) Simple Firewall Management\e[0m" # Light Purple
    echo -e "\e[94m7) Tailscale Management (Offline)\e[0m" # Light Blue
    echo -e "\e[92m8) Install/Change or remove Daily Reboot Timer\e[0m" # Light Green
    echo -e "\e[96m9) Install/Uninstall CFUN 0 Fix\e[0m" # Cyan
    echo -e "\e[91m10) Uninstall Entware/OPKG\e[0m" # Light Red
    echo -e "\e[92m11) Install Speedtest.net CLI (Offline)\e[0m" # Light Green
    echo -e "\e[92m12) Install Fast.com CLI (Offline)\e[0m" # Light Green
    echo -e "\e[92m13) Install OpenSSH Server (Offline)\e[0m" # Light Green
    echo -e "\e[93m14) Exit\e[0m" # Yellow
    read -p "Enter your choice: " choice

    case $choice in
        1)
            send_at_commands
            ;;
        2)
            install_simple_admin
            ;;
        3)
            set_simpleadmin_passwd
            ;;
        4)
            set_root_passwd
            ;;
        5)
            echo -e "\e[1;31mUninstall feature not implemented in offline version yet\e[0m"
            ;;
        6)
            echo -e "\e[1;31mSimple Firewall Management not implemented in offline version yet\e[0m"
            ;;
        7)
            install_update_tailscale
            ;;
        8)
            echo -e "\e[1;31mDaily Reboot Timer not implemented in offline version yet\e[0m"
            ;;
        9)
            echo -e "\e[1;31mCFUN 0 Fix not implemented in offline version yet\e[0m"
            ;;
        10)
            echo -e "\e[1;31mEntware Uninstall not implemented in offline version yet\e[0m"
            ;;
        11)
            install_speedtest
            ;;
        12)
            install_fast
            ;;
        13)
            install_sshd
            ;;
        14)
            echo -e "\e[1;32mGoodbye!\e[0m"
            break
            ;;
        *)
            echo -e "\e[1;31mInvalid option\e[0m"
            ;;
    esac
done