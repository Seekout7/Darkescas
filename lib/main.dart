import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as m;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const FNAFApp());
}

class FNAFApp extends StatelessWidget {
  const FNAFApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF050508),
        colorScheme: const ColorScheme.dark(primary: Color(0xFFFFB300)),
      ),
      home: const RootPage(),
    );
  }
}

class Sfx {
  static void click() => SystemSound.play(SystemSoundType.click);
  static void alert() => SystemSound.play(SystemSoundType.alert);
  static void screamBurst() {
    SystemSound.play(SystemSoundType.alert);
    SystemSound.play(SystemSoundType.click);
  }
}

const kSmall = TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFBBBBBB), letterSpacing: 2);
const kTxt = TextStyle(fontSize: 14, color: Color(0xFFCCCCCC), height: 1.4);
const kHours = ['12 AM', '1 AM', '2 AM', '3 AM', '4 AM', '5 AM', '6 AM'];

class CharDef {
  final String name;
  final Color color;
  final double speed;
  final double cd;
  final String active;
  final String passive;
  const CharDef({required this.name, required this.color, required this.speed, required this.cd, required this.active, required this.passive});
}

const CHARS = [
  CharDef(name: 'KANAT', color: Color(0xFF873600), speed: 1.25, cd: 8, active: 'UCMAK', passive: 'hiz'),
  CharDef(name: 'GOLGE', color: Color(0xFF2C3E50), speed: 1.0, cd: 10, active: 'KAYBOL', passive: 'sessiz'),
  CharDef(name: 'FARE', color: Color(0xFF7D3C98), speed: 1.1, cd: 6, active: 'VENT', passive: 'vent'),
  CharDef(name: 'KAS', color: Color(0xFFCB4335), speed: 0.85, cd: 12, active: 'KIRMAK', passive: 'kapi'),
  CharDef(name: 'HACKER', color: Color(0xFF1ABC9C), speed: 1.0, cd: 15, active: 'JAM', passive: 'sessiz'),
  CharDef(name: 'ISIK', color: Color(0xFFFFD700), speed: 1.05, cd: 0, active: '-', passive: 'isikbagisik'),
  CharDef(name: 'GURULTU', color: Color(0xFFAF6025), speed: 1.0, cd: 8, active: 'SES', passive: '-'),
  CharDef(name: 'KORKU', color: Color(0xFF6C3483), speed: 1.0, cd: 0, active: '-', passive: '-'),
  CharDef(name: 'DALGA', color: Color(0xFF2E86AB), speed: 1.4, cd: 10, active: 'DASH', passive: 'hiz'),
  CharDef(name: 'ENERJI', color: Color(0xFFF39C12), speed: 1.0, cd: 12, active: 'DRAIN', passive: '-'),
  CharDef(name: 'SIS', color: Color(0xFFBDC3C7), speed: 1.05, cd: 15, active: 'ISIN', passive: 'sessiz'),
  CharDef(name: 'KUKLA', color: Color(0xFFE74C3C), speed: 1.0, cd: 10, active: 'CIGLIK', passive: 'sessiz'),
];

class MapNode {
  final String id;
  final double x;
  final double y;
  const MapNode({required this.id, required this.x, required this.y});
}

class MapEdge {
  final String a;
  final String b;
  final String kind;
  const MapEdge({required this.a, required this.b, required this.kind});
}

class GameMap {
  final String name;
  final List<MapNode> nodes;
  final List<MapEdge> edges;
  const GameMap({required this.name, required this.nodes, required this.edges});
}

const MAPS = [
  GameMap(
    name: 'PIZZERIA',
    nodes: [
      MapNode(id: 'O', x: 500, y: 500),
      MapNode(id: 'M1', x: 350, y: 500), MapNode(id: 'M2', x: 650, y: 500),
      MapNode(id: 'LC', x: 150, y: 500), MapNode(id: 'RC', x: 850, y: 500),
      MapNode(id: 'UC', x: 500, y: 150), MapNode(id: 'DC', x: 500, y: 850),
      MapNode(id: 'UL', x: 250, y: 250), MapNode(id: 'UR', x: 750, y: 250),
      MapNode(id: 'DL', x: 250, y: 750), MapNode(id: 'DR', x: 750, y: 750),
      MapNode(id: 'S1', x: 100, y: 200), MapNode(id: 'S2', x: 900, y: 200),
      MapNode(id: 'S3', x: 100, y: 800), MapNode(id: 'S4', x: 900, y: 800),
      MapNode(id: 'V1', x: 300, y: 400), MapNode(id: 'V2', x: 700, y: 400),
      MapNode(id: 'V3', x: 300, y: 600), MapNode(id: 'V4', x: 700, y: 600),
    ],
    edges: [
      MapEdge(a: 'O', b: 'M1', kind: 'doorL'), MapEdge(a: 'M1', b: 'LC', kind: ''),
      MapEdge(a: 'O', b: 'M2', kind: 'doorR'), MapEdge(a: 'M2', b: 'RC', kind: ''),
      MapEdge(a: 'O', b: 'UC', kind: 'vent'), MapEdge(a: 'O', b: 'DC', kind: ''),
      MapEdge(a: 'LC', b: 'UL', kind: ''), MapEdge(a: 'LC', b: 'DL', kind: ''),
      MapEdge(a: 'LC', b: 'V1', kind: ''), MapEdge(a: 'LC', b: 'V3', kind: ''),
      MapEdge(a: 'RC', b: 'UR', kind: ''), MapEdge(a: 'RC', b: 'DR', kind: ''),
      MapEdge(a: 'RC', b: 'V2', kind: ''), MapEdge(a: 'RC', b: 'V4', kind: ''),
      MapEdge(a: 'UC', b: 'UL', kind: ''), MapEdge(a: 'UC', b: 'UR', kind: ''),
      MapEdge(a: 'DC', b: 'DL', kind: ''), MapEdge(a: 'DC', b: 'DR', kind: ''),
      MapEdge(a: 'UL', b: 'V1', kind: ''), MapEdge(a: 'UR', b: 'V2', kind: ''),
      MapEdge(a: 'DL', b: 'V3', kind: ''), MapEdge(a: 'DR', b: 'V4', kind: ''),
      MapEdge(a: 'S1', b: 'UL', kind: ''), MapEdge(a: 'S1', b: 'DL', kind: ''),
      MapEdge(a: 'S2', b: 'UR', kind: ''), MapEdge(a: 'S2', b: 'UL', kind: ''),
      MapEdge(a: 'S3', b: 'DL', kind: ''), MapEdge(a: 'S3', b: 'DC', kind: ''),
      MapEdge(a: 'S4', b: 'DR', kind: ''), MapEdge(a: 'S4', b: 'DC', kind: ''),
    ],
  ),
  GameMap(
    name: 'HASTANE',
    nodes: [
      MapNode(id: 'O', x: 500, y: 500),
      MapNode(id: 'M1', x: 300, y: 500), MapNode(id: 'M2', x: 700, y: 500),
      MapNode(id: 'LC', x: 120, y: 500), MapNode(id: 'RC', x: 880, y: 500),
      MapNode(id: 'UC', x: 500, y: 180), MapNode(id: 'DC', x: 500, y: 820),
      MapNode(id: 'UL', x: 200, y: 200), MapNode(id: 'UR', x: 800, y: 200),
      MapNode(id: 'DL', x: 200, y: 800), MapNode(id: 'DR', x: 800, y: 800),
      MapNode(id: 'S1', x: 100, y: 350), MapNode(id: 'S2', x: 900, y: 650),
      MapNode(id: 'S3', x: 100, y: 650), MapNode(id: 'S4', x: 900, y: 350),
      MapNode(id: 'V1', x: 350, y: 350), MapNode(id: 'V2', x: 650, y: 350),
      MapNode(id: 'V3', x: 350, y: 650), MapNode(id: 'V4', x: 650, y: 650),
    ],
    edges: [
      MapEdge(a: 'O', b: 'M1', kind: 'doorL'), MapEdge(a: 'M1', b: 'LC', kind: ''),
      MapEdge(a: 'O', b: 'M2', kind: 'doorR'), MapEdge(a: 'M2', b: 'RC', kind: ''),
      MapEdge(a: 'O', b: 'UC', kind: 'vent'), MapEdge(a: 'O', b: 'DC', kind: ''),
      MapEdge(a: 'LC', b: 'UL', kind: ''), MapEdge(a: 'LC', b: 'DL', kind: ''),
      MapEdge(a: 'LC', b: 'V1', kind: ''), MapEdge(a: 'LC', b: 'V3', kind: ''),
      MapEdge(a: 'RC', b: 'UR', kind: ''), MapEdge(a: 'RC', b: 'DR', kind: ''),
      MapEdge(a: 'RC', b: 'V2', kind: ''), MapEdge(a: 'RC', b: 'V4', kind: ''),
      MapEdge(a: 'UC', b: 'UL', kind: ''), MapEdge(a: 'UC', b: 'UR', kind: ''),
      MapEdge(a: 'DC', b: 'DL', kind: ''), MapEdge(a: 'DC', b: 'DR', kind: ''),
      MapEdge(a: 'S1', b: 'UL', kind: ''), MapEdge(a: 'S1', b: 'LC', kind: ''),
      MapEdge(a: 'S2', b: 'DR', kind: ''), MapEdge(a: 'S2', b: 'RC', kind: ''),
      MapEdge(a: 'S3', b: 'DL', kind: ''), MapEdge(a: 'S3', b: 'LC', kind: ''),
      MapEdge(a: 'S4', b: 'UR', kind: ''), MapEdge(a: 'S4', b: 'RC', kind: ''),
      MapEdge(a: 'V1', b: 'UL', kind: ''), MapEdge(a: 'V1', b: 'UC', kind: ''),
      MapEdge(a: 'V2', b: 'UR', kind: ''), MapEdge(a: 'V2', b: 'UC', kind: ''),
      MapEdge(a: 'V3', b: 'DL', kind: ''), MapEdge(a: 'V3', b: 'DC', kind: ''),
      MapEdge(a: 'V4', b: 'DR', kind: ''), MapEdge(a: 'V4', b: 'DC', kind: ''),
    ],
  ),
  GameMap(
    name: 'OKUL',
    nodes: [
      MapNode(id: 'O', x: 500, y: 500),
      MapNode(id: 'M1', x: 340, y: 500), MapNode(id: 'M2', x: 660, y: 500),
      MapNode(id: 'LC', x: 160, y: 500), MapNode(id: 'RC', x: 840, y: 500),
      MapNode(id: 'UC', x: 500, y: 200), MapNode(id: 'DC', x: 500, y: 800),
      MapNode(id: 'UL', x: 260, y: 260), MapNode(id: 'UR', x: 740, y: 260),
      MapNode(id: 'DL', x: 260, y: 740), MapNode(id: 'DR', x: 740, y: 740),
      MapNode(id: 'S1', x: 100, y: 200), MapNode(id: 'S2', x: 900, y: 200),
      MapNode(id: 'S3', x: 100, y: 800), MapNode(id: 'S4', x: 900, y: 800),
      MapNode(id: 'C1', x: 350, y: 350), MapNode(id: 'C2', x: 650, y: 350),
      MapNode(id: 'C3', x: 350, y: 650), MapNode(id: 'C4', x: 650, y: 650),
    ],
    edges: [
      MapEdge(a: 'O', b: 'M1', kind: 'doorL'), MapEdge(a: 'M1', b: 'LC', kind: ''),
      MapEdge(a: 'O', b: 'M2', kind: 'doorR'), MapEdge(a: 'M2', b: 'RC', kind: ''),
      MapEdge(a: 'O', b: 'UC', kind: 'vent'), MapEdge(a: 'O', b: 'DC', kind: ''),
      MapEdge(a: 'LC', b: 'UL', kind: ''), MapEdge(a: 'LC', b: 'DL', kind: ''),
      MapEdge(a: 'RC', b: 'UR', kind: ''), MapEdge(a: 'RC', b: 'DR', kind: ''),
      MapEdge(a: 'UC', b: 'UL', kind: ''), MapEdge(a: 'UC', b: 'UR', kind: ''),
      MapEdge(a: 'DC', b: 'DL', kind: ''), MapEdge(a: 'DC', b: 'DR', kind: ''),
      MapEdge(a: 'S1', b: 'UL', kind: ''), MapEdge(a: 'S2', b: 'UR', kind: ''),
      MapEdge(a: 'S3', b: 'DL', kind: ''), MapEdge(a: 'S4', b: 'DR', kind: ''),
      MapEdge(a: 'C1', b: 'UL', kind: ''), MapEdge(a: 'C1', b: 'LC', kind: ''), MapEdge(a: 'C1', b: 'UC', kind: ''),
      MapEdge(a: 'C2', b: 'UR', kind: ''), MapEdge(a: 'C2', b: 'RC', kind: ''), MapEdge(a: 'C2', b: 'UC', kind: ''),
      MapEdge(a: 'C3', b: 'DL', kind: ''), MapEdge(a: 'C3', b: 'LC', kind: ''), MapEdge(a: 'C3', b: 'DC', kind: ''),
      MapEdge(a: 'C4', b: 'DR', kind: ''), MapEdge(a: 'C4', b: 'RC', kind: ''), MapEdge(a: 'C4', b: 'DC', kind: ''),
    ],
  ),
];

