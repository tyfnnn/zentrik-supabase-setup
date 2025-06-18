-- ========================================
-- ZENTRIK NGO-BUCHHALTUNG - INITIALE DATEN
-- ========================================

-- Standard-Währungen einfügen
INSERT INTO currencies (code, name, symbol, decimal_places, is_active) VALUES
('EUR', 'Euro', '€', 2, true),
('USD', 'US Dollar', '$', 2, true),
('TRY', 'Turkish Lira', '₺', 2, true),
('GBP', 'British Pound', '£', 2, true),
('CHF', 'Swiss Franc', 'CHF', 2, true),
('PLN', 'Polish Zloty', 'zł', 2, true),
('CZK', 'Czech Koruna', 'Kč', 2, true),
('HUF', 'Hungarian Forint', 'Ft', 0, true),
('SEK', 'Swedish Krona', 'kr', 2, true),
('NOK', 'Norwegian Krone', 'kr', 2, true),
('DKK', 'Danish Krone', 'kr', 2, true)
ON CONFLICT (code) DO NOTHING;

-- ========================================
-- SKR-KONTENRAHMEN FÜR NGOs
-- ========================================

-- AKTIVA (Vermögen)
INSERT INTO accounts (id, account_number, account_name, account_type, ngo_area, currency_code, description, tax_relevant) VALUES

-- Flüssige Mittel
('11111111-1111-1111-1111-111111111001', '1000', 'Kasse EUR', 'ASSET', 'IDEELL', 'EUR', 'Bargeld in Euro', false),
('11111111-1111-1111-1111-111111111002', '1010', 'Kasse USD', 'ASSET', 'IDEELL', 'USD', 'Bargeld in US Dollar', false),
('11111111-1111-1111-1111-111111111003', '1020', 'Portokasse', 'ASSET', 'IDEELL', 'EUR', 'Kleine Barkasse für Porto und Kleinbeträge', false),

-- Bankkonten
('11111111-1111-1111-1111-111111111011', '1200', 'Bank Girokonto', 'ASSET', 'IDEELL', 'EUR', 'Hauptgirokonto bei der Hausbank', false),
('11111111-1111-1111-1111-111111111012', '1210', 'Bank Projektkonto', 'ASSET', 'IDEELL', 'EUR', 'Separates Konto für Projektgelder', false),
('11111111-1111-1111-1111-111111111013', '1220', 'Bank USD-Konto', 'ASSET', 'IDEELL', 'USD', 'Fremdwährungskonto USD', false),
('11111111-1111-1111-1111-111111111014', '1230', 'PayPal-Konto', 'ASSET', 'IDEELL', 'EUR', 'PayPal für Online-Spenden', false),

-- Forderungen
('11111111-1111-1111-1111-111111111021', '1400', 'Forderungen aus Zuschüssen', 'ASSET', 'IDEELL', 'EUR', 'Noch nicht erhaltene Zuschüsse', false),
('11111111-1111-1111-1111-111111111022', '1410', 'Forderungen aus Spenden', 'ASSET', 'IDEELL', 'EUR', 'Zugesagte aber noch nicht erhaltene Spenden', false),

-- Anlagevermögen
('11111111-1111-1111-1111-111111111031', '0400', 'Büroausstattung', 'ASSET', 'IDEELL', 'EUR', 'Computer, Möbel, Technik', true),
('11111111-1111-1111-1111-111111111032', '0410', 'Fahrzeuge', 'ASSET', 'IDEELL', 'EUR', 'Vereinsfahrzeuge', true),
('11111111-1111-1111-1111-111111111033', '0420', 'Software-Lizenzen', 'ASSET', 'IDEELL', 'EUR', 'Software und Lizenzen', true)

ON CONFLICT (id) DO NOTHING;

-- PASSIVA (Schulden/Eigenkapital)
INSERT INTO accounts (id, account_number, account_name, account_type, ngo_area, currency_code, description, tax_relevant) VALUES

