# Use the official Dex image (Alpine based)
FROM ghcr.io/dexidp/dex:latest

# Copy your config file into the container
# We put it in a standard path
COPY config.yaml /etc/dex/config.yaml

# The official image's ENTRYPOINT is already set to run dex
# We just need to override the CMD to point to our new file
CMD ["dex", "serve", "/etc/dex/config.yaml"]