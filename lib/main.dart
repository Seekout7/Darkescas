// SURUM 7.1 - TEK DOSYA (lib/main.dart)
// GECE VARDIYASI: MOBIL UYUMLU ÇOK OYUNCULU FNAF
// Hatalar giderildi, lobi senkronizasyonu düzeltildi, ses başlatma iyileştirildi.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as m;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ---------- Android / iOS izinleri için hatırlatma ----------
// AndroidManifest.xml'e ekleyin:
// <uses-permission android:name="android.permission.INTERNET"/>
// <uses-permission android:name="android.permission.ACCESS_WIFI_STATE"/>
// <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
// (isteğe bağlı) <uses-permission android:name="android.permission.CHANGE_WIFI_MULTICAST_STATE"/>
//
// iOS Info.plist'e ekleyin:
// <key>NSLocalNetworkUsageDescription</key>
// <string>Bu oyun yerel ağda diğer oyuncuları bulmak için ağ erişimi kullanır.</string>
// ------------------------------------------------------------

const int kPort = 41237;
const double kGameLen = 150.0;
const int kMaxPlayers = 4;
const List<String> kHours = [
  '12 AM', '1 AM', '2 AM', '3 AM', '4 AM', '5 AM', '6 AM'
];

extension Al on Color {
  Color al(double o) {
    final int a = (o.clamp(0.0, 1.0) * 255).round();
    return Color.fromARGB(a, red, green, blue);
  }
}

double _d(dynamic v) => v is num ? v.toDouble() : 0.0;
int _i(dynamic v) => v is num ? v.toInt() : 0;
String _s(dynamic v) => v is String ? v : '';

class CharDef {
  final String name;
  final Color color;
  final double speed;
  final double cd;
  final String active;
  final String passive;
  const CharDef(
    this.name, this.color, this.speed,
    this.cd, this.active, this.passive,
  );
}

const List<CharDef> CHARS = [
  CharDef('Kanat', Color(0xFFD35400), 1.30, 8, 'speed', 'speed'),
  CharDef('Golge', Color(0xFF6C3483), 1.00, 10, 'silent', 'ghost'),
  CharDef('Fare', Color(0xFF8D99AE), 1.10, 9, 'ventrush', 'vent'),
  CharDef('Kas', Color(0xFFB03A2E), 0.85, 12, 'doorbreak', 'door'),
  CharDef('Hacker', Color(0xFF2ECC71), 1.00, 12, 'camjam', 'quiet'),
  CharDef('Isik', Color(0xFFF1C40F), 1.00, 10, 'light', 'lightimmune'),
  CharDef('Gurultucu', Color(0xFFCA6F1E), 1.00, 8, 'noise', 'none'),
  CharDef('Korku', Color(0xFF8E44AD), 0.95, 11, 'fear', 'none'),
  CharDef('Dalga', Color(0xFF3498DB), 1.25, 7, 'dash', 'speed'),
  CharDef('Enerji', Color(0xFF1ABC9C), 1.00, 10, 'drain', 'none'),
  CharDef('Sis', Color(0xFFAEB6BF), 1.05, 13, 'teleport', 'quiet'),
  CharDef('Kukla', Color(0xFFEC7063), 1.00, 12, 'scream', 'ghost'),
];

class MNode {
  final String id;
  final String name;
  final double x;
  final double y;
  const MNode(this.id, this.name, this.x, this.y);
}

class MEdge {
  final String a;
  final String b;
  final String kind;
  const MEdge(this.a, this.b, [this.kind = '']);
}

class GameMap {
  final String name;
  final List<MNode> nodes;
  final List<MEdge> edges;
  const GameMap(this.name, this.nodes, this.edges);
}

const GameMap kMapKlasik = GameMap('KLASIK', [
  MNode('TL', 'SolUst', 170, 170),
  MNode('U', 'Ust Koridor', 500, 140),
  MNode('TR', 'SagUst', 830, 170),
  MNode('R', 'Sag Koridor', 870, 500),
  MNode('BR', 'SagAlt', 830, 830),
  MNode('D', 'Alt Koridor', 500, 870),
  MNode('BL', 'SolAlt', 170, 830),
  MNode('L', 'Sol Koridor', 130, 500),
  MNode('O', 'OFIS', 500, 505),
  MNode('P1', 'Depo A', 890, 330),
  MNode('P2', 'Depo B', 330, 890),
], [
  MEdge('TL', 'U'), MEdge('U', 'TR'),
  MEdge('TR', 'P1'), MEdge('P1', 'R'),
  MEdge('R', 'BR'), MEdge('BR', 'D'),
  MEdge('D', 'P2'), MEdge('P2', 'BL'),
  MEdge('BL', 'L'), MEdge('L', 'TL'),
  MEdge('L', 'O', 'doorL'),
  MEdge('R', 'O', 'doorR'),
  MEdge('U', 'O', 'vent'),
]);

const GameMap kMapSade = GameMap('SADE HALKA', [
  MNode('TL', 'SolUst', 170, 170),
  MNode('U', 'Ust Koridor', 500, 140),
  MNode('TR', 'SagUst', 830, 170),
  MNode('R', 'Sag Koridor', 870, 500),
  MNode('BR', 'SagAlt', 830, 830),
  MNode('D', 'Alt Koridor', 500, 870),
  MNode('BL', 'SolAlt', 170, 830),
  MNode('L', 'Sol Koridor', 130, 500),
  MNode('O', 'OFIS', 500, 505),
], [
  MEdge('TL', 'U'), MEdge('U', 'TR'),
  MEdge('TR', 'R'), MEdge('R', 'BR'),
  MEdge('BR', 'D'), MEdge('D', 'BL'),
  MEdge('BL', 'L'), MEdge('L', 'TL'),
  MEdge('L', 'O', 'doorL'),
  MEdge('R', 'O', 'doorR'),
  MEdge('U', 'O', 'vent'),
]);

const GameMap kMapGenis = GameMap('GENIS', [
  MNode('TL', 'SolUst', 170, 170),
  MNode('U', 'Ust Koridor', 500, 140),
  MNode('TR', 'SagUst', 830, 170),
  MNode('R', 'Sag Koridor', 870, 500),
  MNode('BR', 'SagAlt', 830, 830),
  MNode('D', 'Alt Koridor', 500, 870),
  MNode('BL', 'SolAlt', 170, 830),
  MNode('L', 'Sol Koridor', 130, 500),
  MNode('O', 'OFIS', 500, 505),
  MNode('P1', 'Depo A', 890, 330),
  MNode('P2', 'Depo B', 330, 890),
  MNode('P3', 'Depo C', 330, 110),
  MNode('P4', 'Depo D', 110, 665),
], [
  MEdge('TL', 'P3'), MEdge('P3', 'U'),
  MEdge('U', 'TR'), MEdge('TR', 'P1'),
  MEdge('P1', 'R'), MEdge('R', 'BR'),
  MEdge('BR', 'D'), MEdge('D', 'P2'),
  MEdge('P2', 'BL'), MEdge('BL', 'P4'),
  MEdge('P4', 'L'), MEdge('L', 'TL'),
  MEdge('L', 'O', 'doorL'),
  MEdge('R', 'O', 'doorR'),
  MEdge('U', 'O', 'vent'),
]);

const List<GameMap> MAPS = [kMapKlasik, kMapSade, kMapGenis];

class Sfx {
  static const int sr = 22050;
  static bool ready = false;
  static String dir = '';
  static bool _ambOn = false;
  static Timer? _ambT;
  static final Map<String, Process> _live = {};
  static final Set<String> _busy = {};

