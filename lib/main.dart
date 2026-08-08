// lib/main.dart
// FNAF tarzı, LAN üzerinden çok oyunculu asimetrik korku oyunu
// Tüm kod tek dosyada, harici paket yok.
// flutter analyze 0 hata hedefi.

import 'dart:async';
import 'dart:io';
import 'dart:math' as m;
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Darkescas',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A12),
        textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
      ),
      home: const MenuPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// --------------------------- SABİTLER ---------------------------
const kTxt = TextStyle(color: Color(0xFFB0B0DD), fontSize: 14, height: 1.4);
const kSmall = TextStyle(color: Color(0xFF8888BB), fontSize: 11, fontWeight: FontWeight.w700);
const kHours = ['12AM', '1AM', '2AM', '3AM', '4AM', '5AM', '6AM'];
const String version = 'v8';

// --------------------------- KARAKTERLER ---------------------------
class CharDef {
  final String name;
  final Color color;
  final double speed; // hareket hızı
  final double cd; // yetenek bekleme süresi
  final String active; // yetenek adı
  final String passive; // pasif
  const CharDef(this.name, this.color, this.speed, this.cd, this.active, this.passive);
}

final List<CharDef> CHARS = [
  const CharDef('Kanat', Color(0xFFE67E22), 1.2, 6, 'HIZ', 'HIZLI'),
  const CharDef('Gölge', Color(0xFF8E44AD), 1.0, 5, 'SESSİZ', 'GÖRÜNMEZ'),
  const CharDef('Fare', Color(0xFFE74C3C), 1.1, 8, 'VENTRUSH', 'VENT'),
  const CharDef('Kas', Color(0xFFC0392B), 0.8, 7, 'KIR', 'KAPI'),
  const CharDef('Hacker', Color(0xFF2ECC71), 0.9, 6, 'KAMJAM', 'SESSİZ'),
  const CharDef('Işık', Color(0xFFFFF6B0), 1.0, 5, 'PARLAK', 'IŞIK'),
  const CharDef('Gürültü', Color(0xFFF39C12), 1.0, 4, 'GÜRÜLTÜ', 'YOK'),
  const CharDef('Korku', Color(0xFF9B59B6), 0.9, 6, 'KORKUT', 'YOK'),
  const CharDef('Dalga', Color(0xFF1ABC9C), 1.3, 7, 'DALGA', 'HIZ'),
  const CharDef('Enerji', Color(0xFF3498DB), 0.8, 4, 'DRAIN', 'YOK'),
  const CharDef('Sis', Color(0xFF95A5A6), 1.0, 8, 'IŞIN', 'SESSİZ'),
  const CharDef('Kukla', Color(0xFFE74C3C), 0.7, 10, 'ÇIĞLIK', 'GÖRÜNMEZ'),
];

// --------------------------- HARİTALAR ---------------------------
class GameMap {
  final String name;
  final List<Node> nodes;
  final List<Edge> edges;
  const GameMap(this.name, this.nodes, this.edges);
}

class Node {
  final String id;
  final double x, y;
  const Node(this.id, this.x, this.y);
}

class Edge {
  final String a, b;
  final String kind; // '' koridor, 'doorL', 'doorR', 'vent'
  const Edge(this.a, this.b, this.kind);
}

// Ofis merkezi (500,500) etrafında, ölçek 1 birim = 1 pixel (harita çizimi ölçeklendiriyor)
final List<GameMap> MAPS = [
  GameMap(
    'Klasik',
    [
      const Node('O', 500, 500),
      const Node('L', 350, 500),
      const Node('R', 650, 500),
      const Node('U', 500, 350),
      const Node('D', 500, 650),
      const Node('UL', 350, 350),
      const Node('UR', 650, 350),
      const Node('DL', 350, 650),
      const Node('DR', 650, 650),
      const Node('ST', 500, 200), // üst vent
    ],
    [
      const Edge('O', 'L', 'doorL'),
      const Edge('O', 'R', 'doorR'),
      const Edge('O', 'U', ''),
      const Edge('O', 'D', ''),
      const Edge('L', 'UL', ''),
      const Edge('L', 'DL', ''),
      const Edge('R', 'UR', ''),
      const Edge('R', 'DR', ''),
      const Edge('U', 'UL', ''),
      const Edge('U', 'UR', ''),
      const Edge('D', 'DL', ''),
      const Edge('D', 'DR', ''),
      const Edge('UL', 'UR', ''),
      const Edge('DL', 'DR', ''),
      const Edge('UR', 'DR', ''),
      const Edge('UL', 'DL', ''),
      const Edge('UR', 'ST', 'vent'),
      const Edge('UL', 'ST', 'vent'),
    ],
  ),
  GameMap(
    'Geniş',
    [
      const Node('O', 500, 500),
      const Node('L', 300, 500),
      const Node('R', 700, 500),
      const Node('U', 500, 300),
      const Node('D', 500, 700),
      const Node('UL', 300, 300),
      const Node('UR', 700, 300),
      const Node('DL', 300, 700),
      const Node('DR', 700, 700),
      const Node('ST', 500, 150),
    ],
    [
      const Edge('O', 'L', 'doorL'),
      const Edge('O', 'R', 'doorR'),
      const Edge('O', 'U', ''),
      const Edge('O', 'D', ''),
      const Edge('L', 'UL', ''),
      const Edge('L', 'DL', ''),
      const Edge('R', 'UR', ''),
      const Edge('R', 'DR', ''),
      const Edge('U', 'UL', ''),
      const Edge('U', 'UR', ''),
      const Edge('D', 'DL', ''),
      const Edge('D', 'DR', ''),
      const Edge('UL', 'UR', ''),
      const Edge('DL', 'DR', ''),
      const Edge('UR', 'DR', ''),
      const Edge('UL', 'DL', ''),
      const Edge('UR', 'ST', 'vent'),
      const Edge('UL', 'ST', 'vent'),
    ],
  ),
];

// --------------------------- Sfx (ses - placeholder) ---------------------------
class Sfx {
  static void screamBurst() {
    // Gerçek ses için audioplayers paketi gerekir, şartlar gereği boş
  }
  static void doorClose() {}
  static void doorOpen() {}
  static void lightClick() {}
  static void cameraOn() {}
  static void cameraOff() {}
  static void ventOn() {}
  static void ventOff() {}
  static void powerOut() {}
  static void jump() {}
}

