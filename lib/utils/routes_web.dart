import '../constants/api_urls.dart';

class RoutesWeb {
  final String path;
  final String url;

  RoutesWeb(this.path, this.url);
}
final historyPeriod = ['day', 'week', 'month'];
final List<RoutesWeb> routesWeb = [
  RoutesWeb('/main', ApiUrls.webViewUrl),
  RoutesWeb('/ai_health', ApiUrls.aiHealthUrl),
  ...generateHistoryRoutes('/temp_history', ApiUrls.tempHistory),
  ...generateHistoryRoutes('/weight_history', ApiUrls.weightHistory),
  ...generateHistoryRoutes('/heart_history', ApiUrls.heartHistory),
  ...generateHistoryRoutes('/resp_history', ApiUrls.respHistory),
  ...generateHistoryRoutes('/stayed_time_history', ApiUrls.stayedTimeHistory),
];

List<RoutesWeb> generateHistoryRoutes(String basePath, String baseUrl) {
  final periods = ['day', 'week', 'month'];
  return periods
      .map((period) => RoutesWeb('${basePath}_$period', baseUrl))
      .toList();
}
