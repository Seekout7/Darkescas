// ============================================================
// GECE VARDIYASI - LAN uzerinden asimetrik korku oyunu
// TEK DOSYA main.dart - dis paket YOK (sadece Flutter SDK).
// 1 Guvenlik vs 1-3 Animatronik, ayni Wi-Fi (UDP broadcast).
// ============================================================
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as m;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  runApp(const MyApp());
}

// ------------------------------------------------------------
// KUCUK YARDIMCILAR
// ------------------------------------------------------------
extension ColorAl on Color {
  Color al(double o) => withOpacity(o.clamp(0.0, 1.0));
}

const kTxt = TextStyle(color: Colors.white70, fontSize: 13, height: 1.35);
const kSmall = TextStyle(
    color: Color(0xFFAAAADD),
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 1);
const kHours = ['12 GECE', '01:00', '02:00', '03:00', '04:00', '05:00', '06:00'];

// Ses: dis paket kullanilamadigi icin gercek ses dosyasi
// caliniyor degil; sistem sesleri + guclu titresim (haptics) ile
// "iyice yuksek" hissi verilir. Gercek muzik/SFX icin projeye
// audioplayers gibi bir paket eklenmesi gerekir (bu dosyada YOK).
class Sfx {
  static void click() {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.selectionClick();
  }

  static void doorToggle() {
    SystemSound.play(SystemSoundType.click);
    HapticFeedback.mediumImpact();
  }

  static void tick() => HapticFeedback.lightImpact();

  static void danger() {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.click);
  }

  static void jumpscare() {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.click);
  }

  static void screamBurst() {
    jumpscare();
    Future.delayed(const Duration(milliseconds: 110), HapticFeedback.heavyImpact);
    Future.delayed(const Duration(milliseconds: 230), HapticFeedback.heavyImpact);
    Future.delayed(const Duration(milliseconds: 400), HapticFeedback.heavyImpact);
  }
}

// ------------------------------------------------------------
// UI PARCACIKLARI
// ------------------------------------------------------------
class Btn extends StatelessWidget {
  final String t;
  final String? sub;
  final VoidCallback? on;
  final Color c;
  final bool expand;
  const Btn(
      {super.key,
      required this.t,
      this.sub,
      required this.on,
      this.c = const Color(0xFF3355AA),
      this.expand = true});
  @override
  Widget build(BuildContext context) {
    final active = on != null;
    final w = GestureDetector(
      onTap: active
          ? () {
              Sfx.click();
              on!();
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: active ? c.al(0.88) : c.al(0.22),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.al(active ? 0.4 : 0.12)),
          boxShadow: active
              ? [BoxShadow(color: c.al(0.5), blurRadius: 10, spreadRadius: 1)]
              : [],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: active ? Colors.white : Colors.white38,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 0.5)),
            if (sub != null)
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(sub!,
                    style: TextStyle(
                        color: active ? Colors.white70 : Colors.white24,
                        fontSize: 10)),
              ),
          ],
        ),
      ),
    );
    return expand ? Expanded(child: w) : w;
  }
}

Widget chip(String label, Color c, {bool on = false}) {
  return AnimatedContainer(
    duration: const Duration(milliseconds: 120),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
    decoration: BoxDecoration(
      color: on ? c : c.al(0.14),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: on ? Colors.white : c.al(0.5), width: on ? 2 : 1),
      boxShadow: on ? [BoxShadow(color: c.al(0.6), blurRadius: 8)] : [],
    ),
    child: Text(label,
        style: TextStyle(
            color: on ? Colors.white : c,
            fontWeight: FontWeight.w900,
            fontSize: 12,
            letterSpacing: 1)),
  );
}

// ------------------------------------------------------------
// KARAKTERLER
// ------------------------------------------------------------
class CharDef {
  final String name;
  final Color color;
  final double speed; // hiz carpani
  final double cd; // yetenek bekleme (sn)
  final String active; // aktif yetenek adi
  final String passive; // pasif tip: speed/ghost/vent/door/quiet/light/none
  const CharDef(this.name, this.color, this.speed, this.cd, this.active, this.passive);
}

const List<CharDef> CHARS = [
  CharDef('Kanat', Color(0xFFFF8A3D), 1.15, 14, 'HIZ PATLAMASI', 'speed'),
  CharDef('Golge', Color(0xFF6C3483), 1.0, 16, 'GORUNMEZ OL', 'ghost'),
  CharDef('Fare', Color(0xFFE8A0B4), 1.35, 10, 'VENT HIZLAN', 'vent'),
  CharDef('Kas', Color(0xFF922B21), 0.9, 18, 'KAPI KIR', 'door'),
  CharDef('Hacker', Color(0xFF1F618D), 1.0, 15, 'KAMERA BOZ', 'quiet'),
  CharDef('Isik', Color(0xFFF1C40F), 1.0, 15, 'ISIK BAGISIKLIGI', 'light'),
  CharDef('Gurultucu', Color(0xFF7F8C8D), 1.0, 12, 'GURULTU YAP', 'none'),
  CharDef('Korku', Color(0xFF2C3E50), 1.0, 14, 'KORKUT', 'none'),
  CharDef('Dalga', Color(0xFF17A589), 1.4, 8, 'ATILGAN KOSU', 'speed'),
  CharDef('Enerji', Color(0xFFAF7AC5), 1.0, 16, 'GUC COS', 'none'),
  CharDef('Sis', Color(0xFF5DADE2), 1.0, 17, 'ISINLAN', 'quiet'),
  CharDef('Kukla', Color(0xFF1C1C1C), 1.0, 20, 'CIGLIK AT', 'ghost'),
];

// ------------------------------------------------------------
// HARITA (grafik dugumler + kenarlar) - halka koridor, cikmaz yok
// ------------------------------------------------------------
class MapNode {
  final String id;
  final double x, y;
  const MapNode(this.id, this.x, this.y);
}

class MapEdge {
  final String a, b, kind; // kind: '' koridor, 'doorL','doorR','vent'
  const MapEdge(this.a, this.b, [this.kind = '']);
}

class GameMap {
  final String name;
  final List<MapNode> nodes;
  final List<MapEdge> edges;
  const GameMap(this.name, this.nodes, this.edges);

  MapNode node(String id) => nodes.firstWhere((n) => n.id == id);
}

const List<GameMap> MAPS = [
  GameMap('PIZZA DUKKANI', [
    MapNode('O', 500, 500),
    MapNode('L', 300, 500),
    MapNode('R', 700, 500),
    MapNode('U', 500, 300),
    MapNode('NW', 300, 300),
    MapNode('NE', 700, 300),
    MapNode('SW', 300, 720),
    MapNode('SE', 700, 720),
    MapNode('D', 500, 780),
    MapNode('S1', 140, 220),
    MapNode('S2', 860, 220),
  ], [
    MapEdge('O', 'L', 'doorL'),
    MapEdge('O', 'R', 'doorR'),
    MapEdge('O', 'U', 'vent'),
    MapEdge('L', 'NW'),
    MapEdge('NW', 'U'),
    MapEdge('U', 'NE'),
    MapEdge('NE', 'R'),
    MapEdge('R', 'SE'),
    MapEdge('SE', 'D'),
    MapEdge('D', 'SW'),
    MapEdge('SW', 'L'),
    MapEdge('NW', 'S1'),
    MapEdge('S1', 'SW'),
    MapEdge('NE', 'S2'),
    MapEdge('S2', 'SE'),
  ]),
  GameMap('FABRIKA', [
    MapNode('O', 500, 480),
    MapNode('L', 280, 480),
    MapNode('R', 720, 480),
    MapNode('U', 500, 260),
    MapNode('NW', 260, 260),
    MapNode('NE', 740, 260),
    MapNode('SW', 260, 760),
    MapNode('SE', 740, 760),
    MapNode('D', 500, 820),
    MapNode('S1', 120, 480),
    MapNode('S2', 880, 480),
  ], [
    MapEdge('O', 'L', 'doorL'),
    MapEdge('O', 'R', 'doorR'),
    MapEdge('O', 'U', 'vent'),
    MapEdge('L', 'NW'),
    MapEdge('NW', 'U'),
    MapEdge('U', 'NE'),
    MapEdge('NE', 'R'),
    MapEdge('R', 'SE'),
    MapEdge('SE', 'D'),
    MapEdge('D', 'SW'),
    MapEdge('SW', 'L'),
    MapEdge('L', 'S1'),
    MapEdge('S1', 'SW'),
    MapEdge('R', 'S2'),
    MapEdge('S2', 'SE'),
  ]),
];

