#!/bin/bash

# Prevent TERM, HUP, or INT signals
trap '' TERM HUP INT

VERBOSE=false

# Function to log messages
log_and_print() {
    local message=$1
    logger "$message"
    $VERBOSE && echo "$message"
}

# Process command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -verbose) VERBOSE=true ;;
        -name) shift; DESIRED_NAME=$1 ;;
        -ip) shift; DESIRED_IP=$1 ;;
        -hostentry) shift; DESIRED_HOSTNAME=$1; shift; DESIRED_HOSTIP=$1 ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# hostname change
if [[ -n "$DESIRED_NAME" ]]; then
    CURRENT_NAME=$(hostname)
    if [[ "$CURRENT_NAME" != "$DESIRED_NAME" ]]; then
        $VERBOSE && echo "Setting hostname to $DESIRED_NAME"
        sudo sed -i "s/ $(hostname)$/ $DESIRED_NAME/g" /etc/hosts
        echo "$DESIRED_NAME" | sudo tee /etc/hostname > /dev/null
        sudo hostnamectl set-hostname "$DESIRED_NAME"
        log_and_print "Hostname updated to $DESIRED_NAME"
    else
        $VERBOSE && echo "Hostname is already $DESIRED_NAME"
    fi
fi

# IP address change
if [[ -n "$DESIRED_IP" ]]; then
    LAN_INTERFACE=$(ip route | awk '/default/ { print $5 }')
    CURRENT_IP=$(ip -4 addr show "$LAN_INTERFACE" | awk '/inet/ { print $2 }' | cut -d/ -f1)
    if [[ "$CURRENT_IP" != "$DESIRED_IP" ]]; then
        $VERBOSE && echo "Updating IP address to $DESIRED_IP"
        sudo sed -i "s/$CURRENT_IP/$DESIRED_IP/g" /etc/hosts
        sudo sed -i "s/$CURRENT_IP/$DESIRED_IP/g" /etc/netplan/*.yaml
        sudo netplan apply
        log_and_print "IP address updated to $DESIRED_IP"
    else
        $VERBOSE && echo "IP address is already $DESIRED_IP"
    fi
fi

# Add or update host entry
if [[ -n "$DESIRED_HOSTNAME" && -n "$DESIRED_HOSTIP" ]]; then
    if ! grep -qE "$DESIRED_HOSTIP\s+$DESIRED_HOSTNAME" /etc/hosts; then
        $VERBOSE && echo "Adding new host entry: $DESIRED_HOSTNAME -> $DESIRED_HOSTIP"
        echo "$DESIRED_HOSTIP $DESIRED_HOSTNAME" | sudo tee -a /etc/hosts > /dev/null
        log_and_print "Added host entry: $DESIRED_HOSTNAME with IP $DESIRED_HOSTIP"
    else
        $VERBOSE && echo "Host entry for $DESIRED_HOSTNAME with IP $DESIRED_HOSTIP already exists"
    fi
fi
