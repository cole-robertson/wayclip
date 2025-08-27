#!/bin/bash
# Uninstaller for Wayland Clipboard Manager

SERVICE_NAME="clipboard-manager"
SCRIPT_PATH="$HOME/.local/bin/clipboard_manager.rb"

echo "🗑️  Uninstalling Wayland Clipboard Manager..."

# Stop and disable service
systemctl --user stop "$SERVICE_NAME.service" 2>/dev/null
systemctl --user disable "$SERVICE_NAME.service" 2>/dev/null

# Remove service file
rm -f "$HOME/.config/systemd/user/$SERVICE_NAME.service"

# Remove the script itself
if [ -f "$SCRIPT_PATH" ]; then
    rm -f "$SCRIPT_PATH"
    echo "✅ Removed clipboard manager script"
fi

# Reload systemd
systemctl --user daemon-reload

echo "✅ Service uninstalled"
echo ""
echo "Note: Saved images remain in ~/Desktop/clipboard-images/"
echo "Remove them manually if desired: rm -rf ~/Desktop/clipboard-images"