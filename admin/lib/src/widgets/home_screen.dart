import 'package:lvtn_admin/src/models/Manager/PositionManager.dart';
import 'package:lvtn_admin/src/widgets/pageBLEScan.dart';
import 'package:lvtn_admin/src/widgets/pageBLESelected.dart';
import 'package:flutter/material.dart';
import 'package:bottom_bar/bottom_bar.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:lvtn_admin/src/widgets/search_screen.dart';
import 'package:provider/provider.dart';
import 'package:widget_and_text_animator/widget_and_text_animator.dart';
import '../utils/ble_data.dart';

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
  int _currentBody = 0;
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
    isScanning = !isScanning;
    if (isScanning) {
      flutterBlue.startScan(scanMode: const ScanMode(2), allowDuplicates: true);
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
      List<ScanResult1> ls = [];
      for (var element in results) {
        if (element.device.name.isNotEmpty) {
          ScanResult1 rs = ScanResult1(
              device: element.device,
              advertisementData: element.advertisementData,
              rssi: [element.rssi * 1.0]);
          ls.add(rs);
        }
      }
      bleController.scanResultList = ls;
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
              icon: Icon(isScanning ? Icons.stop : Icons.play_arrow),
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
                    isScanning ? const pageBLEScan() : startScan(),
                    const pageBLESelected(),
                    const SearchScreen(),
                  ]);
            }),
        bottomNavigationBar: BottomBar(
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          selectedIndex: _currentBody,
          onTap: (int index) {
            _pageController.jumpToPage(index);
            setState(() => _currentBody = index);
          },
          items: <BottomBarItem>[
            BottomBarItem(
              icon: const Icon(
                Icons.bluetooth,
                color: Colors.black,
              ),
              title: const Text('BLE Scan'),
              activeColor: Colors.deepOrangeAccent,
              activeTitleColor: Colors.black,
            ),
            BottomBarItem(
              icon: const Icon(
                Icons.map,
                color: Colors.black,
              ),
              title: const Text('List Anchor'),
              backgroundColorOpacity: 0.1,
              activeTitleColor: Colors.black,
              activeColor: Colors.deepOrangeAccent,
            ),
            BottomBarItem(
              icon: const Icon(
                Icons.place,
                color: Colors.black,
              ),
              title: const Text('List Room'),
              backgroundColorOpacity: 0.1,
              activeTitleColor: Colors.black,
              activeColor: Colors.deepOrangeAccent,
            ),
          ],
        ));
  }

  Widget startScan() => Center(
        child: Column(
          children: <Widget>[
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextAnimator(
                  'Scan Bluetooth Device',
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
                const Text(
                  'Choose Room: ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Container(
                  width: 100,
                  child: Center(
                    child: DropdownButton<String>(
                        items: <DropdownMenuItem<String>>[
                          const DropdownMenuItem<String>(
                            value: 'Class',
                            child: Text('Class'),
                          ),
                          const DropdownMenuItem<String>(
                            value: 'Library',
                            child: Text('Library'),
                          ),
                          const DropdownMenuItem<String>(
                            value: 'School',
                            child: Text('School'),
                          ),
                        ],
                        value: context.read<PositionManager>().location,
                        onChanged: (value) {
                          context.read<PositionManager>().setLocation(value!);
                          setState(() {});
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
                  child: const Text(
                    'Start Scan',
                    style: TextStyle(fontSize: 22, color: Colors.white),
                  ),
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      );
}
