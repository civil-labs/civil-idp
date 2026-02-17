# Use the alpine-based Dex image (check your base tag)
FROM ghcr.io/dexidp/dex:v2.37.0-alpine

USER root

# 1. Install dependencies
# 'openssl' -> For generating certs
# 'gettext' -> Provides 'envsubst' command
RUN apk add --no-cache openssl gettext

# 2. Setup Directory
WORKDIR /etc/dex
RUN mkdir -p /etc/dex && chown -R dex:dex /etc/dex

# 3. Copy Assets
COPY config.yaml.tpl /etc/dex/config.yaml.tpl
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

# 4. Make script executable
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

USER dex

# 5. Set Entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["dex", "serve", "/etc/dex/config.yaml"]