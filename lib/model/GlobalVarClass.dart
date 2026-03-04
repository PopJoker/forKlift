// lib/model/GlobalVarClass.dart
import 'BcuInfo.dart';
import 'PackSetInfo.dart';

class GlobalPara {
  GlobalPara._privateConstructor();
  static final GlobalPara instance = GlobalPara._privateConstructor();

  bool btIsConnected = false;

  BcuInfoData BcuInfo = BcuInfoData();

  Map<String, PackSetInfo> PackInfoMap = {
    '1': PackSetInfo(),
    '2': PackSetInfo(),
    '3': PackSetInfo(),
    '4': PackSetInfo(),
    '5': PackSetInfo(),
    '6': PackSetInfo(),
    '7': PackSetInfo(),
  };
}