-- Eigenkapital
('22222222-2222-2222-2222-222222222001', '2000', 'Vereinsvermögen', 'LIABILITY', 'IDEELL', 'EUR', 'Eigenkapital des Vereins', false),
('22222222-2222-2222-2222-222222222002', '2010', 'Zweckgebundene Rücklagen', 'LIABILITY', 'IDEELL', 'EUR', 'Rücklagen für bestimmte Zwecke', false),
('22222222-2222-2222-2222-222222222003', '2020', 'Freie Rücklagen', 'LIABILITY', 'IDEELL', 'EUR', 'Nicht zweckgebundene Rücklagen', false),

-- Verbindlichkeiten
('22222222-2222-2222-2222-222222222011', '3300', 'Verbindlichkeiten aus L&L', 'LIABILITY', 'IDEELL', 'EUR', 'Offene Rechnungen', true),
('22222222-2222-2222-2222-222222222012', '3310', 'Verbindlichkeiten Sozialversicherung', 'LIABILITY', 'IDEELL', 'EUR', 'SV-Beiträge Mitarbeiter', true),
('22222222-2222-2222-2222-222222222013', '3320', 'Verbindlichkeiten Finanzamt', 'LIABILITY', 'IDEELL', 'EUR', 'Steuerschulden', true),

-- Erhaltene Anzahlungen
('22222222-2222-2222-2222-222222222021', '3400', 'Erhaltene Projektvorschüsse', 'LIABILITY', 'IDEELL', 'EUR', 'Vorschüsse für noch nicht abgerechnete Projekte', false)

ON CONFLICT (id) DO NOTHING;

-- ERTRÄGE (Einnahmen)
INSERT INTO accounts (id, account_number, account_name, account_type, ngo_area, currency_code, description, tax_relevant) VALUES

-- Spenden (steuerfrei im ideellen Bereich)
('33333333-3333-3333-3333-333333333001', '4100', 'Geldspenden', 'REVENUE', 'IDEELL', 'EUR', 'Geldspenden von Privatpersonen', false),
('33333333-3333-3333-3333-333333333002', '4110', 'Sachspenden', 'REVENUE', 'IDEELL', 'EUR', 'Bewertete Sachspenden', false),
('33333333-3333-3333-3333-333333333003', '4120', 'Großspenden', 'REVENUE', 'IDEELL', 'EUR', 'Spenden über 10.000 EUR', false),
('33333333-3333-3333-3333-333333333004', '4130', 'Online-Spenden', 'REVENUE', 'IDEELL', 'EUR', 'Spenden über Website/PayPal', false),

-- Zuschüsse
('33333333-3333-3333-3333-333333333011', '4200', 'Öffentliche Zuschüsse', 'REVENUE', 'IDEELL', 'EUR', 'Zuschüsse von Bund, Ländern, Kommunen', false),
('33333333-3333-3333-3333-333333333012', '4210', 'EU-Fördermittel', 'REVENUE', 'IDEELL', 'EUR', 'Fördergelder der Europäischen Union', false),
('33333333-3333-3333-3333-333333333013', '4220', 'Stiftungsgelder', 'REVENUE', 'IDEELL', 'EUR', 'Zuwendungen von Stiftungen', false),

-- Mitgliedsbeiträge
('33333333-3333-3333-3333-333333333021', '4300', 'Mitgliedsbeiträge', 'REVENUE', 'IDEELL', 'EUR', 'Regelmäßige Mitgliedsbeiträge', false),
('33333333-3333-3333-3333-333333333022', '4310', 'Aufnahmegebühren', 'REVENUE', 'IDEELL', 'EUR', 'Einmalige Aufnahmegebühren', false),

-- Sonstige Erträge
('33333333-3333-3333-3333-333333333031', '4400', 'Zinserträge', 'REVENUE', 'ASSET_MANAGEMENT', 'EUR', 'Zinsen aus Geldanlagen', true),
('33333333-3333-3333-3333-333333333032', '4500', 'Erstattungen', 'REVENUE', 'IDEELL', 'EUR', 'Erstattungen und Rückzahlungen', false)