// BFS ile her dugumden ofise (O) giden bir sonraki komsu dugumu bul.
Map<String, String> nextHopToOffice(GameMap map) {
  final adj = <String, List<String>>{};
  for (final n in map.nodes) adj[n.id] = [];
  for (final e in map.edges) {
    adj[e.a]!.add(e.b);
    adj[e.b]!.add(e.a);
  }
  final prev = <String, String>{};
  final visited = <String>{'O'};
  final q = <String>['O'];
  int qi = 0;
  while (qi < q.length) {
    final cur = q[qi++];
    for (final nb in adj[cur]!) {
      if (visited.contains(nb)) continue;
      visited.add(nb);
      prev[nb] = cur;
      q.add(nb);
    }
  }
  return prev; // node -> bir sonraki hop (ofise dogru)
}

// ------------------------------------------------------------
// GORUNTULEME DURUMU (render icin anlik/turetilmis kare)
// ------------------------------------------------------------
class NoiseZone {
  final String o;
  NoiseZone(this.o);
}

class VActor {
  int pid;
  double x, y;
  int ch;
  bool hd; // kamerada gizli (vent icinde vs.)
  bool iv; // gorunmez (Golge yetenegi)
  double cd, stun, wait;
  VActor(
      {required this.pid,
      required this.x,
      required this.y,
      required this.ch,
      this.hd = false,
      this.iv = false,
      this.cd = 0,
      this.stun = 0,
      this.wait = 0});
}

class VF {
  double t = 0;
  int hour = 0;
  double power = 100;
  int usage = 1;
  bool dl = false, dr = false, light = false, cam = false, vent = true, black = false;
  double jam = 0;
  double forceL = 0, forceR = 0, waitL = 0, waitR = 0, ddL = 0, ddR = 0;
  int thL = -1, thR = -1;
  double blind = 0;
  List<NoiseZone> noise = [];
  List<VActor> actors = [];
}

// ------------------------------------------------------------
// AG PROTOKOLU + OYUN DURUMU (Net) - host otoriter
// ------------------------------------------------------------
class PlayerInfo {
  int pid;
  String name;
  String role; // 'G' | 'A'
  int charIdx;
  PlayerInfo({required this.pid, required this.name, this.role = 'A', this.charIdx = 0});
  Map<String, dynamic> toJson() => {'pid': pid, 'name': name, 'role': role, 'ch': charIdx};
  factory PlayerInfo.fromJson(Map<String, dynamic> j) => PlayerInfo(
      pid: j['pid'], name: j['name'] ?? '?', role: j['role'] ?? 'A', charIdx: j['ch'] ?? 0);
}

class _SimActor {
  final int pid;
  double x, y;
  int ch;
  bool ai;
  double jx = 0, jy = 0;
  double cd = 0, stun = 0, wait = 0;
  bool invisible = false;
  int aiDiff = 1;
  _SimActor({required this.pid, required this.x, required this.y, required this.ch, this.ai = false});
}
const int kPort = 47632;
const double kNightSeconds = 300.0; // gece uzunlugu (12AM->6AM), saniye
const double kDoorCloseTime = 5.0; // kapida bekleyip icgirme suresi
const double kStunTime = 3.0;

class Net extends ChangeNotifier {
  // --- kimlik / sayfa ---
  int page = 0; // 0 menu,1 hostAra,2 lobi,3 oyun,4 son
  String myName = 'Oyuncu';
  int myPid = 1;
  bool isHost = false;
  bool aiMode = false;
  String status = '';
  String myRole = 'A';
  int myChar = 0;

  // --- ag ---
  RawDatagramSocket? _sock;
  InternetAddress? hostAddr;
  int hostPort = kPort;
  Timer? _discTimer;
  Timer? _simTimer;
  Timer? _pingTimer;
  DateTime _lastHostMsg = DateTime.now();
  final List<Map<String, dynamic>> found = [];
  final Map<int, InternetAddress> _clientAddr = {};
  final Map<int, int> _clientPort = {};
  int _pidSeq = 2;

  // --- lobi ---
  List<PlayerInfo> players = [];
  int mapIdx = 0;
  int soloDiff = 1;
  int soloCount = 1;

  // --- simulasyon (host / solo) ---
  bool simRunning = false;
  double simTime = 0;
  double simPower = 100;
  bool simDl = true, simDr = true, simLight = false, simVent = true, simCam = false, simBlack = false;
  double simJam = 0;
  double simForceL = 0, simForceR = 0, simWaitL = 0, simWaitR = 0, simDdL = 0, simDdR = 0;
  int simThL = -1, simThR = -1;
  Map<int, String> _closingSince = {}; // pid -> hangi kapida bekliyor L/R
  final Map<int, _SimActor> simActors = {};
  Map<String, String> _hop = {};
  final m.Random _rng = m.Random();

  // --- client render (son iki snapshot arasi) ---
  Map<String, dynamic>? _snapPrev;
  Map<String, dynamic>? _snapNext;
  double _snapPrevAt = 0, _snapNextAt = 0;

  // --- gorsel yardimcilar ---
  double shakeX = 0, shakeY = 0;
  double dlShow = 0, drShow = 0; // 0 acik .. 1 kapali (animasyonlu)
  double fanA = 0;

  // --- bitis ---
  bool over = false;
  String overSide = 'guard';
  String overReason = '';
  int overJs = -1;
  bool jsOn = false;
  double jsT = 0;
  double endDelay = 0;
  bool surprise = false;

  GameMap get curMap => MAPS[mapIdx.clamp(0, MAPS.length - 1)];

  // ============================================================
  // AG BASLATMA
  // ============================================================
  Future<void> _openSocket() async {
    _sock?.close();
    _sock = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _sock!.broadcastEnabled = true;
    _sock!.listen(_onRaw);
  }

  void _send(Map<String, dynamic> msg, InternetAddress addr, int port) {
    try {
      final data = utf8.encode(jsonEncode(msg));
      _sock?.send(data, addr, port);
    } catch (_) {}
  }

  void _broadcastAll(Map<String, dynamic> msg) {
    _send(msg, InternetAddress('255.255.255.255'), kPort);
  }

  void _sendToAllPlayers(Map<String, dynamic> msg) {
    for (final pid in _clientAddr.keys) {
      _send(msg, _clientAddr[pid]!, _clientPort[pid]!);
    }
  }

  void _onRaw(RawSocketEvent ev) {
    if (ev != RawSocketEvent.read) return;
    final d = _sock?.receive();
    if (d == null) return;
    Map<String, dynamic> j;
    try {
      j = jsonDecode(utf8.decode(d.data));
    } catch (_) {
      return;
    }
    _handleMsg(j, d.address, d.port);
  }

