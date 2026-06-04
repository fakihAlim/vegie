<?php
/**
 * AI Key Manager & Smart Weighted Load Balancer
 * LovingHarmony API
 */

class AiKeyManager {
    private static $cipher = 'aes-256-cbc';

    /**
     * Retrieve encryption secret key from environment configuration.
     */
    private static function getSecretKey() {
        if (defined('AI_SECRET_KEY')) {
            return AI_SECRET_KEY;
        }
        // Fallback loader if constant not defined
        $envPath = __DIR__ . '/../env.php';
        if (file_exists($envPath)) {
            $env = @require $envPath;
            if (isset($env['AI_SECRET_KEY'])) {
                return $env['AI_SECRET_KEY'];
            }
        }
        return ''; // Fallback to empty if not configured
    }

    /**
     * Reversibly encrypt an API key using AES-256-CBC.
     */
    public static function encrypt($plaintext) {
        if (empty($plaintext)) return '';
        $ivlen = openssl_cipher_iv_length(self::$cipher);
        $iv = openssl_random_pseudo_bytes($ivlen);
        $ciphertext_raw = openssl_encrypt($plaintext, self::$cipher, self::getSecretKey(), OPENSSL_RAW_DATA, $iv);
        return base64_encode($iv . $ciphertext_raw);
    }

    /**
     * Decrypt a ciphertext API key using AES-256-CBC.
     * Automatically falls back to plaintext if key is not encrypted.
     */
    public static function decrypt($ciphertext) {
        if (empty($ciphertext)) return '';
        $c = base64_decode($ciphertext, true);
        if ($c === false) return $ciphertext; // Fallback for raw plaintext
        
        $ivlen = openssl_cipher_iv_length(self::$cipher);
        if (strlen($c) < $ivlen) {
            return $ciphertext; // Fallback for raw plaintext
        }
        
        $iv = substr($c, 0, $ivlen);
        $ciphertext_raw = substr($c, $ivlen);
        
        $plaintext = openssl_decrypt($ciphertext_raw, self::$cipher, self::getSecretKey(), OPENSSL_RAW_DATA, $iv);
        return $plaintext !== false ? $plaintext : $ciphertext;
    }
    
