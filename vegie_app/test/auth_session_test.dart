import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:loving_harmony/services/auth_service.dart';
import 'package:loving_harmony/providers/recipe_provider.dart';
import 'package:loving_harmony/config/constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Auth Session Leakage Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({
        Constants.keyToken: 'test_token_123',
        Constants.keyUser: '{"id": 1, "name": "User A"}',
        Constants.keyOnboardingCompleted: true,
        'saved_recipes': ['1', '2'],
        'tried_recipes': ['3'],
        'read_myths': ['10', '11'],
      });
    });

    test('logout() clears token, user data, onboarding, and recipe preferences', () async {
      final authService = AuthService();

      // Verify setup initial values
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(Constants.keyToken), 'test_token_123');
      expect(prefs.getString(Constants.keyUser), '{"id": 1, "name": "User A"}');
      expect(prefs.getBool(Constants.keyOnboardingCompleted), true);
      expect(prefs.getStringList('saved_recipes'), ['1', '2']);
      expect(prefs.getStringList('tried_recipes'), ['3']);
      expect(prefs.getStringList('read_myths'), ['10', '11']);

      // Perform logout
      await authService.logout();

      // Verify all session and preference data are removed
      expect(prefs.containsKey(Constants.keyToken), false);
      expect(prefs.containsKey(Constants.keyUser), false);
      expect(prefs.containsKey(Constants.keyOnboardingCompleted), false);
      expect(prefs.containsKey('saved_recipes'), false);
      expect(prefs.containsKey('tried_recipes'), false);
      expect(prefs.containsKey('read_myths'), false);
    });

    test('RecipeProvider loads from SharedPreferences and clears correctly', () async {
      final recipeProvider = RecipeProvider();
      await recipeProvider.loadSavedAndTriedRecipes();

      // Should automatically load from SharedPreferences in constructor
      expect(recipeProvider.savedRecipeIds, [1, 2]);
      expect(recipeProvider.triedRecipeIds, [3]);

      // Test clearRecipes()
      recipeProvider.clearRecipes();
      expect(recipeProvider.savedRecipeIds, isEmpty);
      expect(recipeProvider.triedRecipeIds, isEmpty);

      // Verify re-loading after modifying SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('saved_recipes', ['4', '5']);
      await prefs.setStringList('tried_recipes', ['6']);

      await recipeProvider.loadSavedAndTriedRecipes();
      expect(recipeProvider.savedRecipeIds, [4, 5]);
      expect(recipeProvider.triedRecipeIds, [6]);
    });
  });
}
