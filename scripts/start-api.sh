#!/bin/bash
# Start API server (development mode)
# Usage: ./scripts/start-api.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
API_DIR="$ROOT_DIR/apps/api"

echo "Starting Meow API server..."
echo "Working directory: $API_DIR"

cd "$API_DIR"

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
  echo "Installing dependencies..."
  npm install
fi

# Start development server
echo "Starting development server..."
npm run start:dev