ON CONFLICT (id) DO NOTHING;

-- AUFWENDUNGEN (Ausgaben)
INSERT INTO accounts (id, account_number, account_name, account_type, ngo_area, currency_code, description, tax_relevant) VALUES

-- Projektaufwendungen (Hauptzweck)
('44444444-4444-4444-4444-444444444001', '6000', 'Projektkosten Ausland', 'EXPENSE', 'IDEELL', 'EUR', 'Direkte Projektkosten im Ausland', false),
('44444444-4444-4444-4444-444444444002', '6010', 'Projektkosten Inland', 'EXPENSE', 'IDEELL', 'EUR', 'Direkte Projektkosten im Inland', false),
('44444444-4444-4444-4444-444444444003', '6020', 'Projektmaterial', 'EXPENSE', 'IDEELL', 'EUR', 'Material und Ausrüstung für Projekte', false),
('44444444-4444-4444-4444-444444444004', '6030', 'Partnerorganisationen', 'EXPENSE', 'IDEELL', 'EUR', 'Zahlungen an lokale Partner', false),

-- Personalkosten
('44444444-4444-4444-4444-444444444011', '6100', 'Löhne und Gehälter', 'EXPENSE', 'IDEELL', 'EUR', 'Bruttogehälter hauptamtlicher Mitarbeiter', true),
('44444444-4444-4444-4444-444444444012', '6110', 'Sozialversicherung AG', 'EXPENSE', 'IDEELL', 'EUR', 'Arbeitgeberanteile SV', true),
('44444444-4444-4444-4444-444444444013', '6120', 'Honorare', 'EXPENSE', 'IDEELL', 'EUR', 'Honorare für freie Mitarbeiter', true),
('44444444-4444-4444-4444-444444444014', '6130', 'Fortbildungskosten', 'EXPENSE', 'IDEELL', 'EUR', 'Weiterbildung der Mitarbeiter', true),

-- Reisekosten
('44444444-4444-4444-4444-444444444021', '6200', 'Reisekosten Projekte', 'EXPENSE', 'IDEELL', 'EUR', 'Reisen für Projektarbeit', false),
('44444444-4444-4444-4444-444444444022', '6210', 'Reisekosten Verwaltung', 'EXPENSE', 'IDEELL', 'EUR', 'Verwaltungsreisen', true),

-- Büro- und Verwaltungskosten
('44444444-4444-4444-4444-444444444031', '6300', 'Büromaterial', 'EXPENSE', 'IDEELL', 'EUR', 'Papier, Stifte, Kleinmaterial', true),
('44444444-4444-4444-4444-444444444032', '6310', 'Porto und Versand', 'EXPENSE', 'IDEELL', 'EUR', 'Portokosten', true),
('44444444-4444-4444-4444-444444444033', '6320', 'Telefon und Internet', 'EXPENSE', 'IDEELL', 'EUR', 'Kommunikationskosten', true),
('44444444-4444-4444-4444-444444444034', '6330', 'Software und IT', 'EXPENSE', 'IDEELL', 'EUR', 'Software-Lizenzen und IT-Kosten', true),

-- Raumkosten
('44444444-4444-4444-4444-444444444041', '6400', 'Miete Büroräume', 'EXPENSE', 'IDEELL', 'EUR', 'Büroräume und Lager', true),
('44444444-4444-4444-4444-444444444042', '6410', 'Nebenkosten', 'EXPENSE', 'IDEELL', 'EUR', 'Strom, Heizung, Wasser', true),
('44444444-4444-4444-4444-444444444043', '6420', 'Gebäudereinigung', 'EXPENSE', 'IDEELL', 'EUR', 'Reinigungskosten', true),

