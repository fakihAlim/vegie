-- ============================================
-- Migration: Add TTM columns to users
-- Run this on existing databases
-- ============================================

ALTER TABLE users
  ADD COLUMN ttm_stage ENUM('precontemplation', 'contemplation', 'preparation', 'action', 'maintenance') DEFAULT 'precontemplation' AFTER is_onboarding_completed,
  ADD COLUMN ttm_action_start_date DATE NULL DEFAULT NULL AFTER ttm_stage;
