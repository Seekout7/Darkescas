// lib/main.dart - GECE VARDIYASI: FNAF tarzı LAN + Tek Kişilik YZ
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as m;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const int kPort = 41237;
const double kGameLen = 150.0;
const int kMaxPlayers = 4;
const List<String> kHours = ['12 AM', '1 AM', '2 AM', '3 AM', '4 AM', '5 AM', '6 AM'];

extension Al on Color {
  Color al(double o) => Color.fromARGB((o.clamp(0.0, 1.0) * 255).round(), red, green, blue);
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
  const CharDef(this.name, this.color, this.speed, this.cd, this.active, this.passive);
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
  final double x, y;
  const MNode(this.id, this.name, this.x, this.y);
}

class MEdge {
  final String a, b;
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
  MNode('TL', 'SolUst', 170, 170), MNode('U', 'Ust Koridor', 500, 140),
  MNode('TR', 'SagUst', 830, 170), MNode('R', 'Sag Koridor', 870, 500),
  MNode('BR', 'SagAlt', 830, 830), MNode('D', 'Alt Koridor', 500, 870),
  MNode('BL', 'SolAlt', 170, 830), MNode('L', 'Sol Koridor', 130, 500),
  MNode('O', 'OFIS', 500, 505),
  MNode('P1', 'Depo A', 890, 330), MNode('P2', 'Depo B', 330, 890),
], [
  MEdge('TL', 'U'), MEdge('U', 'TR'), MEdge('TR', 'P1'), MEdge('P1', 'R'),
  MEdge('R', 'BR'), MEdge('BR', 'D'), MEdge('D', 'P2'), MEdge('P2', 'BL'),
  MEdge('BL', 'L'), MEdge('L', 'TL'),
  MEdge('L', 'O', 'doorL'), MEdge('R', 'O', 'doorR'), MEdge('U', 'O', 'vent'),
]);

const GameMap kMapSade = GameMap('SADE HALKA', [
  MNode('TL', 'SolUst', 170, 170), MNode('U', 'Ust Koridor', 500, 140),
  MNode('TR', 'SagUst', 830, 170), MNode('R', 'Sag Koridor', 870, 500),
  MNode('BR', 'SagAlt', 830, 830), MNode('D', 'Alt Koridor', 500, 870),
  MNode('BL', 'SolAlt', 170, 830), MNode('L', 'Sol Koridor', 130, 500),
  MNode('O', 'OFIS', 500, 505),
], [
  MEdge('TL', 'U'), MEdge('U', 'TR'), MEdge('TR', 'R'), MEdge('R', 'BR'),
  MEdge('BR', 'D'), MEdge('D', 'BL'), MEdge('BL', 'L'), MEdge('L', 'TL'),
  MEdge('L', 'O', 'doorL'), MEdge('R', 'O', 'doorR'), MEdge('U', 'O', 'vent'),
]);

const GameMap kMapGenis = GameMap('GENIS', [
  MNode('TL', 'SolUst', 170, 170), MNode('U', 'Ust Koridor', 500, 140),
  MNode('TR', 'SagUst', 830, 170), MNode('R', 'Sag Koridor', 870, 500),
  MNode('BR', 'SagAlt', 830, 830), MNode('D', 'Alt Koridor', 500, 870),
  MNode('BL', 'SolAlt', 170, 830), MNode('L', 'Sol Koridor', 130, 500),
  MNode('O', 'OFIS', 500, 505),
  MNode('P1', 'Depo A', 890, 330), MNode('P2', 'Depo B', 330, 890),
  MNode('P3', 'Depo C', 330, 110), MNode('P4', 'Depo D', 110, 665),
], [
  MEdge('TL', 'P3'), MEdge('P3', 'U'), MEdge('U', 'TR'), MEdge('TR', 'P1'),
  MEdge('P1', 'R'), MEdge('R', 'BR'), MEdge('BR', 'D'), MEdge('D', 'P2'),
  MEdge('P2', 'BL'), MEdge('BL', 'P4'), MEdge('P4', 'L'), MEdge('L', 'TL'),
  MEdge('L', 'O', 'doorL'), MEdge('R', 'O', 'doorR'), MEdge('U', 'O', 'vent'),
]);

const List<GameMap> MAPS = [kMapKlasik, kMapSade, kMapGenis];

