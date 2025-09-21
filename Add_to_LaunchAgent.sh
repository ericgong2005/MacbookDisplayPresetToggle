# Assume the toggle_preset_hotkey binary is in the current directory
BIN_PATH="$(pwd)/toggle_preset_hotkey"

# Generate LaunchAgentCommand.xml with the correct path baked in
cat > ./LaunchAgentCommand.xml <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN"
 "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>com.user.toggle-preset-hotkey</string>

  <key>ProgramArguments</key>
  <array>
    <string>$BIN_PATH</string>
  </array>

  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>

  <key>StandardOutPath</key>
  <string>/tmp/toggle_preset_hotkey.out</string>
  <key>StandardErrorPath</key>
  <string>/tmp/toggle_preset_hotkey.err</string>
</dict>
</plist>
EOF

# Install it into LaunchAgents
DEST=~/Library/LaunchAgents/com.user.toggle-preset-hotkey.plist
mkdir -p ~/Library/LaunchAgents
touch "$DEST"
cat ./LaunchAgentCommand.xml > "$DEST"

# Reload the agent
launchctl unload "$DEST" 2>/dev/null || true
launchctl load "$DEST"
