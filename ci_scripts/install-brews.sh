#!/bin/bash

export HOMEBREW_NO_AUTO_UPDATE=1

brew install awscli

# Verify the aws installation
aws --version

brew install jq

# Verify the jq installation
jq --version

