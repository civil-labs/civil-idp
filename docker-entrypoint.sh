#!/bin/sh
set -e

# ---------------------------------------------------------------------
# 0. Set Defaults (The "Dynamic Location" Logic)
# ---------------------------------------------------------------------
# If the user didn't tell us where to look, default to /etc/dex/
export DEX_GRPC_CERT_FILE=${DEX_GRPC_CERT_FILE:-"/etc/dex/grpc.crt"}
export DEX_GRPC_KEY_FILE=${DEX_GRPC_KEY_FILE:-"/etc/dex/grpc.key"}
export DEX_GRPC_CA_FILE=${DEX_GRPC_CA_FILE:-"/etc/dex/client.crt"}

echo "--- Civil Identity Provider Bootstrapper ---"
echo "Cert Location: $DEX_GRPC_CERT_FILE"

# ---------------------------------------------------------------------
# 1. Certificate Injection (Write to the dynamic path)
# ---------------------------------------------------------------------
inject_cert() {
    local env_var_name="$1"
    local target_file="$2"
    local val=$(eval echo \$$env_var_name) # Run the echo command on the env var and save it to the val
    
    if [ -n "$val" ]; then # Ensure there was a value in the env var
        echo "Injecting from Env Var to $target_file..."
        # Ensure the directory exists (in case the user picked a weird path)
        mkdir -p $(dirname "$target_file") # Ensure target directory exists, create it if not
        echo "$val" | base64 -d > "$target_file" # Decode from base64 and write to target_file
        chmod 600 "$target_file" # Lock down perms to just the owner user
    fi
}

# Passing the base64 val like this ensures we keep logs sanitary
# and don't crash if we don't set the base64
inject_cert "DEX_GRPC_CERT_BASE64"      "$DEX_GRPC_CERT_FILE"
inject_cert "DEX_GRPC_KEY_BASE64"       "$DEX_GRPC_KEY_FILE"
inject_cert "DEX_GRPC_CLIENT_CA_BASE64" "$DEX_GRPC_CA_FILE"

# ---------------------------------------------------------------------
# 2. Self-Signed Fallback
# ---------------------------------------------------------------------
# Check if the file exists at the DYNAMIC location
if [ ! -f "$DEX_GRPC_KEY_FILE" ] || [ ! -f "$DEX_GRPC_CERT_FILE" ]; then
    echo "No certs found at $DEX_GRPC_CERT_FILE. Generating defaults..."
    
    mkdir -p $(dirname "$DEX_GRPC_CERT_FILE")
    
    openssl req -x509 -newkey rsa:4096 -nodes \
        -keyout "$DEX_GRPC_KEY_FILE" \
        -out "$DEX_GRPC_CERT_FILE" \
        -days 3650 \
        -subj "/CN=dex" \
        -addext "subjectAltName=DNS:dex,DNS:localhost,IP:127.0.0.1"

    chmod 600 "$DEX_GRPC_KEY_FILE"
fi
# # Special Handling for Client CA (mTLS)
# # If the config requires a Client CA but we didn't inject one, 
# # we copy the Server Cert to the Client CA path to prevent Dex from crashing.
# # (This effectively allows the server to 'trust itself', which is safe-ish for a fallback)
# if [ ! -f "$CLIENT_CA" ]; then
#     echo "No Client CA found. Using Server Cert as CA fallback to satisfy config..."
#     cp "$SERVER_CERT" "$CLIENT_CA"
# fi

# ---------------------------------------------------------------------
# 3. Configuration Generation
# ---------------------------------------------------------------------

# 1. Decode the Base64 config into a temporary variable
#    If the variable is empty, default to "[]" to prevent YAML errors.
if [ -n "$DEX_CONNECTORS_DEF_BASE64" ]; then
    export DEX_CONNECTORS_LIST=$(echo "$DEX_CONNECTORS_DEF_BASE64" | base64 -d | envsubst) # Need to run envsubst here too to ensure the env vars within the connectors list get replaced properly
else
    export DEX_CONNECTORS_LIST="[]"
fi

# 2. Run envsubst
DEX_CONFIG_DIR="/etc/dex"

echo "Generating config.yaml from template..."

if [ ! -f "$DEX_CONFIG_DIR/config.yaml.tpl" ]; then
    echo "Error: Template not found at $DEX_CONFIG_DIR/config.yaml.tpl"
    exit 1
fi

# Read from the baked-in template -> Write to the location 'dex serve' expects
envsubst < "$DEX_CONFIG_DIR/config.yaml.tpl" > "$DEX_CONFIG_DIR/config.yaml"

# ---------------------------------------------------------------------
# 4. Hand off to Dex
# ---------------------------------------------------------------------
echo "Starting Dex..."
exec "$@"