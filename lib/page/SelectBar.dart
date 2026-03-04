import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../ble/BleService.dart';
import '../model/GlobalVarClass.dart';
import '../model/DataParser.dart';
import 'Frg1MainPage.dart';
import 'Frg2DetailPage.dart';
import 'Frg3ParaPage.dart';

class SelectBarPage extends StatefulWidget {
  @override
  _SelectBarPageState createState() => _SelectBarPageState();
}

class _SelectBarPageState extends State<SelectBarPage> {
  int selectedIndex = 0;
  final List<String> tabs = ["Main", "Detail", "Para"];
  StreamSubscription? _bleSub;
  StreamSubscription? _connSub;

  List<BluetoothDevice> devices = [];
  bool isScanning = false;

  @override
  void initState() {
    super.initState();

    // 訂閱 BLE 資料流
    _bleSub = BleService.instance.dataStream.listen((data) {
      final rcvStr = String.fromCharCodes(data);
      DataParser.parseAndUpdateGlobal(rcvStr);
      print("rcvStr: $rcvStr");
      if (mounted) setState(() {});
    });

    // 訂閱連線/斷線事件
    _connSub = BleService.instance.connectionStream.listen((isConnected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isConnected ? "BLE 已連線" : "BLE 已斷線")),
        );
        GlobalPara.instance.btIsConnected = isConnected;
      }
    });
  }

  @override
  void dispose() {
    _bleSub?.cancel();
    _connSub?.cancel();
    super.dispose();
  }

  Future<void> connectDevice(BluetoothDevice device) async {
    try {
      await BleService.instance.connect(device);
    } catch (e) {
      GlobalPara.instance.btIsConnected = false;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("連線失敗: $e")));
    }
  }

  void showScanDialog() {
    devices.clear();
    isScanning = true;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) {
          BleService.instance.startScan((r) {
            if (!devices.any((d) => d.id == r.device.id)) {
              setStateDialog(() {
                devices.add(r.device);
              });
            }
          });

          Future.delayed(const Duration(seconds: 10), () async {
            await BleService.instance.stopScan();
            if (mounted) setStateDialog(() => isScanning = false);
          });

          return AlertDialog(
            title: const Text("掃描 BLE 裝置"),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: devices.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: devices.length,
                      itemBuilder: (_, i) {
                        final device = devices[i];
                        return ListTile(
                          title: Text(
                            device.name.isEmpty ? "未知裝置" : device.name,
                          ),
                          subtitle: Text(device.id.id),
                          onTap: () async {
                            Navigator.pop(context);
                            await connectDevice(device);
                          },
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  await BleService.instance.stopScan();
                  Navigator.pop(context);
                },
                child: const Text("關閉"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("GUS BMS"),
        actions: [
          IconButton(
            icon: Icon(
              // 根據狀態改 Icon
              GlobalPara.instance.btIsConnected
                  ? Icons
                        .bluetooth_connected // 已連線
                  : (isScanning
                        ? Icons.bluetooth_searching
                        : Icons.bluetooth_disabled), // 掃描中 / 未連線
            ),
            color: GlobalPara.instance.btIsConnected
                ? Colors
                      .green // 已連線綠色
                : (isScanning ? Colors.orange : Colors.grey), // 掃描中橘色 / 未連線灰色
            onPressed: showScanDialog,
          ),
        ],
      ),
      body: IndexedStack(
        index: selectedIndex,
        children: [Frg1MainPage(), Frg2DetailPage(), Frg3ParaPage()],
      ),
      bottomNavigationBar: Container(
        color: Colors.grey[200],
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(tabs.length, (i) {
            final isSelected = selectedIndex == i;
            return GestureDetector(
              onTap: () => setState(() => selectedIndex = i),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.blue : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tabs[i],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
