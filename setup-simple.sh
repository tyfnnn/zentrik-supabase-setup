#!/usr/bin/env bash

# ========================================
# ZENTRIK NGO-BUCHHALTUNG - SIMPLE SETUP
# Vereinfachte Version ohne Root-Check
# ========================================

set -e

# Farben
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

log "🚀 Zentrik NGO-Buchhaltung Setup (Simple Version)"

# User-Info anzeigen
log "👤 Aktueller Benutzer: $(whoami) (UID: $(id -u))"

# Warn vor Root
if [ "$(id -u)" -eq 0 ]; then
    warn "Sie führen das Script als root aus. Das wird NICHT empfohlen!"
    read -p "Trotzdem fortfahren? (y/N): " CONTINUE_AS_ROOT
    if [ "$CONTINUE_AS_ROOT" != "y" ] && [ "$CONTINUE_AS_ROOT" != "Y" ]; then
        error "Setup abgebrochen. Führen Sie das Script als normaler Benutzer aus."
    fi
fi

# ========================================
# VORAUSSETZUNGEN PRÜFEN
# ========================================

log "📋 Überprüfe Systemvoraussetzungen..."

# Docker prüfen
if ! command -v docker >/dev/null 2>&1; then
    error "Docker ist nicht installiert. Führen Sie zuerst aus: bash install-docker.sh"
fi

# Docker Compose prüfen
COMPOSE_CMD=""
if command -v docker-compose >/dev/null 2>&1; then
    COMPOSE_CMD="docker-compose"
elif docker compose version >/dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
else
    error "Docker Compose ist nicht verfügbar. Installieren Sie Docker Compose."
fi

log "✅ Docker gefunden: $(docker --version)"
log "✅ Docker Compose gefunden: $COMPOSE_CMD"

# Docker-Berechtigung testen
if ! docker ps >/dev/null 2>&1; then
    error "Keine Docker-Berechtigung. Führen Sie aus: sudo usermod -aG docker \$USER && newgrp docker"
fi

# ========================================
# BENUTZER-EINGABEN
# ========================================

log "📝 Sammle Konfigurationsdaten..."

# Domain
read -p "🌐 Ihre Domain (z.B. zentrik.example.com): " DOMAIN
if [ -z "$DOMAIN" ]; then
    DOMAIN="localhost"
    warn "Keine Domain angegeben, verwende: $DOMAIN"
fi

# Admin-Credentials
read -p "👤 Admin-Benutzername [zentrik_admin]: " ADMIN_USERNAME
ADMIN_USERNAME=${ADMIN_USERNAME:-zentrik_admin}

# Passwort generieren
ADMIN_PASSWORD=$(openssl rand -base64 20 | tr -d "=+/")
DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/")
JWT_SECRET=$(openssl rand -base64 64 | tr -d "=+/")
SECRET_KEY_BASE=$(openssl rand -base64 64 | tr -d "=+/")
OPERATOR_TOKEN=$(openssl rand -base64 32 | tr -d "=+/")
LOGFLARE_API_KEY=$(openssl rand -base64 32 | tr -d "=+/")

log "🔑 Passwörter automatisch generiert"

# Email-Konfiguration (optional)
read -p "📧 SMTP Host [skip]: " SMTP_HOST
if [ -z "$SMTP_HOST" ]; then
    SMTP_HOST="smtp.example.com"
    SMTP_PORT="587"
    SMTP_USER="your_email@example.com"
    SMTP_PASS="your_password"
    SMTP_SENDER_NAME="Zentrik NGO"
    SMTP_ADMIN_EMAIL="admin@$DOMAIN"
    SMTP_SECURE="true"
    log "📧 SMTP-Konfiguration übersprungen"
else
    read -p "📧 SMTP Port [587]: " SMTP_PORT
    SMTP_PORT=${SMTP_PORT:-587}
    read -p "📧 SMTP User: " SMTP_USER
    read -s -p "📧 SMTP Password: " SMTP_PASS
    echo
    read -p "📧 Sender Name [Zentrik NGO]: " SMTP_SENDER_NAME
    SMTP_SENDER_NAME=${SMTP_SENDER_NAME:-"Zentrik NGO"}
    read -p "📧 Admin Email: " SMTP_ADMIN_EMAIL
    SMTP_SECURE="true"
fi

# ========================================
# PROJEKT SETUP
# ========================================

PROJECT_DIR="zentrik-supabase"

log "📁 Erstelle Projektverzeichnis: $PROJECT_DIR"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# ========================================
# DOCKER COMPOSE DATEI ERSTELLEN
# ========================================

