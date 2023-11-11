import 'package:ble_ips_example4/src/models/Manager/PositionManager.dart';
import 'package:ble_ips_example4/src/models/Manager/RoomManager.dart';
import 'package:ble_ips_example4/src/models/Room.dart';
import 'package:ble_ips_example4/src/models/offsetPosition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:widget_and_text_animator/widget_and_text_animator.dart';
import 'src/utils/animation_paint.dart';
import 'src/utils/ble_data.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (ctx) {
            return PositionManager();
          },
        ),
        ChangeNotifierProvider(
          create: (ctx) {
            return RoomManager();
          },
        ),
      ],
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'BLE Indoor Position',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: const BLEProjectPage(title: 'BLE Indoor Position'),
      ),
    );
  }
}

/* First Page */
class BLEProjectPage extends StatefulWidget {
  const BLEProjectPage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<BLEProjectPage> createState() => _BLEProjectPageState();
}

class _BLEProjectPageState extends State<BLEProjectPage> {
  var bleController = Get.put(BLEResult());

  // page bleController
  final _pageController = PageController();
  TextEditingController textController = TextEditingController();

  // flutter_blue_plus
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  bool isScanning = false;
  late Future<void> _fetchPositions;

  @override
  void initState() {
    _fetchPositions = context.read<PositionManager>().initilize().then((value) {
      context.read<PositionManager>().fetchPositions();
    });
    super.initState();
  }

  /* start or stop callback */
  Future<void> toggleState() async {
    context.read<PositionManager>().fetchPositions();
    isScanning = !isScanning;
    if (isScanning) {
      flutterBlue.startScan(scanMode: ScanMode(2), allowDuplicates: true);
      scan();
    } else {
      flutterBlue.stopScan();

      bleController.initBLEList();
    }
    setState(() {});
  }

  /* Scan */
  void scan() async {
    flutterBlue.scanResults.listen((results) {
      for (var element in results) {
        if (element.device.name.isNotEmpty) {
          var i =
              bleController.macAddressScanList.indexOf(element.device.id.id);
          if (i != -1) {
            if (bleController.scanResultList[i].rssi.length >= 5) {
              // double mean = bleController
              //     .averageRSSI(bleController.scanResultList[i].rssi);
              // if (mean - element.rssi < 20) {
              //   double variance = bleController.scanResultList[i].rssi
              //           .map((x) => pow(x - mean, 2))
              //           .reduce((a, b) => a + b) /
              //       bleController.scanResultList[i].rssi.length;

              //   double standardDeviation = sqrt(variance);
              //   double errorMeasure = standardDeviation;

              //   double errorEstimate = element.rssi - mean;
              //   SimpleKalman kalmanFilter = SimpleKalman(
              //     errorMeasure: errorMeasure,
              //     errorEstimate: errorEstimate,
              //     q: 0.1,
              //   );
              //   for (var e in bleController.scanResultList[i].rssi) {
              //     kalmanFilter.filtered(e);
              //   }
              //   double newValue = kalmanFilter.filtered(element.rssi * 1.0);
              //   bleController.scanResultList[i].rssi.removeAt(0);

              // if (!newValue.isNaN && newValue != 0) {
              //   bleController.scanResultList[i].rssi.add(newValue);
              // } else {
              bleController.scanResultList[i].rssi.add(element.rssi * 1.0);
              // }
              // }
            } else {
              bleController.scanResultList[i].rssi.add(element.rssi * 1.0);
            }
          } else {
            ScanResult1 rs = ScanResult1(
                device: element.device,
                advertisementData: element.advertisementData,
                rssi: [element.rssi * 1.0]);
            bleController.scanResultList.add(rs);
            bleController.macAddressScanList.add(element.device.id.id);
          }
        }
      }
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.deepOrangeAccent,
        actions: [
          IconButton(
            icon: Icon(
                isScanning ? Icons.stop_outlined : Icons.play_arrow_outlined),
            onPressed: toggleState,
          )
        ],
      ),
      body: FutureBuilder(
        future: _fetchPositions,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          return PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                isScanning ? CircleRoute() : startScan(),
              ]);
        },
      ),
    );
  }

  Widget startScan() => Center(
        child: Column(
          children: <Widget>[
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextAnimator(
                  'Find Bluetooth Devices',
                  atRestEffect:
                      WidgetRestingEffects.pulse(effectStrength: 0.25),
                  style: Theme.of(context).textTheme.headline6,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            const Padding(padding: EdgeInsets.all(8)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Choose a map: ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.normal),
                ),
                Container(
                  width: 150,
                  child: Center(
                    child: DropdownButton<String>(
                        items: <DropdownMenuItem<String>>[
                          DropdownMenuItem<String>(
                            value: 'Class',
                            child: Text('Classroom'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'School',
                            child: Text('CICT'),
                          ),
                        ],
                        value: context.read<PositionManager>().location,
                        onChanged: (value) {
                          setState(() {
                            context.read<PositionManager>().setLocation(value!);
                            context.read<RoomManager>().setLocation(value);
                            context.read<RoomManager>().setUserRoom(
                                  Room(
                                    maSo: 0,
                                    map: '',
                                    neightbor: {},
                                    name: '',
                                    offset: OffsetPosition(x: 0, y: 0),
                                    luotTruyCap: 0,
                                    keyWord: [],
                                  ),
                                );
                          });
                        }),
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                toggleState();
              },
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: Colors.deepOrangeAccent),
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                child: Container(
                  child: Text(
                    'Start Scanning',
                    style: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      );
}
