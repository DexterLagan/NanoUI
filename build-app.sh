#!/bin/zsh
set -e
cd "$(dirname "$0")"
swift build -c release
rm -rf NanoUI.app
mkdir -p NanoUI.app/Contents/MacOS
cp .build/release/NanoUI NanoUI.app/Contents/MacOS/
cat > NanoUI.app/Contents/Info.plist <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>NanoUI</string>
    <key>CFBundleDisplayName</key><string>NanoUI</string>
    <key>CFBundleIdentifier</key><string>local.nanoui.app</string>
    <key>CFBundleExecutable</key><string>NanoUI</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
</dict>
</plist>
EOF
echo "Built NanoUI.app"
