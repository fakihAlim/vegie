-- ============================================
-- Migration: Add Carbon Footprint Calculator
-- LovingHarmony Database Schema
-- ============================================

-- Tugas 1: Update Tabel Users
-- Menambahkan kolom total_carbon_saved (DECIMAL(10,2), default 0.00)
ALTER TABLE users 
  ADD COLUMN total_carbon_saved DECIMAL(10,2) NOT NULL DEFAULT 0.00 AFTER height;

-- Tugas 2: Buat Tabel Emission Factors
CREATE TABLE IF NOT EXISTS emission_factors (
    id INT PRIMARY KEY AUTO_INCREMENT,
    food_name VARCHAR(150) NOT NULL UNIQUE,
    category VARCHAR(100) NOT NULL,
    emission_factor DECIMAL(8,2) NOT NULL,
    unit VARCHAR(50) NOT NULL DEFAULT 'kg CO2e/kg',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Tugas 3: Seeding Data Master Emission Factors
INSERT INTO emission_factors (food_name, category, emission_factor) VALUES
('Nasi Putih', 'Karbohidrat', 4.00),
('Jagung', 'Karbohidrat', 1.70),
('Kentang', 'Karbohidrat', 0.50),
('Tempe', 'Protein Nabati', 1.50),
('Tahu', 'Protein Nabati', 2.00),
('Kacang kedelai', 'Protein Nabati', 2.00),
('Kangkung', 'Sayuran', 0.40),
('Bayam', 'Sayuran', 0.50),
('Brokoli', 'Sayuran', 0.50),
('Tomat', 'Sayuran', 1.10),
('Pisang', 'Buah', 0.70),
('Ayam', 'Protein Hewani', 6.00),
('Telur', 'Protein Hewani', 4.50),
('Ikan Laut', 'Protein Hewani', 5.00),
('Daging Sapi', 'Protein Hewani', 60.00)
ON DUPLICATE KEY UPDATE 
  category = VALUES(category),
  emission_factor = VALUES(emission_factor);
