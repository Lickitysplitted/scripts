#!/bin/sh
#
# FalconGather.sh
#
# Description:
#     This script gathers system and Falcon agent information.
#
# Usage:
#     ./falcongather.sh [OPTIONS]
#     Options:
#       -u : Gather uptime information
#       -o : Gather OS and kernel information
#       -f : Gather Falcon agent information
#       -a : Run all checks
#
# Dependencies:
#     - Falcon agent installed at /opt/CrowdStrike/
#     - sudo privileges for gathering kernel modules
#
# Author: [Your Name]
# Date: [Date]
#

# Color codes for better readability
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'  # No Color

# Function to check for command existence
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo -e "${RED}Error: $1 is not installed or not in PATH.${NC}"
        exit 1
    fi
}

# Check for required commands at the beginning
check_command "uname"
check_command "uptime"
check_command "cat"
check_command "yum"
check_command "grep"
check_command "netstat"

# Output redirection to a log file
LOGFILE="/tmp/falcon_gather_$(date +%Y%m%d_%H%M%S).log"
exec > "$LOGFILE" 2>&1

# Function to gather uptime
get_uptime(){
    echo "## Host Uptime ##"
    uptime
}

# Function to gather OS information
get_os(){
    echo "## OS Version ##"
    if [ -f /etc/os-release ]; then
        cat /etc/os-release
    elif [ -f /etc/redhat-release ]; then
        cat /etc/redhat-release
    else
        echo -e "${YELLOW}Warning: OS version file not found.${NC}"
    fi
}

# Function to gather kernel version
get_kernel(){
    echo "## Kernel Version ##"
    uname -r
}

# Function to check Falcon package version
get_falcon_pkg_version(){
    echo "## Falcon Pkg Version ##"
    yum list installed | grep -i falcon || echo -e "${YELLOW}Falcon package not found.${NC}"
}

# Function to check falconctl version
get_falconctl(){
    echo "## falconctl Version ##"
    if [ -f /opt/CrowdStrike/falconctl ]; then
        /opt/CrowdStrike/falconctl -g --version
    else
        echo -e "${YELLOW}Warning: falconctl binary not found.${NC}"
    fi
}

# Function to list loaded Falcon modules
get_modules(){
    echo "## Loaded Falcon Modules ##"
    if command -v lsmod &> /dev/null; then
        falcon_mods=$(sudo lsmod | grep -i falcon | awk '{print $1}')
        if [ -z "$falcon_mods" ]; then
            echo "No Falcon modules loaded."
        else
            for mod in $falcon_mods; do
                echo "$mod"
                sudo modinfo "$mod"
                sleep 1
            done
        fi
    else
        echo -e "${YELLOW}Warning: lsmod command not found.${NC}"
    fi
}

# Function to check Falcon network connections
get_falcon_connection(){
    echo "## Falcon Net Connections ##"
    if command -v ss &> /dev/null; then
        ss -tapn | grep -i falcon
    else
        netstat -tapn | grep -i falcon
    fi
}

# Function to check Falcon archive
get_falcon_archive(){
    echo "## Falcon Archive Folders ##"
    if [ -d /opt/CrowdStrike/ ]; then
        ls -all /opt/CrowdStrike/KernelModuleArchive* || echo -e "${YELLOW}No KernelModuleArchive found.${NC}"
    else
        echo -e "${YELLOW}Falcon directory not found.${NC}"
    fi
}

# Function to check Falcon RFM state
get_falcon_rfmstate(){
    echo "## Falcon RFM State ##"
    if [ -f /opt/CrowdStrike/falconctl ]; then
        /opt/CrowdStrike/falconctl -g --rfm-state
    else
        echo -e "${YELLOW}Warning: falconctl not found.${NC}"
    fi
}

# Function to check Falcon kernel compatibility
check_falcon_kernel(){
    echo "## Falcon Kernel Compatibility ##"
    if [ -f /opt/CrowdStrike/falcon-kernel-check ]; then
        /opt/CrowdStrike/falcon-kernel-check
    else
        echo -e "${YELLOW}Warning: falcon-kernel-check not found.${NC}"
    fi
}

# Function to gather all Falcon-related information
get_falcon_info(){
    echo "#### Falcon Info ####"
    get_falcon_archive
    get_falcon_connection
    get_falcon_pkg_version
    get_falconctl
    get_falcon_rfmstate
    check_falcon_kernel
    get_modules
}

# Main script logic with options
while getopts "uokfa" option; do
    case $option in
        u) get_uptime ;;
        o) get_os; get_kernel ;;
        f) get_falcon_info ;;
        a) get_uptime; get_os; get_kernel; get_falcon_info ;;
        *) echo -e "${RED}Invalid option. Use -u, -o, -f, or -a.${NC}"; exit 1 ;;
    esac
done

# If no options are passed, print usage
if [ $OPTIND -eq 1 ]; then
    echo -e "${YELLOW}No options provided. Use -u for uptime, -o for OS/kernel, -f for Falcon info, or -a for all.${NC}"
fi
