#!/bin/bash

# ========================================
# ZENTRIK NGO-BUCHHALTUNG - SETUP SCRIPT
# Supabase Self-Hosting auf Hetzner Cloud
# ========================================

set -e  # Exit on any error

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
if [[ $EUID -eq 0 ]]; then
   error "Dieses Script sollte NICHT als root ausgeführt werden!"
fi

log "🚀 Zentrik NGO-Buchhaltung Setup startet..."

# ========================================
# SYSTEMVORAUSSETZUNGEN PRÜFEN
# ========================================

log "📋 Überprüfe Systemvoraussetzungen..."

# Docker prüfen
if ! command -v docker &> /dev/null; then
    error "Docker ist nicht installiert. Bitte installieren Sie Docker zuerst."
fi

# Docker Compose prüfen
if ! command -v docker-compose &> /dev/null; then
    error "Docker Compose ist nicht installiert. Bitte installieren Sie Docker Compose zuerst."
fi

# Git prüfen
if ! command -v git &> /dev/null; then
    error "Git ist nicht installiert. Bitte installieren Sie Git zuerst."
fi

# Genügend RAM prüfen (mindestens 4GB empfohlen)
TOTAL_RAM=$(free -m | awk 'NR==2{printf "%.0f", $2/1024}')
if [ "$TOTAL_RAM" -lt 4 ]; then
    warn "Weniger als 4GB RAM verfügbar. Für Produktionsumgebungen werden mindestens 8GB empfohlen."
fi

# Freier Speicherplatz prüfen (mindestens 10GB)
AVAILABLE_SPACE=$(df -h . | awk 'NR==2 {print $4}' | sed 's/G//')
if [ "${AVAILABLE_SPACE%.*}" -lt 10 ]; then
    warn "Weniger als 10GB freier Speicherplatz verfügbar."
fi

log "✅ Systemvoraussetzungen erfüllt"

# ========================================
# BENUTZER-EINGABEN SAMMELN
# ========================================

log "📝 Sammle Konfigurationsdaten..."

# Domain abfragen
read -p "🌐 Ihre Domain (z.B. zentrik.example.com): " DOMAIN
if [[ -z "$DOMAIN" ]]; then
    error "Domain ist erforderlich!"
fi

# Admin-Credentials
read -p "👤 Admin-Benutzername: " ADMIN_USERNAME
if [[ -z "$ADMIN_USERNAME" ]]; then
    ADMIN_USERNAME="zentrik_admin"
fi

# Sicheres Passwort generieren oder abfragen
echo "🔐 Admin-Passwort generieren oder eingeben?"
echo "1) Automatisch generieren (empfohlen)"
echo "2) Manuell eingeben"
read -p "Auswahl (1-2): " PASSWORD_CHOICE

if [[ "$PASSWORD_CHOICE" == "1" ]]; then
    ADMIN_PASSWORD=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    log "🔑 Generiertes Admin-Passwort: $ADMIN_PASSWORD"
    log "⚠️  WICHTIG: Notieren Sie sich dieses Passwort!"
    read -p "Drücken Sie Enter zum Fortfahren..."
else
    read -s -p "🔐 Admin-Passwort eingeben: " ADMIN_PASSWORD
    echo
    if [[ ${#ADMIN_PASSWORD} -lt 12 ]]; then
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

if [[ "$EMAIL_CHOICE" == "1" ]]; then
    read -p "📧 SMTP Host (z.B. smtp.gmail.com): " SMTP_HOST
    read -p "📧 SMTP Port (z.B. 587): " SMTP_PORT
    read -p "📧 SMTP Benutzername: " SMTP_USER
    read -s -p "📧 SMTP Passwort: " SMTP_PASS
    echo
    read -p "📧 Admin Email-Adresse: " SMTP_ADMIN_EMAIL
else
    SMTP_HOST="smtp.example.com"
    SMTP_PORT="587"
    SMTP_USER="your_email@example.com"
    SMTP_PASS="your_password"
    SMTP_ADMIN_EMAIL="admin@$DOMAIN"
fi

log "✅ Konfiguration vollständig"

# ========================================
# PROJEKTVERZEICHNIS ERSTELLEN
# ========================================

PROJECT_DIR="zentrik-supabase"
log "📁 Erstelle Projektverzeichnis: $PROJECT_DIR"

if [[ -d "$PROJECT_DIR" ]]; then
    warn "Verzeichnis $PROJECT_DIR existiert bereits"
    read -p "Überschreiben? (y/N): " OVERWRITE
    if [[ "$OVERWRITE" != "y" && "$OVERWRITE" != "Y" ]]; then
        error "Setup abgebrochen"
    fi
    rm -rf "$PROJECT_DIR"
fi

mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# ========================================
# SUPABASE SETUP HERUNTERLADEN
# ========================================
