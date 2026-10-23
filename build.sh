#!/bin/zsh
# Builds Sonnov.app (menu bar only, no Dock icon).
set -e
cd "$(dirname "$0")"
swift build -c release
APP=Sonnov.app
rm -rf $APP
mkdir -p $APP/Contents/MacOS
cp .build/release/Sonnov $APP/Contents/MacOS/
cat > $APP/Contents/Info.plist <<P
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>Sonnov</string>
<key>CFBundleIdentifier</key><string>com.stephanepoulin.sonnov</string>
<key>CFBundleName</key><string>Sonnov</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleVersion</key><string>1</string>
<key>LSUIElement</key><true/>
<key>CFBundleURLTypes</key><array><dict>
<key>CFBundleURLName</key><string>com.stephanepoulin.sonnov</string>
<key>CFBundleURLSchemes</key><array><string>sonnov</string></array>
</dict></array>
<key>NSAppTransportSecurity</key><dict><key>NSAllowsArbitraryLoads</key><true/></dict>
</dict></plist>
P
codesign --force --sign - $APP
echo "Built $APP"
