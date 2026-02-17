issuer: "${DEX_ISSUER_URL}" # Public URL

web:
  http: "0.0.0.0:${DEX_WEB_UI_PORT}" # Listen on all interfaces

storage:
  type: postgres
  config:
    host: "${DEX_POSTGRES_ADDRESS}" 
    port: 5432
    database: "${DEX_POSTGRES_DB}" 
    user: "${DEX_POSTGRES_USERNAME}" 
    password: "${DEX_POSTGRES_PASSWORD}" 
    ssl:
      mode: disable

oauth2:
  grantTypes:
    - "authorization_code"
    - "refresh_token"
  responseTypes: [ "code" ]
  alwaysShowLoginScreen: true
  skipApprovalScreen: true

staticClients:
  - id: civil-prototype-frontend
    name: "Civil Prototype Frontend"
    # Placeholder: Dex will read the secret from the environment variable
    secret: "${DEX_PROTOTYPE_FRONTEND_CLIENT_SECRET}"
    redirectURIs:
      - "${DEX_PROTOTYPE_FRONTEND_REDIRECT_URI}"

connectors: ${DEX_CONNECTOR_CONFIG}

expiry:
  deviceRequests: "5m"
  signingKeys: "6h"
  idTokens: "24h"
  refreshTokens:
    reuseInterval: "3s"
    validIfNotUsedFor: "2160h" # 90 days
    absoluteLifetime: "3960h" # 165 days

signer:
  type: local
  config:
    keysRotationPeriod: "6h"

# Enable the dedicated telemetry port
telemetry:
  http: "0.0.0.0:${DEX_TELEMETRY_PORT}"

logger:
  level: "info"
  format: "json" # Output structured logs

grpc:
  # Cannot be the same address as an HTTP(S) service.
  addr: "0.0.0.0:${DEX_GRPC_PORT}"

  # Server certs. If TLS credentials aren't provided dex will run in plaintext (HTTP) mode.
  tlsCert: "${DEX_GRPC_CERT_FILE}"
  tlsKey: "${DEX_GRPC_KEY_FILE}"

  # Client auth CA.
  tlsClientCA: "${DEX_GRPC_CA_FILE}"

  # enable reflection
  reflection: true
