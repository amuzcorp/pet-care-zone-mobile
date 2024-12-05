import '../constants/api_urls.dart';

const List<String> historyPeriods = ['day', 'week', 'month'];

class RoutesWeb {
  final String path;
  final String url;

  RoutesWeb(this.path, this.url);
}

final List<RoutesWeb> routesWeb = [
  RoutesWeb('/petcarezone', ApiUrls.webViewUrl),
  RoutesWeb('/ai_health', ApiUrls.aiHealthUrl),
  RoutesWeb('/timeline', ApiUrls.timelineUrl),
  RoutesWeb('/live_cam', ApiUrls.liveCamUrl),
  RoutesWeb('/ai_diagnosis_dislocation', ApiUrls.aiDislocation),
  RoutesWeb('/ai_diagnosis_teeth', ApiUrls.aiTeeth),
  RoutesWeb('/ai_diagnosis_obesity', ApiUrls.aiObesity),
  ...generateHistoryRoutes('/temp_history', ApiUrls.tempHistory),
  ...generateHistoryRoutes('/weight_history', ApiUrls.weightHistory),
  ...generateHistoryRoutes('/heart_rate_history', ApiUrls.heartHistory),
  ...generateHistoryRoutes('/respiratory_rate_history', ApiUrls.respHistory),
  ...generateHistoryRoutes('/stay_time_history', ApiUrls.stayedTimeHistory),
  ...generateHistoryRoutes('/stayed_time_history', ApiUrls.stayedTimeHistory),
];

// Function to dynamically generate history routes for each period
List<RoutesWeb> generateHistoryRoutes(String basePath, String baseUrl) {
  return historyPeriods.map((period) {
    return RoutesWeb('${basePath}_$period', baseUrl);
  }).toList();
}
