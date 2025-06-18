# 🏦 Zentrik NGO-Buchhaltung - Supabase Self-Hosting

Vollständige Anleitung zur Einrichtung von Zentrik NGO-Buchhaltung mit Supabase auf Hetzner Cloud.

## 📋 Überblick

Zentrik ist eine spezialisierte Buchhaltungssoftware für gemeinnützige Organisationen mit internationalen Projekten. Diese Anleitung zeigt, wie Sie Supabase als Backend auf Ihrem eigenen Server hosten.

### 🎯 Was wird installiert?

- **Supabase Backend** (PostgreSQL, Auth, Storage, Realtime)
- **NGO-spezifisches Datenbankschema** mit SKR-Kontenrahmen
- **Multi-Währungs-Support** für internationale Projekte
- **Projektbasierte Buchhaltung** mit Budget-Monitoring
- **Belegverwaltung** mit OCR-Unterstützung
- **Dashboard** mit kritischen Projekt-Warnungen

## 🚀 Schnellstart

### 1. Voraussetzungen

**Server-Anforderungen:**
- Ubuntu 20.04+ oder Debian 11+
- Mindestens 4GB RAM (8GB empfohlen)
- 20GB freier Speicherplatz
- Docker & Docker Compose installiert

**Externe Services:**
- Hetzner Cloud Server
- Domain (für SSL)
- Nginx Proxy Manager
- Cloudflare Tunnel

### 2. Installation

```bash
# Repository klonen
git clone https://github.com/tyfnnn/zentrik-supabase-setup.git
cd zentrik-supabase

# Setup-Script ausführen
chmod +x setup.sh
./setup.sh
```

Das Script führt Sie durch die gesamte Installation und fragt alle notwendigen Konfigurationsdaten ab.

### 3. Nach der Installation

1. **Nginx Proxy Manager konfigurieren:**
   ```
   Domain: zentrik.ihre-domain.com
   Target: http://127.0.0.1:8000
   SSL: Aktiviert
   WebSocket: Aktiviert
   ```

2. **Cloudflare Tunnel einrichten:**
   ```
   zentrik.ihre-domain.com → Ihr Server Port 443
   ```

3. **Android App konfigurieren:**
   ```kotlin
   // app/src/main/res/values/strings.xml
   <string name="supabase_url">https://zentrik.ihre-domain.com</string>
   <string name="supabase_anon_key">ihr_anon_key</string>
   ```

## 🗄️ Datenbankschema

### NGO-spezifische Bereiche

Das Schema unterstützt die vier NGO-Bereiche nach deutschem Steuerrecht:

- **IDEELL**: Steuerfrei (Hauptzweck)
- **ASSET_MANAGEMENT**: Vermögensverwaltung (beschränkt steuerpflichtig)
- **PURPOSE_OPERATION**: Zweckbetrieb (bedingt steuerfrei)
- **ECONOMIC_OPERATION**: Wirtschaftsbetrieb (steuerpflichtig)

### Haupttabellen

```sql
-- Währungen für internationale Arbeit
currencies (code, name, symbol, decimal_places)

-- SKR-Kontenrahmen für NGOs
accounts (account_number, account_name, account_type, ngo_area)

-- Projektbasierte Buchhaltung
projects (project_code, name, budget_amount, spent_amount, ngo_area)

-- Belege mit Workflow
receipts (type, status, amounts, project_id, approval_workflow)
```

### Beispiel-Daten

Das System wird mit Beispieldaten initialisiert:

- **Standard-Währungen**: EUR, USD, TRY, GBP
- **NGO-Kontenplan**: 60+ vordefinierte Konten
- **Demo-Projekte**: Wasserprojekt, Bildung, Gesundheit
- **Beispiel-Belege**: Verschiedene Geschäftsfälle

## ⚙️ Konfiguration

### Umgebungsvariablen

Die wichtigsten Einstellungen in der `.env` Datei:

```bash
# Domain
DOMAIN=zentrik.ihre-domain.com

# Sicherheit
POSTGRES_PASSWORD=ihr_db_passwort
DASHBOARD_USERNAME=admin
DASHBOARD_PASSWORD=ihr_admin_passwort

# JWT Keys (automatisch generiert)
JWT_SECRET=ihr_jwt_secret
ANON_KEY=ihr_anon_key
SERVICE_ROLE_KEY=ihr_service_key

# Email (für Passwort-Reset)
SMTP_HOST=smtp.gmail.com
SMTP_USER=ihr_email@gmail.com
SMTP_PASS=ihr_app_passwort
```

### Multi-Währungs-Konfiguration

```sql
-- Neue Währung hinzufügen
INSERT INTO currencies (code, name, symbol, decimal_places) 
VALUES ('CHF', 'Swiss Franc', 'CHF', 2);

-- Projekt mit Fremdwährung
INSERT INTO projects (name, budget_amount, budget_currency_code) 
VALUES ('Schweiz Projekt', 50000, 'CHF');
```

## 🏗️ Architektur

### Services

```yaml
# Kong API Gateway (Port 8000)
kong: API-Routing und Authentifizierung

# Supabase Studio (Port 3001)  
studio: Web-Interface für Verwaltung

# PostgreSQL (Port 5432)
db: Hauptdatenbank mit NGO-Schema

# Auth Service
auth: Benutzer-Authentifizierung

# Storage Service  
storage: Datei-Upload (Belegbilder)

# Realtime Service
realtime: Live-Updates für Dashboard
```

### Datenfluss

```
Android App → Kong Gateway → Supabase Services → PostgreSQL
             ↓
         Nginx Proxy Manager → Cloudflare Tunnel → Internet
```

## 🔒 Sicherheit

### Authentifizierung