  void _handleMsg(Map<String, dynamic> j, InternetAddress addr, int port) {
    final type = j['type'];
    if (isHost) {
      switch (type) {
        case 'discover':
          _send({
            'type': 'hostinfo',
            'name': myName,
            'count': players.length,
            'port': kPort,
          }, addr, port);
          break;
        case 'hello':
          _addClient(j['name'] ?? '?', addr, port);
          break;
        case 'lobbyReq':
          final p = players.firstWhere((p) => p.pid == j['pid'], orElse: () => PlayerInfo(pid: -1, name: ''));
          if (p.pid != -1) {
            if (j['ch'] != null) p.charIdx = j['ch'];
            if (j['role'] != null) p.role = j['role'];
          }
          _broadcastLobby();
          break;
        case 'act':
          _applyAct(j);
          break;
        case 'leave':
          _removeClient(j['pid']);
          break;
        case 'ping':
          _send({'type': 'pong'}, addr, port);
          break;
      }
    } else {
      switch (type) {
        case 'hostinfo':
          final key = '${addr.address}:${j['port']}';
          if (!found.any((f) => f['key'] == key)) {
            found.add({
              'key': key,
              'ip': addr.address,
              'port': j['port'],
              'name': j['name'],
              'count': j['count'],
            });
            notifyListeners();
          }
          break;
        case 'welcome':
          myPid = j['pid'];
          hostAddr = addr;
          hostPort = port;
          _lastHostMsg = DateTime.now();
          page = 2;
          status = '';
          notifyListeners();
          break;
        case 'lobby':
          players = (j['players'] as List).map((e) => PlayerInfo.fromJson(e)).toList();
          mapIdx = j['mapIdx'] ?? 0;
          _lastHostMsg = DateTime.now();
          notifyListeners();
          break;
        case 'start':
          mapIdx = j['mapIdx'] ?? 0;
          players = (j['players'] as List).map((e) => PlayerInfo.fromJson(e)).toList();
          final me = players.firstWhere((p) => p.pid == myPid, orElse: () => PlayerInfo(pid: myPid, name: myName));
          myRole = me.role;
          myChar = me.charIdx;
          over = false;
          jsOn = false;
          page = 3;
          _lastHostMsg = DateTime.now();
          notifyListeners();
          break;
        case 'snap':
          _snapPrev = _snapNext;
          _snapPrevAt = _snapNextAt;
          _snapNext = Map<String, dynamic>.from(j['d']);
          _snapNextAt = DateTime.now().millisecondsSinceEpoch / 1000.0;
          _lastHostMsg = DateTime.now();
          break;
        case 'over':
          over = true;
          overSide = j['side'];
          overReason = j['reason'] ?? '';
          overJs = j['js'] ?? -1;
          surprise = j['sur'] ?? false;
          jsOn = false;
          notifyListeners();
          break;
        case 'toLobby':
          page = 2;
          over = false;
          notifyListeners();
          break;
        case 'closed':
          status = 'Sunucu kapandi.';
          _teardownNet();
          page = 0;
          notifyListeners();
          break;
        case 'pong':
          _lastHostMsg = DateTime.now();
          break;
      }
    }
  }

  void _addClient(String name, InternetAddress addr, int port) {
    final pid = _pidSeq++;
    _clientAddr[pid] = addr;
    _clientPort[pid] = port;
    players.add(PlayerInfo(pid: pid, name: name, role: 'A', charIdx: players.length % CHARS.length));
    _send({'type': 'welcome', 'pid': pid}, addr, port);
    _broadcastLobby();
  }

  void _removeClient(int pid) {
    players.removeWhere((p) => p.pid == pid);
    _clientAddr.remove(pid);
    _clientPort.remove(pid);
    simActors.remove(pid);
    _broadcastLobby();
    if (simRunning) _checkGuardPresence();
  }

  void _broadcastLobby() {
    final msg = {
      'type': 'lobby',
      'players': players.map((p) => p.toJson()).toList(),
      'mapIdx': mapIdx,
    };
    _sendToAllPlayers(msg);
    notifyListeners();
  }

  // ============================================================
  // MENU EYLEMLERI
  // ============================================================
  Future<void> setName(String n) async {
    myName = n.trim().isEmpty ? 'Oyuncu' : n.trim();
  }

  Future<void> hostGame() async {
    await _openSocket();
    isHost = true;
    myPid = 1;
    players = [PlayerInfo(pid: 1, name: myName, role: 'G', charIdx: 0)];
    mapIdx = 0;
    page = 2;
    status = 'Sunucu acildi. Oyuncular baglanabilir.';
    notifyListeners();
  }

  Future<void> startDiscovery() async {
    await _openSocket();
    isHost = false;
    found.clear();
    page = 1;
    status = 'Araniyor...';
    notifyListeners();
    _discTimer?.cancel();
    _discTimer = Timer.periodic(const Duration(milliseconds: 700), (_) {
      _broadcastAll({'type': 'discover'});
    });
  }

  void stopDiscovery() {
    _discTimer?.cancel();
  }

  Future<void> joinFound(Map<String, dynamic> f) async {
    await joinIp(f['ip'], f['port']);
  }

