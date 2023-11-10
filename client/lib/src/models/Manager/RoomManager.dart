import 'dart:math';
import 'package:ble_ips_example4/src/models/Room.dart';
import 'package:ble_ips_example4/src/models/offsetPosition.dart';
import 'package:ble_ips_example4/src/services/roomService.dart';
import 'package:dijkstra/dijkstra.dart';
import 'package:flutter/material.dart';
import 'package:typicons_flutter/typicons_flutter.dart';

class RoomManager with ChangeNotifier {
  List<Room>? _rooms;
  List<Room>? _search;
  Room? _searchRoom;
  String _location = '';
  Room _userRoom = Room(
      maSo: 0,
      map: '',
      neightbor: {},
      name: '',
      offset: OffsetPosition(x: 0, y: 0),
      luotTruyCap: 0,
      keyWord: []);

  final RoomService _roomService;

  Map<dynamic, dynamic> _graph = {};

  RoomManager() : _roomService = RoomService();

  Future<void> initilize() async {
    await _roomService.connectDB();
  }

  Future<void> fetchPositions(location) async {
    _rooms = await _roomService.fetchPositions(location);
    _graph = {};
    (await _roomService.fetchPositions(location))?.forEach(
      (element) {
        Map neightbor = element.neightbor
            .map((key, value) => MapEntry(int.parse(key), value));
        Map temp = {element.maSo: neightbor};
        _graph.addAll(temp);
      },
    );
    // print(_graph);
    notifyListeners();
  }

  Future<void> updateRoom(Room room) async {
    await _roomService.updateRoom(room);
    notifyListeners();
  }

  void setLocation(String location) {
    _location = location;
    notifyListeners();
  }

  void setUserRoom(Room room) {
    // print(room.name);
    _userRoom = room;
    notifyListeners();
  }

  Room get userRoom {
    return _userRoom;
  }

  void setSearchRoom(Room? room) {
    _searchRoom = room!;
    notifyListeners();
  }

  Room? get searchRoom {
    return _searchRoom;
  }

  List<Room>? get rooms {
    return _rooms;
  }

  List<Room>? get search {
    _search = [..._rooms!.where((element) => element.name != '').toList()];
    _search!.sort((a, b) => b.luotTruyCap.compareTo(a.luotTruyCap));
    // print(_search);
    return _search;
  }

  double distance(Offset a, Offset b) {
    double sum = 0;
    sum = sqrt((a.dx - b.dx) * (a.dx - b.dx) + (a.dy - b.dy) * (a.dy - b.dy));
    if (_location == 'School') return (sum / 20);
    return (sum / 130);
  }

  /// Kiểm tra 2 điểm có nằm trên 1 đường thẳng hay không?
  List<Map>? testTwoPoint(Room first, Room last, List<Room> listRoom) {
    List<Map> path = [];
    // lấy tọa độ của first và last
    var start = Offset(first.offset.x, first.offset.y);
    var end = Offset(last.offset.x, last.offset.y);
    // Khoảng cách từ start đến end
    double span = distance(start, end);
    path.add({
      "title": "Từ ${first.name} đi thẳng ${span.toStringAsFixed(2)} m",
      "icon": Typicons.arrow_up_outline,
    });

    if (start.dx == end.dx || start.dy == end.dy) {
      if (start.dx > end.dx || start.dx < end.dx) {
        return path;
      }
      if (start.dy > end.dy || start.dy < end.dy) {
        return path;
      }
    }
    if (_graph[first.maSo]![last.maSo] != null) {
      return path;
    }
    return null;
  }

  /// Lấy tọa độ điểm mà tại đó đường đi có rẽ hướng
  Room? getPoint(List<Room> listPoint, List<Room> listRoom) {
    for (int i = listPoint.length - 2; i > 0; i--) {
      if (testThreePoint(
              listPoint.first, listPoint[i], listPoint.last, listRoom) !=
          null) {
        return listPoint[i];
      }
    }
    return null;
  }

