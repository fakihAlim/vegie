-- ============================================
-- Migration: Badge Categories & Targets
-- Vegie / LovingHarmony App
-- ============================================

-- Add category and target_value columns to badges table
ALTER TABLE badges 
ADD COLUMN category VARCHAR(50) NOT NULL DEFAULT 'plant_lover' COMMENT 'explorer, streak, plant_lover, quiz_ace' AFTER code,
ADD COLUMN target_value INT NOT NULL DEFAULT 1 AFTER category;

-- Update existing seeded badges with their correct categories and targets
UPDATE badges SET category = 'plant_lover', target_value = 1 WHERE code = 'first_step';
UPDATE badges SET category = 'explorer', target_value = 3 WHERE code = 'explorer';
UPDATE badges SET category = 'streak', target_value = 7 WHERE code = 'streak_7';
UPDATE badges SET category = 'plant_lover', target_value = 10 WHERE code = 'plant_lover';
UPDATE badges SET category = 'quiz_ace', target_value = 5 WHERE code = 'quiz_ace';
