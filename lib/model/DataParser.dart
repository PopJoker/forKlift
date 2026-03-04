// lib/model/DataParser.dart
import 'BcuInfo.dart';
import 'PackSetInfo.dart';
import 'GlobalVarClass.dart';

class DataParser {
  /// 將 16 位狀態轉成 bool list
  static List<bool> cnvStatus2List(int value) {
    return List.generate(16, (i) => ((value >> i) & 0x1) == 1);
  }

  /// 解析單個 PACK 資料
  static PackSetInfo? parsePack(String rcvStr) {
    try {
      final parts = rcvStr.split(',');
      if (parts.length < 39) return null; // 確保資料完整

      final info = PackSetInfo();
      info.packNum = parts[0].replaceAll('.@', '');
      
      // 只有非空 / 非 0 才更新
      if (parts[1].isNotEmpty && parts[1] != "0") info.loVoltage = "${parts[1]} mv";
      if (parts[2].isNotEmpty && parts[2] != "0") info.hiVoltage = "${parts[2]} mv";
      if ((int.tryParse(parts[3]) ?? 0) != 0) info.current = int.tryParse(parts[3])?.toString() ?? info.current;
      if (parts[4].isNotEmpty && parts[4] != "0") info.soc = "${parts[4]} %";
      if (parts[5].isNotEmpty) info.loStatus = parts[5];
      if (parts[6].isNotEmpty) info.hiStatus = parts[6];

      // --- LoStatus Flags ---
      final keysLo = [
        'LoCUV','LoCOV','LoOCC','LoOCD','LoAOLD','LoAOLDL','LoASCD','LoASCDL',
        'LoOTC','LoOTD','LoUTC','LoUTD','LoCHG','LoDSG','LoOCDL','LoOC',
      ];
      final loBits = cnvStatus2List(int.tryParse(info.loStatus) ?? 0);
      info.loFlags = {
        for (int i = 0; i < keysLo.length; i++)
          keysLo[i]: i < loBits.length ? loBits[i] : false,
      };

      // --- HiStatus Flags (只解析有效 bits) ---
      final hiStatusInt = int.tryParse(info.hiStatus) ?? 0;
      info.hiFlags['HiCUV'] = (hiStatusInt & (1 << 0)) != 0;
      info.hiFlags['HiCOV'] = (hiStatusInt & (1 << 1)) != 0;
      info.hiFlags['HiOTC'] = (hiStatusInt & (1 << 8)) != 0;
      info.hiFlags['HiOTD'] = (hiStatusInt & (1 << 9)) != 0;
      info.hiFlags['HiUTC'] = (hiStatusInt & (1 << 10)) != 0;
      info.hiFlags['HiUTD'] = (hiStatusInt & (1 << 11)) != 0;
      info.hiFlags['HiOC'] = (hiStatusInt & (1 << 15)) != 0;

      // --- 溫度 ---
      for (int i = 7; i <= 12; i++) {
        if (parts[i].isNotEmpty && parts[i] != "0") {
          double temp = (double.tryParse(parts[i]) ?? 0) / 10;
          switch(i) {
            case 7: info.loTs1Temp = temp.toStringAsFixed(1); break;
            case 8: info.loTs2Temp = temp.toStringAsFixed(1); break;
            case 9: info.loTs3Temp = temp.toStringAsFixed(1); break;
            case 10: info.hiTs1Temp = temp.toStringAsFixed(1); break;
            case 11: info.hiTs2Temp = temp.toStringAsFixed(1); break;
            case 12: info.hiTs3Temp = temp.toStringAsFixed(1); break;
          }
        }
      }

      if (parts[13].isNotEmpty) info.firmware = parts[13];

      // --- Cell Voltages ---
      for (int i = 0; i < 22; i++) {
        if (parts[14 + i].isNotEmpty && parts[14 + i] != "0") {
          info.cellVoltage[i] = parts[14 + i];
        }
      }

      // --- 容量 & SoH ---
      if (parts[36].isNotEmpty && parts[36] != "0") info.remainingCapacity = parts[36];
      if (parts[37].isNotEmpty && parts[37] != "0") info.fullChargeCapacity = parts[37];
      if (parts[38].isNotEmpty && parts[38] != "0") info.soh = parts[38];

      // 更新全局 Map
      GlobalPara.instance.PackInfoMap[info.packNum] = info;

      return info;
    } catch (e) {
      print("parsePack error: $e");
      return null;
    }
  }

  static BcuInfoData? parseBcu(String str) {
    try {
      final parts = str.split(',');
      if (parts.length < 39) return null;

      final bcu = GlobalPara.instance.BcuInfo ?? BcuInfoData();

      // --- summary ---
      double tmpVoltage = (double.tryParse(parts[1]) ?? 0) / 1000;
      if (tmpVoltage != 0) bcu.maxBatteryVoltage = tmpVoltage.toStringAsFixed(3);

      double tmpCurrent = (double.tryParse(parts[2]) ?? 0) / 100;
      if (tmpCurrent != 0) bcu.batteryCurrent = tmpCurrent.toStringAsFixed(3);

      if (parts[3].isNotEmpty && parts[3] != "0") bcu.batterySOC = parts[3];

      // --- RemainingCap B1~B7 ---
      for (int i = 1; i <= 7; i++) {
        if (parts[31 + i].isNotEmpty && parts[31 + i] != "0") {
          bcu['remainingCapB$i'] = parts[31 + i];
        }
      }

      // --- BatteryVoltage1~7 ---
      for (int i = 1; i <= 7; i++) {
        if (parts[24 + i].isNotEmpty && parts[24 + i] != "0") {
          bcu['batteryVoltage$i'] = parts[24 + i];
        }
      }

      // --- MaxTemperature1~7 ---
      for (int i = 1; i <= 7; i++) {
        double temp = double.tryParse(parts[3 + i]) ?? 0;
        if (temp != 0) bcu['maxTemperature$i'] = (temp / 10).toStringAsFixed(1);
      }

      // --- LoStatus1~7 ---
      for (int i = 1; i <= 7; i++) {
        if (parts[10 + i].isNotEmpty) {
          bcu['loStatus$i'] = parts[10 + i];
        }
      }

      GlobalPara.instance.BcuInfo = bcu;
      return bcu;
    } catch (e) {
      print("parseBcu error: $e");
      return null;
    }
  }

  /// 自動辨識 BCU / PACK 資料並解析
  static void parseAndUpdateGlobal(String rcvStr) {
    if (rcvStr.startsWith(".@0")) {
      parseBcu(rcvStr);
    } else if (rcvStr.startsWith(".@")) {
      parsePack(rcvStr);
    } else {
      print("Unknown data: $rcvStr");
    }
  }
}