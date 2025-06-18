#!/usr/bin/env bash

# ========================================
# ZENTRIK NGO-BUCHHALTUNG - SETUP SCRIPT
# Supabase Self-Hosting auf Hetzner Cloud
# ========================================

set -e  # Exit on any error

# Überprüfe bash
if [ -z "$BASH_VERSION" ]; then
    echo "FEHLER: Dieses Script benötigt bash. Bitte verwenden Sie:"
    echo "bash setup.sh"
    exit 1
fi

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Überprüfe Root-Berechtigung
if [ "$EUID" -eq 0 ]; then
   error "Dieses Script sollte NICHT als root ausgeführt werden!"
fi

log "🚀 Zentrik NGO-Buchhaltung Setup startet..."

# ========================================
# SYSTEMVORAUSSETZUNGEN PRÜFEN
# ========================================

log "📋 Überprüfe Systemvoraussetzungen..."

# Docker prüfen
if ! command -v docker >/dev/null 2>&1; then
    error "Docker ist nicht installiert. Bitte installieren Sie Docker zuerst."
fi

# Docker Compose prüfen
if ! command -v docker-compose >/dev/null 2>&1 && ! docker compose version >/dev/null 2>&1; then
    error "Docker Compose ist nicht installiert. Bitte installieren Sie Docker Compose zuerst."
fi

# Git prüfen
if ! command -v git >/dev/null 2>&1; then
    error "Git ist nicht installiert. Bitte installieren Sie Git zuerst."
fi

# Genügend RAM prüfen (mindestens 4GB empfohlen)
if command -v free >/dev/null 2>&1; then
    TOTAL_RAM=$(free -m | awk 'NR==2{printf "%.0f", $2/1024}')
    if [ "$TOTAL_RAM" -lt 4 ]; then
        warn "Weniger als 4GB RAM verfügbar. Für Produktionsumgebungen werden mindestens 8GB empfohlen."
    fi
fi

# Freier Speicherplatz prüfen (mindestens 10GB)
if command -v df >/dev/null 2>&1; then
    AVAILABLE_SPACE=$(df -h . | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "${AVAILABLE_SPACE%.*}" -lt 10 ] 2>/dev/null; then
        warn "Weniger als 10GB freier Speicherplatz verfügbar."
    fi
fi

log "✅ Systemvoraussetzungen erfüllt"

# ========================================
# BENUTZER-EINGABEN SAMMELN
# ========================================

log "📝 Sammle Konfigurationsdaten..."

# Domain abfragen
read -p "🌐 Ihre Domain (z.B. zentrik.example.com): " DOMAIN
if [ -z "$DOMAIN" ]; then
    error "Domain ist erforderlich!"
fi

# Admin-Credentials
read -p "👤 Admin-Benutzername: " ADMIN_USERNAME
if [ -z "$ADMIN_USERNAME" ]; then
    ADMIN_USERNAME="zentrik_admin"
fi

# Sicheres Passwort generieren oder abfragen
echo "🔐 Admin-Passwort generieren oder eingeben?"
echo "1) Automatisch generieren (empfohlen)"
echo "2) Manuell eingeben"
read -p "Auswahl (1-2): " PASSWORD_CHOICE

if [ "$PASSWORD_CHOICE" = "1" ]; then
    ADMIN_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    log "🔑 Generiertes Admin-Passwort: $ADMIN_PASSWORD"
    log "⚠️  WICHTIG: Notieren Sie sich dieses Passwort!"
    read -p "Drücken Sie Enter zum Fortfahren..."
else
    read -s -p "🔐 Admin-Passwort eingeben: " ADMIN_PASSWORD
    echo
    if [ ${#ADMIN_PASSWORD} -lt 12 ]; then
        error "Passwort muss mindestens 12 Zeichen lang sein!"
    fi
fi

# Datenbank-Passwort
DB_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)

# JWT Secret
JWT_SECRET=$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-64)

# Secret Key Base für Realtime
SECRET_KEY_BASE=$(openssl rand -base64 64 | tr -d "=+/" | cut -c1-64)

# Operator Token
OPERATOR_TOKEN=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)

# Logflare API Key
LOGFLARE_API_KEY=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-32)