-- Öffentlichkeitsarbeit
('44444444-4444-4444-4444-444444444051', '6500', 'Werbung und Marketing', 'EXPENSE', 'IDEELL', 'EUR', 'Werbematerialien und Kampagnen', false),
('44444444-4444-4444-4444-444444444052', '6510', 'Website und Social Media', 'EXPENSE', 'IDEELL', 'EUR', 'Online-Präsenz', false),
('44444444-4444-4444-4444-444444444053', '6520', 'Druckkosten', 'EXPENSE', 'IDEELL', 'EUR', 'Flyer, Broschüren, Jahresbericht', false),

-- Rechtliche und steuerliche Beratung
('44444444-4444-4444-4444-444444444061', '6600', 'Rechts- und Steuerberatung', 'EXPENSE', 'IDEELL', 'EUR', 'Anwalt und Steuerberater', true),
('44444444-4444-4444-4444-444444444062', '6610', 'Wirtschaftsprüfung', 'EXPENSE', 'IDEELL', 'EUR', 'Jahresabschlussprüfung', true),
('44444444-4444-4444-4444-444444444063', '6620', 'Versicherungen', 'EXPENSE', 'IDEELL', 'EUR', 'Vereinsversicherungen', true),

-- Sonstige Kosten
('44444444-4444-4444-4444-444444444071', '6700', 'Bankgebühren', 'EXPENSE', 'IDEELL', 'EUR', 'Kontoführungsgebühren', true),
('44444444-4444-4444-4444-444444444072', '6710', 'Spendenwerbung', 'EXPENSE', 'IDEELL', 'EUR', 'Kosten für Spenderwerbung (max. 35%)', false),
('44444444-4444-4444-4444-444444444073', '6720', 'Mitgliederversammlung', 'EXPENSE', 'IDEELL', 'EUR', 'Kosten für Vereinsversammlungen', false),

-- Abschreibungen
('44444444-4444-4444-4444-444444444081', '6800', 'Abschreibungen Büroausstattung', 'EXPENSE', 'IDEELL', 'EUR', 'AfA auf Büroeinrichtung', true),
('44444444-4444-4444-4444-444444444082', '6810', 'Abschreibungen Software', 'EXPENSE', 'IDEELL', 'EUR', 'AfA auf Software', true),
('44444444-4444-4444-4444-444444444083', '6820', 'Abschreibungen Fahrzeuge', 'EXPENSE', 'IDEELL', 'EUR', 'AfA auf Vereinsfahrzeuge', true)

ON CONFLICT (id) DO NOTHING;

-- ========================================
-- BEISPIEL-PROJEKTE
-- ========================================
INSERT INTO projects (
    id, 
    project_code, 
    name, 
    description, 
    status, 
    start_date, 
    end_date, 
    budget_amount, 
    budget_currency_code, 
    country, 
    region, 
    ngo_area, 
    donor_information, 
    reporting_required,
    next_report_due
) VALUES
(
    '55555555-5555-5555-5555-555555555001',
    'WATER-2024-001',
    'Trinkwasser Initiative Ostafrika',
    'Bau von Brunnen und Wasseraufbereitungsanlagen in ländlichen Gebieten Kenias. Ziel ist die Versorgung von 5.000 Menschen mit sauberem Trinkwasser.',
    'ACTIVE',
    '2024-01-15',
    '2024-12-31',
    85000.00,
    'EUR',
    'Kenia',
    'Turkana County',
    'IDEELL',
    'EU-Entwicklungsfonds (60%), Privatspenden (40%)',
    true,
    '2024-06-30'
),
(
    '55555555-5555-5555-5555-555555555002',
    'EDU-2024-002',
    'Bildung für Alle - Schulbau',
    'Bau einer Grundschule mit 8 Klassenzimmern in einem abgelegenen Dorf in Uganda. Inklusive Lehrerausbildung und Schulmaterial für 3 Jahre.',
    'PLANNING',
    '2024-03-01',
    '2025-02-28',
    120000.00,
    'EUR',
    'Uganda',
    'Gulu District',
    'IDEELL',
    'Bundesministerium für wirtschaftliche Zusammenarbeit und Entwicklung (BMZ)',
    true,
    '2024-09-30'
),
(
    '55555555-5555-5555-5555-555555555003',
    'HEALTH-2024-003',
    'Mobile Gesundheitsstation',
    'Einrichtung einer mobilen Gesundheitsstation mit medizinischer Grundversorgung für 3 abgelegene Dörfer in Tansania.',
    'APPROVED',
    '2024-05-01',
    '2025-04-30',
    45000.00,
    'EUR',
    'Tansania',
    'Dodoma Region',
    'IDEELL',
    'Aktion Deutschland Hilft, Privatspenden',
    false,
    NULL
),
(
    '55555555-5555-5555-5555-555555555004',
    'ADMIN-2024-001',
    'Vereinsverwaltung 2024',
    'Allgemeine Verwaltungskosten des Vereins für das Jahr 2024. Personalkosten, Bürokosten, IT-Infrastruktur.',
    'ACTIVE',
    '2024-01-01',
    '2024-12-31',
    75000.00,
    'EUR',
    'Deutschland',
    'Berlin',
    'IDEELL',
    'Eigenfinanzierung durch Spenden',
    false,
    NULL
)
ON CONFLICT (id) DO NOTHING;

