# Ubuntu 24.04.1 Setup Script

`setup_script.sh` is a Bash script designed to automate the initial setup and configuration of a new Ubuntu 24.04.1 server. It simplifies user account creation, system updates, and other essential configurations.

## Features

- **User Management**
  - Prompts for a new username and creates the user account.
  - Adds the new user to the `sudo` group.
  - Disables the `root` account for enhanced security.

- **SSH Key Integration**
  - Optionally fetches and installs SSH public keys from a GitHub account.

- **Alias Setup**
  - Creates a `.bash_aliases` file with handy command shortcuts:
    - `ll`: `ls -alF`
    - `upg`: `sudo apt update && sudo apt upgrade -y`
    - `pya`: Activates a Python virtual environment.
    - `pyd`: Deactivates a Python virtual environment.

- **Static IP Configuration**
  - Optionally configures a static IP address during setup.

- **System Updates and Package Installation**
  - Updates and upgrades the system.
  - Installs essential packages: `btop`, `net-tools`, and `build-essential`.

## Prerequisites

- **Supported Environment**: Ubuntu 24.04.1.
- **Root Privileges**: This script must be run as `root` or with `sudo`.

## How to Use

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/your-username/your-repository.git
   ```

2. **Navigate to the Directory**:
   ```bash
   cd your-repository
   ```

3. **Make the Script Executable**:
   ```bash
   chmod +x setup_script.sh
   ```

4. **Run the Script**:
   ```bash
   sudo ./setup_script.sh
   ```

5. **Follow the Prompts**:
   - Accept the disclaimer.
   - Create a new user account.
   - Optionally fetch and configure SSH keys.
   - Configure a static IP if desired.

## Disclaimer

This script is provided "as is" without any warranty. It was tested on Ubuntu 24.04.1. The author is not responsible for any errors, issues, or damages caused by its use. Review the script before running it and use it at your own discretion.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