  Future<void> joinIp(String ip, [int port = kPort]) async {
    stopDiscovery();
    if (_sock == null) await _openSocket();
    isHost = false;
    status = 'Baglaniliyor...';
    notifyListeners();
    hostAddr = InternetAddress(ip);
    hostPort = port;
    _send({'type': 'hello', 'name': myName}, hostAddr!, hostPort);
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (hostAddr != null) _send({'type': 'ping'}, hostAddr!, hostPort);
      if (DateTime.now().difference(_lastHostMsg).inSeconds > 8 && page != 0) {
        status = 'Baglanti koptu.';
        _teardownNet();
        page = 0;
        notifyListeners();
      }
    });
  }

  void setChar(int idx) {
    myChar = idx;
    if (isHost) {
      final me = players.firstWhere((p) => p.pid == myPid);
      me.charIdx = idx;
      _broadcastLobby();
    } else if (hostAddr != null) {
      _send({'type': 'lobbyReq', 'pid': myPid, 'ch': idx}, hostAddr!, hostPort);
    }
  }

  void setMap(int idx) {
    if (!isHost) return;
    mapIdx = idx;
    _broadcastLobby();
  }

  void setRole(int pid, String role) {
    if (!isHost) return;
    if (role == 'G' && players.any((p) => p.role == 'G' && p.pid != pid)) {
      for (final p in players) {
        if (p.role == 'G') p.role = 'A';
      }
    }
    players.firstWhere((p) => p.pid == pid).role = role;
    _broadcastLobby();
  }

  bool get canStart =>
      players.length >= 2 && players.any((p) => p.role == 'G') && players.where((p) => p.role == 'A').isNotEmpty;

  void startMultiplayer() {
    if (!isHost || !canStart) return;
    final me = players.firstWhere((p) => p.pid == myPid);
    myRole = me.role;
    myChar = me.charIdx;
    _beginSim();
    _sendToAllPlayers({
      'type': 'start',
      'mapIdx': mapIdx,
      'players': players.map((p) => p.toJson()).toList(),
    });
    over = false;
    jsOn = false;
    page = 3;
    notifyListeners();
  }

  void setSoloDiff(int i) {
    soloDiff = i;
    notifyListeners();
  }

  void setSoloCount(int i) {
    soloCount = i;
    notifyListeners();
  }

  void setSoloMap(int i) {
    mapIdx = i;
    notifyListeners();
  }

  void startSolo() {
    isHost = true;
    aiMode = true;
    myPid = 1;
    myRole = 'G';
    myChar = 0;
    players = [PlayerInfo(pid: 1, name: myName, role: 'G', charIdx: 0)];
    for (int i = 0; i < soloCount; i++) {
      players.add(PlayerInfo(pid: 100 + i, name: 'YZ ${i + 1}', role: 'A', charIdx: i % CHARS.length));
    }
    _beginSim();
    over = false;
    jsOn = false;
    page = 3;
    notifyListeners();
  }

  void toLobbyAll() {
    if (!isHost) return;
    _endSim();
    page = 2;
    over = false;
    _sendToAllPlayers({'type': 'toLobby'});
    notifyListeners();
  }

  void leaveRoom() {
    if (isHost) {
      _sendToAllPlayers({'type': 'closed'});
    } else if (hostAddr != null) {
      _send({'type': 'leave', 'pid': myPid}, hostAddr!, hostPort);
    }
    _endSim();
    _teardownNet();
    page = 0;
    over = false;
    aiMode = false;
    players = [];
    notifyListeners();
  }

  void _teardownNet() {
    _discTimer?.cancel();
    _pingTimer?.cancel();
    _sock?.close();
    _sock = null;
    hostAddr = null;
    _clientAddr.clear();
    _clientPort.clear();
  }

  // ============================================================
  // SIMULASYON (host taraf otoriter)
  // ============================================================
  void _beginSim() {
    simRunning = true;
    simTime = 0;
    simPower = 100;
    simDl = true;
    simDr = true;
    simLight = false;
    simVent = true;
    simCam = false;
    simBlack = false;
    simJam = 0;
    simForceL = 0;
    simForceR = 0;
    simWaitL = 0;
    simWaitR = 0;
    simDdL = 0;
    simDdR = 0;
    simThL = -1;
    simThR = -1;
    simActors.clear();
    _hop = nextHopToOffice(curMap);
    final startNodes = ['S1', 'D', 'S2'];
    int i = 0;
    for (final p in players) {
      if (p.role != 'A') continue;
      final n = curMap.node(startNodes[i % startNodes.length]);
      final a = _SimActor(pid: p.pid, x: n.x, y: n.y, ch: p.charIdx, ai: p.pid >= 100);
      a.aiDiff = soloDiff;
      simActors[p.pid] = a;
      i++;
    }
    _simTimer?.cancel();
    _simTimer = Timer.periodic(const Duration(milliseconds: 50), (_) => _simStep(0.05));
  }

  void _endSim() {
    simRunning = false;
    _simTimer?.cancel();
  }

  void _applyAct(Map<String, dynamic> j) {
    final pid = j['pid'];
    final code = j['code'];
    if (pid == myPid) {
      _doGuardOrActorAction(pid, code, j);
      return;
    }
    _doGuardOrActorAction(pid, code, j);
  }

  void gAct(String code) {
    if (myRole != 'G') return;
    if (isHost) {
      _doGuardOrActorAction(myPid, code, {});
    } else if (hostAddr != null) {
      _send({'type': 'act', 'pid': myPid, 'code': code}, hostAddr!, hostPort);
    }
    Sfx.doorToggle();
  }

  void sendJoy(double dx, double dy) {
    if (myRole != 'A') return;
    if (isHost) {
      simActors[myPid]?.jx = dx;
      simActors[myPid]?.jy = dy;
    } else if (hostAddr != null) {
      _send({'type': 'act', 'pid': myPid, 'code': 'mv', 'dx': dx, 'dy': dy}, hostAddr!, hostPort);
    }
  }

  void _doGuardOrActorAction(int pid, String code, Map<String, dynamic> j) {
    final isGuardPid = players.firstWhere((p) => p.pid == pid, orElse: () => PlayerInfo(pid: -1, name: '')).role == 'G';
    if (isGuardPid) {
      if (simBlack) return;
      switch (code) {
        case 'dl':
          if (simDdL <= 0) simDl = !simDl;
          break;
        case 'dr':
          if (simDdR <= 0) simDr = !simDr;
          break;
        case 'li':
          simLight = !simLight;
          break;
        case 'cm':
          if (!(simJam > 0 && !simCam)) simCam = !simCam;
          break;
        case 'vt':
          simVent = !simVent;
          break;
      }
    } else {
      final a = simActors[pid];
      if (a == null) return;
      switch (code) {
        case 'mv':
          a.jx = (j['dx'] ?? 0).toDouble();
          a.jy = (j['dy'] ?? 0).toDouble();
          break;
        case 'ability':
          _useAbility(a);
          break;
        case 'ctx':
          _ctxAction(a);
          break;
      }
    }
  }

  void useAbility() {
    if (myRole != 'A') return;
    if (isHost) {
      _useAbility(simActors[myPid]!);
    } else if (hostAddr != null) {
      _send({'type': 'act', 'pid': myPid, 'code': 'ability'}, hostAddr!, hostPort);
    }
  }

  void doCtx() {
    if (myRole != 'A') return;
    if (isHost) {
      _ctxAction(simActors[myPid]!);
    } else if (hostAddr != null) {
      _send({'type': 'act', 'pid': myPid, 'code': 'ctx'}, hostAddr!, hostPort);
    }
  }

  void _useAbility(_SimActor a) {
    if (a.cd > 0 || a.stun > 0) return;
    final def = CHARS[a.ch.clamp(0, CHARS.length - 1)];
    a.cd = def.cd;
    switch (def.passive) {
      case 'speed':
        a.jx *= 1; // hiz patlamasi asagida _simStep icinde a.boost ile ele alinir
        _boost[a.pid] = 3.0;
        break;
      case 'ghost':
        a.invisible = true;
        Timer(const Duration(seconds: 4), () => a.invisible = false);
        break;
      case 'vent':
        _boost[a.pid] = 2.5;
        break;
      case 'door':
        if (_nearNode(a, 'L') < 90) simForceL = m.min(1, simForceL + 0.6);
        if (_nearNode(a, 'R') < 90) simForceR = m.min(1, simForceR + 0.6);
        break;
      case 'quiet':
        simJam = 5.0;
        break;
      case 'light':
        break;
      default:
        // Gurultucu / Korku / Enerji / Kukla: alan etkisi
        _noisePulse = 2.0;
        if (def.name == 'Enerji') simPower = m.max(0, simPower - 8);
    }
  }

  final Map<int, double> _boost = {};
  double _noisePulse = 0;

  double _nearNode(_SimActor a, String id) {
    final n = curMap.node(id);
    return (Offset(a.x, a.y) - Offset(n.x, n.y)).distance;
  }

  void _ctxAction(_SimActor a) {
    final atL = _nearNode(a, 'L') < 70;
    final atR = _nearNode(a, 'R') < 70;
    final atU = _nearNode(a, 'U') < 70;
    if (atL && !simDl) {
      simForceL = m.min(1, simForceL + 0.35);
    } else if (atR && !simDr) {
      simForceR = m.min(1, simForceR + 0.35);
    } else if (atL && simDl) {
      _enterOffice(a);
    } else if (atR && simDr) {
      _enterOffice(a);
    } else if (atU && simVent) {
      final o = curMap.node('O');
      a.x = o.x;
      a.y = o.y - 10;
    }
  }

  String? ctxLabel(VF vf) {
    final a = simActors[myPid] ?? _lastLocalActor;
    if (a == null) return null;
    final dl = _nearNode(a, 'L');
    final dr = _nearNode(a, 'R');
    final du = _nearNode(a, 'U');
    if (dl < 70) return simOrVfDoor(vf, true) ? 'GIR' : 'ZORLA';
    if (dr < 70) return simOrVfDoor(vf, false) ? 'GIR' : 'ZORLA';
    if (du < 70 && vf.vent) return 'VENTE GIR';
    return null;
  }

  bool simOrVfDoor(VF vf, bool left) => left ? vf.dl : vf.dr;

  _SimActor? get _lastLocalActor => simActors[myPid];

  void _enterOffice(_SimActor a) {
    _finish('anim', 'Bir animatronik ofise girdi!', a.ch, false);
  }

  void _checkGuardPresence() {
    if (!players.any((p) => p.role == 'G')) {
      _finish('anim', 'Guvenlik oyundan ayrildi.', -1, false);
    }
  }

  void _finish(String side, String reason, int js, bool sur) {
    if (over) return;
    over = true;
    overSide = side;
    overReason = reason;
    overJs = js;
    surprise = sur;
    _endSim();
    _sendToAllPlayers({'type': 'over', 'side': side, 'reason': reason, 'js': js, 'sur': sur});
    if (js >= 0) {
      jsOn = true;
      jsT = 0;
      Sfx.screamBurst();
    }
    notifyListeners();
  }

  // ana simulasyon adimi (host/solo icin ~20Hz)
  void _simStep(double dt) {
    if (!simRunning || over) return;
    simTime += dt;
    final hour = (simTime / (kNightSeconds / 6)).floor().clamp(0, 6);

    // guc tuketimi
    int usage = 1;
    if (simLight) usage++;
    if (simCam) usage++;
    if (!simDl) usage++; // acik kapi da az guc harcar (fan/isik)
    if (!simDr) usage++;
    if (simVent) usage++;
    usage = usage.clamp(1, 6);
    if (!simBlack) {
      simPower -= dt * (0.9 + usage * 0.55);
      if (simPower <= 0) {
        simPower = 0;
        simBlack = true;
        simDl = true;
        simDr = true;
        simLight = false;
        simCam = false;
      }
    }

    if (simJam > 0) simJam = m.max(0, simJam - dt);
    if (_noisePulse > 0) _noisePulse = m.max(0, _noisePulse - dt);
    fanA += dt * 1.4;

    // kapi kirilma / rastgele isinlanma kurallari
    _stepDoor(true);
    _stepDoor(false);

    // aktorler
    for (final a in simActors.values) {
      if (a.cd > 0) a.cd = m.max(0, a.cd - dt);
      if (a.stun > 0) {
        a.stun = m.max(0, a.stun - dt);
        continue;
      }
      final def = CHARS[a.ch.clamp(0, CHARS.length - 1)];
      double speed = def.speed * 90;
      if ((_boost[a.pid] ?? 0) > 0) {
        _boost[a.pid] = m.max(0, _boost[a.pid]! - dt);
        speed *= 1.8;
      }
      if (a.ai) {
        _aiMove(a, dt, speed);
      } else {
        final len = m.sqrt(a.jx * a.jx + a.jy * a.jy);
        if (len > 0.05) {
          a.x += (a.jx / m.max(len, 1)) * speed * dt;
          a.y += (a.jy / m.max(len, 1)) * speed * dt;
        }
      }
      a.x = a.x.clamp(60.0, 940.0);
      a.y = a.y.clamp(60.0, 940.0);

      // kapiya cok yaklastiysa ve kapaliysa iceri giremez, onunde bekler
      _blockAtDoors(a);

      // otomatik giris kurali: kapi ACIKKEN kapida 5 sn bekleme
      final dl = _nearNode(a, 'L');
      final dr = _nearNode(a, 'R');
      if (dl < 70 && simDl) {
        a.wait += dt;
        simWaitL = a.wait;
        simThL = a.ch;
        if (a.wait > kDoorCloseTime) {
          _enterOffice(a);
          return;
        }
      } else if (dr < 70 && simDr) {
        a.wait += dt;
        simWaitR = a.wait;
        simThR = a.ch;
        if (a.wait > kDoorCloseTime) {
          _enterOffice(a);
          return;
        }
      } else {
        a.wait = 0;
      }
      if (dl < 90) simThL = a.ch; else if (simThL == a.ch) simThL = -1;
      if (dr < 90) simThR = a.ch; else if (simThR == a.ch) simThR = -1;
    }
    if (!simActors.values.any((a) => _nearNode(a, 'L') < 90)) {
      simThL = -1;
      simWaitL = 0;
    }
    if (!simActors.values.any((a) => _nearNode(a, 'R') < 90)) {
      simThR = -1;
      simWaitR = 0;
    }

    if (hour >= 6) {
      _finish('guard', 'Sabah 06:00 - nobet bitti!', -1, false);
      return;
    }

    // client'lara yayinla (solo/ai modunda gerek yok ama zararsiz)
    if (isHost && !aiMode) {
      _sendToAllPlayers({'type': 'snap', 'd': _buildSnap(hour, usage)});
    }
    notifyListeners();
  }

  void _stepDoor(bool left) {
    double force = left ? simForceL : simForceR;
    if (force > 0) {
      force = m.max(0, force - 0.04);
      if (left) {
        simForceL = force;
      } else {
        simForceR = force;
      }
      if (force <= 0.001) {
        if (left) {
          simDl = true;
        } else {
          simDr = true;
        }
      }
    }
    // kapi kapanirken kapinin ustune denk gelen canavar isinlanip sersemler
    final dd = left ? simDdL : simDdR;
    if (dd > 0) {
      final nd = m.max(0.0, dd - 0.05);
      if (left) {
        simDdL = nd;
      } else {
        simDdR = nd;
      }
    }
  }

  void _blockAtDoors(_SimActor a) {
    final l = curMap.node('L');
    final r = curMap.node('R');
    if (!simDl) {
      final dist = (Offset(a.x, a.y) - Offset(l.x, l.y)).distance;
      if (dist < 34) {
        // kapi kapaninca ustunde yakalanma -> isinlan + sersemle
        _teleportRandom(a);
      } else if (dist < 55) {
        final dir = Offset(a.x - l.x, a.y - l.y);
        final dd = dir.distance == 0 ? const Offset(1, 0) : dir / dir.distance;
        a.x = l.x + dd.dx * 55;
        a.y = l.y + dd.dy * 55;
      }
    }
    if (!simDr) {
      final dist = (Offset(a.x, a.y) - Offset(r.x, r.y)).distance;
      if (dist < 34) {
        _teleportRandom(a);
      } else if (dist < 55) {
        final dir = Offset(a.x - r.x, a.y - r.y);
        final dd = dir.distance == 0 ? const Offset(1, 0) : dir / dir.distance;
        a.x = r.x + dd.dx * 55;
        a.y = r.y + dd.dy * 55;
      }
    }
  }

  void _teleportRandom(_SimActor a) {
    final rooms = ['S1', 'S2', 'D', 'NW', 'NE', 'SW', 'SE'];
    final n = curMap.node(rooms[_rng.nextInt(rooms.length)]);
    a.x = n.x;
    a.y = n.y;
    a.stun = kStunTime;
    a.wait = 0;
  }

  void _aiMove(_SimActor a, double dt, double speed) {
    speed *= (0.7 + 0.22 * a.aiDiff); // KOLAY/NORMAL/KABUS
    // en yakin dugumu bul, ofise dogru bir sonraki hopu al
    String cur = 'D';
    double best = double.infinity;
    for (final n in curMap.nodes) {
      final d = (Offset(a.x, a.y) - Offset(n.x, n.y)).distance;
      if (d < best) {
        best = d;
        cur = n.id;
      }
    }
    String targetId = cur;
    if (cur != 'O') {
      final hop = _hop[cur];
      targetId = hop ?? 'O';
      if ((cur == 'L' && !simDl) || (cur == 'R' && !simDr)) {
        targetId = cur; // kapida bekle
      }
    } else {
      targetId = 'O';
    }
    final tn = curMap.node(targetId);
    final dir = Offset(tn.x - a.x, tn.y - a.y);
    if (dir.distance > 6) {
      final nd = dir / dir.distance;
      a.x += nd.dx * speed * dt;
      a.y += nd.dy * speed * dt;
    } else if ((targetId == 'L' || targetId == 'R') && a.cd <= 0 && _rng.nextDouble() < 0.02) {
      _useAbility(a);
    }
  }

  Map<String, dynamic> _buildSnap(int hour, int usage) {
    return {
      'h': hour,
      'p': simPower,
      'u': usage,
      'dl': simDl,
      'dr': simDr,
      'li': simLight,
      'cm': simCam,
      'vt': simVent,
      'bl': simBlack,
      'jm': simJam,
      'fl': simForceL,
      'fr': simForceR,
      'wl': simWaitL,
      'wr': simWaitR,
      'ddl': simDdL,
      'ddr': simDdR,
      'thl': simThL,
      'thr': simThR,
      't': simTime,
      'np': _noisePulse,
      'a': simActors.values
          .map((a) => {
                'pid': a.pid,
                'x': a.x,
                'y': a.y,
                'ch': a.ch,
                'iv': a.invisible,
                'cd': a.cd,
                'st': a.stun,
                'wt': a.wait,
              })
          .toList(),
    };
  }

  // her animasyon karesinde cagrilir (client + host gorsel yumusatma)
  void frame(double dt) {
    if (shakeX.abs() > 0.1 || shakeY.abs() > 0.1) {
      shakeX *= 0.82;
      shakeY *= 0.82;
    } else {
      shakeX = 0;
      shakeY = 0;
    }
    final targetDl = isHost ? (simBlack ? true : simDl) : (_lastVfDl ?? true);
    dlShow += ((targetDl ? 1.0 : 0.0) - dlShow) * m.min(1, dt * 8);
    final targetDr = isHost ? (simBlack ? true : simDr) : (_lastVfDr ?? true);
    drShow += ((targetDr ? 1.0 : 0.0) - drShow) * m.min(1, dt * 8);
    fanA += dt * (isHost ? 0 : 1.4);
    if (jsOn) {
      jsT += dt;
      if (jsT > 1.7) {
        jsOn = false;
      }
      shakeX = (m.Random().nextDouble() - 0.5) * 14;
      shakeY = (m.Random().nextDouble() - 0.5) * 14;
    }
    if (over) endDelay += dt;
    notifyListeners();
  }

  bool? _lastVfDl;
  bool? _lastVfDr;

  // ============================================================
  // GORUNTU KARESI URETIMI (VF) - host: dogrudan, client: interpolasyon
  // ============================================================
  VF vf(int nowMs) {
    final f = VF();
    if (isHost) {
      f.hour = (simTime / (kNightSeconds / 6)).floor().clamp(0, 6);
      f.power = simPower;
      f.usage = _lastUsage();
      f.dl = simDl;
      f.dr = simDr;
      f.light = simLight;
      f.cam = simCam;
      f.vent = simVent;
      f.black = simBlack;
      f.jam = simJam;
      f.forceL = simForceL;
      f.forceR = simForceR;
      f.waitL = simWaitL;
      f.waitR = simWaitR;
      f.ddL = simDdL;
      f.ddR = simDdR;
      f.thL = simThL;
      f.thR = simThR;
      f.t = simTime;
      f.noise = _noisePulse > 0 ? [NoiseZone('O')] : [];
      f.actors = simActors.values
          .map((a) => VActor(
              pid: a.pid,
              x: a.x,
              y: a.y,
              ch: a.ch,
              hd: false,
              iv: a.invisible,
              cd: a.cd,
              stun: a.stun,
              wait: a.wait))
          .toList();
      _lastVfDl = f.dl;
      _lastVfDr = f.dr;
      if (!jsOn && !simBlack && f.forceL <= 0 && f.forceR <= 0) {
        // guc kritikse hafif ekran titremesi
        if (f.power < 15) {
          shakeX = (m.Random().nextDouble() - 0.5) * 2;
          shakeY = (m.Random().nextDouble() - 0.5) * 2;
        }
      }
      return f;
    }
    // client: iki snapshot arasi interpolasyon
    final a = _snapPrev;
    final b = _snapNext;
    if (b == null) return f;
    final data = a == null ? b : b;
    double lerp(num x, num y, double t) => x + (y - x) * t;
    double tt = 1.0;
    if (a != null && _snapNextAt > _snapPrevAt) {
      final now = nowMs / 1000.0;
      tt = ((now - _snapNextAt) / (_snapNextAt - _snapPrevAt) + 1).clamp(0.0, 1.5);
    }
    f.hour = data['h'] ?? 0;
    f.power = (data['p'] ?? 100).toDouble();
    f.usage = data['u'] ?? 1;
    f.dl = data['dl'] ?? true;
    f.dr = data['dr'] ?? true;
    f.light = data['li'] ?? false;
    f.cam = data['cm'] ?? false;
    f.vent = data['vt'] ?? true;
    f.black = data['bl'] ?? false;
    f.jam = (data['jm'] ?? 0).toDouble();
    f.forceL = (data['fl'] ?? 0).toDouble();
    f.forceR = (data['fr'] ?? 0).toDouble();
    f.waitL = (data['wl'] ?? 0).toDouble();
    f.waitR = (data['wr'] ?? 0).toDouble();
    f.ddL = (data['ddl'] ?? 0).toDouble();
    f.ddR = (data['ddr'] ?? 0).toDouble();
    f.thL = data['thl'] ?? -1;
    f.thR = data['thr'] ?? -1;
    f.t = (data['t'] ?? 0).toDouble();
    f.noise = ((data['np'] ?? 0) > 0) ? [NoiseZone('O')] : [];
    final actorsJ = (data['a'] as List?) ?? [];
    final prevActorsJ = (a?['a'] as List?) ?? actorsJ;
    f.actors = actorsJ.map<VActor>((e) {
      final prev = prevActorsJ.firstWhere((p) => p['pid'] == e['pid'], orElse: () => e);
      final x = lerp((prev['x'] ?? e['x']), e['x'], tt.clamp(0.0, 1.0));
      final y = lerp((prev['y'] ?? e['y']), e['y'], tt.clamp(0.0, 1.0));
      return VActor(
          pid: e['pid'],
          x: x.toDouble(),
          y: y.toDouble(),
          ch: e['ch'],
          hd: false,
          iv: e['iv'] ?? false,
          cd: (e['cd'] ?? 0).toDouble(),
          stun: (e['st'] ?? 0).toDouble(),
          wait: (e['wt'] ?? 0).toDouble());
    }).toList();
    _lastVfDl = f.dl;
    _lastVfDr = f.dr;
    return f;
  }

  int _lastUsage() {
    int usage = 1;
    if (simLight) usage++;
    if (simCam) usage++;
    if (!simDl) usage++;
    if (!simDr) usage++;
    if (simVent) usage++;
    return usage.clamp(1, 6);
  }
}
// ------------------------------------------------------------
// KOK UYGULAMA
// ------------------------------------------------------------
class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final Net gs = Net();

  @override
  void initState() {
    super.initState();
    gs.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gece Vardiyasi',
      theme: ThemeData.dark(useMaterial3: false).copyWith(
        scaffoldBackgroundColor: const Color(0xFF060610),
        colorScheme: const ColorScheme.dark(primary: Color(0xFF8866FF)),
      ),
      home: Scaffold(
        body: SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0A0A18), Color(0xFF06060C)],
              ),
            ),
            child: _page(),
          ),
        ),
      ),
    );
  }

  Widget _page() {
    switch (gs.page) {
      case 1:
        return DiscoverPage(gs: gs);
      case 2:
        return LobbyPage(gs: gs);
      case 3:
        return GamePage(gs: gs);
      case 4:
        return EndPage(gs: gs);
      case 5:
        return SoloPage(gs: gs);
      default:
        return MenuPage(gs: gs);
    }
  }
}

