#!/bin/bash

set -eo pipefail
set -x

ELASTICSEARCH_UID=${ELASTICSEARCH_UID:-1000}
# directory for default config files
DEFAULT_CONFIG_DIR=/elasticsearch/default-config
# directory for operator generated files
TEMP_CONFIG_DIR=/elasticsearch/temp-config
# directory for user provided custom files
CUSTOM_CONFIG_DIR=/elasticsearch/custom-config
# directory for elasticsearch config files
CONFIG_DIR=/usr/share/elasticsearch/config
# directory for default security config files
DEFAULT_SECURITY_CONFIG_DIR=/elasticsearch/default-securityconfig
# directory for security config files
SECURITY_CONFIG_DIR=/usr/share/elasticsearch/plugins/search-guard-7/sgconfig

# List of comma seperated roles
# NODE_ROLES="master, ingest, data" or NODE_ROLES="master"
NODE_ROLES=${NODE_ROLES:-""}
# Make a list of roles
IFS=',' read -ra ROLES <<<"$NODE_ROLES"

echo "changing the ownership of data folder: /usr/share/elasticsearch/data"
chown -R "$ELASTICSEARCH_UID":"$ELASTICSEARCH_UID" /usr/share/elasticsearch/data

# load default config files to config directory
cp -f -R $DEFAULT_CONFIG_DIR/* $CONFIG_DIR

# For Elasticsearch config directory
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
        # In default elasticsearch.yml, fields like `cluster.name`, `host.network` are set.
        # In kubeDB, we set these values via env. As fields can't be deleted using yq tools,
        # overwrite the whole file.
        if [ -f $TEMP_CONFIG_DIR/"$FILE_NAME" ]; then
            cp -f $TEMP_CONFIG_DIR/"$FILE_NAME" "$FILE_DIR"
        fi

        # merge user provided custom config with the updated one
        if [ -f $CUSTOM_CONFIG_DIR/"$FILE_NAME" ]; then
            yq merge -i --overwrite "$FILE_DIR" $CUSTOM_CONFIG_DIR/"$FILE_NAME"
        fi

        for RoleName in "${ROLES[@]}"; do
            # remove leading and trailing spaces
            RoleName=$(echo $RoleName)
            # Node specific config file are provided with node role as file name prefix.
            # For Example:
            #   - "ingest-elasticsearch.yml" file will be applied to only ingest nodes
            ROLE_FILE_NAME="$RoleName-$FILE_NAME"

            # overwrite the default config file with operator generated one
            if [ -f $TEMP_CONFIG_DIR/"$ROLE_FILE_NAME" ]; then
                cp -f $TEMP_CONFIG_DIR/"$ROLE_FILE_NAME" "$FILE_DIR"
            fi

            # merge user provided custom config with the updated one
            if [ -f $CUSTOM_CONFIG_DIR/"$ROLE_FILE_NAME" ]; then
                yq merge -i --overwrite "$FILE_DIR" $CUSTOM_CONFIG_DIR/"$ROLE_FILE_NAME"
            fi
        done
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

        for RoleName in "${ROLES[@]}"; do
            # remove leading and trailing spaces
            RoleName=$(echo $RoleName)
            # Node specific config file are provided with node role as file name prefix.
            # For Example:
            #   - "ingest-{file-name}" file will be applied to only ingest nodes
            ROLE_FILE_NAME="$RoleName-$FILE_NAME"
            # overwrite the default config with the operator generated one
            if [ -f $TEMP_CONFIG_DIR/"$ROLE_FILE_NAME" ]; then
                cp -f $TEMP_CONFIG_DIR/"$ROLE_FILE_NAME" "$FILE_DIR"
            fi

            # overwrite the updated config with the user provided one
            if [ -f $CUSTOM_CONFIG_DIR/"$ROLE_FILE_NAME" ]; then
                cp -f $CUSTOM_CONFIG_DIR/"$ROLE_FILE_NAME" "$FILE_DIR"
            fi
        done
    fi

    # restore original file permission
    chmod "$ORIGINAL_PERMISSION" "$FILE_DIR"
done

##-------------------------------SearchGuard----------------------------------

# load default securityconfig files to securityconfig directory
# if the security is disabled, security config directory will exist.
if [ -d $SECURITY_CONFIG_DIR ]; then
    cp -f -R $DEFAULT_SECURITY_CONFIG_DIR/* $SECURITY_CONFIG_DIR
fi

# for searchGuard securitconfig files
# if security is disabled, searchGuard security config directory will not exist.
if [ -d $SECURITY_CONFIG_DIR ]; then

    # For Elasticsearch security config directory
    for FILE_DIR in "$SECURITY_CONFIG_DIR"/*; do
        # store original file permissions
        ORIGINAL_PERMISSION=$(stat -c '%a' "$FILE_DIR")

        # extract file name
        FILE_NAME=$(basename -- "$FILE_DIR")

        # extract file extension
        EXTENSION="${FILE_NAME##*.}"

        # For yml files, yq tool is used
        if [[ "$EXTENSION" == "yml" ]]; then
            # merge operator generated config with the default one
            if [ -f $TEMP_CONFIG_DIR/"$FILE_NAME" ]; then
                yq merge -i --overwrite "$FILE_DIR" $TEMP_CONFIG_DIR/"$FILE_NAME"
            fi

            # merge user provided custom config with the updated one
            if [ -f $CUSTOM_CONFIG_DIR/"$FILE_NAME" ]; then
                yq merge -i --overwrite "$FILE_DIR" $CUSTOM_CONFIG_DIR/"$FILE_NAME"
            fi

            for RoleName in "${ROLES[@]}"; do
                # remove leading and trailing spaces
                RoleName=$(echo $RoleName)
                # Node specific config file are provided with node role as file name prefix.
                # For Example:
                #   - "ingest-elasticsearch.yml" file will be applied to only ingest nodes
                ROLE_FILE_NAME="$RoleName-$FILE_NAME"

                # merge operator generated config with the default one
                if [ -f $TEMP_CONFIG_DIR/"$ROLE_FILE_NAME" ]; then
                    yq merge -i --overwrite "$FILE_DIR" $TEMP_CONFIG_DIR/"$ROLE_FILE_NAME"
                fi

                # merge user provided custom config with the updated one
                if [ -f $CUSTOM_CONFIG_DIR/"$ROLE_FILE_NAME" ]; then
                    yq merge -i --overwrite "$FILE_DIR" $CUSTOM_CONFIG_DIR/"$ROLE_FILE_NAME"
                fi
            done
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

            for RoleName in "${ROLES[@]}"; do
                # remove leading and trailing spaces
                RoleName=$(echo $RoleName)
                # Node specific config file are provided with node role as file name prefix.
                # For Example:
                #   - "ingest-{file-name}" file will be applied to only ingest nodes
                ROLE_FILE_NAME="$RoleName-$FILE_NAME"
                # overwrite the default config with the operator generated one
                if [ -f $TEMP_CONFIG_DIR/"$ROLE_FILE_NAME" ]; then
                    cp -f $TEMP_CONFIG_DIR/"$ROLE_FILE_NAME" "$FILE_DIR"
                fi

                # overwrite the updated config with the user provided one
                if [ -f $CUSTOM_CONFIG_DIR/"$ROLE_FILE_NAME" ]; then
                    cp -f $CUSTOM_CONFIG_DIR/"$ROLE_FILE_NAME" "$FILE_DIR"
                fi
            done
        fi

        # restore original file permission
        chmod "$ORIGINAL_PERMISSION" "$FILE_DIR"
    done
fi