class _Actor {
  String id;
  String name;
  bool guard;
  int charIdx;
  double x;
  double y;
  String nodeId;
  double wait;
  double stun;
  bool hd;
  bool iv;
  double cd;
  double joyX;
  double joyY;
  _Actor({
    required this.id, required this.name, required this.guard, this.charIdx = 0,
    this.x = 500, this.y = 500, this.nodeId = 'O', this.wait = 0,
    this.stun = 0, this.hd = false, this.iv = false, this.cd = 0,
    this.joyX = 0, this.joyY = 0,
  });
  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'g': guard, 'c': charIdx,
    'x': x, 'y': y, 'n': nodeId, 'w': wait, 's': stun,
    'h': hd, 'i': iv, 'cd': cd,
  };
  static _Actor fromJson(Map<String, dynamic> j) => _Actor(
    id: j['id'] ?? '', name: j['name'] ?? '', guard: j['g'] == true,
    charIdx: j['c'] ?? 0, x: (j['x'] ?? 500).toDouble(),
    y: (j['y'] ?? 500).toDouble(), nodeId: j['n'] ?? 'O',
    wait: (j['w'] ?? 0).toDouble(), stun: (j['s'] ?? 0).toDouble(),
    hd: j['h'] == true, iv: j['i'] == true, cd: (j['cd'] ?? 0).toDouble(),
  );
}

class _Player {
  String id;
  String name;
  int charIdx;
  _Player({required this.id, required this.name, this.charIdx = 0});
}

class _HostInfo {
  String hostId;
  String hostName;
  String ip;
  int port;
  int players;
  _HostInfo(this.hostId, this.hostName, this.ip, this.port, this.players);
}

class VF {
  double t = 0;
  int hour = 0;
  double power = 100;
  int usage = 1;
  bool dl = false;
  bool dr = false;
  bool light = false;
  bool cam = false;
  bool vent = false;
  double forceL = 0;
  double forceR = 0;
  double waitL = 0;
  double waitR = 0;
  int thL = -1;
  int thR = -1;
  double ddL = 0;
  double ddR = 0;
  double jam = 0;
  double blind = 0;
  bool black = false;
  List<_Actor> actors = [];
  List<String> noise = [];
}

class Net {
  RawDatagramSocket? _s;
  bool isHost = false;
  String myId = '';
  String myName = 'Oyuncu';
  String hostId = '';
  final Map<String, _HostInfo> discovered = {};
  Timer? _discTimer;
  final List<_Player> players = [];
  int soloDiff = 1;
  int soloCount = 1;
  int mapIdx = 0;
  bool inGame = false;
  bool aiMode = false;
  bool solo = false;
  String myRole = '';
  int myChar = 0;
  String myPid = '';
  double gt = 0;
  bool over = false;
  String overSide = '';
  String overReason = '';
  int overJs = -1;
  double endDelay = 0;
  bool surprise = false;
  String status = 'Baglanti kurulmadi';
  int page = 0;
  VoidCallback? onUpdate;
  final VF _vf = VF();
  final List<_Actor> _actors = [];
  double _power = 100;
  bool _dl = false;
  bool _dr = false;
  bool _light = false;
  bool _cam = false;
  bool _vent = false;
  double _forceL = 0;
  double _forceR = 0;
  double _waitL = 0;
  double _waitR = 0;
  int _thL = -1;
  int _thR = -1;
  double _ddL = 0;
  double _ddR = 0;
  double _jam = 0;
  double _blind = 0;
  bool _black = false;
  final List<String> _noise = [];
  double shakeX = 0;
  double shakeY = 0;
  double dlShow = 0;
  double drShow = 0;
  double fanA = 0;
  double _shT = 0;
  final m.Random _r = m.Random();
  Timer? _gameTimer;
  int _port = 49152;

  Future<void> init() async {
    _s = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _s!.broadcastEnabled = true;
    myId = '${DateTime.now().millisecondsSinceEpoch}_${_r.nextInt(99999)}';
    myPid = myId;
    _s!.listen(_onMsg);
    status = 'UDP hazir - port ${_s!.port}';
    onUpdate?.call();
  }

  void _send(String type, Map<String, dynamic> data, String ip, int port) {
    if (_s == null) return;
    try {
      final bytes = utf8.encode(jsonEncode({'type': type, ...data}));
      _s!.send(bytes, InternetAddress(ip), port);
    } catch (_) {}
  }

  void _broadcast(String type, Map<String, dynamic> data) {
    if (_s == null) return;
    try {
      final bytes = utf8.encode(jsonEncode({'type': type, ...data}));
      _s!.send(bytes, InternetAddress('255.255.255.255'), _port);
    } catch (_) {}
  }

  void _onMsg(RawSocketEvent e) {
    if (e != RawSocketEvent.read) return;
    final p = _s!.receive();
    if (p == null) return;
    try {
      final msg = jsonDecode(utf8.decode(p.data)) as Map<String, dynamic>;
      _handle(msg, p.address.address, p.port);
    } catch (_) {}
  }

  void _handle(Map<String, dynamic> m, String ip, int port) {
    final t = m['type'];
    switch (t) {
      case 'discover':
        if (isHost) _sendHostInfo(ip, port);
        break;
      case 'hostinfo':
        _gotHostInfo(m, ip, port);
        break;
      case 'hello':
        if (isHost) _gotHello(m, ip, port);
        break;
      case 'welcome':
        _gotWelcome(m);
        break;
      case 'lobby':
        _gotLobby(m);
        break;
      case 'start':
        _gotStart(m);
        break;
      case 'act':
        if (isHost) _gotAct(m, ip, port);
        break;
      case 'snap':
        _gotSnap(m);
        break;
      case 'over':
        _gotOver(m);
        break;
      case 'leave':
        _gotLeave(m);
        break;
      case 'err':
        status = m['msg'] ?? 'Hata';
        onUpdate?.call();
        break;
    }
  }

