import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';
import '../model/GlobalVarClass.dart';

class Frg3ParaPage extends StatefulWidget {
  @override
  _Frg3ParaPageState createState() => _Frg3ParaPageState();
}

class _Frg3ParaPageState extends State<Frg3ParaPage> {
  Timer? timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(Duration(milliseconds: 250), (_) {
      if (GlobalPara.instance.btIsConnected) setState(() {});
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  double parseDoubleSafe(String? str, {double defaultValue = 0}) {
    if (str == null) return defaultValue;
    return double.tryParse(str.replaceAll(RegExp(r"[ %mv]"), "")) ??
        defaultValue;
  }

  int parseIntSafe(String? str, {int defaultValue = 0}) {
    if (str == null) return defaultValue;
    return int.tryParse(str) ?? defaultValue;
  }

  Widget _packCard({
    required int index,
    required double power,
    required double temp,
    required int status,
  }) {
    final isFault = (status != 0 && status != 12288);

    // 🔥 溫度語意
    Color tempColor;
    if (temp >= 55) {
      tempColor = Colors.red;
    } else if (temp >= 45) {
      tempColor = Colors.orange;
    } else {
      tempColor = Colors.green;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(blurRadius: 8, color: Colors.black12, offset: Offset(0, 3)),
        ],
        border: Border.all(
          color: isFault ? Colors.red.shade300 : Colors.grey.shade200,
          width: isFault ? 1.6 : 1,
        ),
      ),
      child: Row(
        children: [
          // 🔋 左側 icon
          Transform.rotate(
            angle: -pi / 2,
            child: Icon(
              Icons.battery_full,
              color: isFault ? Colors.red : Colors.green,
              size: 34,
            ),
          ),

          const SizedBox(width: 14),

          // 📊 中間資訊
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Pack $index",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${power.toStringAsFixed(2)} kWh",
                  style: const TextStyle(fontSize: 14, color: Colors.blueGrey),
                ),
              ],
            ),
          ),

          // 🌡️ 溫度 badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: tempColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${temp.toStringAsFixed(1)}°C",
              style: TextStyle(color: tempColor, fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(width: 10),

          // 🔥 狀態 badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isFault ? Colors.red : Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isFault ? "FAULT" : "OK",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bcu = GlobalPara.instance.BcuInfo; // ← 這裡不用 cast

    return Scaffold(
      //appBar: AppBar(title: Text("Para Page")),
      body: ListView.separated(
        padding: EdgeInsets.all(10),
        itemCount: 7,
        separatorBuilder: (_, __) => Divider(),
        itemBuilder: (context, i) {
          double cap =
              parseDoubleSafe(bcu['remainingCapB${i + 1}']) / 100; // Ah
          double vol =
              parseDoubleSafe(bcu['batteryVoltage${i + 1}']) / 1000; // V
          double power = cap * vol / 1000; // KWh
          double temp = parseDoubleSafe(bcu['maxTemperature${i + 1}']); // °C
          int status = parseIntSafe(bcu['loStatus${i + 1}']);

          return _packCard(
            index: i + 1,
            power: power,
            temp: temp,
            status: status,
          );
        },
      ),
    );
  }
}