// --------------------------- WIDGET: Btn ---------------------------
class Btn extends StatelessWidget {
  final String t;
  final String? sub;
  final Color c;
  final VoidCallback? on;
  final bool expand;
  const Btn({super.key, required this.t, this.sub, this.c = const Color(0xFF444466), this.on, this.expand = true});
  @override
  Widget build(BuildContext context) {
    final child = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(t, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white)),
        if (sub != null) Text(sub!, style: const TextStyle(fontSize: 9, color: Color(0xFFAAAAEE))),
      ],
    );
    return Expanded(
      flex: expand ? 1 : 0,
      child: GestureDetector(
        onTap: on,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white24, width: 1),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

// --------------------------- VERİ SINIFLARI ---------------------------
class VActor {
  final int pid; // oyuncu ID
  final int ch; // karakter indeksi
  double x, y; // harita koordinatları (0-1000)
  double stun; // sersemleme süresi
  double wait; // kapıda bekleme süresi
  bool hd; // gizli mi (haritada görünmez)
  bool iv; // görünmez mi
  int target; // hedef oda id'si (node index)
  double speedMul;
  VActor({
    required this.pid,
    required this.ch,
    this.x = 500,
    this.y = 500,
    this.stun = 0,
    this.wait = 0,
    this.hd = false,
    this.iv = false,
    this.target = -1,
    this.speedMul = 1.0,
  });
  Map<String, dynamic> toJson() => {
        'pid': pid,
        'ch': ch,
        'x': x,
        'y': y,
        'stun': stun,
        'wait': wait,
        'hd': hd,
        'iv': iv,
        'target': target,
        'speedMul': speedMul,
      };
  factory VActor.fromJson(Map<String, dynamic> j) => VActor(
        pid: j['pid'] as int,
        ch: j['ch'] as int,
        x: j['x'] as double,
        y: j['y'] as double,
        stun: j['stun'] as double? ?? 0,
        wait: j['wait'] as double? ?? 0,
        hd: j['hd'] as bool? ?? false,
        iv: j['iv'] as bool? ?? false,
        target: j['target'] as int? ?? -1,
        speedMul: j['speedMul'] as double? ?? 1.0,
      );
}

class VF {
  // View Frame - oyunun anlık görünümü
  final int hour; // 0-6
  final double power;
  final int usage; // 0-6
  final bool dl, dr, light, cam, vent, black;
  final double ddL, ddR; // kapı kilit süreleri
  final double forceL, forceR; // zorlanma
  final double waitL, waitR; // kapıda bekleme
  final int thL, thR; // kapıdaki canavar indeksi (-1 yok)
  final List<VActor> actors;
  final List<_Noise> noise;
  final double t; // oyun zamanı (saniye)
  final double blind; // karanlık körlük
  final bool jam; // kamera sinyal yok
  final int myPid;
  VF({
    this.hour = 0,
    this.power = 100,
    this.usage = 0,
    this.dl = false,
    this.dr = false,
    this.light = false,
    this.cam = false,
    this.vent = false,
    this.black = false,
    this.ddL = 0,
    this.ddR = 0,
    this.forceL = 0,
    this.forceR = 0,
    this.waitL = 0,
    this.waitR = 0,
    this.thL = -1,
    this.thR = -1,
    this.actors = const [],
    this.noise = const [],
    this.t = 0,
    this.blind = 0,
    this.jam = false,
    this.myPid = -1,
  });
}

class _Noise {
  final String o;
  _Noise(this.o);
}

// --------------------------- NET SINIFI (UDP) ---------------------------
class Net {
  // Oyun durumu
  String myName = '';
  String myRole = 'G'; // 'G' veya 'A'
  int myPid = -1;
  int myChar = 0;
  int mapIdx = 0;
  bool isHost = false;
  bool aiMode = false; // tek başına oyun (host+ai)
  bool over = false;
  String overSide = ''; // 'guard' veya 'anim'
  String overReason = '';
  double endDelay = 0;
  bool surprise = false;
  int overJs = -1; // jumpscare karakteri
  double shakeX = 0, shakeY = 0;
  bool jsOn = false;
  double jsT = 0;
  double soloDiff = 0; // 0,1,2
  int soloCount = 1;

  // Oyun içi kontroller
  bool dlShow = false, drShow = false;
  double fanA = 0;
  bool lightOn = false, camOn = false, ventOpen = false;
  double power = 100;
  int hour = 0;
  bool blackout = false;
  double gameTime = 0;
  List<VActor> actors = [];
  List<_Noise> noise = [];

  // Ağ
  RawDatagramSocket? _socket;
  int _port = 0;
  String _hostAddr = '';
  bool _running = false;
  Timer? _pingTimer;
  Timer? _snapTimer;
  int _snapSeq = 0;
  Map<int, DateTime> _lastPing = {};
  Map<int, int> _pids = {};
  int _nextPid = 1000;
  Map<String, dynamic> _lobbyData = {};
  List<Map<String, dynamic>> _players = [];
  bool _inGame = false;

  // Callback
  void Function(int page)? onPageChange;
  void Function(VF)? onVF;
  void Function()? onLobbyUpdate;
  void Function(String)? onError;

  Net() {
    _initUDP();
  }

  void _initUDP() async {
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _port = _socket!.port;
      _socket!.listen(_onData);
      _running = true;
    } catch (e) {
      if (onError != null) onError!('UDP başlatılamadı: $e');
    }
  }

  void _onData(RawSocketEvent event) {
    if (event == RawSocketEvent.read) {
      final datagram = _socket!.receive();
      if (datagram == null) return;
      final data = utf8.decode(datagram.data);
      final msg = jsonDecode(data) as Map<String, dynamic>;
      _handleMsg(msg, datagram.address, datagram.port);
    }
  }

  void _handleMsg(Map<String, dynamic> msg, InternetAddress addr, int port) {
    final type = msg['type'] as String?;
    if (type == null) return;
    switch (type) {
      case 'discover':
        _send(addr, port, {'type': 'hostinfo', 'name': myName, 'port': _port, 'players': _players.length});
        break;
      case 'hostinfo':
        // keşif cevabı (lobi listesi için)
        break;
      case 'hello':
        // client bağlantı isteği
        if (isHost) _handleHello(msg, addr, port);
        break;
      case 'welcome':
        if (!isHost) _handleWelcome(msg);
        break;
      case 'lobby':
        if (isHost) _handleLobby(msg, addr, port);
        break;
      case 'start':
        if (!isHost && _inGame) _handleStart(msg);
        break;
      case 'state':
        if (isHost && _inGame) _handleState(msg, addr, port);
        break;
      case 'act':
        if (isHost && _inGame) _handleAct(msg, addr, port);
        break;
      case 'snap':
        if (!isHost && _inGame) _handleSnap(msg);
        break;
      case 'over':
        if (!isHost && _inGame) _handleOver(msg);
        break;
      case 'err':
        if (onError != null) onError!(msg['text'] as String? ?? 'Hata');
        break;
      case 'ping':
        _send(addr, port, {'type': 'pong'});
        break;
      case 'pong':
        // ping yanıtı
        break;
      case 'leave':
        if (isHost) _handleLeave(msg, addr, port);
        break;
      case 'closed':
        // host kapandı
        break;
    }
  }

  void _send(InternetAddress addr, int port, Map<String, dynamic> msg) {
    try {
      final data = utf8.encode(jsonEncode(msg));
      _socket?.send(data, addr, port);
    } catch (_) {}
  }

  void broadcastDiscover() {
    final addr = InternetAddress('255.255.255.255');
    _send(addr, 9999, {'type': 'discover', 'name': myName});
  }

  // ---------------------- HOST İŞLEMLERİ ----------------------
  void createLobby(String name) {
    myName = name;
    isHost = true;
    _players.clear();
    _pids.clear();
    _nextPid = 1000;
    _players.add({'name': name, 'pid': _nextPid, 'char': 0, 'ready': false});
    _pids[_nextPid] = _nextPid;
    myPid = _nextPid++;
    _lobbyData = {'map': 0, 'players': _players};
    onPageChange?.call(2); // Lobi
    _startPingTimer();
  }

  void joinLobby(String ip, String name) {
    myName = name;
    isHost = false;
    _hostAddr = ip;
    _send(InternetAddress(ip), 9999, {'type': 'hello', 'name': name, 'port': _port});
  }

  void _handleHello(Map<String, dynamic> msg, InternetAddress addr, int port) {
    if (!isHost) return;
    final name = msg['name'] as String?;
    if (name == null) return;
    // var olan kontrol
    final pid = _nextPid++;
    _players.add({'name': name, 'pid': pid, 'char': 0, 'ready': false});
    _pids[pid] = pid;
    _lobbyData['players'] = _players;
    _send(addr, port, {'type': 'welcome', 'pid': pid, 'players': _players, 'map': mapIdx});
    _broadcastLobby();
  }

  void _handleWelcome(Map<String, dynamic> msg) {
    if (isHost) return;
    myPid = msg['pid'] as int;
    _lobbyData = msg;
    _players = List<Map<String, dynamic>>.from(msg['players'] as List);
    mapIdx = msg['map'] as int? ?? 0;
    onPageChange?.call(2);
    _startPingTimer();
  }

  void setPlayerChar(int idx) {
    if (!isHost) {
      // client olarak lobiye gönder
      _send(InternetAddress(_hostAddr), 9999, {'type': 'lobby', 'char': idx});
      return;
    }
    for (var p in _players) {
      if (p['pid'] == myPid) {
        p['char'] = idx;
        break;
      }
    }
    _broadcastLobby();
  }

  void setMap(int idx) {
    if (!isHost) return;
    mapIdx = idx;
    _lobbyData['map'] = idx;
    _broadcastLobby();
  }

  void _broadcastLobby() {
    if (!isHost) return;
    _lobbyData['players'] = _players;
    _lobbyData['map'] = mapIdx;
    for (var p in _players) {
      final pid = p['pid'] as int;
      final addr = _getAddr(pid);
      if (addr != null) {
        _send(addr, 9999, {'type': 'lobby', 'data': _lobbyData});
      }
    }
  }

  void _handleLobby(Map<String, dynamic> msg, InternetAddress addr, int port) {
    if (!isHost) return;
    // client karakter değişikliği
    final char = msg['char'] as int?;
    if (char != null) {
      final pid = _pidForAddr(addr, port);
      if (pid != null) {
        for (var p in _players) {
          if (p['pid'] == pid) {
            p['char'] = char.clamp(0, CHARS.length - 1);
            break;
          }
        }
        _broadcastLobby();
      }
    }
  }

  void startGame() {
    if (!isHost) return;
    if (_players.length < 2) {
      if (onError != null) onError!('En az 2 oyuncu gerekli!');
      return;
    }
    // Rolleri belirle: ilk oyuncu guard, diğerleri anim
    _inGame = true;
    _snapSeq = 0;
    _initGameState();
    _broadcastStart();
    onPageChange?.call(3);
    _startSnapTimer();
  }

  void _initGameState() {
    // host oyun durumunu başlat
    power = 100;
    hour = 0;
    gameTime = 0;
    blackout = false;
    over = false;
    actors.clear();
    noise.clear();
    // oyuncuları ekle
    bool first = true;
    for (var p in _players) {
      final pid = p['pid'] as int;
      final ch = p['char'] as int;
      final role = first ? 'G' : 'A';
      if (first) {
        myRole = 'G';
        myPid = pid;
      }
      first = false;
      // animatronikleri başlangıç pozisyonlarına koy
      final actor = VActor(
        pid: pid,
        ch: ch,
        x: 500 + (pid % 10) * 20,
        y: 500 + (pid % 7) * 20,
      );
      if (role == 'G') {
        actor.x = 500;
        actor.y = 500;
        actor.hd = true;
        actor.iv = true;
      }
      actors.add(actor);
    }
    // guard'ı gizle
    for (var a in actors) {
      if (a.pid == myPid && myRole == 'G') {
        a.hd = true;
        a.iv = true;
      }
    }
  }

  void _broadcastStart() {
    for (var p in _players) {
      final pid = p['pid'] as int;
      final addr = _getAddr(pid);
      if (addr != null) {
        _send(addr, 9999, {
          'type': 'start',
          'pid': pid,
          'role': pid == myPid ? myRole : (myRole == 'G' ? 'A' : 'G'), // aslında herkese kendi rolü
          'map': mapIdx,
          'actors': actors.map((a) => a.toJson()).toList(),
          'time': gameTime,
        });
      }
    }
  }

  void _handleStart(Map<String, dynamic> msg) {
    if (isHost) return;
    _inGame = true;
    myRole = msg['role'] as String;
    mapIdx = msg['map'] as int;
    final actorsJson = msg['actors'] as List;
    actors = actorsJson.map((j) => VActor.fromJson(j as Map<String, dynamic>)).toList();
    gameTime = msg['time'] as double? ?? 0;
    onPageChange?.call(3);
    _startSnapTimer();
  }

  // ---------------------- OYUN DÖNGÜSÜ (host) ----------------------
  void frame(double dt) {
    if (!_inGame || over || !isHost) return;
    gameTime += dt;
    // saat hesapla
    hour = (gameTime / 60).floor().clamp(0, 6);
    // güç tüketimi
    double usage = 0;
    if (dlShow) usage += 0.5;
    if (drShow) usage += 0.5;
    if (lightOn) usage += 1.0;
    if (camOn) usage += 2.0;
    if (ventOpen) usage += 0.3;
    if (!blackout) {
      power -= usage * dt * 0.2;
      if (power < 0) {
        power = 0;
        blackout = true;
        // kapılar açılır, kontroller kilitlenir
        dlShow = false;
        drShow = false;
        lightOn = false;
        camOn = false;
        ventOpen = false;
        Sfx.powerOut();
      }
    }
    // kapı kilitleri
    if (dlShow) {
      // kapı kapanırsa, kapıdaki canavar sersemler
      _checkDoor('L');
    }
    if (drShow) {
      _checkDoor('R');
    }
    // animatronik hareket
    _moveAnims(dt);
    // güç kullanım göstergesi
    // snap gönder
    _snapSeq++;
    if (_snapSeq % 2 == 0) _sendSnap();
    // kazanma kontrolü
    if (hour >= 6 && !over) {
      _endGame('guard', 'Sabah oldu!');
    }
    // VF oluştur ve callback
    final vf = _buildVF();
    if (onVF != null) onVF!(vf);
  }

  void _moveAnims(double dt) {
    // her animatronik için hedefe doğru hareket
    for (var a in actors) {
      if (a.pid == myPid && myRole == 'G') continue; // guard hareket etmez
      if (a.stun > 0) {
        a.stun -= dt;
        if (a.stun < 0) a.stun = 0;
        continue;
      }
      if (a.wait > 0) {
        a.wait -= dt;
        if (a.wait < 0) a.wait = 0;
        // kapıda bekleme süresi dolduysa ve kapı açıksa saldır
        _checkDoorAttack(a);
        continue;
      }
      // hedef belirleme: rastgele oda
      if (a.target < 0) {
        a.target = _randomNode();
      }
      // hedefe doğru ilerle
      final targetNode = MAPS[mapIdx].nodes[a.target];
      if (targetNode == null) { a.target = -1; continue; }
      double dx = targetNode.x - a.x;
      double dy = targetNode.y - a.y;
      final dist = m.sqrt(dx*dx + dy*dy);
      if (dist < 5) {
        a.x = targetNode.x;
        a.y = targetNode.y;
        a.target = -1;
        continue;
      }
      final speed = CHARS[a.ch.clamp(0, CHARS.length-1)].speed * a.speedMul * 40;
      final step = speed * dt;
      a.x += dx / dist * step;
      a.y += dy / dist * step;
    }
  }

  int _randomNode() {
    final nodes = MAPS[mapIdx].nodes;
    return m.Random().nextInt(nodes.length);
  }

  void _checkDoor(String side) {
    // kapı kapanınca kapıdaki canavarı sersemlet
    final isL = side == 'L';
    for (var a in actors) {
      if (a.pid == myPid) continue;
      final dx = a.x - 500;
      if (isL) {
        if (dx < -50 && dx > -150 && a.y > 400 && a.y < 600) {
          // kapı kapatıldı, sersemlet
          a.stun = 3.0;
          a.x = 500 + m.Random().nextInt(200) - 100;
          a.y = 500 + m.Random().nextInt(200) - 100;
          a.wait = 0;
          Sfx.doorClose();
        }
      } else {
        if (dx > 50 && dx < 150 && a.y > 400 && a.y < 600) {
          a.stun = 3.0;
          a.x = 500 + m.Random().nextInt(200) - 100;
          a.y = 500 + m.Random().nextInt(200) - 100;
          a.wait = 0;
          Sfx.doorClose();
        }
      }
    }
  }

  void _checkDoorAttack(VActor a) {
    // kapıda bekleme süresi doldu ve kapı açık mı?
    final dx = a.x - 500;
    bool atLeft = dx < -50 && a.y > 400 && a.y < 600;
    bool atRight = dx > 50 && a.y > 400 && a.y < 600;
    if (atLeft && !dlShow) {
      // guard'ı yakala
      _endGame('anim', 'Animatronik içeri girdi!');
    } else if (atRight && !drShow) {
      _endGame('anim', 'Animatronik içeri girdi!');
    }
  }

  void _endGame(String side, String reason) {
    if (over) return;
    over = true;
    overSide = side;
    overReason = reason;
    overJs = 11; // kukla jumpscare
    surprise = true;
    Sfx.screamBurst();
    // tüm oyunculara over gönder
    for (var p in _players) {
      final pid = p['pid'] as int;
      final addr = _getAddr(pid);
      if (addr != null) {
        _send(addr, 9999, {'type': 'over', 'side': side, 'reason': reason, 'js': overJs});
      }
    }
    onPageChange?.call(4);
  }

  void _sendSnap() {
    final vf = _buildVF();
    final data = {
      'type': 'snap',
      'seq': _snapSeq,
      'vf': {
        'hour': vf.hour,
        'power': vf.power,
        'usage': vf.usage,
        'dl': vf.dl,
        'dr': vf.dr,
        'light': vf.light,
        'cam': vf.cam,
        'vent': vf.vent,
        'black': vf.black,
        'ddL': vf.ddL,
        'ddR': vf.ddR,
        'forceL': vf.forceL,
        'forceR': vf.forceR,
        'waitL': vf.waitL,
        'waitR': vf.waitR,
        'thL': vf.thL,
        'thR': vf.thR,
        'actors': vf.actors.map((a) => a.toJson()).toList(),
        'noise': vf.noise.map((n) => n.o).toList(),
        't': vf.t,
        'blind': vf.blind,
        'jam': vf.jam,
      }
    };
    for (var p in _players) {
      final pid = p['pid'] as int;
      final addr = _getAddr(pid);
      if (addr != null) {
        _send(addr, 9999, data);
      }
    }
  }

  VF _buildVF() {
    final camJam = false; // hacker yeteneği ile değişebilir
    final dl = dlShow;
    final dr = drShow;
    final light = lightOn;
    final cam = camOn;
    final vent = ventOpen;
    final black = blackout;
    final ddL = 0.0; // kilit süresi yok
    final ddR = 0.0;
    final forceL = 0.0;
    final forceR = 0.0;
    final waitL = 0.0;
    final waitR = 0.0;
    int thL = -1, thR = -1;
    for (var a in actors) {
      if (a.pid == myPid) continue;
      final dx = a.x - 500;
      if (dx < -50 && dx > -150 && a.y > 400 && a.y < 600) {
        thL = a.ch;
        if (!dl) a.wait += 0.016; // kapı açıkken bekleme artar
      }
      if (dx > 50 && dx < 150 && a.y > 400 && a.y < 600) {
        thR = a.ch;
        if (!dr) a.wait += 0.016;
      }
    }
    final usage = (dl ? 1 : 0) + (dr ? 1 : 0) + (light ? 1 : 0) + (cam ? 2 : 0) + (vent ? 0.3 : 0);
    final noise = <_Noise>[];
    if (cam) {
      // kamera açıkken sesli odalar
      for (var a in actors) {
        if (a.pid == myPid) continue;
        // rastgele gürültü
        if (m.Random().nextDouble() < 0.01) {
          final nodeIdx = m.Random().nextInt(MAPS[mapIdx].nodes.length);
          noise.add(_Noise(MAPS[mapIdx].nodes[nodeIdx].id));
        }
      }
    }
    return VF(
      hour: hour,
      power: power,
      usage: usage.toInt(),
      dl: dl,
      dr: dr,
      light: light,
      cam: cam,
      vent: vent,
      black: black,
      ddL: ddL,
      ddR: ddR,
      forceL: forceL,
      forceR: forceR,
      waitL: waitL,
      waitR: waitR,
      thL: thL,
      thR: thR,
      actors: List.from(actors),
      noise: noise,
      t: gameTime,
      blind: black ? 1.0 : 0.0,
      jam: camJam,
      myPid: myPid,
    );
  }

  // Client tarafı snap alımı
  void _handleSnap(Map<String, dynamic> msg) {
    if (isHost) return;
    final vfData = msg['vf'] as Map<String, dynamic>;
    // VF oluştur
    final actorsJson = vfData['actors'] as List;
    final actorsList = actorsJson.map((j) => VActor.fromJson(j as Map<String, dynamic>)).toList();
    final noiseList = (vfData['noise'] as List).map((n) => _Noise(n as String)).toList();
    final vf = VF(
      hour: vfData['hour'] as int,
      power: vfData['power'] as double,
      usage: vfData['usage'] as int,
      dl: vfData['dl'] as bool,
      dr: vfData['dr'] as bool,
      light: vfData['light'] as bool,
      cam: vfData['cam'] as bool,
      vent: vfData['vent'] as bool,
      black: vfData['black'] as bool,
      ddL: vfData['ddL'] as double? ?? 0,
      ddR: vfData['ddR'] as double? ?? 0,
      forceL: vfData['forceL'] as double? ?? 0,
      forceR: vfData['forceR'] as double? ?? 0,
      waitL: vfData['waitL'] as double? ?? 0,
      waitR: vfData['waitR'] as double? ?? 0,
      thL: vfData['thL'] as int? ?? -1,
      thR: vfData['thR'] as int? ?? -1,
      actors: actorsList,
      noise: noiseList,
      t: vfData['t'] as double? ?? 0,
      blind: vfData['blind'] as double? ?? 0,
      jam: vfData['jam'] as bool? ?? false,
      myPid: myPid,
    );
    // yerel durumu güncelle (buton durumları vb.)
    dlShow = vf.dl;
    drShow = vf.dr;
    lightOn = vf.light;
    camOn = vf.cam;
    ventOpen = vf.vent;
    blackout = vf.black;
    power = vf.power;
    hour = vf.hour;
    actors = vf.actors;
    noise = vf.noise;
    gameTime = vf.t;
    if (onVF != null) onVF!(vf);
  }

  void _handleOver(Map<String, dynamic> msg) {
    if (isHost) return;
    over = true;
    overSide = msg['side'] as String;
    overReason = msg['reason'] as String;
    overJs = msg['js'] as int? ?? 11;
    surprise = true;
    Sfx.screamBurst();
    onPageChange?.call(4);
  }

  // Oyuncu aksiyonları (guard)
  void gAct(String act) {
    if (blackout) return;
    if (!_inGame) return;
    final msg = {'type': 'act', 'act': act};
    if (isHost) {
      _handleActLocal(act);
    } else {
      _send(InternetAddress(_hostAddr), 9999, msg);
    }
  }

  void _handleActLocal(String act) {
    switch (act) {
      case 'dl': dlShow = !dlShow; if (dlShow) Sfx.doorClose(); else Sfx.doorOpen(); break;
      case 'dr': drShow = !drShow; if (drShow) Sfx.doorClose(); else Sfx.doorOpen(); break;
      case 'li': lightOn = !lightOn; Sfx.lightClick(); break;
      case 'cm': camOn = !camOn; if (camOn) Sfx.cameraOn(); else Sfx.cameraOff(); break;
      case 'vt': ventOpen = !ventOpen; if (ventOpen) Sfx.ventOn(); else Sfx.ventOff(); break;
    }
  }

  void _handleAct(Map<String, dynamic> msg, InternetAddress addr, int port) {
    if (!isHost) return;
    final act = msg['act'] as String?;
    if (act == null) return;
    final pid = _pidForAddr(addr, port);
    if (pid == null) return;
    // guard için
    if (pid == myPid) {
      _handleActLocal(act);
    } else {
      // animatronik aksiyonları
      // act: 'joy', 'ctx', 'ability'
    }
  }

  // Animatronik joystick
  void sendJoy(double x, double y) {
    if (myRole != 'A' || _inGame == false) return;
    final msg = {'type': 'act', 'act': 'joy', 'x': x, 'y': y};
    if (isHost) {
      _handleJoyLocal(x, y);
    } else {
      _send(InternetAddress(_hostAddr), 9999, msg);
    }
  }

  void _handleJoyLocal(double x, double y) {
    // animatroniği hareket ettir
    for (var a in actors) {
      if (a.pid == myPid) {
        final speed = CHARS[a.ch.clamp(0, CHARS.length-1)].speed * 40;
        a.x += x * speed * 0.016;
        a.y += y * speed * 0.016;
        // sınırlar
        a.x = a.x.clamp(0, 1000);
        a.y = a.y.clamp(0, 1000);
        break;
      }
    }
  }

  void _handleJoy(Map<String, dynamic> msg, InternetAddress addr, int port) {
    final pid = _pidForAddr(addr, port);
    if (pid == null) return;
    final x = msg['x'] as double? ?? 0;
    final y = msg['y'] as double? ?? 0;
    // host'ta local işleme
    for (var a in actors) {
      if (a.pid == pid) {
        final speed = CHARS[a.ch.clamp(0, CHARS.length-1)].speed * 40;
        a.x += x * speed * 0.016;
        a.y += y * speed * 0.016;
        a.x = a.x.clamp(0, 1000);
        a.y = a.y.clamp(0, 1000);
        break;
      }
    }
  }

  // Animatronik yetenek
  void useAbility() {
    if (myRole != 'A' || _inGame == false) return;
    final msg = {'type': 'act', 'act': 'ability'};
    if (isHost) {
      _handleAbilityLocal();
    } else {
      _send(InternetAddress(_hostAddr), 9999, msg);
    }
  }

  void _handleAbilityLocal() {
    // karakter yeteneği
    for (var a in actors) {
      if (a.pid == myPid) {
        final ch = a.ch.clamp(0, CHARS.length-1);
        // basit yetenekler
        if (ch == 0) { a.speedMul = 2.0; Timer(Duration(seconds: 2), () => a.speedMul = 1.0); }
        else if (ch == 1) { a.hd = true; Timer(Duration(seconds: 3), () => a.hd = false); }
        else if (ch == 2) { // ventrush: ventten geç
          a.x = 500; a.y = 200; // üst vent
        }
        else if (ch == 3) { // doorbreak: kapıyı kır
          dlShow = false; drShow = false;
        }
        else if (ch == 4) { // camjam
          // kamera sinyal kes
        }
        else if (ch == 5) { // lightimmune: ışıkta görünmez
          a.hd = true;
        }
        else if (ch == 6) { // gürültü
          // rastgele gürültü
        }
        else if (ch == 7) { // korku
          // guard'ı korkut
        }
        else if (ch == 8) { // dalga
          a.speedMul = 1.5; Timer(Duration(seconds: 1), () => a.speedMul = 1.0);
        }
        else if (ch == 9) { // drain
          power -= 5;
        }
        else if (ch == 10) { // teleport
          a.x = 500 + m.Random().nextInt(200) - 100;
          a.y = 500 + m.Random().nextInt(200) - 100;
        }
        else if (ch == 11) { // scream
          Sfx.screamBurst();
        }
        break;
      }
    }
  }

  void _handleAbility(Map<String, dynamic> msg, InternetAddress addr, int port) {
    final pid = _pidForAddr(addr, port);
    if (pid == null) return;
    // local işle
    // basitçe host'ta çalıştır
    _handleAbilityLocal();
  }

  // Bağlamsal buton (ctx)
  void doCtx() {
    if (myRole != 'A' || _inGame == false) return;
    final msg = {'type': 'act', 'act': 'ctx'};
    if (isHost) {
      _handleCtxLocal();
    } else {
      _send(InternetAddress(_hostAddr), 9999, msg);
    }
  }

  String? ctxLabel(VF vf) {
    // bulunduğu odada ne yapabilir?
    for (var a in vf.actors) {
      if (a.pid == myPid) {
        final x = a.x, y = a.y;
        // ofis yakını
        final dx = x - 500, dy = y - 500;
        if (dx.abs() < 100 && dy.abs() < 100) {
          if (dlShow) return 'ZORLA KAPI';
          else return 'GİR';
        }
        // kapılar
        if (dx < -50 && dy.abs() < 100) return 'VENT';
        if (dx > 50 && dy.abs() < 100) return 'VENT';
        // vent
        if (x > 450 && x < 550 && y < 250) return 'VENT';
        return 'SALDIR';
      }
    }
    return null;
  }

  void _handleCtxLocal() {
    // ctx butonu işlevi
    for (var a in actors) {
      if (a.pid == myPid) {
        final x = a.x, y = a.y;
        final dx = x - 500, dy = y - 500;
        if (dx.abs() < 100 && dy.abs() < 100) {
          if (dlShow) {
            // kapıyı kır
            dlShow = false;
          } else {
            // içeri gir
            _endGame('anim', 'Animatronik içeri girdi!');
          }
        } else if (dx < -50 || dx > 50) {
          // vent
          a.x = 500;
          a.y = 200;
        } else if (x > 450 && x < 550 && y < 250) {
          // ventten çık
          a.x = 500 + (m.Random().nextInt(200) - 100);
          a.y = 500 + (m.Random().nextInt(200) - 100);
        } else {
          // saldır
          // guard'ı yakala
          _endGame('anim', 'Animatronik saldırdı!');
        }
        break;
      }
    }
  }

  // ---------------------- YARDIMCI ----------------------
  InternetAddress? _getAddr(int pid) {
    // basit: adres saklama yok, her mesajda addr ile gelir
    return null;
  }

  int? _pidForAddr(InternetAddress addr, int port) {
    // gerçekte adres-pid eşlemesi tutulmalı, şimdilik ilk pid
    if (_players.isNotEmpty) return _players[0]['pid'] as int;
    return null;
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      // ping gönder
    });
  }

  void _startSnapTimer() {
    _snapTimer?.cancel();
    _snapTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (isHost && _inGame) {
        // frame çağrısı GamePage'den gelir
      }
    });
  }

  void leaveRoom() {
    _inGame = false;
    over = false;
    _pingTimer?.cancel();
    _snapTimer?.cancel();
    _socket?.close();
    onPageChange?.call(0);
  }

  void toLobbyAll() {
    // host lobiye dön
    _inGame = false;
    over = false;
    onPageChange?.call(2);
  }

  // Solo mod (tek başına)
  void setSoloDiff(int i) { soloDiff = i.toDouble(); }
  void setSoloCount(int i) { soloCount = i; }
  void setSoloMap(int i) { mapIdx = i; }
  void startSolo() {
    // tek başına oyun
    isHost = true;
    aiMode = true;
    _players.clear();
    _players.add({'name': myName, 'pid': 1, 'char': 0, 'ready': true});
    myPid = 1;
    myRole = 'G';
    // yapay zeka animatronikleri ekle
    for (int i = 0; i < soloCount; i++) {
      final ch = i % CHARS.length;
      _players.add({'name': 'AI$i', 'pid': 1000 + i, 'char': ch, 'ready': true});
    }
    _inGame = true;
    _initGameState();
    onPageChange?.call(3);
  }

  VF vf(int now) {
    // GamePage'den çağrılır
    return _buildVF();
  }

  // ---------------------- YOK ETME ----------------------
  void dispose() {
    _socket?.close();
    _pingTimer?.cancel();
    _snapTimer?.cancel();
  }
}

