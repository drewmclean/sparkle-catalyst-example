#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e
set -o pipefail

# ----------------------
# NOTE: Will need to:
#
# 1.) Initially set environment variables represented in this script:
#     S3_INFRA
#     S3_ACCESS_KEY_ID
#     S3_SECRET_ACCESS_KEY
#     REGION
# 2.) make the script executable run chmod 0777 ./app-distribution-cli.sh

# ----------------------

# Variables
REGION="us-east-2"

# S3 Bucket should never change
BUCKET_PATH="play-app-distribution"

create_aws_config() {
  # Configure AWS CLI with the provided credentials
  aws_config_file="$HOME/.aws/config"
  aws_credentials_file="$HOME/.aws/credentials"
  mkdir -p "$(dirname "$aws_config_file")"
  mkdir -p "$(dirname "$aws_credentials_file")"

  echo "[default]" > "$aws_config_file"
  echo "region = $REGION" >> "$aws_config_file"

  echo "[default]" > "$aws_credentials_file"
  echo "aws_access_key_id = $AWS_ACCESS_KEY_ID" >> "$aws_credentials_file"
  echo "aws_secret_access_key = $AWS_SECRET_ACCESS_KEY" >> "$aws_credentials_file"
}

delete_aws_config() {
  # Clean up the AWS credentials file
  rm -f "$AWS_CONFIG_FILE" "$AWS_CREDENTIALS_FILE"
}

upload() {
  local file_path=""
  local version=""
  local infra=""

  while [[ $# -gt 0 ]]; do
      case "$1" in
          --file-path)
              file_path="$2"
              shift 2
              ;;
          --version)
              version="$2"
              shift 2
              ;;
          --env)
              infra="$2"
              shift 2
              ;;
          *)
              echo "Unknown argument: $1"
              return 1
              ;;
      esac
  done

  echo "File path: $file_path"
  echo "Version: $version"
  echo "Infra: $infra"

  # Dynamic generation of upload path
  upload_path=""

  # Determine the bucket name based on the S3_INFRASTRUCTURE variable
  if [ "$infra" == "s" ]; then
    upload_path="s/versions/$version"
  elif [ "$S3_INFRA" == "p" ]; then
    upload_path="p/versions/$version"
  else
    echo "Invalid S3_INFRASTRUCTURE value. Use 's' for staging or 'p' for production."
    exit 1
  fi
  bucket_path="$BUCKET_PATH/$upload_path"

  # Extract the file name and extension
  file_name=$(basename "$file_path")

  # Upload the file to S3
  aws s3 cp "$file_path" "s3://$bucket_path/$file_name"

  echo "Upload Complete!"
  echo "URL: https://$BUCKET_PATH.s3.$REGION.amazonaws.com/$upload_path/$file_name"
}

replace_current_version() {
  local version=""
  local infra=""

  while [[ $# -gt 0 ]]; do
      case "$1" in
          --with-version)
              version="$2"
              shift 2
              ;;
          --env)
              infra="$2"
              shift 2
              ;;
          *)
          echo "Unknown argument: $1"
          return 1
          ;;
      esac
  done

  echo "Version: $version"
  echo "Infra: $infra"

  # Dynamic generation of source and target paths
  source_path=""
  target_path=""
  # Determine the bucket name based on the S3_INFRASTRUCTURE variable
  if [ "$infra" == "s" ]; then
    source_path="s/versions/$version"
    target_path="s/versions/current"
  elif [ "$S3_INFRA" == "p" ]; then
    source_path="p/versions/$version"
    target_path="s/versions/current"
  else
    echo "Invalid S3_INFRASTRUCTURE value. Use 's' for staging or 'p' for production."
    exit 1
  fi

  source_bucket_path="$BUCKET_PATH/$source_path"
  target_bucket_path="$BUCKET_PATH/$target_path"

  # Copy the folder on S3
  aws s3 cp "s3://$source_bucket_path/" "s3://$target_bucket_path/" # Trailing "/" required to denote folder contents

  echo "Copy Completed:"
  echo "  From: https://$BUCKET_PATH.s3.$REGION.amazonaws.com/$source_bucket_path/"
  echo "  To: https://$BUCKET_PATH.s3.$REGION.amazonaws.com/$target_bucket_path/"

  aws cloudfront create-invalidation --distribution-id "E302TTMNA3A77J" --paths "$target_bucket_path/*"

  echo "Cloudfront cached invalidated at path: $$target_bucket_path/*"

}