// ============================ SES ============================
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
      final d = await Directory.systemTemp.createTemp('gecevardiyasi');
      dir = d.path;
      _wf('scream', _genScream());
      _wf('amb', _genAmb());
      _wf('slam', _genSlam());
      _wf('click', _genClick());
      _wf('chime', _genChime());
      _wf('down', _genDown());
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
      Future<void>.delayed(const Duration(milliseconds: 120), () => HapticFeedback.heavyImpact());
      Future<void>.delayed(const Duration(milliseconds: 260), () => HapticFeedback.vibrate());
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
      Future<void>.delayed(const Duration(milliseconds: 180), () {
        SystemSound.play(SystemSoundType.alert);
        HapticFeedback.heavyImpact();
      });
      Future<void>.delayed(const Duration(milliseconds: 420), () => HapticFeedback.vibrate());
      return;
    }
    for (int i = 0; i < 3; i++) {
      Future<void>.delayed(Duration(milliseconds: i * 220), () {
        _busy.remove('scream');
        play('scream');
      });
    }
  }

  static void startAmb() {
    if (_mobile) {
      if (_ambOn) return;
      _ambOn = true;
      _ambT?.cancel();
      _ambT = Timer.periodic(const Duration(milliseconds: 1700), (_) {
        if (_ambOn) HapticFeedback.lightImpact();
      });
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
      final growl = ((t * 92) % 1) > 0.5 ? 1.0 : -1.0;
      final env = m.min(1.0, t / 0.04) * m.pow(1 - p, 0.7).toDouble();
      var v = saw * 0.5 + nz * 0.35 + growl * 0.25;
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
      double v = m.sin(2 * m.pi * 46 * t) * 0.5 + m.sin(2 * m.pi * 92.4 * t) * 0.2;
      final nz = r.nextDouble() * 2 - 1;
      lp += (nz - lp) * 0.05;
      v += lp * 0.35;
      v *= 0.72 + 0.28 * m.sin(2 * m.pi * 0.09 * t);
      for (int k = 0; k < 4; k++) {
        final st = 1.0 + k * 3.8;
        if (t > st && t < st + 3.2) {
          final dt2 = t - st;
          v += m.sin(2 * m.pi * notes[k % 4] * dt2) * 0.16 * m.exp(-dt2 * 1.4);
        }
      }
      var fade = 1.0;
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
      out[i] = lp * 0.7 * m.exp(-t * 16) + m.sin(2 * m.pi * 52 * t) * m.exp(-t * 9) * 0.9;
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
        if (t > st) v += m.sin(2 * m.pi * notes[k] * (t - st)) * m.exp(-(t - st) * 2.2) * 0.35;
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
      if (Platform.isMacOS) return [
            ['afplay', p]
          ];
      if (Platform.isLinux) return [
            ['paplay', p],
            ['aplay', '-q', p]
          ];
      if (Platform.isWindows) return [
            ['powershell', '-NoProfile', '-Command', '[System.Media.SoundPlayer]::new(\'$p\').PlaySync()']
          ];
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

// ============================ VERİ ============================
class PInfo {
  final int pid;
  final InternetAddress addr;
  final int port;
  final String name;
  String sel;
  int lastSeen;
  PInfo(this.pid, this.addr, this.port, this.name, this.lastSeen) : sel = '';
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
  String? eA, eB;
  double prog = 0;
  double stun = 0;
  double cdUntil = 0;
  double buffU = 0, buffM = 1;
  double hideU = 0, ventU = 0;
  String? forcing;
  double forceT = 0;
  double waitT = 0;
  double jx = 0, jy = 0;
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
  final double x, y;
  final double stun, cd, wait;
  final bool iv, hd;
  final String nd;
  final String fc;
  VActor(this.pid, this.name, this.ch, this.x, this.y, this.stun, this.cd, this.wait, this.iv, this.hd, this.nd, this.fc);
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
  bool dl = true, dr = true, vent = true, light = false, cam = false, black = false;
  double jam = 0, fear = 0, blind = 0, waitL = 0, waitR = 0, forceL = 0, forceR = 0;
  double ddL = 0, ddR = 0;
  int thL = -1, thR = -1;
  List<VActor> actors = [];
  List<Nz> noise = [];
}

// ============================ NET + SİM + YZ ============================
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
  Timer? scanT, pingT, cliT, joinTO, simT;
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
  bool dl = true, dr = true, ventOpen = true, lightOn = false, camOn = false;
  double dlDis = 0, drDis = 0, jamU = 0, fearU = 0, blindU = 0;
  final Map<int, Actor> actors = {};
  final List<NzMark> noise = [];
  final List<String> evQ = [];
  final List<String> sfxQ = [];
  int closeL = 0, closeR = 0;
  Map<String, MNode> nodeById = {};
  Map<String, List<MEdge>> edgesByNode = {};
  Map<String, double> edgeLen = {};
  Map<String, String> edgeKind = {};
  GameMap get curMap => MAPS[mapIdx];

  Map<String, dynamic>? sCur, sPrev;
  int sCurAt = 0;

  double dlShow = 1, drShow = 1, fanA = 0;
  double shakeX = 0, shakeY = 0;
  double _jx = 0, _jy = 0;
  int tickN = 0;
  int _lastLocalDoor = 0;

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
      sock = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port, reuseAddress: true);
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
      status = 'Port acilamadi. Baska bir oda acik olabilir.';
      notifyListeners();
      return;
    }
    isHost = true;
    aiMode = false;
    hostPid = 1;
    myPid = 1;
    pidSeq = 2;
    players.clear();
    players[1] = PInfo(1, InternetAddress.loopbackIPv4, 0, myName, DateTime.now().millisecondsSinceEpoch);
    inGame = false;
    over = false;
    page = 2;
    status = 'Oda acik. Diger oyuncular LOBI ARA ile katilsin.';
    _findLocalIp();
    _startHostTimers();
    notifyListeners();
  }

  Future<void> _findLocalIp() async {
    try {
      final ifs = await NetworkInterface.list(type: InternetAddressType.IPv4);
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
      if (pl.addr.address == a.address && pl.port == p) return pl.pid;
    }
    return -1;
  }

  List<Map<String, dynamic>> _lobbyList() {
    return players.values.map((p) => {'p': p.pid, 'n': p.name, 's': p.sel, 'h': p.pid == hostPid}).toList();
  }

  void _bcastLobby() {
    _bcast({'t': 'lobby', 'players': _lobbyList(), 'map': mapIdx, 'host': hostPid});
  }

  void _hostRx(Map<String, dynamic> j, InternetAddress ad, int po) {
    final t = _s(j['t']);
    if (t == 'discover') {
      _sendTo({'t': 'hostinfo', 'hn': myName, 'mp': mapIdx, 'pc': players.length}, ad, po);
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
      players[id] = PInfo(id, ad, po, nm, DateTime.now().millisecondsSinceEpoch);
      _sendTo({'t': 'welcome', 'pid': id, 'host': hostPid, 'map': mapIdx, 'players': _lobbyList()}, ad, po);
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
        if (actors.values.where((a) => !a.isAI).isEmpty && !actors.values.any((a) => a.pid != guardPid)) {
          endGame('guard', 'Tum animatronikler gitti', -1, -1);
        }
      }
    }
    if (page == 2) _bcastLobby();
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
    scanT = Timer.periodic(const Duration(milliseconds: 1200), (_) => _sendDiscover());
    _sendDiscover();
    notifyListeners();
  }

  void _sendDiscover() {
    try {
      sock?.send(utf8.encode(jsonEncode({'t': 'discover', 'n': myName})), InternetAddress('255.255.255.255'), kPort);
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
      if (page > 0 && !isHost && hostAddr != null && now - lastHostRx > 9000) {
        _toMenu('Baglanti zaman asimi');
        return;
      }
      if (page == 3 && !over && !isHost && myRole == 'A' && hostAddr != null) {
        _sendTo({'t': 'state', 'jx': _jx, 'jy': _jy}, hostAddr!, hostPort);
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
        status = 'Yanit yok. IP dogru mu? Ayni Wi-Fi mi?';
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
        found[key] = HostInfo(_s(j['hn']), _i(j['mp']), _i(j['pc']), ad, po, DateTime.now().millisecondsSinceEpoch);
        status = '${found.length} oda bulundu';
        notifyListeners();
      }
      return;
    }
    if (hostAddr != null && (ad.address != hostAddr!.address || po != hostPort)) {
      if (t != 'err') return;
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
      _onOver(_s(j['w']), _s(j['rs']), _i(j['js']), _i(j['kp']), _i(j['sp']) == 1);
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
        rows.add(PRow(_i(p['p']), _s(p['n']), _s(p['s']), _i(p['h']) == 1));
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
      if (hostAddr != null) _sendTo({'t': 'leave'}, hostAddr!, hostPort);
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
    players[1] = PInfo(1, InternetAddress.loopbackIPv4, 0, myName, DateTime.now().millisecondsSinceEpoch);
    inGame = false;
    over = false;
    _startHostTimers();
    final chars = <int>[];
    final pool = List<int>.generate(CHARS.length, (i) => i)..shuffle(_r);
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
    simT = Timer.periodic(const Duration(milliseconds: 50), (_) => _tick());
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
      edgeLen['${e.a}|${e.b}'] = m.sqrt((na.x - nb.x) * (na.x - nb.x) + (na.y - nb.y) * (na.y - nb.y));
      edgeKind['${e.a}|${e.b}'] = e.kind;
    }
  }

  double _len(String a, String b) => edgeLen['$a|$b'] ?? edgeLen['$b|$a'] ?? 1.0;
  String _kind(String a, String b) => edgeKind['$a|$b'] ?? edgeKind['$b|$a'] ?? '';

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
    final spawns = curMap.nodes.where((n) => n.id != 'O' && n.id != 'L' && n.id != 'R' && n.id != 'U').toList()..shuffle(_r);
    int si = 0;
    roles.forEach((pidStr, info) {
      final pid = int.tryParse(pidStr) ?? -1;
      if (_s(info['r']) == 'A') {
        final nd = spawns[si % spawns.length].id;
        si++;
        final ch = _i(info['c']).clamp(0, CHARS.length - 1);
        final nm = players[pid]?.name ?? 'YZ-${CHARS[ch].name}';
        final a = Actor(pid, nm, ch, nd);
        a.isAI = pid >= 100;
        if (a.isAI) a.aiDecide = 1.0 + _r.nextDouble();
        actors[pid] = a;
      }
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
    _aiTick(dt);
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
      if (a.eB != null && ((a.eA == nid && a.eB == 'O') || (a.eA == 'O' && a.eB == nid))) {
        _slam(a);
      }
    }
  }

  void _slam(Actor a) {
    final opts = curMap.nodes.where((n) => n.id != 'O' && n.id != a.node).map((n) => n.id).toList();
    a.node = opts[_r.nextInt(opts.length)];
    a.eA = null;
    a.eB = null;
    a.prog = 0;
    a.stun = 3;
    a.forcing = null;
    a.waitT = 0;
    evQ.add('slam');
  }

  void _aiTick(double dt) {
    if (!aiMode) return;
    final aggr = [0.6, 1.0, 1.5][soloDiff.clamp(0, 2)];
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
              if (c.active == 'doorbreak' && sT >= a.cdUntil) {
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
        final far = ['BR', 'BL', 'D'].where((n) => nodeById.containsKey(n)).toList();
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
      if (a.node == 'U' && ventOpen && _r.nextDouble() < 0.4 * aggr * dt * 20) {
        _startEdge(a, 'O');
        continue;
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
      final opts = curMap.nodes.where((n) => n.id != 'O').map((n) => n.id).toList();
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
      final opts = ['L', 'R', 'U'].where((n) => nodeById.containsKey(n)).toList();
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
          final other = players.values.where((q) => q.sel == 'G' && q.pid != pid).toList();
          if (other.isNotEmpty) {
            if (pid != hostPid) _sendTo({'t': 'err', 'm': 'Guvenlik zaten secildi'}, p.addr, p.port);
            return;
          }
        }
        p.sel = s;
        if (pid == myPid) mySel = s;
        _bcastLobby();
        notifyListeners();
      } else if (k == 'map' && pid == hostPid) {
        mapIdx = _i(v).clamp(0, MAPS.length - 1);
        _bcastLobby();
        notifyListeners();
      }
      return;
    }
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
            if (a.eB != null && ((a.eA == 'U' && a.eB == 'O') || (a.eA == 'O' && a.eB == 'U'))) {
              _slam(a);
            }
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
        final opts = curMap.nodes.where((n) => n.id != 'O').map((n) => n.id).toList();
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
        final opts = ['L', 'R', 'U'].where((n) => nodeById.containsKey(n)).toList();
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
      final crossing = a.eB != null && ((a.eA == node && a.eB == 'O') || (a.eA == 'O' && a.eB == node));
      if (atDoor || crossing) {
        if (c.passive == 'lightimmune' || c.passive == 'ghost' || sT < a.hideU) continue;
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
      double x, y;
      if (a.eB != null) {
        final pa = nodeById[a.eA!]!;
        final pb = nodeById[a.eB!]!;
        x = _lp(pa.x, pb.x, a.prog);
        y = _lp(pa.y, pb.y, a.prog);
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
    double fL = 0, fR = 0;
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

  double _lp(double a, double b, double t) => a + (b - a) * t;

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
    _bcast({'t': 'over', 'w': side, 'rs': reason, 'js': js, 'kp': killer, 'sp': surprise ? 1 : 0});
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
      double x, y;
      if (a.eB != null) {
        final pa = nodeById[a.eA!]!;
        final pb = nodeById[a.eB!]!;
        x = _lp(pa.x, pb.x, a.prog);
        y = _lp(pa.y, pb.y, a.prog);
      } else {
        final n = nodeById[a.node]!;
        x = n.x;
        y = n.y;
      }
      final hidden = c.passive == 'ghost' || sT < a.hideU;
      final iv = a.eB != null && _kind(a.eA!, a.eB!) == 'vent';
      vf.actors.add(VActor(a.pid, a.name, a.char, x, y, m.max(0.0, a.stun), m.max(0.0, a.cdUntil - sT), a.waitT, iv, hidden, a.eB != null ? '${a.eA}>${a.eB}' : a.node, a.forcing ?? ''));
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
    final prevList = (sPrev != null && sPrev!['actors'] is List) ? sPrev!['actors'] as List : const [];
    for (final a in curList) {
      final pid = _i(a['i']);
      double x = _d(a['x']);
      double y = _d(a['y']);
      for (final p in prevList) {
        if (_i(p['i']) == pid) {
          x = _lp(_d(p['x']), x, alpha);
          y = _lp(_d(p['y']), y, alpha);
          break;
        }
      }
      vf.actors.add(VActor(pid, _s(a['n']), _i(a['c']), x, y, _d(a['st']), _d(a['cd']), _d(a['wt']), _i(a['iv']) == 1, _i(a['hd']) == 1, _s(a['nd']), _s(a['fc'])));
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
      if (parts.length == 2 && parts[1] == 'O' && (parts[0] == 'L' || parts[0] == 'R')) return 'SALDIR';
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
    dlShow += (((dl ? 1.0 : 0.0)) - dlShow) * m.min(1.0, dt * 10);
    drShow += (((dr ? 1.0 : 0.0)) - drShow) * m.min(1.0, dt * 10);
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

// ============================ UI ============================
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  Sfx.init();
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gece Vardiyasi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: const Color(0xFF05040A)),
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
    return Scaffold(backgroundColor: const Color(0xFF05040A), body: SafeArea(child: body));
  }
}

