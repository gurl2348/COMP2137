#!/bin/bash
# This script transfers and executes the configure-host.sh script on two remote servers and updates the local /etc/hosts file accordingly.

# Copy configure-host.sh to server1-mgmt
scp configure-host.sh remoteadmin@server1-mgmt:/root

# Execute the script on server1-mgmt with specified parameters
ssh remoteadmin@server1-mgmt -- /root/configure-host.sh -name loghost -ip 192.168.16.3 -hostentry webhost 192.168.16.4

# Fetch and display the hostname, IP address, and host entry from server1-mgmt
hostname1=$(ssh remoteadmin@server1-mgmt -- hostname)
ip1=$(ssh remoteadmin@server1-mgmt -- hostname -I | awk '{print $1}')
entryname1=$(ssh remoteadmin@server1-mgmt -- grep "192.168.16.4" /etc/hosts | awk '{print $2}')

echo "hostname=$hostname1"
echo "host ip=$ip1"
echo "entryname=$entryname1"

# Validate the changes on server1-mgmt
if [[ "$hostname1" == "loghost" && "$ip1" == "192.168.16.3" && "$entryname1" == "webhost" ]]; then
    echo "Configuration on server1-mgmt is correct"
else
    echo "Configuration on server1-mgmt is incorrect"
fi

# Copy configure-host.sh to server2-mgmt
scp configure-host.sh remoteadmin@server2-mgmt:/root

# Execute the script on server2-mgmt with specified parameters
ssh remoteadmin@server2-mgmt -- /root/configure-host.sh -name webhost -ip 192.168.16.4 -hostentry loghost 192.168.16.3

# Fetch and display the hostname, IP address, and host entry from server2-mgmt
hostname2=$(ssh remoteadmin@server2-mgmt -- hostname)
ip2=$(ssh remoteadmin@server2-mgmt -- hostname -I | awk '{print $1}')
entryname2=$(ssh remoteadmin@server2-mgmt -- grep "192.168.16.3" /etc/hosts | awk '{print $2}')

echo "hostname=$hostname2"
echo "host ip=$ip2"
echo "entryname=$entryname2"

# Validate the changes on server2-mgmt
if [[ "$hostname2" == "webhost" && "$ip2" == "192.168.16.4" && "$entryname2" == "loghost" ]]; then
    echo "Configuration on server2-mgmt is correct"
else
    echo "Configuration on server2-mgmt is incorrect"
fi

# Update the local /etc/hosts file with new entries
./configure-host.sh -hostentry loghost 192.168.16.3
./configure-host.sh -hostentry webhost 192.168.16.4