  /// Kiểm tra 3 điểm có rẽ hướng hay không
  List? testThreePoint(Room first, Room mid, Room last, List<Room> listRoom) {
    var start = Offset(first.offset.x, first.offset.y);
    var prevEnd = Offset(mid.offset.x, mid.offset.y);
    var end = Offset(last.offset.x, last.offset.y);
    // Khoảng cách từ điểm giữa tới điểm cuối
    double span = distance(prevEnd, end);
    List left = [
      {
        "title": "Quẹo trái ${span.toStringAsFixed(2)} m",
        "icon": Typicons.arrow_left_outline
      }
    ];
    List right = [
      {
        "title": "Quẹo phải ${span.toStringAsFixed(2)} m",
        "icon": Typicons.arrow_right_outline
      }
    ];
    // Kiểm tra điểm đầu và điểm giửa có nằm trên 1 đường thẳng hay không
    if (testTwoPoint(first, mid, listRoom) != null) {
      if (start.dy == prevEnd.dy && prevEnd.dx == end.dx ||
          start.dy == prevEnd.dy && testTwoPoint(mid, last, listRoom) != null) {
        if (start.dx > prevEnd.dx) {
          if (prevEnd.dy < end.dy) {
            return left;
          }
          return right;
        } else {
          if (prevEnd.dy < end.dy) {
            return right;
          }
          return left;
        }
      } else if (start.dx == prevEnd.dx && prevEnd.dy == end.dy ||
          start.dx == prevEnd.dx && testTwoPoint(mid, last, listRoom) != null) {
        if (start.dy < prevEnd.dy) {
          if (prevEnd.dx < end.dx) {
            return left;
          }
          return right;
        } else {
          if (prevEnd.dx < end.dx) {
            return right;
          }
          return left;
        }
      }
      if (testTwoPoint(mid, last, listRoom) != null) {
        if (start.dx > prevEnd.dx && prevEnd.dy > end.dy ||
            start.dx < prevEnd.dx && prevEnd.dy < end.dy) {
          return right;
        }
        if (start.dx > prevEnd.dx && prevEnd.dy < end.dy ||
            start.dx < prevEnd.dx && prevEnd.dy > end.dy) {
          return left;
        }
      }
    }
    return null;
  }

  List<Room> dijkstra({required Room from, required Room to}) {
    List<Room> listDijkstra = [];
    List dijkstra = Dijkstra.findPathFromGraph(
        _graph, from.maSo as dynamic, to.maSo as dynamic);
    for (var element in dijkstra) {
      listDijkstra.add(_rooms!.firstWhere((e) => e.maSo == element));
    }
    return listDijkstra;
  }

  /// Hàm tìm đường đi
  List<Map> route(
      {required Room from, required Room to, required List<Room> listRoom}) {
    if (distance(Offset(from.offset.x, from.offset.y),
            Offset(to.offset.x, to.offset.y)) <
        1) {
      return [
        {
          "title": "Đã đến vị trí bạn muốn",
          "icon": Typicons.arrow_up_outline,
        }
      ];
    }
    try {
      List<Room> listDijkstra = dijkstra(from: from, to: to);
      // Nếu mã phòng nhỏ hơn 100 thì chuyển thành tên ngược lại giữ nguyên
      Room roomName = listDijkstra.first;

      List<Map> path = [];
      if (testTwoPoint(listDijkstra.first, listDijkstra.last, listRoom) !=
          null) {
        return testTwoPoint(listDijkstra.first, listDijkstra.last, listRoom)!;
      } else {
        var point = getPoint(listDijkstra, listRoom);
        if (point != null) {
          double span = distance(
              Offset(listDijkstra.first.offset.x, listDijkstra.first.offset.y),
              Offset(point.offset.x, point.offset.y));
          path.add({
            "title":
                "Từ ${roomName.name} đi thẳng ${span.toStringAsFixed(2)} m",
            "icon": Typicons.arrow_up_outline,
          });
          for (var element in testThreePoint(
              listDijkstra.first, point, listDijkstra.last, listRoom)!) {
            path.add(element);
          }
          return path;
        } else {
          List<Room> left = [];
          List<Room> right = [];

          left.addAll(listDijkstra);
          while (getPoint(left, listRoom) == null) {
            left.removeLast();
          }
          right.addAll(listDijkstra.getRange(
              listDijkstra.indexOf(getPoint(left, listRoom)!),
              listDijkstra.length));
          double span = distance(
              Offset(listDijkstra.first.offset.x, listDijkstra.first.offset.y),
              Offset(right.first.offset.x, right.first.offset.y));
          path.add({
            "title":
                "Từ ${roomName.name} đi thẳng ${span.toStringAsFixed(2)} m",
            "icon": Typicons.arrow_up_outline,
          });
          for (var element
              in route(from: left.first, to: left.last, listRoom: listRoom)) {
            if (!element["title"].toString().contains("đi thẳng")) {
              path.add(element);
            }
          }
          for (var element
              in route(from: right.first, to: right.last, listRoom: listRoom)) {
            if (!element["title"].toString().contains("đi thẳng")) {
              path.add(element);
            }
          }
          return path;
        }
      }
    } catch (e) {
      return [
        {
          "title": "Chưa tìm được hướng dẫn",
          "icon": Typicons.arrow_up_outline,
        }
      ];
    }
  }
}