-- ========================================
-- BEISPIEL-BELEGE
-- ========================================
INSERT INTO receipts (
    id,
    receipt_number,
    type,
    status,
    receipt_date,
    entry_date,
    debit_account_id,
    credit_account_id,
    original_amount,
    original_currency_code,
    base_amount,
    base_currency_code,
    project_id,
    description,
    vendor,
    reference,
    notes,
    created_by
) VALUES
-- Spendeneingänge
(
    '66666666-6666-6666-6666-666666666001',
    'SP-2024-001',
    'INCOME',
    'BOOKED',
    '2024-01-15',
    '2024-01-15',
    '11111111-1111-1111-1111-111111111011', -- Bank Girokonto
    '33333333-3333-3333-3333-333333333001', -- Geldspenden
    2500.00,
    'EUR',
    2500.00,
    'EUR',
    '55555555-5555-5555-5555-555555555001', -- Wasserprojekt
    'Spende für Trinkwasser-Initiative',
    'Max Mustermann',
    'Überweisung vom 15.01.2024',
    'Großzügige Spende für das Wasserprojekt in Kenia',
    (SELECT id FROM auth.users LIMIT 1)
),
(
    '66666666-6666-6666-6666-666666666002',
    'SP-2024-002',
    'INCOME',
    'BOOKED',
    '2024-01-20',
    '2024-01-20',
    '11111111-1111-1111-1111-111111111014', -- PayPal
    '33333333-3333-3333-3333-333333333004', -- Online-Spenden
    150.00,
    'EUR',
    150.00,
    'EUR',
    '55555555-5555-5555-5555-555555555002', -- Bildungsprojekt
    'Online-Spende über Website',
    'PayPal Spender',
    'PayPal-ID: 12345678',
    'Spende über die Vereinswebsite',
    (SELECT id FROM auth.users LIMIT 1)
),

-- EU-Fördermittel
(
    '66666666-6666-6666-6666-666666666003',
    'ZU-2024-001',
    'INCOME',
    'BOOKED',
    '2024-02-01',
    '2024-02-01',
    '11111111-1111-1111-1111-111111111012', -- Bank Projektkonto
    '33333333-3333-3333-3333-333333333012', -- EU-Fördermittel
    50000.00,
    'EUR',
    50000.00,
    'EUR',
    '55555555-5555-5555-5555-555555555001', -- Wasserprojekt
    'EU-Entwicklungsfonds Tranche 1',
    'Europäische Union',
    'Bewilligungsbescheid EU-2024-WATER-001',
    'Erste Tranche der EU-Förderung für das Wasserprojekt',
    (SELECT id FROM auth.users LIMIT 1)
),