const TextStyle kTitle = TextStyle(fontSize: 30, fontWeight: FontWeight.w900, letterSpacing: 3, color: Color(0xFFFFB300), shadows: [Shadow(blurRadius: 12, color: Color(0x88FF6600))]);
const TextStyle kTxt = TextStyle(fontSize: 14, color: Color(0xFFCFCFE8));
const TextStyle kSmall = TextStyle(fontSize: 11, color: Color(0xFF8888AA));

class Btn extends StatelessWidget {
  final String t;
  final String sub;
  final VoidCallback? on;
  final Color c;
  final bool expand;
  const Btn({super.key, required this.t, this.sub = '', this.on, this.c = Colors.deepPurple, this.expand = true});
  @override
  Widget build(BuildContext context) {
    final w = GestureDetector(
      onTap: on,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: c.al(on == null ? 0.15 : 0.55),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: on == null ? Colors.white12 : c.al(0.9), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
            if (sub.isNotEmpty) Text(sub, style: const TextStyle(fontSize: 10, color: Color(0xFFBBBBDD))),
          ],
        ),
      ),
    );
    return expand ? Expanded(child: w) : w;
  }
}

Widget chip(String s, Color c, {bool on = false}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: c.al(on ? 0.7 : 0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: c, width: on ? 2 : 1)),
    child: Text(s, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: on ? Colors.white : c)),
  );
}

