#!/bin/bash

set -euxo pipefail

OUTPUT_FILE="${SRCROOT}/Flutter/Environment.xcconfig"
cp /dev/null "$OUTPUT_FILE"

function decode_base64() {
  echo "${*}" | base64 --decode
}

has_app_name=false

if [[ -n "${DART_DEFINES:-}" ]]; then
  IFS=',' read -r -a define_items <<<"$DART_DEFINES"

  for line in "${define_items[@]}"; do
    decoded_line=$(decode_base64 "$line")
    lowercase_line=$(echo "$decoded_line" | tr '[:upper:]' '[:lower:]')
    if [[ $lowercase_line != flutter* ]]; then
      echo "$decoded_line" >> "$OUTPUT_FILE"
    fi
    if [[ $lowercase_line == app_name=* ]]; then
      has_app_name=true
    fi
  done
fi

if [[ $has_app_name == false ]]; then
  echo "APP_NAME=FlutterKaigi 2026" >> "$OUTPUT_FILE"
fi
