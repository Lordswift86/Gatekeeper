#!/bin/zsh

# GateKeeper APK Build Script
# This script builds APKs for all three Flutter apps

set -e  # Exit on error

echo "🚀 Starting GateKeeper APK Builds..."
echo ""

# Get the base directory
BASE_DIR="$HOME/Desktop/AI PROJECTS/Gatekeeper"
FLUTTER_BIN="$BASE_DIR/gatekeeper_resident_flutter/flutter_sdk/flutter/bin/flutter"

# Build Estate Admin
echo "📱 Building Estate Admin APK..."
cd "$BASE_DIR/gatekeeper_estate_admin_flutter"
$FLUTTER_BIN clean
$FLUTTER_BIN build apk --release
echo "✅ Estate Admin APK built!"
echo ""

# Build Resident
echo "📱 Building Resident APK..."
cd "$BASE_DIR/gatekeeper_resident_flutter"
$FLUTTER_BIN clean
$FLUTTER_BIN build apk --release
echo "✅ Resident APK built!"
echo ""

# Build Security
echo "📱 Building Security APK..."
cd "$BASE_DIR/gatekeeper_security_flutter"
$FLUTTER_BIN clean
$FLUTTER_BIN build apk --release
echo "✅ Security APK built!"
echo ""

echo "🎉 All APKs built successfully!"
echo ""
echo "📦 APKs are located at:"
echo "  • Estate Admin: gatekeeper_estate_admin_flutter/build/app/outputs/flutter-apk/app-release.apk"
echo "  • Resident: gatekeeper_resident_flutter/build/app/outputs/flutter-apk/app-release.apk"
echo "  • Security: gatekeeper_security_flutter/build/app/outputs/flutter-apk/app-release.apk"
