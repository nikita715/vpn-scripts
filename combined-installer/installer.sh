#!/bin/bash

# Function to add allowed IPs for iptables
add_allowed_ip() {
    echo "Enter the IP address to allow (or type 'done' to finish):"
    while true; do
        read ip
        if [[ $ip == "done" ]]; then
            break
        fi
        sudo iptables -I INPUT -p tcp -s $ip --dport 1080 -j ACCEPT
    done
}

# Update and Upgrade
sudo apt update && sudo apt upgrade -y

# Install Dante
sudo apt install dante-server -y

# Configure Dante
sudo bash -c 'cat > /etc/danted.conf << EOF
logoutput: syslog
internal: eth0 port = 1080   # Replace "eth0" with your network interface if different
external: eth0              # Replace "eth0" with your network interface if different
method: none

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect
}

socks pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    command: bind connect udpassociate
    log: connect disconnect
}
EOF'

# Restart Dante
sudo systemctl restart danted

# Add allowed IPs for Dante
add_allowed_ip

# Block all other traffic to Dante port
sudo iptables -A INPUT -p tcp --dport 1080 -j REJECT

# Save iptables rules
sudo apt install iptables-persistent -y
sudo netfilter-persistent save

# Download and run OpenVPN install script from angristan
curl -O https://raw.githubusercontent.com/angristan/openvpn-install/master/openvpn-install.sh
chmod +x openvpn-install.sh

# Run the OpenVPN install script
sudo AUTO_INSTALL=y ./openvpn-install.sh

# Install Shadowsocks
sudo apt install shadowsocks-libev -y

# Configure Shadowsocks
sudo bash -c 'cat > /etc/shadowsocks-libev/config.json << EOF
{
    "server":"0.0.0.0",
    "server_port":8388,
    "local_address":"127.0.0.1",
    "local_port":1080,
    "password":"your_password",
    "timeout":300,
    "method":"aes-256-gcm"
}
EOF'

# Start and enable Shadowsocks
sudo systemctl start shadowsocks-libev
sudo systemctl enable shadowsocks-libev

echo "Setup complete. Please review the configurations and restart services if necessary."
