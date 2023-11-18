#! /usr/bin/env bash

# Check for ip argument
if [ $# -eq 0 ]
  then
    echo "No argument supplied. Add IP argument."
fi

# Vars
hn=$(hostname)
ip=$1
int=$(ip r | grep default | awk '/default/ {print $5}')
gw=$(ip r | grep default | cut -d " " -f 3)
nm=$(ip -o -f inet addr show | awk '/scope global/ {print $2, $4}' | grep $int | cut -d "/" -f 2)


# Set static ip
cat << EOF > /etc/network/interfaces
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

allow-hotplug $int
iface $int inet static
address $ip
netmask $nm
gateway $gw
EOF

# Add an /etc/hosts entry for IP address
cat << EOF > /etc/hosts
127.0.0.1       localhost
$ip    $hn.proxmox.com $hn

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

# Restart network service
systemctl restart networking.service

# Update apt base sources list
cat << EOF > /etc/apt/sources.list
deb http://deb.debian.org/debian bookworm main non-free-firmware contrib non-free
deb-src http://deb.debian.org/debian bookworm main non-free-firmware contrib non-free

deb http://deb.debian.org/debian-security/ bookworm-security main non-free-firmware contrib non-free
deb-src http://deb.debian.org/debian-security/ bookworm-security main non-free-firmware contrib non-free

deb http://deb.debian.org/debian bookworm-updates main non-free-firmware contrib non-free
deb-src http://deb.debian.org/debian bookworm-updates main non-free-firmware contrib non-free
EOF


# Add the Proxmox VE repository
echo "deb [arch=amd64] http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-install-repo.list

# Add the Proxmox VE repository key
wget https://enterprise.proxmox.com/debian/proxmox-release-bookworm.gpg -O /etc/apt/trusted.gpg.d/proxmox-release-bookworm.gpg 

# Update your repository and system
apt update -y && apt full-upgrade -y

# Install the Proxmox VE packages
apt install -y proxmox-ve postfix open-iscsi chrony

# Remove the os-prober package
apt remove -y os-prober

# Reboot
reboot now