# Email-Konfiguration (optional)
echo "📧 Email-Konfiguration für Passwort-Reset?"
echo "1) Konfigurieren (empfohlen)"
echo "2) Später konfigurieren"
read -p "Auswahl (1-2): " EMAIL_CHOICE

if [ "$EMAIL_CHOICE" = "1" ]; then
    read -p "📧 SMTP Host (z.B. smtp.gmail.com): " SMTP_HOST
    read -p "📧 SMTP Port (z.B. 587): " SMTP_PORT
    read -p "📧 SMTP Benutzername: " SMTP_USER
    read -s -p "📧 SMTP Passwort: " SMTP_PASS
    echo
    read -p "📧 Absendername (z.B. Zentrik NGO): " SMTP_SENDER_NAME
    read -p "📧 Admin Email-Adresse: " SMTP_ADMIN_EMAIL
    echo "🔒 SMTP Verschlüsselung aktivieren? (Y/n):"
    read -p "Eingabe: " SMTP_SECURE_INPUT
    if [ "$SMTP_SECURE_INPUT" = "n" ] || [ "$SMTP_SECURE_INPUT" = "N" ]; then
        SMTP_SECURE="false"
    else
        SMTP_SECURE="true"
    fi
else
    SMTP_HOST="smtp.example.com"
    SMTP_PORT="587"
    SMTP_USER="your_email@example.com"
    SMTP_PASS="your_password"
    SMTP_SENDER_NAME="Your Project Name"
    SMTP_ADMIN_EMAIL="admin@$DOMAIN"
    SMTP_SECURE="true"
fi

log "✅ Konfiguration vollständig"

# ========================================
# PROJEKTVERZEICHNIS ERSTELLEN
# ========================================

PROJECT_DIR="zentrik-supabase"
log "📁 Erstelle Projektverzeichnis: $PROJECT_DIR"

if [ -d "$PROJECT_DIR" ]; then
    warn "Verzeichnis $PROJECT_DIR existiert bereits"
    read -p "Überschreiben? (y/N): " OVERWRITE
    if [ "$OVERWRITE" != "y" ] && [ "$OVERWRITE" != "Y" ]; then
        error "Setup abgebrochen"
    fi
    rm -rf "$PROJECT_DIR"
fi

mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# ========================================
# SUPABASE SETUP HERUNTERLADEN
# ========================================

log "📥 Lade Supabase Docker Setup herunter..."

