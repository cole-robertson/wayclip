# Wayland Clipboard Manager

A clipboard manager that understands context. Paste images as file paths in your terminal, and as actual images in Discord - automatically.

## The Problem

You take a screenshot to share with a colleague. In Discord, you want to paste the image. In your terminal, you need the file path. Currently, you're stuck manually saving files or typing paths. It's the kind of friction that breaks your flow a hundred times a day.

## The Solution

This tool watches your clipboard and switches formats based on your focused window. Copy once, paste appropriately everywhere. Your terminal gets paths, your chat apps get images. Zero configuration, zero thinking required.

## 🚀 Quick Start

```bash
# One-line install
curl -sL https://raw.githubusercontent.com/cole-robertson/wayland-clipboard-manager/main/install.sh | bash
```

That's it! The service is now running and will persist across restarts.

## ✨ Features

- **Auto-saves images**: All copied images saved with timestamps (configurable location)
- **Smart context switching**: Automatically detects terminal vs GUI apps
- **Auto-cleanup**: Removes old images after 7 days (configurable)
- **Zero configuration**: Works instantly after install
- **Lightweight**: ~150 lines of Ruby, minimal CPU usage
- **Persistent**: Runs as a systemd user service

## 🎯 How It Works

1. Copy any image (screenshot, download, etc.)
2. Focus on your terminal → `Ctrl+V` pastes the file path
3. Focus on Discord → `Ctrl+V` pastes the actual image
4. No manual switching needed!

## 📋 Supported Apps

**Get file paths in:**
- Ghostty, Alacritty, Kitty, WezTerm
- VS Code, Vim, Emacs, Zed
- Any terminal emulator

**Get images in:**
- Discord, Slack, Teams
- Web browsers
- Any non-terminal app

## 🛠️ Requirements

- Wayland session (Hyprland/Sway)
- Ruby (installed automatically)
- wl-clipboard (installed automatically)

**Note:** Without Hyprland/Sway, images are still saved but format switching is disabled

## 📌 Usage

After installation, the service runs automatically. No interaction needed!

### Service Commands
```bash
# Check status
systemctl --user status clipboard-manager

# View logs
journalctl --user -u clipboard-manager -f

# Restart
systemctl --user restart clipboard-manager

# Stop
systemctl --user stop clipboard-manager
```

### Uninstall
```bash
./uninstall.sh
```

## 🔧 Configuration

### Save Directory
Set `CLIPBOARD_SAVE_DIR` to change where images are stored:

```bash
export CLIPBOARD_SAVE_DIR=~/Pictures/screenshots
```

Default: `~/Desktop/clipboard-images`

### Image Retention
Set `CLIPBOARD_RETENTION_DAYS` to control how long images are kept:

```bash
export CLIPBOARD_RETENTION_DAYS=14  # Keep for 2 weeks
export CLIPBOARD_RETENTION_DAYS=0   # Disable auto-cleanup
```

Default: `7` days (based on last access time)

### Customization

Edit `clipboard_manager.rb` to:
- Add app patterns (line 10)
- Adjust polling rate

## 🐛 Troubleshooting

**Not switching?**
```bash
# Check if running
systemctl --user status clipboard-manager

# Check Wayland
echo $XDG_SESSION_TYPE  # Should be "wayland"

# Check Hyprland
hyprctl version

# Test clipboard
echo test | wl-copy && wl-paste
```

**Wrong app detection?**
```bash
# See what window is detected
journalctl --user -u clipboard-manager -f
# Copy an image and watch the logs
```

## 📄 License

MIT - Use however you want!

## 🤝 Contributing
If you want to change something, you can just edit the file! Send a PR if you find a bug of if you think others could benefit from the change too.
