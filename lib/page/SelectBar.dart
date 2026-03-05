import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../ble/BleService.dart';
import '../model/GlobalVarClass.dart';
import '../model/DataParser.dart';
import '../utils/SharedUtil.dart';
import 'MainPage.dart';
import 'DetailPage.dart';
import 'ParaPage.dart';

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

  /// 顯示解析失敗歷史 Dialog
  Future<void> showFailHistory() async {
    final keys = ["pack", "bcu", "unknown"];
    Map<String, List<String>> history = {};
    for (var key in keys) {
      List<Map<String, String>> rawList = await SharedUtil.getFailHistory(key);
      history[key] = rawList
          .map((e) => "${e['time'] ?? ''} - ${e['reason'] ?? ''}")
          .toList();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          "解析失敗歷史",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: Stack(
            children: [
              // 歷史紀錄
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: history.values.every((list) => list.isEmpty)
                        ? const Center(child: Text("暫無失敗紀錄"))
                        : ListView.separated(
                            itemCount: keys.length,
                            separatorBuilder: (_, __) => const Divider(),
                            itemBuilder: (context, index) {
                              final key = keys[index];
                              final list = history[key]!;
                              if (list.isEmpty) return const SizedBox();
                              return Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blueGrey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      key.toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    ...list.map(
                                      (e) => Text(
                                        e,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 24), // 避開 Maker
                ],
              ),

              // Maker 名稱右下角
              Positioned(
                right: 0,
                bottom: 0,
                child: Text(
                  "M.K: Maverick Tu",
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[600],
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Row(
            children: [
              TextButton(
                onPressed: () async {
                  await Future.wait(
                    keys.map((key) => SharedUtil.clearFailHistory(key)),
                  );
                  Navigator.pop(context);
                  setState(() {});
                },
                child: const Text("清除全部"),
              ),
              TextButton(
                onPressed: () {
                  final allText = history.values.expand((e) => e).join("\n");
                  Clipboard.setData(ClipboardData(text: allText));
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text("已複製到剪貼簿")));
                },
                child: const Text("全部複製"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("關閉"),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void handleBleButton() {
    if (GlobalPara.instance.btIsConnected) {
      // 已連線 → 詢問是否斷線
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("BLE 已連線"),
          content: const Text("是否斷開目前連線？"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("取消"),
            ),
            TextButton(
              onPressed: () async {
                await BleService.instance.disconnect();
                GlobalPara.instance.btIsConnected = false;
                Navigator.pop(context);
                setState(() {}); // 更新按鈕顏色
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("已斷開連線")));
              },
              child: const Text("斷開連線"),
            ),
          ],
        ),
      );
    } else {
      // 未連線 → 掃描
      showScanDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("GUS F-Lift"),
        actions: [
          IconButton(
            icon: Icon(
              GlobalPara.instance.btIsConnected
                  ? Icons.bluetooth_connected
                  : (isScanning
                        ? Icons.bluetooth_searching
                        : Icons.bluetooth_disabled),
            ),
            color: GlobalPara.instance.btIsConnected
                ? Colors.green
                : (isScanning ? Colors.orange : Colors.grey),
            onPressed: handleBleButton,
          ),
          IconButton(
            icon: const Icon(Icons.error_outline),
            tooltip: "解析失敗歷史",
            onPressed: showFailHistory,
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