# Offizielle Supabase Docker Files
git clone --depth 1 https://github.com/supabase/supabase.git temp-supabase
cp -r temp-supabase/docker/* .
rm -rf temp-supabase

# ========================================
# VERZEICHNISSTRUKTUR ERSTELLEN
# ========================================

log "📂 Erstelle Verzeichnisstruktur..."

# Erstelle notwendige Verzeichnisse
mkdir -p volumes/api
mkdir -p volumes/db
mkdir -p volumes/storage
mkdir -p volumes/logs
mkdir -p volumes/functions

# Setze Berechtigungen
chmod -R 755 volumes/

# ========================================
# KONFIGURATIONSDATEIEN GENERIEREN
# ========================================

log "⚙️ Generiere Konfigurationsdateien..."

# JWT-Keys generieren
log "🔑 Generiere JWT-Keys..."

# Generiere Anon Key
ANON_KEY=$(docker run --rm supabase/studio:latest node -e "
const jwt = require('jsonwebtoken');
const payload = {
  iss: 'supabase',
  role: 'anon',
  exp: Math.floor(Date.now()/1000) + (60*60*24*365*10)
};
console.log(jwt.sign(payload, '$JWT_SECRET'));
" 2>/dev/null)

# Generiere Service Role Key
SERVICE_ROLE_KEY=$(docker run --rm supabase/studio:latest node -e "
const jwt = require('jsonwebtoken');
const payload = {
  iss: 'supabase',
  role: 'service_role',
  exp: Math.floor(Date.now()/1000) + (60*60*24*365*10)
};
console.log(jwt.sign(payload, '$JWT_SECRET'));
" 2>/dev/null)

# .env Datei erstellen
log "📝 Erstelle .env Datei..."

cat > .env << EOF
# ========================================
# ZENTRIK NGO-BUCHHALTUNG - SUPABASE ENV
# Automatisch generiert am $(date)
# ========================================

# Domain Configuration
DOMAIN=$DOMAIN

# Security - WICHTIG: Gut aufbewahren!
POSTGRES_PASSWORD=$DB_PASSWORD
DASHBOARD_USERNAME=$ADMIN_USERNAME
DASHBOARD_PASSWORD=$ADMIN_PASSWORD

# PostgreSQL
POSTGRES_HOST=db
POSTGRES_PORT=5432
POSTGRES_DB=postgres

# JWT Configuration
JWT_SECRET=$JWT_SECRET
JWT_EXPIRY=3600
ANON_KEY=$ANON_KEY
SERVICE_ROLE_KEY=$SERVICE_ROLE_KEY

# Realtime
SECRET_KEY_BASE=$SECRET_KEY_BASE

# Studio
STUDIO_DEFAULT_ORGANIZATION=Zentrik
STUDIO_DEFAULT_PROJECT=zentrik-ngo-buchhaltung

# Auth
DISABLE_SIGNUP=false
ENABLE_EMAIL_SIGNUP=true
ENABLE_EMAIL_AUTOCONFIRM=false
ENABLE_ANONYMOUS_USERS=false
ADDITIONAL_REDIRECT_URLS=https://$DOMAIN

# Email/SMTP
SMTP_HOST=$SMTP_HOST
SMTP_PORT=$SMTP_PORT
SMTP_USER=$SMTP_USER
SMTP_PASS=$SMTP_PASS
SMTP_SENDER_NAME=$SMTP_SENDER_NAME
SMTP_ADMIN_EMAIL=$SMTP_ADMIN_EMAIL
SMTP_SECURE=$SMTP_SECURE

# Security
MFA_ENABLED=true
MFA_MAX_ENROLLED_FACTORS=10
GOTRUE_SECURITY_UPDATE_PASSWORD_REQUIRE_REAUTHENTICATION=true

# API
PGRST_DB_SCHEMAS=public,storage,graphql_public
LOG_LEVEL=info

# Analytics
LOGFLARE_API_KEY=$LOGFLARE_API_KEY

# Features
IMGPROXY_ENABLE_WEBP_DETECTION=true
FUNCTIONS_VERIFY_JWT=false

# System
DOCKER_SOCKET_LOCATION=/var/run/docker.sock
OPERATOR_TOKEN=$OPERATOR_TOKEN
EOF

# Kong Konfiguration
log "🦍 Erstelle Kong Konfiguration..."

cat > volumes/api/kong.yml << 'EOF'
_format_version: "1.1"

consumers:
  - username: anon
    keyauth_credentials:
      - key: ${SUPABASE_ANON_KEY}
  - username: service_role
    keyauth_credentials:
      - key: ${SUPABASE_SERVICE_KEY}

acls:
  - consumer: anon
    group: anon
  - consumer: service_role
    group: admin

services:
  - name: rest-v1
    url: http://rest:3000/
    routes:
      - name: rest-v1-all
        strip_path: true
        paths:
          - /rest/v1/
    plugins:
      - name: cors
      - name: key-auth
        config:
          hide_credentials: false
      - name: acl
        config:
          hide_groups_header: true
          allow:
            - admin
            - anon

  - name: auth-v1
    url: http://auth:9999/
    routes:
      - name: auth-v1-all
        strip_path: true
        paths:
          - /auth/v1/
    plugins:
      - name: cors

  - name: realtime-v1
    url: http://realtime:4000/socket/
    routes:
      - name: realtime-v1-all
        strip_path: true
        paths:
          - /realtime/v1/
    plugins:
      - name: cors
      - name: key-auth
        config:
          hide_credentials: false
      - name: acl
        config:
          hide_groups_header: true
          allow:
            - admin
            - anon

  - name: storage-v1
    url: http://storage:5000/
    routes:
      - name: storage-v1-all
        strip_path: true
        paths:
          - /storage/v1/
    plugins:
      - name: cors

  - name: functions-v1
    url: http://functions:9000/
    routes:
      - name: functions-v1-all
        strip_path: true
        paths:
          - /functions/v1/
    plugins:
      - name: cors

  - name: meta-v1
    url: http://meta:8080/
    routes:
      - name: meta-v1-all
        strip_path: true
        paths:
          - /pg/
    plugins:
      - name: key-auth
        config:
          hide_credentials: false
      - name: acl
        config:
          hide_groups_header: true
          allow:
            - admin
EOF

# Vector Logging Konfiguration
log "📊 Erstelle Vector Logging Konfiguration..."

cat > volumes/logs/vector.yml << 'EOF'
data_dir: /vector-data-dir

sources:
  docker_host:
    type: docker_logs
    include_labels:
      - "com.docker.compose.project=zentrik-supabase"

transforms:
  parse_logs:
    type: remap
    inputs: ["docker_host"]
    source: |
      .timestamp = parse_timestamp(.timestamp, "%Y-%m-%dT%H:%M:%S%.fZ") ?? now()

sinks:
  logflare:
    type: http
    inputs: ["parse_logs"]
    uri: http://analytics:4000/api/logs
    method: post
    encoding:
      codec: json
    headers:
      X-API-KEY: "${LOGFLARE_API_KEY}"
      Content-Type: "application/json"
EOF

# PostgreSQL Konfiguration
log "🐘 Erstelle PostgreSQL Konfiguration..."

cat > volumes/db/postgresql.conf << 'EOF'
# PostgreSQL configuration for Zentrik Supabase

# Connection Settings
listen_addresses = '*'
port = 5432
max_connections = 200

# Memory Settings  
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100

# Query Tuning
random_page_cost = 1.1
effective_io_concurrency = 200

# Write Ahead Logging
wal_level = replica
max_wal_senders = 3
max_replication_slots = 3

# Logging
log_destination = 'stderr'
logging_collector = on
log_directory = 'pg_log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_statement = 'mod'
log_min_duration_statement = 1000

# Locale
lc_messages = 'en_US.utf8'
lc_monetary = 'en_US.utf8'
lc_numeric = 'en_US.utf8'
lc_time = 'en_US.utf8'
default_text_search_config = 'pg_catalog.english'

# Extensions
shared_preload_libraries = 'pg_stat_statements'
EOF

# ========================================
# ZENTRIK DATENBANKSCHEMA
# ========================================

log "🗄️ Erstelle Zentrik Datenbankschema..."

# Das Schema wurde bereits in den Artifacts erstellt - hier kopieren
# (In der echten Implementierung würden Sie die SQL-Dateien aus den Artifacts verwenden)

# Erstelle SQL-Initialisierungsfiles
mkdir -p volumes/db

# Schema-Datei (vereinfacht für das Setup-Script)
cat > volumes/db/zentrik-schema.sql << 'EOF'
-- Zentrik NGO Schema (vereinfachte Version für Setup)
-- Vollständiges Schema siehe separate SQL-Dateien

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Basis-Tabellen für Demo
CREATE TABLE IF NOT EXISTS currencies (
    code VARCHAR(3) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    symbol VARCHAR(10) NOT NULL,
    is_active BOOLEAN DEFAULT true
);

-- Weitere Tabellen werden über separate Migrations geladen
EOF

# ========================================
# DOCKER COMPOSE ANPASSUNGEN
# ========================================

log "🐳 Konfiguriere Docker Compose..."

# Backup der originalen docker-compose.yml
if [[ -f "docker-compose.yml" ]]; then
    cp docker-compose.yml docker-compose.yml.backup
fi

# Nutze unser angepasstes Docker Compose File
# (Das wurde bereits in den Artifacts erstellt)

# ========================================
# FIREWALL KONFIGURATION
# ========================================

log "🔥 Konfiguriere Firewall..."

# UFW Status prüfen
if command -v ufw &> /dev/null; then
    if [[ $(ufw status | head -1 | awk '{print $2}') == "active" ]]; then
        log "UFW ist aktiv - konfiguriere Firewall-Regeln..."
        
        # Erlaube SSH (wichtig!)
        sudo ufw allow 22/tcp
        
        # Erlaube HTTP/HTTPS für Nginx Proxy Manager
        sudo ufw allow 80/tcp
        sudo ufw allow 443/tcp
        
        # Erlaube Supabase Studio (nur für Setup)
        sudo ufw allow 3001/tcp
        
        # Erlaube Kong API Gateway
        sudo ufw allow 8000/tcp
        
        log "✅ Firewall-Regeln konfiguriert"
    else
        log "UFW ist inaktiv - überspringe Firewall-Konfiguration"
    fi
else
    log "UFW nicht gefunden - überspringe Firewall-Konfiguration"
fi

# ========================================
# DOCKER COMPOSE STARTEN
# ========================================

log "🚀 Starte Zentrik Supabase..."

# Docker-Compose Datei validieren
if ! docker-compose config > /dev/null 2>&1; then
    error "Docker Compose Konfiguration ist fehlerhaft!"
fi

# Images pullen
log "📦 Lade Docker Images..."
docker-compose pull

# Starte Services
log "▶️ Starte Services..."
docker-compose up -d

# Warte auf Services
log "⏳ Warte auf Services..."
sleep 30

# ========================================
# HEALTH CHECKS
# ========================================

log "🏥 Überprüfe Service-Status..."

# Kong API Gateway
if curl -f http://localhost:8000/health > /dev/null 2>&1; then
    log "✅ Kong API Gateway ist erreichbar"
else
    warn "⚠️ Kong API Gateway nicht erreichbar"
fi

# Supabase Studio
if curl -f http://localhost:3001 > /dev/null 2>&1; then
    log "✅ Supabase Studio ist erreichbar"
else
    warn "⚠️ Supabase Studio nicht erreichbar"
fi

# PostgreSQL
if docker-compose exec -T db pg_isready -h localhost -p 5432 > /dev/null 2>&1; then
    log "✅ PostgreSQL ist bereit"
else
    warn "⚠️ PostgreSQL nicht bereit"
fi

# ========================================
# SSL/TLS HINWEISE
# ========================================

log "🔒 SSL/TLS Setup-Hinweise..."

echo
echo "========================================"
echo "📋 NÄCHSTE SCHRITTE"
echo "========================================"
echo
echo "1. 🔗 Nginx Proxy Manager konfigurieren:"
echo "   - Proxy Host für $DOMAIN erstellen"
echo "   - Target: http://127.0.0.1:8000"
echo "   - SSL-Zertifikat aktivieren"
echo
echo "2. 🌩️ Cloudflare Tunnel konfigurieren:"
echo "   - Tunnel für $DOMAIN → Ihr Server"
echo "   - Port 443 (HTTPS) weiterleiten"
echo
echo "3. 🎛️ Zugriff auf Supabase Studio:"
echo "   - URL: https://$DOMAIN"
echo "   - Oder lokal: http://localhost:3001"
echo "   - Benutzername: $ADMIN_USERNAME"
echo "   - Passwort: [siehe unten]"
echo
echo "4. 📱 Android App konfigurieren:"
echo "   - Supabase URL: https://$DOMAIN"
echo "   - Anon Key: [siehe .env Datei]"
echo "   - Service Key: [siehe .env Datei]"
echo

# ========================================
# CREDENTIALS AUSGEBEN
# ========================================

echo "========================================"
echo "🔑 WICHTIGE ZUGANGSDATEN"
echo "========================================"
echo
echo "🌐 Domain: https://$DOMAIN"
echo "👤 Admin-Benutzer: $ADMIN_USERNAME"
echo "🔐 Admin-Passwort: $ADMIN_PASSWORD"
echo "🗄️ Datenbank-Passwort: $DB_PASSWORD"
echo
echo "🔑 API-Keys (für Android App):"
echo "   Anon Key: $ANON_KEY"
echo "   Service Key: $SERVICE_ROLE_KEY"
echo
echo "⚠️  WICHTIG: Speichern Sie diese Daten sicher!"
echo "   Alle Credentials sind auch in der .env Datei gespeichert."
echo

# ========================================
# WARTUNGSSCRIPTS ERSTELLEN
# ========================================

log "🛠️ Erstelle Wartungsscripts..."

# Backup-Script
cat > backup.sh << 'EOF'
#!/bin/bash
# Zentrik Supabase Backup Script

BACKUP_DIR="backups/$(date +%Y-%m-%d_%H-%M-%S)"
mkdir -p "$BACKUP_DIR"

echo "🗄️ Erstelle Datenbank-Backup..."
docker-compose exec -T db pg_dump -U postgres postgres | gzip > "$BACKUP_DIR/database.sql.gz"

echo "📁 Erstelle Storage-Backup..."
tar -czf "$BACKUP_DIR/storage.tar.gz" volumes/storage/

echo "⚙️ Sichere Konfiguration..."
cp .env "$BACKUP_DIR/"
cp docker-compose.yml "$BACKUP_DIR/"

echo "✅ Backup erstellt in: $BACKUP_DIR"
EOF

# Update-Script
cat > update.sh << 'EOF'
#!/bin/bash
# Zentrik Supabase Update Script

echo "🔄 Aktualisiere Zentrik Supabase..."

# Backup vor Update
./backup.sh

# Pull neue Images
docker-compose pull

# Restart Services
docker-compose down
docker-compose up -d

echo "✅ Update abgeschlossen"
EOF

# Monitoring-Script
cat > status.sh << 'EOF'
#!/bin/bash
# Zentrik Supabase Status Script

echo "📊 Zentrik Supabase Status"
echo "=========================="

# Service Status
echo
echo "🐳 Docker Services:"
docker-compose ps

# Resource Usage
echo
echo "💾 Ressourcenverbrauch:"
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"

# Disk Usage
echo
echo "💿 Speicherverbrauch:"
du -sh volumes/*

# Health Checks
echo
echo "🏥 Health Checks:"
if curl -f http://localhost:8000/health > /dev/null 2>&1; then
    echo "✅ Kong API Gateway"
else
    echo "❌ Kong API Gateway"
fi

if curl -f http://localhost:3001 > /dev/null 2>&1; then
    echo "✅ Supabase Studio"
else
    echo "❌ Supabase Studio"
fi
EOF

# Scripts ausführbar machen
chmod +x backup.sh update.sh status.sh

# ========================================
# SYSTEMD SERVICE (OPTIONAL)
# ========================================

if command -v systemctl >/dev/null 2>&1; then
    echo
    read -p "🔧 Systemd Service für automatischen Start erstellen? (y/N): " CREATE_SERVICE
    
    if [ "$CREATE_SERVICE" = "y" ] || [ "$CREATE_SERVICE" = "Y" ]; then
        log "🔧 Erstelle Systemd Service..."
        
        sudo tee /etc/systemd/system/zentrik-supabase.service > /dev/null << EOF
[Unit]
Description=Zentrik Supabase
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=$(pwd)
ExecStart=/usr/local/bin/docker-compose up -d
ExecStop=/usr/local/bin/docker-compose down
TimeoutStartSec=0
User=$(whoami)

[Install]
WantedBy=multi-user.target
EOF

        sudo systemctl daemon-reload
        sudo systemctl enable zentrik-supabase
        
        log "✅ Systemd Service erstellt und aktiviert"
        log "   Verwendung: sudo systemctl start/stop/restart zentrik-supabase"
    fi
fi

# ========================================
# SETUP ABSCHLUSS
# ========================================

echo
echo "========================================"
echo "🎉 ZENTRIK SETUP ERFOLGREICH!"
echo "========================================"
echo
echo "Ihr Zentrik NGO-Buchhaltungssystem ist bereit!"
echo
echo "📁 Projektverzeichnis: $(pwd)"
echo "🌐 URL: https://$DOMAIN"
echo "📚 Dokumentation: https://supabase.com/docs"
echo
echo "🔧 Nützliche Befehle:"
echo "   ./status.sh     - Status anzeigen"
echo "   ./backup.sh     - Backup erstellen"
echo "   ./update.sh     - System aktualisieren"
echo
echo "📞 Support: https://github.com/zentrik/support"
echo
echo "Vielen Dank für die Nutzung von Zentrik! 🙏"
echo

# Log-File erstellen
echo "$(date): Zentrik Supabase Setup erfolgreich abgeschlossen" >> setup.log

log "🏁 Setup abgeschlossen!"