- **Row Level Security (RLS)** auf allen Tabellen
- **JWT-basierte Authentifizierung**
- **Rollenbasierte Zugriffskontrolle**

### Policies

```sql
-- Benutzer sehen nur ihre eigenen Belege
CREATE POLICY "Users can view their own receipts" 
ON receipts FOR SELECT 
USING (auth.uid() = created_by);

-- Admins können alles verwalten
CREATE POLICY "Admins can manage all receipts" 
ON receipts FOR ALL 
USING (auth.role() = 'service_role');
```

### Netzwerk-Sicherheit

- **SSL/TLS** über Cloudflare
- **Rate Limiting** in Kong
- **Firewall-Regeln** für Server
- **Private Docker Networks**

## 📊 Dashboard Features

### Kritische Projekte

Das Dashboard identifiziert automatisch Projekte mit:

- **Budget-Überschreitung**
- **Nahende Deadlines**
- **Lange Inaktivität**
- **Fehlende Berichte**

### Financial Overview

- **Budget-Auslastung** nach NGO-Bereichen
- **Steuerliche Trennung** der Bereiche
- **Multi-Währungs-Übersicht**
- **Trend-Analysen**

### Workflow-Management

- **Beleg-Genehmigung** mit Status-Tracking
- **Automatische Validierung**
- **Audit-Trail** für alle Änderungen

## 🛠️ Wartung

### Backup

```bash
# Automatisches Backup
./backup.sh

# Backup-Inhalt:
# - PostgreSQL Dump
# - Storage-Dateien  
# - Konfigurationsdateien
```

### Updates

```bash
# System aktualisieren
./update.sh

# Status überprüfen
./status.sh
```

### Monitoring

```bash
# Service-Status
docker-compose ps

# Logs anzeigen
docker-compose logs -f kong
docker-compose logs -f db

# Resource-Verbrauch
docker stats
```

## 🔧 Fehlerbehebung

### Häufige Probleme

**Kong Gateway nicht erreichbar:**
```bash
# Service-Status prüfen
docker-compose ps kong

# Logs anzeigen
docker-compose logs kong

# Neustart
docker-compose restart kong
```

**PostgreSQL Connection Error:**
```bash
# Database Health Check
docker-compose exec db pg_isready

# Logs prüfen
docker-compose logs db

# Verbindung testen
docker-compose exec db psql -U postgres
```

**SSL/TLS Probleme:**
```bash
# Nginx Proxy Manager Logs
docker logs nginx-proxy-manager

# Cloudflare Tunnel Status
cloudflared tunnel info
```

### Log-Analyse

```bash
# Alle Services
docker-compose logs

# Spezifischer Service  
docker-compose logs -f auth

# Letzte 100 Zeilen
docker-compose logs --tail=100
```

## 📱 Android App Integration

### Konfiguration

```kotlin
// build.gradle.kts (app)
implementation("io.github.jan-tennert.supabase:postgrest-kt:2.0.0")
implementation("io.github.jan-tennert.supabase:auth-kt:2.0.0")
implementation("io.github.jan-tennert.supabase:storage-kt:2.0.0")

// Supabase Client
val supabase = createSupabaseClient(
    supabaseUrl = "https://zentrik.ihre-domain.com",
    supabaseKey = "ihr_anon_key"
) {
    install(Auth)
    install(Postgrest)
    install(Storage)
}
```

### Datenbankzugriff

```kotlin
// Projekte laden
val projects = supabase.from("projects")
    .select()
    .decodeList<Project>()

// Beleg erstellen
val receipt = Receipt(
    type = ReceiptType.EXPENSE,
    description = "Projektausgabe",
    originalAmount = BigDecimal("100.00"),
    originalCurrencyCode = "EUR"
)

supabase.from("receipts")
    .insert(receipt)
```

## 🌍 Multi-Währungs-Setup

### Exchange Rate Integration

```sql
-- Exchange Rate Tabelle (optional)
CREATE TABLE exchange_rates (
    from_currency VARCHAR(3),
    to_currency VARCHAR(3), 
    rate DECIMAL(10,6),
    rate_date DATE,
    PRIMARY KEY (from_currency, to_currency, rate_date)
);
```

### API Integration

```kotlin
// Exchange Rate Service
class ExchangeRateService {
    suspend fun getRate(from: String, to: String, date: LocalDate): BigDecimal {
        // Integration mit exchangerate-api.com
        // oder interner Tabelle
    }
}
```

## 📋 Checkliste nach Installation

- [ ] **Supabase Studio** erreichbar unter https://ihre-domain.com
- [ ] **Android App** kann sich verbinden
- [ ] **Beispiel-Daten** sind sichtbar
- [ ] **Multi-Währung** funktioniert
- [ ] **Backups** werden erstellt
- [ ] **SSL-Zertifikat** ist gültig
- [ ] **Rate Limiting** ist aktiv
- [ ] **Monitoring** ist eingerichtet

## 🤝 Support

### Dokumentation

- [Supabase Docs](https://supabase.com/docs)
- [PostgreSQL Manual](https://www.postgresql.org/docs/)
- [Docker Compose Reference](https://docs.docker.com/compose/)

### Community

- [Zentrik GitHub](https://github.com/zentrik)
- [Supabase Discord](https://discord.supabase.com)
- [NGO-Software Forum](https://forum.ngo-software.org)

### Kommerzielle Unterstützung

Für professionelle Unterstützung und Anpassungen:
- Email: support@zentrik.de
- Website: https://zentrik.de/support

## 📄 Lizenz

Zentrik NGO-Buchhaltung ist Open Source Software unter der MIT Lizenz.

Supabase ist Open Source unter der Apache 2.0 Lizenz.

---

**Entwickelt mit ❤️ für NGOs weltweit**
