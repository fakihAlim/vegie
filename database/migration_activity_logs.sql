-- ============================================
-- Migration: Add user_activity_logs table
-- ============================================

USE lovingharmony;

CREATE TABLE IF NOT EXISTS user_activity_logs (
  id            INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  user_id       INT          NOT NULL,
  session_id    VARCHAR(50)  DEFAULT NULL, -- to group actions under the same session
  action        VARCHAR(100) NOT NULL,     -- 'app_open', 'app_close', 'screen_view', etc.
  screen        VARCHAR(100) DEFAULT NULL, -- 'HomeScreen', 'FoodLogScreen', etc.
  duration      INT UNSIGNED DEFAULT NULL, -- session duration or screen duration in seconds
  extra_data    JSON         DEFAULT NULL, -- additional info
  platform      VARCHAR(20)  DEFAULT NULL, -- 'android' / 'ios'
  device_name   VARCHAR(100) DEFAULT NULL, -- e.g. 'Samsung SM-G998B'
  os_version    VARCHAR(50)  DEFAULT NULL, -- e.g. 'Android 12'
  app_version   VARCHAR(20)  DEFAULT NULL, -- e.g. '1.0.0'
  created_at    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id),
  INDEX idx_session_id (session_id),
  INDEX idx_action (action),
  INDEX idx_created (created_at)
) ENGINE=InnoDB;
