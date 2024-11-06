#!/bin/bash

# Exit immediately if any command fails and fail on pipe failures
set -e
set -o pipefail

REPOSITORY_ROOT="$CI_WORKSPACE_PATH/repository"
CI_SCRIPTS_PATH="$REPOSITORY_ROOT/CarrotApp/ci_scripts"

# Load the constants (shared with post_clone)
source "$CI_SCRIPTS_PATH/constants.sh"

source "$CI_SCRIPTS_PATH/helpers.sh"
chmod +x "$CI_SCRIPTS_PATH/helpers.sh"

source "$CI_SCRIPTS_PATH/s3-tools.sh"
chmod +x "$CI_SCRIPTS_PATH/s3-tools.sh"

# ===================================================================
# INPUT PARAMETERS 
# ===================================================================
ASSETS_PATH="$CI_SCRIPTS_PATH/Assets"

S3_INFRA=""
RELEASE_NOTES_FILE_NAME=""
# Path to the DMG Canvas document file
#    If it's in your Xcode project folder:
#      DMG_TEMPLATE_PATH="$SRCROOT/DiskImage.dmgcanvas"
#    Or use a manually-specified path
#      DMG_TEMPLATE_PATH="~/Desktop/DiskImage.dmgcanvas"
DMG_TEMPLATE_PATH=""
# The file with this name, inside your DMG Canvas template, will get
# replaced with your Xcode build product (which is named $CI_PRODUCT).
# In this example, they both have the same name:
FILE_NAME_IN_DMG_TEMPLATE=""

# Internal code to pass to the functions api for setting latest build number.
SET_LATEST_BUILD_INTERNAL_CODE="AAQ3JlYXRlV2l0aFBsYXkyMDIxCg=="

if [ "$PLAY_ENV" == "staging" ]; then
    S3_INFRA="s"
    FUNCTIONS_API_GATEWAY="https://play-staging-api-gateway-baje80yl.uc.gateway.dev"
    RELEASE_NOTES_FILE_NAME="ReleaseNotes-Staging.txt"
    DMG_TEMPLATE_PATH="$ASSETS_PATH/DMG/Play2Staging_Template.dmgcanvas"
    FILE_NAME_IN_DMG_TEMPLATE="Play 2 - Staging.app"
elif [ "$PLAY_ENV" == "production" ]; then
    S3_INFRA="p"
    FUNCTIONS_API_GATEWAY="https://play-gen2-api-gateway-d7m491ww.uc.gateway.dev"
    RELEASE_NOTES_FILE_NAME="ReleaseNotes-Prod.txt"
    DMG_TEMPLATE_PATH="$ASSETS_PATH/DMG/Play2_Template.dmgcanvas"
    FILE_NAME_IN_DMG_TEMPLATE="Play 2.app"
else
    echo "Invalid PLAY_ENV value. Use 'staging' or 'production'."
    exit 1
fi


# S3
S3_BUCKET_NAME="my-bucket-name"
S3_DEFAULT_BASE_URL="https://$S3_BUCKET_NAME.s3.us-east-2.amazonaws.com"
S3_BASE_URL=$S3_DEFAULT_BASE_URL

TEAM_ID="<my-apple-team-id>"
PROJECT_NAME="$CI_PRODUCT"

# Variables set in XCodeCloud
# The issuer ID for the app store connect API key used for notarization
NOTARIZATION_ISSUER_ID="<my-issuer-id>"
# The key ID for the app store connect API key used for notarization
NOTARIZATION_KEY_ID="<my-key-id>"
# Owner name registerd to DMG Canvas license
DMG_CANVAS_LICENSED_TO="Andrew McLean"
# Owner license key to DMG Canvas license
DMG_CANVAS_LICENSE_KEY="<my-dmg-canvas-license-key"
# Path to a text file containing the Sparkle EdDSA private key.
SPARKLE_PRIVATE_KEY="<my-sparkle-key>"
# File name for release notes
SPARKLE_FULL_RELEASE_NOTES_URL="https://www.website.com/c/release-notes"
SPARKLE_SUPPORT_LINK_URL="https://www.website.com/c/help/"

# The file path to the key for the app store connect API key used for notarization
NOTARIZATION_KEY_FILE_PATH="$ASSETS_PATH/Certs/<my-key-file>.p8"

# Path to a plain text file containing a text of the release notes for the current version being released.
# This is embedded by Sparkle framework into appcast.xml and is displayed to user's when the update is available.
EMBED_RELEASE_NOTES_PATH="$REPOSITORY_ROOT/SparkleTest/ReleaseNotes/$RELEASE_NOTES_FILE_NAME"