-- Projektausgaben
(
    '66666666-6666-6666-6666-666666666004',
    'RE-2024-001',
    'EXPENSE',
    'BOOKED',
    '2024-02-15',
    '2024-02-16',
    '44444444-4444-4444-4444-444444444001', -- Projektkosten Ausland
    '11111111-1111-1111-1111-111111111011', -- Bank Girokonto
    15000.00,
    'EUR',
    15000.00,
    'EUR',
    '55555555-5555-5555-5555-555555555001', -- Wasserprojekt
    'Bohrequipment für Brunnen',
    'African Drilling Ltd.',
    'Rechnung ADL-2024-0156',
    'Spezialisierte Bohrausrüstung für Tiefbrunnen',
    (SELECT id FROM auth.users LIMIT 1)
),
(
    '66666666-6666-6666-6666-666666666005',
    'RE-2024-002',
    'EXPENSE',
    'APPROVED',
    '2024-02-20',
    '2024-02-21',
    '44444444-4444-4444-4444-444444444021', -- Reisekosten Projekte
    '11111111-1111-1111-1111-111111111011', -- Bank Girokonto
    3250.00,
    'EUR',
    3250.00,
    'EUR',
    '55555555-5555-5555-5555-555555555001', -- Wasserprojekt
    'Projektreise nach Kenia',
    'Kenya Airways',
    'Ticket-Nr: KQ-789654123',
    'Flug für Projektleiter zur Standortbesichtigung',
    (SELECT id FROM auth.users LIMIT 1)
),

-- Multi-Währungs-Beispiel
(
    '66666666-6666-6666-6666-666666666006',
    'RE-2024-003',
    'EXPENSE',
    'PENDING_APPROVAL',
    '2024-02-25',
    '2024-02-26',
    '44444444-4444-4444-4444-444444444004', -- Partnerorganisationen
    '11111111-1111-1111-1111-111111111013', -- Bank USD-Konto
    8500.00,
    'USD',
    7650.00, -- Umgerechnet mit Kurs 1.11
    'EUR',
    '55555555-5555-5555-5555-555555555003', -- Gesundheitsprojekt
    'Zahlung an lokale Partnerorganisation',
    'Dodoma Health Initiative',
    'Kooperationsvertrag DHI-2024-01',
    'Quartalszahlung an Partnerorganisation in Tansania',
    (SELECT id FROM auth.users LIMIT 1)
),

-- Verwaltungskosten
(
    '66666666-6666-6666-6666-666666666007',
    'RE-2024-004',
    'EXPENSE',
    'BOOKED',
    '2024-01-31',
    '2024-02-01',
    '44444444-4444-4444-4444-444444444041', -- Miete Büroräume
    '11111111-1111-1111-1111-111111111011', -- Bank Girokonto
    2200.00,
    'EUR',
    2200.00,
    'EUR',
    '55555555-5555-5555-5555-555555555004', -- Verwaltungsprojekt
    'Büro-Miete Februar 2024',
    'Immobilien GmbH Berlin',
    'Rechnung IMG-2024-02',
    'Monatliche Büromiete inkl. Nebenkosten',
    (SELECT id FROM auth.users LIMIT 1)
),
(
    '66666666-6666-6666-6666-666666666008',
    'RE-2024-005',
    'EXPENSE',
    'BOOKED',
    '2024-02-01',
    '2024-02-02',
    '44444444-4444-4444-4444-444444444011', -- Löhne und Gehälter
    '11111111-1111-1111-1111-111111111011', -- Bank Girokonto
    4500.00,
    'EUR',
    4500.00,
    'EUR',
    '55555555-5555-5555-5555-555555555004', -- Verwaltungsprojekt
    'Gehalt Projektkoordinator Februar',
    'Gehaltszahlung',
    'Lohnabrechnung 2024-02',
    'Bruttogehalt für Vollzeit-Projektkoordinator',
    (SELECT id FROM auth.users LIMIT 1)
),