  Future<void> hostGame() async {
    isHost = true;
    hostId = myId;
    players.clear();
    players.add(_Player(id: myId, name: myName));
    status = 'Host olundu - yayin yapiliyor';
    page = 2;
    _discTimer?.cancel();
    _discTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _broadcast('hostinfo', {'hid': myId, 'hname': myName, 'n': players.length, 'p': _s!.port});
    });
    onUpdate?.call();
  }

  void _sendHostInfo(String ip, int port) {
    _send('hostinfo', {'hid': myId, 'hname': myName, 'n': players.length, 'p': _s!.port}, ip, port);
  }

  void _gotHostInfo(Map<String, dynamic> m, String ip, int port) {
    final hid = m['hid'] as String? ?? '';
    if (hid.isEmpty || hid == myId) return;
    discovered[hid] = _HostInfo(
      hid, m['hname'] as String? ?? 'Host', ip,
      m['p'] as int? ?? 49152, m['n'] as int? ?? 1,
    );
    onUpdate?.call();
  }

  Future<void> joinByIp(String ip) async {
    if (ip.isEmpty) {
      status = 'IP gecersiz';
      onUpdate?.call();
      return;
    }
    status = 'Katiliniyor: $ip';
    onUpdate?.call();
    _send('hello', {'pid': myId, 'name': myName}, ip, _port);
    hostId = '';
  }

  Future<void> joinHost(_HostInfo h) async {
    status = 'Katiliniyor: ${h.hostName}';
    onUpdate?.call();
    _send('hello', {'pid': myId, 'name': myName}, h.ip, h.port);
    hostId = h.hostId;
  }

  void _gotHello(Map<String, dynamic> m, String ip, int port) {
    if (!isHost) return;
    if (inGame) {
      _send('err', {'msg': 'Oyun basladi'}, ip, port);
      return;
    }
    if (players.length >= 4) {
      _send('err', {'msg': 'Lobi dolu'}, ip, port);
      return;
    }
    final pid = m['pid'] as String? ?? '';
    final name = m['name'] as String? ?? 'Oyuncu';
    if (pid.isEmpty || players.any((p) => p.id == pid)) return;
    players.add(_Player(id: pid, name: name));
    _send('welcome', {
      'hid': myId, 'pid': pid,
      'players': players.map((p) => {'id': p.id, 'name': p.name, 'c': p.charIdx}).toList(),
    }, ip, port);
    _broadcastLobby();
    onUpdate?.call();
  }

  void _gotWelcome(Map<String, dynamic> m) {
    if (isHost) return;
    hostId = m['hid'] as String? ?? '';
    myPid = m['pid'] as String? ?? myId;
    final plist = m['players'] as List<dynamic>? ?? [];
    players.clear();
    for (final p in plist) {
      final pm = p as Map<String, dynamic>;
      players.add(_Player(id: pm['id'] as String? ?? '', name: pm['name'] as String? ?? '', charIdx: pm['c'] as int? ?? 0));
    }
    status = 'Lobiye katildin';
    page = 2;
    onUpdate?.call();
  }

  void _broadcastLobby() {
    if (!isHost) return;
    _broadcast('lobby', {
      'players': players.map((p) => {'id': p.id, 'name': p.name, 'c': p.charIdx}).toList(),
      'mapIdx': mapIdx,
    });
  }

  void _gotLobby(Map<String, dynamic> m) {
    if (isHost) return;
    final plist = m['players'] as List<dynamic>? ?? [];
    players.clear();
    for (final p in plist) {
      final pm = p as Map<String, dynamic>;
      players.add(_Player(id: pm['id'] as String? ?? '', name: pm['name'] as String? ?? '', charIdx: pm['c'] as int? ?? 0));
    }
    mapIdx = m['mapIdx'] as int? ?? 0;
    onUpdate?.call();
  }

  void setMyChar(int c) {
    myChar = c;
    if (isHost) {
      final me = players.firstWhere((p) => p.id == myId, orElse: () => players.first);
      me.charIdx = c;
      _broadcastLobby();
    } else {
      _send('act', {'k': 'char', 'v': c, 'pid': myId}, hostId, _port);
    }
    onUpdate?.call();
  }

  void setHostMap(int i) {
    if (!isHost) return;
    mapIdx = i;
    _broadcastLobby();
    onUpdate?.call();
  }

  void _gotAct(Map<String, dynamic> m, String ip, int port) {
    final pid = m['pid'] as String? ?? '';
    final k = m['k'] as String? ?? '';
    final v = m['v'];
    if (!inGame) {
      if (k == 'char') {
        final p = players.firstWhere((pl) => pl.id == pid, orElse: () => _Player(id: '', name: ''));
        if (p.id.isNotEmpty) p.charIdx = v as int;
        _broadcastLobby();
      }
      return;
    }
    _applyAct(pid, k, v);
    onUpdate?.call();
  }

  void _applyAct(String pid, String k, dynamic v) {
    switch (k) {
      case 'dl':
        if (!_black && _ddL <= 0) { _dl = !_dl; _ddL = 0.3; Sfx.click(); }
        break;
      case 'dr':
        if (!_black && _ddR <= 0) { _dr = !_dr; _ddR = 0.3; Sfx.click(); }
        break;
      case 'li':
        if (!_black) { _light = !_light; Sfx.click(); }
        break;
      case 'cm':
        if (!_black && (_jam <= 0 || _cam)) { _cam = !_cam; Sfx.click(); }
        break;
      case 'vt':
        if (!_black) { _vent = !_vent; Sfx.click(); }
        break;
      case 'joy':
        final a = _actors.firstWhere((x) => x.id == pid, orElse: () => _Actor(id: '', name: '', guard: false));
        if (a.id.isNotEmpty) {
          a.joyX = (v as List).first.toDouble();
          a.joyY = v.last.toDouble();
        }
        break;
      case 'ctx':
        _doAnimAct(pid, v as String? ?? '');
        break;
      case 'abil':
        _useAbility(pid);
        break;
      case 'char':
        final p = players.firstWhere((pl) => pl.id == pid, orElse: () => _Player(id: '', name: ''));
        if (p.id.isNotEmpty) p.charIdx = v as int;
        _broadcastLobby();
        break;
    }
  }

  void _doAnimAct(String pid, String act) {
    final a = _actors.firstWhere((x) => x.id == pid, orElse: () => _Actor(id: '', name: '', guard: false));
    if (a.id.isEmpty) return;
    switch (act) {
      case 'ZORLA':
        if (a.nodeId == 'M1' && _dl) a.wait = 5;
        else if (a.nodeId == 'M2' && _dr) a.wait = 5;
        break;
      case 'VENT':
        if (a.nodeId == 'UC' || a.nodeId == 'O') a.nodeId = 'UC';
        break;
      case 'SALDIR':
        if (a.nodeId == 'O') _endGame('anim', '${a.name} saldirdi!');
        break;
    }
  }

  void _useAbility(String pid) {
    final a = _actors.firstWhere((x) => x.id == pid, orElse: () => _Actor(id: '', name: '', guard: false));
    if (a.id.isEmpty || a.cd > 0) return;
    final ch = CHARS[a.charIdx.clamp(0, CHARS.length - 1)];
    a.cd = ch.cd;
    switch (ch.name) {
      case 'KANAT': a.x += 150; break;
      case 'GOLGE':
        a.iv = true;
        Future.delayed(const Duration(seconds: 3), () => a.iv = false);
        break;
      case 'FARE':
        if (a.nodeId == 'UC' || a.nodeId == 'DC') a.nodeId = 'O';
        break;
      case 'KAS':
        if (a.nodeId == 'M1') { _forceL = 3; _dl = true; }
        else if (a.nodeId == 'M2') { _forceR = 3; _dr = true; }
        break;
      case 'HACKER': _jam = 5; break;
      case 'GURULTU': _noise.add(a.nodeId); break;
      case 'DALGA': a.x += 200; break;
      case 'ENERJI': _power = m.max(0, _power - 10); break;
      case 'SIS': a.nodeId = _randomNode(); break;
      case 'KUKLA': _blind = m.max(_blind, 1.5); break;
    }
  }

  String _randomNode() {
    const nodes = ['LC', 'RC', 'UC', 'DC', 'UL', 'UR', 'DL', 'DR', 'S1', 'S2', 'S3', 'S4'];
    return nodes[_r.nextInt(nodes.length)];
  }

  Future<void> startGame() async {
    if (!isHost) return;
    if (players.length < 2) {
      status = 'En az 2 oyuncu gerekli';
      onUpdate?.call();
      return;
    }
    inGame = true;
    _initGame();
    _broadcast('start', {
      'mapIdx': mapIdx,
      'roles': _actors.map((a) => {'id': a.id, 'g': a.guard, 'c': a.charIdx}).toList(),
    });
    _startGameTimer();
    onUpdate?.call();
  }

  void _gotStart(Map<String, dynamic> m) {
    if (isHost) return;
    inGame = true;
    mapIdx = m['mapIdx'] as int? ?? 0;
    _initGame();
    final roles = m['roles'] as List<dynamic>? ?? [];
    for (final r in roles) {
      final rm = r as Map<String, dynamic>;
      final id = rm['id'] as String? ?? '';
      final a = _actors.firstWhere((x) => x.id == id, orElse: () => _Actor(id: '', name: '', guard: false));
      if (a.id.isNotEmpty) {
        a.guard = rm['g'] == true;
        a.charIdx = rm['c'] as int? ?? 0;
        if (a.id == myId) {
          myRole = a.guard ? 'G' : 'A';
          myChar = a.charIdx;
        }
      }
    }
    page = 3;
    onUpdate?.call();
  }

  void _initGame() {
    _actors.clear();
    final plist = [...players];
    if (isHost || solo) {
      final guard = plist.first;
      guard.charIdx = 0;
      _actors.add(_Actor(id: guard.id, name: guard.name, guard: true, x: 500, y: 500, nodeId: 'O'));
      final animCount = solo ? soloCount : plist.length - 1;
      for (int i = 0; i < animCount; i++) {
        if (i + 1 < plist.length && !solo) {
          _actors.add(_Actor(
            id: plist[i + 1].id, name: plist[i + 1].name, guard: false,
            charIdx: plist[i + 1].charIdx, x: 100 + i * 50.0, y: 200, nodeId: 'S1',
          ));
        } else {
          final names = ['Kanat', 'Golge', 'Fare', 'Kas', 'Hacker', 'Isik'];
          _actors.add(_Actor(
            id: 'AI_$i', name: names[i % names.length], guard: false,
            charIdx: i % CHARS.length, x: 200 + i * 100.0, y: 300, nodeId: 'S1',
          ));
        }
      }
    } else {
      for (final p in plist) {
        _actors.add(_Actor(id: p.id, name: p.name, guard: false));
      }
    }
    _power = 100;
    _dl = false; _dr = false; _light = false; _cam = false; _vent = false;
    gt = 0; over = false; _black = false;
    _forceL = 0; _forceR = 0; _waitL = 0; _waitR = 0;
    _thL = -1; _thR = -1; _jam = 0; _blind = 0;
    _noise.clear();
  }

  void _startGameTimer() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!inGame || over) return;
      _frame(0.05);
    });
  }

  void _frame(double dt) {
    gt += dt;
    _vf.t += dt;
    _vf.hour = (gt / 60).floor().clamp(0, 6);
    fanA += dt * 8;
    if (_ddL > 0) _ddL -= dt;
    if (_ddR > 0) _ddR -= dt;
    if (_forceL > 0) _forceL -= dt;
    if (_forceR > 0) _forceR -= dt;
    if (_jam > 0) _jam -= dt;
    if (_blind > 0) _blind -= dt;
    int usage = 1;
    if (_dl) usage++;
    if (_dr) usage++;
    if (_light) usage++;
    if (_cam) usage++;
    if (_vent) usage++;
    _power -= dt * usage * 0.4;
    if (_power <= 0 && !_black) {
      _power = 0;
      _black = true;
      _dl = false; _dr = false; _light = false; _cam = false; _vent = false;
      Sfx.alert();
    }
    if (_power < 0) _power = 0;
    if (_shT > 0) {
      _shT -= dt;
      shakeX = (_r.nextDouble() * 2 - 1) * 8 * _shT;
      shakeY = (_r.nextDouble() * 2 - 1) * 8 * _shT;
    } else { shakeX = 0; shakeY = 0; }
    dlShow += ((_dl ? 1.0 : 0.0) - dlShow) * dt * 4;
    drShow += ((_dr ? 1.0 : 0.0) - drShow) * dt * 4;
    for (final a in _actors) {
      if (a.cd > 0) a.cd -= dt;
      if (a.stun > 0) { a.stun -= dt; continue; }
      if (!a.guard) {
        _moveAnim(a, dt);
        if (a.nodeId == 'M1') {
          if (_dl) {
            a.wait += dt;
            if (a.wait >= 5) { _endGame('anim', '${a.name} kapidan iceri girdi!'); return; }
          } else {
            if (a.wait > 0.1) { a.nodeId = _randomNode(); a.stun = 3; a.wait = 0; }
          }
          _waitL = a.wait; _thL = a.charIdx;
        } else if (a.nodeId == 'M2') {
          if (_dr) {
            a.wait += dt;
            if (a.wait >= 5) { _endGame('anim', '${a.name} kapidan iceri girdi!'); return; }
          } else {
            if (a.wait > 0.1) { a.nodeId = _randomNode(); a.stun = 3; a.wait = 0; }
          }
          _waitR = a.wait; _thR = a.charIdx;
        } else if (a.nodeId == 'O') {
          _endGame('anim', '${a.name} ofise girdi!');
          return;
        } else { a.wait = 0; }
      }
    }
    if (gt >= 360) {
      _endGame('guard', 'Sabah 6 ya kadar hayatta kaldi!');
      return;
    }
    if (gt > 30 && _r.nextDouble() < 0.0005) {
      surprise = true;
      _shT = 1.5;
      Sfx.screamBurst();
    }
    if (isHost || solo) _broadcastSnap();
    onUpdate?.call();
  }

  void _moveAnim(_Actor a, double dt) {
    if (a.joyX == 0 && a.joyY == 0) return;
    final map = MAPS[mapIdx];
    final speed = CHARS[a.charIdx.clamp(0, CHARS.length - 1)].speed * 100;
    a.x += a.joyX * speed * dt;
    a.y += a.joyY * speed * dt;
    for (final n in map.nodes) {
      if (n.id == a.nodeId) continue;
      final dx = n.x - a.x;
      final dy = n.y - a.y;
      if (dx * dx + dy * dy < 40 * 40) {
        bool connected = false;
        String kind = '';
        for (final e in map.edges) {
          if ((e.a == a.nodeId && e.b == n.id) || (e.b == a.nodeId && e.a == n.id)) {
            connected = true;
            kind = e.kind;
            break;
          }
        }
        if (!connected) continue;
        if (n.id == 'O' && !_dl && !_dr) continue;
        if ((kind == 'doorL' && !_dl) || (kind == 'doorR' && !_dr)) continue;
        a.nodeId = n.id;
        a.x = n.x;
        a.y = n.y;
        break;
      }
    }
  }

  void _broadcastSnap() {
    _broadcast('snap', {
      'gt': gt, 'p': _power, 'dl': _dl, 'dr': _dr,
      'li': _light, 'cm': _cam, 'vt': _vent,
      'fl': _forceL, 'fr': _forceR, 'wl': _waitL, 'wr': _waitR,
      'tl': _thL, 'tr': _thR, 'jl': _jam, 'bl': _blind,
      'bk': _black, 'ddl': _ddL, 'ddr': _ddR,
      'actors': _actors.map((a) => a.toJson()).toList(),
    });
  }

  void _gotSnap(Map<String, dynamic> m) {
    if (isHost) return;
    gt = (m['gt'] ?? 0).toDouble();
    _power = (m['p'] ?? 100).toDouble();
    _dl = m['dl'] == true; _dr = m['dr'] == true;
    _light = m['li'] == true; _cam = m['cm'] == true; _vent = m['vt'] == true;
    _forceL = (m['fl'] ?? 0).toDouble(); _forceR = (m['fr'] ?? 0).toDouble();
    _waitL = (m['wl'] ?? 0).toDouble(); _waitR = (m['wr'] ?? 0).toDouble();
    _thL = m['tl'] as int? ?? -1; _thR = m['tr'] as int? ?? -1;
    _jam = (m['jl'] ?? 0).toDouble(); _blind = (m['bl'] ?? 0).toDouble();
    _black = m['bk'] == true;
    _ddL = (m['ddl'] ?? 0).toDouble(); _ddR = (m['ddr'] ?? 0).toDouble();
    final alist = m['actors'] as List<dynamic>? ?? [];
    _actors.clear();
    for (final a in alist) _actors.add(_Actor.fromJson(a as Map<String, dynamic>));
    final me = _actors.firstWhere((x) => x.id == myId, orElse: () => _Actor(id: '', name: '', guard: false));
    if (me.id.isNotEmpty) { myRole = me.guard ? 'G' : 'A'; myChar = me.charIdx; }
    if (page != 3) page = 3;
    onUpdate?.call();
  }

  void _endGame(String side, String reason) {
    over = true;
    overSide = side;
    overReason = reason;
    overJs = side == 'anim' ? -1 : 0;
    final anims = _actors.where((a) => !a.guard).toList();
    if (anims.isNotEmpty && side == 'anim') overJs = anims[_r.nextInt(anims.length)].charIdx;
    page = 4;
    endDelay = 0;
    if (isHost) _broadcast('over', {'side': side, 'reason': reason, 'js': overJs});
    onUpdate?.call();
  }

  void _gotOver(Map<String, dynamic> m) {
    if (isHost) return;
    over = true;
    overSide = m['side'] as String? ?? 'guard';
    overReason = m['reason'] as String? ?? '';
    overJs = m['js'] as int? ?? -1;
    page = 4;
    onUpdate?.call();
  }

  void _gotLeave(Map<String, dynamic> m) {
    final pid = m['pid'] as String? ?? '';
    players.removeWhere((p) => p.id == pid);
    _actors.removeWhere((a) => a.id == pid);
    if (isHost) _broadcastLobby();
    onUpdate?.call();
  }

  void setName(String n) { myName = n.isEmpty ? 'Oyuncu' : n; onUpdate?.call(); }

  void startDiscovery() {
    discovered.clear();
    page = 1;
    status = 'Hostlar araniyor...';
    _discTimer?.cancel();
    _discTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _broadcast('discover', {'pid': myId});
      onUpdate?.call();
    });
    onUpdate?.call();
  }

  void stopDiscovery() { _discTimer?.cancel(); _discTimer = null; }

  void leaveRoom() {
    _gameTimer?.cancel();
    _discTimer?.cancel();
    inGame = false;
    over = false;
    isHost = false;
    hostId = '';
    players.clear();
    _actors.clear();
    discovered.clear();
    page = 0;
    status = 'Baglanti kesildi';
    _broadcast('leave', {'pid': myId});
    onUpdate?.call();
  }

  void toLobbyAll() {
    if (isHost) {
      inGame = false;
      over = false;
      page = 2;
      _broadcastLobby();
    } else {
      page = 2;
    }
    onUpdate?.call();
  }

  void setSoloDiff(int i) { soloDiff = i; onUpdate?.call(); }
  void setSoloCount(int i) { soloCount = i; onUpdate?.call(); }
  void setSoloMap(int i) { mapIdx = i; onUpdate?.call(); }

  void startSolo() {
    aiMode = true;
    solo = true;
    inGame = true;
    myRole = 'G';
    players.clear();
    players.add(_Player(id: myId, name: myName));
    _initGame();
    page = 3;
    isHost = true;
    _startGameTimer();
    onUpdate?.call();
  }

  void gAct(String k) {
    if (isHost || solo) _applyAct(myId, k, null);
    else _send('act', {'k': k, 'pid': myId}, hostId, _port);
    onUpdate?.call();
  }

  void sendJoy(double x, double y) {
    if (isHost || solo) {
      final a = _actors.firstWhere((ac) => ac.id == myId, orElse: () => _Actor(id: '', name: '', guard: false));
      if (a.id.isNotEmpty) { a.joyX = x; a.joyY = y; }
    } else {
      _send('act', {'k': 'joy', 'v': [x, y], 'pid': myId}, hostId, _port);
    }
  }

  String? ctxLabel(VF vf) {
    if (myRole != 'A') return null;
    final me = _actors.firstWhere((a) => a.id == myId, orElse: () => _Actor(id: '', name: '', guard: false));
    if (me.id.isEmpty) return null;
    switch (me.nodeId) {
      case 'M1':
      case 'M2':
        if (_dl || _dr) return 'ZORLA';
        return 'BEKLE';
      case 'UC':
      case 'DC':
        return 'VENT';
      case 'O':
        return 'SALDIR';
      default:
        return null;
    }
  }

  void doCtx() {
    final lbl = ctxLabel(_vf);
    if (lbl == null) return;
    if (isHost || solo) _applyAct(myId, 'ctx', lbl);
    else _send('act', {'k': 'ctx', 'v': lbl, 'pid': myId}, hostId, _port);
  }

  void useAbility() {
    if (isHost || solo) _applyAct(myId, 'abil', null);
    else _send('act', {'k': 'abil', 'pid': myId}, hostId, _port);
  }

  VF vf(int now) {
    _vf.hour = (gt / 60).floor().clamp(0, 6);
    _vf.power = _power;
    _vf.dl = _dl; _vf.dr = _dr; _vf.light = _light;
    _vf.cam = _cam; _vf.vent = _vent;
    _vf.forceL = _forceL; _vf.forceR = _forceR;
    _vf.waitL = _waitL; _vf.waitR = _waitR;
    _vf.thL = _thL; _vf.thR = _thR;
    _vf.ddL = _ddL; _vf.ddR = _ddR;
    _vf.jam = _jam; _vf.blind = _blind;
    _vf.black = _black;
    _vf.actors = [..._actors];
    _vf.noise = [..._noise];
    int u = 1;
    if (_dl) u++; if (_dr) u++; if (_light) u++; if (_cam) u++; if (_vent) u++;
    _vf.usage = u;
    return _vf;
  }

  GameMap get curMap => MAPS[mapIdx.clamp(0, MAPS.length - 1)];

  void dispose() {
    _gameTimer?.cancel();
    _discTimer?.cancel();
    _s?.close();
  }
}

