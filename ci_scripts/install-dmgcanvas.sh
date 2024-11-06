#!/bin/bash
REPOSITORY_ROOT="$CI_WORKSPACE_PATH/repository"
CI_SCRIPTS_PATH="$REPOSITORY_ROOT/CarrotApp/ci_scripts"
source "$CI_SCRIPTS_PATH/constants.sh"

DMG_CANVAS_VERSION="4.0.9"
DMG_CANVAS_URL="https://arweb-assets.s3.amazonaws.com/downloads/dmgcanvas/versions/DMGCanvas$DMG_CANVAS_VERSION.zip"

# download and install DMGCanvas
install_dmgcanvas() {
  echo "installing dmg-canvas..."

  # Create the directory if it doesn't exist
  mkdir -p "$DMG_CANVAS_DIR"

  # Download the dmg-canvas archive
  curl -L "$DMG_CANVAS_URL" -o "$DMG_CANVAS_DIR/dmg-canvas.zip"
  if [ $? -ne 0 ]; then
      echo "Failed to download dmg-canvas"
      exit 1
  fi

  # Unzip the dmg-canvas archive
  echo "Extracting dmg-canvas..."
  unzip -o "$DMG_CANVAS_DIR/dmg-canvas.zip" -d "$DMG_CANVAS_DIR"
  if [ $? -ne 0 ]; then
    echo "Failed to extract dmg-canvas"
    exit 1
  fi

  # execute access

  chmod +x "$DMG_CANVAS_EXECUTABLE"
  export PATH="$DMG_CANVAS_DIR:$PATH"

  echo "dmg-canvas setup successfully"
}

install_dmgcanvas
