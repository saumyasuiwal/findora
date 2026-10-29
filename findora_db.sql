-- =====================================================================
-- FINDORA DATABASE INITIALIZATION SCRIPT (findora_db)
-- Smart Campus Lost & Found Management System
-- Compatible with MySQL 8.0+ and embedded H2 SQL engine
-- =====================================================================

CREATE DATABASE IF NOT EXISTS findora_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE findora_db;

-- 1. USERS TABLE
CREATE TABLE IF NOT EXISTS users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    student_id VARCHAR(50) UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'STUDENT',
    account_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_user_email ON users (email);
CREATE INDEX IF NOT EXISTS idx_user_role ON users (role);

-- 2. CAMPUS LOCATIONS TABLE
CREATE TABLE IF NOT EXISTS campus_locations (
    location_id INT AUTO_INCREMENT PRIMARY KEY,
    location_name VARCHAR(120) NOT NULL UNIQUE,
    description VARCHAR(255),
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_location_active ON campus_locations (is_active);

-- 3. ITEMS TABLE (Lost and Found Reports)
CREATE TABLE IF NOT EXISTS items (
    item_id INT AUTO_INCREMENT PRIMARY KEY,
    reporter_id INT NOT NULL,
    item_type VARCHAR(10) NOT NULL,
    item_name VARCHAR(150) NOT NULL,
    category VARCHAR(80) NOT NULL,
    public_description TEXT NOT NULL,
    private_verification_details TEXT,
    location_id INT NOT NULL,
    event_date DATE NOT NULL,
    approximate_time VARCHAR(50),
    image_path VARCHAR(255),
    custody_status VARCHAR(50) DEFAULT 'HELD_BY_FINDER',
    report_status VARCHAR(30) NOT NULL DEFAULT 'OPEN',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (reporter_id) REFERENCES users(user_id) ON DELETE RESTRICT,
    FOREIGN KEY (location_id) REFERENCES campus_locations(location_id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_items_type ON items (item_type);
CREATE INDEX IF NOT EXISTS idx_items_category ON items (category);
CREATE INDEX IF NOT EXISTS idx_items_location ON items (location_id);
CREATE INDEX IF NOT EXISTS idx_items_status ON items (report_status);
CREATE INDEX IF NOT EXISTS idx_items_date ON items (event_date);

-- 4. SMART MATCHES TABLE
CREATE TABLE IF NOT EXISTS matches (
    match_id INT AUTO_INCREMENT PRIMARY KEY,
    lost_item_id INT NOT NULL,
    found_item_id INT NOT NULL,
    match_score INT NOT NULL,
    match_explanation TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_checked_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (lost_item_id) REFERENCES items(item_id) ON DELETE CASCADE,
    FOREIGN KEY (found_item_id) REFERENCES items(item_id) ON DELETE CASCADE,
    CONSTRAINT uq_lost_found_match UNIQUE (lost_item_id, found_item_id)
);

CREATE INDEX IF NOT EXISTS idx_matches_score ON matches (match_score);

-- 5. CLAIMS TABLE
CREATE TABLE IF NOT EXISTS claims (
    claim_id INT AUTO_INCREMENT PRIMARY KEY,
    item_id INT NOT NULL,
    claimant_id INT NOT NULL,
    ownership_explanation TEXT NOT NULL,
    evidence_path VARCHAR(255),
    claim_status VARCHAR(30) NOT NULL DEFAULT 'PENDING',
    reviewed_by INT NULL,
    review_reason TEXT,
    submitted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    reviewed_at TIMESTAMP NULL,
    FOREIGN KEY (item_id) REFERENCES items(item_id) ON DELETE CASCADE,
    FOREIGN KEY (claimant_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (reviewed_by) REFERENCES users(user_id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_claims_status ON claims (claim_status);
CREATE INDEX IF NOT EXISTS idx_claims_item ON claims (item_id);
CREATE INDEX IF NOT EXISTS idx_claims_claimant ON claims (claimant_id);

-- 6. NOTIFICATIONS TABLE
CREATE TABLE IF NOT EXISTS notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    related_item_id INT NULL,
    related_claim_id INT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    FOREIGN KEY (related_item_id) REFERENCES items(item_id) ON DELETE SET NULL,
    FOREIGN KEY (related_claim_id) REFERENCES claims(claim_id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_notif_user_read ON notifications (user_id, is_read);

-- 7. RETURNS TABLE
CREATE TABLE IF NOT EXISTS returns (
    return_id INT AUTO_INCREMENT PRIMARY KEY,
    item_id INT NOT NULL,
    claim_id INT NOT NULL UNIQUE,
    claimant_id INT NOT NULL,
    verified_by INT NOT NULL,
    returned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    handover_notes TEXT,
    FOREIGN KEY (item_id) REFERENCES items(item_id) ON DELETE RESTRICT,
    FOREIGN KEY (claim_id) REFERENCES claims(claim_id) ON DELETE RESTRICT,
    FOREIGN KEY (claimant_id) REFERENCES users(user_id) ON DELETE RESTRICT,
    FOREIGN KEY (verified_by) REFERENCES users(user_id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_returns_item ON returns (item_id);

-- 8. PICKUP TOKENS TABLE
CREATE TABLE IF NOT EXISTS pickup_tokens (
    token_id INT AUTO_INCREMENT PRIMARY KEY,
    claim_id INT NOT NULL UNIQUE,
    token_code VARCHAR(64) NOT NULL UNIQUE,
    token_hash VARCHAR(128) NOT NULL,
    is_used BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NOT NULL,
    FOREIGN KEY (claim_id) REFERENCES claims(claim_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_token_code ON pickup_tokens (token_code);

-- 9. AUDIT LOGS TABLE
CREATE TABLE IF NOT EXISTS audit_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    actor_id INT NULL,
    actor_name VARCHAR(100),
    action VARCHAR(100) NOT NULL,
    affected_record VARCHAR(100),
    details TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_audit_action ON audit_logs (action);

-- =====================================================================
-- SEED DATA
-- Default Password for all demo accounts: Password@123
-- =====================================================================

-- Campus Locations
INSERT INTO campus_locations (location_id, location_name, description, is_active) VALUES
(1, 'Central Library - 1st Floor Reading Hall', 'Main student study hall and silent reading area', TRUE),
(2, 'Central Library - 3rd Floor Digital Lab', 'Computer workstation area with high-speed internet', TRUE),
(3, 'Engineering Block A - Room 204', 'Lecture hall for Computer Science & IT departments', TRUE),
(4, 'Science Complex - Chemistry Lab 2', 'Undergraduate practical laboratory on ground floor', TRUE),
(5, 'Main Student Cafeteria', 'Central dining hall, food court, and terrace seating', TRUE),
(6, 'Sports Complex - Indoor Badminton Court', 'Main sports pavilion and locker room hallway', TRUE),
(7, 'University Auditorium', 'Main seminar hall and performing arts auditorium', TRUE),
(8, 'Innovation & Research Hub', 'Incubation center, robotics lab, and collaborative space', TRUE),
(9, 'Campus Green Lawn & Amphitheatre', 'Outdoor central student gathering area', TRUE),
(10, 'North Hostel Block - Common Room', 'Residential common lounge and recreational hall', TRUE);

-- Users
INSERT INTO users (user_id, full_name, email, student_id, password_hash, role, account_status) VALUES
(1, 'Campus Safety Administrator', 'admin@findora.campus.edu', 'ADM-001', '$2a$10$kXUGzUhDHF/ITLFwb0NVoOZxKfVEp1stD.p1yq5sxOVE3DiX9mD2C', 'ADMIN', 'ACTIVE'),
(2, 'Alex Rivers', 'alex.rivers@campus.edu', 'STU-2024-001', '$2a$10$kXUGzUhDHF/ITLFwb0NVoOZxKfVEp1stD.p1yq5sxOVE3DiX9mD2C', 'STUDENT', 'ACTIVE'),
(3, 'Priya Sharma', 'priya.sharma@campus.edu', 'STU-2024-002', '$2a$10$kXUGzUhDHF/ITLFwb0NVoOZxKfVEp1stD.p1yq5sxOVE3DiX9mD2C', 'STUDENT', 'ACTIVE'),
(4, 'Marcus Chen', 'marcus.chen@campus.edu', 'STU-2024-003', '$2a$10$kXUGzUhDHF/ITLFwb0NVoOZxKfVEp1stD.p1yq5sxOVE3DiX9mD2C', 'STUDENT', 'ACTIVE'),
(5, 'Sarah Jenkins', 'sarah.jenkins@campus.edu', 'STU-2024-004', '$2a$10$kXUGzUhDHF/ITLFwb0NVoOZxKfVEp1stD.p1yq5sxOVE3DiX9mD2C', 'STUDENT', 'ACTIVE');

-- Seed Items: Realistic Campus Scenarios
INSERT INTO items (item_id, reporter_id, item_type, item_name, category, public_description, private_verification_details, location_id, event_date, approximate_time, image_path, custody_status, report_status) VALUES
(1, 2, 'LOST', 'Black Leather Fossil Wallet', 'Wallets and bags', 'Black bi-fold leather wallet with subtle stitch details. Contains college ID and transit pass.', 'Has a silver Metro card inside with initials A.R. and a family photo behind the left flap.', 1, '2026-10-27', '14:30', 'wallet_lost.jpg', 'N_A', 'OPEN'),
(2, 3, 'FOUND', 'Black Leather Bi-fold Wallet', 'Wallets and bags', 'Found a black leather wallet under the reading desk near aisle 4.', 'Contains student transit card ending in 8421 and family photo inside sleeve.', 1, '2026-10-28', '16:00', 'wallet_found.jpg', 'LOST_PROPERTY_OFFICE', 'OPEN'),
(3, 4, 'LOST', 'Cobalt Blue Hydro Flask 32oz', 'Water bottles', 'Wide-mouth insulated bottle with black flex cap. Blue color with a few outdoor stickers.', 'Has a distinct hexagonal GitHub sticker and a minor scratch on the bottom base rim.', 5, '2026-10-26', '12:45', 'bottle_lost.jpg', 'N_A', 'OPEN'),
(4, 5, 'FOUND', 'Blue Stainless Steel Hydro Flask', 'Water bottles', 'Found blue water bottle on cafeteria booth table 12.', 'Sticker on side says Git and has indentation scratch underneath.', 5, '2026-10-27', '13:30', 'bottle_found.jpg', 'HELD_BY_FINDER', 'OPEN'),
(5, 2, 'LOST', 'Sony WH-1000XM4 Headphones (Silver)', 'Electronics', 'Silver/platinum grey over-ear headphones in original grey hard-shell case.', 'Serial number ending in 9043. Right ear cup cushion has a small red speck.', 2, '2026-10-24', '11:15', 'headphones.jpg', 'N_A', 'RESOLVED'),
(6, 4, 'FOUND', 'Sony Wireless Headphones with Case', 'Electronics', 'Grey Sony over-ear headphones found at 3rd floor workstation.', 'Right pad has red marker mark. Hard zipper case with auxiliary cable.', 2, '2026-10-24', '15:00', 'headphones.jpg', 'LOST_PROPERTY_OFFICE', 'RESOLVED'),
(7, 3, 'LOST', 'Casio FX-991EX Scientific Calculator', 'Books and stationery', 'Black scientific calculator with slide-on protective cover.', 'Name "P. Sharma" inscribed with blue permanent marker on the inside lid.', 3, '2026-10-28', '10:00', 'calculator.jpg', 'N_A', 'OPEN'),
(8, 5, 'FOUND', 'University Student ID Card', 'Identity cards and documents', 'Found campus smart card in sports complex corridor.', 'Belongs to student ID STU-2024-001 with barcode readable.', 6, '2026-10-29', '09:15', 'id_card.jpg', 'CAMPUS_STAFF', 'OPEN');

-- Smart Match
INSERT INTO matches (match_id, lost_item_id, found_item_id, match_score, match_explanation) VALUES
(1, 1, 2, 92, '{"categoryScore":25,"nameScore":23,"descScore":18,"locationScore":15,"dateScore":11,"totalScore":92,"confidence":"Strong Potential Match","explanation":"Identical category (Wallets and bags), high title resemblance (Black Leather Wallet), exact campus location (Central Library), and 1-day date proximity."}');

-- Pre-seed Claim and Return for Headphones
INSERT INTO claims (claim_id, item_id, claimant_id, ownership_explanation, claim_status, reviewed_by, review_reason, submitted_at, reviewed_at) VALUES
(1, 6, 2, 'These are my Sony WH-1000XM4 headphones lost on Wednesday. I have the companion app registered to my phone and can demonstrate bluetooth pairing.', 'APPROVED', 1, 'Claimant verified serial number and connected device via Sony Headphones Connect app.', '2026-10-25 14:00:00', '2026-10-26 10:30:00');

INSERT INTO returns (return_id, item_id, claim_id, claimant_id, verified_by, returned_at, handover_notes) VALUES
(1, 6, 1, 2, 1, '2026-10-26 11:00:00', 'Handover completed at Central Safety Desk. Student showed college ID STU-2024-001 and signed physical ledger.');

-- Notifications
INSERT INTO notifications (user_id, related_item_id, related_claim_id, message, is_read) VALUES
(2, 2, NULL, 'Strong potential match found (92% match) for your lost "Black Leather Fossil Wallet" at Central Library!', FALSE),
(2, 6, 1, 'Your ownership claim for "Sony Wireless Headphones with Case" was APPROVED! Visit Campus Safety Desk for pickup.', TRUE),
(4, 4, NULL, 'A potential match was calculated for your lost Cobalt Blue Hydro Flask at Main Student Cafeteria.', FALSE);

-- Audit Log Entry
INSERT INTO audit_logs (actor_id, actor_name, action, affected_record, details) VALUES
(1, 'Campus Safety Administrator', 'CLAIM_APPROVED', 'Claim #1', 'Approved claim for Sony Wireless Headphones after verifying app pairing.');
