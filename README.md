# AWS VPS Setup Panel

A lightweight, interactive Bash setup panel for configuring an AWS VPS with a simple terminal UI.

The project is designed around `roote.sh` and provides an interactive menu for enabling root SSH login, changing the hostname, and checking the current SSH/system status. The script includes colored output, progress animations, validation, and recovery handling. fileciteturn0file0L3-L8

## Features

- Interactive terminal-based setup panel
- Enable **root SSH login**
- Enable **SSH password authentication**
- Set or change the root password
- Change the VPS hostname
- Automatically update `/etc/hostname`
- Automatically update `/etc/hosts`
- Check SSH configuration before restarting the SSH service
- Automatic recovery if the generated SSH override is invalid
- View current hostname and SSH status
- Colored status messages
- Animated progress bars
- Spinner while commands are running
- Typewriter-style startup screen
- Safe terminal input handling
- Prevents accidental use through a non-interactive pipe such as `curl ... | bash`

## Menu

When launched, the panel provides:

```text
1) Enable ROOT Login
2) Change HOSTNAME
3) ROOT Login + HOSTNAME
4) Show Status
0) Exit
```

These options are implemented directly in the main interactive menu. fileciteturn0file0L492-L530

## Requirements

- Linux VPS
- Bash
- Root/sudo access
- OpenSSH server
- `systemd`
- An interactive terminal

The script checks that it is being executed as root before continuing. fileciteturn0file0L195-L205

## Installation

Clone the repository:

```bash
git clone https://github.com/YOUR-USERNAME/YOUR-REPOSITORY.git
cd YOUR-REPOSITORY
```

Make the script executable:

```bash
chmod +x roote.sh
```

Run it as root:

```bash
sudo ./roote.sh
```

Or:

```bash
sudo bash roote.sh
```

## Important: Run Interactively

This script intentionally requires a real terminal for user input.

Do **not** run it like:

```bash
curl https://example.com/roote.sh | bash
```

The script reads menu input from `/dev/tty` and exits if an interactive terminal is unavailable. This prevents the menu from entering an invalid-input loop when stdin is piped. fileciteturn0file0L62-L83

## Root SSH Configuration

The root-login option creates an SSH override at:

```text
/etc/ssh/sshd_config.d/99-root-login.conf
```

with:

```text
PermitRootLogin yes
PasswordAuthentication yes
```

Before replacing an existing override, the script creates a timestamped backup. It also checks the AWS cloud-init SSH configuration when applicable. fileciteturn0file0L247-L280

After making changes, the script validates the SSH configuration using:

```bash
sshd -t
```

Only after successful validation does it restart the SSH service. If validation fails, it attempts to remove the generated override and restore the previous working configuration. fileciteturn0file0L285-L313

## Hostname Configuration

The hostname option:

1. Displays the current hostname.
2. Requests a new hostname.
3. Validates the hostname format.
4. Runs `hostnamectl`.
5. Updates `/etc/hostname`.
6. Updates or creates the `127.0.1.1` entry in `/etc/hosts`.

Allowed hostname characters include letters, numbers, hyphens, and dots. fileciteturn0file0L370-L399

## System Status

The status screen displays:

- Current hostname
- Root SSH login state
- Password authentication state
- SSH service state

The script uses `sshd -T` to inspect the effective SSH configuration and `systemctl` to check whether SSH is running. fileciteturn0file0L448-L486

## Safety Notes

Enabling root login and password-based SSH authentication can increase the attack surface of a VPS.

For production servers, consider using:

- SSH keys instead of passwords
- Firewall rules
- Fail2ban or another authentication protection mechanism
- Disabled root password authentication where possible
- Restricted SSH access
- Regular system updates

This project changes SSH authentication settings, so make sure you have another working access method before applying SSH configuration changes.

## Project Structure

```text
.
├── roote.sh
└── README.md
```

## Example

```text
+==========================================+
| AWS VPS SETUP PANEL                      |
+==========================================+

Hostname: my-server

[OK] Root SSH Login: ENABLED

--------------------------------------------

1) Enable ROOT Login
2) Change HOSTNAME
3) ROOT Login + HOSTNAME
4) Show Status
0) Exit
```

## Compatibility

The script is intended for Linux VPS environments using OpenSSH and systemd. It is particularly focused on AWS VPS instances and includes handling for AWS cloud-init SSH settings. fileciteturn0file0L243-L280

## Contributing

Pull requests and improvements are welcome.

When submitting changes:

1. Keep the script compatible with Bash.
2. Validate SSH configuration changes before restarting SSH.
3. Avoid breaking interactive terminal input.
4. Test changes on a disposable VPS before production use.

## License

Add your preferred license here, for example:

```text
MIT License
```

If you intend to publish this project publicly, choose a license that matches how you want others to use and modify the project.
