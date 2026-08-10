import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/services/api_client.dart';

final systemStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final response = await ApiClient().getSystemStats();
  if (response.statusCode == 200) {
    return response.data['data'] as Map<String, dynamic>;
  } else {
    throw Exception(response.data['message'] ?? 'Failed to load system stats');
  }
});

final leaderboardProvider = FutureProvider<List<dynamic>>((ref) async {
  final response = await ApiClient().getLeaderboard();
  if (response.statusCode == 200) {
    return response.data['data'] as List<dynamic>;
  } else {
    throw Exception(response.data['message'] ?? 'Failed to load leaderboard');
  }
});

final teamActivityProvider = FutureProvider<List<dynamic>>((ref) async {
  final response = await ApiClient().getTeamActivity();
  if (response.statusCode == 200) {
    return response.data['data'] as List<dynamic>;
  } else {
    throw Exception(response.data['message'] ?? 'Failed to load team activity');
  }
});