  static bool get _mobile {
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  static Future<void> init() async {
    if (_mobile) {
      ready = true;
      return;
    }
    try {
      if (ready) return;
      final d = await Directory.systemTemp.createTemp('gv');
      dir = d.path;
      _wf('scream', _wav(_genScream()));
      _wf('amb', _wav(_genAmb()));
      _wf('slam', _wav(_genSlam()));
      _wf('click', _wav(_genClick()));
      _wf('chime', _wav(_genChime()));
      _wf('down', _wav(_genDown()));
      ready = true;
    } catch (_) {}
  }

  static String _p(String n) => '$dir${Platform.pathSeparator}$n.wav';

  static void _wf(String n, Uint8List b) {
    File(_p(n)).writeAsBytesSync(b);
  }

  static void play(String name) {
    if (_mobile) {
      _mobilePlay(name);
      return;
    }
    if (!ready || _busy.contains(name)) return;
    _busy.add(name);
    _spawn(name).then((p) {
      if (p == null) {
        _busy.remove(name);
        return;
      }
      _live[name] = p;
      p.exitCode.then((_) {
        _live.remove(name);
        _busy.remove(name);
      });
    });
  }

  static void _mobilePlay(String name) {
    if (name == 'scream' || name == 'js') {
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.heavyImpact();
      Future<void>.delayed(
        const Duration(milliseconds: 120),
        () => HapticFeedback.heavyImpact(),
      );
      Future<void>.delayed(
        const Duration(milliseconds: 260),
        () => HapticFeedback.vibrate(),
      );
    } else if (name == 'slam' || name == 'break') {
      SystemSound.play(SystemSoundType.click);
      HapticFeedback.mediumImpact();
    } else if (name == 'down') {
      HapticFeedback.heavyImpact();
    } else if (name == 'chime') {
      SystemSound.play(SystemSoundType.alert);
    } else {
      HapticFeedback.lightImpact();
    }
  }

  static void screamBurst() {
    if (_mobile) {
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.vibrate();
      Future<void>.delayed(
        const Duration(milliseconds: 180),
        () {
          SystemSound.play(SystemSoundType.alert);
          HapticFeedback.heavyImpact();
        },
      );
      return;
    }
    for (int i = 0; i < 3; i++) {
      Future<void>.delayed(
        Duration(milliseconds: i * 220),
        () {
          _busy.remove('scream');
          play('scream');
        },
      );
    }
  }

  static void startAmb() {
    if (_mobile) {
      if (_ambOn) return;
      _ambOn = true;
      _ambT?.cancel();
      _ambT = Timer.periodic(
        const Duration(milliseconds: 1700),
        (_) {
          if (_ambOn) HapticFeedback.lightImpact();
        },
      );
      return;
    }
    if (!ready || _ambOn) return;
    _ambOn = true;
    _loop();
  }

  static Future<void> _loop() async {
    while (_ambOn) {
      final p = await _spawn('amb');
      if (p == null) return;
      _live['amb'] = p;
      try {
        await p.exitCode;
      } catch (_) {}
      _live.remove('amb');
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }

  static void stopAmb() {
    _ambOn = false;
    _ambT?.cancel();
    _ambT = null;
    if (_mobile) return;
    try {
      _live['amb']?.kill();
    } catch (_) {}
  }

  static void stopAll() {
    stopAmb();
    if (_mobile) return;
    for (final p in _live.values) {
      try {
        p.kill();
      } catch (_) {}
    }
    _live.clear();
    _busy.clear();
  }

  static Uint8List _wav(List<double> s) {
    final n = s.length;
    final bd = ByteData(44 + n * 2);
    void ws(int o, String str) {
      for (int i = 0; i < str.length; i++) {
        bd.setUint8(o + i, str.codeUnitAt(i));
      }
    }
    ws(0, 'RIFF');
    bd.setUint32(4, 36 + n * 2, Endian.little);
    ws(8, 'WAVE');
    ws(12, 'fmt ');
    bd.setUint32(16, 16, Endian.little);
    bd.setUint16(20, 1, Endian.little);
    bd.setUint16(22, 1, Endian.little);
    bd.setUint32(24, sr, Endian.little);
    bd.setUint32(28, sr * 2, Endian.little);
    bd.setUint16(32, 2, Endian.little);
    bd.setUint16(34, 16, Endian.little);
    ws(36, 'data');
    bd.setUint32(40, n * 2, Endian.little);
    for (int i = 0; i < n; i++) {
      final v = (s[i].clamp(-1.0, 1.0) * 32767).round();
      bd.setInt16(44 + i * 2, v, Endian.little);
    }
    return bd.buffer.asUint8List();
  }

  static double _tanh(double x) {
    final e = m.exp(2 * x);
    return (e - 1) / (e + 1);
  }

  static List<double> _genScream() {
    final r = m.Random(7);
    final n = (sr * 1.6).round();
    final out = List<double>.filled(n, 0);
    for (int i = 0; i < n; i++) {
      final t = i / sr;
      final p = t / 1.6;
      final f = 780 - 540 * p + 90 * m.sin(t * 37);
      final saw = 2 * ((t * f) % 1) - 1;
      final nz = r.nextDouble() * 2 - 1;
      final gr = ((t * 92) % 1) > 0.5 ? 1.0 : -1.0;
      final env = m.min(1.0, t / 0.04) * m.pow(1 - p, 0.7).toDouble();
      var v = saw * 0.5 + nz * 0.35 + gr * 0.25;
      v = _tanh(2.6 * v) * env * 0.85;
      out[i] = v;
    }
    return out;
  }

  static List<double> _genAmb() {
    final r = m.Random(3);
    const dur = 16.0;
    final n = (sr * dur).round();
    final out = List<double>.filled(n, 0);
    double lp = 0;
    final notes = [110.0, 103.8, 130.8, 98.0];
    for (int i = 0; i < n; i++) {
      final t = i / sr;
      double v = m.sin(2 * m.pi * 46 * t) * 0.5;
      v += m.sin(2 * m.pi * 92.4 * t) * 0.2;
      final nz = r.nextDouble() * 2 - 1;
      lp += (nz - lp) * 0.05;
      v += lp * 0.35;
      v *= 0.72 + 0.28 * m.sin(2 * m.pi * 0.09 * t);
      for (int k = 0; k < 4; k++) {
        final st = 1.0 + k * 3.8;
        if (t > st && t < st + 3.2) {
          final dt2 = t - st;
          v += m.sin(2 * m.pi * notes[k % 4] * dt2) *
              0.16 * m.exp(-dt2 * 1.4);
        }
      }
      double fade = 1.0;
      if (t < 0.8) fade = t / 0.8;
      if (t > dur - 0.8) fade = (dur - t) / 0.8;
      out[i] = v * fade * 0.32;
    }
    return out;
  }

  static List<double> _genSlam() {
    final r = m.Random(11);
    final n = (sr * 0.35).round();
    final out = List<double>.filled(n, 0);
    double lp = 0;
    for (int i = 0; i < n; i++) {
      final t = i / sr;
      final nz = r.nextDouble() * 2 - 1;
      lp += (nz - lp) * 0.25;
      out[i] = lp * 0.7 * m.exp(-t * 16) +
          m.sin(2 * m.pi * 52 * t) * m.exp(-t * 9) * 0.9;
    }
    return out;
  }

  static List<double> _genClick() {
    final n = (sr * 0.07).round();
    final out = List<double>.filled(n, 0);
    for (int i = 0; i < n; i++) {
      final t = i / sr;
      out[i] = m.sin(2 * m.pi * 1400 * t) * m.exp(-t * 60) * 0.5;
    }
    return out;
  }

  static List<double> _genChime() {
    final notes = [523.3, 659.3, 784.0];
    final n = (sr * 2.0).round();
    final out = List<double>.filled(n, 0);
    for (int i = 0; i < n; i++) {
      final t = i / sr;
      double v = 0;
      for (int k = 0; k < 3; k++) {
        final st = k * 0.22;
        if (t > st) {
          v += m.sin(2 * m.pi * notes[k] * (t - st)) *
              m.exp(-(t - st) * 2.2) * 0.35;
        }
      }
      out[i] = v;
    }
    return out;
  }

  static List<double> _genDown() {
    final n = (sr * 1.0).round();
    final out = List<double>.filled(n, 0);
    for (int i = 0; i < n; i++) {
      final t = i / sr;
      final f = 280 - 220 * t;
      out[i] = m.sin(2 * m.pi * f * t) * m.exp(-t * 3) * 0.6;
    }
    return out;
  }

  static List<List<String>> _cmds(String p) {
    try {
      if (Platform.isMacOS) {
        return [
          ['afplay', p]
        ];
      }
      if (Platform.isLinux) {
        return [
          ['paplay', p],
          ['aplay', '-q', p]
        ];
      }
      if (Platform.isWindows) {
        final ps = '[System.Media.SoundPlayer]::new'
            '(\'$p\').PlaySync()';
        return [
          ['powershell', '-NoProfile', '-Command', ps]
        ];
      }
    } catch (_) {}
    return [];
  }

  static Future<Process?> _spawn(String name) async {
    if (!ready) return null;
    for (final c in _cmds(_p(name))) {
      try {
        return await Process.start(c[0], c.sublist(1));
      } catch (_) {}
    }
    return null;
  }
}

class PInfo {
  final int pid;
  final InternetAddress addr;
  final int port;
  final String name;
  String sel;
  int lastSeen;
  PInfo(this.pid, this.addr, this.port, this.name, this.lastSeen)
      : sel = '';
}

class HostInfo {
  final String name;
  final int map;
  final int count;
  final InternetAddress addr;
  final int port;
  final int ts;
  HostInfo(this.name, this.map, this.count, this.addr, this.port, this.ts);
}

class PRow {
  final int pid;
  final String name;
  final String sel;
  final bool host;
  PRow(this.pid, this.name, this.sel, this.host);
}

class Actor {
  final int pid;
  final String name;
  final int char;
  String node;
  String? eA;
  String? eB;
  double prog = 0;
  double stun = 0;
  double cdUntil = 0;
  double buffU = 0;
  double buffM = 1;
  double hideU = 0;
  double ventU = 0;
  String? forcing;
  double forceT = 0;
  double waitT = 0;
  double jx = 0;
  double jy = 0;
  int lastIn = 0;
  bool isAI = false;
  int aiGoal = -1;
  double aiDecide = 0;
  double aiRetreat = 0;
  Actor(this.pid, this.name, this.char, this.node);
}

class NzMark {
  final String o;
  final double u;
  NzMark(this.o, this.u);
}

class VActor {
  final int pid;
  final String name;
  final int ch;
  final double x;
  final double y;
  final double stun;
  final double cd;
  final double wait;
  final bool iv;
  final bool hd;
  final String nd;
  final String fc;
  VActor(
    this.pid, this.name, this.ch, this.x, this.y,
    this.stun, this.cd, this.wait, this.iv, this.hd,
    this.nd, this.fc,
  );
}

class Nz {
  final String o;
  final double u;
  Nz(this.o, this.u);
}

class VF {
  double t = 0;
  int hour = 0;
  double power = 100;
  int usage = 1;
  bool dl = true;
  bool dr = true;
  bool vent = true;
  bool light = false;
  bool cam = false;
  bool black = false;
  double jam = 0;
  double fear = 0;
  double blind = 0;
  double waitL = 0;
  double waitR = 0;
  double forceL = 0;
  double forceR = 0;
  double ddL = 0;
  double ddR = 0;
  int thL = -1;
  int thR = -1;
  List<VActor> actors = [];
  List<Nz> noise = [];
}

class Net extends ChangeNotifier {
  int page = 0;
  String status = 'Hazir. LAN veya TEK KISILIK YZ modu.';
  String myName = 'Oyuncu';
  int session = 0;

  RawDatagramSocket? sock;
  StreamSubscription<SocketEvent>? sub;
  bool isHost = false;
  bool aiMode = false;
  int soloDiff = 1;
  int soloCount = 2;
  int myPid = -1;
  int hostPid = -1;
  int pidSeq = 2;
  InternetAddress? hostAddr;
  int hostPort = kPort;
  int lastHostRx = 0;
  bool scanning = false;
  final Map<String, HostInfo> found = {};
  Timer? scanT;
  Timer? pingT;
  Timer? cliT;
  Timer? joinTO;
  Timer? simT;
  final m.Random _r = m.Random();

  final Map<int, PInfo> players = {};
  List<PRow> rows = [];
  int mapIdx = 0;
  String mySel = '';
  String localIp = '';

  bool inGame = false;
  String myRole = '';
  int myChar = 0;
  int guardPid = -1;
  double sT = 0;
  bool over = false;
  String overSide = '';
  String overReason = '';
  int overJs = -1;
  int overKiller = -1;
  bool surprise = false;
  double endDelay = 0;
  bool jsOn = false;
  double jsT = 0;

  double sPower = 100;
  bool black = false;
  bool dl = true;
  bool dr = true;
  bool ventOpen = true;
  bool lightOn = false;
  bool camOn = false;
  double dlDis = 0;
  double drDis = 0;
  double jamU = 0;
  double fearU = 0;
  double blindU = 0;
  final Map<int, Actor> actors = {};
  final List<NzMark> noise = [];
  final List<String> evQ = [];
  final List<String> sfxQ = [];
  int closeL = 0;
  int closeR = 0;
  Map<String, MNode> nodeById = {};
  Map<String, List<MEdge>> edgesByNode = {};
  Map<String, double> edgeLen = {};
  Map<String, String> edgeKind = {};
  GameMap get curMap => MAPS[mapIdx];

  Map<String, dynamic>? sCur;
  Map<String, dynamic>? sPrev;
  int sCurAt = 0;

  double dlShow = 1;
  double drShow = 1;
  double fanA = 0;
  double shakeX = 0;
  double shakeY = 0;
  double _jx = 0;
  double _jy = 0;
  int tickN = 0;
  int _lastLocalDoor = 0;

  // -------- Lobi satırlarını güncelle ----------
  void _updateRows() {
    rows = players.values.map((p) {
      return PRow(p.pid, p.name, p.sel, p.pid == hostPid);
    }).toList();
    notifyListeners();
  }

  void goSolo() {
    page = 5;
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

  void _onSock(SocketEvent e) {
    if (e != SocketEvent.read) return;
    final s = sock;
    if (s == null) return;
    Datagram? dg = s.receive();
    while (dg != null) {
      _rx(dg);
      dg = s.receive();
    }
  }

  void _rx(Datagram dg) {
    Map<String, dynamic> j;
    try {
      j = jsonDecode(utf8.decode(dg.data)) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    if (isHost) {
      _hostRx(j, dg.address, dg.port);
    } else {
      _cliRx(j, dg.address, dg.port);
    }
  }

  void _sendTo(Map<String, dynamic> mm, InternetAddress a, int p) {
    try {
      sock?.send(utf8.encode(jsonEncode(mm)), a, p);
    } catch (_) {}
  }

  void _bcast(Map<String, dynamic> mm) {
    for (final p in players.values) {
      if (p.pid == hostPid) continue;
      _sendTo(mm, p.addr, p.port);
    }
  }

  Future<bool> _ensureSock(int port) async {
    if (sock != null) return true;
    try {
      sock = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        port,
        reuseAddress: true,
      );
      sock!.broadcastEnabled = true;
      sub = sock!.listen(_onSock);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _closeSock() {
    sub?.cancel();
    sub = null;
    try {
      sock?.close();
    } catch (_) {}
    sock = null;
  }

  Future<void> hostGame() async {
    status = 'Oda aciliyor...';
    notifyListeners();
    final ok = await _ensureSock(kPort);
    if (!ok) {
      status = 'Port acilamadi. Baska oda acik olabilir.';
      notifyListeners();
      return;
    }
    isHost = true;
    aiMode = false;
    hostPid = 1;
    myPid = 1;
    pidSeq = 2;
    players.clear();
    final now = DateTime.now().millisecondsSinceEpoch;
    players[1] = PInfo(1, InternetAddress.loopbackIPv4, 0, myName, now);
    inGame = false;
    over = false;
    page = 2;
    status = 'Oda acik. Diger oyuncular LOBI ARA ile katilsin.';
    _findLocalIp();
    _updateRows();                     // <<< host kendi listesini görsün
    _startHostTimers();
    notifyListeners();
  }

  Future<void> _findLocalIp() async {
    try {
      final ifs = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );
      for (final i in ifs) {
        for (final a in i.addresses) {
          if (!a.isLoopback) {
            localIp = a.address;
            return;
          }
        }
      }
    } catch (_) {}
    localIp = '';
  }

  void _startHostTimers() {
    pingT?.cancel();
    pingT = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      final now = DateTime.now().millisecondsSinceEpoch;
      for (final p in players.values.toList()) {
        if (p.pid == hostPid) continue;
        _sendTo({'t': 'ping', 'ts': now}, p.addr, p.port);
      }
      final exp = <int>[];
      players.forEach((k, v) {
        if (k != hostPid && now - v.lastSeen > 8000) exp.add(k);
      });
      for (final k in exp) {
        _drop(k);
      }
    });
  }

  int _pidOf(InternetAddress a, int p) {
    for (final pl in players.values) {
      if (pl.addr.address == a.address && pl.port == p) {
        return pl.pid;
      }
    }
    return -1;
  }

  List<Map<String, dynamic>> _lobbyList() {
    return players.values.map((p) {
      return {'p': p.pid, 'n': p.name, 's': p.sel, 'h': p.pid == hostPid};
    }).toList();
  }

  void _bcastLobby() {
    _bcast({
      't': 'lobby',
      'players': _lobbyList(),
      'map': mapIdx,
      'host': hostPid
    });
  }

  void _hostRx(Map<String, dynamic> j, InternetAddress ad, int po) {
    final t = _s(j['t']);
    if (t == 'discover') {
      _sendTo({
        't': 'hostinfo',
        'hn': myName,
        'mp': mapIdx,
        'pc': players.length
      }, ad, po);
      return;
    }
    if (t == 'hello') {
      if (page != 2 || inGame) {
        _sendTo({'t': 'err', 'm': 'Oda su an oyunda'}, ad, po);
        return;
      }
      if (players.length >= kMaxPlayers) {
        _sendTo({'t': 'err', 'm': 'Oda dolu (4 kisi)'}, ad, po);
        return;
      }
      final id = pidSeq++;
      var nm = _s(j['n']);
      if (nm.isEmpty) nm = 'Oyuncu';
      final now = DateTime.now().millisecondsSinceEpoch;
      players[id] = PInfo(id, ad, po, nm, now);
      _sendTo({
        't': 'welcome',
        'pid': id,
        'host': hostPid,
        'map': mapIdx,
        'players': _lobbyList()
      }, ad, po);
      _updateRows();                 // host listesini güncelle
      _bcastLobby();
      status = '${players[id]!.name} katildi';
      notifyListeners();
      return;
    }
    final pid = _pidOf(ad, po);
    if (pid < 0) return;
    players[pid]?.lastSeen = DateTime.now().millisecondsSinceEpoch;
    if (t == 'leave') {
      _drop(pid);
    } else if (t == 'state') {
      final a = actors[pid];
      if (a != null && !a.isAI) {
        a.jx = _d(j['jx']);
        a.jy = _d(j['jy']);
        a.lastIn = DateTime.now().millisecondsSinceEpoch;
      }
    } else if (t == 'act') {
      _applyAct(pid, _s(j['k']), j['v']);
    }
  }

  void _drop(int pid) {
    final p = players.remove(pid);
    if (p == null) return;
    if (inGame && !over) {
      if (pid == guardPid) {
        endGame('anim', 'Guvenlik baglantisi koptu', -1, -1);
      } else {
        actors.remove(pid);
        if (!actors.values.any((a) => a.pid != guardPid)) {
          endGame('guard', 'Tum animatronikler gitti', -1, -1);
        }
      }
    }
    if (page == 2) {
      _updateRows();                // host listesini güncelle
      _bcastLobby();
    }
    status = '${p.name} ayrildi';
    notifyListeners();
  }

  Future<void> startScan() async {
    final ok = await _ensureSock(0);
    if (!ok) {
      status = 'Soket acilamadi';
      notifyListeners();
      return;
    }
    scanning = true;
    found.clear();
    page = 1;
    status = 'Odalar araniyor...';
    _startCliTimer();
    scanT?.cancel();
    scanT = Timer.periodic(
      const Duration(milliseconds: 1200),
      (_) => _sendDiscover(),
    );
    _sendDiscover();
    notifyListeners();
  }

  void _sendDiscover() {
    try {
      final b = InternetAddress('255.255.255.255');
      sock?.send(
        utf8.encode(jsonEncode({'t': 'discover', 'n': myName})),
        b,
        kPort,
      );
    } catch (_) {}
    final now = DateTime.now().millisecondsSinceEpoch;
    found.removeWhere((k, v) => now - v.ts > 5000);
    notifyListeners();
  }

  void stopScan() {
    scanning = false;
    scanT?.cancel();
    scanT = null;
  }

  void _startCliTimer() {
    if (cliT != null) return;
    cliT = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (page > 0 && !isHost && hostAddr != null) {
        // zaman aşımını 9 → 12 saniye yaptık
        if (now - lastHostRx > 12000) {
          _toMenu('Baglanti zaman asimi');
          return;
        }
      }
      if (page == 3 && !over && !isHost && myRole == 'A') {
        if (hostAddr != null) {
          _sendTo({'t': 'state', 'jx': _jx, 'jy': _jy}, hostAddr!, hostPort);
        }
      }
    });
  }

