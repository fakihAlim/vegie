-- ============================================
-- Migration: Add nutrition columns to food_logs
-- Run this on existing databases
-- ============================================

ALTER TABLE food_logs
  ADD COLUMN calories FLOAT DEFAULT NULL AFTER nutrition_notes,
  ADD COLUMN carbs FLOAT DEFAULT NULL AFTER calories,
  ADD COLUMN fat FLOAT DEFAULT NULL AFTER carbs,
  ADD COLUMN protein FLOAT DEFAULT NULL AFTER fat;
