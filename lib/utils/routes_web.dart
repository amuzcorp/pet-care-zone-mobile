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
  RoutesWeb('/temp_history_day', ApiUrls.tempHistoryDay),
  RoutesWeb('/temp_history_week', ApiUrls.tempHistoryDay),
];