  Future<void> joinIp(String ip) async {
    final ok = await _ensureSock(0);
    if (!ok) {
      status = 'Soket acilamadi';
      notifyListeners();
      return;
    }
    InternetAddress a;
    try {
      a = InternetAddress(ip.trim());
    } catch (_) {
      status = 'Gecersiz IP adresi';
      notifyListeners();
      return;
    }
    _startCliTimer();
    hostAddr = a;
    hostPort = kPort;
    lastHostRx = DateTime.now().millisecondsSinceEpoch;
    status = 'Baglaniliyor: $ip';
    notifyListeners();
    _sendTo({'t': 'hello', 'n': myName}, a, kPort);
    joinTO?.cancel();
    joinTO = Timer(const Duration(seconds: 4), () {
      if (page != 2) {
        status = 'Yanit yok. IP ve ayni Wi-Fi kontrol et.';
        notifyListeners();
      }
    });
  }

  void joinFound(HostInfo h) {
    joinIp(h.addr.address);
  }

  void _cliRx(Map<String, dynamic> j, InternetAddress ad, int po) {
    final t = _s(j['t']);
    if (t == 'hostinfo') {
      if (scanning) {
        final key = '${ad.address}:$po';
        final now = DateTime.now().millisecondsSinceEpoch;
        found[key] = HostInfo(
            _s(j['hn']), _i(j['mp']), _i(j['pc']), ad, po, now);
        status = '${found.length} oda bulundu';
        notifyListeners();
      }
      return;
    }
    if (hostAddr != null) {
      if (ad.address != hostAddr!.address || po != hostPort) {
        if (t != 'err') return;
      }
    }
    lastHostRx = DateTime.now().millisecondsSinceEpoch;
    if (t == 'welcome') {
      if (page == 2) return;
      joinTO?.cancel();
      stopScan();
      isHost = false;
      myPid = _i(j['pid']);
      hostPid = _i(j['host']);
      mapIdx = _i(j['map']).clamp(0, MAPS.length - 1);
      hostAddr = ad;
      hostPort = po;
      _rowsFrom(j);
      mySel = '';
      page = 2;
      status = '';
      notifyListeners();
    } else if (t == 'lobby') {
      mapIdx = _i(j['map']).clamp(0, MAPS.length - 1);
      _rowsFrom(j);
      final inRoom = rows.any((r) => r.pid == myPid);
      if (!inRoom) {
        _toMenu('Odadan cikarildin');
        return;
      }
      final me = rows.firstWhere((r) => r.pid == myPid);
      mySel = me.sel;
      if (page == 3 || page == 4) page = 2;
      status = '';
      notifyListeners();
    } else if (t == 'start') {
      mapIdx = _i(j['map']).clamp(0, MAPS.length - 1);
      final roles = j['roles'];
      if (roles is Map) {
        final mine = roles['$myPid'];
        myRole = mine == null ? 'G' : _s(mine['r']);
        myChar = mine == null ? 0 : _i(mine['c']);
      }
      _startLocalGame();
    } else if (t == 'snap') {
      if (page == 3) {
        sPrev = sCur;
        sCur = j;
        sCurAt = DateTime.now().millisecondsSinceEpoch;
        final ev = j['ev'];
        if (ev is List) {
          for (final e in ev) {
            sfxQ.add(_s(e));
          }
        }
      }
    } else if (t == 'over') {
      _onOver(
        _s(j['w']),
        _s(j['rs']),
        _i(j['js']),
        _i(j['kp']),
        _i(j['sp']) == 1,
      );
    } else if (t == 'err') {
      status = _s(j['m']);
      notifyListeners();
    } else if (t == 'closed') {
      _toMenu('Oda kapatildi');
    } else if (t == 'ping') {
      if (_i(j['e']) != 1) {
        _sendTo({'t': 'ping', 'ts': j['ts'], 'e': 1}, ad, po);
      }
    }
  }

