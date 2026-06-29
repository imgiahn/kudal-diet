class ApiEndpoints {
  ApiEndpoints._();

  static const String daily = '/api/v1/daily';
  static const String calendar = '/api/v1/calendar';
  static const String meals = '/api/v1/meals';
  static String deleteMeal(String id) => '/api/v1/meals/$id';
  static String deleteMealItem(String id) => '/api/v1/meal-items/$id';
  static String updateMealItem(String id) => '/api/v1/meal-items/$id';
  static const String weights = '/api/v1/weights';
  static const String exercises = '/api/v1/exercises';
  static const String kudal = '/api/v1/kudal';
  static const String analyzeMealUpload = '/api/v1/ai/analyze-meal-upload';
}
