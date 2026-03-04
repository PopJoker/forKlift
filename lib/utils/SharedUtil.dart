import 'package:shared_preferences/shared_preferences.dart';

class SharedUtil {
  /// 增加失敗次數，並記錄每次失敗原因
  static Future<void> addFailRecord(String key, String reason) async {
    final prefs = await SharedPreferences.getInstance();

    // 取得現有的失敗列表
    List<String> failList = prefs.getStringList("${key}_fail_list") ?? [];

    // 加入新記錄，格式: timestamp|reason
    final now = DateTime.now().toIso8601String();
    failList.add("$now|$reason");

    // 限制歷史長度，例如保留最近 100 筆
    if (failList.length > 100) {
      failList = failList.sublist(failList.length - 100);
    }

    // 儲存
    await prefs.setStringList("${key}_fail_list", failList);

    // 更新失敗次數
    int count = prefs.getInt("${key}_fail_count") ?? 0;
    await prefs.setInt("${key}_fail_count", count + 1);
  }

  /// 取得失敗次數
  static Future<int> getFailCount(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt("${key}_fail_count") ?? 0;
  }

  /// 取得所有失敗歷史
  /// 回傳 List<Map<String, String>>，每筆包含 timestamp 與 reason
  static Future<List<Map<String, String>>> getFailHistory(String key) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> failList = prefs.getStringList("${key}_fail_list") ?? [];
    return failList.map((e) {
      final split = e.split('|');
      return {
        'timestamp': split[0],
        'reason': split.length > 1 ? split.sublist(1).join('|') : '',
      };
    }).toList();
  }

  /// 清除失敗記錄
  static Future<void> clearFailHistory(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("${key}_fail_list");
    await prefs.setInt("${key}_fail_count", 0);
  }
}