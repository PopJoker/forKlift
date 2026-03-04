class BcuInfoData {
  // --- Capacities ---
  final Map<String, String> _remainingCap = {};
  // --- Voltages ---
  final Map<String, String> _batteryVoltage = {};
  // --- Temperatures ---
  final Map<String, String> _maxTemperature = {};
  // --- Status ---
  final Map<String, String> _loStatus = {};

  // --- Summary ---
  String maxBatteryVoltage = '';
  String batteryCurrent = '';
  String batterySOC = '';

  // Constructor: 初始化 1~7 pack
  BcuInfoData() {
    for (int i = 1; i <= 7; i++) {
      _remainingCap['B$i'] = '';
      _batteryVoltage['$i'] = '';
      _maxTemperature['$i'] = '';
      _loStatus['$i'] = '';
    }
  }

  // Map-like getter
  String operator [](String key) {
    if (key.startsWith('remainingCapB')) {
      return _remainingCap[key.substring(12)] ?? '0';
    } else if (key.startsWith('batteryVoltage')) {
      return _batteryVoltage[key.substring(14)] ?? '0';
    } else if (key.startsWith('maxTemperature')) {
      return _maxTemperature[key.substring(14)] ?? '0';
    } else if (key.startsWith('loStatus')) {
      return _loStatus[key.substring(8)] ?? '0';
    } else if (key == 'maxBatteryVoltage') return maxBatteryVoltage;
    else if (key == 'batteryCurrent') return batteryCurrent;
    else if (key == 'batterySOC') return batterySOC;

    return '0';
  }

  // Map-like setter，方便更新資料
  void operator []=(String key, String value) {
    if (key.startsWith('remainingCapB')) {
      _remainingCap[key.substring(12)] = value;
    } else if (key.startsWith('batteryVoltage')) {
      _batteryVoltage[key.substring(14)] = value;
    } else if (key.startsWith('maxTemperature')) {
      _maxTemperature[key.substring(14)] = value;
    } else if (key.startsWith('loStatus')) {
      _loStatus[key.substring(8)] = value;
    } else if (key == 'maxBatteryVoltage') maxBatteryVoltage = value;
    else if (key == 'batteryCurrent') batteryCurrent = value;
    else if (key == 'batterySOC') batterySOC = value;
  }
}