  void _rowsFrom(Map<String, dynamic> j) {
    rows = [];
    final list = j['players'];
    if (list is List) {
      for (final p in list) {
        rows.add(PRow(
            _i(p['p']), _s(p['n']), _s(p['s']), _i(p['h']) == 1));
      }
    }
  }

  void _startLocalGame() {
    inGame = true;
    over = false;
    jsOn = false;
    jsT = 0;
    endDelay = 0;
    sCur = null;
    sPrev = null;
    dlShow = 1;
    drShow = 1;
    session++;
    page = 3;
    Sfx.stopAll();
    Sfx.startAmb();
    notifyListeners();
  }

  void _toMenu(String msg) {
    if (isHost) _bcast({'t': 'closed'});
    scanT?.cancel();
    scanT = null;
    joinTO?.cancel();
    joinTO = null;
    cliT?.cancel();
    cliT = null;
    pingT?.cancel();
    pingT = null;
    simT?.cancel();
    simT = null;
    _closeSock();
    isHost = false;
    aiMode = false;
    scanning = false;
    inGame = false;
    over = false;
    jsOn = false;
    players.clear();
    rows = [];
    actors.clear();
    sCur = null;
    sPrev = null;
    hostAddr = null;
    Sfx.stopAll();
    page = 0;
    status = msg;
    notifyListeners();
  }

  void leaveRoom() {
    if (aiMode) {
      simT?.cancel();
      simT = null;
      inGame = false;
      over = false;
      jsOn = false;
      actors.clear();
      isHost = false;
      aiMode = false;
      Sfx.stopAll();
      page = 0;
      status = 'YZ modu kapatildi';
      notifyListeners();
      return;
    }
    if (isHost) {
      _toMenu('Oda kapatildi');
    } else {
      if (hostAddr != null) {
        _sendTo({'t': 'leave'}, hostAddr!, hostPort);
      }
      _toMenu('Odadan ayrildin');
    }
  }

  Future<void> startSolo() async {
    status = 'YZ modu hazirlaniyor...';
    notifyListeners();
    final ok = await _ensureSock(kPort);
    if (!ok) {
      status = 'Soket acilamadi. Baska oturum acik olabilir.';
      notifyListeners();
      return;
    }
    isHost = true;
    aiMode = true;
    hostPid = 1;
    myPid = 1;
    players.clear();
    final now = DateTime.now().millisecondsSinceEpoch;
    players[1] = PInfo(1, InternetAddress.loopbackIPv4, 0, myName, now);
    inGame = false;
    over = false;
    _startHostTimers();
    final chars = <int>[];
    final pool = List<int>.generate(CHARS.length, (i) => i);
    pool.shuffle(_r);
    for (int i = 0; i < soloCount && i < pool.length; i++) {
      chars.add(pool[i]);
    }
    final roles = <String, dynamic>{
      '1': {'r': 'G', 'c': -1},
    };
    int id = 100;
    for (final c in chars) {
      roles['$id'] = {'r': 'A', 'c': c};
      id++;
    }
    _initSim(1, roles);
    myRole = 'G';
    myChar = 0;
    _startLocalGame();
    _startSimTimer();
  }

  void pick(String sel) {
    if (isHost) {
      _applyAct(myPid, 'pick', sel);
    } else if (hostAddr != null) {
      _sendTo({'t': 'act', 'k': 'pick', 'v': sel}, hostAddr!, hostPort);
    }
  }

  void setMap(int i) {
    if (isHost) {
      _applyAct(myPid, 'map', i);
    } else if (hostAddr != null) {
      _sendTo({'t': 'act', 'k': 'map', 'v': i}, hostAddr!, hostPort);
    }
  }

