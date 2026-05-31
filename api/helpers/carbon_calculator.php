<?php
/**
 * Carbon Footprint Calculator Helper
 * LovingHarmony API
 * 
 * Logic: Calculates carbon savings based on emission factors of logged food items.
 */

class CarbonCalculator {
    private PDO $db;

    /**
     * Constructor receives PDO database connection
     */
    public function __construct(PDO $db) {
        $this->db = $db;
    }

    /**
     * Calculate carbon saved for a meal and add it to user's total carbon saved.
     * 
     * @param int $userId
     * @param array $foodItems - Array of arrays, e.g. [['name' => 'Tempe', 'weight' => 0.15]]
     * @return float - Carbon saved this meal (kg CO2e)
     */
    public function calculateAndSaveCarbon(int $userId, array $foodItems): float {
        $totalSavedThisMeal = 0.00;

        // Prepared statement for selecting factor
        $stmt = $this->db->prepare(
            "SELECT emission_factor, category FROM emission_factors WHERE food_name = ?"
        );

        // Standard prepared statement for keyword lookup as a fallback
        $fallbackStmt = $this->db->prepare(
            "SELECT emission_factor, category FROM emission_factors WHERE ? LIKE CONCAT('%', food_name, '%') LIMIT 1"
        );

        foreach ($foodItems as $item) {
            $name = trim($item['name'] ?? $item['food_name'] ?? $item['nama'] ?? '');
            $weight = (float)($item['weight'] ?? $item['weight_kg'] ?? 0.15); // Default 150g serving

            if (empty($name)) {
                continue;
            }

            // 1. Direct match query
            $stmt->execute([$name]);
            $row = $stmt->fetch(PDO::FETCH_ASSOC);

            // 2. Fallback partial match if direct match fails
            if (!$row) {
                $fallbackStmt->execute([$name]);
                $row = $fallbackStmt->fetch(PDO::FETCH_ASSOC);
            }

            if ($row) {
                $category = $row['category'];
                $emissionFactor = (float)$row['emission_factor'];

                // 2. Calculate Actual Emission: (Weight * emission_factor)
                $actualEmission = $weight * $emissionFactor;

                // 3. Calculate Savings:
                // Reward all plant-based categories by replacing Beef (Daging Sapi) baseline (60.00 kg CO2e/kg)
                $plantBasedCategories = ['Protein Nabati', 'Sayuran', 'Karbohidrat', 'Buah'];
                if (in_array($category, $plantBasedCategories)) {
                    $saving = ($weight * 60.00) - $actualEmission;
                    $totalSavedThisMeal += max(0.00, $saving);
                }
            } else {
                // Hardcoded fallback for common keywords if not matched in DB
                $lowerName = strtolower($name);
                if (strpos($lowerName, 'tahu') !== false) {
                    // Replaces Beef (60.00) with Tahu (2.00)
                    $totalSavedThisMeal += max(0.00, ($weight * 60.00) - ($weight * 2.00));
                } elseif (strpos($lowerName, 'tempe') !== false) {
                    // Replaces Beef (60.00) with Tempe (1.50)
                    $totalSavedThisMeal += max(0.00, ($weight * 60.00) - ($weight * 1.50));
                } elseif (strpos($lowerName, 'sayur') !== false || strpos($lowerName, 'bayam') !== false || strpos($lowerName, 'brokoli') !== false || strpos($lowerName, 'kangkung') !== false || strpos($lowerName, 'nasi') !== false || strpos($lowerName, 'pisang') !== false) {
                    // Replaces Beef (60.00) with Sayuran/Carb baseline (1.00)
                    $totalSavedThisMeal += max(0.00, ($weight * 60.00) - ($weight * 1.00));
                }
            }
        }

        // 5. Update user's total carbon saved if saving > 0
        if ($totalSavedThisMeal > 0) {
            $updateStmt = $this->db->prepare(
                "UPDATE users SET total_carbon_saved = total_carbon_saved + ? WHERE id = ?"
            );
            $updateStmt->execute([$totalSavedThisMeal, $userId]);
        }

        // 6. Return total savings from this session
        return round($totalSavedThisMeal, 2);
    }
}
