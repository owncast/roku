#!/bin/bash

if [ $# -lt 2 ]; then
    echo "Roku device password and IP address required, in that order."
    exit 1
fi

TMPDIR="${TMPDIR:-/tmp}"
ROKU_TMP_BUNDLE_FILE="$TMPDIR/rokubundle.zip"

echo "Creating $ROKU_TMP_BUNDLE_FILE"
zip -FS -9 -q -r $ROKU_TMP_BUNDLE_FILE *

echo "Deploying $ROKU_TMP_BUNDLE_FILE to $2"
curl --user rokudev:"$1" --anyauth -sS -F "mysubmit=Install" -F "archive=@$ROKU_TMP_BUNDLE_FILE" -F "passwd=" http://$2/plugin_install | grep -o '(?<=<font color="red">).*' | sed 's/<\/font>//'
