#!/bin/zsh
set -e
cd "$(dirname "$0")"
swift build -c release
rm -rf NanoBanana.app
mkdir -p NanoBanana.app/Contents/MacOS
cp .build/release/NanoBanana NanoBanana.app/Contents/MacOS/
cat > NanoBanana.app/Contents/Info.plist <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>NanoBanana</string>
    <key>CFBundleDisplayName</key><string>Nano Banana 2</string>
    <key>CFBundleIdentifier</key><string>local.nanobanana.app</string>
    <key>CFBundleExecutable</key><string>NanoBanana</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
</dict>
</plist>
EOF
echo "Built NanoBanana.app"
