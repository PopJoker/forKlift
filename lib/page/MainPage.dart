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

  Widget _modernInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            color: Colors.black12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: children,
      ),
    );
  }

  Widget _infoItem(IconData icon, String title, String value) {
    return Column(
      children: [
        Icon(icon, size: 22, color: Colors.blueGrey),
        const SizedBox(height: 6),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

    final mainColor = isError ? Colors.red : Colors.blue;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ==============================
                // 主狀態卡（強化版）
                // ==============================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isError
                          ? [Colors.red.shade400, Colors.red.shade600]
                          : [Colors.blue.shade400, Colors.blue.shade600],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 12,
                        color: Colors.black12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // 🔹 藍芽狀態（小）
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bluetooth,
                            color: Colors.white.withOpacity(0.9),
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isBtConnected
                                ? "Bluetooth Connected"
                                : "Bluetooth Disconnected",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // 🔥 主容量（超大）
                      Text(
                        batCap.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),

                      Text(
                        swBatCap ? "%" : "kWh",
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 🔹 狀態
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ==============================
                // 資訊卡片
                // ==============================
                _modernInfoCard([
                  _infoItem(
                    Icons.flash_on,
                    "Voltage",
                    "${GlobalPara.instance.BcuInfo.maxBatteryVoltage} V",
                  ),
                  _infoItem(
                    Icons.electric_bolt,
                    "Current",
                    "${GlobalPara.instance.BcuInfo.batteryCurrent} A",
                  ),
                  _infoItem(
                    Icons.thermostat,
                    "Temp",
                    "${getMaxTemperature().toStringAsFixed(1)} °C",
                  ),
                ]),

                const SizedBox(height: 18),

                // ==============================
                // 切換按鈕
                // ==============================
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => swBatCap = !swBatCap),
                    icon: const Icon(Icons.swap_horiz),
                    label: const Text("切換容量單位"),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
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