class RootPage extends StatefulWidget {
  const RootPage({super.key});
  @override
  State<RootPage> createState() => _RootPageState();
}

class _RootPageState extends State<RootPage> {
  final Net gs = Net();
  @override
  void initState() {
    super.initState();
    gs.onUpdate = () { if (mounted) setState(() {}); };
    gs.init();
  }
  @override
  void dispose() { gs.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    switch (gs.page) {
      case 0: return MenuPage(gs: gs);
      case 1: return FindPage(gs: gs);
      case 2: return LobbyPage(gs: gs);
      case 3: return GamePage(gs: gs);
      case 4: return EndPage(gs: gs);
      case 5: return SoloSetupPage(gs: gs);
      default: return MenuPage(gs: gs);
    }
  }
}

class MenuPage extends StatefulWidget {
  final Net gs;
  const MenuPage({super.key, required this.gs});
  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final _nameCtl = TextEditingController(text: 'Oyuncu');
  final _ipCtl = TextEditingController();
  bool _showIp = false;
  @override
  void dispose() { _nameCtl.dispose(); _ipCtl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final gs = widget.gs;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0A0612), Color(0xFF000000)]),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 30),
                const Text(
                  'GECE\nVARDIYASI',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, letterSpacing: 8, color: Color(0xFFFFB300), height: 0.9,
                    shadows: [Shadow(color: Color(0xFFFF2200), blurRadius: 30), Shadow(color: Color(0xFFFF0000), blurRadius: 60)]),
                ),
                const SizedBox(height: 6),
                const Text('FNAF TARZI KORKU OYUNU', textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF888888), letterSpacing: 4)),
                const SizedBox(height: 30),
                SizedBox(height: 180, child: CustomPaint(size: const Size(double.infinity, 180),
                  painter: MenuAnimP(t: DateTime.now().millisecondsSinceEpoch / 1000))),
                const SizedBox(height: 30),
                TextField(controller: _nameCtl, onChanged: gs.setName,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(labelText: 'KARAKTER ADI', labelStyle: const TextStyle(color: Color(0xFF888888)),
                    filled: true, fillColor: const Color(0xFF111122),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF333355))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF333355)))),
                const SizedBox(height: 20),
                Btn(t: 'HOST OL', on: () { gs.setName(_nameCtl.text); gs.hostGame(); }, c: const Color(0xFFD35400)),
                const SizedBox(height: 12),
                Btn(t: 'LOBI ARA', on: () { gs.setName(_nameCtl.text); gs.startDiscovery(); }, c: const Color(0xFF1F618D)),
                const SizedBox(height: 12),
                Btn(t: 'IP ILE KATIL', on: () { setState(() => _showIp = !_showIp); }, c: const Color(0xFF7D3C98)),
                if (_showIp) ...[
                  const SizedBox(height: 12),
                  TextField(controller: _ipCtl, style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(hintText: 'ornek: 192.168.1.100', filled: true, fillColor: const Color(0xFF111122),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF333355)))),
                  const SizedBox(height: 8),
                  Btn(t: 'BAGLAN', on: () { gs.setName(_nameCtl.text); gs.joinByIp(_ipCtl.text); }, c: const Color(0xFF27AE60), expand: false),
                ],
                const SizedBox(height: 12),
                Btn(t: 'TEK KISILIK MOD', on: () { gs.setName(_nameCtl.text); gs.aiMode = true; gs.solo = true; gs.page = 5; gs.onUpdate?.call(); }, c: const Color(0xFF555577)),
                const SizedBox(height: 20),
                Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFF111122), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF333355))),
                  child: Text(gs.status, style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 12), textAlign: TextAlign.center)),
                const SizedBox(height: 30),
                const Text('Nasil Oynanir?', style: TextStyle(color: Color(0xFFFFB300), fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 2)),
                const SizedBox(height: 8),
                const Text('GUVENLIK: Kapilari ve isiklari yoneterek sabah 6 ya kadar hayatta kal.\n\nANIMATRONIK: Koridorlarda gezin, kapilari zorla, havalandirmaya gir, guvenligi yakala.', style: kTxt),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SoloSetupPage extends StatelessWidget {
  final Net gs;
  const SoloSetupPage({super.key, required this.gs});
  @override
  Widget build(BuildContext context) {
    const diffs = ['KOLAY', 'NORMAL', 'KABUS'];
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0A0612), Color(0xFF000000)])),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  const Text('TEK KISILIK YZ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2, color: Color(0xFFFFB300))),
                  const Spacer(),
                  Btn(t: 'GERI', on: () { gs.page = 0; gs.onUpdate?.call(); }, expand: false, c: const Color(0xFF555577)),
                ]),
                const SizedBox(height: 8),
                const Text('Sen guvenliksin. YZ animatronikler seni avlar. Sabah 6 ya kadar hayatta kal.', style: kTxt),
                const SizedBox(height: 16),
                const Text('ZORLUK:', style: kSmall),
                const SizedBox(height: 6),
                Row(children: [
                  for (int i = 0; i < 3; i++)
                    Padding(padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(onTap: () => gs.setSoloDiff(i), child: chip(diffs[i], const Color(0xFFE74C3C), on: gs.soloDiff == i))),
                ]),
                const SizedBox(height: 14),
                const Text('ANIMATRONIK SAYISI:', style: kSmall),
                const SizedBox(height: 6),
                Row(children: [
                  for (int i = 1; i <= 3; i++)
                    Padding(padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(onTap: () => gs.setSoloCount(i), child: chip('$i', const Color(0xFF8E44AD), on: gs.soloCount == i))),
                ]),
                const SizedBox(height: 14),
                const Text('HARITA:', style: kSmall),
                const SizedBox(height: 6),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  for (int i = 0; i < MAPS.length; i++)
                    GestureDetector(onTap: () => gs.setSoloMap(i), child: chip(MAPS[i].name, const Color(0xFF3498DB), on: gs.mapIdx == i)),
                ]),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E8449), padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                  onPressed: () => gs.startSolo(),
                  child: const Text('GECEYE BASLA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FindPage extends StatelessWidget {
  final Net gs;
  const FindPage({super.key, required this.gs});
  @override
  Widget build(BuildContext context) {
    final hosts = gs.discovered.values.toList();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0A0612), Color(0xFF000000)])),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  const Text('LOBI ARA', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 3, color: Color(0xFFFFB300))),
                  const Spacer(),
                  Btn(t: 'IPTAL', on: () { gs.stopDiscovery(); gs.page = 0; gs.onUpdate?.call(); }, expand: false, c: const Color(0xFF555577)),
                ]),
                const SizedBox(height: 12),
                Text(gs.status, style: kSmall),
                const SizedBox(height: 12),
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: const Color(0xFF111122), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF333355))),
                  child: Row(children: [
                    Container(width: 10, height: 10, decoration: const BoxDecoration(color: Color(0xFF2ECC71), shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text('${hosts.length} host bulundu', style: const TextStyle(color: Colors.white, fontSize: 14)),
                  ])),
                const SizedBox(height: 12),
                Expanded(
                  child: hosts.isEmpty
                      ? const Center(child: Text('Hostlar araniyor...\n\nAyni Wi-Fi aginda bir hostun oyunda oldugundan emin olun.', textAlign: TextAlign.center, style: kTxt))
                      : ListView.separated(
                          itemCount: hosts.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (c, i) {
                            final h = hosts[i];
                            return GestureDetector(
                              onTap: () { gs.stopDiscovery(); gs.joinHost(h); },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1F2937), Color(0xFF111827)]),
                                  borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF374151))),
                                child: Row(children: [
                                  Container(width: 50, height: 50, decoration: BoxDecoration(color: const Color(0xFFFFB300), borderRadius: BorderRadius.circular(10)),
                                    child: const Icon(Icons.videogame_asset, color: Color(0xFF111122))),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(h.hostName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                                    Text('${h.ip} - ${h.players}/4 oyuncu', style: kSmall),
                                  ])),
                                  const Icon(Icons.chevron_right, color: Colors.white70),
                                ]),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class LobbyPage extends StatelessWidget {
  final Net gs;
  const LobbyPage({super.key, required this.gs});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0A0612), Color(0xFF000000)])),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(children: [
                  const Text('LOBI', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 3, color: Color(0xFFFFB300))),
                  const Spacer(),
                  Btn(t: 'AYRIL', on: () => gs.leaveRoom(), expand: false, c: const Color(0xFF555577)),
                ]),
                const SizedBox(height: 12),
                Text('${gs.players.length} oyuncu - ${gs.isHost ? "HOST" : "KATILIMCI"}', style: kSmall),
                const SizedBox(height: 16),
                const Text('OYUNCULAR:', style: kSmall),
                const SizedBox(height: 8),
                Expanded(flex: 2, child: ListView.separated(
                  itemCount: gs.players.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (c, i) {
                    final p = gs.players[i];
                    final ch = CHARS[p.charIdx.clamp(0, CHARS.length - 1)];
                    return Container(padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: const Color(0xFF111122), borderRadius: BorderRadius.circular(10), border: Border.all(color: ch.color.al(0.5))),
                      child: Row(children: [
                        SizedBox(width: 40, height: 40, child: CustomPaint(painter: AnimPrev(ch: p.charIdx.clamp(0, CHARS.length - 1)))),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                          Text(ch.name, style: TextStyle(color: ch.color, fontSize: 11)),
                        ])),
                        if (p.id == gs.myId)
                          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: const Color(0xFFFFB300), borderRadius: BorderRadius.circular(6)),
                            child: const Text('SEN', style: TextStyle(color: Color(0xFF111122), fontSize: 10, fontWeight: FontWeight.w900))),
                      ]),
                    );
                  },
                )),
                const SizedBox(height: 12),
                const Text('KARAKTER SEC:', style: kSmall),
                const SizedBox(height: 8),
                Expanded(flex: 3, child: GridView.count(
                  crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 0.75,
                  children: [
                    for (int i = 0; i < CHARS.length; i++)
                      GestureDetector(
                        onTap: () => gs.setMyChar(i),
                        child: Container(
                          decoration: BoxDecoration(color: const Color(0xFF111122), borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: gs.myChar == i ? CHARS[i].color : const Color(0xFF333355), width: gs.myChar == i ? 3 : 1)),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            SizedBox(width: 40, height: 40, child: CustomPaint(painter: AnimPrev(ch: i))),
                            const SizedBox(height: 4),
                            Text(CHARS[i].name, style: TextStyle(color: CHARS[i].color, fontSize: 9, fontWeight: FontWeight.w800)),
                          ]),
                        ),
                      ),
                  ],
                )),
                if (gs.isHost) ...[
                  const SizedBox(height: 12),
                  const Text('HARITA:', style: kSmall),
                  const SizedBox(height: 6),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (int i = 0; i < MAPS.length; i++)
                      GestureDetector(onTap: () => gs.setHostMap(i), child: chip(MAPS[i].name, const Color(0xFF3498DB), on: gs.mapIdx == i)),
                  ]),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gs.players.length >= 2 ? const Color(0xFF1E8449) : const Color(0xFF555555),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: gs.players.length >= 2 ? () => gs.startGame() : null,
                    child: Text(gs.players.length >= 2 ? 'OYUNU BASLAT' : 'MIN 2 OYUNCU GEREKLI',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                ] else
                  Container(padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFF111122), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF333355))),
                    child: const Text('Hostun oyunu baslatmasini bekleyin...', style: kTxt, textAlign: TextAlign.center)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class Btn extends StatelessWidget {
  final String t;
  final String? sub;
  final Color c;
  final VoidCallback? on;
  final bool expand;
  const Btn({super.key, required this.t, this.sub, required this.c, this.on, this.expand = true});
  @override
  Widget build(BuildContext context) {
    final enabled = on != null;
    return GestureDetector(
      onTap: () { if (enabled) { Sfx.click(); on!(); } },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        width: expand ? double.infinity : null,
        decoration: BoxDecoration(
          color: enabled ? c : c.al(0.3),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white24, width: 1.5),
          boxShadow: enabled ? [BoxShadow(color: c.al(0.4), blurRadius: 10, spreadRadius: 1)] : null,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(t, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2)),
          if (sub != null) Text(sub!, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

Widget chip(String t, Color c, {bool on = false}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(color: on ? c : c.al(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: on ? Colors.white : c, width: 2)),
    child: Text(t, style: TextStyle(color: on ? Colors.white : Colors.white70, fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
  );
}

class GamePage extends StatefulWidget {
  final Net gs;
  const GamePage({super.key, required this.gs});
  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with SingleTickerProviderStateMixin {
  late AnimationController c;
  Duration? lastD;
  @override
  void initState() { super.initState(); c = AnimationController(vsync: this)..repeat(); c.addListener(_tick); }
  void _tick() {
    final d = c.lastElapsedDuration ?? Duration.zero;
    double dt = 0.016;
    if (lastD != null) dt = m.min(0.05, (d - lastD!).inMicroseconds / 1000000);
    lastD = d;
    if (widget.gs.isHost || widget.gs.solo) widget.gs._frame(dt);
  }
  @override
  void dispose() { c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final gs = widget.gs;
    return AnimatedBuilder(
      animation: c,
      builder: (context, _) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final vf = gs.vf(now);
        return Stack(children: [
          Positioned.fill(
            child: Transform.translate(
              offset: Offset(gs.shakeX, gs.shakeY),
              child: gs.myRole == 'G' ? _buildGuard(gs, vf, now) : _buildAnim(gs, vf, now),
            ),
          ),
          if (vf.blind > 0) Positioned.fill(child: Container(color: Colors.white.al(m.min(0.85, vf.blind)))),
          if (gs.over) Positioned.fill(child: Container(color: (gs.overSide == 'anim' ? const Color(0xFFFF2200) : const Color(0xFF22FF88)).al(0.12 + 0.1 * m.sin(gs.endDelay * 12).abs()))),
        ]);
      },
    );
  }

  Widget _buildGuard(Net gs, VF vf, int now) {
    final jammed = vf.cam && vf.jam > 0;
    final pulse = 0.6 + 0.4 * m.sin(now / 90);
    return Stack(children: [
      Positioned.fill(
        child: vf.cam && !vf.black
            ? CustomPaint(painter: MapP(map: gs.curMap, vf: vf, camMode: true, myPid: gs.myPid, t: vf.t, jam: jammed))
            : CustomPaint(painter: OfficeP(vf: vf, dlShow: gs.dlShow, drShow: gs.drShow, fanA: gs.fanA, t: now / 1000)),
      ),
      Positioned.fill(child: CustomPaint(painter: NoiseP(seed: now ~/ 60, heavy: vf.cam, jam: jammed))),
      Positioned.fill(child: const CustomPaint(painter: VignetteP())),
      Positioned(top: 8, left: 10, right: 10, child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(kHours[vf.hour.clamp(0, 6)], style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, shadows: [Shadow(blurRadius: 6, color: Colors.black)])),
          Text(vf.black ? 'KARANLIK!' : 'GECE VARDIYASI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: vf.black ? Colors.red : const Color(0xFFAAAAEE))),
        ]),
        const Spacer(),
        if (vf.cam) Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: (vf.t % 1 < 0.6) ? Colors.red : Colors.transparent, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          const Text('REC', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 12)),
        ]),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('GUC %${vf.power.toInt()}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: vf.power < 25 ? Colors.red : const Color(0xFF7CFC00))),
          Row(mainAxisSize: MainAxisSize.min, children: [
            for (int i = 0; i < 6; i++)
              Container(width: 7, height: 13, margin: const EdgeInsets.only(left: 2),
                color: i < vf.usage ? (vf.usage >= 5 ? Colors.red : vf.usage >= 3 ? Colors.orange : Colors.green) : const Color(0xFF222233)),
          ]),
        ]),
      ])),
      if (vf.forceL > 0 || vf.waitL > 1.5) Positioned(top: 66, left: 0, right: 0, child: Center(child: Text(
        'SOL KAPI ${vf.forceL > 0 ? 'ZORLANIYOR!' : 'TEHLIKE!'}',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.red.al(pulse))))),
      if (vf.forceR > 0 || vf.waitR > 1.5) Positioned(top: 86, left: 0, right: 0, child: Center(child: Text(
        'SAG KAPI ${vf.forceR > 0 ? 'ZORLANIYOR!' : 'TEHLIKE!'}',
        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.red.al(pulse))))),
      if (vf.black) const Positioned(top: 120, left: 0, right: 0, child: Center(child: Text('GUC BITTI - KONTROLLER KILITLENDI',
        style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2)))),
      if (jammed) const Positioned(top: 150, left: 0, right: 0, child: Center(child: Text('SINYAL YOK',
        style: TextStyle(color: Color(0xFF66FF66), fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 4)))),
      Positioned(bottom: 8, left: 8, right: 8, child: Row(children: [
        Expanded(child: Btn(t: 'SOL KAPI', sub: vf.ddL > 0 ? 'KILIT ${vf.ddL.toStringAsFixed(1)}' : (vf.dl ? 'ACIK' : 'KAPALI'),
          c: vf.dl ? const Color(0xFF1E8449) : const Color(0xFF922B21), on: vf.black || vf.ddL > 0 ? null : () => gs.gAct('dl'))),
        const SizedBox(width: 4),
        Expanded(child: Btn(t: 'ISIK', sub: vf.light ? 'ACIK' : 'KAPALI', c: const Color(0xFFB7950B), on: vf.black ? null : () => gs.gAct('li'))),
        const SizedBox(width: 4),
        Expanded(child: Btn(t: 'KAMERA', sub: vf.cam ? 'ACIK' : 'KAPALI', c: const Color(0xFF1F618D), on: vf.black || (vf.jam > 0 && !vf.cam) ? null : () => gs.gAct('cm'))),
        const SizedBox(width: 4),
        Expanded(child: Btn(t: 'VENT', sub: vf.vent ? 'ACIK' : 'KAPALI', c: const Color(0xFF148F77), on: vf.black ? null : () => gs.gAct('vt'))),
        const SizedBox(width: 4),
        Expanded(child: Btn(t: 'SAG KAPI', sub: vf.ddR > 0 ? 'KILIT ${vf.ddR.toStringAsFixed(1)}' : (vf.dr ? 'ACIK' : 'KAPALI'),
          c: vf.dr ? const Color(0xFF1E8449) : const Color(0xFF922B21), on: vf.black || vf.ddR > 0 ? null : () => gs.gAct('dr'))),
      ])),
    ]);
  }

  Widget _buildAnim(Net gs, VF vf, int now) {
    _Actor? me;
    for (final a in vf.actors) if (a.id == gs.myPid) { me = a; break; }
    final ctx = gs.ctxLabel(vf);
    final cd = me?.cd ?? 0.0;
    final ci = gs.myChar.clamp(0, CHARS.length - 1);
    final cdMax = CHARS[ci].cd;
    return Stack(children: [
      Positioned.fill(child: CustomPaint(painter: MapP(map: gs.curMap, vf: vf, camMode: false, myPid: gs.myPid, t: vf.t, jam: false))),
      Positioned.fill(child: CustomPaint(painter: NoiseP(seed: now ~/ 90, heavy: false, jam: false))),
      Positioned.fill(child: const CustomPaint(painter: VignetteP())),
      Positioned(top: 8, left: 10, right: 10, child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(kHours[vf.hour.clamp(0, 6)], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
          Text(CHARS[ci].name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: CHARS[ci].color)),
        ]),
        const Spacer(),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('GUC %${vf.power.toInt()}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: vf.power < 25 ? Colors.red : const Color(0xFF7CFC00))),
          Text('SOL:${vf.dl ? 'ACIK' : 'KAPALI'} SAG:${vf.dr ? 'ACIK' : 'KAPALI'} VENT:${vf.vent ? 'ACIK' : 'KAPALI'}',
            style: const TextStyle(fontSize: 10, color: Color(0xFFAAAADD))),
        ]),
      ])),
      if (me != null && me.stun > 0) Positioned(top: 0, bottom: 0, left: 0, right: 0, child: Center(child: Text(
        'SERSEMLEDIN ${me.stun.toStringAsFixed(1)} sn',
        style: const TextStyle(color: Color(0xFFFFEE55), fontSize: 24, fontWeight: FontWeight.w900, shadows: [Shadow(blurRadius: 10, color: Colors.black)])))),
      Positioned(bottom: 20, left: 16, child: Joy(onVec: gs.sendJoy)),
      Positioned(bottom: 24, right: 16, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
        if (ctx != null) GestureDetector(
          onTap: gs.doCtx,
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            decoration: BoxDecoration(color: const Color(0xFFC0392B).al(0.85), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white54, width: 2)),
            child: Text(ctx, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white))),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: cd <= 0 ? gs.useAbility : null,
          child: SizedBox(width: 86, height: 86, child: Stack(children: [
            Positioned.fill(child: Container(decoration: BoxDecoration(shape: BoxShape.circle, color: CHARS[ci].color.al(cd > 0 ? 0.2 : 0.75), border: Border.all(color: CHARS[ci].color, width: 2)))),
            Positioned.fill(child: CustomPaint(painter: ArcP(frac: cdMax > 0 ? cd / cdMax : 0, col: Colors.black.al(0.65)))),
            Center(child: Text(CHARS[ci].active, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white))),
            if (cd > 0) Positioned(bottom: 14, left: 0, right: 0, child: Center(child: Text(cd.toStringAsFixed(0),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white70)))),
          ])),
        ),
      ])),
    ]);
  }
}

