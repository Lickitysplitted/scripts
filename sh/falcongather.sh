#!/bin/sh

get_uptime(){
    echo "## Host Uptime ##"
    uptime
}

get_os(){
    echo "## OS Version ##"
    cat /etc/os-release
    cat /etc/redhat-release
}

get_kernel(){
    echo "## Kernel Version ##"
    uname -r
}

get_falcon_pkg_version(){
    echo "## Falcon Pkg Version ##"
    yum list installed | grep falcon
}

get_falconctl(){
    echo "## falconctl Version ##"
    /opt/CrowdStrike/falconctl -g --version
}

get_modules(){
    echo "## Loaded Falcon Modules ##"
    sudo lsmod | grep falcon
}

get_falcon_connection(){
    echo "## Falcon Net Connections ##"
    netstat -tapn | grep falcon
}

get_falcon_archive(){
    echo "## Falcon Archive Folders ##"
    ls -all /opt/CrowdStrike/KernelModuleArchive*
}

get_falcon_rfmstate(){
    echo "## Falcon RFM State ##"
    /opt/CrowdStrike/falconctl -g --rfm-state
}

check_falcon_kernel(){
    echo "## Falcon Kernel Compatibility ##"
    /opt/CrowdStrike/falcon-kernel-check
}

echo "#### Host Info ####"
get_uptime
echo "#### OS info ####"
get_os
get_kernel
echo "#### Falcon Info ####"
get_modules
get_falcon_archive
get_falcon_connection
get_falcon_rfmstate
check_falcon_kernel