log "📝 Erstelle Docker Compose Konfiguration..."

cat > docker-compose.yml << 'COMPOSE_EOF'
version: '3.8'

services:
  # PostgreSQL Database
  db:
    container_name: supabase-db
    image: supabase/postgres:15.1.1.78
    healthcheck:
      test: pg_isready -U postgres -h localhost
      interval: 5s
      timeout: 5s
      retries: 10
    restart: unless-stopped
    ports:
      - "5432:5432"
    environment:
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: postgres
    volumes:
      - db_data:/var/lib/postgresql/data
    networks:
      - zentrik-network

  # Kong API Gateway
  kong:
    container_name: supabase-kong
    image: kong:2.8.1
    restart: unless-stopped
    ports:
      - "8000:8000"
    environment:
      KONG_DATABASE: "off"
      KONG_DECLARATIVE_CONFIG: /kong/kong.yml
      KONG_DNS_ORDER: LAST,A,CNAME
      KONG_PLUGINS: request-transformer,cors,key-auth,acl
    volumes:
      - ./kong.yml:/kong/kong.yml:ro
    networks:
      - zentrik-network
    depends_on:
      - db

  # Supabase Studio
  studio:
    container_name: supabase-studio
    image: supabase/studio:20241106-8a20e3b
    restart: unless-stopped
    ports:
      - "3001:3000"
    environment:
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      DEFAULT_ORGANIZATION_NAME: "Zentrik"
      DEFAULT_PROJECT_NAME: "zentrik-ngo"
      SUPABASE_URL: http://kong:8000
      SUPABASE_PUBLIC_URL: https://${DOMAIN}
      SUPABASE_ANON_KEY: ${ANON_KEY}
      SUPABASE_SERVICE_KEY: ${SERVICE_ROLE_KEY}
    networks:
      - zentrik-network
    depends_on:
      - kong

networks:
  zentrik-network:
    driver: bridge

volumes:
  db_data:
    driver: local
COMPOSE_EOF

# ========================================
# UMGEBUNGSVARIABLEN ERSTELLEN
# ========================================

log "⚙️ Erstelle Umgebungsvariablen..."

# JWT Keys generieren (vereinfacht)
ANON_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
SERVICE_ROLE_KEY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImV4cCI6MTk4MzgxMjk5Nn0.EGIM96RAZx35lJzdJsyH-qQwv8Hdp7fsn3W0YpN81IU"

cat > .env << ENV_EOF
# Zentrik NGO Supabase Configuration
DOMAIN=$DOMAIN
POSTGRES_PASSWORD=$DB_PASSWORD
DASHBOARD_USERNAME=$ADMIN_USERNAME
DASHBOARD_PASSWORD=$ADMIN_PASSWORD

# JWT Configuration
JWT_SECRET=$JWT_SECRET
ANON_KEY=$ANON_KEY
SERVICE_ROLE_KEY=$SERVICE_ROLE_KEY

# Email Configuration
SMTP_HOST=$SMTP_HOST
SMTP_PORT=$SMTP_PORT
SMTP_USER=$SMTP_USER
SMTP_PASS=$SMTP_PASS
SMTP_SENDER_NAME=$SMTP_SENDER_NAME
SMTP_ADMIN_EMAIL=$SMTP_ADMIN_EMAIL
SMTP_SECURE=$SMTP_SECURE
ENV_EOF

# ========================================
# KONG KONFIGURATION
# ========================================

log "🦍 Erstelle Kong Konfiguration..."

cat > kong.yml << 'KONG_EOF'
_format_version: "1.1"

consumers:
  - username: anon
    keyauth_credentials:
      - key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0

services:
  - name: postgres
    url: http://db:5432
    routes:
      - name: postgres
        paths:
          - /db

plugins:
  - name: cors
    config:
      origins:
        - "*"
      methods:
        - GET
        - POST
        - PUT
        - DELETE
        - OPTIONS
      headers:
        - Accept
        - Authorization
        - Content-Type
        - X-Requested-With
      credentials: true
KONG_EOF

# ========================================
# DATENBANK SCHEMA
# ========================================

log "🗄️ Erstelle Datenbankschema..."

mkdir -p sql

cat > sql/schema.sql << 'SCHEMA_EOF'
-- Zentrik NGO Database Schema (Basic)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Currencies
CREATE TABLE IF NOT EXISTS currencies (
    code VARCHAR(3) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    symbol VARCHAR(10) NOT NULL,
    is_active BOOLEAN DEFAULT true
);

