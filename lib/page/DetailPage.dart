import 'package:flutter/material.dart';
import 'dart:async';
import '../model/GlobalVarClass.dart';
import '../model/PackSetInfo.dart';

class Frg2DetailPage extends StatefulWidget {
  @override
  _Frg2DetailPageState createState() => _Frg2DetailPageState();
}

class _Frg2DetailPageState extends State<Frg2DetailPage> {
  String selectedPack = "1";
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

  @override
  Widget build(BuildContext context) {
    // 安全取 pack，避免 null
    var pack = GlobalPara.instance.PackInfoMap[selectedPack] ?? PackSetInfo();

    // 確保 flags 是 Map
    pack.loFlags = pack.loFlags.isNotEmpty ? pack.loFlags : {
      'LoOC': false,'LoDSG': false,'LoCHG': false,'LoUTD': false,'LoUTC': false,
      'LoOTD': false,'LoOTC': false,'LoASCDL': false,'LoASCD': false,'LoAOLDL': false,
      'LoAOLD': false,'LoOCD': false,'LoOCC': false,'LoCOV': false,'LoCUV': false,
    };
    pack.hiFlags = pack.hiFlags.isNotEmpty ? pack.hiFlags : {
      'HiOC': false,'HiUTD': false,'HiUTC': false,'HiOTD': false,'HiOTC': false,
      'HiCOV': false,'HiCUV': false,
    };

    // 確保 cellVoltage 初始化
    pack.cellVoltage = pack.cellVoltage.isNotEmpty
        ? pack.cellVoltage
        : List.generate(22, (_) => "0");

    return Scaffold(
      //appBar: AppBar(title: Text("Detail Page")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 選 Pack
            DropdownButton<String>(
              value: selectedPack,
              items: List.generate(
                7,
                (i) => DropdownMenuItem(
                  child: Text("Pack ${i + 1}"),
                  value: "${i + 1}",
                ),
              ),
              onChanged: (v) => setState(() => selectedPack = v!),
            ),
            SizedBox(height: 10),
            // 基本數據
            Text("LoVoltage: ${pack.loVoltage}"),
            Text("HiVoltage: ${pack.hiVoltage}"),
            Text("Current: ${pack.current} A"),
            Text("SOC: ${pack.soc}"),
            Text("LoStatus: ${pack.loStatus}"),
            Text("hiStatus: ${pack.hiStatus}"),
            Text("Firmware: ${pack.firmware}"),
            SizedBox(height: 20),

            // Cell Voltages
            Text("Cell Voltages"),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: pack.cellVoltage.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
                childAspectRatio: 3,
              ),
              itemBuilder: (context, index) {
                return Container(
                  padding: EdgeInsets.all(4),
                  color: Colors.grey[200],
                  child: Center(
                    child: Text(
                      pack.cellVoltage[index],
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 20),

            // Lo Flags
            Text("Lo Flags"),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: pack.loFlags.entries.map((e) {
                bool val = e.value;
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: val ? Colors.red : Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    e.key,
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 10),

            // Hi Flags
            Text("Hi Flags"),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: pack.hiFlags.entries.map((e) {
                bool val = e.value;
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: val ? Colors.red : Colors.green,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    e.key,
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}