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
  echo "✅ Generated STORAGE_PASSWORD"
fi

mkdir -p data/authelia/config
if [ ! -f "data/authelia/config/users.yml" ]; then
  echo ">> Creating default users.yml..."
  cat <<EOF >data/authelia/config/users.yml
users:
  admin:
    displayname: "Default Admin"
    # รหัสผ่านคือ "password" ( Argon2id hash )
    password: "\$argon2id\$v=19\$m=65536,t=3,p=4\$Dn6H69Yp9GqG6iLp7Zz2Yg\$Fv/KAnAbe6Dk8w7p/L2+GjH5YFzC/D7B8E5g6G6/7gE"
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
