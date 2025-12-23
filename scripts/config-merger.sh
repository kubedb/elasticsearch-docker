#!/bin/bash

set -eo pipefail
set -x

install_yq() {
  if command -v yq >/dev/null 2>&1; then
    echo "yq already available"
    return 0
  fi

  echo "Installing yq..."

  # Detect architecture
  ARCH=$(uname -m)
  case "$ARCH" in
    x86_64|amd64) YQ_BINARY="yq_linux_amd64" ;;
    aarch64|arm64) YQ_BINARY="yq_linux_arm64" ;;
    armv7l) YQ_BINARY="yq_linux_arm" ;;
    *) echo "ERROR: Unsupported architecture: $ARCH" >&2; exit 1 ;;
  esac

  # Download yq binary to /tmp (writable by non-root user)
  YQ_URL="https://github.com/mikefarah/yq/releases/latest/download/${YQ_BINARY}"

  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$YQ_URL" -o /tmp/yq
  elif command -v wget >/dev/null 2>&1; then
    wget -qO /tmp/yq "$YQ_URL"
  else
    echo "ERROR: curl or wget required to install yq" >&2
    exit 1
  fi

  chmod +x /tmp/yq
  export PATH="/tmp:$PATH"

  if ! /tmp/yq --version >/dev/null 2>&1; then
    echo "ERROR: yq installation failed" >&2
    exit 1
  fi

  echo "yq installed successfully"
}


# Call the installer (add this after the chown block, around line 35)
install_yq


ELASTICSEARCH_UID=${ELASTICSEARCH_UID:-1000}
# directory for operator generated files
TEMP_CONFIG_DIR=/elasticsearch/temp-config
# directory for user provided custom files
CUSTOM_CONFIG_DIR=/usr/share/elasticsearch/config/custom-config
# directory for elasticsearch config files
CONFIG_DIR=/usr/share/elasticsearch/config
# secure settings directory
SECURE_SETTINGS_DIR=/elasticsearch/secure-settings
#Apply Config
APPLY_CONFIG="applyconfig"

# List of comma seperated roles
# NODE_ROLES="master, ingest, data" or NODE_ROLES="master"
NODE_ROLES=${NODE_ROLES:-""}
# Make a list of roles
IFS=',' read -ra ROLES <<<"$NODE_ROLES"

if [[ "$(id -u)" == "0" ]]; then
  echo "changing the ownership of data folder: /usr/share/elasticsearch/data"
  chown -R "$ELASTICSEARCH_UID":"$ELASTICSEARCH_UID" /usr/share/elasticsearch/data
fi

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
            yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' -i "$FILE_DIR" $CUSTOM_CONFIG_DIR/"$FILE_NAME"
        fi

        #merge applyconfig files with the updated one
        APPLY_CONFIG_FILE_NAME="$APPLY_CONFIG-$FILE_NAME"
        if [ -f $TEMP_CONFIG_DIR/"$APPLY_CONFIG_FILE_NAME" ]; then
            yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' -i "$FILE_DIR" $TEMP_CONFIG_DIR/"$APPLY_CONFIG_FILE_NAME"
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
                yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' -i "$FILE_DIR" $CUSTOM_CONFIG_DIR/"$ROLE_FILE_NAME"
            fi
            #merge applyconfig files with the updated one
            APPLY_CONFIG_ROLE_FILE_NAME="$APPLY_CONFIG-$ROLE_FILE_NAME"
            if [ -f $TEMP_CONFIG_DIR/"$APPLY_CONFIG_ROLE_FILE_NAME" ]; then
                yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' -i "$FILE_DIR" $TEMP_CONFIG_DIR/"$APPLY_CONFIG_ROLE_FILE_NAME"
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
done

##----------------------------------------Elasticsearch Keystore------------------------------------

# For secure settings
# On "$ /usr/share/elasticsearch/bin/elasticsearch-keystore create" command,
# elasticsearch.keystore file is created at config directory.
# Create the keystore, later add the secure settings to keystore.
# Since the keystore is generated even before starting the main container, no need to
# restart/reload the secure settings.
if [ -d $SECURE_SETTINGS_DIR ]; then
    echo "Updating secure settings..."
    if [ -f $CONFIG_DIR/elasticsearch.keystore ]; then
        echo "Keystore already initialized!"
    else
        echo "Creating elasticsearch keystore"
        if [ -f $SECURE_SETTINGS_DIR/password ]; then
            /usr/share/elasticsearch/bin/elasticsearch-keystore create --password < <(
                cat $SECURE_SETTINGS_DIR/password && echo
                cat $SECURE_SETTINGS_DIR/password
            )
        else
            /usr/share/elasticsearch/bin/elasticsearch-keystore create
        fi

        for FILE_DIR in "$SECURE_SETTINGS_DIR"/*; do
            # extract file name
            FILE_NAME=$(basename -- "$FILE_DIR")
            # Don't add keystore password to the keystore itself
            if [ "$FILE_NAME" != "password" ]; then
                if [ -f $SECURE_SETTINGS_DIR/password ]; then
                    /usr/share/elasticsearch/bin/elasticsearch-keystore add-file --force "$FILE_NAME" "$FILE_DIR" < <(cat $SECURE_SETTINGS_DIR/password)
                else
                    /usr/share/elasticsearch/bin/elasticsearch-keystore add-file --force "$FILE_NAME" "$FILE_DIR"
                fi
            fi
        done
    fi
fi