class EndPage extends StatefulWidget {
  final Net gs;
  const EndPage({super.key, required this.gs});
  @override
  State<EndPage> createState() => _EndPageState();
}

class _EndPageState extends State<EndPage> with SingleTickerProviderStateMixin {
  late AnimationController c;
  bool surpriseOn = false;
  double surpriseT = 0;
  bool surpriseFired = false;
  double waitT = 0;
  @override
  void initState() { super.initState(); c = AnimationController(vsync: this)..repeat(); c.addListener(_tick); }
  void _tick() {
    final gs = widget.gs;
    if (!mounted) return;
    if (!surpriseFired && gs.surprise) {
      waitT += 0.016;
      if (waitT > 1.6) { surpriseFired = true; surpriseOn = true; surpriseT = 0; Sfx.screamBurst(); }
    }
    if (surpriseOn) {
      surpriseT += 0.016;
      if (surpriseT > 1.8) surpriseOn = false;
      setState(() {});
    }
  }
  @override
  void dispose() { c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final gs = widget.gs;
    final won = (gs.myRole == 'G' && gs.overSide == 'guard') || (gs.myRole == 'A' && gs.overSide == 'anim');
    return AnimatedBuilder(animation: c, builder: (context, _) {
      return Stack(children: [
        Center(
          child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (gs.overJs >= 0) SizedBox(height: 170, width: 170, child: CustomPaint(painter: AnimPrev(ch: gs.overJs))),
            const SizedBox(height: 10),
            Text(won ? 'KAZANDIN!' : 'YAKALANDIN!', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 4,
              color: won ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C))),
            const SizedBox(height: 10),
            Text(gs.overReason, textAlign: TextAlign.center, style: kTxt),
            const SizedBox(height: 8),
            Text(gs.myRole == 'G' ? 'Rol: GUVENLIK' : 'Rol: ${CHARS[gs.myChar.clamp(0, CHARS.length - 1)].name}', style: kSmall),
            if (gs.surprise && surpriseFired) const Padding(padding: EdgeInsets.only(top: 10),
              child: Text('SENI GORUYORUZ...', style: TextStyle(color: Color(0xFFFF3333), fontWeight: FontWeight.w900, letterSpacing: 3))),
            const SizedBox(height: 26),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              if (gs.isHost && !gs.aiMode) Btn(t: 'LOBIYE DON', sub: 'revans', on: () => gs.toLobbyAll(), expand: false, c: const Color(0xFF1F618D)),
              if (gs.isHost && !gs.aiMode) const SizedBox(width: 10),
              Btn(t: 'ANA MENU', on: () => gs.leaveRoom(), expand: false, c: const Color(0xFF555577)),
            ]),
          ])),
        ),
        if (surpriseOn) Positioned.fill(
          child: Container(color: Colors.black, child: Stack(children: [
            Positioned.fill(child: CustomPaint(painter: NoiseP(seed: (surpriseT * 60).toInt(), heavy: true, jam: true))),
            Center(child: Transform.scale(scale: 0.6 + surpriseT * 1.4,
              child: CustomPaint(size: const Size(300, 300), painter: AnimPrev(ch: 11)))),
            Positioned.fill(child: Container(color: Colors.red.al(0.25 + 0.2 * m.sin(surpriseT * 40).abs()))),
          ])),
        ),
      ]);
    });
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
      onPanEnd: (d) { setState(() => v = Offset.zero); widget.onVec(0, 0); },
      child: SizedBox(width: size, height: size, child: CustomPaint(painter: JoyP(v: v, rad: rad))),
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
    canvas.drawCircle(c, rad + 14, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = const Color(0xFF4444AA).al(0.8));
    canvas.drawCircle(c, 4, Paint()..color = const Color(0xFF4444AA));
    canvas.drawCircle(c + v, 26, Paint()..color = const Color(0xFF8866FF).al(0.9));
    canvas.drawCircle(c + v, 26, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = Colors.white54);
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
    final r = Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: size.width / 2);
    canvas.drawArc(r, -m.pi / 2, frac * 2 * m.pi, true, Paint()..color = col);
  }
  @override
  bool shouldRepaint(ArcP old) => old.frac != frac;
}