-- IT-Kosten
(
    '66666666-6666-6666-6666-666666666009',
    'RE-2024-006',
    'EXPENSE',
    'DRAFT',
    '2024-03-01',
    '2024-03-01',
    '44444444-4444-4444-4444-444444444034', -- Software und IT
    '11111111-1111-1111-1111-111111111011', -- Bank Girokonto
    299.00,
    'EUR',
    299.00,
    'EUR',
    '55555555-5555-5555-5555-555555555004', -- Verwaltungsprojekt
    'Zentrik Buchhaltungssoftware - Jahresabo',
    'Zentrik Software GmbH',
    'Lizenz-Nr: ZEN-2024-NGO-001',
    'Jahresabonnement für NGO-Buchhaltungssoftware',
    (SELECT id FROM auth.users LIMIT 1)
),

-- Spendenwerbung
(
    '66666666-6666-6666-6666-666666666010',
    'RE-2024-007',
    'EXPENSE',
    'PENDING_APPROVAL',
    '2024-02-28',
    '2024-03-01',
    '44444444-4444-4444-4444-444444444072', -- Spendenwerbung
    '11111111-1111-1111-1111-111111111011', -- Bank Girokonto
    1800.00,
    'EUR',
    1800.00,
    'EUR',
    NULL, -- Nicht projektbezogen
    'Facebook-Werbung für Spendenkampagne',
    'Meta Platforms Ireland',
    'Kampagne-ID: FB-2024-WATER-HELP',
    'Social Media Werbung für das Wasserprojekt',
    (SELECT id FROM auth.users LIMIT 1)
)
ON CONFLICT (id) DO NOTHING;

-- ========================================
-- UPDATE PROJEKT SPENT_AMOUNT
-- ========================================
-- Aktualisiere die ausgegebenen Beträge basierend auf gebuchten Belegen
UPDATE projects SET spent_amount = (
    SELECT COALESCE(SUM(r.base_amount), 0)
    FROM receipts r 
    WHERE r.project_id = projects.id 
    AND r.status = 'BOOKED' 
    AND r.type = 'EXPENSE'
) - (
    SELECT COALESCE(SUM(r.base_amount), 0)
    FROM receipts r 
    WHERE r.project_id = projects.id 
    AND r.status = 'BOOKED' 
    AND r.type = 'INCOME'
);

-- ========================================
-- DEMO-BENUTZER (für Tests)
-- ========================================
-- Diese Daten werden normalerweise über die Auth-API erstellt
-- Hier nur als Beispiel für die Datenstruktur

COMMENT ON TABLE currencies IS 'Standard-Währungen für internationale NGO-Arbeit';
COMMENT ON TABLE accounts IS 'SKR-Kontenrahmen speziell angepasst für gemeinnützige Organisationen';
COMMENT ON TABLE projects IS 'Beispiel-Projekte zeigen verschiedene NGO-Aktivitäten';
COMMENT ON TABLE receipts IS 'Beispiel-Belege demonstrieren verschiedene Geschäftsfälle';

-- ========================================
-- HILFSFUNKTIONEN FÜR ENTWICKLUNG
-- ========================================

-- Funktion zum Zurücksetzen der Demo-Daten
CREATE OR REPLACE FUNCTION reset_demo_data()
RETURNS void AS $
BEGIN
    -- Lösche Belege (wegen Foreign Keys zuerst)
    DELETE FROM receipts WHERE id LIKE '66666666-%';
    
    -- Lösche Projekte
    DELETE FROM projects WHERE id LIKE '55555555-%';
    
    -- Setze Spent-Amounts zurück
    UPDATE projects SET spent_amount = 0;
    
    RAISE NOTICE 'Demo-Daten wurden zurückgesetzt';
END;
$ LANGUAGE plpgsql;

