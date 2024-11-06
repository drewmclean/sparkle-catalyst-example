#!/bin/bash
REPOSITORY_ROOT="$CI_WORKSPACE_PATH/repository"
CI_SCRIPTS_PATH="$REPOSITORY_ROOT/CarrotApp/ci_scripts"
source "$CI_SCRIPTS_PATH/constants.sh"


SPARKLE_VERSION="2.6.4"
SPARKLE_URL="https://github.com/sparkle-project/Sparkle/releases/download/${SPARKLE_VERSION}/Sparkle-for-Swift-Package-Manager.zip"

# download and install Sparkle
install_sparkle() {
  echo "Downloading Sparkle from $SPARKLE_URL"
  # Create directory for Sparkle
  mkdir -p "$SPARKLE_DIR"

  # Download Sparkle
  curl -L "$SPARKLE_URL" -o "$SPARKLE_DIR/Sparkle.zip"

  # Unzip the Sparkle archive
  echo "Extracting Sparkle"
  unzip -o "$SPARKLE_DIR/Sparkle.zip" -d "$SPARKLE_DIR"

  # Remove the zip file
  rm "$SPARKLE_DIR/Sparkle.zip"
  echo "Sparkle installed at $SPARKLE_DIR"
}


install_sparkle