class MenuPage extends StatefulWidget {
  final Net gs;
  const MenuPage({super.key, required this.gs});
  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  final TextEditingController nameC = TextEditingController(text: 'Oyuncu');
  final TextEditingController ipC = TextEditingController();

  @override
  void dispose() {
    nameC.dispose();
    ipC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gs = widget.gs;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('GECE VARDIYASI', textAlign: TextAlign.center, style: kTitle),
            const SizedBox(height: 4),
            const Text('LAN FNAF + TEK KISILIK YZ', textAlign: TextAlign.center, style: kSmall),
            const SizedBox(height: 26),
            TextField(
              controller: nameC,
              maxLength: 14,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Adin', counterText: ''),
              onChanged: (v) => gs.myName = v.trim().isEmpty ? 'Oyuncu' : v.trim(),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7D3C98), padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () {
                gs.myName = nameC.text.trim().isEmpty ? 'Oyuncu' : nameC.text.trim();
                gs.hostGame();
              },
              child: const Text('HOST OL (ODA KUR)', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1F618D), padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () {
                gs.myName = nameC.text.trim().isEmpty ? 'Oyuncu' : nameC.text.trim();
                gs.startScan();
              },
              child: const Text('LOBI ARA', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF922B21), padding: const EdgeInsets.symmetric(vertical: 14)),
              onPressed: () {
                gs.myName = nameC.text.trim().isEmpty ? 'Oyuncu' : nameC.text.trim();
                gs.page = 5;
                gs.notifyListeners();
              },
              child: const Text('TEK KISILIK - YZ HAYATTA KALMA', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ipC,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: 'IP ile katil (192.168.x.x)', isDense: true),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF145A32)),
                  onPressed: () {
                    gs.myName = nameC.text.trim().isEmpty ? 'Oyuncu' : nameC.text.trim();
                    if (ipC.text.trim().isNotEmpty) gs.joinIp(ipC.text.trim());
                  },
                  child: const Text('KATIL'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF111122), borderRadius: BorderRadius.circular(8)),
              child: Text(gs.status, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFFCC66), fontSize: 13)),
            ),
            const SizedBox(height: 10),
            const Text('Port 41237. Ayni Wi-Fi gerekli. Yayin bulunamazsa IP ile katil.', textAlign: TextAlign.center, style: kSmall),
          ],
        ),
      ),
    );
  }
}

class ScanPage extends StatelessWidget {
  final Net gs;
  const ScanPage({super.key, required this.gs});
  @override
  Widget build(BuildContext context) {
    final hosts = gs.found.values.toList();
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFB300))),
              const SizedBox(width: 10),
              const Text('ODALAR ARANIYOR...', style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 2)),
              const Spacer(),
              Btn(t: 'GERI', on: () => gs._toMenu('Arama iptal'), expand: false, c: const Color(0xFF555577)),
            ],
          ),
          const SizedBox(height: 6),
          Text(gs.status, style: kSmall),
          const SizedBox(height: 10),
          Expanded(
            child: hosts.isEmpty
                ? const Center(child: Text('Henuz oda yok. Bir cihaz HOST OL ile oda acsin.', textAlign: TextAlign.center, style: kTxt))
                : ListView.separated(
                    itemCount: hosts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final h = hosts[i];
                      return GestureDetector(
                        onTap: () => gs.joinFound(h),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: const Color(0xFF151530), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF333366))),
                          child: Row(
                            children: [
                              const Icon(Icons.meeting_room, color: Color(0xFFFFB300)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${h.name} odasi', style: const TextStyle(fontWeight: FontWeight.w700)),
                                    Text('${h.addr.address} - ${h.count}/4 - ${MAPS[h.map.clamp(0, MAPS.length - 1)].name}', style: kSmall),
                                  ],
                                ),
                              ),
                              chip('KATIL', const Color(0xFF2ECC71), on: true),
                            ],
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

