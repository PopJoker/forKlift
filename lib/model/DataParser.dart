import 'BcuInfo.dart';
import 'PackSetInfo.dart';
import 'GlobalVarClass.dart';
import '../utils/SharedUtil.dart';

class DataParser {
  static List<bool> cnvStatus2List(int value) {
    return List.generate(16, (i) => ((value >> i) & 0x1) == 1);
  }

  /// 解析單個 PACK 資料，並紀錄每個失敗欄位
  static Future<PackSetInfo?> parsePack(String rcvStr) async {
    final info = PackSetInfo();
    try {
      final parts = rcvStr.split(',');
      if (parts.length < 39) {
        await SharedUtil.addFailRecord("pack", "資料長度不足: ${parts.length}");
      }

      info.packNum = parts[0].replaceAll('.@', '');
      if (info.packNum.isEmpty) {
        await SharedUtil.addFailRecord("pack", "packNum 空值");
      }

      // 核心欄位
      if (parts.length > 1 && parts[1] != "0" && parts[1].isNotEmpty) {
        info.loVoltage = "${parts[1]} mv";
      } else {
        await SharedUtil.addFailRecord("pack", "loVoltage 空或 0");
      }

      if (parts.length > 2 && parts[2] != "0" && parts[2].isNotEmpty) {
        info.hiVoltage = "${parts[2]} mv";
      } else {
        await SharedUtil.addFailRecord("pack", "hiVoltage 空或 0");
      }

      if (parts.length > 3 && (int.tryParse(parts[3]) ?? 0) != 0) {
        info.current = int.tryParse(parts[3])?.toString() ?? info.current;
      } else {
        await SharedUtil.addFailRecord("pack", "current 空或 0");
      }

      if (parts.length > 4 && parts[4] != "0" && parts[4].isNotEmpty) {
        info.soc = "${parts[4]} %";
      } else {
        await SharedUtil.addFailRecord("pack", "SOC 空或 0");
      }

      // LoStatus / HiStatus
      info.loStatus = (parts.length > 5) ? parts[5] : "";
      info.hiStatus = (parts.length > 6) ? parts[6] : "";
      if (info.loStatus.isEmpty) await SharedUtil.addFailRecord("pack", "loStatus 空");
      if (info.hiStatus.isEmpty) await SharedUtil.addFailRecord("pack", "hiStatus 空");

      final keysLo = [
        'LoCUV','LoCOV','LoOCC','LoOCD','LoAOLD','LoAOLDL','LoASCD','LoASCDL',
        'LoOTC','LoOTD','LoUTC','LoUTD','LoCHG','LoDSG','LoOCDL','LoOC',
      ];
      final loBits = cnvStatus2List(int.tryParse(info.loStatus) ?? 0);
      info.loFlags = {
        for (int i = 0; i < keysLo.length; i++)
          keysLo[i]: i < loBits.length ? loBits[i] : false,
      };

      final hiStatusInt = int.tryParse(info.hiStatus) ?? 0;
      info.hiFlags['HiCUV'] = (hiStatusInt & (1 << 0)) != 0;
      info.hiFlags['HiCOV'] = (hiStatusInt & (1 << 1)) != 0;
      info.hiFlags['HiOTC'] = (hiStatusInt & (1 << 8)) != 0;
      info.hiFlags['HiOTD'] = (hiStatusInt & (1 << 9)) != 0;
      info.hiFlags['HiUTC'] = (hiStatusInt & (1 << 10)) != 0;
      info.hiFlags['HiUTD'] = (hiStatusInt & (1 << 11)) != 0;
      info.hiFlags['HiOC'] = (hiStatusInt & (1 << 15)) != 0;

      // 溫度欄位
      for (int i = 7; i <= 12; i++) {
        double temp = (parts.length > i && parts[i] != "0" && parts[i].isNotEmpty)
            ? (double.tryParse(parts[i]) ?? 0) / 10
            : -9999;
        switch(i) {
          case 7: info.loTs1Temp = temp != -9999 ? temp.toStringAsFixed(1) : ""; break;
          case 8: info.loTs2Temp = temp != -9999 ? temp.toStringAsFixed(1) : ""; break;
          case 9: info.loTs3Temp = temp != -9999 ? temp.toStringAsFixed(1) : ""; break;
          case 10: info.hiTs1Temp = temp != -9999 ? temp.toStringAsFixed(1) : ""; break;
          case 11: info.hiTs2Temp = temp != -9999 ? temp.toStringAsFixed(1) : ""; break;
          case 12: info.hiTs3Temp = temp != -9999 ? temp.toStringAsFixed(1) : ""; break;
        }
        if (temp == -9999) await SharedUtil.addFailRecord("pack", "temp${i-6} 空或 0");
      }

      // firmware
      if (parts.length > 13 && parts[13].isNotEmpty) info.firmware = parts[13];
      else await SharedUtil.addFailRecord("pack", "firmware 空");

      // cellVoltage
      for (int i = 0; i < 22; i++) {
        if (parts.length > 14 + i && parts[14 + i].isNotEmpty && parts[14 + i] != "0") {
          info.cellVoltage[i] = parts[14 + i];
        } else {
          await SharedUtil.addFailRecord("pack", "cellVoltage[$i] 空或 0");
        }
      }

      // 容量 & SoH
      if (parts.length > 36 && parts[36].isNotEmpty && parts[36] != "0") info.remainingCapacity = parts[36];
      else await SharedUtil.addFailRecord("pack", "remainingCapacity 空或 0");

      if (parts.length > 37 && parts[37].isNotEmpty && parts[37] != "0") info.fullChargeCapacity = parts[37];
      else await SharedUtil.addFailRecord("pack", "fullChargeCapacity 空或 0");

      if (parts.length > 38 && parts[38].isNotEmpty && parts[38] != "0") info.soh = parts[38];
      else await SharedUtil.addFailRecord("pack", "SOH 空或 0");

      // 更新全局 Map
      GlobalPara.instance.PackInfoMap[info.packNum] = info;

      return info;
    } catch (e) {
      await SharedUtil.addFailRecord("pack", e.toString());
      return null;
    }
  }