    /**
     * Check and refresh key windows dynamically.
     * Automatically unblocks keys whose time/day windows have expired.
     */
    public static function getActiveKeys($db) {
        $now = date('Y-m-d H:i:s');
        $today = date('Y-m-d');
        $currentMinute = date('Y-m-d H:i:00');
        
        // Fetch all keys
        $stmt = $db->query("SELECT * FROM ai_gemini_keys ORDER BY id ASC");
        $keys = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        $refreshedKeys = [];
        foreach ($keys as $key) {
            $key['api_key'] = self::decrypt($key['api_key']);
            $updated = false;
            
            // Check RPM window (1 minute)
            $rpmWindow = $key['rpm_window_start'] ? date('Y-m-d H:i:00', strtotime($key['rpm_window_start'])) : null;
            if ($rpmWindow !== $currentMinute) {
                $key['rpm_usage'] = 0;
                $key['rpm_window_start'] = $currentMinute;
                $updated = true;
            }
            
            // Check TPM window (1 minute)
            $tpmWindow = $key['tpm_window_start'] ? date('Y-m-d H:i:00', strtotime($key['tpm_window_start'])) : null;
            if ($tpmWindow !== $currentMinute) {
                $key['tpm_usage'] = 0;
                $key['tpm_window_start'] = $currentMinute;
                $updated = true;
            }
            
            // Check RPD window (1 day)
            $rpdWindow = $key['rpd_window_start'] ? date('Y-m-d', strtotime($key['rpd_window_start'])) : null;
            if ($rpdWindow !== $today) {
                $key['rpd_usage'] = 0;
                $key['total_requests_today'] = 0;
                $key['rpd_window_start'] = $today;
                $updated = true;
            }
            
            // Unblock key if it was Temporarily Unavailable but its limits are cleared
            if ($key['status'] === 'temporarily_unavailable') {
                if ($key['rpm_usage'] < $key['rpm_limit'] && 
                    $key['tpm_usage'] < $key['tpm_limit'] && 
                    $key['rpd_usage'] < $key['rpd_limit']) {
                    $key['status'] = 'active';
                    $updated = true;
                }
            }
            
            if ($updated) {
                $updateStmt = $db->prepare("
                    UPDATE ai_gemini_keys 
                    SET status = ?, rpm_usage = ?, tpm_usage = ?, rpd_usage = ?, total_requests_today = ?, 
                        rpm_window_start = ?, tpm_window_start = ?, rpd_window_start = ?
                    WHERE id = ?
                ");
                $updateStmt->execute([
                    $key['status'],
                    $key['rpm_usage'],
                    $key['tpm_usage'],
                    $key['rpd_usage'],
                    $key['total_requests_today'],
                    $key['rpm_window_start'],
                    $key['tpm_window_start'],
                    $key['rpd_window_start'],
                    $key['id']
                ]);
            }
            
            $refreshedKeys[] = $key;
        }
        
        return $refreshedKeys;
    }
    
    /**
     * Choose the best API key according to load balancer rules:
     * 1. Calculate percentage usages.
     * 2. Choose key with lowest usage percentage.
     * 3. Demote near limit keys (> 90%).
     * 4. Tie-break using LRU (Least Recently Used).
     */
    public static function selectBestKey($db, &$allKeys = null) {
        $keys = self::getActiveKeys($db);
        $allKeys = $keys; // expose refreshed list to caller if needed
        
        if (empty($keys)) {
            return null;
        }
        
        $availableKeys = [];
        foreach ($keys as $key) {
            // Check status or hard limits
            if ($key['status'] === 'temporarily_unavailable' || $key['status'] === 'blocked') {
                continue;
            }
            
            if ($key['rpm_usage'] >= $key['rpm_limit'] || 
                $key['tpm_usage'] >= $key['tpm_limit'] || 
                $key['rpd_usage'] >= $key['rpd_limit']) {
                
                // Mark as Temporarily Unavailable
                $db->prepare("UPDATE ai_gemini_keys SET status = 'temporarily_unavailable' WHERE id = ?")
                   ->execute([$key['id']]);
                continue;
            }
            
            $availableKeys[] = $key;
        }
        
        if (empty($availableKeys)) {
            return null;
        }
        
        $normalKeys = [];
        $nearLimitKeys = [];
        
        foreach ($availableKeys as $key) {
            $rpmPct = $key['rpm_usage'] / $key['rpm_limit'];
            $tpmPct = $key['tpm_usage'] / $key['tpm_limit'];
            $rpdPct = $key['rpd_usage'] / $key['rpd_limit'];
            
            $maxPct = max($rpmPct, $tpmPct, $rpdPct);
            $key['max_pct'] = $maxPct;
            $key['rpm_pct'] = $rpmPct;
            $key['tpm_pct'] = $tpmPct;
            $key['rpd_pct'] = $rpdPct;
            
            // Near limit = > 90% in any limit
            if ($rpmPct > 0.9 || $tpmPct > 0.9 || $rpdPct > 0.9) {
                $nearLimitKeys[] = $key;
            } else {
                $normalKeys[] = $key;
            }
        }
        
        // Choose group: prefer normal keys, fallback to near limit keys
        $selectedGroup = !empty($normalKeys) ? $normalKeys : $nearLimitKeys;
        
        // Sort keys:
        // 1. Percentage usage (max_pct ascending)
        // 2. Least recently used (last_used_at ascending, nulls are oldest/treated as 0)
        usort($selectedGroup, function($a, $b) {
            if (abs($a['max_pct'] - $b['max_pct']) > 0.0001) {
                return $a['max_pct'] <=> $b['max_pct'];
            }
            
            $timeA = $a['last_used_at'] ? strtotime($a['last_used_at']) : 0;
            $timeB = $b['last_used_at'] ? strtotime($b['last_used_at']) : 0;
            return $timeA <=> $timeB;
        });
        
        return $selectedGroup[0];
    }
    
    /**
     * Record a successful request: increment counters and update timestamps.
     */
    public static function recordSuccess($db, $keyId, $tokensUsed) {
        $stmt = $db->prepare("
            UPDATE ai_gemini_keys 
            SET rpm_usage = rpm_usage + 1, 
                tpm_usage = tpm_usage + ?, 
                rpd_usage = rpd_usage + 1, 
                total_requests_today = total_requests_today + 1,
                last_used_at = CURRENT_TIMESTAMP
            WHERE id = ?
        ");
        $stmt->execute([$tokensUsed, $keyId]);
        
        // Ensure status is updated if it crossed the 100% threshold
        $stmt = $db->prepare("SELECT * FROM ai_gemini_keys WHERE id = ?");
        $stmt->execute([$keyId]);
        $key = $stmt->fetch();
        if ($key) {
            if ($key['rpm_usage'] >= $key['rpm_limit'] || 
                $key['tpm_usage'] >= $key['tpm_limit'] || 
                $key['rpd_usage'] >= $key['rpd_limit']) {
                $db->prepare("UPDATE ai_gemini_keys SET status = 'temporarily_unavailable' WHERE id = ?")
                   ->execute([$keyId]);
            } elseif ($key['rpm_usage'] / $key['rpm_limit'] > 0.9 || 
                      $key['tpm_usage'] / $key['tpm_limit'] > 0.9 || 
                      $key['rpd_usage'] / $key['rpd_limit'] > 0.9) {
                $db->prepare("UPDATE ai_gemini_keys SET status = 'near_limit' WHERE id = ?")
                   ->execute([$keyId]);
            } else {
                $db->prepare("UPDATE ai_gemini_keys SET status = 'active' WHERE id = ?")
                   ->execute([$keyId]);
            }
        }
    }
    
    /**
     * Record a failed request (e.g. rate limit error or HTTP 429).
     */
    public static function recordFailure($db, $keyId, $status = 'temporarily_unavailable') {
        $stmt = $db->prepare("UPDATE ai_gemini_keys SET status = ? WHERE id = ?");
        $stmt->execute([$status, $keyId]);
    }
    
    /**
     * Check if Adaptive Key Management is enabled.
     */
    public static function isAdaptiveEnabled($db) {
        $stmt = $db->prepare("SELECT setting_value FROM ai_settings WHERE setting_key = 'adaptive_key_management'");
        $stmt->execute();
        $val = $stmt->fetchColumn();
        return $val === '1' || $val === 1 || $val === true;
    }
    
    /**
     * Reset statistics for all keys.
     */
    public static function resetAllDailyStats($db) {
        $today = date('Y-m-d');
        $currentMinute = date('Y-m-d H:i:00');
        $stmt = $db->prepare("
            UPDATE ai_gemini_keys 
            SET rpm_usage = 0, 
                tpm_usage = 0, 
                rpd_usage = 0, 
                total_requests_today = 0,
                rpm_window_start = ?,
                tpm_window_start = ?,
                rpd_window_start = ?,
                status = 'active'
        ");
        return $stmt->execute([$currentMinute, $currentMinute, $today]);
    }
    
    /**
     * Mask API keys for security.
     * Example: AIzaSyD...8Kf -> AIza***8Kf
     */
    public static function maskKey($key) {
        if (empty($key)) return '';
        $len = strlen($key);
        if ($len <= 8) {
            return str_repeat('*', $len);
        }
        return substr($key, 0, 4) . '***' . substr($key, -3);
    }
}