  void startGame() {
    if (!isHost || page != 2 || inGame) return;
    if (players.length < 2) {
      status = 'En az 2 kisi gerekli';
      notifyListeners();
      return;
    }
    int? guard;
    for (final p in players.values) {
      if (p.sel == 'G') {
        guard = p.pid;
        break;
      }
    }
    if (guard == null) {
      for (final p in players.values) {
        if (p.pid != hostPid && p.sel == '') {
          guard = p.pid;
          break;
        }
      }
      guard ??= hostPid;
      players[guard]!.sel = 'G';
    }
    final roles = <String, dynamic>{};
    int k = 0;
    for (final p in players.values) {
      if (p.pid == guard) {
        roles['${p.pid}'] = {'r': 'G', 'c': -1};
      } else {
        int c;
        if (p.sel.startsWith('C')) {
          c = int.tryParse(p.sel.substring(1)) ?? (k % CHARS.length);
        } else {
          c = (p.pid * 5 + k * 3) % CHARS.length;
        }
        k++;
        roles['${p.pid}'] = {'r': 'A', 'c': c};
      }
    }
    mapIdx = mapIdx.clamp(0, MAPS.length - 1);
    aiMode = false;
    _initSim(guard, roles);
    _bcast({'t': 'start', 'map': mapIdx, 'roles': roles});
    final mine = roles['$myPid'] as Map<String, dynamic>;
    myRole = _s(mine['r']);
    myChar = _i(mine['c']);
    _startLocalGame();
    _startSimTimer();
  }

  void _startSimTimer() {
    simT?.cancel();
    simT = Timer.periodic(const Duration(milliseconds: 50), (_) {
      _tick();
    });
  }

  void _initMapIdx() {
    nodeById = {for (final n in curMap.nodes) n.id: n};
    edgesByNode = {};
    edgeLen = {};
    edgeKind = {};
    for (final e in curMap.edges) {
      edgesByNode.putIfAbsent(e.a, () => []).add(e);
      edgesByNode.putIfAbsent(e.b, () => []).add(e);
      final na = nodeById[e.a]!;
      final nb = nodeById[e.b]!;
      final dx = na.x - nb.x;
      final dy = na.y - nb.y;
      edgeLen['${e.a}|${e.b}'] = m.sqrt(dx * dx + dy * dy);
      edgeKind['${e.a}|${e.b}'] = e.kind;
    }
  }

  double _len(String a, String b) {
    return edgeLen['$a|$b'] ?? edgeLen['$b|$a'] ?? 1.0;
  }

  String _kind(String a, String b) {
    return edgeKind['$a|$b'] ?? edgeKind['$b|$a'] ?? '';
  }

  double _lerp(double a, double b, double t) => a + (b - a) * t;

  void _initSim(int guard, Map<String, dynamic> roles) {
    _initMapIdx();
    guardPid = guard;
    sT = 0;
    sPower = 100;
    black = false;
    dl = true;
    dr = true;
    ventOpen = true;
    lightOn = false;
    camOn = false;
    dlDis = 0;
    drDis = 0;
    jamU = 0;
    fearU = 0;
    blindU = 0;
    closeL = 0;
    closeR = 0;
    noise.clear();
    evQ.clear();
    actors.clear();
    final spawns = curMap.nodes
        .where((n) => n.id != 'O' && n.id != 'L' && n.id != 'R' && n.id != 'U')
        .toList();
    spawns.shuffle(_r);
    int si = 0;
    roles.forEach((pidStr, info) {
      final pid = int.tryParse(pidStr) ?? -1;
      if (_s(info['r']) != 'A') return;
      final nd = spawns[si % spawns.length].id;
      si++;
      final ch = _i(info['c']).clamp(0, CHARS.length - 1);
      final nm = players[pid]?.name ?? 'YZ-${CHARS[ch].name}';
      final a = Actor(pid, nm, ch, nd);
      a.isAI = pid >= 100;
      if (a.isAI) a.aiDecide = 1.0 + _r.nextDouble();
      actors[pid] = a;
    });
  }

  List<String> _bfs(String from, String to) {
    if (from == to) return [from];
    final prev = <String, String>{};
    final q = [from];
    final seen = {from};
    while (q.isNotEmpty) {
      final cur = q.removeAt(0);
      for (final e in edgesByNode[cur] ?? const <MEdge>[]) {
        final other = e.a == cur ? e.b : e.a;
        if (seen.contains(other)) continue;
        seen.add(other);
        prev[other] = cur;
        q.add(other);
      }
    }
    if (!seen.contains(to)) return [];
    final path = <String>[to];
    var at = to;
    while (at != from) {
      at = prev[at]!;
      path.insert(0, at);
    }
    return path;
  }

  void _tick() {
    if (!inGame || over) return;
    const double dt = 0.05;
    sT += dt;
    tickN++;
    if (sT >= kGameLen) {
      endGame('guard', 'Sabah 6! Geceye dayandin.', -1, -1);
      return;
    }
    if (!black) {
      double drain = 0.45;
      if (!dl) drain += 0.5;
      if (!dr) drain += 0.5;
      if (lightOn) drain += 0.25;
      if (camOn) drain += 0.3;
      if (!ventOpen) drain += 0.15;
      if (aiMode) drain *= [0.9, 1.0, 1.15][soloDiff.clamp(0, 2)];
      sPower -= drain * dt;
      if (sPower <= 0) {
        sPower = 0;
        _blackout();
      }
    }
    noise.removeWhere((z) => sT > z.u);
    _aiTick();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    for (final a in actors.values.toList()) {
      if (!actors.containsKey(a.pid)) continue;
      final c = CHARS[a.char];
      if (a.stun > 0) {
        a.stun -= dt;
        continue;
      }
      final fresh = a.isAI || nowMs - a.lastIn < 1200;
      double ix = fresh ? a.jx : 0;
      double iy = fresh ? a.jy : 0;
      double ilen = m.sqrt(ix * ix + iy * iy);
      if (ilen > 1) {
        ix /= ilen;
        iy /= ilen;
        ilen = 1.0;
      }
      double sp = 170 * c.speed;
      if (a.isAI) sp *= [0.9, 1.0, 1.15][soloDiff.clamp(0, 2)];
      if (sT < a.buffU) sp *= a.buffM;
      if (a.eB != null) {
        final pa = nodeById[a.eA!]!;
        final pb = nodeById[a.eB!]!;
        final len = _len(a.eA!, a.eB!);
        final dx = (pb.x - pa.x) / len;
        final dy = (pb.y - pa.y) / len;
        if (!a.isAI && ilen > 0.5 && (dx * ix + dy * iy) < -0.55) {
          final tmp = a.eA;
          a.eA = a.eB;
          a.eB = tmp;
          a.prog = 1 - a.prog;
        }
        final kind = _kind(a.eA!, a.eB!);
        double s2 = sp;
        if (kind == 'vent') {
          s2 *= 0.8;
          if (c.passive == 'vent') s2 *= 1.6;
          if (sT < a.ventU) s2 *= 2.2;
        }
        a.prog += s2 * dt / len;
        if (a.prog >= 1) {
          _arrive(a, a.eB!);
        } else if (a.prog <= 0) {
          _arrive(a, a.eA!);
        }
      } else {
        if (a.node == 'L' && dl) {
          a.waitT += dt;
          if (a.waitT >= 5) {
            _startEdge(a, 'O');
            evQ.add('auto');
            continue;
          }
        } else if (a.node == 'R' && dr) {
          a.waitT += dt;
          if (a.waitT >= 5) {
            _startEdge(a, 'O');
            evQ.add('auto');
            continue;
          }
        } else {
          a.waitT = 0;
        }
        if (a.forcing != null) {
          final side = a.forcing!;
          final open = side == 'L' ? dl : dr;
          if (open || a.node != side) {
            a.forcing = null;
          } else {
            a.forceT += dt;
            final need = c.passive == 'door' ? 1.3 : 2.6;
            if (a.forceT >= need) {
              if (side == 'L') {
                dl = true;
                dlDis = sT + 4;
              } else {
                dr = true;
                drDis = sT + 4;
              }
              evQ.add('break');
              a.forcing = null;
            }
          }
        }
        if (ilen > 0.35) {
          final edges = edgesByNode[a.node] ?? [];
          String? best;
          double bestDot = 0.5;
          for (final e in edges) {
            final other = e.a == a.node ? e.b : e.a;
            final kind = _kind(e.a, e.b);
            if (kind == 'doorL' && !dl) continue;
            if (kind == 'doorR' && !dr) continue;
            if (kind == 'vent' && !ventOpen) continue;
            final na = nodeById[a.node]!;
            final nb = nodeById[other]!;
            final len = _len(a.node, other);
            final dot = ((nb.x - na.x) / len) * ix + ((nb.y - na.y) / len) * iy;
            if (dot > bestDot) {
              bestDot = dot;
              best = other;
            }
          }
          if (best != null) _startEdge(a, best);
        }
      }
    }
    if (tickN % 2 == 0) _sendSnap();
  }

  void _startEdge(Actor a, String other) {
    a.eA = a.node;
    a.eB = other;
    a.prog = 0;
    a.waitT = 0;
    a.forcing = null;
  }