  /// BCU 解析，每個欄位空或 0 都會紀錄
  static Future<BcuInfoData?> parseBcu(String str) async {
    final bcu = GlobalPara.instance.BcuInfo ?? BcuInfoData();
    try {
      final parts = str.split(',');
      if (parts.length < 39) {
        await SharedUtil.addFailRecord("bcu", "資料長度不足: ${parts.length}");
      }

      // voltage
      double tmpVoltage = (parts.length > 1 ? double.tryParse(parts[1]) ?? 0 : 0) / 1000;
      if (tmpVoltage != 0) bcu.maxBatteryVoltage = tmpVoltage.toStringAsFixed(3);
      else await SharedUtil.addFailRecord("bcu", "maxBatteryVoltage 空或 0");

      double tmpCurrent = (parts.length > 2 ? double.tryParse(parts[2]) ?? 0 : 0) / 100;
      if (tmpCurrent != 0) bcu.batteryCurrent = tmpCurrent.toStringAsFixed(3);
      else await SharedUtil.addFailRecord("bcu", "batteryCurrent 空或 0");

      if (parts.length > 3 && parts[3] != "0" && parts[3].isNotEmpty) bcu.batterySOC = parts[3];
      else await SharedUtil.addFailRecord("bcu", "batterySOC 空或 0");

      // RemainingCap B1~B7
      for (int i = 1; i <= 7; i++) {
        if (parts.length > 31 + i && parts[31 + i].isNotEmpty && parts[31 + i] != "0") {
          bcu['remainingCapB$i'] = parts[31 + i];
        } else {
          await SharedUtil.addFailRecord("bcu", "remainingCapB$i 空或 0");
        }
      }

      // BatteryVoltage1~7
      for (int i = 1; i <= 7; i++) {
        if (parts.length > 24 + i && parts[24 + i].isNotEmpty && parts[24 + i] != "0") {
          bcu['batteryVoltage$i'] = parts[24 + i];
        } else {
          await SharedUtil.addFailRecord("bcu", "batteryVoltage$i 空或 0");
        }
      }

      // MaxTemperature1~7
      for (int i = 1; i <= 7; i++) {
        double temp = (parts.length > 3 + i ? double.tryParse(parts[3 + i]) ?? 0 : 0);
        if (temp != 0) bcu['maxTemperature$i'] = (temp / 10).toStringAsFixed(1);
        else await SharedUtil.addFailRecord("bcu", "maxTemperature$i 空或 0");
      }

      // LoStatus1~7
      for (int i = 1; i <= 7; i++) {
        if (parts.length > 10 + i && parts[10 + i].isNotEmpty) {
          bcu['loStatus$i'] = parts[10 + i];
        } else {
          await SharedUtil.addFailRecord("bcu", "loStatus$i 空");
        }
      }

      GlobalPara.instance.BcuInfo = bcu;
      return bcu;
    } catch (e) {
      await SharedUtil.addFailRecord("bcu", e.toString());
      return null;
    }
  }

  /// 自動辨識 BCU / PACK 資料並解析
  static Future<void> parseAndUpdateGlobal(String rcvStr) async {
    if (rcvStr.startsWith(".@0")) {
      await parseBcu(rcvStr);
    } else if (rcvStr.startsWith(".@")) {
      await parsePack(rcvStr);
    } else {
      await SharedUtil.addFailRecord("unknown", "Unknown data format: $rcvStr");
    }
  }
}