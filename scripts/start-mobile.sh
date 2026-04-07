#!/bin/bash
# Start Flutter mobile app (development mode)
# Usage: ./scripts/start-mobile.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
MOBILE_DIR="$ROOT_DIR/apps/mobile"

echo "Starting Meow Flutter app..."
echo "Working directory: $MOBILE_DIR"

cd "$MOBILE_DIR"

# Get dependencies
echo "Getting Flutter dependencies..."
flutter pub get

# Run the app
echo "Running Flutter app..."
flutter run
