#!/bin/bash

set -eo pipefail
set -x

OPENSEARCH_DASHBOARDS_UID=${OPENSEARCH_DASHBOARDS_UID:-1000}
# directory for default config files
DEFAULT_CONFIG_DIR=/opensearch-dashboards/default-config
# directory for operator generated files
TEMP_CONFIG_DIR=/opensearch-dashboards/temp-config
# directory for user provided custom files
CUSTOM_CONFIG_DIR=/opensearch-dashboards/custom-config
# directory for opensearch-dashboards config files
CONFIG_DIR=/usr/share/opensearch-dashboards/config

# load default config files to config directory
cp -f -R $DEFAULT_CONFIG_DIR/* $CONFIG_DIR

# For opensearch-dashboards config directory
for FILE_DIR in "$CONFIG_DIR"/*; do
    # store original file permissions
    ORIGINAL_PERMISSION=$(stat -c '%a' "$FILE_DIR")

    # extract file name
    FILE_NAME=$(basename -- "$FILE_DIR")

    # extract file extension
    EXTENSION="${FILE_NAME##*.}"

    # For yml files, yq tool is used
    if [[ "$EXTENSION" == "yml" ]]; then
        # overwrite the default config file with operator generated one.
        # In default opensearch-dashboards.yml, fields like `elasticsearch.username`, `elasticsearch.password` etc. are set.
        # In kubeDB, we set these values via env. As fields can't be deleted using yq tools,
        # overwrite the whole file.
        if [ -f $TEMP_CONFIG_DIR/"$FILE_NAME" ]; then
            cp -f $TEMP_CONFIG_DIR/"$FILE_NAME" "$FILE_DIR"
        fi

        # merge user provided custom config with the updated one
        if [ -f $CUSTOM_CONFIG_DIR/"$FILE_NAME" ]; then
            yq merge -i --overwrite "$FILE_DIR" $CUSTOM_CONFIG_DIR/"$FILE_NAME"
        fi

    else
        # process non-yml files
        # overwrite the default config with the operator generated one
        if [ -f $TEMP_CONFIG_DIR/"$FILE_NAME" ]; then
            cp -f $TEMP_CONFIG_DIR/"$FILE_NAME" "$FILE_DIR"
        fi

        # overwrite the updated config with the user provided one
        if [ -f $CUSTOM_CONFIG_DIR/"$FILE_NAME" ]; then
            cp -f $CUSTOM_CONFIG_DIR/"$FILE_NAME" "$FILE_DIR"
        fi

    fi

    # restore original file permission
    chmod "$ORIGINAL_PERMISSION" "$FILE_DIR"
done

