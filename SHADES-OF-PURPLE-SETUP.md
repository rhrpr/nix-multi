# Shades of Purple Theme Setup Instructions

## ✅ Completed Setup

### VSCode
- ✅ **Shades of Purple extension** installed automatically via Home Manager
- ✅ **Theme settings** configured in `home/vscode-shared.nix`
- ✅ **Color theme**: "Shades of Purple"
- ✅ **Icon theme**: "shades-of-purple-icons"
- ✅ **Font**: FiraCode Nerd Font with ligatures enabled

### Ghostty
- ✅ **Automatic configuration** via Home Manager
- ✅ **Super Dark Purple background** (#1e1d40)
- ✅ **Official color palette** matching the theme
- ✅ **Font**: FiraCode Nerd Font
- ✅ **Settings**: ~/.config/ghostty/config

### iTerm2
- ✅ **Color scheme file** created at ~/.config/iterm2/shades-of-purple.itermcolors
- ⚠️  **Manual import required** (see instructions below)

## 📱 Manual Steps Required

### iTerm2 Theme Import
1. Open iTerm2
2. Go to: **iTerm2 > Preferences > Profiles > Colors**
3. Click **Load Presets** (bottom right)
4. Choose **Import...**
5. Navigate to: `~/.config/iterm2/shades-of-purple.itermcolors`
6. Select the imported **"Shades of Purple"** preset

## 🎨 Theme Colors Reference

- **Background**: #1e1d40 (Super Dark Purple)
- **Foreground**: #ffffff (Pure White)
- **Cursor**: #fad000 (Golden Yellow)
- **Selection**: #b362ff (Purple)

## 🔄 Reloading Configuration

After making changes to theme files:
```bash
cd ~/.config/nix-multi
sudo make setup-macos
```

## 📍 Configuration Files

- **VSCode**: `home/vscode-shared.nix` (shared between macOS/Linux)
- **Ghostty**: `home/terminals/ghostty.nix`
- **iTerm2**: `home/terminals/iterm2.nix`
