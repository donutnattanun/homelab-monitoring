#!/usr/bin/env bash
set -e

DOMAIN="homelab.local"
SERVICES=("auth" "monitor")

echo "🚀 Starting Homelab Setup..."

# 1. Generate Self-signed Certificates
mkdir -p nginx/cert
for sub in "${SERVICES[@]}"; do
  if [ ! -f "nginx/cert/$sub.$DOMAIN.pem" ]; then
    echo ">> Generating Cert for $sub.$DOMAIN..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
      -keyout "nginx/cert/$sub.$DOMAIN-key.pem" \
      -out "nginx/cert/$sub.$DOMAIN.pem" \
      -subj "/C=TH/ST=Bangkok/L=Bangkok/O=Homelab/CN=$sub.$DOMAIN"
  fi
done

# 2. Setup Default Environment
if [ ! -f ".env" ]; then
  echo ">> Creating .env from template..."
  cp .env.example .env
fi

# 3. Setup Secrets
echo ">> Generating Authelia Secrets..."
mkdir -p data/authelia/secrets

# เจนรหัสสุ่ม 64 ตัวอักษรสำหรับ Secrets
for secret in JWT_SECRET SESSION_SECRET STORAGE_ENCRYPTION_KEY; do
  if [ ! -f "data/authelia/secrets/$secret" ]; then
    openssl rand -base64 48 >"data/authelia/secrets/$secret"
    echo "✅ Generated $secret"
  fi
done

# gen STORAGE_PASSWORD
if [ ! -f "data/authelia/secrets/STORAGE_PASSWORD" ]; then
  openssl rand -hex 16 >"data/authelia/secrets/STORAGE_PASSWORD"
  DB_PASSWORD=$(cat data/authelia/secrets/STORAGE_PASSWORD)
  echo ">> Injecting DB Password into configuration.yml..."
  sed -i "s/password: \"StrongPassword123\"/password: \"$DB_PASSWORD\"/g" data/authelia/config/configuration.yml
  echo "✅ Generated STORAGE_PASSWORD"
fi
#gen login password
RAW_ADMIN_PASS="admin123"
mkdir -p data/authelia/config
if [ ! -f "data/authelia/config/users.yml" ]; then
  RAW_HASH=$(docker run --rm authelia/authelia:latest authelia crypto hash generate argon2 --password "$RAW_ADMIN_PASS") || {
    echo "❌ Docker failed"
    exit 1
  }
  ADMIN_HASH=$(echo "$RAW_HASH" | grep -o '\$argon2id\$[^ ]*' || true)
  if [ -z "$ADMIN_HASH" ]; then
    echo "❌ Error: Could not extract Argon2id hash from Authelia output."
    echo "Debug: Output was: $RAW_HASH"
    exit 1
  fi
  echo ">> Creating default users.yml..."
  cat <<EOF >data/authelia/config/users.yml
users:
  admin:
    displayname: "Default Admin"
    password: "$ADMIN_HASH"
    email: "admin@homelab.local"
    groups:
      - admins
EOF
  echo "✅ Generated users.yml with default user 'admin' (pass: password)"
fi

echo "------------------------------------------------"
echo "✅ Setup Complete!"
echo "📍 Please add the following to your /etc/hosts:"
echo "127.0.0.1  auth.$DOMAIN monitor.$DOMAIN"
echo "------------------------------------------------"
echo "Run 'make up' to start the system."