# NOTE: this process kept breaking
# Create a unique folder for the build products.
PRODUCT_NAME_STRIPPED=$(strip_whitespace "$CI_PRODUCT")
EXPORT_PATH="$CI_WORKSPACE_PATH/tmp/$PRODUCT_NAME_STRIPPED-Export"
mkdir -p "$EXPORT_PATH"

BUILT_APP_PATH="${CI_DEVELOPER_ID_SIGNED_APP_PATH}/${FILE_NAME_IN_DMG_TEMPLATE}"
INFOPLIST_PATH="${BUILT_APP_PATH}/Contents/Info.plist"

echo "EXPORT_PATH: $EXPORT_PATH"
echo "BUILT_APP_PATH: $BUILT_APP_PATH"
echo "INFOPLIST_PATH: $INFOPLIST_PATH"
echo "FILE_NAME_IN_DMG_TEMPLATE: $FILE_NAME_IN_DMG_TEMPLATE"
echo "CI_PRODUCT: $CI_PRODUCT"

echo "Listing CI_DEVELOPMENT_SIGNED_APP_PATH..."
ls -al "$CI_DEVELOPMENT_SIGNED_APP_PATH"
echo ""
echo ""

echo "Listing BUILT_APP_PATH:"
ls -al "$BUILT_APP_PATH"
echo ""
echo ""

# if [ ! -f "$BUILT_APP_PATH" ]; then
#     echo "Error: $CI_PRODUCT.app file not found at $BUILT_APP_PATH"
#     exit 1
# fi

# if [ ! -f "$INFOPLIST_PATH" ]; then
#     echo "Error: Info.plist file not found at $INFOPLIST_PATH"
#     exit 1
# fi

# Get the version numbers which we can use in the dmg file name, and s3 path
BUNDLE_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${INFOPLIST_PATH}")
BUNDLE_SHORT_VERSION_STRING=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${INFOPLIST_PATH}")

BUILT_DMG_NAME="${PRODUCT_NAME_STRIPPED}.dmg"
SPARKLE_EMBED_RELEASE_NOTES_NAME="${PRODUCT_NAME_STRIPPED}.txt"

echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Building the disk image with dmgcanvas..."
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo ""
echo ""

BUILT_DMG_PATH="$EXPORT_PATH/$BUILT_DMG_NAME"

echo "PRODUCT_NAME_STRIPPED: $PRODUCT_NAME_STRIPPED"
echo "BUNDLE_VERSION: $BUNDLE_VERSION"
echo "BUNDLE_SHORT_VERSION_STRING: $BUNDLE_SHORT_VERSION_STRING"
echo "BUILT_DMG_NAME: $BUILT_DMG_NAME"
echo "BUILT_DMG_PATH: $BUILT_DMG_PATH"

"$DMG_CANVAS_EXECUTABLE" register "$DMG_CANVAS_LICENSED_TO" "$DMG_CANVAS_LICENSE_KEY"

# Generate a DMG
"$DMG_CANVAS_EXECUTABLE" "$DMG_TEMPLATE_PATH" "$BUILT_DMG_PATH" -setFilePath "$FILE_NAME_IN_DMG_TEMPLATE" "$BUILT_APP_PATH" -skipSigningAndNotarization

if [ $? -ne 0 ] 
then
    echo "Building the disk image with dmgcanvas failed."
    exit -4
fi

echo ""
echo "DMG Packaging completed. DMG Path: $BUILT_DMG_PATH"
echo ""

echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Notarizing DMG..."
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo ""
echo ""
echo ""

echo "Submiting for notarization..."
REQUEST_ID=$(/usr/bin/xcrun notarytool submit --issuer "$NOTARIZATION_ISSUER_ID" --key "$NOTARIZATION_KEY_FILE_PATH" --key-id "$NOTARIZATION_KEY_ID" --output-format plist --wait --no-progress "$BUILT_DMG_PATH" | plutil -extract id raw -)
echo ""

echo "Logging notarization..."
/usr/bin/xcrun notarytool log --issuer "$NOTARIZATION_ISSUER_ID" --key "$NOTARIZATION_KEY_FILE_PATH" --key-id "$NOTARIZATION_KEY_ID" "$REQUEST_ID"
echo ""

echo "Stapling notarization..."
/usr/bin/xcrun stapler staple "$BUILT_DMG_PATH"
echo ""

