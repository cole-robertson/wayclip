#!/bin/bash
# One-command installer for Wayclip

set -e

# Installation paths
INSTALL_DIR="$HOME/.local/bin"
SCRIPT_PATH="$INSTALL_DIR/clipboard_manager.rb"
SERVICE_NAME="wayclip"
GITHUB_RAW="https://raw.githubusercontent.com/cole-robertson/wayclip/main"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📋 Wayclip Installer"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check Wayland
if [ "$XDG_SESSION_TYPE" != "wayland" ]; then
    echo "❌ Error: Not running on Wayland (detected: $XDG_SESSION_TYPE)"
    echo "   This tool requires a Wayland session."
    exit 1
fi

# Check required dependencies
echo "📦 Checking required dependencies..."
MISSING_DEPS=""

if ! command -v ruby &> /dev/null; then
    MISSING_DEPS="$MISSING_DEPS ruby"
fi

if ! command -v wl-copy &> /dev/null || ! command -v wl-paste &> /dev/null; then
    MISSING_DEPS="$MISSING_DEPS wl-clipboard"
fi

if [ -n "$MISSING_DEPS" ]; then
    echo "   Missing:$MISSING_DEPS"
    echo "   Installing required packages..."
    sudo apt update && sudo apt install -y $MISSING_DEPS || {
        echo "❌ Failed to install dependencies"
        exit 1
    }
else
    echo "   ✓ All required dependencies installed"
fi

# Check for Hyprland/Sway
echo ""
echo "🔍 Checking window manager..."

FEATURES=""
if command -v hyprctl &> /dev/null; then
    echo "   ✓ Hyprland detected"
    FEATURES="auto-switch"
elif command -v swaymsg &> /dev/null; then
    echo "   ✓ Sway detected (Note: Sway support is experimental)"
    FEATURES="auto-switch"
else
    echo "   ⚠️  Warning: Hyprland/Sway not found"
    echo "   The manager will save images but won't auto-switch formats."
    echo "   Install Hyprland for the best experience."
    FEATURES="save-only"
fi

# Download the clipboard manager script
echo ""
echo "📥 Downloading clipboard manager..."
mkdir -p "$INSTALL_DIR"
curl -sL "$GITHUB_RAW/clipboard_manager.rb" -o "$SCRIPT_PATH" || {
    echo "❌ Failed to download clipboard manager"
    exit 1
}
chmod +x "$SCRIPT_PATH"
echo "   ✓ Downloaded to $SCRIPT_PATH"

# Create directories
mkdir -p "$HOME/Desktop/clipboard-images"
mkdir -p "$HOME/.config/systemd/user"

# Create systemd service
echo "🔧 Creating systemd service..."
cat > "$HOME/.config/systemd/user/$SERVICE_NAME.service" << EOF
[Unit]
Description=Wayclip - Auto-switch clipboard image/path for terminals
After=graphical-session.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=always
RestartSec=1
ExecStart=$SCRIPT_PATH

[Install]
WantedBy=default.target
EOF

# Enable and start service
echo "🚀 Starting service..."
systemctl --user daemon-reload
systemctl --user enable "$SERVICE_NAME.service"
systemctl --user restart "$SERVICE_NAME.service"

# Check status
sleep 1
if systemctl --user is-active --quiet "$SERVICE_NAME.service"; then
    echo ""
    echo "✅ Installation complete!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    if [ "$FEATURES" = "auto-switch" ]; then
        echo "The clipboard manager is now running and will:"
        echo "• Save all copied images to ~/Desktop/clipboard-images/"
        echo "• Auto-switch to file paths in terminals/editors"
        echo "• Keep images for Discord/Slack/chat apps"
    else
        echo "The clipboard manager is running (limited mode):"
        echo "• Save all copied images to ~/Desktop/clipboard-images/"
        echo "• No automatic format switching"
        echo ""
        echo "⚠️  Install Hyprland for automatic format switching"
    fi
    echo ""
    echo "📌 Commands:"
    echo "   Status:  systemctl --user status $SERVICE_NAME"
    echo "   Logs:    journalctl --user -u $SERVICE_NAME -f"
    echo "   Stop:    systemctl --user stop $SERVICE_NAME"
    echo "   Restart: systemctl --user restart $SERVICE_NAME"
    echo ""
else
    echo "❌ Service failed to start. Check logs with:"
    echo "   journalctl --user -u $SERVICE_NAME -e"
    exit 1
fi