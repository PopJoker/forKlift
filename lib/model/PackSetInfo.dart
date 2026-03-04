//lib\model\PackSetInfo.dart
class PackSetInfo {
  String packNum = "1";

  String loVoltage = "0";
  String hiVoltage = "0";
  String current = "0";
  String soc = "0";

  String loStatus = "0";
  String hiStatus = "0";

  String loTs1Temp = "0";
  String loTs2Temp = "0";
  String loTs3Temp = "0";
  String hiTs1Temp = "0";
  String hiTs2Temp = "0";
  String hiTs3Temp = "0";

  Map<String, bool> loFlags = {
    'LoCUV': false, 
    'LoCOV': false,
    'LoOCC': false,
    'LoOCD': false,
    'LoAOLD': false,
    'LoAOLDL': false,
    'LoASCD': false,
    'LoASCDL': false,
    'LoOTC': false,
    'LoOTD': false,
    'LoUTC': false,
    'LoUTD': false,
    'LoCHG': false,
    'LoDSG': false,
    'LoOCDL': false, 
    'LoOC': false,  
  };

  Map<String, bool> hiFlags = {
    'HiCUV': false,
    'HiCOV': false,
    'HiOTC': false,
    'HiOTD': false,
    'HiUTC': false,
    'HiUTD': false,
    'HiOC': false,
  };

  String firmware = "1.0";

  List<String> cellVoltage = List.generate(22, (_) => "0");

  String remainingCapacity = "0";
  String fullChargeCapacity = "0";
  String soh = "0";
}