#!/bin/bash

# Exit immediately if any command fails and fail on pipe failures
set -e

#
# Installs all dependencies used in direct distribution release script
#

REPOSITORY_ROOT="$CI_WORKSPACE_PATH/repository"
CI_SCRIPTS_PATH="$REPOSITORY_ROOT/CarrotApp/ci_scripts"

source "$CI_SCRIPTS_PATH/constants.sh"

echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Install DMG Canvas"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

## Install DMG Canvas via zip - the issue with this is it generates a /Volumes/workspace/dmg-canvas
DMGCANVAS_SCRIPT_PATH="$CI_SCRIPTS_PATH/install-dmgcanvas.sh"
chmod +x "$DMGCANVAS_SCRIPT_PATH"
"$DMGCANVAS_SCRIPT_PATH"

echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Install Sparkle binaries"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

## Install Sparkle binaries
SPARKLE_INSTALL_SCRIPT_PATH="$CI_SCRIPTS_PATH/install-sparkle-binaries.sh"
chmod +x "$SPARKLE_INSTALL_SCRIPT_PATH"
"$SPARKLE_INSTALL_SCRIPT_PATH"

echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Install AWS & JQ from homebrew"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

## Install aws & jq
BREWS_INSTALL_SCRIPT_PATH="$CI_SCRIPTS_PATH/install-brews.sh"
chmod +x "$BREWS_INSTALL_SCRIPT_PATH"
"$BREWS_INSTALL_SCRIPT_PATH"
