#!/bin/sh


strip_whitespace() {
    local input="$1"
    # Remove leading and trailing whitespace
    local stripped=$(echo "$input" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    # Remove all internal whitespace (optional)
    stripped=$(echo "$stripped" | tr -d '[:space:]')
    echo "$stripped"
}

