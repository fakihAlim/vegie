-- Add points column to food_logs table
ALTER TABLE food_logs ADD COLUMN points INT DEFAULT 0 AFTER protein;