  void _arrive(Actor a, String nodeId) {
    a.eA = null;
    a.eB = null;
    a.prog = 0;
    a.node = nodeId;
    if (nodeId == 'O') {
      _killBy(a);
      return;
    }
    if (nodeId == 'L' || nodeId == 'R' || nodeId == 'U') {
      final c = CHARS[a.char];
      final quiet = c.passive == 'quiet' || sT < a.hideU;
      if (!quiet) evQ.add('al_$nodeId');
    }
  }

  void _killBy(Actor a) {
    endGame('anim', '${a.name} ofise sizdi!', a.char, a.pid);
  }

  void _blackout() {
    if (black) return;
    black = true;
    dl = true;
    dr = true;
    ventOpen = true;
    lightOn = false;
    camOn = false;
    evQ.add('black');
  }

  void _slamOn(String side) {
    final nid = side == 'L' ? 'L' : 'R';
    for (final a in actors.values) {
      if (a.eB == null) continue;
      final hit = (a.eA == nid && a.eB == 'O') || (a.eA == 'O' && a.eB == nid);
      if (hit) _slam(a);
    }
  }

  void _slam(Actor a) {
    final opts = curMap.nodes
        .where((n) => n.id != 'O' && n.id != a.node)
        .map((n) => n.id)
        .toList();
    a.node = opts[_r.nextInt(opts.length)];
    a.eA = null;
    a.eB = null;
    a.prog = 0;
    a.stun = 3;
    a.forcing = null;
    a.waitT = 0;
    evQ.add('slam');
  }

  void _aiTick() {
    if (!aiMode) return;
    final aggr = [0.6, 1.0, 1.5][soloDiff.clamp(0, 2)];
    const double dt = 0.05;
    for (final a in actors.values) {
      if (!a.isAI || a.stun > 0) continue;
      final c = CHARS[a.char];
      if (a.eB != null) {
        final pb = nodeById[a.eB!]!;
        final pa = nodeById[a.eA!]!;
        final len = _len(a.eA!, a.eB!);
        a.jx = (pb.x - pa.x) / len;
        a.jy = (pb.y - pa.y) / len;
        a.lastIn = DateTime.now().millisecondsSinceEpoch;
        continue;
      }
      a.aiDecide -= dt;
      if (a.forcing != null) {
        a.jx = 0;
        a.jy = 0;
        continue;
      }
      if (a.node == 'L' || a.node == 'R') {
        final open = a.node == 'L' ? dl : dr;
        if (open) {
          if (a.aiDecide <= 0) {
            _startEdge(a, 'O');
            a.aiDecide = 2.0 + _r.nextDouble() * 3.0 / aggr;
          } else {
            a.jx = 0;
            a.jy = 0;
          }
        } else {
          if (a.aiDecide <= 0) {
            final roll = _r.nextDouble();
            if (roll < 0.45 * aggr) {
              final canBr = c.active == 'doorbreak';
              if (canBr && sT >= a.cdUntil) {
                if (a.node == 'L') {
                  dl = true;
                  dlDis = sT + 5;
                } else {
                  dr = true;
                  drDis = sT + 5;
                }
                evQ.add('break');
                a.cdUntil = sT + c.cd;
                a.aiDecide = 1.0;
              } else {
                a.forcing = a.node;
                a.forceT = 0;
                a.aiDecide = 3.0;
              }
            } else {
              a.aiRetreat = 3.0 + _r.nextDouble() * 3.0;
              a.aiDecide = 1.0 + _r.nextDouble();
            }
          }
        }
        continue;
      }
      if (a.aiRetreat > 0) {
        a.aiRetreat -= dt;
        final far = ['BR', 'BL', 'D']
            .where((n) => nodeById.containsKey(n))
            .toList();
        if (far.isEmpty) continue;
        final target = far[_r.nextInt(far.length)];
        final path = _bfs(a.node, target);
        if (path.length >= 2) {
          final nb = nodeById[path[1]]!;
          final na = nodeById[a.node]!;
          final len = _len(a.node, path[1]);
          a.jx = (nb.x - na.x) / len;
          a.jy = (nb.y - na.y) / len;
          a.lastIn = DateTime.now().millisecondsSinceEpoch;
        }
        continue;
      }
      if (a.node == 'U' && ventOpen) {
        if (_r.nextDouble() < 0.4 * aggr * dt * 20) {
          _startEdge(a, 'O');
          continue;
        }
      }
      if (a.aiDecide <= 0) {
        final wl = 1.0 + closeR * 0.4;
        final wr = 1.0 + closeL * 0.4;
        String target;
        final roll = _r.nextDouble() * (wl + wr + 1.0);
        if (roll < wl) {
          target = 'L';
        } else if (roll < wl + wr) {
          target = 'R';
        } else {
          target = 'U';
        }
        a.aiGoal = curMap.nodes.indexWhere((n) => n.id == target);
        a.aiDecide = 0.8 + _r.nextDouble() * 1.4 / aggr;
      }
      if (a.aiGoal >= 0 && a.aiGoal < curMap.nodes.length) {
        final target = curMap.nodes[a.aiGoal].id;
        final path = _bfs(a.node, target);
        if (path.length >= 2) {
          final nb = nodeById[path[1]]!;
          final na = nodeById[a.node]!;
          final len = _len(a.node, path[1]);
          a.jx = (nb.x - na.x) / len;
          a.jy = (nb.y - na.y) / len;
          a.lastIn = DateTime.now().millisecondsSinceEpoch;
        } else {
          a.jx = 0;
          a.jy = 0;
        }
      }
      if (sT >= a.cdUntil && _r.nextDouble() < 0.01 * aggr) {
        _aiAbility(a, c);
      }
    }
  }

  void _aiAbility(Actor a, CharDef c) {
    var used = true;
    if (c.active == 'speed') {
      a.buffU = sT + 2.5;
      a.buffM = 1.9;
    } else if (c.active == 'silent') {
      a.hideU = sT + 5;
    } else if (c.active == 'ventrush') {
      a.ventU = sT + 5;
    } else if (c.active == 'camjam') {
      jamU = sT + 6;
      if (camOn) camOn = false;
      evQ.add('jam');
    } else if (c.active == 'light') {
      blindU = sT + 1.6;
      if (lightOn) lightOn = false;
    } else if (c.active == 'noise') {
      final opts = curMap.nodes
          .where((n) => n.id != 'O')
          .map((n) => n.id)
          .toList();
      noise.add(NzMark(opts[_r.nextInt(opts.length)], sT + 7));
    } else if (c.active == 'fear') {
      fearU = sT + 3;
      evQ.add('fear');
    } else if (c.active == 'dash') {
      a.buffU = sT + 1.3;
      a.buffM = 2.4;
    } else if (c.active == 'drain') {
      if (!black) {
        sPower = m.max(0.0, sPower - 12);
        if (sPower <= 0) _blackout();
      }
    } else if (c.active == 'teleport') {
      final opts = ['L', 'R', 'U']
          .where((n) => nodeById.containsKey(n))
          .toList();
      a.node = opts[_r.nextInt(opts.length)];
      a.eA = null;
      a.eB = null;
      a.prog = 0;
      a.stun = 0.4;
      a.forcing = null;
    } else if (c.active == 'scream') {
      if (camOn) camOn = false;
      fearU = m.max(fearU, sT + 1.2);
      evQ.add('scream');
    } else {
      used = false;
    }
    if (used) a.cdUntil = sT + c.cd;
  }

