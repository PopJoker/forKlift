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
          double power = cap * vol /1000; // KWh
          double temp = parseDoubleSafe(bcu['maxTemperature${i + 1}']); // °C
          int status = parseIntSafe(bcu['loStatus${i + 1}']);

          return ListTile(
            leading: Transform.rotate(
              angle: -pi / 2, // 將圖標橫躺
              child: Icon(
                Icons.battery_full,
                color: (status != 0 && status != 12288)
                    ? Colors.red
                    : Colors.green,
                size: 30,
              ),
            ),
            title: Text("Pack ${i + 1}"),
            subtitle: Text(
              "Power: ${power.toStringAsFixed(2)} KWh\nTemp: ${temp.toStringAsFixed(1)}°C",
            ),
          );
        },
      ),
    );
  }
}