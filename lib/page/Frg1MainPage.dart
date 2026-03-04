import 'package:flutter/material.dart';
import 'dart:async';
import '../model/GlobalVarClass.dart';

class Frg1MainPage extends StatefulWidget {
  @override
  _Frg1MainPageState createState() => _Frg1MainPageState();
}

class _Frg1MainPageState extends State<Frg1MainPage> {
  bool swBatCap = false; // 切換 KWh / SOC
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(Duration(milliseconds: 250), (_) {
      setState(() {}); // 無論藍芽或電池狀態都刷新
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  double calculateKWh() {
    final bcu = GlobalPara.instance.BcuInfo;

    double totalAh = 0;
    for (int i = 1; i <= 7; i++) {
      totalAh += (double.tryParse(bcu['remainingCapB$i']) ?? 0) / 100;
    }

    final voltage = (double.tryParse(bcu['maxBatteryVoltage']) ?? 0);
    return totalAh * voltage / 1000.0;
  }

  double getMaxTemperature() {
    final bcu = GlobalPara.instance.BcuInfo;
    double maxTemp = 0;
    for (int i = 1; i <= 7; i++) {
      double temp = double.tryParse(bcu['maxTemperature$i']) ?? 0;
      if (temp > maxTemp) maxTemp = temp;
    }
    return maxTemp;
  }

  String getBatteryStatus() {
    bool isNormal = GlobalPara.instance.PackInfoMap.values.every((pack) {
      int lo = int.tryParse(pack.loStatus) ?? 0;
      int hi = int.tryParse(pack.hiStatus) ?? 0;
      return (lo == 0 || lo == 12288) && (hi == 0 || hi == 12288);
    });

    double current =
        double.tryParse(GlobalPara.instance.BcuInfo.batteryCurrent) ?? 0;

    return (isNormal ? "正常" : "異常") + (current <= 0 ? " [放電]" : " [充電]");
  }

  // 小工具函數：資訊欄位
  Widget buildInfoColumn(String title, String value) {
    return Column(
      children: [
        Text(title, style: TextStyle(fontSize: 16, color: Colors.grey[700])),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    double batCap = swBatCap
        ? double.tryParse(GlobalPara.instance.BcuInfo.batterySOC) ?? 0
        : calculateKWh();

    String status = getBatteryStatus();
    bool isError = status.contains("異常");
    bool isBtConnected = GlobalPara.instance.btIsConnected;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // 狀態卡片
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  color: isError ? Colors.red[50] : Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 藍芽狀態
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.bluetooth,
                              color: isBtConnected ? Colors.blue : Colors.grey,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              isBtConnected ? "藍芽已連線" : "藍芽未連線",
                              style: TextStyle(
                                fontSize: 16,
                                color: isBtConnected
                                    ? Colors.blue
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Icon(
                          Icons.battery_full,
                          size: 60,
                          color: isError ? Colors.red : Colors.blue,
                        ),
                        SizedBox(height: 10),
                        Text(
                          "狀態: $status",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isError ? Colors.red : Colors.blue,
                          ),
                        ),
                        Divider(
                          height: 30,
                          thickness: 1,
                          color: Colors.grey[300],
                        ),

                        // 上排資訊：容量 / 電壓 / 電流
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            buildInfoColumn(
                              "容量",
                              "${batCap.toStringAsFixed(2)} ${swBatCap ? '%' : 'KWh'}",
                            ),
                            buildInfoColumn(
                              "電壓",
                              "${GlobalPara.instance.BcuInfo.maxBatteryVoltage} V",
                            ),
                            buildInfoColumn(
                              "電流",
                              "${GlobalPara.instance.BcuInfo.batteryCurrent} A",
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // 下排資訊：溫度
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            buildInfoColumn(
                              "溫度",
                              "${getMaxTemperature().toStringAsFixed(1)} °C",
                            ),
                          ],
                        ),

                        SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => setState(() => swBatCap = !swBatCap),
                          icon: Icon(Icons.swap_horiz),
                          label: Text("切換容量單位"),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
