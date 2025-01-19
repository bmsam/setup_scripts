#!/bin/bash

# Print headers in bold
print_header() {
    echo -e "\n\033[1m$1\033[0m"
}

# Print success messages
print_success() {
    echo -e "\t-> $1"
}

# Print prompts in yellow
print_prompt() {
    echo -ne "\033[1;33m$1\033[0m"
}

# Display disclaimer
display_disclaimer() {
    echo -e "\033[1;31mDISCLAIMER:\nThis script is provided 'as is' without any warranty.\nIt was tested on Ubuntu 24.04.1.\nThe author is not responsible for any errors or damages.\033[0m"
    print_prompt "Do you accept the terms and wish to proceed? (y/n): "
    read ACCEPT_DISCLAIMER
    if [[ "$ACCEPT_DISCLAIMER" =~ ^[Nn]$ ]]; then
        echo "Exiting as the disclaimer was not accepted."
        exit 1
    fi
}

# Create a new user
create_new_user() {
    print_header "Creating a new user account..."
    print_prompt "Enter the username for the new user: "
    read NEW_USER

    if id "$NEW_USER" &>/dev/null; then
        print_success "User $NEW_USER already exists. Skipping user creation."
        return
    fi

    sudo adduser --disabled-password --gecos "" "$NEW_USER" >/dev/null 2>&1 && print_success "User $NEW_USER created successfully."
    echo ""
    print_prompt "Please set the password for $NEW_USER: "
    echo ""
    sudo passwd "$NEW_USER" >/dev/null 2>&1 && print_success "Password set successfully for $NEW_USER."

    sudo usermod -aG sudo "$NEW_USER" >/dev/null 2>&1 && print_success "$NEW_USER added to the sudo group successfully."
}

# Disable root user
disable_root_user() {
    sudo passwd -l root >/dev/null 2>&1 && print_success "Root account disabled successfully."
}

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root. Exiting..."
    exit 1
fi

# Main logic
display_disclaimer
clear
create_new_user
disable_root_user

# Prepare secondary script
cat <<'EOF' > /tmp/user_script.sh
#!/bin/bash

print_header() { echo -e "\n\033[1m$1\033[0m"; }
print_success() { echo -e "\t-> $1"; }
print_prompt() { echo -ne "\033[1;33m$1\033[0m"; }

fetch_ssh_key() {
    curl -s "https://github.com/$1.keys" || { echo "Failed to fetch SSH key for $1"; exit 1; }
}

# Ask the user if they want to fetch SSH key from GitHub
echo ""
print_prompt "Do you want to fetch an SSH key from GitHub? (y/n): "
read -r FETCH_SSH_KEY
if [[ "$FETCH_SSH_KEY" =~ ^[Yy]$ ]]; then
    print_prompt "Please enter your GitHub username to fetch your SSH keys: "
    read GITHUB_USERNAME

    print_header "Fetching SSH key from GitHub for user $GITHUB_USERNAME..."
    SSH_KEY=$(fetch_ssh_key "$GITHUB_USERNAME")
    if [[ -n "$SSH_KEY" ]]; then
        mkdir -p ~/.ssh && chmod 700 ~/.ssh
        if [[ -f ~/.ssh/authorized_keys && ! $(grep -qF "$SSH_KEY" ~/.ssh/authorized_keys) ]]; then
            echo "$SSH_KEY" >> ~/.ssh/authorized_keys
            print_success "SSH key appended to existing authorized_keys file."
        else
            echo "$SSH_KEY" > ~/.ssh/authorized_keys
            print_success "SSH key added to new authorized_keys file."
        fi
        chmod 600 ~/.ssh/authorized_keys
    else
        echo "Failed to fetch SSH key. Skipping SSH key setup."
    fi
else
    print_success "Skipping SSH key setup."
fi

print_header "Creating .bash_aliases..."
cat <<EOF2 > ~/.bash_aliases
alias ll='ls -alF'
alias upg='sudo apt update && sudo apt upgrade -y'
alias pya='.env/bin/activate'
alias pyd='deactivate'
EOF2
print_success ".bash_aliases created successfully."

print_header "Sourcing .bashrc..."
source ~/.bashrc >/dev/null 2>&1 && print_success ".bashrc sourced successfully."

print_prompt "Would you like to configure a static IP? (y/n): "
read -r CONFIGURE_STATIC_IP
if [[ "$CONFIGURE_STATIC_IP" =~ ^[Yy]$ ]]; then
    print_header "Configuring static IP..."
    print_prompt "Enter the desired static IP address (e.g., 10.10.2.72): "
    read STATIC_IP
    print_prompt "Enter the gateway (e.g., 10.10.2.1): "
    read GATEWAY
    print_prompt "Enter the DNS servers (comma-separated, e.g., 8.8.8.8,8.8.4.4): "
    read DNS
    print_prompt "Enter the subnet mask (e.g., 24): "
    read NETMASK
    print_prompt "Enter the network interface name (e.g., eth0): "
    read INTERFACE

    NETPLAN_CONFIG=$(find /etc/netplan -name "*.yaml" | head -n 1)
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
    sudo netplan apply >/dev/null 2>&1 && print_success "Static IP configuration applied successfully."
else
    print_success "Skipping static IP configuration."
fi

print_header "Updating and upgrading the system..."
sudo apt update -y >/dev/null 2>&1 && sudo apt upgrade -y >/dev/null 2>&1 && print_success "System updated successfully."

print_header "Installing packages..."
sudo apt install -y btop net-tools build-essential >/dev/null 2>&1 && print_success "Packages installed successfully."
EOF

sudo chmod +x /tmp/user_script.sh
sudo chown "$NEW_USER":"$NEW_USER" /tmp/user_script.sh
sudo -u "$NEW_USER" bash /tmp/user_script.sh

print_header "Cleaning up temporary files..."
sudo rm -f /tmp/user_script.sh >/dev/null 2>&1 && print_success "Cleanup complete."

print_header "Setup complete!"
echo ""
