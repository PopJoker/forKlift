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
    timer = Timer.periodic(const Duration(milliseconds: 250), (_) {
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
    var pack = GlobalPara.instance.PackInfoMap[selectedPack] ?? PackSetInfo();

    // fallback
    pack.loFlags = pack.loFlags.isNotEmpty
        ? pack.loFlags
        : {
            'LoOC': false,
            'LoDSG': false,
            'LoCHG': false,
            'LoUTD': false,
            'LoUTC': false,
            'LoOTD': false,
            'LoOTC': false,
            'LoASCDL': false,
            'LoASCD': false,
            'LoAOLDL': false,
            'LoAOLD': false,
            'LoOCD': false,
            'LoOCC': false,
            'LoCOV': false,
            'LoCUV': false,
          };

    pack.hiFlags = pack.hiFlags.isNotEmpty
        ? pack.hiFlags
        : {
            'HiOC': false,
            'HiUTD': false,
            'HiUTC': false,
            'HiOTD': false,
            'HiOTC': false,
            'HiCOV': false,
            'HiCUV': false,
          };

    pack.cellVoltage = pack.cellVoltage.isNotEmpty
        ? pack.cellVoltage
        : List.generate(22, (_) => "0");

    return Scaffold(
      // appBar: AppBar(
      //   title: const Text("Pack Detail"),
      //   elevation: 0,
      // ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPackSelector(),
            const SizedBox(height: 12),

            _buildInfoCard(pack),

            const SizedBox(height: 16),
            _buildCellGrid(pack),

            const SizedBox(height: 16),
            _buildFlagSection("Lo Flags", pack.loFlags),

            const SizedBox(height: 12),
            _buildFlagSection("Hi Flags", pack.hiFlags),
          ],
        ),
      ),
    );
  }

  // =============================
  // Pack selector
  // =============================
  Widget _buildPackSelector() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: selectedPack,
            isExpanded: true,
            items: List.generate(
              7,
              (i) => DropdownMenuItem(
                value: "${i + 1}",
                child: Text("Pack ${i + 1}"),
              ),
            ),
            onChanged: (v) => setState(() => selectedPack = v!),
          ),
        ),
      ),
    );
  }

  // =============================
  // Info card
  // =============================
  Widget _buildInfoCard(PackSetInfo pack) {
    Widget row(String title, String value) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            row("Lo Voltage", pack.loVoltage.toString()),
            row("Hi Voltage", pack.hiVoltage.toString()),
            row("Current", "${pack.current} A"),
            row("SOC", pack.soc.toString()),
            row("Lo Status", pack.loStatus.toString()),
            row("Hi Status", pack.hiStatus.toString()),
            row("Firmware", pack.firmware.toString()),
          ],
        ),
      ),
    );
  }

  // =============================
  // Cell grid
  // =============================
  Widget _buildCellGrid(PackSetInfo pack) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Cell Voltages",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pack.cellVoltage.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 6,
                crossAxisSpacing: 6,
                childAspectRatio: 1.6,
              ),
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blueGrey.shade100),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Cell${index + 1}",
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        pack.cellVoltage[index],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // =============================
  // Flag section
  // =============================
  Widget _buildFlagSection(String title, Map<String, bool> flags) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: flags.entries.map((e) {
                final val = e.value;

                final bgColor = val ? Colors.green : Colors.grey.shade400;

                final textColor = val ? Colors.white : Colors.black87;

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    e.key,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 11,
                      fontWeight: val ? FontWeight.bold : FontWeight.normal,
                    ),
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