  void _applyAct(int pid, String k, dynamic v) {
    if (page == 2 && !inGame) {
      if (k == 'pick') {
        final s = _s(v);
        final p = players[pid];
        if (p == null) return;
        if (s == 'G') {
          final other = players.values
              .where((q) => q.sel == 'G' && q.pid != pid)
              .toList();
          if (other.isNotEmpty) {
            if (pid != hostPid) {
              _sendTo({'t': 'err', 'm': 'Guvenlik zaten secildi'}, p.addr, p.port);
            }
            return;
          }
        }
        p.sel = s;
        if (pid == myPid) mySel = s;
        _updateRows();            // host listesini güncelle
        _bcastLobby();
        notifyListeners();
      } else if (k == 'map' && pid == hostPid) {
        mapIdx = _i(v).clamp(0, MAPS.length - 1);
        _updateRows();
        _bcastLobby();
        notifyListeners();
      }
      return;
    }
    // oyun içi aksiyonlar (değişmedi)
    if (!inGame || over) return;
    if (pid == guardPid) {
      if (black) return;
      if (k == 'dl') {
        if (sT < dlDis) return;
        dl = !dl;
        if (!dl) {
          closeL++;
          _slamOn('L');
        }
        evQ.add('door');
        _sendSnap();
      } else if (k == 'dr') {
        if (sT < drDis) return;
        dr = !dr;
        if (!dr) {
          closeR++;
          _slamOn('R');
        }
        evQ.add('door');
        _sendSnap();
      } else if (k == 'li') {
        lightOn = !lightOn;
        _sendSnap();
      } else if (k == 'cm') {
        if (sT < jamU && !camOn) return;
        camOn = !camOn;
        _sendSnap();
      } else if (k == 'vt') {
        ventOpen = !ventOpen;
        if (!ventOpen) {
          for (final a in actors.values) {
            if (a.eB == null) continue;
            final hit = (a.eA == 'U' && a.eB == 'O') || (a.eA == 'O' && a.eB == 'U');
            if (hit) _slam(a);
          }
        }
        evQ.add('vent');
        _sendSnap();
      }
      return;
    }
    final a = actors[pid];
    if (a == null || a.isAI) return;
    final c = CHARS[a.char];
    if (k == 'ab') {
      if (sT < a.cdUntil || a.stun > 0) return;
      var used = true;
      if (c.active == 'speed') {
        a.buffU = sT + 2.5;
        a.buffM = 1.9;
      } else if (c.active == 'silent') {
        a.hideU = sT + 5;
      } else if (c.active == 'ventrush') {
        a.ventU = sT + 5;
      } else if (c.active == 'doorbreak') {
        if (a.eB == null && a.node == 'L' && !dl) {
          dl = true;
          dlDis = sT + 5;
          evQ.add('break');
        } else if (a.eB == null && a.node == 'R' && !dr) {
          dr = true;
          drDis = sT + 5;
          evQ.add('break');
        } else {
          used = false;
        }
      } else if (c.active == 'camjam') {
        jamU = sT + 6;
        if (camOn) camOn = false;
        evQ.add('jam');
      } else if (c.active == 'light') {
        blindU = sT + 1.6;
        if (lightOn) lightOn = false;
      } else if (c.active == 'noise') {
        final opts = curMap.nodes
            .where((n) => n.id != 'O')
            .map((n) => n.id)
            .toList();
        noise.add(NzMark(opts[_r.nextInt(opts.length)], sT + 7));
      } else if (c.active == 'fear') {
        fearU = sT + 3;
        evQ.add('fear');
      } else if (c.active == 'dash') {
        a.buffU = sT + 1.3;
        a.buffM = 2.4;
      } else if (c.active == 'drain') {
        if (!black) {
          sPower = m.max(0.0, sPower - 12);
          if (sPower <= 0) _blackout();
        }
      } else if (c.active == 'teleport') {
        final opts = ['L', 'R', 'U']
            .where((n) => nodeById.containsKey(n))
            .toList();
        a.node = opts[_r.nextInt(opts.length)];
        a.eA = null;
        a.eB = null;
        a.prog = 0;
        a.stun = 0.4;
        a.forcing = null;
      } else if (c.active == 'scream') {
        if (camOn) camOn = false;
        fearU = m.max(fearU, sT + 1.2);
        evQ.add('scream');
      } else {
        used = false;
      }
      if (used) a.cdUntil = sT + c.cd;
      _sendSnap();
    } else if (k == 'ctx') {
      final s2 = _s(v);
      if (a.stun > 0) return;
      if (s2 == 'GIR' || s2 == 'SALDIR') {
        if (a.eB == null && a.node == 'L' && dl) {
          if (s2 == 'SALDIR') {
            a.buffU = sT + 1.0;
            a.buffM = 1.6;
          }
          _startEdge(a, 'O');
        } else if (a.eB == null && a.node == 'R' && dr) {
          if (s2 == 'SALDIR') {
            a.buffU = sT + 1.0;
            a.buffM = 1.6;
          }
          _startEdge(a, 'O');
        }
      } else if (s2 == 'ZORLA') {
        if (a.eB == null && a.node == 'L' && !dl) {
          a.forcing = 'L';
          a.forceT = 0;
        } else if (a.eB == null && a.node == 'R' && !dr) {
          a.forcing = 'R';
          a.forceT = 0;
        }
      } else if (s2 == 'VENT') {
        if (a.eB == null && a.node == 'U' && ventOpen) {
          _startEdge(a, 'O');
        }
      }
      _sendSnap();
    }
  }

  int? _revealAt(String node) {
    if (!lightOn || black) return null;
    for (final a in actors.values) {
      final c = CHARS[a.char];
      final atDoor = a.eB == null && a.node == node;
      final crossing = a.eB != null &&
          ((a.eA == node && a.eB == 'O') || (a.eA == 'O' && a.eB == node));
      if (atDoor || crossing) {
        final imm = c.passive == 'lightimmune';
        final gh = c.passive == 'ghost';
        if (imm || gh || sT < a.hideU) continue;
        return a.char;
      }
    }
    return null;
  }

  void _sendSnap() {
    if (!inGame) return;
    final al = <Map<String, dynamic>>[];
    for (final a in actors.values) {
      final c = CHARS[a.char];
      double x;
      double y;
      if (a.eB != null) {
        final pa = nodeById[a.eA!]!;
        final pb = nodeById[a.eB!]!;
        x = _lerp(pa.x, pb.x, a.prog);
        y = _lerp(pa.y, pb.y, a.prog);
      } else {
        final n = nodeById[a.node]!;
        x = n.x;
        y = n.y;
      }
      final hidden = c.passive == 'ghost' || sT < a.hideU;
      final iv = a.eB != null && _kind(a.eA!, a.eB!) == 'vent';
      al.add({
        'i': a.pid,
        'n': a.name,
        'c': a.char,
        'x': x,
        'y': y,
        'st': m.max(0.0, a.stun),
        'cd': m.max(0.0, a.cdUntil - sT),
        'iv': iv ? 1 : 0,
        'hd': hidden ? 1 : 0,
        'nd': a.eB != null ? '${a.eA}>${a.eB}' : a.node,
        'wt': a.waitT,
        'fc': a.forcing ?? '',
      });
    }
    sfxQ.addAll(evQ);
    double fL = 0;
    double fR = 0;
    for (final a in actors.values) {
      if (a.forcing == 'L') fL = m.max(fL, a.forceT / 2.6);
      if (a.forcing == 'R') fR = m.max(fR, a.forceT / 2.6);
    }
    final snap = <String, dynamic>{
      't': 'snap',
      'tm': sT,
      'pw': sPower,
      'us': _usage(),
      'dl': dl,
      'dr': dr,
      'vd': ventOpen,
      'li': lightOn,
      'cm': camOn,
      'bo': black,
      'jm': m.max(0.0, jamU - sT),
      'fe': m.max(0.0, fearU - sT),
      'bl': m.max(0.0, blindU - sT),
      'wl': _waitAt('L'),
      'wr': _waitAt('R'),
      'fl': fL,
      'fr': fR,
      'ddl': m.max(0.0, dlDis - sT),
      'ddr': m.max(0.0, drDis - sT),
      'tl': _revealAt('L') ?? -1,
      'tr': _revealAt('R') ?? -1,
      'actors': al,
      'nz': noise.map((z) => {'o': z.o, 'u': z.u - sT}).toList(),
      'ev': evQ.toList(),
    };
    evQ.clear();
    _bcast(snap);
  }

  double _waitAt(String node) {
    double w = 0;
    for (final a in actors.values) {
      if (a.eB == null && a.node == node) w = m.max(w, a.waitT);
    }
    return w;
  }

  int _usage() {
    int u = 1;
    if (!dl) u++;
    if (!dr) u++;
    if (lightOn) u++;
    if (camOn) u++;
    if (!ventOpen) u++;
    return u;
  }

  void endGame(String side, String reason, int js, int killer) {
    if (over) return;
    over = true;
    simT?.cancel();
    simT = null;
    surprise = _r.nextDouble() < 0.01;
    _bcast({
      't': 'over',
      'w': side,
      'rs': reason,
      'js': js,
      'kp': killer,
      'sp': surprise ? 1 : 0
    });
    _onOver(side, reason, js, killer, surprise);
  }

  void _onOver(String side, String reason, int js, int killer, bool sp) {
    over = true;
    overSide = side;
    overReason = reason;
    overJs = js;
    overKiller = killer;
    surprise = sp;
    endDelay = 0;
    Sfx.stopAmb();
    if (js >= 0 && (myRole == 'G' || killer == myPid)) {
      jsOn = true;
      jsT = 0;
      sfxQ.add('js');
    } else if (side == 'guard') {
      sfxQ.add('chime');
    }
    notifyListeners();
  }

  void toLobbyAll() {
    if (!isHost) return;
    inGame = false;
    over = false;
    jsOn = false;
    actors.clear();
    _updateRows();                 // host listesini güncelle
    _bcastLobby();
    page = 2;
    status = 'Lobiye donuldu.';
    notifyListeners();
  }

  VF vf(int nowMs) {
    if (isHost && inGame) return _vfSim();
    return _vfSnap(nowMs);
  }

