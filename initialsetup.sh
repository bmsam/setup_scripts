#!/bin/bash

# Function to print headers in yellow
print_header() {
    echo -e "\033[1;33m$1\033[0m"
}

# Function to fetch SSH key from GitHub
fetch_ssh_key() {
    local github_username="$1"
    curl -s "https://github.com/$github_username.keys" || {
        echo "Error: Failed to fetch SSH key for $github_username"
        exit 1
    }
}

# Function to configure a static IP
configure_static_ip() {
    print_header "Configuring static IP..."
    
    # Prompt user for static IP details
    read -p "Enter the desired static IP address (e.g., 10.10.2.72): " STATIC_IP
    read -p "Enter the gateway (e.g., 10.10.2.1): " GATEWAY
    read -p "Enter the DNS servers (comma-separated, e.g., 8.8.8.8,8.8.4.4): " DNS
    read -p "Enter the subnet mask (e.g., 24): " NETMASK
    read -p "Enter the network interface name (e.g., eth0): " INTERFACE

    # Backup the existing netplan configuration
    print_header "Backing up the existing netplan configuration..."
    NETPLAN_CONFIG=$(find /etc/netplan -name "*.yaml" | head -n 1)
    if [[ -z "$NETPLAN_CONFIG" ]]; then
        echo "Error: No netplan configuration file found in /etc/netplan."
        exit 1
    fi
    sudo cp "$NETPLAN_CONFIG" "$NETPLAN_CONFIG.bak"

    # Generate a new netplan configuration
    print_header "Generating a new netplan configuration for a static IP..."
    sudo bash -c "cat <<EOF > $NETPLAN_CONFIG
network:
  version: 2
  renderer: networkd
  ethernets:
    $INTERFACE:
      addresses:
        - $STATIC_IP/$NETMASK
      routes:
        - to: default
          via: $GATEWAY
      nameservers:
        addresses: [$DNS]
EOF"

    # Apply the netplan configuration
    print_header "Applying the new netplan configuration..."
    sudo netplan apply

    echo "Static IP configuration applied successfully. New IP: $STATIC_IP"
}

# Prompt the user for their GitHub username
print_header "Please enter your GitHub username to fetch your SSH keys:"
read -p "GitHub username: " GITHUB_USERNAME

# Fetch SSH key from GitHub
print_header "Fetching SSH key from GitHub for user $GITHUB_USERNAME..."
SSH_KEY=$(fetch_ssh_key "$GITHUB_USERNAME")

# Create .bash_aliases and add aliases
print_header "Creating .bash_aliases with aliases..."
cat <<EOF > ~/.bash_aliases
alias ll='ls -alF'
alias upg='sudo apt update && sudo apt upgrade -y'
alias pya='.env/bin/activate'
alias pyd='deactivate'
EOF

# Reload .bashrc to apply aliases
print_header "Sourcing .bashrc to apply changes..."
source ~/.bashrc

# Create .ssh directory if it doesn't exist
print_header "Setting up SSH authorized_keys..."
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Check if authorized_keys exists and append the key if it does
if [[ -f ~/.ssh/authorized_keys ]]; then
    if ! grep -qF "$SSH_KEY" ~/.ssh/authorized_keys; then
        echo "$SSH_KEY" >> ~/.ssh/authorized_keys
        print_header "SSH key appended to existing authorized_keys file."
    else
        print_header "SSH key already exists in authorized_keys file."
    fi
else
    echo "$SSH_KEY" > ~/.ssh/authorized_keys
    print_header "SSH key added to new authorized_keys file."
fi

chmod 600 ~/.ssh/authorized_keys

# Ask the user if they want to configure a static IP
# print_header "Would you like to configure a static IP? (y/n)"
# read -r CONFIGURE_STATIC_IP
read -p "Would you like to configure a static IP? (y/n): " CONFIGURE_STATIC_IP

if [[ "$CONFIGURE_STATIC_IP" =~ ^[Yy]$ ]]; then
    configure_static_ip
else
    print_header "Skipping static IP configuration."
fi

# Update and upgrade the system
print_header "Running system update and upgrade..."
sudo apt update && sudo apt upgrade -y

# Install required packages
print_header "Installing required packages: btop, net-tools, build-essential..."
sudo apt install -y btop net-tools build-essential

print_header "Setup complete!"
