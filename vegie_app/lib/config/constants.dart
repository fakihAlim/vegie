class Constants {
  // API Configuration
  static String baseUrl = 'http://192.168.1.10/Vegie/api';
  static const String localUrl = 'http://192.168.1.10/Vegie/api';
  static const String onlineUrl = 'https://yodi.my.id/vegie/api';
  static const String endpointLogin = '/auth/login';
  static const String endpointRegister = '/auth/register';
  static const String endpointProfile = '/auth/profile';
  static const String endpointFcmToken = '/auth/fcm-token';

  static const String endpointFoodLogs = '/food-logs';
  static const String endpointFoodLogsSync = '/food-logs/sync';
  static const String endpointStreak = '/food-logs/streak';

  static const String endpointNews = '/news';
  static const String endpointRecipes = '/recipes';
  static const String endpointGroups = '/groups';
  static const String endpointNotifications = '/notifications';
  static const String endpointQuoteToday = '/quotes/today';
  static const String endpointActivityLogs = '/activity-logs';
  static const String endpointDailyQuiz = '/quizzes/daily';
  static const String endpointQuizzes = '/quizzes';

  // Shared Preferences Keys
  static const String keyToken = 'auth_token';
  static const String keyUser = 'auth_user';
  static const String keyOnboardingCompleted = 'onboarding_completed';
  static const String endpointOnboarding = '/auth/onboarding';
}
