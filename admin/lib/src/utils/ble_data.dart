import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

@override
class ScanResult1 {
  ScanResult1(
      {required this.device,
      required this.advertisementData,
      required this.rssi});

  final BluetoothDevice device;
  final AdvertisementData advertisementData;
  List<double> rssi;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanResult1 &&
          runtimeType == other.runtimeType &&
          device == other.device;

  @override
  int get hashCode => device.hashCode;

  @override
  String toString() {
    return 'ScanResult1{device: $device, advertisementData: $advertisementData, rssi: $rssi}';
  }
}

/* Provider class */
class BLEResult extends GetxController {
  // Raw BLE Scan Result
  List<ScanResult1> scanResultList = [];
  List<double> rssiAverageList = [];
  List<double> rssiFilterList = [];
  List<String> macAddressScanList = [];

  // BLE advertising pacekt format
  List<String> deviceNameList = [];
  List<String> macAddressList = [];
  List<String> rssiList = [];

  List<String> txPowerLevelList = [];
  List<String> manuFacturerDataList = [];
  List<String> serviceUuidsList = [];

  // BTN flag
  List<bool> flagList = [];

  // selected beacon param for distance
  List<int> selectedDeviceIdxList = [];
  List<String> selectedDeviceNameList = [];
  List<num> selectedConstNList = [];
  List<int> selectedRSSI_1mList = [];
  List<double> selectedCenterXList = [];
  List<double> selectedCenterYList = [];
  List<num> selectedDistanceList = [];

  // max distance
  double maxDistance = 8.0;

  // distance value
  List<double> distanceList = [];

  averageRSSI(List<double> a) {
    return a.fold<double>(
            0, (previousValue, element) => previousValue + element) /
        a.length;
  }

  void initBLEList() {
    print(1);
    scanResultList = [];
    selectedDeviceIdxList = [];
    macAddressScanList = [];
    rssiAverageList = [];
    rssiFilterList = [];

    deviceNameList = [];
    macAddressList = [];
    rssiList = [];
    txPowerLevelList = [];
    manuFacturerDataList = [];
    serviceUuidsList = [];
    flagList = [];
    selectedDeviceIdxList = [];
    selectedDeviceNameList = [];
    selectedConstNList = [];
    selectedRSSI_1mList = [];
    selectedCenterXList = [];
    selectedCenterYList = [];
    selectedDistanceList = [];

    distanceList = [];
  }

  void updateBLEList(
      {required String deviceName,
      required String macAddress,
      required String rssi,
      required String serviceUUID,
      required String manuFactureData,
      required String tp}) {
    if (macAddressList.contains(macAddress)) {
      rssiList[macAddressList.indexOf(macAddress)] = rssi;
    } else {
      deviceNameList.add(deviceName);
      macAddressList.add(macAddress);
      rssiList.add(rssi);
      serviceUuidsList.add(serviceUUID);
      manuFacturerDataList.add(manuFactureData);
      txPowerLevelList.add(tp);
      flagList.add(false);
    }
    update();
  }

  void updateFlagList({required bool flag, required int index}) {
    flagList[index] = flag;
    update();
  }

  void updateselectedDeviceIdx(index, constN, rSSI_1M, X, Y, distance) {
    if (!selectedDeviceIdxList.contains(index)) {
      selectedDeviceIdxList.add(index);
      selectedDeviceNameList.add(deviceNameList[index]);
      selectedConstNList.add(constN);
      selectedRSSI_1mList.add(rSSI_1M);
      selectedCenterXList.add(X);
      selectedCenterYList.add(Y);
      selectedDistanceList.add(distance);
      updateFlagList(flag: true, index: index);
    }
    update();
  }

  void updateselectedDeviceIdxList() {
    flagList.forEachIndexed((index, element) {
      if (element == true) {
        if (!selectedDeviceIdxList.contains(index)) {
          selectedDeviceIdxList.add(index);
          selectedDeviceNameList.add(deviceNameList[index]);
          selectedConstNList.add(2.0);
          selectedRSSI_1mList.add(-67);
          selectedCenterXList.add(0.0);
          selectedCenterYList.add(0.0);
          selectedDistanceList.add(0.0);
        }
      } else {
        int idx = selectedDeviceIdxList.indexOf(index);
        if (idx != -1) {
          selectedDeviceIdxList.remove(index);
          selectedDeviceNameList.removeAt(idx);
          selectedConstNList.removeAt(idx);
          selectedRSSI_1mList.removeAt(idx);
          selectedCenterXList.removeAt(idx);
          selectedCenterYList.removeAt(idx);
          selectedDistanceList.removeAt(idx);
        }
      }
    });
    update();
  }
}