-- Funktion zur Neuberechnung der Projektbudgets
CREATE OR REPLACE FUNCTION recalculate_project_budgets()
RETURNS void AS $
BEGIN
    UPDATE projects SET spent_amount = (
        SELECT COALESCE(SUM(
            CASE 
                WHEN r.type = 'EXPENSE' THEN r.base_amount
                WHEN r.type = 'INCOME' THEN -r.base_amount
                ELSE 0
            END
        ), 0)
        FROM receipts r 
        WHERE r.project_id = projects.id 
        AND r.status = 'BOOKED'
    );
    
    RAISE NOTICE 'Projektbudgets wurden neu berechnet';
END;
$ LANGUAGE plpgsql;

-- ========================================
-- INDEXE FÜR BESSERE PERFORMANCE
-- ========================================

-- Zusammengesetzte Indizes für häufige Abfragen
CREATE INDEX IF NOT EXISTS idx_receipts_project_status_type ON receipts(project_id, status, type);
CREATE INDEX IF NOT EXISTS idx_receipts_date_status ON receipts(receipt_date, status);
CREATE INDEX IF NOT EXISTS idx_projects_status_active ON projects(status, is_active);
CREATE INDEX IF NOT EXISTS idx_accounts_type_area ON accounts(account_type, ngo_area);

-- ========================================
-- PERFORMANCE-VIEWS
-- ========================================

-- View für schnelle Dashboard-Abfragen
CREATE OR REPLACE VIEW dashboard_summary AS
SELECT 
    'projects' as metric,
    COUNT(*) as total_count,
    COUNT(*) FILTER (WHERE status = 'ACTIVE') as active_count,
    COUNT(*) FILTER (WHERE status = 'COMPLETED') as completed_count,
    SUM(budget_amount) as total_budget,
    SUM(spent_amount) as total_spent
FROM projects WHERE is_active = true

UNION ALL

SELECT 
    'receipts' as metric,
    COUNT(*) as total_count,
    COUNT(*) FILTER (WHERE status = 'PENDING_APPROVAL') as pending_count,
    COUNT(*) FILTER (WHERE status = 'BOOKED') as booked_count,
    SUM(base_amount) FILTER (WHERE type = 'INCOME' AND status = 'BOOKED') as total_income,
    SUM(base_amount) FILTER (WHERE type = 'EXPENSE' AND status = 'BOOKED') as total_expenses
FROM receipts;

-- View für Währungsstatistiken
CREATE OR REPLACE VIEW currency_usage AS
SELECT 
    c.code,
    c.name,
    c.symbol,
    COUNT(DISTINCT p.id) as projects_count,
    COUNT(DISTINCT r.id) as receipts_count,
    SUM(CASE WHEN r.status = 'BOOKED' THEN r.original_amount ELSE 0 END) as total_amount
FROM currencies c
LEFT JOIN projects p ON c.code = p.budget_currency_code
LEFT JOIN receipts r ON c.code = r.original_currency_code
WHERE c.is_active = true
GROUP BY c.code, c.name, c.symbol
ORDER BY total_amount DESC;

-- ========================================
-- DATENBANK-WARTUNG
-- ========================================

-- Regelmäßige Bereinigung alter Audit-Logs (älter als 7 Jahre)
CREATE OR REPLACE FUNCTION cleanup_old_audit_logs()
RETURNS void AS $
BEGIN
    DELETE FROM audit_log 
    WHERE changed_at < NOW() - INTERVAL '7 years';
    
    GET DIAGNOSTICS rows_deleted = ROW_COUNT;
    RAISE NOTICE 'Deleted % old audit log entries', rows_deleted;
END;
$ LANGUAGE plpgsql;

-- ========================================
-- BERECHTIGUNG FÜR DEMO-USER
-- ========================================

-- Grant Berechtigungen für authentifizierte Benutzer
GRANT SELECT ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT INSERT, UPDATE ON receipts TO authenticated;
GRANT INSERT, UPDATE ON projects TO authenticated;

-- Grant für Service Role (Admin)
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;

-- Grant für Anonymous (nur Lesezugriff auf öffentliche Daten)
GRANT SELECT ON currencies TO anon;

COMMIT;
