-- ============================================
-- Migration: Add gender column to users
-- Run this on existing databases
-- ============================================

ALTER TABLE users
  ADD COLUMN gender VARCHAR(10) NULL DEFAULT NULL AFTER height;
