import '../constants/api_urls.dart';

const List<String> historyPeriods = ['day', 'week', 'month'];

class RoutesWeb {
  final String path;
  final String url;

  RoutesWeb(this.path, this.url);
}

final List<RoutesWeb> routesWeb = [
  RoutesWeb('/main', ApiUrls.webViewUrl),
  RoutesWeb('/ai_health', ApiUrls.aiHealthUrl),
  ...generateHistoryRoutes('/temp_history', ApiUrls.tempHistory),
  ...generateHistoryRoutes('/weight_history', ApiUrls.weightHistory),
  ...generateHistoryRoutes('/heart_history', ApiUrls.heartHistory),
  ...generateHistoryRoutes('/resp_history', ApiUrls.respHistory),
  ...generateHistoryRoutes('/stayed_time_history', ApiUrls.stayedTimeHistory),
];

// Function to dynamically generate history routes for each period
List<RoutesWeb> generateHistoryRoutes(String basePath, String baseUrl) {
  return historyPeriods.map((period) {
    return RoutesWeb('${basePath}_$period', baseUrl);
  }).toList();
}
