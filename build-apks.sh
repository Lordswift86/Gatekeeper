#!/bin/zsh

# GateKeeper APK Build Script
# This script builds APKs for all three Flutter apps

set -e  # Exit on error

echo "🚀 Starting GateKeeper APK Builds..."
echo ""

# Get the base directory
BASE_DIR="$HOME/Desktop/AI PROJECTS/Gatekeeper"
# FLUTTER_BIN="$BASE_DIR/gatekeeper_resident_flutter/flutter_sdk/flutter/bin/flutter"
FLUTTER_BIN="flutter" # Assuming flutter is in PATH

# Build Estate Admin
echo "📱 Building Estate Admin APK..."
cd "$BASE_DIR/mobile/estate_admin"
$FLUTTER_BIN clean
$FLUTTER_BIN build apk --release
echo "✅ Estate Admin APK built!"
echo ""

# Build Resident
echo "📱 Building Resident APK..."
cd "$BASE_DIR/mobile/resident"
$FLUTTER_BIN clean
$FLUTTER_BIN build apk --release
echo "✅ Resident APK built!"
echo ""

# Build Security
echo "📱 Building Security APK..."
cd "$BASE_DIR/mobile/security"
$FLUTTER_BIN clean
$FLUTTER_BIN build apk --release
echo "✅ Security APK built!"
echo ""

echo "🎉 All APKs built successfully!"
echo ""
echo "📦 APKs are located at:"
echo "  • Estate Admin: mobile/estate_admin/build/app/outputs/flutter-apk/app-release.apk"
echo "  • Resident: mobile/resident/build/app/outputs/flutter-apk/app-release.apk"
echo "  • Security: mobile/security/build/app/outputs/flutter-apk/app-release.apk"
