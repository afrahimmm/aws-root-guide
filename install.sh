#!/bin/bash

echo "======================================="
echo "   🚀 RDXHERE AUTO INSTALL SCRIPT"
echo "======================================="

# Ensure running as root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root (use sudo -i)"
  exit
fi

echo "📦 Updating system..."
apt update -y

echo "🖥️ Setting hostname..."
hostnamectl set-hostname rdxhere

# Update hosts file
echo "✏️ Updating /etc/hosts..."
sed -i 's/127.0.1.1.*/127.0.1.1 rdxhere/g' /etc/hosts || echo "127.0.1.1 rdxhere" >> /etc/hosts

echo "🎨 Creating custom MOTD..."
cat << 'EOF' > /etc/update-motd.d/99-custom
#!/bin/bash
echo "======================================="
echo "        🚀 RDXHERE SERVER"
echo "======================================="
echo "User:        $(whoami)"
echo "Hostname:    $(hostname)"
echo "IP:          $(hostname -I | awk '{print $1}')"
echo "Uptime:      $(uptime -p)"
echo "Memory:      $(free -h | awk '/Mem:/ {print $3 "/" $2}')"
echo "Disk:        $(df -h / | awk 'NR==2 {print $3 "/" $2}')"
echo "---------------------------------------"
echo "Discord:     rdxhere.exe"
echo "Support:     https://discord.gg/heartbeat"
echo "======================================="
echo "   ⚡ Powered by rdxhere.exe"
echo "======================================="
EOF

chmod +x /etc/update-motd.d/99-custom

echo "🧹 Removing default Ubuntu MOTD..."
chmod -x /etc/update-motd.d/* 2>/dev/null
chmod +x /etc/update-motd.d/99-custom

echo "🔐 Installing security tools..."
apt install ufw fail2ban -y

echo "🛡️ Configuring firewall..."
ufw allow OpenSSH
ufw --force enable

echo "⚙️ Disabling last login message..."
if grep -q "^PrintLastLog" /etc/ssh/sshd_config; then
  sed -i 's/^PrintLastLog.*/PrintLastLog no/' /etc/ssh/sshd_config
else
  echo "PrintLastLog no" >> /etc/ssh/sshd_config
fi

systemctl restart ssh

echo "======================================="
echo "✅ INSTALLATION COMPLETE!"
echo "👉 Re-login to see changes"
echo "======================================="