  VF _vfSim() {
    final vf = VF();
    vf.t = sT;
    vf.hour = m.min(6, (sT / (kGameLen / 6)).floor());
    vf.power = sPower;
    vf.usage = _usage();
    vf.dl = dl;
    vf.dr = dr;
    vf.vent = ventOpen;
    vf.light = lightOn;
    vf.cam = camOn;
    vf.black = black;
    vf.jam = m.max(0.0, jamU - sT);
    vf.fear = m.max(0.0, fearU - sT);
    vf.blind = m.max(0.0, blindU - sT);
    vf.waitL = _waitAt('L');
    vf.waitR = _waitAt('R');
    for (final a in actors.values) {
      if (a.forcing == 'L') vf.forceL = m.max(vf.forceL, a.forceT / 2.6);
      if (a.forcing == 'R') vf.forceR = m.max(vf.forceR, a.forceT / 2.6);
    }
    vf.ddL = m.max(0.0, dlDis - sT);
    vf.ddR = m.max(0.0, drDis - sT);
    vf.thL = _revealAt('L') ?? -1;
    vf.thR = _revealAt('R') ?? -1;
    for (final a in actors.values) {
      final c = CHARS[a.char];
      double x;
      double y;
      if (a.eB != null) {
        final pa = nodeById[a.eA!]!;
        final pb = nodeById[a.eB!]!;
        x = _lerp(pa.x, pb.x, a.prog);
        y = _lerp(pa.y, pb.y, a.prog);
      } else {
        final n = nodeById[a.node]!;
        x = n.x;
        y = n.y;
      }
      final hidden = c.passive == 'ghost' || sT < a.hideU;
      final iv = a.eB != null && _kind(a.eA!, a.eB!) == 'vent';
      final nd = a.eB != null ? '${a.eA}>${a.eB}' : a.node;
      vf.actors.add(VActor(
        a.pid, a.name, a.char, x, y,
        m.max(0.0, a.stun), m.max(0.0, a.cdUntil - sT),
        a.waitT, iv, hidden, nd, a.forcing ?? '',
      ));
    }
    for (final z in noise) {
      vf.noise.add(Nz(z.o, z.u - sT));
    }
    return vf;
  }

  VF _vfSnap(int nowMs) {
    final vf = VF();
    final cur = sCur;
    if (cur == null) return vf;
    final alpha = ((nowMs - sCurAt) / 110).clamp(0.0, 1.0);
    vf.t = _d(cur['tm']);
    vf.hour = m.min(6, (vf.t / (kGameLen / 6)).floor());
    vf.power = _d(cur['pw']);
    vf.usage = _i(cur['us']);
    vf.dl = cur['dl'] == true;
    vf.dr = cur['dr'] == true;
    vf.vent = cur['vd'] == true;
    vf.light = cur['li'] == true;
    vf.cam = cur['cm'] == true;
    vf.black = cur['bo'] == true;
    vf.jam = _d(cur['jm']);
    vf.fear = _d(cur['fe']);
    vf.blind = _d(cur['bl']);
    vf.waitL = _d(cur['wl']);
    vf.waitR = _d(cur['wr']);
    vf.forceL = _d(cur['fl']);
    vf.forceR = _d(cur['fr']);
    vf.ddL = _d(cur['ddl']);
    vf.ddR = _d(cur['ddr']);
    vf.thL = _i(cur['tl']);
    vf.thR = _i(cur['tr']);
    final curList = cur['actors'] is List ? cur['actors'] as List : const [];
    List prevList = const [];
    if (sPrev != null && sPrev!['actors'] is List) {
      prevList = sPrev!['actors'] as List;
    }
    for (final a in curList) {
      final pid = _i(a['i']);
      double x = _d(a['x']);
      double y = _d(a['y']);
      for (final p in prevList) {
        if (_i(p['i']) == pid) {
          x = _lerp(_d(p['x']), x, alpha);
          y = _lerp(_d(p['y']), y, alpha);
          break;
        }
      }
      vf.actors.add(VActor(
        pid, _s(a['n']), _i(a['c']), x, y,
        _d(a['st']), _d(a['cd']), _d(a['wt']),
        _i(a['iv']) == 1, _i(a['hd']) == 1,
        _s(a['nd']), _s(a['fc']),
      ));
    }
    final nz = cur['nz'];
    if (nz is List) {
      for (final z in nz) {
        vf.noise.add(Nz(_s(z['o']), _d(z['u'])));
      }
    }
    return vf;
  }

  void sendJoy(double x, double y) {
    _jx = x;
    _jy = y;
    if (isHost && inGame && myRole == 'A') {
      final a = actors[myPid];
      if (a != null) {
        a.jx = x;
        a.jy = y;
        a.lastIn = DateTime.now().millisecondsSinceEpoch;
      }
    }
  }

  void gAct(String k) {
    if (isHost) {
      _applyAct(myPid, k, null);
    } else if (hostAddr != null) {
      _sendTo({'t': 'act', 'k': k}, hostAddr!, hostPort);
    }
    if (k == 'dl' || k == 'dr' || k == 'vt') {
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastLocalDoor > 400) sfxQ.add('door');
      _lastLocalDoor = now;
    }
  }

  String? ctxLabel(VF vf) {
    VActor? me;
    for (final a in vf.actors) {
      if (a.pid == myPid) {
        me = a;
        break;
      }
    }
    if (me == null) return null;
    if (me.nd.contains('>')) {
      final parts = me.nd.split('>');
      if (parts.length == 2 && parts[1] == 'O') {
        if (parts[0] == 'L' || parts[0] == 'R') return 'SALDIR';
      }
      return null;
    }
    if (me.nd == 'L') return vf.dl ? 'GIR' : 'ZORLA';
    if (me.nd == 'R') return vf.dr ? 'GIR' : 'ZORLA';
    if (me.nd == 'U' && vf.vent) return 'VENT';
    return null;
  }

  void doCtx() {
    final v = vf(DateTime.now().millisecondsSinceEpoch);
    final label = ctxLabel(v);
    if (label == null) return;
    if (isHost) {
      _applyAct(myPid, 'ctx', label);
    } else if (hostAddr != null) {
      _sendTo({'t': 'act', 'k': 'ctx', 'v': label}, hostAddr!, hostPort);
    }
  }

  void useAbility() {
    if (isHost) {
      _applyAct(myPid, 'ab', null);
    } else if (hostAddr != null) {
      _sendTo({'t': 'act', 'k': 'ab'}, hostAddr!, hostPort);
    }
  }

  void frame(double dt) {
    fanA += dt * (black ? 1.2 : 9.0);
    dlShow += ((dl ? 1.0 : 0.0) - dlShow) * m.min(1.0, dt * 10);
    drShow += ((dr ? 1.0 : 0.0) - drShow) * m.min(1.0, dt * 10);
    if (jsOn) {
      jsT += dt;
      if (jsT > 2.4 && page == 3) {
        page = 4;
        notifyListeners();
      }
    } else if (over && page == 3) {
      endDelay += dt;
      if (endDelay > 1.4) {
        page = 4;
        notifyListeners();
      }
    }
    final r = m.Random();
    double amp = 0;
    if (jsOn) amp = 16;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final vfNow = vf(nowMs);
    if (vfNow.fear > 0) amp = m.max(amp, 6.0);
    shakeX = amp > 0 ? (r.nextDouble() * 2 - 1) * amp : 0;
    shakeY = amp > 0 ? (r.nextDouble() * 2 - 1) * amp : 0;
    for (final e in sfxQ) {
      _mapSfx(e, nowMs);
    }
    sfxQ.clear();
  }

  void _mapSfx(String e, int now) {
    if (e == 'slam' || e == 'break') {
      Sfx.play('slam');
    } else if (e == 'door' || e == 'vent' || e == 'jam') {
      if (e == 'door' && now - _lastLocalDoor < 400 && myRole == 'G') return;
      Sfx.play('click');
    } else if (e == 'black') {
      Sfx.play('down');
    } else if (e == 'js') {
      Sfx.play('scream');
    } else if (e == 'chime') {
      Sfx.play('chime');
    } else if (e == 'scream') {
      if (myRole == 'G') Sfx.play('scream');
    }
  }

  void disposeAll() {
    _toMenu('');
    Sfx.stopAll();
  }
}

// ---------- main ----------
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Sfx.init();                  // masaüstü sesleri oluşana kadar bekle
  runApp(const App());
}

// ---------- App ----------
class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gece Vardiyasi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF05040A),
      ),
      home: const Root(),
    );
  }
}

class Root extends StatefulWidget {
  const Root({super.key});
  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  final Net gs = Net();

  @override
  void initState() {
    super.initState();
    gs.addListener(_re);
  }

  void _re() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    gs.removeListener(_re);
    gs.disposeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (gs.page == 1) {
      body = ScanPage(gs: gs);
    } else if (gs.page == 2) {
      body = LobbyPage(gs: gs);
    } else if (gs.page == 3) {
      body = GamePage(key: ValueKey<int>(gs.session), gs: gs);
    } else if (gs.page == 4) {
      body = EndPage(gs: gs);
    } else if (gs.page == 5) {
      body = SoloPage(gs: gs);
    } else {
      body = MenuPage(gs: gs);
    }
    return Scaffold(
      backgroundColor: const Color(0xFF05040A),
      body: SafeArea(child: body),
    );
  }
}

// ---------- Arayüz widget'ları (aynı, değişiklik yok) ----------
// (Btn, chip, MenuPage, ScanPage, LobbyPage, SoloPage, GamePage, EndPage,
//  Joy, JoyP, ArcP, JsOverlay, JsP, drawAnimatronic, AnimPrev, OfficeP,
//  MapP, NoiseP, VignetteP)
// ... (öncekiyle tamamen aynı, buraya kopyalanabilir)

// Dosya sonu.