// ------------------------------------------------------------
// MENU
// ------------------------------------------------------------
class MenuPage extends StatefulWidget {
  final Net gs;
  const MenuPage({super.key, required this.gs});
  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final nameCtl = TextEditingController(text: 'Oyuncu');
  final ipCtl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final gs = widget.gs;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
          const Text('GECE VARDIYASI',
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  color: Color(0xFFFF3B3B))),
          const SizedBox(height: 4),
          const Text('LAN uzerinden asimetrik korku oyunu', style: kTxt),
          const SizedBox(height: 22),
          const Text('ADIN:', style: kSmall),
          const SizedBox(height: 6),
          TextField(
            controller: nameCtl,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF181828),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onChanged: gs.setName,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Btn(
                  t: 'HOST OL',
                  sub: 'oda kur',
                  c: const Color(0xFF1E8449),
                  on: () async {
                    await gs.setName(nameCtl.text);
                    await gs.hostGame();
                  }),
              const SizedBox(width: 10),
              Btn(
                  t: 'LOBI ARA',
                  sub: 'ayni Wi-Fi',
                  c: const Color(0xFF1F618D),
                  on: () async {
                    await gs.setName(nameCtl.text);
                    await gs.startDiscovery();
                  }),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: ipCtl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'IP adresi ile katil (ornek: 192.168.1.5)',
                    hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
                    filled: true,
                    fillColor: const Color(0xFF181828),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Btn(
                  t: 'KATIL',
                  expand: false,
                  c: const Color(0xFF8E44AD),
                  on: ipCtl.text.trim().isEmpty
                      ? null
                      : () async {
                          await gs.setName(nameCtl.text);
                          await gs.joinIp(ipCtl.text.trim());
                        }),
            ],
          ),
          const SizedBox(height: 10),
          Btn(
              t: 'TEK KISILIK YZ',
              sub: 'internetsiz, tek basina oyna',
              c: const Color(0xFFB7950B),
              on: () async {
                await gs.setName(nameCtl.text);
                gs.page = 5;
                gs.notifyListeners();
              }),
          const Spacer(),
          if (gs.status.isNotEmpty)
            Center(child: Text(gs.status, style: kSmall)),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// SUNUCU ARAMA