// --------------------------- SAYFALAR ---------------------------
// Menü Sayfası
class MenuPage extends StatefulWidget {
  const MenuPage({super.key});
  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final TextEditingController _nameCtrl = TextEditingController(text: 'Oyuncu');
  final TextEditingController _ipCtrl = TextEditingController();
  String _status = '';
  final Net _net = Net();

  @override
  void initState() {
    super.initState();
    _net.onPageChange = (page) {
      if (page == 2) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LobbyPage(gs: _net)));
      } else if (page == 3) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => GamePage(gs: _net)));
      } else if (page == 4) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => EndPage(gs: _net)));
      } else if (page == 0) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MenuPage()));
      }
    };
    _net.onError = (e) => setState(() => _status = 'Hata: $e');
  }

  @override
  void dispose() {
    _net.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('DARKESCAS', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Color(0xFFFFB300), letterSpacing: 4)),
            const SizedBox(height: 8),
            const Text('v8 - LAN Asimetrik Korku', style: TextStyle(color: Colors.white54)),
            const SizedBox(height: 40),
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'İsmin', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _net.myName = _nameCtrl.text.trim();
                      _net.createLobby(_net.myName);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E8449)),
                    child: const Text('HOST OL', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _net.myName = _nameCtrl.text.trim();
                      _net.broadcastDiscover();
                      setState(() => _status = 'Aranıyor...');
                      // keşif sonucu lobiye geçiş
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2980B9)),
                    child: const Text('LOBİ ARA', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ipCtrl,
                    decoration: const InputDecoration(labelText: 'IP adresi', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    final ip = _ipCtrl.text.trim();
                    if (ip.isNotEmpty) {
                      _net.myName = _nameCtrl.text.trim();
                      _net.joinLobby(ip, _net.myName);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8E44AD)),
                  child: const Text('KATIL'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _net.myName = _nameCtrl.text.trim();
                _net.startSolo();
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE67E22)),
              child: const Text('TEK BAŞINA OYNA (SOLO)'),
            ),
            const SizedBox(height: 20),
            Text(_status, style: const TextStyle(color: Colors.orange)),
          ],
        ),
      ),
    );
  }
}

