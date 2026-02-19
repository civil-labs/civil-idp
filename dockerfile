# Use the alpine-based Dex image (check your base tag)
FROM ghcr.io/dexidp/dex:v2.37.0-alpine

USER root

# 1. Install dependencies
# 'openssl' -> For generating certs
# 'gettext' -> Provides 'envsubst' command
RUN apk add --no-cache openssl gettext

# 2. Setup Directory
WORKDIR /etc/dex

# Use the numeric UID/GID (1001 is the Dex default)
RUN mkdir -p /etc/dex && chown -R 1001:1001 /etc/dex

# 3. Copy Assets (Ensure you chown during the copy too!)
COPY --chown=1001:1001 config.yaml /etc/dex/config.yaml

USER 1001

# 5. Set Entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["dex", "serve", "/etc/dex/config.yaml"]