class MenuAnimP extends CustomPainter {
  final double t;
  MenuAnimP({required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < 4; i++) {
      final cx = size.width * 0.2 + i * size.width * 0.2;
      final bob = m.sin(t * 2 + i) * 4;
      drawAnimatronic(canvas, Offset(cx, size.height * 0.5 + bob), size.height * 0.7, i * 3, t);
    }
  }
  @override
  bool shouldRepaint(MenuAnimP old) => true;
}

void drawAnimatronic(Canvas canvas, Offset o, double s, int ch, double t, {bool dark = false, bool scream = false}) {
  final cd = CHARS[ch.clamp(0, CHARS.length - 1)];
  final Color body = dark ? const Color(0xFF0A0A10) : cd.color;
  final Color body2 = dark ? const Color(0xFF0A0A10) : Color.lerp(cd.color, Colors.black, 0.35)!;
  final Color eye = dark ? const Color(0xFFFFFFFF) : (ch == 5 ? const Color(0xFFFFF6B0) : const Color(0xFFEAF7FF));
  final glow = Paint()..color = cd.color.al(dark ? 0.25 : 0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
  canvas.drawCircle(o, s * 0.52, glow);
  if (ch == 0) {
    for (final dir in [-1.0, 1.0]) {
      final flap = m.sin(t * 7) * 0.25;
      final wing = Path()
        ..moveTo(o.dx + dir * s * 0.22, o.dy + s * 0.18)
        ..quadraticBezierTo(o.dx + dir * s * (0.72 + flap), o.dy - s * 0.1, o.dx + dir * s * 0.55, o.dy + s * 0.42)
        ..quadraticBezierTo(o.dx + dir * s * 0.3, o.dy + s * 0.4, o.dx + dir * s * 0.22, o.dy + s * 0.18)
        ..close();
      canvas.drawPath(wing, Paint()..color = (dark ? const Color(0xFF0A0A10) : const Color(0xFF873600)).al(0.95));
    }
  }
  if (ch == 10) {
    for (int i = 0; i < 3; i++) {
      final cen = Offset(o.dx + (i - 1) * s * 0.16, o.dy + s * (0.52 + i * 0.05));
      canvas.drawOval(Rect.fromCenter(center: cen, width: s * 0.3, height: s * 0.16), Paint()..color = body.al(0.25 - i * 0.06));
    }
  }
  canvas.drawOval(Rect.fromCenter(center: Offset(o.dx, o.dy + s * 0.32), width: s * 0.6, height: s * 0.52), Paint()..color = body2);
  final inner = dark ? const Color(0xFF0A0A10) : Color.lerp(cd.color, Colors.white, 0.25)!;
  canvas.drawOval(Rect.fromCenter(center: Offset(o.dx, o.dy + s * 0.34), width: s * 0.34, height: s * 0.3), Paint()..color = inner);
  if (ch == 2) {
    for (final dir in [-1.0, 1.0]) {
      final ec = Offset(o.dx + dir * s * 0.26, o.dy - s * 0.42);
      canvas.drawCircle(ec, s * 0.16, Paint()..color = body);
      canvas.drawCircle(ec, s * 0.08, Paint()..color = dark ? const Color(0xFF0A0A10) : const Color(0xFFE8A0B4));
    }
  }
  if (ch == 7) {
    for (int i = 0; i < 5; i++) {
      final ang = -m.pi * 0.85 + i * (m.pi * 0.7 / 4);
      final p1 = Offset(o.dx + m.cos(ang) * s * 0.3, o.dy - s * 0.18 + m.sin(ang) * s * 0.3);
      final p2 = Offset(o.dx + m.cos(ang) * s * 0.46, o.dy - s * 0.18 + m.sin(ang) * s * 0.46);
      final p3 = Offset(o.dx + m.cos(ang + 0.25) * s * 0.3, o.dy - s * 0.18 + m.sin(ang + 0.25) * s * 0.3);
      canvas.drawPath(Path()..moveTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy)..lineTo(p3.dx, p3.dy)..close(), Paint()..color = body);
    }
  }
  if (ch == 11) {
    final hatR = Rect.fromCenter(center: Offset(o.dx, o.dy - s * 0.34), width: s * 0.5, height: s * 0.4);
    final hatC = dark ? const Color(0xFF0A0A10) : const Color(0xFF641E16);
    canvas.drawArc(hatR, m.pi * 0.95, m.pi * 1.1, false, Paint()..style = PaintingStyle.stroke..strokeWidth = s * 0.09..color = hatC);
    canvas.drawCircle(Offset(o.dx + s * 0.05, o.dy - s * 0.52), s * 0.07, Paint()..color = Colors.white.al(dark ? 0.4 : 1));
  }
  canvas.drawOval(Rect.fromCenter(center: Offset(o.dx, o.dy - s * 0.16), width: s * 0.56, height: s * 0.5), Paint()..color = body);
  if (ch == 4) {
    canvas.drawLine(Offset(o.dx, o.dy - s * 0.4), Offset(o.dx, o.dy - s * 0.62), Paint()..color = body2..strokeWidth = s * 0.03);
    final blink = (t % 0.8) < 0.4;
    final ac = blink ? const Color(0xFF2ECC71) : const Color(0xFF145A32);
    canvas.drawCircle(Offset(o.dx, o.dy - s * 0.64), s * 0.045, Paint()..color = ac..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
  }
  if (ch == 5) {
    final halo = Paint()..color = const Color(0xFFFFF6B0).al(0.5)..style = PaintingStyle.stroke..strokeWidth = s * 0.03..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(o.dx, o.dy - s * 0.1), s * 0.46, halo);
  }
  final blink = (t % 3.1) < 0.12 && !scream;
  for (final dir in [-1.0, 1.0]) {
    final ec = Offset(o.dx + dir * s * 0.12, o.dy - s * 0.2);
    if (blink) {
      canvas.drawLine(ec - Offset(s * 0.05, 0), ec + Offset(s * 0.05, 0), Paint()..color = eye..strokeWidth = s * 0.02);
    } else {
      canvas.drawCircle(ec, s * (scream ? 0.085 : 0.06), Paint()..color = eye..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
      canvas.drawCircle(ec, s * 0.025, Paint()..color = Colors.black);
    }
  }
  final mouthW = scream ? 0.4 : 0.22;
  final mouthH = scream ? 0.3 : 0.1;
  canvas.drawOval(Rect.fromCenter(center: Offset(o.dx, o.dy - s * 0.02), width: s * mouthW, height: s * mouthH), Paint()..color = const Color(0xFF12040A));
  if (scream || ch == 3 || ch == 7 || ch == 0) {
    final mw = s * mouthW;
    for (int i = 0; i < 5; i++) {
      final tx = o.dx - mw / 2 + mw * (i + 0.5) / 5;
      final ty = o.dy - s * 0.02 - s * mouthH / 2;
      canvas.drawPath(Path()..moveTo(tx - s * 0.02, ty)..lineTo(tx + s * 0.02, ty)..lineTo(tx, ty + s * 0.05)..close(), Paint()..color = const Color(0xFFE8E8E8));
    }
  }
  canvas.drawOval(Rect.fromCenter(center: Offset(o.dx - s * 0.13, o.dy + s * 0.58), width: s * 0.18, height: s * 0.09), Paint()..color = body2);
  canvas.drawOval(Rect.fromCenter(center: Offset(o.dx + s * 0.13, o.dy + s * 0.58), width: s * 0.18, height: s * 0.09), Paint()..color = body2);
}

class AnimPrev extends CustomPainter {
  final int ch;
  AnimPrev({required this.ch});
  @override
  void paint(Canvas canvas, Size size) {
    drawAnimatronic(canvas, Offset(size.width / 2, size.height * 0.52), size.height * 0.72, ch, 1.2);
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
  OfficeP({required this.vf, required this.dlShow, required this.drShow, required this.fanA, required this.t});
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final horizon = h * 0.62;
    final r = m.Random((t * 20).toInt());
    final wallR = Rect.fromLTWH(0, 0, w, horizon);
    canvas.drawRect(wallR, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1B1030), Color(0xFF0C0716)]).createShader(wallR));
    final floorR = Rect.fromLTWH(0, horizon, w, h - horizon);
    canvas.drawRect(floorR, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF171021), Color(0xFF040207)]).createShader(floorR));
    final tile = Paint()..color = Colors.white.al(0.03)..strokeWidth = 1;
    for (int i = 1; i < 12; i++) canvas.drawLine(Offset(w * i / 12, 0), Offset(w * i / 12, horizon), tile);
    final flick = vf.black ? 0.0 : (0.8 + 0.15 * m.sin(t * 13) + 0.05 * r.nextDouble());
    final lampX = w * 0.5;
    canvas.drawLine(Offset(lampX, 0), Offset(lampX, h * 0.07), Paint()..color = const Color(0xFF333344)..strokeWidth = 3);
    if (!vf.black) {
      final cone = Path()..moveTo(lampX - w * 0.03, h * 0.075)..lineTo(lampX + w * 0.03, h * 0.075)..lineTo(lampX + w * 0.22, h * 0.95)..lineTo(lampX - w * 0.22, h * 0.95)..close();
      final coneC = [const Color(0xFFFFE9A0).al(0.10 * flick), const Color(0xFFFFE9A0).al(0.0)];
      canvas.drawPath(cone, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: coneC).createShader(Rect.fromLTWH(0, 0, w, h)));
      canvas.drawOval(Rect.fromCenter(center: Offset(lampX, h * 0.078), width: w * 0.05, height: h * 0.014),
        Paint()..color = const Color(0xFFFFE9A0).al(0.9 * flick)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    }
    _poster(canvas, Rect.fromLTWH(w * 0.205, h * 0.14, w * 0.1, h * 0.17), 0);
    _poster(canvas, Rect.fromLTWH(w * 0.695, h * 0.14, w * 0.1, h * 0.17), 11);
    _doorway(canvas, size, true, 1 - dlShow);
    _doorway(canvas, size, false, 1 - drShow);
    final deskTop = h * 0.8;
    final desk = Path()..moveTo(w * 0.28, h * 0.99)..lineTo(w * 0.36, deskTop)..lineTo(w * 0.64, deskTop)..lineTo(w * 0.72, h * 0.99)..close();
    canvas.drawPath(desk, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: const [Color(0xFF3A2A1C), Color(0xFF1D130B)]).createShader(Rect.fromLTWH(0, deskTop, w, h * 0.2)));
    final monW = w * 0.15;
    final monR = Rect.fromCenter(center: Offset(w * 0.44, h * 0.7), width: monW, height: h * 0.15);
    canvas.drawRRect(RRect.fromRectAndRadius(monR.inflate(4), const Radius.circular(6)), Paint()..color = const Color(0xFF14141E));
    canvas.drawRRect(RRect.fromRectAndRadius(monR, const Radius.circular(4)), Paint()..color = vf.black ? const Color(0xFF050508) : const Color(0xFF062511));
    if (!vf.black) {
      for (int i = 0; i < 8; i++) {
        final y = monR.top + 6 + i * (monR.height - 12) / 8;
        canvas.drawLine(Offset(monR.left + 4, y), Offset(monR.right - 4, y), Paint()..color = const Color(0xFF1DFF6E).al(0.14));
      }
      if ((t % 1) < 0.5) canvas.drawRect(Rect.fromLTWH(monR.center.dx + monW * 0.3, monR.top + 6, 4, 8), Paint()..color = const Color(0xFF57FF8F));
    }
    canvas.drawRect(Rect.fromLTWH(monR.center.dx - 5, monR.bottom + 4, 10, h * 0.045), Paint()..color = const Color(0xFF14141E));
    final fx = w * 0.62;
    final fy = h * 0.72;
    final fr = h * 0.05;
    canvas.drawRect(Rect.fromLTWH(fx - fr * 0.2, fy + fr, fr * 0.4, h * 0.05), Paint()..color = const Color(0xFF222230));
    canvas.save();
    canvas.translate(fx, fy);
    canvas.rotate(fanA);
    for (int i = 0; i < 3; i++) {
      canvas.rotate(2 * m.pi / 3);
      canvas.drawOval(Rect.fromCenter(center: Offset(fr * 0.45, 0), width: fr * 0.85, height: fr * 0.3),
        Paint()..color = const Color(0xFF8899AA).al(vf.black ? 0.25 : 0.8));
    }
    canvas.restore();
    canvas.drawCircle(Offset(fx, fy), fr, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.5..color = const Color(0xFF556677));
    canvas.drawCircle(Offset(fx, fy), fr * 0.16, Paint()..color = const Color(0xFF334455));
    if (vf.black) {
      canvas.drawRect(Offset.zero & size, Paint()..color = Colors.black.al(0.86 + 0.04 * m.sin(t * 3)));
      if (vf.thL >= 0 || vf.thR >= 0) {
        if (r.nextDouble() < 0.4) {
          final side = vf.thL >= 0 ? -1.0 : 1.0;
          final ex = w * 0.5 + side * w * 0.4;
          for (final d2 in [-1.0, 1.0]) {
            canvas.drawCircle(Offset(ex + d2 * w * 0.012, h * 0.45), 3,
              Paint()..color = Colors.white.al(0.8)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
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
    canvas.drawCircle(Offset(c.dx - s * 0.22, c.dy - s * 0.3), s * 0.14, Paint()..color = CHARS[ch].color.al(0.9));
    canvas.drawCircle(Offset(c.dx + s * 0.22, c.dy - s * 0.3), s * 0.14, Paint()..color = CHARS[ch].color.al(0.9));
    canvas.drawOval(Rect.fromCenter(center: c, width: s * 0.7, height: s * 0.6), Paint()..color = CHARS[ch].color);
    for (final d2 in [-1.0, 1.0]) canvas.drawCircle(Offset(c.dx + d2 * s * 0.14, c.dy - s * 0.05), s * 0.06, Paint()..color = Colors.white);
  }

  void _doorway(Canvas canvas, Size size, bool left, double closedFrac) {
    final w = size.width;
    final h = size.height;
    final opW = w * 0.145;
    final opH = h * 0.6;
    final x0 = left ? w * 0.03 : w - w * 0.03 - opW;
    final op = Rect.fromLTWH(x0, h * 0.16, opW, opH);
    canvas.drawRect(op.inflate(6), Paint()..color = const Color(0xFF2A2438));
    canvas.drawRect(op, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: const [Color(0xFF02020A), Color(0xFF000000)]).createShader(op));
    final threat = left ? vf.thL : vf.thR;
    final wait = left ? vf.waitL : vf.waitR;
    if (vf.light && !vf.black) {
      canvas.drawRect(op, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [const Color(0xFFFFE9A0).al(0.02), const Color(0xFFFFE9A0).al(0.2)]).createShader(op));
      if (threat >= 0) drawAnimatronic(canvas, Offset(op.center.dx, op.bottom - opH * 0.32), opH * 0.62, threat, t, dark: true);
    }
    if (wait > 0.5 && closedFrac < 0.5) {
      final a = (wait / 5).clamp(0.0, 1.0) * (0.35 + 0.3 * m.sin(t * 8).abs());
      canvas.drawRect(op.inflate(5), Paint()..style = PaintingStyle.stroke..strokeWidth = 4..color = Colors.red.al(a));
    }
    if (closedFrac > 0.02) {
      final ph = opH * closedFrac;
      final panel = Rect.fromLTWH(op.left, op.top, opW, ph);
      canvas.drawRect(panel, Paint()..shader = const LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight,
        colors: const [Color(0xFF39424F), Color(0xFF697786), Color(0xFF39424F)]).createShader(panel));
      for (int i = 0; i < 6; i++) {
        final y = op.top + ph * i / 6;
        canvas.drawLine(Offset(op.left, y), Offset(op.right, y), Paint()..color = Colors.black.al(0.25)..strokeWidth = 1.5);
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
    canvas.drawCircle(lampC, 5, Paint()..color = (closedFrac > 0.5 ? const Color(0xFFFF3B3B) : const Color(0xFF3BFF6E))..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
  }
  @override
  bool shouldRepaint(OfficeP old) => true;
}

class MapP extends CustomPainter {
  final GameMap map;
  final VF vf;
  final bool camMode;
  final bool jam;
  final String myPid;
  final double t;
  MapP({required this.map, required this.vf, required this.camMode, required this.myPid, required this.t, required this.jam});
  Offset sc(Offset c, Offset p, double s) => c + Offset((p.dx - 500) * s, (p.dy - 500) * s);
  @override
  void paint(Canvas canvas, Size size) {
    final bg = camMode ? const Color(0xFF020A06) : const Color(0xFF070711);
    canvas.drawRect(Offset.zero & size, Paint()..color = bg);
    final s = m.min(size.width, size.height) / 1000 * 0.92;
    final c = Offset(size.width / 2, size.height / 2);
    final pos = <String, Offset>{};
    for (final n in map.nodes) pos[n.id] = sc(c, Offset(n.x, n.y), s);
    final corridor = Paint()..style = PaintingStyle.stroke..strokeWidth = 86 * s..strokeCap = StrokeCap.round..color = camMode ? const Color(0xFF0A2617) : const Color(0xFF161B2C);
    final corridorIn = Paint()..style = PaintingStyle.stroke..strokeWidth = 62 * s..strokeCap = StrokeCap.round..color = camMode ? const Color(0xFF10381F) : const Color(0xFF232B47);
    for (final e in map.edges) {
      if (e.kind == 'vent') continue;
      final p1 = pos[e.a]!;
      final p2 = pos[e.b]!;
      if (e.kind.isEmpty) { canvas.drawLine(p1, p2, corridor); canvas.drawLine(p1, p2, corridorIn); }
    }
    for (final e in map.edges) {
      if (e.kind.isEmpty) continue;
      final p1 = pos[e.a]!;
      final p2 = pos[e.b]!;
      if (e.kind == 'vent') {
        final open = vf.vent;
        final dashP = _dash(Path()..moveTo(p1.dx, p1.dy)..lineTo(p2.dx, p2.dy), 14 * s);
        canvas.drawPath(dashP, Paint()..style = PaintingStyle.stroke..strokeWidth = 20 * s..strokeCap = StrokeCap.round..color = (open ? const Color(0xFF1ABC9C) : const Color(0xFF922B21)).al(camMode ? 0.8 : 1));
        final mid = (p1 + p2) / 2;
        if (!open) {
          canvas.drawLine(mid + Offset(-12 * s, -12 * s), mid + Offset(12 * s, 12 * s), Paint()..color = Colors.red..strokeWidth = 3);
          canvas.drawLine(mid + Offset(12 * s, -12 * s), mid + Offset(-12 * s, 12 * s), Paint()..color = Colors.red..strokeWidth = 3);
        }
        continue;
      }
      final open = e.kind == 'doorL' ? vf.dl : vf.dr;
      final dir = (p2 - p1);
      final doorMid = p1 + dir * 0.72;
      canvas.drawLine(p1, p2, Paint()..style = PaintingStyle.stroke..strokeWidth = 40 * s..strokeCap = StrokeCap.round..color = (open ? const Color(0xFF1E8449) : const Color(0xFF922B21)).al(camMode ? 0.7 : 0.95));
      final perp = Offset(-dir.dy, dir.dx);
      final pl = perp / (m.sqrt(perp.dx * perp.dx + perp.dy * perp.dy) + 0.0001);
      canvas.drawLine(doorMid - pl * 34 * s, doorMid + pl * 34 * s, Paint()..color = (open ? const Color(0xFF7CFC00) : const Color(0xFFFF4C4C))..strokeWidth = 7 * s);
    }
    final o = pos['O']!;
    final offR = Rect.fromCircle(center: o, radius: 74 * s);
    canvas.drawRRect(RRect.fromRectAndRadius(offR, Radius.circular(18 * s)), Paint()..color = camMode ? const Color(0xFF0E3B22) : const Color(0xFF2C2450));
    canvas.drawRRect(RRect.fromRectAndRadius(offR, Radius.circular(18 * s)), Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = const Color(0xFFF1C40F).al(0.7));
    for (final n in map.nodes) {
      if (n.id == 'O') continue;
      final p = pos[n.id]!;
      canvas.drawCircle(p, 40 * s, Paint()..color = camMode ? const Color(0xFF0F3320) : const Color(0xFF2A3355));
    }
    for (final z in vf.noise) {
      final p = pos[z];
      if (p == null) continue;
      final pl = (0.6 + 0.4 * m.sin(t * 6)).clamp(0.0, 1.0);
      canvas.drawCircle(p, 26 * s * (0.8 + 0.3 * pl), Paint()..color = const Color(0xFFF1C40F).al(0.25 * pl));
    }
    if (!jam) {
      for (final a in vf.actors) {
        if (camMode && (a.hd || a.iv)) continue;
        final p = sc(c, Offset(a.x, a.y), s);
        final col = CHARS[a.charIdx.clamp(0, CHARS.length - 1)].color;
        canvas.drawCircle(p, 20 * s, Paint()..color = col.al(0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
        canvas.drawCircle(p, 14 * s, Paint()..color = col);
        canvas.drawCircle(p, 14 * s, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = Colors.white.al(0.7));
        if (a.id == myPid) canvas.drawCircle(p, 22 * s, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.5..color = Colors.white);
        if (a.stun > 0) {
          final rr = 24 * s;
          for (int i = 0; i < 3; i++) {
            final ang = t * 4 + i * 2 * m.pi / 3;
            canvas.drawCircle(p + Offset(m.cos(ang), m.sin(ang)) * rr, 3.5, Paint()..color = const Color(0xFFFFEE55));
          }
        }
        if (a.wait > 0.3) {
          canvas.drawArc(Rect.fromCircle(center: p, radius: 26 * s), -m.pi / 2, (a.wait / 5).clamp(0.0, 1.0) * 2 * m.pi, false,
            Paint()..style = PaintingStyle.stroke..strokeWidth = 4..color = Colors.red.al(0.9));
        }
      }
    }
    if (camMode) canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF00FF66).al(0.05));
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
    final dens = [2600.0, 900.0, 260.0, 120.0][level];
    final n = (size.width * size.height / dens).toInt();
    final white = Paint();
    for (int i = 0; i < n; i++) {
      final a = r.nextDouble() * (jam ? 0.4 : (heavy ? 0.2 : 0.07));
      white.color = Colors.white.al(a);
      final sw = r.nextDouble() * 2.2 + 0.6;
      final double sh = r.nextDouble() < 0.12 ? 2.0 : 1.0;
      canvas.drawRect(Rect.fromLTWH(r.nextDouble() * size.width, r.nextDouble() * size.height, sw, sh), white);
    }
    final scan = Paint()..color = Colors.black.al(jam ? 0.16 : 0.06);
    for (double y = 0; y < size.height; y += 3) canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), scan);
    if (jam || (heavy && r.nextDouble() < 0.35)) {
      final by = r.nextDouble() * size.height;
      final bh = 6 + r.nextDouble() * 26;
      canvas.drawRect(Rect.fromLTWH(0, by, size.width, bh), Paint()..color = Colors.white.al(0.08));
    }
  }
  @override
  bool shouldRepaint(NoiseP old) => old.seed != seed;
}

class VignetteP extends CustomPainter {
  const VignetteP();
  @override
  void paint(Canvas canvas, Size size) {
    final r2 = Rect.fromCircle(center: Offset(size.width / 2, size.height / 2), radius: size.longestSide * 0.72);
    final grad = RadialGradient(colors: [Colors.transparent, Colors.black.al(0.55), Colors.black.al(0.85)], stops: const [0.55, 0.85, 1.0]);
    canvas.drawRect(Offset.zero & size, Paint()..shader = grad.createShader(r2));
  }
  @override
  bool shouldRepaint(VignetteP old) => false;
}

extension _ColorX on Color {
  Color al(double a) => withValues(alpha: a.clamp(0, 1));
}