class LobbyPage extends StatelessWidget {
  final Net gs;
  const LobbyPage({super.key, required this.gs});
  @override
  Widget build(BuildContext context) {
    final isHost = gs.isHost;
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('LOBI', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2, color: Color(0xFFFFB300))),
              const Spacer(),
              Btn(t: 'CIK', on: () => gs.leaveRoom(), expand: false, c: const Color(0xFF922B21)),
            ],
          ),
          if (gs.localIp.isNotEmpty) Text('Bu cihazin IP: ${gs.localIp}', style: kSmall),
          if (gs.status.isNotEmpty) Text(gs.status, style: const TextStyle(color: Color(0xFFFFCC66), fontSize: 12)),
          const SizedBox(height: 8),
          const Text('HARITA (host secer):', style: kSmall),
          const SizedBox(height: 4),
          Row(
            children: [
              for (int i = 0; i < MAPS.length; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(onTap: isHost ? () => gs.setMap(i) : null, child: chip(MAPS[i].name, const Color(0xFF3498DB), on: gs.mapIdx == i)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          const Text('OYUNCULAR:', style: kSmall),
          const SizedBox(height: 4),
          SizedBox(
            height: 70,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final p in gs.rows)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFF151530), borderRadius: BorderRadius.circular(10), border: Border.all(color: p.sel == 'G' ? const Color(0xFFF1C40F) : const Color(0xFF333366))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('${p.host ? '*' : ''}${p.name}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        Text(p.sel == 'G' ? 'GUVERDIN' : (p.sel.startsWith('C') ? CHARS[int.tryParse(p.sel.substring(1)) ?? 0].name : 'secim yok'), style: const TextStyle(fontSize: 11, color: Color(0xFF9999CC))),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text('KARAKTER SEC (ilk kutu = GUVERDIN):', style: kSmall),
          const SizedBox(height: 6),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  GestureDetector(
                    onTap: () => gs.pick('G'),
                    child: Container(
                      width: 96,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4D3800).al(0.8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: gs.mySel == 'G' ? const Color(0xFFF1C40F) : const Color(0xFF555522), width: gs.mySel == 'G' ? 3 : 1),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 58, child: Center(child: Icon(Icons.security, size: 44, color: Color(0xFFF1C40F)))),
                          const Text('GUVERDIN', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFFF1C40F))),
                          Text(gs.rows.any((r) => r.sel == 'G') && gs.mySel != 'G' ? 'dolu' : 'sen ol', style: const TextStyle(fontSize: 9, color: Color(0xFFAA9955))),
                        ],
                      ),
                    ),
                  ),
                  for (int i = 0; i < CHARS.length; i++)
                    GestureDetector(
                      onTap: () => gs.pick('C$i'),
                      child: Container(
                        width: 96,
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF12122A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: gs.mySel == 'C$i' ? CHARS[i].color : const Color(0xFF333355), width: gs.mySel == 'C$i' ? 3 : 1),
                        ),
                        child: Column(
                          children: [
                            SizedBox(height: 58, child: CustomPaint(size: const Size(90, 58), painter: AnimPrev(ch: i))),
                            Text(CHARS[i].name, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: CHARS[i].color)),
                            Text('${CHARS[i].active}/${CHARS[i].passive}', style: const TextStyle(fontSize: 9, color: Color(0xFF8888AA))),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          if (isHost)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: gs.rows.length >= 2 ? const Color(0xFF1E8449) : const Color(0xFF333344),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: gs.rows.length >= 2 ? () => gs.startGame() : null,
              child: Text('OYUNU BASLAT (${gs.rows.length}/4) - min 2 kisi', style: const TextStyle(fontWeight: FontWeight.w900)),
            )
          else
            const Text('Hostun baslatmasi bekleniyor...', textAlign: TextAlign.center, style: kTxt),
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
    final diffs = ['KOLAY', 'NORMAL', 'KABUS'];
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('TEK KISILIK YZ', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2, color: Color(0xFFFFB300))),
              const Spacer(),
              Btn(t: 'GERI', on: () => gs._toMenu('Hazir'), expand: false, c: const Color(0xFF555577)),
            ],
          ),
          const SizedBox(height: 8),
          const Text('Sen guvenlik sin. YZ animatronikler seni avlar. Sabah 6 ya kadar hayatta kal.', style: kTxt),
          const SizedBox(height: 16),
          const Text('ZORLUK:', style: kSmall),
          const SizedBox(height: 6),
          Row(
            children: [
              for (int i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      gs.soloDiff = i;
                      gs.notifyListeners();
                    },
                    child: chip(diffs[i], const Color(0xFFE74C3C), on: gs.soloDiff == i),
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
                    onTap: () {
                      gs.soloCount = i;
                      gs.notifyListeners();
                    },
                    child: chip('$i', const Color(0xFF8E44AD), on: gs.soloCount == i),
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
                    onTap: () {
                      gs.mapIdx = i;
                      gs.notifyListeners();
                    },
                    child: chip(MAPS[i].name, const Color(0xFF3498DB), on: gs.mapIdx == i),
                  ),
                ),
            ],
          ),
          const Spacer(),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E8449), padding: const EdgeInsets.symmetric(vertical: 16)),
            onPressed: () => gs.startSolo(),
            child: const Text('GECEYE BASLA', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
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

class _GamePageState extends State<GamePage> with SingleTickerProviderStateMixin {
  late AnimationController c;
  Duration? lastD;

  @override
  void initState() {
    super.initState();
    c = AnimationController(vsync: this)..repeat();
    c.addListener(_tick);
  }

  void _tick() {
    final d = c.lastElapsedDuration;
    final dt = lastD == null ? 0.016 : m.min(0.05, (d - lastD!).inMicroseconds / 1000000);
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
                child: gs.myRole == 'G' ? _buildGuard(gs, vf, now) : _buildAnim(gs, vf, now),
              ),
            ),
            if (vf.blind > 0) Positioned.fill(child: Container(color: Colors.white.al(m.min(0.85, vf.blind)))),
            if (gs.jsOn) Positioned.fill(child: JsOverlay(ch: gs.overJs, t: gs.jsT))
            else if (gs.over)
              Positioned.fill(child: Container(color: (gs.overSide == 'anim' ? const Color(0xFFFF2200) : const Color(0xFF22FF88)).al(0.12 + 0.1 * m.sin(gs.endDelay * 12).abs()))),
          ],
        );
      },
    );
  }

  Widget _buildGuard(Net gs, VF vf, int now) {
    final jammed = vf.cam && vf.jam > 0;
    return Stack(
      children: [
        Positioned.fill(
          child: vf.cam && !vf.black
              ? CustomPaint(painter: MapP(map: gs.curMap, vf: vf, camMode: true, myPid: gs.myPid, t: vf.t, jam: jammed))
              : CustomPaint(painter: OfficeP(vf: vf, dlShow: gs.dlShow, drShow: gs.drShow, fanA: gs.fanA, t: now / 1000)),
        ),
        Positioned.fill(child: CustomPaint(painter: NoiseP(seed: now ~/ 60, heavy: vf.cam, jam: jammed))),
        Positioned.fill(child: const CustomPaint(painter: VignetteP())),
        Positioned(
          top: 8,
          left: 10,
          right: 10,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(kHours[vf.hour.clamp(0, 6)], style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white, shadows: [Shadow(blurRadius: 6, color: Colors.black)])),
                  Text(vf.black ? 'KARANLIK!' : 'GECE VARDIYASI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: vf.black ? Colors.red : const Color(0xFFAAAAEE))),
                ],
              ),
              const Spacer(),
              if (vf.cam)
                Row(
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: (vf.t % 1 < 0.6) ? Colors.red : Colors.transparent, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    const Text('REC', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 12)),
                  ],
                ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('GUC %${vf.power.toInt()}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: vf.power < 25 ? Colors.red : const Color(0xFF7CFC00))),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0; i < 6; i++)
                        Container(
                          width: 7,
                          height: 13,
                          margin: const EdgeInsets.only(left: 2),
                          color: i < vf.usage ? (vf.usage >= 5 ? Colors.red : vf.usage >= 3 ? Colors.orange : Colors.green) : const Color(0xFF222233),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        if (vf.forceL > 0 || vf.waitL > 1.5)
          Positioned(top: 66, left: 0, right: 0, child: Center(child: Text('SOL KAPI ${vf.forceL > 0 ? 'ZORLANIYOR!' : 'TEHLIKE!'}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.red.al(0.6 + 0.4 * m.sin(now / 90))))),
        if (vf.forceR > 0 || vf.waitR > 1.5)
          Positioned(top: 86, left: 0, right: 0, child: Center(child: Text('SAG KAPI ${vf.forceR > 0 ? 'ZORLANIYOR!' : 'TEHLIKE!'}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Colors.red.al(0.6 + 0.4 * m.sin(now / 90))))),
        if (vf.black) const Positioned(top: 120, left: 0, right: 0, child: Center(child: Text('GUC BITTI - KONTROLLER KILITLENDI', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2))),
        if (jammed) const Positioned(top: 150, left: 0, right: 0, child: Center(child: Text('SINYAL YOK', style: TextStyle(color: Color(0xFF66FF66), fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 4))),
        Positioned(
          bottom: 8,
          left: 8,
          right: 8,
          child: Row(
            children: [
              Btn(t: 'SOL KAPI', sub: vf.ddL > 0 ? 'KILIT ${vf.ddL.toStringAsFixed(1)}' : (vf.dl ? 'ACIK' : 'KAPALI'), c: vf.dl ? const Color(0xFF1E8449) : const Color(0xFF922B21), on: vf.black || vf.ddL > 0 ? null : () => gs.gAct('dl')),
              const SizedBox(width: 6),
              Btn(t: 'ISIK', sub: vf.light ? 'ACIK' : 'KAPALI', c: const Color(0xFFB7950B), on: vf.black ? null : () => gs.gAct('li')),
              const SizedBox(width: 6),
              Btn(t: 'KAMERA', sub: vf.cam ? 'ACIK' : 'KAPALI', c: const Color(0xFF1F618D), on: vf.black || (vf.jam > 0 && !vf.cam) ? null : () => gs.gAct('cm')),
              const SizedBox(width: 6),
              Btn(t: 'VENT', sub: vf.vent ? 'ACIK' : 'KAPALI', c: const Color(0xFF148F77), on: vf.black ? null : () => gs.gAct('vt')),
              const SizedBox(width: 6),
              Btn(t: 'SAG KAPI', sub: vf.ddR > 0 ? 'KILIT ${vf.ddR.toStringAsFixed(1)}' : (vf.dr ? 'ACIK' : 'KAPALI'), c: vf.dr ? const Color(0xFF1E8449) : const Color(0xFF922B21), on: vf.black || vf.ddR > 0 ? null : () => gs.gAct('dr')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnim(Net gs, VF vf, int now) {
    VActor? me;
    for (final a in vf.actors) {
      if (a.pid == gs.myPid) {
        me = a;
        break;
      }
    }
    final ctx = gs.ctxLabel(vf);
    final cd = me?.cd ?? 0.0;
    final cdMax = CHARS[gs.myChar.clamp(0, CHARS.length - 1)].cd;
    return Stack(
      children: [
        Positioned.fill(child: CustomPaint(painter: MapP(map: gs.curMap, vf: vf, camMode: false, myPid: gs.myPid, t: vf.t, jam: false))),
        Positioned.fill(child: CustomPaint(painter: NoiseP(seed: now ~/ 90, heavy: false, jam: false))),
        Positioned.fill(child: const CustomPaint(painter: VignetteP())),
        Positioned(
          top: 8,
          left: 10,
          right: 10,
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(kHours[vf.hour.clamp(0, 6)], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                  Text(CHARS[gs.myChar.clamp(0, CHARS.length - 1)].name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: CHARS[gs.myChar.clamp(0, CHARS.length - 1)].color)),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('GUC %${vf.power.toInt()}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: vf.power < 25 ? Colors.red : const Color(0xFF7CFC00))),
                  Text('SOL:${vf.dl ? 'ACIK' : 'KAPALI'} SAG:${vf.dr ? 'ACIK' : 'KAPALI'} VENT:${vf.vent ? 'ACIK' : 'KAPALI'}', style: const TextStyle(fontSize: 10, color: Color(0xFFAAAADD))),
                ],
              ),
            ],
          ),
        ),
        if (me != null && me.stun > 0)
          Positioned(top: 0, bottom: 0, left: 0, right: 0, child: Center(child: Text('SERSEMLEDIN ${me.stun.toStringAsFixed(1)} sn', style: const TextStyle(color: Color(0xFFFFEE55), fontSize: 24, fontWeight: FontWeight.w900, shadows: [Shadow(blurRadius: 10, color: Colors.black)]))),
        Positioned(bottom: 20, left: 16, child: Joy(onVec: gs.sendJoy)),
        Positioned(
          bottom: 24,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (ctx != null)
                GestureDetector(
                  onTap: gs.doCtx,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                    decoration: BoxDecoration(color: const Color(0xFFC0392B).al(0.85), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white54, width: 2)),
                    child: Text(ctx, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                  ),
                ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: cd <= 0 ? gs.useAbility : null,
                child: SizedBox(
                  width: 86,
                  height: 86,
                  child: Stack(
                    children: [
                      Positioned.fill(child: Container(decoration: BoxDecoration(shape: BoxShape.circle, color: CHARS[gs.myChar.clamp(0, CHARS.length - 1)].color.al(cd > 0 ? 0.2 : 0.75), border: Border.all(color: CHARS[gs.myChar.clamp(0, CHARS.length - 1)].color, width: 2)))),
                      Positioned.fill(child: CustomPaint(painter: ArcP(frac: cdMax > 0 ? cd / cdMax : 0, col: Colors.black.al(0.65)))),
                      Center(child: Text(CHARS[gs.myChar.clamp(0, CHARS.length - 1)].active, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.white))),
                      if (cd > 0) Positioned(bottom: 14, left: 0, right: 0, child: Center(child: Text(cd.toStringAsFixed(0), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white70)))),
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

class _EndPageState extends State<EndPage> with SingleTickerProviderStateMixin {
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
        if (Sfx._mobile) HapticFeedback.vibrate();
      }
    }
    if (surpriseOn) {
      surpriseT += 0.016;
      if (surpriseT > 1.8) {
        surpriseOn = false;
      }
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
    final won = (gs.myRole == 'G' && gs.overSide == 'guard') || (gs.myRole == 'A' && gs.overSide == 'anim');
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
                    if (gs.overJs >= 0) SizedBox(height: 170, width: 170, child: CustomPaint(painter: AnimPrev(ch: gs.overJs))),
                    const SizedBox(height: 10),
                    Text(won ? 'KAZANDIN!' : 'YAKALANDIN!', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: 4, color: won ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C))),
                    const SizedBox(height: 10),
                    Text(gs.overReason, textAlign: TextAlign.center, style: kTxt),
                    const SizedBox(height: 8),
                    Text(gs.myRole == 'G' ? 'Rol: GUVERDIN' : 'Rol: ${CHARS[gs.myChar.clamp(0, CHARS.length - 1)].name}', style: kSmall),
                    if (gs.surprise && surpriseFired) const Padding(padding: EdgeInsets.only(top: 10), child: Text('SENI GORUYORUZ...', style: TextStyle(color: Color(0xFFFF3333), fontWeight: FontWeight.w900, letterSpacing: 3))),
                    const SizedBox(height: 26),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (gs.isHost && !gs.aiMode) Btn(t: 'LOBIYE DON', sub: 'revans', on: () => gs.toLobbyAll(), expand: false, c: const Color(0xFF1F618D)),
                        if (gs.isHost && !gs.aiMode) const SizedBox(width: 10),
                        Btn(t: 'ANA MENU', on: () => gs.leaveRoom(), expand: false, c: const Color(0xFF555577)),
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
                      Positioned.fill(child: CustomPaint(painter: NoiseP(seed: (surpriseT * 60).toInt(), heavy: true, jam: true))),
                      Center(
                        child: Transform.scale(
                          scale: 0.6 + surpriseT * 1.4,
                          child: CustomPaint(size: const Size(300, 300), painter: AnimPrev(ch: gs._r.nextInt(CHARS.length))),
                        ),
                      ),
                      Positioned.fill(child: Container(color: Colors.red.al(0.25 + 0.2 * m.sin(surpriseT * 40).abs()))),
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
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFFF0000).al(pulse));
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

// ============================ ÇİZİM ============================
void drawAnimatronic(Canvas canvas, Offset o, double s, int ch, double t, {bool dark = false, bool scream = false}) {
  final cd = CHARS[ch.clamp(0, CHARS.length - 1)];
  Color body = dark ? const Color(0xFF0A0A10) : cd.color;
  Color body2 = dark ? const Color(0xFF0A0A10) : Color.lerp(cd.color, Colors.black, 0.35)!;
  Color eye = dark ? const Color(0xFFFFFFFF) : const Color(0xFFEAF7FF);
  if (ch == 5) eye = const Color(0xFFFFF6B0);
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
      canvas.drawOval(Rect.fromCircle(center: Offset(o.dx + (i - 1) * s * 0.16, o.dy + s * (0.52 + i * 0.05)), width: s * 0.3, height: s * 0.16), Paint()..color = body.al(0.25 - i * 0.06));
    }
  }
  canvas.drawOval(Rect.fromCenter(center: Offset(o.dx, o.dy + s * 0.32), width: s * 0.6, height: s * 0.52), Paint()..color = body2);
  canvas.drawOval(Rect.fromCenter(center: Offset(o.dx, o.dy + s * 0.34), width: s * 0.34, height: s * 0.3), Paint()..color = (dark ? const Color(0xFF0A0A10) : Color.lerp(cd.color, Colors.white, 0.25)!));
  if (ch == 2) {
    for (final dir in [-1.0, 1.0]) {
      canvas.drawCircle(Offset(o.dx + dir * s * 0.26, o.dy - s * 0.42), s * 0.16, Paint()..color = body);
      canvas.drawCircle(Offset(o.dx + dir * s * 0.26, o.dy - s * 0.42), s * 0.08, Paint()..color = dark ? const Color(0xFF0A0A10) : const Color(0xFFE8A0B4));
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
    canvas.drawArc(Rect.fromCenter(center: Offset(o.dx, o.dy - s * 0.34), width: s * 0.5, height: s * 0.4), m.pi * 0.95, m.pi * 1.1, false, Paint()..style = PaintingStyle.stroke..strokeWidth = s * 0.09..color = dark ? const Color(0xFF0A0A10) : const Color(0xFF641E16));
    canvas.drawCircle(Offset(o.dx + s * 0.05, o.dy - s * 0.52), s * 0.07, Paint()..color = Colors.white.al(dark ? 0.4 : 1));
  }
  canvas.drawOval(Rect.fromCenter(center: Offset(o.dx, o.dy - s * 0.16), width: s * 0.56, height: s * 0.5), Paint()..color = body);
  if (ch == 4) {
    canvas.drawLine(Offset(o.dx, o.dy - s * 0.4), Offset(o.dx, o.dy - s * 0.62), Paint()..color = body2..strokeWidth = s * 0.03);
    final blink = (t % 0.8) < 0.4;
    canvas.drawCircle(Offset(o.dx, o.dy - s * 0.64), s * 0.045, Paint()..color = blink ? const Color(0xFF2ECC71) : const Color(0xFF145A32)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
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
      canvas.drawPath(Path()..moveTo(tx - s * 0.02, o.dy - s * 0.02 - s * mouthH / 2)..lineTo(tx + s * 0.02, o.dy - s * 0.02 - s * mouthH / 2)..lineTo(tx, o.dy - s * 0.02 - s * mouthH / 2 + s * 0.05)..close(), Paint()..color = const Color(0xFFE8E8E8));
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
  final double dlShow, drShow, fanA, t;
  OfficeP({required this.vf, required this.dlShow, required this.drShow, required this.fanA, required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final horizon = h * 0.62;
    final r = m.Random((t * 20).toInt());
    canvas.drawRect(Rect.fromLTWH(0, 0, w, horizon), Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1B1030), Color(0xFF0C0716)]).createShader(Rect.fromLTWH(0, 0, w, horizon)));
    canvas.drawRect(Rect.fromLTWH(0, horizon, w, h - horizon), Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF171021), Color(0xFF040207)]).createShader(Rect.fromLTWH(0, horizon, w, h - horizon)));
    final tile = Paint()..color = Colors.white.al(0.03)..strokeWidth = 1;
    for (int i = 1; i < 12; i++) {
      canvas.drawLine(Offset(w * i / 12, 0), Offset(w * i / 12, horizon), tile);
    }
    final flick = vf.black ? 0.0 : (0.8 + 0.15 * m.sin(t * 13) + 0.05 * r.nextDouble());
    final lampX = w * 0.5;
    canvas.drawLine(Offset(lampX, 0), Offset(lampX, h * 0.07), Paint()..color = const Color(0xFF333344)..strokeWidth = 3);
    if (!vf.black) {
      final cone = Path()
        ..moveTo(lampX - w * 0.03, h * 0.075)
        ..lineTo(lampX + w * 0.03, h * 0.075)
        ..lineTo(lampX + w * 0.22, h * 0.95)
        ..lineTo(lampX - w * 0.22, h * 0.95)
        ..close();
      canvas.drawPath(cone, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFFFFE9A0).al(0.10 * flick), const Color(0xFFFFE9A0).al(0.0)]).createShader(Rect.fromLTWH(0, 0, w, h)));
      canvas.drawOval(Rect.fromCenter(center: Offset(lampX, h * 0.078), width: w * 0.05, height: h * 0.014), Paint()..color = const Color(0xFFFFE9A0).al(0.9 * flick)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    }
    _poster(canvas, Rect.fromLTWH(w * 0.205, h * 0.14, w * 0.1, h * 0.17), 0);
    _poster(canvas, Rect.fromLTWH(w * 0.695, h * 0.14, w * 0.1, h * 0.17), 11);
    _doorway(canvas, size, true, 1 - dlShow, vf);
    _doorway(canvas, size, false, 1 - drShow, vf);
    final deskTop = h * 0.8;
    final desk = Path()
      ..moveTo(w * 0.28, h * 0.99)
      ..lineTo(w * 0.36, deskTop)
      ..lineTo(w * 0.64, deskTop)
      ..lineTo(w * 0.72, h * 0.99)
      ..close();
    canvas.drawPath(desk, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF3A2A1C), Color(0xFF1D130B)]).createShader(Rect.fromLTWH(0, deskTop, w, h * 0.2)));
    final monW = w * 0.15;
    final monR = Rect.fromCenter(center: Offset(w * 0.44, h * 0.7), width: monW, height: h * 0.15);
    canvas.drawRRect(RRect.fromRectAndRadius(monR.inflate(4), const Radius.circular(6)), Paint()..color = const Color(0xFF14141E));
    canvas.drawRRect(RRect.fromRectAndRadius(monR, const Radius.circular(4)), Paint()..color = vf.black ? const Color(0xFF050508) : const Color(0xFF062511));
    if (!vf.black) {
      for (int i = 0; i < 8; i++) {
        canvas.drawLine(Offset(monR.left + 4, monR.top + 6 + i * (monR.height - 12) / 8), Offset(monR.right - 4, monR.top + 6 + i * (monR.height - 12) / 8), Paint()..color = const Color(0xFF1DFF6E).al(0.14));
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
      canvas.drawOval(Rect.fromCenter(center: Offset(fr * 0.45, 0), width: fr * 0.85, height: fr * 0.3), Paint()..color = const Color(0xFF8899AA).al(vf.black ? 0.25 : 0.8));
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
            canvas.drawCircle(Offset(ex + d2 * w * 0.012, h * 0.45), 3, Paint()..color = Colors.white.al(0.8)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
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
    for (final d2 in [-1.0, 1.0]) {
      canvas.drawCircle(Offset(c.dx + d2 * s * 0.14, c.dy - s * 0.05), s * 0.06, Paint()..color = Colors.white);
    }
  }

  void _doorway(Canvas canvas, Size size, bool left, double closedFrac, VF vf) {
    final w = size.width;
    final h = size.height;
    final opW = w * 0.145;
    final opH = h * 0.6;
    final x0 = left ? w * 0.03 : w - w * 0.03 - opW;
    final op = Rect.fromLTWH(x0, h * 0.16, opW, opH);
    canvas.drawRect(op.inflate(6), Paint()..color = const Color(0xFF2A2438));
    canvas.drawRect(op, Paint()..shader = const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF02020A), Color(0xFF000000)]).createShader(op));
    final threat = left ? vf.thL : vf.thR;
    final wait = left ? vf.waitL : vf.waitR;
    if (vf.light && !vf.black) {
      canvas.drawRect(op, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [const Color(0xFFFFE9A0).al(0.02), const Color(0xFFFFE9A0).al(0.2)]).createShader(op));
      if (threat >= 0) {
        drawAnimatronic(canvas, Offset(op.center.dx, op.bottom - opH * 0.32), opH * 0.62, threat, t, dark: true);
      }
    }
    if (wait > 0.5 && closedFrac < 0.5) {
      final a = (wait / 5).clamp(0.0, 1.0) * (0.35 + 0.3 * m.sin(t * 8).abs());
      canvas.drawRect(op.inflate(5), Paint()..style = PaintingStyle.stroke..strokeWidth = 4..color = Colors.red.al(a));
    }
    if (closedFrac > 0.02) {
      final ph = opH * closedFrac;
      final panel = Rect.fromLTWH(op.left, op.top, opW, ph);
      canvas.drawRect(panel, Paint()..shader = const LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Color(0xFF39424F), Color(0xFF697786), Color(0xFF39424F)]).createShader(panel));
      for (int i = 0; i < 6; i++) {
        canvas.drawLine(Offset(op.left, op.top + ph * i / 6), Offset(op.right, op.top + ph * i / 6), Paint()..color = Colors.black.al(0.25)..strokeWidth = 1.5);
      }
      final by = op.top + ph;
      const seg = 12.0;
      for (double sx = op.left; sx < op.right; sx += seg) {
        final idx = ((sx - op.left) / seg).toInt();
        canvas.drawRect(Rect.fromLTWH(sx, by - 8, m.min(seg, op.right - sx), 8), Paint()..color = idx.isEven ? const Color(0xFFE8B93C) : const Color(0xFF141414));
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
  final int myPid;
  final double t;
  MapP({required this.map, required this.vf, required this.camMode, required this.myPid, required this.t, required this.jam});

  Offset sc(Offset c, Offset p, double s) => c + Offset((p.dx - 500) * s, (p.dy - 500) * s);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = camMode ? const Color(0xFF020A06) : const Color(0xFF070711));
    final s = m.min(size.width, size.height) / 1000 * 0.92;
    final c = Offset(size.width / 2, size.height / 2);
    final pos = <String, Offset>{for (final n in map.nodes) n.id: sc(c, Offset(n.x, n.y), s)};
    final corridor = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 86 * s
      ..strokeCap = StrokeCap.round
      ..color = camMode ? const Color(0xFF0A2617) : const Color(0xFF161B2C);
    final corridorIn = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 62 * s
      ..strokeCap = StrokeCap.round
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
      canvas.drawLine(doorMid - pl * 34 * s, doorMid + pl * 34 * s, Paint()..color = open ? const Color(0xFF7CFC00) : const Color(0xFFFF4C4C)..strokeWidth = 7 * s);
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
      final p = pos[z.o];
      if (p == null) continue;
      final pl = (0.6 + 0.4 * m.sin(t * 6)).clamp(0.0, 1.0);
      canvas.drawCircle(p, 26 * s * (0.8 + 0.3 * pl), Paint()..color = const Color(0xFFF1C40F).al(0.25 * pl));
    }
    if (!jam) {
      for (final a in vf.actors) {
        if (camMode && (a.hd || a.iv)) continue;
        final p = sc(c, Offset(a.x, a.y), s);
        final col = CHARS[a.ch.clamp(0, CHARS.length - 1)].color;
        canvas.drawCircle(p, 20 * s, Paint()..color = col.al(0.5)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
        canvas.drawCircle(p, 14 * s, Paint()..color = col);
        canvas.drawCircle(p, 14 * s, Paint()..style = PaintingStyle.stroke..strokeWidth = 2..color = Colors.white.al(0.7));
        if (a.pid == myPid) {
          canvas.drawCircle(p, 22 * s, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.5..color = Colors.white);
        }
        if (a.stun > 0) {
          final rr = 24 * s;
          for (int i = 0; i < 3; i++) {
            final ang = t * 4 + i * 2 * m.pi / 3;
            canvas.drawCircle(p + Offset(m.cos(ang), m.sin(ang)) * rr, 3.5, Paint()..color = const Color(0xFFFFEE55));
          }
        }
        if (a.wait > 0.3) {
          canvas.drawArc(Rect.fromCircle(center: p, radius: 26 * s), -m.pi / 2, (a.wait / 5).clamp(0.0, 1.0) * 2 * m.pi, false, Paint()..style = PaintingStyle.stroke..strokeWidth = 4..color = Colors.red.al(0.9));
        }
      }
    }
    if (camMode) {
      canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF00FF66).al(0.05));
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
      canvas.drawRect(Rect.fromLTWH(r.nextDouble() * size.width, r.nextDouble() * size.height, r.nextDouble() * 2.2 + 0.6, r.nextDouble() < 0.12 ? 2 : 1), white);
    }
    final scan = Paint()..color = Colors.black.al(jam ? 0.16 : 0.06);
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), scan);
    }
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
    canvas.drawRect(Offset.zero & size, Paint()..shader = RadialGradient(colors: [Colors.transparent, Colors.black.al(0.55), Colors.black.al(0.85)], stops: const [0.55, 0.85, 1.0]).createShader(r2));
  }

  @override
  bool shouldRepaint(VignetteP old) => false;
}