echo "Validating staple..."
/usr/bin/xcrun stapler validate "$BUILT_DMG_PATH"

echo ""
echo ""
echo ""

echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Signing DMG with Sparkle edRSA..."
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

SPARKLE_BIN="$SPARKLE_DIR/bin"

sparkleSignature=$(echo "$SPARKLE_PRIVATE_KEY" | $SPARKLE_BIN/sign_update "$BUILT_DMG_PATH" --ed-key-file - -p)

echo "Verifying Sparkle EdDSA signature: $sparkleSignature"

# Verify the Sparkle signature on the signed DMG. This doesn't allow pipe private key for some reason.
sparklePrivateKeyPath="$EXPORT_PATH/sparkle_private_key.txt"
echo "$SPARKLE_PRIVATE_KEY" > "$sparklePrivateKeyPath"
$SPARKLE_BIN/sign_update --verify --ed-key-file "$sparklePrivateKeyPath" "$BUILT_DMG_PATH" "$sparkleSignature" 
rm "$sparklePrivateKeyPath"

echo "Sparkle EdDSA signing completed."

echo ""
echo ""
echo ""
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Copying embedded release notes to Sparkle directory..."
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
# Copy the embedded release notes to the same directory as the DMG
# NOTE: The release notes file name must match the DMG file name.
SPARKLE_RELEASE_NOTES_PATH=$(eval echo "$EXPORT_PATH/$SPARKLE_EMBED_RELEASE_NOTES_NAME")
cp $EMBED_RELEASE_NOTES_PATH $SPARKLE_RELEASE_NOTES_PATH

echo ""
echo ""
echo ""
echo "Copying embedded release notes completed."

echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Generating Sparkle appcast..."
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

DOWNLOAD_VERSION_FOLDER_NAME="$BUNDLE_SHORT_VERSION_STRING-$BUNDLE_VERSION"
DOWNLOAD_URL_PREFIX="$S3_BASE_URL/$S3_INFRA/versions/$DOWNLOAD_VERSION_FOLDER_NAME/"

# Generate appcast item for new version
echo "$SPARKLE_PRIVATE_KEY" | $SPARKLE_BIN/generate_appcast --ed-key-file - --download-url-prefix "$DOWNLOAD_URL_PREFIX" --embed-release-notes "$EXPORT_PATH" --full-release-notes-url "$SPARKLE_FULL_RELEASE_NOTES_URL" --link "$SPARKLE_SUPPORT_LINK_URL" --critical-update-version "$BUNDLE_SHORT_VERSION_STRING"

APPCAST_XML_PATH="$EXPORT_PATH/appcast.xml"
# Check if the file exists
if [ -f $APPCAST_XML_PATH ]; then
    # If the file exists, echo its contents
    echo "Appcast contents:"
    cat "$APPCAST_XML_PATH"
else
    echo "appcast.xml failed to generate at $APPCAST_XML_PATH"
    exit -5
fi

echo ""
echo ""
echo ""
echo "Generate appcast completed."

echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "Uploading assets to S3..."
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

# Create the .aws/ config and credentials files.
create_aws_config

# Upload the Signed DMG file to s3 in a subfolder for this version
echo "Begin upload DMG to $DOWNLOAD_VERSION_FOLDER_NAME/"
upload --file-path "$BUILT_DMG_PATH" --version "$DOWNLOAD_VERSION_FOLDER_NAME" --env "$S3_INFRA"

echo "Begin upload appcast.xml to $DOWNLOAD_VERSION_FOLDER_NAME/"
# Upload the Appcast file to s3 in a subfolder for this version
upload --file-path "$APPCAST_XML_PATH" --version "$DOWNLOAD_VERSION_FOLDER_NAME" --env "$S3_INFRA"

if [ "$IS_PUBLIC_RELEASE" = "1" ]; then

    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "Releasing to Public /current s3 folder."
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

    upload --file-path "$BUILT_DMG_PATH" --version "current" --env "$S3_INFRA"
    upload --file-path "$APPCAST_XML_PATH" --version "current" --env "$S3_INFRA"

else

    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    echo "Releasing to Internal /internal s3 folder."
    echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

    upload --file-path "$BUILT_DMG_PATH" --version "internal" --env "$S3_INFRA"
    upload --file-path "$APPCAST_XML_PATH" --version "internal" --env "$S3_INFRA"

fi

# Delete the .aws/ config and credentials files.
delete_aws_config
