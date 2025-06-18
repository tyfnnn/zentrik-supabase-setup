-- ========================================
-- ZENTRIK NGO-BUCHHALTUNG DATABASE SCHEMA
-- ========================================

-- Aktiviere UUID Extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Erstelle ENUM Types
CREATE TYPE ngo_area AS ENUM (
    'IDEELL',
    'ASSET_MANAGEMENT', 
    'PURPOSE_OPERATION',
    'ECONOMIC_OPERATION'
);

CREATE TYPE account_type AS ENUM (
    'ASSET',
    'LIABILITY',
    'EXPENSE', 
    'REVENUE'
);

CREATE TYPE project_status AS ENUM (
    'PLANNING',
    'APPROVED',
    'ACTIVE',
    'PAUSED',
    'COMPLETED',
    'CANCELLED'
);

CREATE TYPE receipt_type AS ENUM (
    'EXPENSE',
    'INCOME',
    'TRANSFER',
    'OPENING_BALANCE',
    'CLOSING_ENTRY'
);

CREATE TYPE receipt_status AS ENUM (
    'DRAFT',
    'PENDING_APPROVAL',
    'APPROVED',
    'REJECTED',
    'BOOKED'
);

-- ========================================
-- CURRENCIES TABLE
-- ========================================
CREATE TABLE currencies (
    code VARCHAR(3) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    symbol VARCHAR(10) NOT NULL,
    decimal_places INTEGER DEFAULT 2,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS für Currencies
ALTER TABLE currencies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Currencies are viewable by everyone" 
ON currencies FOR SELECT 
USING (true);

CREATE POLICY "Currencies are manageable by admins" 
ON currencies FOR ALL 
USING (auth.role() = 'service_role');

-- ========================================
-- ACCOUNTS TABLE (SKR für NGOs)
-- ========================================
CREATE TABLE accounts (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    account_number VARCHAR(10) NOT NULL UNIQUE,
    account_name VARCHAR(200) NOT NULL,
    account_type account_type NOT NULL,
    ngo_area ngo_area NOT NULL,
    currency_code VARCHAR(3) REFERENCES currencies(code) ON DELETE RESTRICT,
    is_active BOOLEAN DEFAULT true,
    description TEXT,
    parent_account_id UUID REFERENCES accounts(id),
    tax_relevant BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indizes für bessere Performance
CREATE INDEX idx_accounts_account_number ON accounts(account_number);
CREATE INDEX idx_accounts_type ON accounts(account_type);
CREATE INDEX idx_accounts_ngo_area ON accounts(ngo_area);
CREATE INDEX idx_accounts_currency ON accounts(currency_code);

-- RLS für Accounts
ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Accounts are viewable by authenticated users" 
ON accounts FOR SELECT 
USING (auth.role() = 'authenticated');

CREATE POLICY "Accounts are manageable by admins" 
ON accounts FOR ALL 
USING (auth.role() = 'service_role');

-- ========================================
-- PROJECTS TABLE
-- ========================================
CREATE TABLE projects (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    project_code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    status project_status DEFAULT 'PLANNING',
    
    -- Zeitraum
    start_date DATE NOT NULL,
    end_date DATE,
    
    -- Budget
    budget_amount DECIMAL(15,2) NOT NULL CHECK (budget_amount >= 0),
    budget_currency_code VARCHAR(3) REFERENCES currencies(code) ON DELETE RESTRICT,
    spent_amount DECIMAL(15,2) DEFAULT 0 CHECK (spent_amount >= 0),
    
    -- Lokalisierung
    country VARCHAR(100),
    region VARCHAR(100),
    coordinates VARCHAR(50), -- Format: "lat,lng"
    
    -- NGO-spezifisch
    ngo_area ngo_area DEFAULT 'IDEELL',
    donor_information TEXT,
    reporting_required BOOLEAN DEFAULT false,
    next_report_due DATE,
    
    -- Metadaten
    is_active BOOLEAN DEFAULT true,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indizes
CREATE INDEX idx_projects_code ON projects(project_code);
CREATE INDEX idx_projects_status ON projects(status);
CREATE INDEX idx_projects_dates ON projects(start_date, end_date);
CREATE INDEX idx_projects_ngo_area ON projects(ngo_area);
CREATE INDEX idx_projects_currency ON projects(budget_currency_code);

-- RLS für Projects
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Projects are viewable by authenticated users" 
ON projects FOR SELECT 
USING (auth.role() = 'authenticated');

CREATE POLICY "Projects are manageable by authenticated users" 
ON projects FOR ALL 
USING (auth.role() = 'authenticated');

-- ========================================
-- RECEIPTS TABLE (Belege)
-- ========================================
CREATE TABLE receipts (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    
    -- Grunddaten
    receipt_number VARCHAR(50),
    type receipt_type NOT NULL,
    status receipt_status DEFAULT 'DRAFT',
    
    -- Datum
    receipt_date DATE NOT NULL,
    entry_date DATE DEFAULT CURRENT_DATE,
    
    -- Buchungslogik (Doppik)
    debit_account_id UUID REFERENCES accounts(id) ON DELETE RESTRICT,
    credit_account_id UUID REFERENCES accounts(id) ON DELETE RESTRICT,
    
    -- Beträge und Währung
    original_amount DECIMAL(15,2) NOT NULL CHECK (original_amount > 0),
    original_currency_code VARCHAR(3) REFERENCES currencies(code) ON DELETE RESTRICT,
    exchange_rate DECIMAL(10,6),
    base_amount DECIMAL(15,2) NOT NULL CHECK (base_amount > 0),
    base_currency_code VARCHAR(3) REFERENCES currencies(code) ON DELETE RESTRICT,
    
    -- Projektbezug
    project_id UUID REFERENCES projects(id) ON DELETE CASCADE,
    
    -- Beschreibung & Details
    description TEXT NOT NULL,
    vendor VARCHAR(200),
    reference VARCHAR(100),
    notes TEXT,
    
    -- Steuerliche Informationen
    tax_amount DECIMAL(15,2),
    tax_rate DECIMAL(5,2),
    is_deductible BOOLEAN DEFAULT false,
    
    -- Dateien & OCR
    image_paths TEXT[], -- Array von Dateipfaden
    ocr_text TEXT,
    ocr_confidence REAL CHECK (ocr_confidence >= 0 AND ocr_confidence <= 1),
    
    -- Genehmigung & Workflow
    approved_by UUID REFERENCES auth.users(id),
    approved_at TIMESTAMPTZ,
    
    -- Metadaten
    created_by UUID REFERENCES auth.users(id) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indizes
CREATE INDEX idx_receipts_date ON receipts(receipt_date);
CREATE INDEX idx_receipts_status ON receipts(status);
CREATE INDEX idx_receipts_type ON receipts(type);
CREATE INDEX idx_receipts_project ON receipts(project_id);
CREATE INDEX idx_receipts_accounts ON receipts(debit_account_id, credit_account_id);
CREATE INDEX idx_receipts_currency ON receipts(original_currency_code, base_currency_code);
CREATE INDEX idx_receipts_created_by ON receipts(created_by);

-- RLS für Receipts
ALTER TABLE receipts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own receipts" 
ON receipts FOR SELECT 
USING (auth.uid() = created_by OR auth.role() = 'service_role');

CREATE POLICY "Users can create their own receipts" 
ON receipts FOR INSERT 
WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Users can update their own draft/rejected receipts" 
ON receipts FOR UPDATE 
USING (auth.uid() = created_by AND status IN ('DRAFT', 'REJECTED'));

CREATE POLICY "Admins can manage all receipts" 
ON receipts FOR ALL 
USING (auth.role() = 'service_role');

-- ========================================
-- FUNCTIONS & TRIGGERS
-- ========================================

-- Funktion zum automatischen Update von updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger für alle Tabellen
CREATE TRIGGER update_currencies_updated_at BEFORE UPDATE ON currencies
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_accounts_updated_at BEFORE UPDATE ON accounts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_receipts_updated_at BEFORE UPDATE ON receipts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ========================================
-- VIEWS FÜR DASHBOARDS
-- ========================================

-- View für Projektstatistiken
CREATE VIEW project_statistics AS
SELECT 
    p.id,
    p.project_code,
    p.name,
    p.budget_amount,
    p.spent_amount,
    p.budget_amount - p.spent_amount AS remaining_budget,
    CASE 
        WHEN p.budget_amount > 0 THEN (p.spent_amount / p.budget_amount * 100)
        ELSE 0 
    END AS budget_utilization,
    p.spent_amount > p.budget_amount AS is_over_budget,
    CASE 
        WHEN p.end_date IS NOT NULL THEN p.end_date - CURRENT_DATE
        ELSE NULL 
    END AS days_until_deadline,
    COUNT(r.id) AS receipts_count,
    COUNT(CASE WHEN r.status = 'PENDING_APPROVAL' THEN 1 END) AS pending_approvals_count
FROM projects p
LEFT JOIN receipts r ON p.id = r.project_id AND r.status != 'REJECTED'
WHERE p.is_active = true
GROUP BY p.id, p.project_code, p.name, p.budget_amount, p.spent_amount, p.end_date;

-- View für NGO-Bereich-Statistiken
CREATE VIEW ngo_area_statistics AS
SELECT 
    ngo_area,
    COUNT(*) AS project_count,
    SUM(budget_amount) AS total_budget,
    SUM(spent_amount) AS total_spent,
    AVG(CASE WHEN budget_amount > 0 THEN spent_amount / budget_amount * 100 ELSE 0 END) AS avg_utilization
FROM projects 
WHERE is_active = true
GROUP BY ngo_area;

-- View für kritische Projekte
CREATE VIEW critical_projects AS
SELECT 
    p.*,
    ps.budget_utilization,
    ps.is_over_budget,
    ps.days_until_deadline,
    ps.receipts_count,
    CASE 
        WHEN ps.is_over_budget THEN 100
        WHEN ps.budget_utilization > 90 THEN 50
        ELSE 0
    END +
    CASE 
        WHEN ps.days_until_deadline < 0 THEN 80
        WHEN ps.days_until_deadline <= 7 THEN 60
        WHEN ps.days_until_deadline <= 30 THEN 30
        ELSE 0
    END +
    CASE 
        WHEN p.status = 'ACTIVE' AND ps.receipts_count < 3 THEN 20
        ELSE 0
    END AS criticality_score
FROM projects p
JOIN project_statistics ps ON p.id = ps.id
WHERE p.is_active = true
AND (ps.is_over_budget OR ps.days_until_deadline <= 30 OR (p.status = 'ACTIVE' AND ps.receipts_count < 3))
ORDER BY criticality_score DESC;

-- ========================================
-- FUNCTIONS FÜR BUSINESS LOGIC
-- ========================================

-- Funktion zum automatischen Update des Projektbudgets
CREATE OR REPLACE FUNCTION update_project_spent_amount()
RETURNS TRIGGER AS $
BEGIN
    -- Bei INSERT oder UPDATE eines gebuchten Belegs
    IF (TG_OP = 'INSERT' OR TG_OP = 'UPDATE') AND NEW.status = 'BOOKED' AND NEW.project_id IS NOT NULL THEN
        UPDATE projects 
        SET spent_amount = spent_amount + NEW.base_amount,
            updated_at = NOW()
        WHERE id = NEW.project_id;
    END IF;
    
    -- Bei DELETE eines gebuchten Belegs
    IF TG_OP = 'DELETE' AND OLD.status = 'BOOKED' AND OLD.project_id IS NOT NULL THEN
        UPDATE projects 
        SET spent_amount = spent_amount - OLD.base_amount,
            updated_at = NOW()
        WHERE id = OLD.project_id;
    END IF;
    
    -- Bei UPDATE von BOOKED auf anderen Status
    IF TG_OP = 'UPDATE' AND OLD.status = 'BOOKED' AND NEW.status != 'BOOKED' AND OLD.project_id IS NOT NULL THEN
        UPDATE projects 
        SET spent_amount = spent_amount - OLD.base_amount,
            updated_at = NOW()
        WHERE id = OLD.project_id;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$ LANGUAGE plpgsql;

-- Trigger für automatisches Budget-Update
CREATE TRIGGER receipt_project_budget_update
    AFTER INSERT OR UPDATE OR DELETE ON receipts
    FOR EACH ROW
    EXECUTE FUNCTION update_project_spent_amount();

-- Funktion zur Validierung von Belegen
CREATE OR REPLACE FUNCTION validate_receipt()
RETURNS TRIGGER AS $
BEGIN
    -- Prüfe, ob Soll- und Haben-Konto unterschiedlich sind
    IF NEW.debit_account_id = NEW.credit_account_id THEN
        RAISE EXCEPTION 'Debit and credit accounts must be different';
    END IF;
    
    -- Prüfe, ob beide Konten zur gleichen Währung gehören (vereinfacht)
    -- In einer echten Implementierung könnte man hier Multi-Währungs-Logik implementieren
    
    -- Prüfe Betragsplausibilität
    IF NEW.original_amount <= 0 OR NEW.base_amount <= 0 THEN
        RAISE EXCEPTION 'Amounts must be greater than zero';
    END IF;
    
    -- Prüfe Datum
    IF NEW.receipt_date > CURRENT_DATE THEN
        RAISE EXCEPTION 'Receipt date cannot be in the future';
    END IF;
    
    RETURN NEW;
END;
$ LANGUAGE plpgsql;

-- Trigger für Beleg-Validierung
CREATE TRIGGER validate_receipt_trigger
    BEFORE INSERT OR UPDATE ON receipts
    FOR EACH ROW
    EXECUTE FUNCTION validate_receipt();

-- ========================================
-- AUDIT LOG TABELLE
-- ========================================
CREATE TABLE audit_log (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    record_id UUID NOT NULL,
    action VARCHAR(10) NOT NULL, -- INSERT, UPDATE, DELETE
    old_values JSONB,
    new_values JSONB,
    changed_by UUID REFERENCES auth.users(id),
    changed_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_audit_log_table_record ON audit_log(table_name, record_id);
CREATE INDEX idx_audit_log_user ON audit_log(changed_by);
CREATE INDEX idx_audit_log_timestamp ON audit_log(changed_at);

-- Audit-Funktion
CREATE OR REPLACE FUNCTION audit_trigger_function()
RETURNS TRIGGER AS $
BEGIN
    IF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (table_name, record_id, action, old_values, changed_by)
        VALUES (TG_TABLE_NAME, OLD.id, 'DELETE', to_jsonb(OLD), auth.uid());
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (table_name, record_id, action, old_values, new_values, changed_by)
        VALUES (TG_TABLE_NAME, NEW.id, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW), auth.uid());
        RETURN NEW;
    ELSIF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (table_name, record_id, action, new_values, changed_by)
        VALUES (TG_TABLE_NAME, NEW.id, 'INSERT', to_jsonb(NEW), auth.uid());
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$ LANGUAGE plpgsql;

-- Audit-Trigger für alle wichtigen Tabellen
CREATE TRIGGER audit_projects_trigger
    AFTER INSERT OR UPDATE OR DELETE ON projects
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER audit_receipts_trigger
    AFTER INSERT OR UPDATE OR DELETE ON receipts
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

CREATE TRIGGER audit_accounts_trigger
    AFTER INSERT OR UPDATE OR DELETE ON accounts
    FOR EACH ROW EXECUTE FUNCTION audit_trigger_function();

-- ========================================
-- STORAGE BUCKETS FÜR DATEIEN
-- ========================================

-- Bucket für Belegbilder
INSERT INTO storage.buckets (id, name, public) 
VALUES ('receipt-images', 'receipt-images', false);

-- Bucket für Projektdokumente
INSERT INTO storage.buckets (id, name, public) 
VALUES ('project-documents', 'project-documents', false);

-- Storage Policies
CREATE POLICY "Authenticated users can upload receipt images" 
ON storage.objects FOR INSERT 
WITH CHECK (bucket_id = 'receipt-images' AND auth.role() = 'authenticated');

CREATE POLICY "Users can view their own receipt images" 
ON storage.objects FOR SELECT 
USING (bucket_id = 'receipt-images' AND auth.role() = 'authenticated');

CREATE POLICY "Users can delete their own receipt images" 
ON storage.objects FOR DELETE 
USING (bucket_id = 'receipt-images' AND auth.role() = 'authenticated');

-- ========================================
-- KOMMENTARE FÜR DOKUMENTATION
-- ========================================

COMMENT ON TABLE currencies IS 'Verwaltung der unterstützten Währungen für internationale NGO-Projekte';
COMMENT ON TABLE accounts IS 'SKR-Kontenrahmen speziell für gemeinnützige Organisationen mit NGO-Bereich-Trennung';
COMMENT ON TABLE projects IS 'Projektbasierte Buchhaltung mit Multi-Währungs-Support und Deadline-Management';
COMMENT ON TABLE receipts IS 'Belege mit vollständiger Doppik, OCR-Unterstützung und Genehmigungsworkflow';
COMMENT ON TABLE audit_log IS 'Audit-Trail für alle Änderungen an kritischen Geschäftsdaten';

COMMENT ON COLUMN projects.ngo_area IS 'Steuerlicher Bereich: IDEELL (steuerfrei), ASSET_MANAGEMENT (beschränkt), PURPOSE_OPERATION (bedingt steuerfrei), ECONOMIC_OPERATION (steuerpflichtig)';
COMMENT ON COLUMN receipts.status IS 'Workflow: DRAFT -> PENDING_APPROVAL -> APPROVED -> BOOKED (oder REJECTED)';
COMMENT ON COLUMN receipts.exchange_rate IS 'Wechselkurs zum Belegdatum für Multi-Währungs-Umrechnung';
