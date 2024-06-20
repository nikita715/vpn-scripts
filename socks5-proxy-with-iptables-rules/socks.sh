#!/bin/sh

# Function to display a wizard prompt
wizard_prompt() {
    echo "Dante SOCKS5 Proxy Setup Wizard"
    echo "==============================="
    printf "Enter the port for the SOCKS5 server: "
    read server_port
    echo "Enter the list of client IP addresses (separated by spaces): "
    read client_ips
}

# Function to configure dante
configure_dante() {
    apt-get update
    apt-get install dante-server
    echo "Configuring Dante SOCKS5 proxy server..."

    # Create a new configuration file
    cat > /etc/danted.conf <<EOL
logoutput: stderr

internal: 0.0.0.0 port = $server_port
external: eth0

method: none

user.privileged: root
user.unprivileged: nobody
user.libwrap: nobody

client pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    log: connect disconnect error
}

pass {
    from: 0.0.0.0/0 to: 0.0.0.0/0
    protocol: tcp udp
}
EOL
}

# Function to configure iptables
configure_iptables() {
    echo "Configuring iptables..."

    # Reject all other traffic to the server port
    iptables -I INPUT -p tcp --dport $server_port -j REJECT

    # Allow traffic from each client IP
    for ip in $client_ips; do
        iptables -I INPUT -p tcp --dport $server_port -s $ip -j ACCEPT
    done

    # Save iptables rules
    apt-get install -y iptables-persistent
    netfilter-persistent save
}

# Function to start and enable dante
start_dante() {
    echo "Starting and enabling Dante service..."
    systemctl start danted
    systemctl enable danted
}

# Main script execution
wizard_prompt
configure_dante
configure_iptables
start_dante

echo "Dante SOCKS5 proxy server setup complete."
