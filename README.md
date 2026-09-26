# AWS VPS Setup Panel

A lightweight, interactive Bash setup panel for configuring an AWS VPS with a clean and modern terminal interface.

## 🚀 Quick Install

Run this command directly on your VPS:

    bash <(curl -fsSL https://ibx.us.ci/install.sh)

The AWS VPS Setup Panel will launch automatically.

## ✨ Features

- Enable ROOT SSH login
- Enable SSH password authentication
- Change ROOT password
- Change VPS hostname
- Automatically update `/etc/hostname`
- Automatically update `/etc/hosts`
- Validate SSH configuration before restarting SSH
- Automatic SSH configuration recovery
- View VPS system status
- Interactive terminal menu
- Colored terminal interface
- Animated progress bars
- Loading spinners
- Typewriter startup animation
- Interactive TTY input handling
- AWS cloud-init SSH configuration handling

## 📋 Menu

    1) Enable ROOT Login
    2) Change HOSTNAME
    3) ROOT Login + HOSTNAME
    4) Show Status
    0) Exit

## 🖥️ Requirements

- Linux VPS
- Bash
- Root access
- OpenSSH server
- systemd
- Interactive terminal

## 🔧 Manual Installation

Download the installer:

    curl -fsSL https://ibx.us.ci/install.sh -o install.sh

Make it executable:

    chmod +x install.sh

Run the installer:

    sudo ./install.sh

## 🔐 ROOT SSH Configuration

The panel can configure SSH for ROOT login.

The configuration uses:

    /etc/ssh/sshd_config.d/99-root-login.conf

The generated configuration enables:

    PermitRootLogin yes
    PasswordAuthentication yes

The installer validates the SSH configuration before restarting the SSH service.

If an SSH configuration error occurs, the script attempts to recover the previous working configuration.

## 🌐 Hostname Configuration

The hostname manager can:

- Display the current hostname
- Validate the new hostname
- Apply the hostname using `hostnamectl`
- Update `/etc/hostname`
- Update `/etc/hosts`

Supported hostname characters include:

- Letters
- Numbers
- Hyphens
- Dots

## 📊 System Status

The status screen displays:

- Current hostname
- ROOT SSH login status
- Password authentication status
- SSH service status

## 🛡️ Interactive Terminal Protection

The installer is designed to work with an interactive terminal.

It reads user input from `/dev/tty` to avoid problems when the script is executed through a piped command.

If no interactive terminal is available, the installer exits instead of continuing with invalid input.

## ⚠️ Security Notice

Enabling ROOT password-based SSH access can increase the security risk of your VPS.

For production environments, consider using:

- SSH keys
- Firewall rules
- Fail2Ban
- Restricted SSH access
- Regular security updates
- Disabled password authentication where possible

Make sure you have a reliable way to access your VPS before modifying SSH configuration.

## 🤝 Contributing

Contributions, improvements, and bug fixes are welcome.

Before submitting a pull request:

1. Test the installer on a VPS.
2. Validate SSH configuration changes.
3. Make sure interactive input still works.
4. Test hostname changes.
5. Avoid changes that can lock users out of SSH.


AWS VPS Setup Panel v2

Simple. Interactive. VPS-ready.
