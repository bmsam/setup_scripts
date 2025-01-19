#!/bin/bash

# Function to print headers in yellow
print_header() {
    echo -e "\033[1;33m$1\033[0m"
}

# Function to create a new user
create_new_user() {
    print_header "Creating a new user account..."
    read -p "Enter the username for the new user: " NEW_USER

    if id "$NEW_USER" &>/dev/null; then
        echo "User $NEW_USER already exists. Skipping user creation."
    else
        sudo adduser "$NEW_USER"
        print_header "Adding $NEW_USER to ssh and wheel groups..."
        sudo usermod -aG ssh "$NEW_USER"
        sudo usermod -aG wheel "$NEW_USER"
        echo "User $NEW_USER created and added to ssh and wheel groups."
    fi
}

# Function to disable the root user
disable_root_user() {
    print_header "Disabling the root account..."
    sudo passwd -l root
    echo "Root account has been disabled."
}

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Exiting..."
    exit 1
fi

# Create a new user and disable root
create_new_user
disable_root_user

# Switch to the new user
print_header "Switching to the new user..."
sudo -i -u "$NEW_USER" bash <<'EOF'

# Function to fetch SSH key from GitHub
fetch_ssh_key() {
    local github_username="$1"
    curl -s "https://github.com/$github_username.keys" || {
        echo "Error: Failed to fetch SSH key for $github_username"
        exit 1
    }
}

print_header "Please enter your GitHub username to fetch your SSH keys:"
read -p "GitHub username: " GITHUB_USERNAME

print_header "Fetching SSH key from GitHub for user $GITHUB_USERNAME..."
SSH_KEY=$(fetch_ssh_key "$GITHUB_USERNAME")

print_header "Setting up SSH authorized_keys..."
mkdir -p ~/.ssh
chmod 700 ~/.ssh

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

print_header "Creating .bash_aliases with aliases..."
cat <<EOF2 > ~/.bash_aliases
alias ll='ls -alF'
alias upg='sudo apt update && sudo apt upgrade -y'
alias pya='.env/bin/activate'
alias pyd='deactivate'
EOF2

print_header "Sourcing .bashrc to apply changes..."
source ~/.bashrc

print_header "Would you like to configure a static IP? (y/n)"
read -r CONFIGURE_STATIC_IP
if [[ "$CONFIGURE_STATIC_IP" =~ ^[Yy]$ ]]; then
    print_header "Configuring static IP..."
    read -p "Enter the desired static IP address (e.g., 10.10.2.72): " STATIC_IP
    read -p "Enter the gateway (e.g., 10.10.2.1): " GATEWAY
    read -p "Enter the DNS servers (comma-separated, e.g., 8.8.8.8,8.8.4.4): " DNS
    read -p "Enter the subnet mask (e.g., 24): " NETMASK
    read -p "Enter the network interface name (e.g., eth0): " INTERFACE

    NETPLAN_CONFIG=$(find /etc/netplan -name "*.yaml" | head -n 1)
    if [[ -z "$NETPLAN_CONFIG" ]]; then
        echo "Error: No netplan configuration file found in /etc/netplan."
        exit 1
    fi
    sudo cp "$NETPLAN_CONFIG" "$NETPLAN_CONFIG.bak"
    sudo bash -c "cat <<EOF3 > $NETPLAN_CONFIG
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
EOF3"
    sudo netplan apply
    echo "Static IP configuration applied successfully. New IP: $STATIC_IP"
else
    print_header "Skipping static IP configuration."
fi

print_header "Running system update and upgrade..."
sudo apt update && sudo apt upgrade -y

print_header "Installing required packages: btop, net-tools, build-essential..."
sudo apt install -y btop net-tools build-essential

print_header "Setup complete!"

EOF
