#!/bin/bash
set -e

echo "=========================================="
echo "BTT CB1 Klipper Optimization Script"
echo "=========================================="
echo ""

# Optimize APT configuration for embedded system
echo "Configuring APT optimizations..."
sudo tee /etc/apt/apt.conf.d/99optimizations > /dev/null << EOF
Acquire::Queue-Mode "host";
Acquire::Retries "3";
Acquire::IndexTargets::deb::Contents::Meta-Size "0";
Acquire::Languages "none";
APT::Install-Recommends "false";
APT::Install-Suggests "false";
EOF

# Reduce systemd journal size
echo "Configuring journal limits..."
sudo mkdir -p /etc/systemd/journald.conf.d
sudo tee /etc/systemd/journald.conf.d/size-limit.conf > /dev/null << EOF
[Journal]
SystemMaxUse=100M
SystemMaxFileSize=10M
MaxRetentionSec=1week
EOF

# Disable automatic package upgrades, modify apt-daily to weekly
echo "Configuring update timers..."
sudo systemctl disable --now apt-daily-upgrade.timer
sudo systemctl mask apt-daily-upgrade.service

# Disable unnecessary services
echo "Disabling unnecessary services..."
sudo systemctl disable --now man-db.timer
sudo systemctl disable --now ModemManager.service 2>/dev/null || true

# Install useful tools
echo "Installing tools..."
sudo apt update
sudo apt install -y git micro
sudo apt autoremove -y

# Create shell aliases and environment
echo "Creating aliases..."
sudo tee /etc/profile.d/custom-aliases.sh > /dev/null << 'EOF'
# File listing aliases
export TIME_FORMAT="%y %b %d, %I:%M:%S %p"
export LS_OPTIONS='--group-directories-first --color=auto --time-style=+"$TIME_FORMAT"'
eval "$(dircolors 2>/dev/null || dircolors -b)"
alias ls="ls $LS_OPTIONS"
alias ll="ls -lh"
alias la="ls -lAh"

# Editor aliases
alias e=micro
export EDITOR=micro

# Update/cleanup aliases
alias update='sudo apt update && sudo apt list --upgradable'
alias upgrade='sudo apt upgrade -y && sudo apt autoremove -y'
alias clean='sudo sh -c "apt autoremove -y && apt clean && sync && echo && df -h /"'

# Klipper log aliases
alias klogs="journalctl -fu klipper"
alias mlog="journalctl -fu moonraker"

# Temperature check
alias temp="cat /sys/class/thermal/thermal_zone0/temp | awk '{print \$1/1000}'"
EOF

sudo chmod 644 /etc/profile.d/custom-aliases.sh

# Apply changes
echo "Applying configuration changes..."
sudo systemctl daemon-reload
sudo systemctl restart systemd-journald

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Changes made:"
echo "  ✓ APT optimized for embedded system"
echo "  ✓ Journal limited to 100MB, 1 week retention"
echo "  ✓ Auto-upgrades disabled"
echo "  ✓ Unnecessary services disabled"
echo "  ✓ Useful aliases added (ll, la, e, update, upgrade, cleanup, klogs, mlog, temp)"
echo ""
echo "  ! Use 'update' to check for updates, 'upgrade' to install them."
echo ""
