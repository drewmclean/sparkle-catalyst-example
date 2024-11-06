#!/bin/bash

set -e

# https://developer.apple.com/documentation/xcode/environment-variable-reference
if [[ -n $CI_XCODE_CLOUD ]];
then
    echo "This build script is being run from from XCode Cloud."
    echo "CI_DEVELOPER_ID_SIGNED_APP_PATH: $CI_DEVELOPER_ID_SIGNED_APP_PATH"
    echo "CI_ARCHIVE_PATH: $CI_ARCHIVE_PATH"
    echo "CI_WORKSPACE_PATH: $CI_WORKSPACE_PATH"
fi

if [ "$CI_XCODEBUILD_ACTION" != "archive" ]; then
  echo "Skipping post clone script for $CI_XCODEBUILD_ACTION action. This only needs to run post archive."
  exit 0
fi




echo ""
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Starting Release Direct Distribution..."
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

REPOSITORY_ROOT="$CI_WORKSPACE_PATH/repository"
CI_SCRIPTS_PATH="$REPOSITORY_ROOT/CarrotApp/ci_scripts"
source "$CI_SCRIPTS_PATH/constants.sh"

# Run the post archive process
POST_ARCHIVE_SCRIPT_PATH="$CI_SCRIPTS_PATH/distribute-app.sh"
chmod +x "$POST_ARCHIVE_SCRIPT_PATH"
"$POST_ARCHIVE_SCRIPT_PATH"