-- Insert default currencies
INSERT INTO currencies (code, name, symbol) VALUES
('EUR', 'Euro', '€'),
('USD', 'US Dollar', '$'),
('GBP', 'British Pound', '£'),
('TRY', 'Turkish Lira', '₺')
ON CONFLICT (code) DO NOTHING;

-- Basic accounts table
CREATE TABLE IF NOT EXISTS accounts (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    currency_code VARCHAR(3) REFERENCES currencies(code),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Basic projects table  
CREATE TABLE IF NOT EXISTS projects (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    budget_amount DECIMAL(15,2) DEFAULT 0,
    currency_code VARCHAR(3) REFERENCES currencies(code),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE currencies ENABLE ROW LEVEL SECURITY;
ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;

-- Basic policies (allow all for now)
CREATE POLICY "Allow all" ON currencies FOR ALL USING (true);
CREATE POLICY "Allow all" ON accounts FOR ALL USING (true);
CREATE POLICY "Allow all" ON projects FOR ALL USING (true);
SCHEMA_EOF

# ========================================
# SERVICES STARTEN
# ========================================

log "🚀 Starte Zentrik Supabase Services..."

# Docker Compose verwenden
$COMPOSE_CMD pull
$COMPOSE_CMD up -d

# Warten auf Services
log "⏳ Warte auf Services (30 Sekunden)..."
sleep 30

# Schema laden
log "📊 Lade Datenbankschema..."
docker exec -i supabase-db psql -U postgres -d postgres < sql/schema.sql

# ========================================
# STATUS PRÜFEN
# ========================================

log "🏥 Überprüfe Service-Status..."

# Kong testen
if curl -f http://localhost:8000 >/dev/null 2>&1; then
    log "✅ Kong API Gateway läuft"
else
    warn "⚠️ Kong API Gateway nicht erreichbar"
fi

# Studio testen
if curl -f http://localhost:3001 >/dev/null 2>&1; then
    log "✅ Supabase Studio läuft"
else
    warn "⚠️ Supabase Studio nicht erreichbar"
fi

# PostgreSQL testen
if docker exec supabase-db pg_isready -h localhost >/dev/null 2>&1; then
    log "✅ PostgreSQL läuft"
else
    warn "⚠️ PostgreSQL nicht bereit"
fi

# ========================================
# WARTUNGSSCRIPTS
# ========================================

log "🛠️ Erstelle Wartungsscripts..."

# Status Script
cat > status.sh << 'STATUS_EOF'
#!/bin/bash
echo "📊 Zentrik Supabase Status"
echo "=========================="
docker-compose ps
echo ""
echo "🌐 URLs:"
echo "Kong API:        http://localhost:8000"
echo "Supabase Studio: http://localhost:3001"
echo "PostgreSQL:      localhost:5432"
STATUS_EOF

# Stop Script
cat > stop.sh << 'STOP_EOF'
#!/bin/bash
echo "🛑 Stoppe Zentrik Supabase..."
docker-compose down
STATUS_EOF

# Start Script
cat > start.sh << 'START_EOF'
#!/bin/bash
echo "🚀 Starte Zentrik Supabase..."
docker-compose up -d
STATUS_EOF

chmod +x status.sh stop.sh start.sh

# ========================================
# ABSCHLUSS
# ========================================

echo
echo "========================================"
echo "🎉 ZENTRIK SETUP ERFOLGREICH!"
echo "========================================"
echo
echo "📍 Projektverzeichnis: $(pwd)"
echo
echo "🌐 Zugangspunkte:"
echo "   Kong API Gateway:  http://localhost:8000"
echo "   Supabase Studio:   http://localhost:3001"
echo "   PostgreSQL:        localhost:5432"
echo
echo "🔑 Zugangsdaten:"
echo "   Admin User:        $ADMIN_USERNAME"
echo "   Admin Password:    $ADMIN_PASSWORD"
echo "   DB Password:       $DB_PASSWORD"
echo
echo "🔑 API Keys (für Android App):"
echo "   Supabase URL:      http://localhost:8000"
echo "   Anon Key:          $ANON_KEY"
echo "   Service Key:       $SERVICE_ROLE_KEY"
echo
echo "🛠️ Nützliche Befehle:"
echo "   ./status.sh        - Status anzeigen"
echo "   ./stop.sh          - Services stoppen"
echo "   ./start.sh         - Services starten"
echo
echo "📝 Alle Konfigurationsdaten sind in der .env Datei gespeichert"
echo
echo "✅ Setup abgeschlossen!"

log "🏁 Zentrik NGO-Buchhaltung ist bereit!"
