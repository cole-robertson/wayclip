#!/bin/bash
# Uninstaller for Wayland Clipboard Manager

SERVICE_NAME="clipboard-manager"

echo "🗑️  Uninstalling Wayland Clipboard Manager..."

# Stop and disable service
systemctl --user stop "$SERVICE_NAME.service" 2>/dev/null
systemctl --user disable "$SERVICE_NAME.service" 2>/dev/null

# Remove service file
rm -f "$HOME/.config/systemd/user/$SERVICE_NAME.service"

# Reload systemd
systemctl --user daemon-reload

echo "✅ Service uninstalled"
echo ""
echo "Note: Saved images remain in ~/Desktop/claude-images/"
echo "Remove them manually if desired: rm -rf ~/Desktop/claude-images"