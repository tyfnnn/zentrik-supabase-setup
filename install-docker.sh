#!/usr/bin/env bash

# ========================================
# DOCKER INSTALLATION SCRIPT
# Für Ubuntu/Debian Systeme
# ========================================

set -e

# Farben
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[WARN] $1${NC}"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
    exit 1
}

# Root-Check
if [ "$EUID" -eq 0 ]; then
   error "Dieses Script sollte NICHT als root ausgeführt werden!"
fi

# OS Detection
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
else
    error "Kann Betriebssystem nicht erkennen"
fi

log "🐳 Docker Installation für $OS $VERSION"

# Überprüfe ob Docker bereits installiert ist
if command -v docker >/dev/null 2>&1; then
    DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | cut -d',' -f1)
    warn "Docker ist bereits installiert (Version: $DOCKER_VERSION)"
    read -p "Trotzdem neu installieren? (y/N): " REINSTALL
    if [ "$REINSTALL" != "y" ] && [ "$REINSTALL" != "Y" ]; then
        log "Installation übersprungen"
        exit 0
    fi
fi

log "📦 Aktualisiere Paketlisten..."
sudo apt-get update

log "📦 Installiere Abhängigkeiten..."
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    apt-transport-https \
    software-properties-common

# Docker GPG Key hinzufügen
log "🔑 Füge Docker GPG-Schlüssel hinzu..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/$OS/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Docker Repository hinzufügen
log "📋 Füge Docker Repository hinzu..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$OS \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Paketlisten aktualisieren
log "🔄 Aktualisiere Paketlisten..."
sudo apt-get update

# Docker installieren
log "🐳 Installiere Docker..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Docker Compose (standalone) installieren
log "🔧 Installiere Docker Compose..."
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# User zu docker Gruppe hinzufügen
log "👤 Füge Benutzer zur Docker-Gruppe hinzu..."
sudo usermod -aG docker $USER

# Docker Service starten und aktivieren
log "🚀 Starte Docker Service..."
sudo systemctl start docker
sudo systemctl enable docker

# Teste Docker Installation
log "🧪 Teste Docker Installation..."
sudo docker run --rm hello-world

# Teste Docker Compose
log "🧪 Teste Docker Compose..."
docker-compose --version

echo
echo "========================================"
echo "✅ DOCKER INSTALLATION ERFOLGREICH!"
echo "========================================"
echo
echo "📋 Installierte Versionen:"
echo "   Docker: $(docker --version)"
echo "   Docker Compose: $(docker-compose --version)"
echo
echo "⚠️  WICHTIG:"
echo "   Bitte loggen Sie sich ab und wieder ein,"
echo "   damit die Gruppenmitgliedschaft wirksam wird."
echo
echo "   Oder verwenden Sie: newgrp docker"
echo
echo "🚀 Danach können Sie das Zentrik Setup ausführen:"
echo "   bash setup.sh"
echo

log "🏁 Docker Installation abgeschlossen!"