// ------------------------------------------------------------
class DiscoverPage extends StatelessWidget {
  final Net gs;
  const DiscoverPage({super.key, required this.gs});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('SUNUCULAR',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const Spacer(),
              Btn(
                  t: 'GERI',
                  expand: false,
                  c: const Color(0xFF555577),
                  on: () {
                    gs.stopDiscovery();
                    gs.page = 0;
                    gs.notifyListeners();
                  }),
            ],
          ),
          const SizedBox(height: 4),
          Text(gs.status, style: kSmall),
          const SizedBox(height: 12),
          Expanded(
            child: gs.found.isEmpty
                ? const Center(
                    child: Text('Ayni Wi-Fi agindaki sunucular burada listelenecek...',
                        textAlign: TextAlign.center, style: kTxt))
                : ListView.builder(
                    itemCount: gs.found.length,
                    itemBuilder: (context, i) {
                      final f = gs.found[i];
                      return Card(
                        color: const Color(0xFF161626),
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(f['name'] ?? '?',
                              style: const TextStyle(fontWeight: FontWeight.w800)),
                          subtitle: Text('${f['ip']}  ·  ${f['count']} oyuncu', style: kSmall),
                          trailing: ElevatedButton(
                            onPressed: () => gs.joinFound(f),
                            child: const Text('KATIL'),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// LOBI
// ------------------------------------------------------------
class LobbyPage extends StatelessWidget {
  final Net gs;
  const LobbyPage({super.key, required this.gs});
  @override
  Widget build(BuildContext context) {
    final me = gs.players.firstWhere((p) => p.pid == gs.myPid,
        orElse: () => PlayerInfo(pid: gs.myPid, name: gs.myName));
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('LOBI', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 3)),
              const Spacer(),
              Btn(t: 'GERI', expand: false, c: const Color(0xFF555577), on: gs.leaveRoom),
            ],
          ),
          const SizedBox(height: 10),
          const Text('OYUNCULAR:', style: kSmall),
          const SizedBox(height: 6),
          SizedBox(
            height: 130,
            child: ListView.builder(
              itemCount: gs.players.length,
              itemBuilder: (context, i) {
                final p = gs.players[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141422),
                    borderRadius: BorderRadius.circular(8),
                    border: p.pid == gs.myPid ? Border.all(color: const Color(0xFF8866FF)) : null,
                  ),
                  child: Row(
                    children: [
                      Container(width: 10, height: 10,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: p.role == 'G' ? const Color(0xFF3498DB) : CHARS[p.charIdx].color)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(p.name,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
                      Text(p.role == 'G' ? 'GUVENLIK' : CHARS[p.charIdx].name, style: kSmall),
                      if (gs.isHost)
                        IconButton(
                          icon: const Icon(Icons.swap_horiz, size: 18, color: Colors.white54),
                          onPressed: () => gs.setRole(p.pid, p.role == 'G' ? 'A' : 'G'),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          if (me.role == 'A') ...[
            const Text('KARAKTER SEC:', style: kSmall),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (int i = 0; i < CHARS.length; i++)
                  GestureDetector(
                    onTap: () => gs.setChar(i),
                    child: chip(CHARS[i].name, CHARS[i].color, on: gs.myChar == i),
                  ),
              ],
            ),
            const SizedBox(height: 14),
          ],
          const Text('HARITA:', style: kSmall),
          const SizedBox(height: 6),
          Row(
            children: [
              for (int i = 0; i < MAPS.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: gs.isHost ? () => gs.setMap(i) : null,
                    child: chip(MAPS[i].name, const Color(0xFF3498DB), on: gs.mapIdx == i),
                  ),
                ),
            ],
          ),
          const Spacer(),
          if (gs.isHost)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: gs.canStart ? const Color(0xFF1E8449) : const Color(0xFF333344),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: gs.canStart ? gs.startMultiplayer : null,
              child: Text(gs.canStart ? 'OYUNU BASLAT' : 'EN AZ 2 OYUNCU (1 GUVENLIK) GEREKLI',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
            )
          else
            const Center(child: Text('Host oyunu baslatmasini bekliyorsun...', style: kTxt)),
        ],
      ),
    );
  }
}
class SoloPage extends StatelessWidget {
  final Net gs;
  const SoloPage({super.key, required this.gs});
  @override
  Widget build(BuildContext context) {
    const diffs = ['KOLAY', 'NORMAL', 'KABUS'];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('TEK KISILIK YZ',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900,
                      letterSpacing: 2, color: Color(0xFFFFB300))),
              const Spacer(),
              Btn(t: 'GERI', on: () => gs.leaveRoom(),
                  expand: false, c: const Color(0xFF555577)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Sen guvenliksin. YZ animatronikler seni avlar. Sabah 6 ya kadar hayatta kal.',
            style: kTxt,
          ),
          const SizedBox(height: 16),
          const Text('ZORLUK:', style: kSmall),
          const SizedBox(height: 6),
          Row(
            children: [
              for (int i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => gs.setSoloDiff(i),
                    child: chip(diffs[i], const Color(0xFFE74C3C),
                        on: gs.soloDiff == i),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('ANIMATRONIK SAYISI:', style: kSmall),
          const SizedBox(height: 6),
          Row(
            children: [
              for (int i = 1; i <= 3; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => gs.setSoloCount(i),
                    child: chip('$i', const Color(0xFF8E44AD),
                        on: gs.soloCount == i),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('HARITA:', style: kSmall),
          const SizedBox(height: 6),
          Row(
            children: [
              for (int i = 0; i < MAPS.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => gs.setSoloMap(i),
                    child: chip(MAPS[i].name, const Color(0xFF3498DB),
                        on: gs.mapIdx == i),
                  ),
                ),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E8449),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () => gs.startSolo(),
            child: const Text('GECEYE BASLA',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

class GamePage extends StatefulWidget {
  final Net gs;
  const GamePage({super.key, required this.gs});
  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage>
    with SingleTickerProviderStateMixin {
  late AnimationController c;
  Duration? lastD;

  @override
  void initState() {
    super.initState();
    c = AnimationController(vsync: this)..repeat();
    c.addListener(_tick);
  }

  void _tick() {
    final d = c.lastElapsedDuration ?? Duration.zero;
    double dt = 0.016;
    if (lastD != null) {
      dt = m.min(0.05, (d - lastD!).inMicroseconds / 1000000);
    }
    lastD = d;
    widget.gs.frame(dt);
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gs = widget.gs;
    return AnimatedBuilder(
      animation: c,
      builder: (context, _) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final vf = gs.vf(now);
        return Stack(
          children: [
            Positioned.fill(
              child: Transform.translate(
                offset: Offset(gs.shakeX, gs.shakeY),
                child: gs.myRole == 'G'
                    ? _buildGuard(gs, vf, now)
                    : _buildAnim(gs, vf, now),
              ),
            ),
            if (vf.blind > 0)
              Positioned.fill(
                child: Container(
                    color: Colors.white.al(m.min(0.85, vf.blind))),
              ),
            if (gs.jsOn)
              Positioned.fill(child: JsOverlay(ch: gs.overJs, t: gs.jsT))
            else if (gs.over)
              Positioned.fill(
                child: Container(
                  color: (gs.overSide == 'anim'
                          ? const Color(0xFFFF2200)
                          : const Color(0xFF22FF88))
                      .al(0.12 + 0.1 * m.sin(gs.endDelay * 12).abs()),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildGuard(Net gs, VF vf, int now) {
    final jammed = vf.cam && vf.jam > 0;
    final pulse = 0.6 + 0.4 * m.sin(now / 90);
    return Stack(
      children: [
        Positioned.fill(
          child: vf.cam && !vf.black
              ? CustomPaint(
                  painter: MapP(map: gs.curMap, vf: vf, camMode: true,
                      myPid: gs.myPid, t: vf.t, jam: jammed))
              : CustomPaint(
                  painter: OfficeP(vf: vf, dlShow: gs.dlShow,
                      drShow: gs.drShow, fanA: gs.fanA, t: now / 1000)),
        ),
        Positioned.fill(
          child: CustomPaint(
            painter: NoiseP(seed: now ~/ 60, heavy: vf.cam, jam: jammed),
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
                  color: Colors.red.al(pulse))))),
        if (vf.forceR > 0 || vf.waitR > 1.5)
          Positioned(top: 86, left: 0, right: 0,
            child: Center(child: Text(
              'SAG KAPI ${vf.forceR > 0 ? 'ZORLANIYOR!' : 'TEHLIKE!'}',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900,
                  color: Colors.red.al(pulse))))),
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
                  on: vf.black || (vf.jam > 0 && !vf.cam) ? null : () => gs.gAct('cm')),
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

  Widget _buildAnim(Net gs, VF vf, int now) {
    VActor? me;
    for (final a in vf.actors) {
      if (a.pid == gs.myPid) { me = a; break; }
    }
    final ctx = gs.ctxLabel(vf);
    final cd = me?.cd ?? 0.0;
    final ci = gs.myChar.clamp(0, CHARS.length - 1);
    final cdMax = CHARS[ci].cd;
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(painter: MapP(map: gs.curMap, vf: vf,
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
                      color: const Color(0xFFC0392B).al(0.85),
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
                          color: CHARS[ci].color.al(cd > 0 ? 0.2 : 0.75),
                          border: Border.all(color: CHARS[ci].color, width: 2)))),
                      Positioned.fill(child: CustomPaint(
                        painter: ArcP(frac: cdMax > 0 ? cd / cdMax : 0,
                            col: Colors.black.al(0.65)))),
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

class EndPage extends StatefulWidget {
  final Net gs;
  const EndPage({super.key, required this.gs});
  @override
  State<EndPage> createState() => _EndPageState();
}

class _EndPageState extends State<EndPage>
    with SingleTickerProviderStateMixin {
  late AnimationController c;
  bool surpriseOn = false;
  double surpriseT = 0;
  bool surpriseFired = false;
  double waitT = 0;

  @override
  void initState() {
    super.initState();
    c = AnimationController(vsync: this)..repeat();
    c.addListener(_tick);
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
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gs = widget.gs;
    final won = (gs.myRole == 'G' && gs.overSide == 'guard') ||
        (gs.myRole == 'A' && gs.overSide == 'anim');
    return AnimatedBuilder(
      animation: c,
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
                        color: Colors.red.al(0.25 + 0.2 * m.sin(surpriseT * 40).abs()))),
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
    canvas.drawCircle(c, rad + 14, Paint()..color = const Color(0xFF11112A).al(0.75));
    canvas.drawCircle(c, rad + 14, Paint()
      ..style = PaintingStyle.stroke..strokeWidth = 2
      ..color = const Color(0xFF4444AA).al(0.8));
    canvas.drawCircle(c, 4, Paint()..color = const Color(0xFF4444AA));
    canvas.drawCircle(c + v, 26, Paint()..color = const Color(0xFF8866FF).al(0.9));
    canvas.drawCircle(c + v, 26, Paint()
      ..style = PaintingStyle.stroke..strokeWidth = 2..color = Colors.white54);
  }

  @override
  bool shouldRepaint(JoyP old) => old.v != v;
}

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
        Paint()..color = const Color(0xFFFF0000).al(pulse));
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
      canvas.drawLine(p1, p2, Paint()..color = Colors.white.al(0.12)..strokeWidth = 2);
    }
  }

  @override
  bool shouldRepaint(JsP old) => true;
}

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
    ..color = cd.color.al(dark ? 0.25 : 0.5)
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
      canvas.drawPath(wing, Paint()..color = wc.al(0.95));
    }
  }
  if (ch == 10) {
    for (int i = 0; i < 3; i++) {
      final cen = Offset(o.dx + (i - 1) * s * 0.16, o.dy + s * (0.52 + i * 0.05));
      canvas.drawOval(
        Rect.fromCenter(center: cen, width: s * 0.3, height: s * 0.16),
        Paint()..color = body.al(0.25 - i * 0.06));
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
        Paint()..color = Colors.white.al(dark ? 0.4 : 1));
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
      ..color = const Color(0xFFFFF6B0).al(0.5)
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
    final tile = Paint()..color = Colors.white.al(0.03)..strokeWidth = 1;
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
      final coneC = [const Color(0xFFFFE9A0).al(0.10 * flick), const Color(0xFFFFE9A0).al(0.0)];
      canvas.drawPath(cone, Paint()
        ..shader = LinearGradient(begin: Alignment.topCenter,
            end: Alignment.bottomCenter, colors: coneC)
            .createShader(Rect.fromLTWH(0, 0, w, h)));
      canvas.drawOval(
        Rect.fromCenter(center: Offset(lampX, h * 0.078),
            width: w * 0.05, height: h * 0.014),
        Paint()..color = const Color(0xFFFFE9A0).al(0.9 * flick)
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
            Paint()..color = const Color(0xFF1DFF6E).al(0.14));
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
        Paint()..color = const Color(0xFF8899AA).al(vf.black ? 0.25 : 0.8));
    }
    canvas.restore();
    canvas.drawCircle(Offset(fx, fy), fr, Paint()
      ..style = PaintingStyle.stroke..strokeWidth = 2.5
      ..color = const Color(0xFF556677));
    canvas.drawCircle(Offset(fx, fy), fr * 0.16, Paint()..color = const Color(0xFF334455));
    if (vf.black) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = Colors.black.al(0.86 + 0.04 * m.sin(t * 3)));
      if (vf.thL >= 0 || vf.thR >= 0) {
        if (r.nextDouble() < 0.4) {
          final side = vf.thL >= 0 ? -1.0 : 1.0;
          final ex = w * 0.5 + side * w * 0.4;
          for (final d2 in [-1.0, 1.0]) {
            canvas.drawCircle(Offset(ex + d2 * w * 0.012, h * 0.45), 3, Paint()
              ..color = Colors.white.al(0.8)
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
        Paint()..color = CHARS[ch].color.al(0.9));
    canvas.drawCircle(Offset(c.dx + s * 0.22, c.dy - s * 0.3), s * 0.14,
        Paint()..color = CHARS[ch].color.al(0.9));
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
      final lightC = [const Color(0xFFFFE9A0).al(0.02), const Color(0xFFFFE9A0).al(0.2)];
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
        ..style = PaintingStyle.stroke..strokeWidth = 4..color = Colors.red.al(a));
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
            Paint()..color = Colors.black.al(0.25)..strokeWidth = 1.5);
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
          ..strokeCap = StrokeCap.round..color = vc.al(camMode ? 0.8 : 1));
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
        ..strokeCap = StrokeCap.round..color = dc.al(camMode ? 0.7 : 0.95));
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
          ..color = const Color(0xFFF1C40F).al(0.7));
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
          Paint()..color = const Color(0xFFF1C40F).al(0.25 * pl));
    }
    if (!jam) {
      for (final a in vf.actors) {
        if (camMode && (a.hd || a.iv)) continue;
        final p = sc(c, Offset(a.x, a.y), s);
        final col = CHARS[a.ch.clamp(0, CHARS.length - 1)].color;
        canvas.drawCircle(p, 20 * s, Paint()
          ..color = col.al(0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
        canvas.drawCircle(p, 14 * s, Paint()..color = col);
        canvas.drawCircle(p, 14 * s, Paint()
          ..style = PaintingStyle.stroke..strokeWidth = 2..color = Colors.white.al(0.7));
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
                ..color = Colors.red.al(0.9));
        }
      }
    }
    if (camMode) {
      canvas.drawRect(Offset.zero & size,
          Paint()..color = const Color(0xFF00FF66).al(0.05));
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
      white.color = Colors.white.al(a);
      final sw = r.nextDouble() * 2.2 + 0.6;
      final double sh = r.nextDouble() < 0.12 ? 2.0 : 1.0;
      canvas.drawRect(Rect.fromLTWH(r.nextDouble() * size.width,
          r.nextDouble() * size.height, sw, sh), white);
    }
    final scan = Paint()..color = Colors.black.al(jam ? 0.16 : 0.06);
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), scan);
    }
    if (jam || (heavy && r.nextDouble() < 0.35)) {
      final by = r.nextDouble() * size.height;
      final bh = 6 + r.nextDouble() * 26;
      canvas.drawRect(Rect.fromLTWH(0, by, size.width, bh),
          Paint()..color = Colors.white.al(0.08));
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
      Colors.transparent, Colors.black.al(0.55), Colors.black.al(0.85)
    ], stops: const [0.55, 0.85, 1.0]);
    canvas.drawRect(Offset.zero & size, Paint()..shader = grad.createShader(r2));
  }

  @override
  bool shouldRepaint(VignetteP old) => false;
}
// DOSYA SONU - SURUM 9 (tek dosya, LAN coklu oyunculu)
