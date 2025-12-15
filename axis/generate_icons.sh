#!/bin/bash

# Source images
LIGHT_SOURCE="/Users/diggy/Productive/light-icon.png"
DARK_SOURCE="/Users/diggy/Productive/dark-icon.png"
DEST_DIR="/Users/diggy/Productive/axis/ios/Runner/Assets.xcassets/AppIcon.appiconset"

# Create directory if it doesn't exist
mkdir -p "$DEST_DIR"

echo "Generating light mode icons..."
# Generate all required icon sizes for light mode
sips -z 40 40 "$LIGHT_SOURCE" --out "$DEST_DIR/Icon-App-20x20@1x.png"
sips -z 60 60 "$LIGHT_SOURCE" --out "$DEST_DIR/Icon-App-20x20@2x.png"
sips -z 60 60 "$LIGHT_SOURCE" --out "$DEST_DIR/Icon-App-20x20@3x.png"
sips -z 29 29 "$LIGHT_SOURCE" --out "$DEST_DIR/Icon-App-29x29@1x.png"
sips -z 58 58 "$LIGHT_SOURCE" --out "$DEST_DIR/Icon-App-29x29@2x.png"
sips -z 87 87 "$LIGHT_SOURCE" --out "$DEST_DIR/Icon-App-29x29@3x.png"
sips -z 40 40 "$LIGHT_SOURCE" --out "$DEST_DIR/Icon-App-40x40@1x.png"
sips -z 80 80 "$LIGHT_SOURCE" --out "$DEST_DIR/Icon-App-40x40@2x.png"
sips -z 120 120 "$LIGHT_SOURCE" --out "$DEST_DIR/Icon-App-40x40@3x.png"
sips -z 120 120 "$LIGHT_SOURCE" --out "$DEST_DIR/Icon-App-60x60@2x.png"
sips -z 180 180 "$LIGHT_SOURCE" --out "$DEST_DIR/Icon-App-60x60@3x.png"
sips -z 76 76 "$LIGHT_SOURCE" --out "$DEST_DIR/Icon-App-76x76@1x.png"
sips -z 152 152 "$LIGHT_SOURCE" --out "$DEST_DIR/Icon-App-76x76@2x.png"
sips -z 167 167 "$LIGHT_SOURCE" --out "$DEST_DIR/Icon-App-83.5x83.5@2x.png"
sips -z 1024 1024 "$LIGHT_SOURCE" --out "$DEST_DIR/Icon-App-1024x1024@1x.png"

echo "Generating dark mode icons..."
# Generate all required icon sizes for dark mode
sips -z 40 40 "$DARK_SOURCE" --out "$DEST_DIR/Icon-App-20x20@1x-dark.png"
sips -z 60 60 "$DARK_SOURCE" --out "$DEST_DIR/Icon-App-20x20@2x-dark.png"
sips -z 60 60 "$DARK_SOURCE" --out "$DEST_DIR/Icon-App-20x20@3x-dark.png"
sips -z 29 29 "$DARK_SOURCE" --out "$DEST_DIR/Icon-App-29x29@1x-dark.png"
sips -z 58 58 "$DARK_SOURCE" --out "$DEST_DIR/Icon-App-29x29@2x-dark.png"
sips -z 87 87 "$DARK_SOURCE" --out "$DEST_DIR/Icon-App-29x29@3x-dark.png"
sips -z 40 40 "$DARK_SOURCE" --out "$DEST_DIR/Icon-App-40x40@1x-dark.png"
sips -z 80 80 "$DARK_SOURCE" --out "$DEST_DIR/Icon-App-40x40@2x-dark.png"
sips -z 120 120 "$DARK_SOURCE" --out "$DEST_DIR/Icon-App-40x40@3x-dark.png"
sips -z 120 120 "$DARK_SOURCE" --out "$DEST_DIR/Icon-App-60x60@2x-dark.png"
sips -z 180 180 "$DARK_SOURCE" --out "$DEST_DIR/Icon-App-60x60@3x-dark.png"
sips -z 76 76 "$DARK_SOURCE" --out "$DEST_DIR/Icon-App-76x76@1x-dark.png"
sips -z 152 152 "$DARK_SOURCE" --out "$DEST_DIR/Icon-App-76x76@2x-dark.png"
sips -z 167 167 "$DARK_SOURCE" --out "$DEST_DIR/Icon-App-83.5x83.5@2x-dark.png"
sips -z 1024 1024 "$DARK_SOURCE" --out "$DEST_DIR/Icon-App-1024x1024@1x-dark.png"

echo "✅ All icon sizes generated for both light and dark modes!"