// Lobi Sayfası
class LobbyPage extends StatefulWidget {
  final Net gs;
  const LobbyPage({super.key, required this.gs});
  @override
  State<LobbyPage> createState() => _LobbyPageState();
}

class _LobbyPageState extends State<LobbyPage> {
  List<Map<String, dynamic>> players = [];

  @override
  void initState() {
    super.initState();
    widget.gs.onLobbyUpdate = _update;
    _update();
  }

  void _update() {
    setState(() {
      // players = widget.gs._players; // private
    });
  }

  @override
  Widget build(BuildContext context) {
    final isHost = widget.gs.isHost;
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('LOBI', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFFFFB300))),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => widget.gs.leaveRoom(),
                  child: const Text('AYRIL'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Oyuncular:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            Expanded(
              child: ListView.builder(
                itemCount: players.length,
                itemBuilder: (ctx, i) {
                  final p = players[i];
                  return ListTile(
                    title: Text(p['name']),
                    subtitle: Text('Karakter: ${CHARS[p['char'] as int].name}'),
                    trailing: isHost ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {},
                    ) : null,
                  );
                },
              ),
            ),
            if (isHost) ...[
              const Text('Harita:', style: TextStyle(fontWeight: FontWeight.w700)),
              Wrap(
                children: List.generate(MAPS.length, (i) => Padding(
                  padding: const EdgeInsets.all(4),
                  child: ChoiceChip(
                    label: Text(MAPS[i].name),
                    selected: widget.gs.mapIdx == i,
                    onSelected: (_) => widget.gs.setMap(i),
                  ),
                )),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: players.length >= 2 ? widget.gs.startGame : null,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E8449)),
                child: const Text('OYUNU BAŞLAT', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Oyun Sayfası (verilen kodu kullan, sadece Net bağlantısı)
class GamePage extends StatefulWidget {
  final Net gs;
  const GamePage({super.key, required this.gs});
  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  Duration? lastD;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this)..repeat();
    _ctrl.addListener(_tick);
    widget.gs.onVF = (vf) {
      // UI güncellemesi için setState
      if (mounted) setState(() {});
    };
  }

  void _tick() {
    final d = _ctrl.lastElapsedDuration ?? Duration.zero;
    double dt = 0.016;
    if (lastD != null) {
      dt = m.min(0.05, (d - lastD!).inMicroseconds / 1000000);
    }
    lastD = d;
    if (widget.gs.isHost && !widget.gs.over) {
      widget.gs.frame(dt);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gs = widget.gs;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final vf = gs.vf(now);
        return Stack(
          children: [
            Positioned.fill(
              child: Transform.translate(
                offset: Offset(gs.shakeX, gs.shakeY),
                child: gs.myRole == 'G'
                    ? _buildGuard(gs, vf)
                    : _buildAnim(gs, vf, now),
              ),
            ),
            if (vf.blind > 0)
              Positioned.fill(
                child: Container(color: Colors.white.withAlpha((255 * m.min(0.85, vf.blind)).toInt())),
              ),
            if (gs.jsOn)
              Positioned.fill(child: JsOverlay(ch: gs.overJs, t: gs.jsT))
            else if (gs.over)
              Positioned.fill(
                child: Container(
                  color: (gs.overSide == 'anim'
                      ? const Color(0xFFFF2200)
                      : const Color(0xFF22FF88))
                      .withAlpha((255 * (0.12 + 0.1 * m.sin(gs.endDelay * 12).abs())).toInt()),
                ),
              ),
          ],
        );
      },
    );
  }

  // Guard görünümü (verilen kodun _buildGuard'ı)
  Widget _buildGuard(Net gs, VF vf) {
    // vf'den gelen verilerle UI
    final jammed = vf.cam && vf.jam;
    final pulse = 0.6 + 0.4 * m.sin(DateTime.now().millisecondsSinceEpoch / 90);
    return Stack(
      children: [
        Positioned.fill(
          child: vf.cam && !vf.black
              ? CustomPaint(
                  painter: MapP(map: MAPS[gs.mapIdx], vf: vf, camMode: true,
                      myPid: gs.myPid, t: vf.t, jam: jammed))
              : CustomPaint(
                  painter: OfficeP(vf: vf, dlShow: gs.dlShow,
                      drShow: gs.drShow, fanA: gs.fanA, t: DateTime.now().millisecondsSinceEpoch / 1000)),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: NoiseP(seed: DateTime.now().millisecondsSinceEpoch ~/ 60, heavy: vf.cam, jam: jammed),
          ),
        ),
        Positioned.fill(child: const CustomPaint(painter: VignetteP())),
        Positioned(
          top: 8, left: 10, right: 10,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(kHours[vf.hour.clamp(0, 6)],
                      style: const TextStyle(fontSize: 26,
                          fontWeight: FontWeight.w900, color: Colors.white,
                          shadows: [Shadow(blurRadius: 6, color: Colors.black)])),
                  Text(vf.black ? 'KARANLIK!' : 'GECE VARDIYASI',
                      style: TextStyle(fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: vf.black ? Colors.red : const Color(0xFFAAAAEE))),
                ],
              ),
              const Spacer(),
              if (vf.cam)
                Row(children: [
                  Container(width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: (vf.t % 1 < 0.6) ? Colors.red : Colors.transparent,
                      shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text('REC', style: TextStyle(color: Colors.red,
                      fontWeight: FontWeight.w900, fontSize: 12)),
                ]),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('GUC %${vf.power.toInt()}',
                      style: TextStyle(fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: vf.power < 25 ? Colors.red : const Color(0xFF7CFC00))),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < 6; i++)
                        Container(width: 7, height: 13,
                          margin: const EdgeInsets.only(left: 2),
                          color: i < vf.usage
                              ? (vf.usage >= 5 ? Colors.red
                                  : vf.usage >= 3 ? Colors.orange : Colors.green)
                              : const Color(0xFF222233)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        if (vf.forceL > 0 || vf.waitL > 1.5)
          Positioned(top: 66, left: 0, right: 0,
            child: Center(child: Text(
              'SOL KAPI ${vf.forceL > 0 ? 'ZORLANIYOR!' : 'TEHLIKE!'}',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900,
                  color: Colors.red.withAlpha((255 * pulse).toInt()))))),
        if (vf.forceR > 0 || vf.waitR > 1.5)
          Positioned(top: 86, left: 0, right: 0,
            child: Center(child: Text(
              'SAG KAPI ${vf.forceR > 0 ? 'ZORLANIYOR!' : 'TEHLIKE!'}',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900,
                  color: Colors.red.withAlpha((255 * pulse).toInt()))))),
        if (vf.black)
          const Positioned(top: 120, left: 0, right: 0,
            child: Center(child: Text('GUC BITTI - KONTROLLER KILITLENDI',
                style: TextStyle(color: Colors.red,
                    fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2)))),
        if (jammed)
          const Positioned(top: 150, left: 0, right: 0,
            child: Center(child: Text('SINYAL YOK',
                style: TextStyle(color: Color(0xFF66FF66),
                    fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 4)))),
        Positioned(
          bottom: 8, left: 8, right: 8,
          child: Row(
            children: [
              Btn(t: 'SOL KAPI',
                  sub: vf.ddL > 0 ? 'KILIT ${vf.ddL.toStringAsFixed(1)}'
                      : (vf.dl ? 'ACIK' : 'KAPALI'),
                  c: vf.dl ? const Color(0xFF1E8449) : const Color(0xFF922B21),
                  on: vf.black || vf.ddL > 0 ? null : () => gs.gAct('dl')),
              const SizedBox(width: 6),
              Btn(t: 'ISIK', sub: vf.light ? 'ACIK' : 'KAPALI',
                  c: const Color(0xFFB7950B),
                  on: vf.black ? null : () => gs.gAct('li')),
              const SizedBox(width: 6),
              Btn(t: 'KAMERA', sub: vf.cam ? 'ACIK' : 'KAPALI',
                  c: const Color(0xFF1F618D),
                  on: vf.black || (vf.jam && !vf.cam) ? null : () => gs.gAct('cm')),
              const SizedBox(width: 6),
              Btn(t: 'VENT', sub: vf.vent ? 'ACIK' : 'KAPALI',
                  c: const Color(0xFF148F77),
                  on: vf.black ? null : () => gs.gAct('vt')),
              const SizedBox(width: 6),
              Btn(t: 'SAG KAPI',
                  sub: vf.ddR > 0 ? 'KILIT ${vf.ddR.toStringAsFixed(1)}'
                      : (vf.dr ? 'ACIK' : 'KAPALI'),
                  c: vf.dr ? const Color(0xFF1E8449) : const Color(0xFF922B21),
                  on: vf.black || vf.ddR > 0 ? null : () => gs.gAct('dr')),
            ],
          ),
        ),
      ],
    );
  }

  // Animatronik görünümü
  Widget _buildAnim(Net gs, VF vf, int now) {
    VActor? me;
    for (final a in vf.actors) {
      if (a.pid == gs.myPid) { me = a; break; }
    }
    final ctx = gs.ctxLabel(vf);
    final cd = me?.stun ?? 0; // yetenek bekleme yerine stun kullan
    final ci = gs.myChar.clamp(0, CHARS.length - 1);
    final cdMax = CHARS[ci].cd;
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: MapP(map: MAPS[gs.mapIdx], vf: vf,
              camMode: false, myPid: gs.myPid, t: vf.t, jam: false)),
        ),
        Positioned.fill(
          child: CustomPaint(
              painter: NoiseP(seed: now ~/ 90, heavy: false, jam: false)),
        ),
        Positioned.fill(child: const CustomPaint(painter: VignetteP())),
        Positioned(
          top: 8, left: 10, right: 10,
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(kHours[vf.hour.clamp(0, 6)],
                      style: const TextStyle(fontSize: 22,
                          fontWeight: FontWeight.w900, color: Colors.white)),
                  Text(CHARS[ci].name,
                      style: TextStyle(fontSize: 12,
                          fontWeight: FontWeight.w800, color: CHARS[ci].color)),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('GUC %${vf.power.toInt()}',
                      style: TextStyle(fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: vf.power < 25 ? Colors.red : const Color(0xFF7CFC00))),
                  Text('SOL:${vf.dl ? 'ACIK' : 'KAPALI'} SAG:${vf.dr ? 'ACIK' : 'KAPALI'} VENT:${vf.vent ? 'ACIK' : 'KAPALI'}',
                      style: const TextStyle(fontSize: 10, color: Color(0xFFAAAADD))),
                ],
              ),
            ],
          ),
        ),
        if (me != null && me.stun > 0)
          Positioned(top: 0, bottom: 0, left: 0, right: 0,
            child: Center(child: Text(
              'SERSEMLEDIN ${me.stun.toStringAsFixed(1)} sn',
              style: const TextStyle(color: Color(0xFFFFEE55), fontSize: 24,
                  fontWeight: FontWeight.w900,
                  shadows: [Shadow(blurRadius: 10, color: Colors.black)])))),
        Positioned(bottom: 20, left: 16, child: Joy(onVec: gs.sendJoy)),
        Positioned(
          bottom: 24, right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (ctx != null)
                GestureDetector(
                  onTap: gs.doCtx,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC0392B).withAlpha(220),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white54, width: 2)),
                    child: Text(ctx, style: const TextStyle(fontSize: 18,
                        fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: cd <= 0 ? gs.useAbility : null,
                child: SizedBox(
                  width: 86, height: 86,
                  child: Stack(
                    children: [
                      Positioned.fill(child: Container(
                        decoration: BoxDecoration(shape: BoxShape.circle,
                          color: CHARS[ci].color.withAlpha(cd > 0 ? 50 : 190),
                          border: Border.all(color: CHARS[ci].color, width: 2)))),
                      Positioned.fill(child: CustomPaint(
                        painter: ArcP(frac: cdMax > 0 ? cd / cdMax : 0,
                            col: Colors.black.withAlpha(170)))),
                      Center(child: Text(CHARS[ci].active,
                          style: const TextStyle(fontSize: 11,
                              fontWeight: FontWeight.w900, color: Colors.white))),
                      if (cd > 0)
                        Positioned(bottom: 14, left: 0, right: 0,
                          child: Center(child: Text(cd.toStringAsFixed(0),
                              style: const TextStyle(fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white70)))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Son Sayfası
class EndPage extends StatefulWidget {
  final Net gs;
  const EndPage({super.key, required this.gs});
  @override
  State<EndPage> createState() => _EndPageState();
}

class _EndPageState extends State<EndPage> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  bool surpriseOn = false;
  double surpriseT = 0;
  bool surpriseFired = false;
  double waitT = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this)..repeat();
    _ctrl.addListener(_tick);
  }

  void _tick() {
    final gs = widget.gs;
    if (!mounted) return;
    if (!surpriseFired && gs.surprise) {
      waitT += 0.016;
      if (waitT > 1.6) {
        surpriseFired = true;
        surpriseOn = true;
        surpriseT = 0;
        Sfx.screamBurst();
      }
    }
    if (surpriseOn) {
      surpriseT += 0.016;
      if (surpriseT > 1.8) surpriseOn = false;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gs = widget.gs;
    final won = (gs.myRole == 'G' && gs.overSide == 'guard') ||
        (gs.myRole == 'A' && gs.overSide == 'anim');
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (gs.overJs >= 0)
                      SizedBox(height: 170, width: 170,
                        child: CustomPaint(painter: AnimPrev(ch: gs.overJs))),
                    const SizedBox(height: 10),
                    Text(won ? 'KAZANDIN!' : 'YAKALANDIN!',
                        style: TextStyle(fontSize: 40,
                            fontWeight: FontWeight.w900, letterSpacing: 4,
                            color: won ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C))),
                    const SizedBox(height: 10),
                    Text(gs.overReason, textAlign: TextAlign.center, style: kTxt),
                    const SizedBox(height: 8),
                    Text(gs.myRole == 'G' ? 'Rol: GUVERDIN'
                        : 'Rol: ${CHARS[gs.myChar.clamp(0, CHARS.length - 1)].name}',
                        style: kSmall),
                    if (gs.surprise && surpriseFired)
                      const Padding(padding: EdgeInsets.only(top: 10),
                        child: Text('SENI GORUYORUZ...',
                            style: TextStyle(color: Color(0xFFFF3333),
                                fontWeight: FontWeight.w900, letterSpacing: 3))),
                    const SizedBox(height: 26),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (gs.isHost && !gs.aiMode)
                          Btn(t: 'LOBIYE DON', sub: 'revans',
                              on: () => gs.toLobbyAll(), expand: false,
                              c: const Color(0xFF1F618D)),
                        if (gs.isHost && !gs.aiMode) const SizedBox(width: 10),
                        Btn(t: 'ANA MENU', on: () => gs.leaveRoom(),
                            expand: false, c: const Color(0xFF555577)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (surpriseOn)
              Positioned.fill(
                child: Container(
                  color: Colors.black,
                  child: Stack(
                    children: [
                      Positioned.fill(child: CustomPaint(
                        painter: NoiseP(seed: (surpriseT * 60).toInt(),
                            heavy: true, jam: true))),
                      Center(child: Transform.scale(
                        scale: 0.6 + surpriseT * 1.4,
                        child: CustomPaint(size: const Size(300, 300),
                            painter: AnimPrev(ch: 11)))),
                      Positioned.fill(child: Container(
                        color: Colors.red.withAlpha((255 * (0.25 + 0.2 * m.sin(surpriseT * 40).abs())).toInt()))),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// --------------------------- JOYSTICK ---------------------------
class Joy extends StatefulWidget {
  final void Function(double, double) onVec;
  const Joy({super.key, required this.onVec});
  @override
  State<Joy> createState() => _JoyState();
}

class _JoyState extends State<Joy> {
  Offset v = Offset.zero;
  static const double rad = 58.0;
  static const double size = 164.0;

  void set(Offset local) {
    final c = Offset(size / 2, size / 2);
    Offset d = local - c;
    final l = d.distance;
    if (l > rad) d = d * (rad / l);
    setState(() => v = d);
    widget.onVec(d.dx / rad, d.dy / rad);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) => set(d.localPosition),
      onPanUpdate: (d) => set(d.localPosition),
      onPanEnd: (d) {
        setState(() => v = Offset.zero);
        widget.onVec(0, 0);
      },
      child: SizedBox(width: size, height: size,
        child: CustomPaint(painter: JoyP(v: v, rad: rad))),
    );
  }
}

class JoyP extends CustomPainter {
  final Offset v;
  final double rad;
  JoyP({required this.v, required this.rad});
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(c, rad + 14, Paint()..color = const Color(0xFF11112A).withAlpha(190));
    canvas.drawCircle(c, rad + 14, Paint()
      ..style = PaintingStyle.stroke..strokeWidth = 2
      ..color = const Color(0xFF4444AA).withAlpha(200));
    canvas.drawCircle(c, 4, Paint()..color = const Color(0xFF4444AA));
    canvas.drawCircle(c + v, 26, Paint()..color = const Color(0xFF8866FF).withAlpha(230));
    canvas.drawCircle(c + v, 26, Paint()
      ..style = PaintingStyle.stroke..strokeWidth = 2..color = Colors.white54);
  }

  @override
  bool shouldRepaint(JoyP old) => old.v != v;
}

// --------------------------- DİĞER PAINTER'LAR ---------------------------
class ArcP extends CustomPainter {
  final double frac;
  final Color col;
  ArcP({required this.frac, required this.col});
  @override
  void paint(Canvas canvas, Size size) {
    if (frac <= 0) return;
    final r = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.width / 2);
    canvas.drawArc(r, -m.pi / 2, frac * 2 * m.pi, true, Paint()..color = col);
  }

  @override
  bool shouldRepaint(ArcP old) => old.frac != frac;
}

class JsOverlay extends StatelessWidget {
  final int ch;
  final double t;
  const JsOverlay({super.key, required this.ch, required this.t});
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: JsP(ch: ch, t: t), size: Size.infinite);
  }
}

class JsP extends CustomPainter {
  final int ch;
  final double t;
  JsP({required this.ch, required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final r = m.Random((t * 60).toInt());
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black);
    final pulse = 0.14 + 0.12 * m.sin(t * 40).abs();
    canvas.drawRect(Offset.zero & size,
        Paint()..color = const Color(0xFFFF0000).withAlpha((255 * pulse).toInt()));
    final p = m.min(1.0, t / 1.7);
    final scale = 0.25 + 1.25 * p * p;
    final s = size.shortestSide * 0.85 * scale;
    final jx = (r.nextDouble() * 2 - 1) * 18;
    final jy = (r.nextDouble() * 2 - 1) * 18;
    final center = Offset(size.width / 2 + jx, size.height / 2 + jy + s * 0.05);
    drawAnimatronic(canvas, center, s, ch.clamp(0, CHARS.length - 1), t, scream: true);
    for (int i = 0; i < 10; i++) {
      final ang = r.nextDouble() * 2 * m.pi;
      final rr = size.shortestSide * (0.5 + r.nextDouble() * 0.3);
      final p1 = center + Offset(m.cos(ang), m.sin(ang)) * rr;
      final p2 = center + Offset(m.cos(ang), m.sin(ang)) * (rr + 60);
      canvas.drawLine(p1, p2, Paint()..color = Colors.white.withAlpha(30)..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(JsP old) => true;
}

// drawAnimatronic - verilen koddan aynen
void drawAnimatronic(Canvas canvas, Offset o, double s, int ch, double t,
    {bool dark = false, bool scream = false}) {
  final cd = CHARS[ch.clamp(0, CHARS.length - 1)];
  final Color body = dark ? const Color(0xFF0A0A10) : cd.color;
  final Color body2 = dark
      ? const Color(0xFF0A0A10)
      : Color.lerp(cd.color, Colors.black, 0.35)!;
  final Color eye = dark
      ? const Color(0xFFFFFFFF)
      : (ch == 5 ? const Color(0xFFFFF6B0) : const Color(0xFFEAF7FF));
  final glow = Paint()
    ..color = cd.color.withAlpha(dark ? 60 : 130)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
  canvas.drawCircle(o, s * 0.52, glow);
  if (ch == 0) {
    for (final dir in [-1.0, 1.0]) {
      final flap = m.sin(t * 7) * 0.25;
      final wing = Path()
        ..moveTo(o.dx + dir * s * 0.22, o.dy + s * 0.18)
        ..quadraticBezierTo(o.dx + dir * s * (0.72 + flap), o.dy - s * 0.1,
            o.dx + dir * s * 0.55, o.dy + s * 0.42)
        ..quadraticBezierTo(o.dx + dir * s * 0.3, o.dy + s * 0.4,
            o.dx + dir * s * 0.22, o.dy + s * 0.18)
        ..close();
      final wc = dark ? const Color(0xFF0A0A10) : const Color(0xFF873600);
      canvas.drawPath(wing, Paint()..color = wc.withAlpha(245));
    }
  }
  if (ch == 10) {
    for (int i = 0; i < 3; i++) {
      final cen = Offset(o.dx + (i - 1) * s * 0.16, o.dy + s * (0.52 + i * 0.05));
      canvas.drawOval(
        Rect.fromCenter(center: cen, width: s * 0.3, height: s * 0.16),
        Paint()..color = body.withAlpha(60));
    }
  }
  canvas.drawOval(
    Rect.fromCenter(center: Offset(o.dx, o.dy + s * 0.32),
        width: s * 0.6, height: s * 0.52),
    Paint()..color = body2);
  final inner = dark
      ? const Color(0xFF0A0A10)
      : Color.lerp(cd.color, Colors.white, 0.25)!;
  canvas.drawOval(
    Rect.fromCenter(center: Offset(o.dx, o.dy + s * 0.34),
        width: s * 0.34, height: s * 0.3),
    Paint()..color = inner);
  if (ch == 2) {
    for (final dir in [-1.0, 1.0]) {
      final ec = Offset(o.dx + dir * s * 0.26, o.dy - s * 0.42);
      canvas.drawCircle(ec, s * 0.16, Paint()..color = body);
      final ic = dark ? const Color(0xFF0A0A10) : const Color(0xFFE8A0B4);
      canvas.drawCircle(ec, s * 0.08, Paint()..color = ic);
    }
  }
  if (ch == 7) {
    for (int i = 0; i < 5; i++) {
      final ang = -m.pi * 0.85 + i * (m.pi * 0.7 / 4);
      final p1 = Offset(o.dx + m.cos(ang) * s * 0.3, o.dy - s * 0.18 + m.sin(ang) * s * 0.3);
      final p2 = Offset(o.dx + m.cos(ang) * s * 0.46, o.dy - s * 0.18 + m.sin(ang) * s * 0.46);
      final p3 = Offset(o.dx + m.cos(ang + 0.25) * s * 0.3, o.dy - s * 0.18 + m.sin(ang + 0.25) * s * 0.3);
      canvas.drawPath(
        Path()..moveTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy)..lineTo(p3.dx, p3.dy)..close(),
        Paint()..color = body);
    }
  }
  if (ch == 11) {
    final hatR = Rect.fromCenter(center: Offset(o.dx, o.dy - s * 0.34),
        width: s * 0.5, height: s * 0.4);
    final hatC = dark ? const Color(0xFF0A0A10) : const Color(0xFF641E16);
    canvas.drawArc(hatR, m.pi * 0.95, m.pi * 1.1, false, Paint()
      ..style = PaintingStyle.stroke..strokeWidth = s * 0.09..color = hatC);
    canvas.drawCircle(Offset(o.dx + s * 0.05, o.dy - s * 0.52), s * 0.07,
        Paint()..color = Colors.white.withAlpha(dark ? 100 : 255));
  }
  canvas.drawOval(
    Rect.fromCenter(center: Offset(o.dx, o.dy - s * 0.16),
        width: s * 0.56, height: s * 0.5),
    Paint()..color = body);
  if (ch == 4) {
    canvas.drawLine(Offset(o.dx, o.dy - s * 0.4), Offset(o.dx, o.dy - s * 0.62),
        Paint()..color = body2..strokeWidth = s * 0.03);
    final blink = (t % 0.8) < 0.4;
    final ac = blink ? const Color(0xFF2ECC71) : const Color(0xFF145A32);
    canvas.drawCircle(Offset(o.dx, o.dy - s * 0.64), s * 0.045, Paint()
      ..color = ac..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
  }
  if (ch == 5) {
    final halo = Paint()
      ..color = const Color(0xFFFFF6B0).withAlpha(130)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.03
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(o.dx, o.dy - s * 0.1), s * 0.46, halo);
  }
  final blink = (t % 3.1) < 0.12 && !scream;
  for (final dir in [-1.0, 1.0]) {
    final ec = Offset(o.dx + dir * s * 0.12, o.dy - s * 0.2);
    if (blink) {
      canvas.drawLine(ec - Offset(s * 0.05, 0), ec + Offset(s * 0.05, 0),
          Paint()..color = eye..strokeWidth = s * 0.02);
    } else {
      canvas.drawCircle(ec, s * (scream ? 0.085 : 0.06), Paint()
        ..color = eye..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
      canvas.drawCircle(ec, s * 0.025, Paint()..color = Colors.black);
    }
  }
  final mouthW = scream ? 0.4 : 0.22;
  final mouthH = scream ? 0.3 : 0.1;
  canvas.drawOval(
    Rect.fromCenter(center: Offset(o.dx, o.dy - s * 0.02),
        width: s * mouthW, height: s * mouthH),
    Paint()..color = const Color(0xFF12040A));
  if (scream || ch == 3 || ch == 7 || ch == 0) {
    final mw = s * mouthW;
    for (int i = 0; i < 5; i++) {
      final tx = o.dx - mw / 2 + mw * (i + 0.5) / 5;
      final ty = o.dy - s * 0.02 - s * mouthH / 2;
      canvas.drawPath(
        Path()..moveTo(tx - s * 0.02, ty)..lineTo(tx + s * 0.02, ty)
            ..lineTo(tx, ty + s * 0.05)..close(),
        Paint()..color = const Color(0xFFE8E8E8));
    }
  }
  canvas.drawOval(
    Rect.fromCenter(center: Offset(o.dx - s * 0.13, o.dy + s * 0.58),
        width: s * 0.18, height: s * 0.09),
    Paint()..color = body2);
  canvas.drawOval(
    Rect.fromCenter(center: Offset(o.dx + s * 0.13, o.dy + s * 0.58),
        width: s * 0.18, height: s * 0.09),
    Paint()..color = body2);
}

class AnimPrev extends CustomPainter {
  final int ch;
  AnimPrev({required this.ch});
  @override
  void paint(Canvas canvas, Size size) {
    drawAnimatronic(canvas, Offset(size.width / 2, size.height * 0.52),
        size.height * 0.72, ch, 1.2);
  }

  @override
  bool shouldRepaint(AnimPrev old) => old.ch != ch;
}

// OfficeP, MapP, NoiseP, VignetteP - verilen koddan aynen (kısaltılmış)
class OfficeP extends CustomPainter {
  final VF vf;
  final double dlShow;
  final double drShow;
  final double fanA;
  final double t;
  OfficeP({required this.vf, required this.dlShow, required this.drShow,
      required this.fanA, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final horizon = h * 0.62;
    final r = m.Random((t * 20).toInt());
    final wallR = Rect.fromLTWH(0, 0, w, horizon);
    canvas.drawRect(wallR, Paint()
      ..shader = const LinearGradient(begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1B1030), Color(0xFF0C0716)]).createShader(wallR));
    final floorR = Rect.fromLTWH(0, horizon, w, h - horizon);
    canvas.drawRect(floorR, Paint()
      ..shader = const LinearGradient(begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF171021), Color(0xFF040207)]).createShader(floorR));
    final tile = Paint()..color = Colors.white.withAlpha(8)..strokeWidth = 1;
    for (int i = 1; i < 12; i++) {
      canvas.drawLine(Offset(w * i / 12, 0), Offset(w * i / 12, horizon), tile);
    }
    final flick = vf.black ? 0.0 : (0.8 + 0.15 * m.sin(t * 13) + 0.05 * r.nextDouble());
    final lampX = w * 0.5;
    canvas.drawLine(Offset(lampX, 0), Offset(lampX, h * 0.07),
        Paint()..color = const Color(0xFF333344)..strokeWidth = 3);
    if (!vf.black) {
      final cone = Path()
        ..moveTo(lampX - w * 0.03, h * 0.075)
        ..lineTo(lampX + w * 0.03, h * 0.075)
        ..lineTo(lampX + w * 0.22, h * 0.95)
        ..lineTo(lampX - w * 0.22, h * 0.95)
        ..close();
      final coneC = [const Color(0xFFFFE9A0).withAlpha((255 * 0.10 * flick).toInt()), const Color(0xFFFFE9A0).withAlpha(0)];
      canvas.drawPath(cone, Paint()
        ..shader = LinearGradient(begin: Alignment.topCenter,
            end: Alignment.bottomCenter, colors: coneC)
            .createShader(Rect.fromLTWH(0, 0, w, h)));
      canvas.drawOval(
        Rect.fromCenter(center: Offset(lampX, h * 0.078),
            width: w * 0.05, height: h * 0.014),
        Paint()..color = const Color(0xFFFFE9A0).withAlpha((255 * 0.9 * flick).toInt())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    }
    _poster(canvas, Rect.fromLTWH(w * 0.205, h * 0.14, w * 0.1, h * 0.17), 0);
    _poster(canvas, Rect.fromLTWH(w * 0.695, h * 0.14, w * 0.1, h * 0.17), 11);
    _doorway(canvas, size, true, 1 - dlShow);
    _doorway(canvas, size, false, 1 - drShow);
    final deskTop = h * 0.8;
    final desk = Path()
      ..moveTo(w * 0.28, h * 0.99)..lineTo(w * 0.36, deskTop)
      ..lineTo(w * 0.64, deskTop)..lineTo(w * 0.72, h * 0.99)..close();
    const deskC = [Color(0xFF3A2A1C), Color(0xFF1D130B)];
    canvas.drawPath(desk, Paint()
      ..shader = const LinearGradient(begin: Alignment.topCenter,
          end: Alignment.bottomCenter, colors: deskC)
          .createShader(Rect.fromLTWH(0, deskTop, w, h * 0.2)));
    final monW = w * 0.15;
    final monR = Rect.fromCenter(center: Offset(w * 0.44, h * 0.7),
        width: monW, height: h * 0.15);
    canvas.drawRRect(RRect.fromRectAndRadius(monR.inflate(4), const Radius.circular(6)),
        Paint()..color = const Color(0xFF14141E));
    final monCol = vf.black ? const Color(0xFF050508) : const Color(0xFF062511);
    canvas.drawRRect(RRect.fromRectAndRadius(monR, const Radius.circular(4)),
        Paint()..color = monCol);
    if (!vf.black) {
      for (int i = 0; i < 8; i++) {
        final y = monR.top + 6 + i * (monR.height - 12) / 8;
        canvas.drawLine(Offset(monR.left + 4, y), Offset(monR.right - 4, y),
            Paint()..color = const Color(0xFF1DFF6E).withAlpha(36));
      }
      if ((t % 1) < 0.5) {
        canvas.drawRect(Rect.fromLTWH(monR.center.dx + monW * 0.3, monR.top + 6, 4, 8),
            Paint()..color = const Color(0xFF57FF8F));
      }
    }
    canvas.drawRect(Rect.fromLTWH(monR.center.dx - 5, monR.bottom + 4, 10, h * 0.045),
        Paint()..color = const Color(0xFF14141E));
    final fx = w * 0.62;
    final fy = h * 0.72;
    final fr = h * 0.05;
    canvas.drawRect(Rect.fromLTWH(fx - fr * 0.2, fy + fr, fr * 0.4, h * 0.05),
        Paint()..color = const Color(0xFF222230));
    canvas.save();
    canvas.translate(fx, fy);
    canvas.rotate(fanA);
    for (int i = 0; i < 3; i++) {
      canvas.rotate(2 * m.pi / 3);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(fr * 0.45, 0),
            width: fr * 0.85, height: fr * 0.3),
        Paint()..color = const Color(0xFF8899AA).withAlpha(vf.black ? 60 : 200));
    }
    canvas.restore();
    canvas.drawCircle(Offset(fx, fy), fr, Paint()
      ..style = PaintingStyle.stroke..strokeWidth = 2.5
      ..color = const Color(0xFF556677));
    canvas.drawCircle(Offset(fx, fy), fr * 0.16, Paint()..color = const Color(0xFF334455));
    if (vf.black) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = Colors.black.withAlpha((255 * (0.86 + 0.04 * m.sin(t * 3))).toInt()));
      if (vf.thL >= 0 || vf.thR >= 0) {
        if (r.nextDouble() < 0.4) {
          final side = vf.thL >= 0 ? -1.0 : 1.0;
          final ex = w * 0.5 + side * w * 0.4;
          for (final d2 in [-1.0, 1.0]) {
            canvas.drawCircle(Offset(ex + d2 * w * 0.012, h * 0.45), 3, Paint()
              ..color = Colors.white.withAlpha(200)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
          }
        }
      }
    }
  }

  void _poster(Canvas canvas, Rect r2, int ch) {
    canvas.drawRect(r2, Paint()..color = const Color(0xFF241A33));
    canvas.drawRect(r2.deflate(3), Paint()..color = const Color(0xFF31204A));
    final c = Offset(r2.center.dx, r2.center.dy - r2.height * 0.1);
    final s = r2.height * 0.5;
    canvas.drawCircle(Offset(c.dx - s * 0.22, c.dy - s * 0.3), s * 0.14,
        Paint()..color = CHARS[ch].color.withAlpha(230));
    canvas.drawCircle(Offset(c.dx + s * 0.22, c.dy - s * 0.3), s * 0.14,
        Paint()..color = CHARS[ch].color.withAlpha(230));
    canvas.drawOval(Rect.fromCenter(center: c, width: s * 0.7, height: s * 0.6),
        Paint()..color = CHARS[ch].color);
    for (final d2 in [-1.0, 1.0]) {
      canvas.drawCircle(Offset(c.dx + d2 * s * 0.14, c.dy - s * 0.05), s * 0.06,
          Paint()..color = Colors.white);
    }
  }

  void _doorway(Canvas canvas, Size size, bool left, double closedFrac) {
    final w = size.width;
    final h = size.height;
    final opW = w * 0.145;
    final opH = h * 0.6;
    final x0 = left ? w * 0.03 : w - w * 0.03 - opW;
    final op = Rect.fromLTWH(x0, h * 0.16, opW, opH);
    canvas.drawRect(op.inflate(6), Paint()..color = const Color(0xFF2A2438));
    const doorC = [Color(0xFF02020A), Color(0xFF000000)];
    canvas.drawRect(op, Paint()
      ..shader = const LinearGradient(begin: Alignment.topCenter,
          end: Alignment.bottomCenter, colors: doorC).createShader(op));
    final threat = left ? vf.thL : vf.thR;
    final wait = left ? vf.waitL : vf.waitR;
    if (vf.light && !vf.black) {
      final lightC = [const Color(0xFFFFE9A0).withAlpha(5), const Color(0xFFFFE9A0).withAlpha(50)];
      canvas.drawRect(op, Paint()
        ..shader = LinearGradient(begin: Alignment.topCenter,
            end: Alignment.bottomCenter, colors: lightC).createShader(op));
      if (threat >= 0) {
        drawAnimatronic(canvas, Offset(op.center.dx, op.bottom - opH * 0.32),
            opH * 0.62, threat, t, dark: true);
      }
    }
    if (wait > 0.5 && closedFrac < 0.5) {
      final a = (wait / 5).clamp(0.0, 1.0) * (0.35 + 0.3 * m.sin(t * 8).abs());
      canvas.drawRect(op.inflate(5), Paint()
        ..style = PaintingStyle.stroke..strokeWidth = 4..color = Colors.red.withAlpha((255 * a).toInt()));
    }
    if (closedFrac > 0.02) {
      final ph = opH * closedFrac;
      final panel = Rect.fromLTWH(op.left, op.top, opW, ph);
      const panelC = [Color(0xFF39424F), Color(0xFF697786), Color(0xFF39424F)];
      canvas.drawRect(panel, Paint()
        ..shader = const LinearGradient(begin: Alignment.centerLeft,
            end: Alignment.centerRight, colors: panelC).createShader(panel));
      for (int i = 0; i < 6; i++) {
        final y = op.top + ph * i / 6;
        canvas.drawLine(Offset(op.left, y), Offset(op.right, y),
            Paint()..color = Colors.black.withAlpha(60)..strokeWidth = 1.5);
      }
      final by = op.top + ph;
      const seg = 12.0;
      for (double sx = op.left; sx < op.right; sx += seg) {
        final idx = ((sx - op.left) / seg).toInt();
        final sw = m.min(seg, op.right - sx);
        final col = idx.isEven ? const Color(0xFFE8B93C) : const Color(0xFF141414);
        canvas.drawRect(Rect.fromLTWH(sx, by - 8, sw, 8), Paint()..color = col);
      }
    }
    final lampC = Offset(left ? op.right + 10 : op.left - 10, op.top - 8);
    final lampCol = closedFrac > 0.5 ? const Color(0xFFFF3B3B) : const Color(0xFF3BFF6E);
    canvas.drawCircle(lampC, 5, Paint()
      ..color = lampCol..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
  }

  @override
  bool shouldRepaint(OfficeP old) => true;
}

class MapP extends CustomPainter {
  final GameMap map;
  final VF vf;
  final bool camMode;
  final bool jam;
  final int myPid;
  final double t;
  MapP({required this.map, required this.vf, required this.camMode,
      required this.myPid, required this.t, required this.jam});

  Offset sc(Offset c, Offset p, double s) {
    return c + Offset((p.dx - 500) * s, (p.dy - 500) * s);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bg = camMode ? const Color(0xFF020A06) : const Color(0xFF070711);
    canvas.drawRect(Offset.zero & size, Paint()..color = bg);
    final s = m.min(size.width, size.height) / 1000 * 0.92;
    final c = Offset(size.width / 2, size.height / 2);
    final pos = <String, Offset>{};
    for (final n in map.nodes) {
      pos[n.id] = sc(c, Offset(n.x, n.y), s);
    }
    final corridor = Paint()..style = PaintingStyle.stroke
      ..strokeWidth = 86 * s..strokeCap = StrokeCap.round
      ..color = camMode ? const Color(0xFF0A2617) : const Color(0xFF161B2C);
    final corridorIn = Paint()..style = PaintingStyle.stroke
      ..strokeWidth = 62 * s..strokeCap = StrokeCap.round
      ..color = camMode ? const Color(0xFF10381F) : const Color(0xFF232B47);
    for (final e in map.edges) {
      if (e.kind == 'vent') continue;
      final p1 = pos[e.a]!;
      final p2 = pos[e.b]!;
      if (e.kind.isEmpty) {
        canvas.drawLine(p1, p2, corridor);
        canvas.drawLine(p1, p2, corridorIn);
      }
    }
    for (final e in map.edges) {
      if (e.kind.isEmpty) continue;
      final p1 = pos[e.a]!;
      final p2 = pos[e.b]!;
      if (e.kind == 'vent') {
        final open = vf.vent;
        final dashP = _dash(Path()..moveTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy), 14 * s);
        final vc = open ? const Color(0xFF1ABC9C) : const Color(0xFF922B21);
        canvas.drawPath(dashP, Paint()
          ..style = PaintingStyle.stroke..strokeWidth = 20 * s
          ..strokeCap = StrokeCap.round..color = vc.withAlpha(camMode ? 200 : 255));
        final mid = (p1 + p2) / 2;
        if (!open) {
          canvas.drawLine(mid + Offset(-12 * s, -12 * s), mid + Offset(12 * s, 12 * s),
              Paint()..color = Colors.red..strokeWidth = 3);
          canvas.drawLine(mid + Offset(12 * s, -12 * s), mid + Offset(-12 * s, 12 * s),
              Paint()..color = Colors.red..strokeWidth = 3);
        }
        continue;
      }
      final open = e.kind == 'doorL' ? vf.dl : vf.dr;
      final dir = (p2 - p1);
      final doorMid = p1 + dir * 0.72;
      final dc = open ? const Color(0xFF1E8449) : const Color(0xFF922B21);
      canvas.drawLine(p1, p2, Paint()
        ..style = PaintingStyle.stroke..strokeWidth = 40 * s
        ..strokeCap = StrokeCap.round..color = dc.withAlpha(camMode ? 180 : 240));
      final perp = Offset(-dir.dy, dir.dx);
      final pl = perp / (m.sqrt(perp.dx * perp.dx + perp.dy * perp.dy) + 0.0001);
      final barCol = open ? const Color(0xFF7CFC00) : const Color(0xFFFF4C4C);
      canvas.drawLine(doorMid - pl * 34 * s, doorMid + pl * 34 * s,
          Paint()..color = barCol..strokeWidth = 7 * s);
    }
    final o = pos['O']!;
    final offR = Rect.fromCircle(center: o, radius: 74 * s);
    final offCol = camMode ? const Color(0xFF0E3B22) : const Color(0xFF2C2450);
    canvas.drawRRect(RRect.fromRectAndRadius(offR, Radius.circular(18 * s)),
        Paint()..color = offCol);
    canvas.drawRRect(RRect.fromRectAndRadius(offR, Radius.circular(18 * s)),
        Paint()..style = PaintingStyle.stroke..strokeWidth = 3
          ..color = const Color(0xFFF1C40F).withAlpha(180));
    for (final n in map.nodes) {
      if (n.id == 'O') continue;
      final p = pos[n.id]!;
      final nc = camMode ? const Color(0xFF0F3320) : const Color(0xFF2A3355);
      canvas.drawCircle(p, 40 * s, Paint()..color = nc);
    }
    for (final z in vf.noise) {
      final p = pos[z.o];
      if (p == null) continue;
      final pl = (0.6 + 0.4 * m.sin(t * 6)).clamp(0.0, 1.0);
      canvas.drawCircle(p, 26 * s * (0.8 + 0.3 * pl),
          Paint()..color = const Color(0xFFF1C40F).withAlpha((255 * 0.25 * pl).toInt()));
    }
    if (!jam) {
      for (final a in vf.actors) {
        if (camMode && (a.hd || a.iv)) continue;
        final p = sc(c, Offset(a.x, a.y), s);
        final col = CHARS[a.ch.clamp(0, CHARS.length - 1)].color;
        canvas.drawCircle(p, 20 * s, Paint()
          ..color = col.withAlpha(130)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
        canvas.drawCircle(p, 14 * s, Paint()..color = col);
        canvas.drawCircle(p, 14 * s, Paint()
          ..style = PaintingStyle.stroke..strokeWidth = 2..color = Colors.white.withAlpha(180));
        if (a.pid == myPid) {
          canvas.drawCircle(p, 22 * s, Paint()
            ..style = PaintingStyle.stroke..strokeWidth = 2.5..color = Colors.white);
        }
        if (a.stun > 0) {
          final rr = 24 * s;
          for (int i = 0; i < 3; i++) {
            final ang = t * 4 + i * 2 * m.pi / 3;
            canvas.drawCircle(p + Offset(m.cos(ang), m.sin(ang)) * rr, 3.5,
                Paint()..color = const Color(0xFFFFEE55));
          }
        }
        if (a.wait > 0.3) {
          canvas.drawArc(Rect.fromCircle(center: p, radius: 26 * s), -m.pi / 2,
              (a.wait / 5).clamp(0.0, 1.0) * 2 * m.pi, false, Paint()
                ..style = PaintingStyle.stroke..strokeWidth = 4
                ..color = Colors.red.withAlpha(230));
        }
      }
    }
    if (camMode) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = const Color(0xFF00FF66).withAlpha(13));
    }
  }

  Path _dash(Path p, double dl) {
    final out = Path();
    for (final met in p.computeMetrics()) {
      double dist = 0;
      while (dist < met.length) {
        final end = m.min(dist + dl, met.length);
        out.addPath(met.extractPath(dist, end), Offset.zero);
        dist = end + dl;
      }
    }
    return out;
  }

  @override
  bool shouldRepaint(MapP old) => true;
}

class NoiseP extends CustomPainter {
  final int seed;
  final bool heavy;
  final bool jam;
  NoiseP({required this.seed, required this.heavy, required this.jam});
  @override
  void paint(Canvas canvas, Size size) {
    final r = m.Random(seed);
    final level = jam ? 3 : (heavy ? 1 : 0);
    final dens = [2600.0, 900.0, 260.0][level];
    final n = (size.width * size.height / dens).toInt();
    final white = Paint();
    for (int i = 0; i < n; i++) {
      final a = r.nextDouble() * (jam ? 0.4 : (heavy ? 0.2 : 0.07));
      white.color = Colors.white.withAlpha((255 * a).toInt());
      final sw = r.nextDouble() * 2.2 + 0.6;
      final double sh = r.nextDouble() < 0.12 ? 2.0 : 1.0;
      canvas.drawRect(Rect.fromLTWH(r.nextDouble() * size.width,
          r.nextDouble() * size.height, sw, sh), white);
    }
    final scan = Paint()..color = Colors.black.withAlpha(jam ? 40 : 15);
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), scan);
    }
    if (jam || (heavy && r.nextDouble() < 0.35)) {
      final by = r.nextDouble() * size.height;
      final bh = 6 + r.nextDouble() * 26;
      canvas.drawRect(Rect.fromLTWH(0, by, size.width, bh),
          Paint()..color = Colors.white.withAlpha(20));
    }
  }

  @override
  bool shouldRepaint(NoiseP old) => old.seed != seed;
}

class VignetteP extends CustomPainter {
  const VignetteP();
  @override
  void paint(Canvas canvas, Size size) {
    final r2 = Rect.fromCircle(center: Offset(size.width / 2, size.height / 2),
        radius: size.longestSide * 0.72);
    final grad = RadialGradient(colors: [
      Colors.transparent, Colors.black.withAlpha(140), Colors.black.withAlpha(220)
    ], stops: const [0.55, 0.85, 1.0]);
    canvas.drawRect(Offset.zero & size, Paint()..shader = grad.createShader(r2));
  }

  @override
  bool shouldRepaint(VignetteP old) => false;
}
