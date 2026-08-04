import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';

void main() => runApp(const GameApp());

class GameApp extends StatelessWidget {
  const GameApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Darkescas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: false),
      home: const GameScreen(),
    );
  }
}

// ============================= GRAFİK KALİTESİ =============================
enum Quality { low, medium, high }

class GQ {
  bool glow = false;
  bool darkness = false;
  bool fog = false;
  bool vignette = false;
  bool noise = false;
  bool shake = false;
  bool gradFloor = false;
  int particleCap = 0;
  double darkAlpha = 0.0;

  static GQ of(Quality q) {
    if (q == Quality.low) return GQ();
    if (q == Quality.medium) {
      return GQ()
        ..glow = true
        ..darkness = true
        ..vignette = true
        ..noise = true
        ..gradFloor = true
        ..particleCap = 50
        ..darkAlpha = 0.55;
    }
    return GQ()
      ..glow = true
      ..darkness = true
      ..fog = true
      ..vignette = true
      ..noise = true
      ..shake = true
      ..gradFloor = true
      ..particleCap = 140
      ..darkAlpha = 0.72;
  }
}

// ============================= MODELLER =============================
class Endpoint {
  final InternetAddress address;
  final int port;
  Endpoint(this.address, this.port);
}

class PlayerNet {
  final int id;
  String name;
  int charId;
  int role;
  double x, y;
  bool moving, insideOffice, alive;
  int roomId;
  double lastSeen;
  double cooldownUntil, boostUntil, silentUntil, lightUntil, ventProgress;
  int entrySide;
  PlayerNet({
    required this.id,
    required this.name,
    this.charId = -1,
    this.role = -1,
    this.x = 0,
    this.y = 0,
    this.moving = false,
    this.insideOffice = false,
    this.alive = true,
    this.roomId = -1,
    this.lastSeen = 0,
    this.cooldownUntil = 0,
    this.boostUntil = 0,
    this.silentUntil = 0,
    this.lightUntil = 0,
    this.ventProgress = 0,
    this.entrySide = 0,
  });
}

class AiNet {
  final int id;
  final int charId;
  double x, y, tx, ty;
  int roomId;
  double speed, nextThink;
  bool moving;
  AiNet({required this.id, required this.charId, required this.x, required this.y, this.roomId = 0, this.speed = 1.0})
      : tx = x,
        ty = y,
        nextThink = 0,
        moving = false;
}

class EntityView {
  final int id, charId, role, room;
  final double x, y;
  final bool moving, hidden, inside;
  final Color color;
  EntityView({
    required this.id,
    required this.charId,
    required this.role,
    required this.x,
    required this.y,
    required this.room,
    required this.moving,
    required this.hidden,
    required this.inside,
    required this.color,
  });
}

class Room {
  final String name;
  final Rect rect;
  Room(this.name, this.rect);
}

class MapDef {
  final String name;
  final Rect office;
  final Offset leftDoor, rightDoor, vent, insideLeft, insideRight, insideVent;
  final List<Room> rooms;
  MapDef({
    required this.name,
    required this.office,
    required this.leftDoor,
    required this.rightDoor,
    required this.vent,
    required this.insideLeft,
    required this.insideRight,
    required this.insideVent,
    required this.rooms,
  });
}

class CharDef {
  final String name;
  final Color color;
  final double speed, cooldown;
  final String active, passive;
  CharDef({
    required this.name,
    required this.color,
    required this.speed,
    required this.cooldown,
    required this.active,
    required this.passive,
  });
}

class DiscoveredHost {
  final String addr;
  final int port;
  String session;
  int count, map;
  double last;
  DiscoveredHost({required this.addr, required this.port, required this.session, required this.count, required this.map, required this.last});
}

class Particle {
  double x, y, vx, vy, life, maxLife, size;
  Color color;
  Particle({required this.x, required this.y, required this.vx, required this.vy, required this.life, required this.size, required this.color})
      : maxLife = life;
}

// ============================= ANA EKRAN =============================
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});
  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  static const int netPort = 47777;
  static const double nightDuration = 240.0;
  static const int maxPlayers = 4;

  final Random rnd = Random();
  final TextEditingController ipCtrl = TextEditingController();
  Ticker? _ticker;
  final ValueNotifier<int> _frame = ValueNotifier<int>(0);
  double _hudAccum = 0;

  Quality quality = Quality.medium;
  late GQ q = GQ.of(quality);
  bool _particlesOn = true;
  bool _showSettings = false;

  int page = 0;
  bool isHost = false;
  int myId = -1, guardId = -1, myRole = -1, myChar = -1, currentMap = 0;
  String myName = "", status = "", endMsg = "";

  RawDatagramSocket? sock;
  InternetAddress? hostAddr;
  int hostPort = netPort;
  final Map<int, Endpoint> endpoints = {};
  final List<PlayerNet> players = [];
  final List<AiNet> ais = [];
  final List<DiscoveredHost> discovered = [];
  final Map<int, EntityView> remote = {};

  late List<CharDef> chars;
  MapDef? activeMap;

  Timer? slowTimer;
  double lastDiscovery = 0, lastPing = 0, lastHostPacket = 0, lastLobby = 0, lastStateSend = 0, lastSnap = 0;

  double gameTime = 0, energy = 100;
  bool leftDoorClosed = true, rightDoorClosed = true, flashOn = false, camOn = false, blackout = false;
  int winner = 0;
  double forcedL = 0, forcedR = 0, dmgL = 0, dmgR = 0, camJam = 0, ctrlLock = 0;
  int noiseRoom = -1;
  double noiseUntil = 0;

  Offset localPos = Offset.zero;
  bool localMoving = false, myInside = false, myBoost = false;
  double myCooldown = 0;
  Offset joyThumb = Offset.zero;
  double joyX = 0, joyY = 0;
  int selectedCamRoom = 0;

  final List<Particle> particles = [];
  double shake = 0;
  double jumpscare = 0;

  @override
  void initState() {
    super.initState();
    myName = "Oyuncu ${rnd.nextInt(900) + 100}";
    chars = makeChars();
    slowTimer = Timer.periodic(const Duration(seconds: 1), slowTick);
  }

  @override
  void dispose() {
    _ticker?.dispose();
    slowTimer?.cancel();
    try { sock?.close(); } catch (_) {}
    ipCtrl.dispose();
    super.dispose();
  }

  void ui() {
    if (mounted) setState(() {});
  }

  double nowSec() => DateTime.now().millisecondsSinceEpoch / 1000.0;

  void setQuality(Quality v) {
    quality = v;
    q = GQ.of(v);
    ui();
  }

  // ============================= AĞ =============================
  Future<bool> startHostSocket() async {
    _closeNet();
    try {
      sock = await RawDatagramSocket.bind(InternetAddress.anyIPv4, netPort);
      sock!.broadcastEnabled = true;
      sock!.listen(_onSock);
      return true;
    } catch (e) {
      status = "Host hatası: $e";
      return false;
    }
  }

  Future<bool> startClientSocket() async {
    _closeNet();
    try {
      sock = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      sock!.broadcastEnabled = true;
      sock!.listen(_onSock);
      return true;
    } catch (e) {
      status = "Socket hatası: $e";
      return false;
    }
  }

  void _closeNet() {
    try { sock?.close(); } catch (_) {}
    sock = null;
  }

  void _onSock(RawSocketEvent e) {
    if (e != RawSocketEvent.read) return;
    Datagram? dg = sock?.receive();
    if (dg == null) return;
    try {
      dynamic dec = jsonDecode(utf8.decode(dg.data));
      if (dec is! Map) return;
      Map<String, dynamic> m = dec.cast<String, dynamic>();
      Map<String, dynamic> p = m["p"] is Map ? (m["p"] as Map).cast<String, dynamic>() : {};
      if (isHost) {
        _hostPacket(gs(m["t"]), p, dg);
      } else {
        _clientPacket(gs(m["t"]), p, dg);
      }
    } catch (_) {}
  }

  void _send(Map<String, dynamic> d, InternetAddress a, int port) {
    try { sock?.send(utf8.encode(jsonEncode(d)), a, port); } catch (_) {}
  }

  void _toHost(Map<String, dynamic> d) {
    if (hostAddr != null) _send(d, hostAddr!, hostPort);
  }

  void _toAll(Map<String, dynamic> d) {
    if (!isHost) return;
    for (var e in endpoints.values) _send(d, e.address, e.port);
  }

  int _epId(InternetAddress a, int port) {
    for (var e in endpoints.entries) {
      if (e.value.address.address == a.address && e.value.port == port) return e.key;
    }
    return -1;
  }

  void _hostPacket(String t, Map<String, dynamic> p, Datagram dg) {
    if (t == "discover") {
      if (page == 2) _send({"t": "hostinfo", "p": {"name": "$myName - Oda", "count": players.length, "map": currentMap}}, dg.address, dg.port);
      return;
    }
    if (t == "hello") {
      int ex = _epId(dg.address, dg.port);
      if (ex != -1) {
        _send({"t": "welcome", "p": {"id": ex}}, dg.address, dg.port);
        return;
      }
      if (page != 2 || players.length >= maxPlayers) {
        _send({"t": "err", "p": {"m": "Katılamazsın."}}, dg.address, dg.port);
        return;
      }
      int id = 1;
      while (players.any((x) => x.id == id)) id++;
      players.add(PlayerNet(id: id, name: gs(p["name"]).isEmpty ? "Oyuncu $id" : gs(p["name"]), lastSeen: nowSec()));
      endpoints[id] = Endpoint(dg.address, dg.port);
      _send({"t": "welcome", "p": {"id": id}}, dg.address, dg.port);
      status = "Oyuncu katıldı.";
      _broadcastLobby();
      return;
    }
    int id = _epId(dg.address, dg.port);
    if (id == -1) return;
    PlayerNet? pl = _player(id);
    if (pl != null) pl.lastSeen = nowSec();
    if (t == "ping") return;
    if (t == "leave") { _removePlayer(id); return; }
    if (t == "char" && page == 2) { _hostSelectChar(id, gi(p["c"])); return; }
    if (t == "state" && page == 3 && pl != null && pl.role == 1 && pl.alive) {
      pl.x = gd(p["x"]);
      pl.y = gd(p["y"]);
      pl.moving = gb(p["mv"]);
      if (activeMap != null) pl.roomId = _roomAt(Offset(pl.x, pl.y));
      return;
    }
    if (t == "act" && page == 3) _handleAction(id, gs(p["a"]));
  }

  void _clientPacket(String t, Map<String, dynamic> p, Datagram dg) {
    lastHostPacket = nowSec();
    if (t == "hostinfo" && page == 1) {
      String key = dg.address.address;
      DiscoveredHost? f;
      for (var d in discovered) if (d.addr == key) f = d;
      if (f == null) {
        discovered.add(DiscoveredHost(addr: key, port: dg.port, session: gs(p["name"]), count: gi(p["count"]), map: gi(p["map"]), last: nowSec()));
      } else {
        f.session = gs(p["name"]);
        f.count = gi(p["count"]);
        f.map = gi(p["map"]);
        f.last = nowSec();
      }
      ui();
      return;
    }
    if (t == "welcome") { myId = gi(p["id"]); page = 2; status = "Lobidesin."; ui(); return; }
    if (t == "lobby") {
      players.clear();
      currentMap = gi(p["map"]);
      if (p["players"] is List) {
        for (var it in (p["players"] as List)) {
          if (it is Map) {
            Map<String, dynamic> pl = it.cast<String, dynamic>();
            players.add(PlayerNet(id: gi(pl["id"]), name: gs(pl["name"]), charId: gi(pl["char"]), lastSeen: nowSec()));
          }
        }
      }
      if (page == 2) ui();
      return;
    }
    if (t == "start") { _startFromPayload(p); return; }
    if (t == "snap") { _applySnap(p); return; }
    if (t == "over") { _endLocal(gi(p["w"]), gs(p["m"])); return; }
    if (t == "err") { status = gs(p["m"]); page = 0; _closeNet(); ui(); return; }
    if (t == "closed") { _closeNet(); page = 0; status = "Host kapattı."; ui(); return; }
  }

  // ============================= MENÜ / LOBİ =============================
  Future<void> hostGame() async {
    if (!await startHostSocket()) { ui(); return; }
    isHost = true;
    myId = 0;
    guardId = -1;
    myRole = -1;
    myChar = -1;
    currentMap = 0;
    players.clear();
    endpoints.clear();
    ais.clear();
    remote.clear();
    players.add(PlayerNet(id: 0, name: myName, lastSeen: nowSec()));
    page = 2;
    status = "Host hazır.";
    _broadcastLobby();
    ui();
  }

  Future<void> openDiscovery() async {
    if (!await startClientSocket()) { ui(); return; }
    isHost = false;
    myId = -1;
    discovered.clear();
    page = 1;
    _sendDiscover();
    lastDiscovery = nowSec();
    ui();
  }

  void _sendDiscover() {
    try { _send({"t": "discover"}, InternetAddress("255.255.255.255"), netPort); } catch (_) {}
  }

  Future<void> joinIp() async {
    InternetAddress? a;
    try { a = InternetAddress(ipCtrl.text.trim()); } catch (_) {}
    if (a == null) { status = "Geçerli IP gir."; ui(); return; }
    if (!await startClientSocket()) { ui(); return; }
    isHost = false;
    myId = -1;
    hostAddr = a;
    hostPort = netPort;
    _hello();
    page = 0;
    status = "Bağlanıyor...";
    lastHostPacket = nowSec();
    ui();
  }

  void _joinDisc(DiscoveredHost d) {
    try {
      hostAddr = InternetAddress(d.addr);
      hostPort = d.port;
      _hello();
      page = 0;
      status = "Bağlanıyor...";
      lastHostPacket = nowSec();
      ui();
    } catch (_) {}
  }

  void _hello() => _toHost({"t": "hello", "p": {"name": myName}});

  void returnMenu() {
    if (isHost) _toAll({"t": "closed"}); else _toHost({"t": "leave"});
    _ticker?.dispose();
    _ticker = null;
    _closeNet();
    isHost = false;
    page = 0;
    myId = -1;
    guardId = -1;
    myRole = -1;
    myChar = -1;
    winner = 0;
    players.clear();
    endpoints.clear();
    ais.clear();
    remote.clear();
    discovered.clear();
    particles.clear();
    status = "Ana menü.";
    ui();
  }

  void _selectChar(int c) {
    if (page != 2) return;
    if (isHost) _hostSelectChar(myId, c); else _toHost({"t": "char", "p": {"c": c}});
  }

  void _hostSelectChar(int pid, int c) {
    if (page != 2 || c < 0 || c >= chars.length) return;
    PlayerNet? pl = _player(pid);
    if (pl == null) return;
    for (var o in players) {
      if (o.id != pid && o.charId == c) { status = "Bu karakter seçili."; _broadcastLobby(); return; }
    }
    pl.charId = c;
    status = "${chars[c].name} seçildi.";
    _broadcastLobby();
  }

  void _setMap(int m) {
    if (!isHost || page != 2) return;
    currentMap = m.clamp(0, 1);
    _broadcastLobby();
  }

  void _broadcastLobby() {
    if (!isHost) return;
    _toAll({"t": "lobby", "p": {"map": currentMap, "players": players.map((p) => {"id": p.id, "name": p.name, "char": p.charId}).toList()}});
    lastLobby = nowSec();
    ui();
  }

  // ============================= OYUN BAŞLAT =============================
  void _startHost() {
    if (!isHost || page != 2 || players.length < 2) { status = "En az 2 oyuncu."; ui(); return; }
    activeMap = makeMap(currentMap);
    _resetVars();
    List<int> ids = players.map((e) => e.id).toList();
    guardId = ids[rnd.nextInt(ids.length)];
    List<int> used = [];
    for (var p in players) {
      if (p.id == guardId) {
        p.role = 0;
        p.charId = -1;
        p.x = activeMap!.office.center.dx;
        p.y = activeMap!.office.center.dy;
        p.insideOffice = true;
        p.roomId = -2;
      } else {
        p.role = 1;
        if (p.charId < 0 || p.charId >= chars.length || used.contains(p.charId)) p.charId = _freeChar(used);
        used.add(p.charId);
        Offset s = _randSpawn();
        p.x = s.dx;
        p.y = s.dy;
        p.insideOffice = false;
        p.roomId = _roomAt(s);
      }
      p.alive = true;
      p.moving = false;
      p.cooldownUntil = 0;
      p.boostUntil = 0;
      p.silentUntil = 0;
      p.lightUntil = 0;
      p.ventProgress = 0;
      if (p.id == myId) { myRole = p.role; myChar = p.charId; localPos = Offset(p.x, p.y); myInside = p.insideOffice; }
    }
    ais.clear();
    int aiId = -100;
    for (int c = 0; c < chars.length; c++) {
      if (!used.contains(c)) {
        Offset s = _randSpawn();
        ais.add(AiNet(id: aiId--, charId: c, x: s.dx, y: s.dy, roomId: max(0, _roomAt(s)), speed: 1.0 + rnd.nextDouble() * 0.7));
      }
    }
    _toAll({"t": "start", "p": {
      "map": currentMap,
      "guard": guardId,
      "players": players.map((p) => {"id": p.id, "char": p.charId, "role": p.role, "x": p.x, "y": p.y}).toList(),
      "ais": ais.map((a) => {"id": a.id, "char": a.charId, "x": a.x, "y": a.y}).toList(),
    }});
    page = 3;
    _startTicker();
    ui();
  }

  void _startFromPayload(Map<String, dynamic> p) {
    _resetVars();
    currentMap = gi(p["map"]);
    guardId = gi(p["guard"]);
    activeMap = makeMap(currentMap);
    players.clear();
    remote.clear();
    ais.clear();
    if (p["players"] is List) {
      for (var it in (p["players"] as List)) {
        if (it is Map) {
          Map<String, dynamic> ps = it.cast<String, dynamic>();
          int id = gi(ps["id"]);
          int ch = gi(ps["char"]);
          int rl = gi(ps["role"]);
          double x = gd(ps["x"]), y = gd(ps["y"]);
          if (id == myId) {
            myRole = rl;
            myChar = ch;
            localPos = Offset(x, y);
            myInside = rl == 0;
          } else {
            remote[id] = EntityView(id: id, charId: ch, role: rl, x: x, y: y, room: rl == 0 ? -2 : _roomAt(Offset(x, y)), moving: false, hidden: false, inside: rl == 0, color: _charColor(ch));
          }
        }
      }
    }
    if (p["ais"] is List) {
      for (var it in (p["ais"] as List)) {
        if (it is Map) {
          Map<String, dynamic> a = it.cast<String, dynamic>();
          int id = gi(a["id"]);
          int ch = gi(a["char"]);
          double x = gd(a["x"]), y = gd(a["y"]);
          remote[id] = EntityView(id: id, charId: ch, role: 2, x: x, y: y, room: _roomAt(Offset(x, y)), moving: false, hidden: false, inside: false, color: _charColor(ch));
        }
      }
    }
    page = 3;
    _startTicker();
    ui();
  }

  void _resetVars() {
    gameTime = 0;
    energy = 100;
    leftDoorClosed = true;
    rightDoorClosed = true;
    flashOn = false;
    camOn = false;
    blackout = false;
    winner = 0;
    endMsg = "";
    forcedL = 0;
    forcedR = 0;
    dmgL = 0;
    dmgR = 0;
    camJam = 0;
    ctrlLock = 0;
    noiseRoom = -1;
    noiseUntil = 0;
    localMoving = false;
    myInside = myRole == 0;
    myCooldown = 0;
    myBoost = false;
    selectedCamRoom = 0;
    particles.clear();
    shake = 0;
    jumpscare = 0;
  }

  void _startTicker() {
    _ticker?.dispose();
    _ticker = createTicker(_tick)..start();
  }

  // ============================= DÖNGÜ =============================
  void _tick(Duration d) {
    if (page != 3) return;
    const double dt = 1.0 / 60.0;
    if (winner == 0) {
      if (myRole == 1) _moveLocal(dt);
      if (isHost) {
        _hostUpdate(dt);
      } else if (myRole == 1 && nowSec() - lastStateSend > 0.1) {
        _sendState();
      }
    }
    _updateParticles(dt);
    shake = max(0.0, shake - dt * 3);
    jumpscare = max(0.0, jumpscare - dt);
    _frame.value++;
    _hudAccum += dt;
    if (_hudAccum > 0.1) { _hudAccum = 0; ui(); }
  }

  void slowTick(Timer t) {
    double now = nowSec();
    if (page == 1) {
      if (now - lastDiscovery > 2) { lastDiscovery = now; _sendDiscover(); }
      int b = discovered.length;
      discovered.removeWhere((d) => now - d.last > 6);
      if (b != discovered.length) ui();
    }
    if (!isHost && (page == 2 || page == 3)) {
      if (now - lastHostPacket > 10) { status = "Bağlantı koptu."; returnMenu(); return; }
      if (now - lastPing > 2) { lastPing = now; _toHost({"t": "ping"}); }
    }
    if (isHost && page == 2 && now - lastLobby > 2) _broadcastLobby();
    if (isHost && (page == 2 || page == 3)) {
      for (int i = players.length - 1; i >= 0; i--) {
        if (players[i].id != 0 && now - players[i].lastSeen > 10) _removePlayer(players[i].id);
      }
    }
  }

  void _hostUpdate(double dt) {
    if (winner != 0 || activeMap == null) return;
    gameTime += dt;
    double drain = 0.08;
    if (leftDoorClosed) drain += 0.4;
    if (rightDoorClosed) drain += 0.4;
    if (flashOn) drain += 0.35;
    if (camOn) drain += 0.5;
    for (var p in players) {
      if (p.role == 1 && p.alive && p.charId >= 0 && p.charId < chars.length && chars[p.charId].passive == "energy") {
        if ((Offset(p.x, p.y) - activeMap!.office.center).distance < 10) drain += 0.15;
      }
    }
    energy -= drain * dt;
    if (energy <= 0 && !blackout) {
      energy = 0;
      blackout = true;
      leftDoorClosed = false;
      rightDoorClosed = false;
      flashOn = false;
      camOn = false;
    }
    if (blackout) energy = 0;
    _updateAI(dt);
    if (gameTime >= nightDuration) { _endGame(1, "Güvenlik sabaha kadar dayandı."); return; }
    if (!players.any((p) => p.role == 1 && p.alive)) { _endGame(1, "Animatronik kalmadı."); return; }
    PlayerNet? me = _player(myId);
    if (me != null) {
      myInside = me.insideOffice;
      myCooldown = max(0.0, me.cooldownUntil - gameTime);
      myBoost = me.boostUntil > gameTime;
    }
    double now = nowSec();
    if (now - lastSnap > 0.1) { lastSnap = now; _broadcastSnap(); }
  }

  void _updateAI(double dt) {
    if (activeMap == null || activeMap!.rooms.isEmpty) return;
    for (var a in ais) {
      if (a.roomId < 0 || a.roomId >= activeMap!.rooms.length) a.roomId = rnd.nextInt(activeMap!.rooms.length);
      Rect r = activeMap!.rooms[a.roomId].rect;
      if (gameTime >= a.nextThink || (Offset(a.x, a.y) - Offset(a.tx, a.ty)).distance < 0.5) {
        a.nextThink = gameTime + 2 + rnd.nextDouble() * 3;
        double mx = min(1.0, r.width * 0.25), my = min(1.0, r.height * 0.25);
        double x1 = r.left + mx, x2 = r.right - mx, y1 = r.top + my, y2 = r.bottom - my;
        if (x2 < x1) x1 = x2 = r.center.dx;
        if (y2 < y1) y1 = y2 = r.center.dy;
        a.tx = x1 + rnd.nextDouble() * (x2 - x1);
        a.ty = y1 + rnd.nextDouble() * (y2 - y1);
      }
      Offset dir = Offset(a.tx, a.ty) - Offset(a.x, a.y);
      if (dir.distance > 0.2) {
        Offset n = Offset(a.x, a.y) + (dir / dir.distance) * a.speed * dt;
        a.x = n.dx;
        a.y = n.dy;
        a.moving = true;
      } else {
        a.moving = false;
      }
    }
  }

  void _moveLocal(double dt) {
    if (page != 3 || winner != 0 || myRole != 1 || activeMap == null) return;
    Offset dir = Offset(joyX, joyY);
    localMoving = dir.distance > 0.1;
    if (localMoving) {
      if (dir.distance > 1) dir = dir / dir.distance;
      double sp = _localSpeed();
      Offset n = localPos + dir * sp * dt;
      if (_walkable(n)) {
        localPos = n;
      } else {
        Offset nx = localPos + Offset(dir.dx * sp * dt, 0);
        if (_walkable(nx)) localPos = nx;
        Offset ny = localPos + Offset(0, dir.dy * sp * dt);
        if (_walkable(ny)) localPos = ny;
      }
    }
    if (isHost) {
      PlayerNet? me = _player(myId);
      if (me != null) { me.x = localPos.dx; me.y = localPos.dy; me.moving = localMoving; me.roomId = _roomAt(localPos); }
    }
  }

  double _localSpeed() {
    double s = 3.2;
    if (myChar >= 0 && myChar < chars.length) {
      s = chars[myChar].speed;
      if (chars[myChar].passive == "speed") s *= 1.15;
    }
    if (myBoost) s *= 1.6;
    if (myInside) s *= 0.85;
    return s;
  }

  void _sendState() {
    lastStateSend = nowSec();
    _toHost({"t": "state", "p": {"x": localPos.dx, "y": localPos.dy, "mv": localMoving}});
  }

  // ============================= AKSİYONLAR =============================
  void _guardAct(String a) {
    if (page != 3 || myRole != 0 || winner != 0) return;
    if (isHost) _handleAction(myId, a); else _toHost({"t": "act", "p": {"a": a}});
  }

  void _interact() {
    if (page != 3 || myRole != 1 || winner != 0) return;
    String a = _context();
    if (a == "none") return;
    if (isHost) _handleAction(myId, a); else _toHost({"t": "act", "p": {"a": a}});
  }

  void _ability() {
    if (page != 3 || myRole != 1 || winner != 0 || myCooldown > 0) return;
    if (isHost) _handleAction(myId, "ability"); else _toHost({"t": "act", "p": {"a": "ability"}});
  }

  String _context() {
    if (page != 3 || activeMap == null || myRole != 1) return "none";
    if (myInside) return "attack";
    if ((localPos - activeMap!.leftDoor).distance < 3) return leftDoorClosed ? "forceL" : "enterL";
    if ((localPos - activeMap!.rightDoor).distance < 3) return rightDoorClosed ? "forceR" : "enterR";
    if ((localPos - activeMap!.vent).distance < 3) return "vent";
    return "none";
  }

  void _handleAction(int id, String a) {
    if (page != 3 || winner != 0 || activeMap == null) return;
    PlayerNet? p = _player(id);
    if (p == null || !p.alive) return;
    p.lastSeen = nowSec();
    if (id == guardId) { _guardAction(a); return; }
    if (p.role != 1 || p.charId < 0 || p.charId >= chars.length) return;
    CharDef c = chars[p.charId];
    if (a == "ability") {
      if (gameTime < p.cooldownUntil) return;
      p.cooldownUntil = gameTime + c.cooldown;
      _applyActive(p, c);
    } else if (a == "enterL") _enter(p, 0);
    else if (a == "enterR") _enter(p, 1);
    else if (a == "forceL") _force(p, 0, c);
    else if (a == "forceR") _force(p, 1, c);
    else if (a == "vent") _vent(p, c);
    else if (a == "attack") _attack(p, c);
  }

  void _guardAction(String a) {
    if (blackout || ctrlLock > gameTime) return;
    if (a == "doorL" && forcedL <= gameTime) { leftDoorClosed = !leftDoorClosed; dmgL = 0; }
    else if (a == "doorR" && forcedR <= gameTime) { rightDoorClosed = !rightDoorClosed; dmgR = 0; }
    else if (a == "flash") flashOn = !flashOn;
    else if (a == "cam") camOn = !camOn;
  }

  void _enter(PlayerNet p, int side) {
    if (p.insideOffice || activeMap == null) return;
    Offset door = side == 0 ? activeMap!.leftDoor : activeMap!.rightDoor;
    if ((Offset(p.x, p.y) - door).distance > 3) return;
    if (side == 0 ? leftDoorClosed : rightDoorClosed) return;
    p.insideOffice = true;
    p.entrySide = side;
    p.roomId = -2;
    Offset in = side == 0 ? activeMap!.insideLeft : activeMap!.insideRight;
    p.x = in.dx;
    p.y = in.dy;
    _burst(in, Colors.red, 14);
    if (p.id == myId) { myInside = true; localPos = in; }
  }

  void _force(PlayerNet p, int side, CharDef c) {
    if (p.insideOffice || activeMap == null) return;
    Offset door = side == 0 ? activeMap!.leftDoor : activeMap!.rightDoor;
    if ((Offset(p.x, p.y) - door).distance > 3) return;
    if (!(side == 0 ? leftDoorClosed : rightDoorClosed)) return;
    if ((side == 0 ? forcedL : forcedR) > gameTime) return;
    double dmg = 25;
    if (c.passive == "door") dmg *= 1.5;
    _burst(door, Colors.orange, 10);
    shake = max(shake, 0.5);
    if (side == 0) {
      dmgL += dmg;
      if (dmgL >= 100) { dmgL = 0; leftDoorClosed = false; forcedL = gameTime + 5; }
    } else {
      dmgR += dmg;
      if (dmgR >= 100) { dmgR = 0; rightDoorClosed = false; forcedR = gameTime + 5; }
    }
  }

  void _vent(PlayerNet p, CharDef c) {
    if (p.insideOffice || activeMap == null) return;
    if ((Offset(p.x, p.y) - activeMap!.vent).distance > 3) return;
    p.ventProgress += (c.passive == "vent" ? 0.6 : 0.34);
    if (p.ventProgress >= 1) {
      p.ventProgress = 0;
      p.insideOffice = true;
      p.entrySide = 2;
      p.roomId = -2;
      p.x = activeMap!.insideVent.dx;
      p.y = activeMap!.insideVent.dy;
      _burst(activeMap!.insideVent, Colors.yellow, 12);
      if (p.id == myId) { myInside = true; localPos = Offset(p.x, p.y); }
    }
  }

  void _attack(PlayerNet p, CharDef c) {
    if (!p.insideOffice || activeMap == null) return;
    bool repelled = false;
    if (flashOn && !blackout && p.lightUntil < gameTime) repelled = (c.passive == "light") ? rnd.nextBool() : true;
    if (repelled) {
      Offset out = _outside(p.entrySide);
      p.insideOffice = false;
      p.ventProgress = 0;
      p.x = out.dx;
      p.y = out.dy;
      p.roomId = _roomAt(out);
      p.cooldownUntil = max(p.cooldownUntil, gameTime + 2);
      _burst(out, Colors.blue, 12);
      if (p.id == myId) { myInside = false; localPos = out; }
    } else {
      jumpscare = 1.2;
      shake = 1.5;
      _burst(Offset(p.x, p.y), Colors.red, 40);
      _endGame(2, "${p.name} güvenliği yakaladı!");
    }
  }

  Offset _outside(int side) {
    if (activeMap == null) return Offset.zero;
    if (side == 0) return activeMap!.leftDoor;
    if (side == 1) return activeMap!.rightDoor;
    return activeMap!.vent;
  }

  void _applyActive(PlayerNet p, CharDef c) {
    if (activeMap == null) return;
    if (c.active == "speed") { p.boostUntil = gameTime + 4; }
    else if (c.active == "dash") {
      Offset d = activeMap!.office.center - Offset(p.x, p.y);
      if (d.distance > 0.1) {
        Offset t = Offset(p.x, p.y) + (d / d.distance) * 4;
        if (_walkableFor(t, p)) { p.x = t.dx; p.y = t.dy; _burst(t, c.color, 10); if (p.id == myId) localPos = t; }
      }
    } else if (c.active == "camjam") { camJam = gameTime + 5; }
    else if (c.active == "doorbreak") {
      if ((Offset(p.x, p.y) - activeMap!.leftDoor).distance < 3.5) { leftDoorClosed = false; forcedL = gameTime + 5; _burst(activeMap!.leftDoor, Colors.orange, 16); }
      else if ((Offset(p.x, p.y) - activeMap!.rightDoor).distance < 3.5) { rightDoorClosed = false; forcedR = gameTime + 5; _burst(activeMap!.rightDoor, Colors.orange, 16); }
    } else if (c.active == "ventrush") {
      if ((Offset(p.x, p.y) - activeMap!.vent).distance < 3.5) {
        p.insideOffice = true; p.entrySide = 2; p.roomId = -2;
        p.x = activeMap!.insideVent.dx; p.y = activeMap!.insideVent.dy;
        if (p.id == myId) { myInside = true; localPos = Offset(p.x, p.y); }
      }
    } else if (c.active == "drain") {
      if ((Offset(p.x, p.y) - activeMap!.office.center).distance < 10) energy = max(0.0, energy - 10);
    } else if (c.active == "lightimmune") { p.lightUntil = gameTime + 5; }
    else if (c.active == "silent") { p.silentUntil = gameTime + 5; }
    else if (c.active == "noise") {
      if (activeMap!.rooms.isNotEmpty) { noiseRoom = rnd.nextInt(activeMap!.rooms.length); noiseUntil = gameTime + 3; }
    } else if (c.active == "fear") { ctrlLock = gameTime + 3; }
  }

  bool _walkableFor(Offset pos, PlayerNet p) {
    if (activeMap == null) return false;
    if (p.role == 0) return activeMap!.office.contains(pos);
    if (p.insideOffice) return activeMap!.office.contains(pos);
    if (activeMap!.office.contains(pos)) return false;
    for (var r in activeMap!.rooms) if (r.rect.contains(pos)) return true;
    return false;
  }

  // ============================= SNAPSHOT / BİTİŞ =============================
  void _broadcastSnap() {
    if (!isHost || page != 3) return;
    List<Map<String, dynamic>> ents = [];
    for (var p in players) {
      if (!p.alive) continue;
      bool hid = false;
      if (p.role == 1 && p.charId >= 0 && p.charId < chars.length) {
        if (p.silentUntil > gameTime) hid = true;
        String pa = chars[p.charId].passive;
        if (pa == "quiet" || pa == "ghost") hid = true;
      }
      ents.add({"id": p.id, "ch": p.charId, "rl": p.role, "x": p.x, "y": p.y, "rm": p.roomId, "mv": p.moving, "io": p.insideOffice, "cd": max(0.0, p.cooldownUntil - gameTime), "hid": hid, "sp": p.boostUntil > gameTime});
    }
    for (var a in ais) {
      ents.add({"id": a.id, "ch": a.charId, "rl": 2, "x": a.x, "y": a.y, "rm": a.roomId, "mv": a.moving, "io": false, "cd": 0.0, "hid": false, "sp": false});
    }
    _toAll({"t": "snap", "p": {"t": gameTime, "e": energy.round(), "ld": leftDoorClosed, "rd": rightDoorClosed, "fl": flashOn, "cam": camOn, "jam": max(0.0, camJam - gameTime), "black": blackout, "w": winner, "g": guardId, "nr": noiseRoom, "nu": noiseUntil, "ents": ents}});
  }

  void _applySnap(Map<String, dynamic> p) {
    if (page != 3) return;
    gameTime = gd(p["t"]);
    energy = gd(p["e"]);
    leftDoorClosed = gb(p["ld"]);
    rightDoorClosed = gb(p["rd"]);
    flashOn = gb(p["fl"]);
    camOn = gb(p["cam"]);
    camJam = gameTime + gd(p["jam"]);
    blackout = gb(p["black"]);
    guardId = gi(p["g"]);
    noiseRoom = gi(p["nr"]);
    noiseUntil = gd(p["nu"]);
    if (gi(p["w"]) > 0) { _endLocal(gi(p["w"]), gs(p["m"])); return; }
    remote.clear();
    if (p["ents"] is List) {
      for (var it in (p["ents"] as List)) {
        if (it is Map) {
          Map<String, dynamic> e = it.cast<String, dynamic>();
          int id = gi(e["id"]);
          if (id == myId) {
            myInside = gb(e["io"]);
            myCooldown = gd(e["cd"]);
            myBoost = gb(e["sp"]);
            Offset hp = Offset(gd(e["x"]), gd(e["y"]));
            if ((localPos - hp).distance > 5) localPos = hp;
            continue;
          }
          remote[id] = EntityView(id: id, charId: gi(e["ch"]), role: gi(e["rl"]), x: gd(e["x"]), y: gd(e["y"]), room: gi(e["rm"]), moving: gb(e["mv"]), hidden: gb(e["hid"]), inside: gb(e["io"]), color: _charColor(gi(e["ch"])));
        }
      }
    }
    lastHostPacket = nowSec();
  }

  void _endGame(int w, String m) {
    if (page != 3 || winner != 0) return;
    winner = w;
    _toAll({"t": "over", "p": {"w": w, "m": m}});
    _endLocal(w, m);
  }

  void _endLocal(int w, String m) {
    if (page == 4) return;
    winner = w;
    endMsg = m;
    page = 4;
    _ticker?.dispose();
    _ticker = null;
    ui();
  }

  void _removePlayer(int id) {
    if (id == 0) return;
    if (page == 3 && id == guardId) {
      players.removeWhere((p) => p.id == id);
      endpoints.remove(id);
      _endGame(2, "Güvenlik ayrıldı.");
      return;
    }
    players.removeWhere((p) => p.id == id);
    endpoints.remove(id);
    if (page == 2) { status = "Oyuncu ayrıldı."; _broadcastLobby(); }
    else if (page == 3 && !players.any((p) => p.role == 1 && p.alive)) _endGame(1, "Animatronik kalmadı.");
  }

  // ============================= PARÇACIKLAR =============================
  void _burst(Offset pos, Color color, int count) {
    if (!_particlesOn || q.particleCap == 0) return;
    int n = min(count, q.particleCap - particles.length);
    for (int i = 0; i < n; i++) {
      double ang = rnd.nextDouble() * 2 * pi;
      double sp = 1 + rnd.nextDouble() * 4;
      particles.add(Particle(x: pos.dx, y: pos.dy, vx: cos(ang) * sp, vy: sin(ang) * sp, life: 0.4 + rnd.nextDouble() * 0.5, size: 0.2 + rnd.nextDouble() * 0.4, color: color));
    }
  }

  void _updateParticles(double dt) {
    for (int i = particles.length - 1; i >= 0; i--) {
      Particle p = particles[i];
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.vx *= 0.92;
      p.vy *= 0.92;
      p.life -= dt;
      if (p.life <= 0) particles.removeAt(i);
    }
  }

  // ============================= GEOMETRİ =============================
  PlayerNet? _player(int id) {
    for (var p in players) if (p.id == id) return p;
    return null;
  }

  bool _walkable(Offset pos) {
    if (activeMap == null) return false;
    if (myRole == 0) return activeMap!.office.contains(pos);
    if (myInside) return activeMap!.office.contains(pos);
    if (activeMap!.office.contains(pos)) return false;
    for (var r in activeMap!.rooms) if (r.rect.contains(pos)) return true;
    return false;
  }

  int _roomAt(Offset pos) {
    if (activeMap == null) return -1;
    if (activeMap!.office.contains(pos)) return -2;
    for (int i = 0; i < activeMap!.rooms.length; i++) if (activeMap!.rooms[i].rect.contains(pos)) return i;
    return -1;
  }

  Offset _randSpawn() {
    if (activeMap == null || activeMap!.rooms.isEmpty) return const Offset(20, 20);
    Rect r = activeMap!.rooms[rnd.nextInt(activeMap!.rooms.length)].rect;
    double mx = min(1.0, r.width * 0.25), my = min(1.0, r.height * 0.25);
    double x1 = r.left + mx, x2 = r.right - mx, y1 = r.top + my, y2 = r.bottom - my;
    if (x2 < x1) x1 = x2 = r.center.dx;
    if (y2 < y1) y1 = y2 = r.center.dy;
    return Offset(x1 + rnd.nextDouble() * (x2 - x1), y1 + rnd.nextDouble() * (y2 - y1));
  }

  int _freeChar(List<int> used) {
    for (int i = 0; i < 100; i++) {
      int c = rnd.nextInt(chars.length);
      if (!used.contains(c)) return c;
    }
    for (int c = 0; c < chars.length; c++) if (!used.contains(c)) return c;
    return 0;
  }

  String _charName(int id) => (id < 0 || id >= chars.length) ? "?" : chars[id].name;
  Color _charColor(int id) => (id < 0 || id >= chars.length) ? Colors.white : chars[id].color;

  List<EntityView> _views() {
    List<EntityView> v = [];
    if (isHost) {
      for (var p in players) {
        if (!p.alive) continue;
        bool hid = false;
        if (p.role == 1 && p.charId >= 0 && p.charId < chars.length) {
          if (p.silentUntil > gameTime) hid = true;
          String pa = chars[p.charId].passive;
          if (pa == "quiet" || pa == "ghost") hid = true;
        }
        v.add(EntityView(id: p.id, charId: p.charId, role: p.role, x: p.x, y: p.y, room: p.roomId, moving: p.moving, hidden: hid, inside: p.insideOffice, color: p.role == 0 ? Colors.cyan : _charColor(p.charId)));
      }
      for (var a in ais) v.add(EntityView(id: a.id, charId: a.charId, role: 2, x: a.x, y: a.y, room: a.roomId, moving: a.moving, hidden: false, inside: false, color: _charColor(a.charId)));
    } else {
      v.addAll(remote.values);
      if (myRole == 1) v.add(EntityView(id: myId, charId: myChar, role: 1, x: localPos.dx, y: localPos.dy, room: _roomAt(localPos), moving: localMoving, hidden: false, inside: myInside, color: _charColor(myChar)));
    }
    return v;
  }

  String _detected() {
    if (activeMap == null || selectedCamRoom < 0 || selectedCamRoom >= activeMap!.rooms.length) return "";
    if (camJam > gameTime) return "PARAZİT - GÖRÜNTÜ YOK";
    List<String> names = [];
    for (var v in _views()) {
      if (v.role != 0 && !v.inside && v.room == selectedCamRoom && v.moving && !v.hidden) names.add(_charName(v.charId));
    }
    String t = "";
    if (noiseRoom == selectedCamRoom && noiseUntil > gameTime) t += "SES ALGILANDI!\n";
    t += names.isEmpty ? "Temiz." : "Hareket: ${names.join(', ')}";
    return t;
  }

  String _clock() {
    int h = ((gameTime / nightDuration).clamp(0.0, 1.0) * 6).floor();
    if (h >= 6) return "06:00";
    if (h <= 0) return "12:00";
    return "0$h:00";
  }

  // ============================= UI =============================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050508),
      body: SafeArea(child: Builder(builder: (_) {
        if (page == 0) return _menu();
        if (page == 1) return _discover();
        if (page == 2) return _lobby();
        if (page == 3) return _game();
        return _end();
      })),
    );
  }

  Widget _menu() => Padding(padding: const EdgeInsets.all(20), child: Column(children: [
    const Text("DARKESCAS", style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Color(0xFFB388FF))),
    const Text("LAN Korku Prototipi", style: TextStyle(color: Colors.white54)),
    const SizedBox(height: 12),
    Text(status, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15)),
    const SizedBox(height: 20),
    _btn("HOST OL", hostGame),
    _btn("OYUN BUL", openDiscovery),
    TextField(controller: ipCtrl, keyboardType: TextInputType.number, style: const TextStyle(fontSize: 18),
      decoration: InputDecoration(hintText: "192.168.1.x", filled: true, fillColor: Colors.grey[900], border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
    const SizedBox(height: 10),
    _btn("IP İLE KATIL", joinIp),
    const SizedBox(height: 10),
    _btn("GRAFİK AYARLARI", () { _showSettings = true; ui(); }),
    const SizedBox(height: 16),
    Text("Kalite: ${_qName()}", style: const TextStyle(color: Colors.white70)),
    const Expanded(child: SizedBox()),
  ]));

  Widget _discover() => Column(children: [
    const Padding(padding: EdgeInsets.all(16), child: Text("Ağdaki Oyunlar", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
    Text(discovered.isEmpty ? "Aranıyor..." : "${discovered.length} oda"),
    Expanded(child: ListView.builder(itemCount: discovered.length, itemBuilder: (c, i) {
      DiscoveredHost d = discovered[i];
      return Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), child: _btn("${d.session}\n${d.count}/$maxPlayers - Harita ${d.map + 1}", () => _joinDisc(d)));
    })),
    Padding(padding: const EdgeInsets.all(16), child: _btn("GERİ", returnMenu)),
  ]);

  Widget _lobby() {
    String pt = players.map((p) => "${p.name}${p.id == 0 ? " (HOST)" : ""} - ${p.charId >= 0 && p.charId < chars.length ? chars[p.charId].name : 'Seçilmedi'}").join("\n");
    return Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      const Text("LOBİ", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
      Text(status, style: const TextStyle(color: Colors.white60)),
      const SizedBox(height: 6),
      Text(pt, textAlign: TextAlign.center),
      const SizedBox(height: 10),
      Text("Harita: ${makeMap(currentMap).name}"),
      Row(children: [
        Expanded(child: _btn("Harita 1", () => _setMap(0), bg: currentMap == 0 ? Colors.teal : null)),
        const SizedBox(width: 8),
        Expanded(child: _btn("Harita 2", () => _setMap(1), bg: currentMap == 1 ? Colors.teal : null)),
      ]),
      const SizedBox(height: 8),
      _btn("OYUNU BAŞLAT", _startHost, enabled: isHost && players.length >= 2),
      const SizedBox(height: 8),
      Expanded(child: ListView.builder(itemCount: chars.length, itemBuilder: (c, i) {
        bool me = false, other = false;
        for (var p in players) if (p.charId == i) { if (p.id == myId) me = true; else other = true; }
        Color bg = Colors.grey[850]!;
        if (me) bg = Colors.green[800]!;
        if (other) bg = Colors.red[900]!;
        return Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: _btn(chars[i].name, () => _selectChar(i), bg: bg, enabled: !other || me, small: true));
      })),
      _btn("AYRIL", returnMenu),
    ]));
  }

  Widget _game() {
    List<EntityView> views = _views();
    bool camActive = camOn && !blackout;
    String top = "${_clock()} | Enerji %${energy.round()}";
    if (blackout) top += " | KARANLIK!";
    if (camJam > gameTime) top += " | PARAZİT!";
    if (views.any((v) => v.role == 1 && v.inside)) top += " | OFİSTE BİRİ VAR!";
    return Stack(children: [
      ValueListenableBuilder<int>(valueListenable: _frame, builder: (c, f, w) => Positioned.fill(child: CustomPaint(painter: GamePainter(
        map: activeMap, entities: views, q: q, particles: _particlesOn ? particles : const <Particle>[],
        shake: shake, jumpscare: jumpscare, myRole: myRole, localPos: localPos, flashOn: flashOn, blackout: blackout,
        leftClosed: leftDoorClosed, rightClosed: rightDoorClosed, camActive: camActive && myRole == 0, rnd: rnd, gameTime: gameTime)))),
      Positioned(top: 8, left: 8, right: 8, child: Container(padding: const EdgeInsets.all(8), color: Colors.black54, child: Row(children: [
        Expanded(child: Text(top, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14))),
        IconButton(icon: const Icon(Icons.settings, size: 20), onPressed: () { _showSettings = true; ui(); }),
      ]))),
      if (camActive && myRole == 0) _camOverlay(),
      if (myRole == 0) _guardBar(),
      if (myRole == 1) _animControls(),
      if (_showSettings) _settingsOverlay(),
    ]);
  }

  Widget _camOverlay() {
    if (activeMap == null) return const SizedBox();
    return Positioned(top: 50, left: 8, right: 8, height: 210, child: Container(padding: const EdgeInsets.all(8), color: const Color(0xDD001400), child: Column(children: [
      Text("KAMERA: ${activeMap!.rooms[selectedCamRoom].name}", style: const TextStyle(color: Color(0xFF66FF66))),
      const SizedBox(height: 4),
      Expanded(child: Text(_detected(), style: const TextStyle(color: Color(0xFF66FF66)))),
      SizedBox(height: 56, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: activeMap!.rooms.length, itemBuilder: (c, i) =>
        Padding(padding: const EdgeInsets.only(right: 6), child: _btn(activeMap!.rooms[i].name, () { selectedCamRoom = i; ui(); }, bg: selectedCamRoom == i ? Colors.green[900] : Colors.black, small: true)))),
    ])));
  }

  Widget _guardBar() => Positioned(left: 8, right: 8, bottom: 8, height: 76, child: Row(children: [
    Expanded(child: _btn(leftDoorClosed ? "SOL KAPALI" : "SOL AÇIK", () => _guardAct("doorL"), bg: leftDoorClosed ? Colors.red[900] : Colors.green[900], small: true)),
    const SizedBox(width: 6),
    Expanded(child: _btn(rightDoorClosed ? "SAĞ KAPALI" : "SAĞ AÇIK", () => _guardAct("doorR"), bg: rightDoorClosed ? Colors.red[900] : Colors.green[900], small: true)),
    const SizedBox(width: 6),
    Expanded(child: _btn("FENER", () => _guardAct("flash"), bg: flashOn ? Colors.yellow[800] : Colors.grey[850], small: true)),
    const SizedBox(width: 6),
    Expanded(child: _btn("KAMERA", () => _guardAct("cam"), bg: camOn ? Colors.blue[900] : Colors.grey[850], small: true)),
  ]));

  Widget _animControls() {
    String a = _context();
    String label = "ETKİLEŞİM YOK";
    if (a == "attack") label = "SALDIR!";
    else if (a == "enterL") label = "SOLDAN SIZ";
    else if (a == "enterR") label = "SAĞDAN SIZ";
    else if (a == "forceL") label = "SOL ZORLA";
    else if (a == "forceR") label = "SAĞ ZORLA";
    else if (a == "vent") label = "HAVALANDIRMA";
    return Stack(children: [
      Positioned(left: 20, bottom: 20, child: _joystick()),
      Positioned(right: 20, bottom: 110, width: 170, height: 64, child: _btn(myCooldown > 0 ? "YETENEK ${myCooldown.ceil()}s" : "YETENEK", _ability, bg: myCooldown <= 0 ? Colors.purple[800] : Colors.grey[850], enabled: myCooldown <= 0, small: true)),
      Positioned(right: 20, bottom: 30, width: 170, height: 64, child: _btn(label, _interact, bg: a == "none" ? Colors.grey[850] : Colors.orange[900], enabled: a != "none", small: true)),
    ]);
  }

  Widget _joystick() => GestureDetector(
    onPanStart: (d) => _joy(d.localPosition),
    onPanUpdate: (d) => _joy(d.localPosition),
    onPanEnd: (_) { joyThumb = Offset.zero; joyX = 0; joyY = 0; ui(); },
    child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white10, border: Border.all(color: Colors.white24)),
      child: Stack(children: [Positioned(left: 75 + joyThumb.dx - 30, top: 75 + joyThumb.dy - 30, child: Container(width: 60, height: 60, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white38)))])));

  void _joy(Offset local) {
    Offset v = local - const Offset(75, 75);
    double d = v.distance;
    if (d > 60) v = (v / d) * 60;
    joyThumb = v;
    joyX = v.dx / 60;
    joyY = v.dy / 60;
  }

  Widget _settingsOverlay() => Positioned.fill(child: Material(color: Colors.black87, child: Center(child: Container(width: 300, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF141220), borderRadius: BorderRadius.circular(16)), child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Text("GRAFİK AYARLARI", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
    const SizedBox(height: 12),
    Row(children: [
      Expanded(child: _btn("Düşük", () => setQuality(Quality.low), bg: quality == Quality.low ? Colors.teal : null, small: true)),
      const SizedBox(width: 6),
      Expanded(child: _btn("Orta", () => setQuality(Quality.medium), bg: quality == Quality.medium ? Colors.teal : null, small: true)),
      const SizedBox(width: 6),
      Expanded(child: _btn("Yüksek", () => setQuality(Quality.high), bg: quality == Quality.high ? Colors.teal : null, small: true)),
    ]),
    const SizedBox(height: 10),
    _btn(_particlesOn ? "Parçacıklar: AÇIK" : "Parçacıklar: KAPALI", () { _particlesOn = !_particlesOn; ui(); }, small: true),
    const SizedBox(height: 8),
    Text("Kalite: ${_qName()}", style: const TextStyle(color: Colors.white60)),
    const SizedBox(height: 12),
    _btn("KAPAT", () { _showSettings = false; ui(); }),
  ]))));

  String _qName() => quality == Quality.low ? "Düşük" : quality == Quality.medium ? "Orta" : "Yüksek";

  Widget _end() {
    String r = winner == 1 ? "GÜVENLİK KAZANDI" : "ANİMATRONİKLER KAZANDI";
    String per = myRole == 0 ? (winner == 1 ? "Kazandın!" : "Yakalandın!") : (winner == 2 ? "Kazandınız!" : "Kaybettiniz!");
    return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(r, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Color(0xFFB388FF))),
      const SizedBox(height: 12),
      Text(per, style: const TextStyle(fontSize: 20)),
      const SizedBox(height: 12),
      Text(endMsg, style: const TextStyle(color: Colors.white60)),
      const SizedBox(height: 24),
      _btn("ANA MENÜ", returnMenu),
    ])));
  }

  Widget _btn(String text, VoidCallback on, {Color? bg, bool enabled = true, bool small = false}) => ElevatedButton(
    onPressed: enabled ? on : null,
    style: ElevatedButton.styleFrom(backgroundColor: bg ?? Colors.grey[850], disabledBackgroundColor: Colors.grey[900]),
    child: Padding(padding: EdgeInsets.all(small ? 8 : 12), child: Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: small ? 13 : 18))));

  // ============================= VERİ =============================
  List<CharDef> makeChars() => [
    CharDef(name: "Volti", color: const Color(0xFF3CC8FF), speed: 3.4, cooldown: 12, active: "speed", passive: "speed"),
    CharDef(name: "Griz", color: const Color(0xFFBE5A32), speed: 3.1, cooldown: 18, active: "doorbreak", passive: "door"),
    CharDef(name: "Çarkınetta", color: const Color(0xFFC8B4E6), speed: 3.2, cooldown: 16, active: "camjam", passive: "quiet"),
    CharDef(name: "Karga-9", color: const Color(0xFF28E696), speed: 3.3, cooldown: 12, active: "noise", passive: "ghost"),
    CharDef(name: "Zımpara", color: const Color(0xFFE66464), speed: 3.1, cooldown: 20, active: "fear", passive: "door"),
    CharDef(name: "Fısıltı", color: const Color(0xFF96C8FF), speed: 3.3, cooldown: 20, active: "ventrush", passive: "vent"),
    CharDef(name: "Mırıltı", color: const Color(0xFF8C50A0), speed: 3.2, cooldown: 16, active: "drain", passive: "energy"),
    CharDef(name: "Lüm", color: const Color(0xFFFFE65A), speed: 3.2, cooldown: 16, active: "lightimmune", passive: "light"),
    CharDef(name: "Teneke", color: const Color(0xFFA0A0A0), speed: 3.2, cooldown: 14, active: "silent", passive: "quiet"),
    CharDef(name: "TikTak", color: const Color(0xFFE6963C), speed: 3.4, cooldown: 12, active: "dash", passive: "speed"),
    CharDef(name: "Cıvata", color: const Color(0xFF6464E6), speed: 3.2, cooldown: 16, active: "camjam", passive: "vent"),
    CharDef(name: "Çekir", color: const Color(0xFFE650B4), speed: 3.3, cooldown: 16, active: "drain", passive: "energy"),
    CharDef(name: "Siren", color: const Color(0xFFDCC8A0), speed: 3.2, cooldown: 12, active: "noise", passive: "ghost"),
    CharDef(name: "Gölge", color: const Color(0xFF3C3C46), speed: 3.2, cooldown: 16, active: "camjam", passive: "ghost"),
    CharDef(name: "Kavray", color: const Color(0xFF6EB450), speed: 3.1, cooldown: 18, active: "doorbreak", passive: "door"),
    CharDef(name: "Buğu", color: const Color(0xFFBEE6F0), speed: 3.2, cooldown: 14, active: "silent", passive: "quiet"),
    CharDef(name: "Şerare", color: const Color(0xFFFF4646), speed: 3.5, cooldown: 12, active: "dash", passive: "speed"),
    CharDef(name: "Hışır", color: const Color(0xFF8C7D50), speed: 3.1, cooldown: 12, active: "noise", passive: "energy"),
    CharDef(name: "Yansı", color: const Color(0xFFDCDCFF), speed: 3.2, cooldown: 16, active: "lightimmune", passive: "light"),
    CharDef(name: "Eski-1", color: const Color(0xFF5A8C96), speed: 3.0, cooldown: 18, active: "doorbreak", passive: "door"),
  ];

  MapDef makeMap(int id) {
    if (id == 1) return MapDef(name: "Yeni Pizzacı", office: Rect.fromLTWH(17, 18, 6, 4),
      leftDoor: const Offset(16.3, 19.5), rightDoor: const Offset(23.7, 19.5), vent: const Offset(20, 17.5),
      insideLeft: const Offset(18, 20), insideRight: const Offset(22, 20), insideVent: const Offset(20, 19),
      rooms: [Room("Ana Salon", Rect.fromLTWH(16, 14, 8, 15)), Room("Sol Koridor", Rect.fromLTWH(10, 18, 7, 6)),
        Room("Sağ Koridor", Rect.fromLTWH(23, 18, 7, 6)), Room("Yemek", Rect.fromLTWH(12, 4, 16, 11)),
        Room("Sol Kanat", Rect.fromLTWH(8, 10, 10, 4)), Room("Sağ Kanat", Rect.fromLTWH(22, 10, 10, 4)),
        Room("Parça Servis", Rect.fromLTWH(2, 10, 7, 8)), Room("Ödül Köşesi", Rect.fromLTWH(31, 10, 7, 8)),
        Room("Oyun Alanı", Rect.fromLTWH(14, 0, 12, 5))]);
    return MapDef(name: "Eski Pizzacı", office: Rect.fromLTWH(17, 34, 6, 4),
      leftDoor: const Offset(16.3, 35.5), rightDoor: const Offset(23.7, 35.5), vent: const Offset(20, 33),
      insideLeft: const Offset(18, 36), insideRight: const Offset(22, 36), insideVent: const Offset(20, 35),
      rooms: [Room("Sahne", Rect.fromLTWH(16, 0, 8, 6)), Room("Yemek", Rect.fromLTWH(12, 5, 16, 15)),
        Room("Sol Koridor", Rect.fromLTWH(10, 18, 8, 18)), Room("Sağ Koridor", Rect.fromLTWH(22, 18, 8, 18)),
        Room("Ana Koridor", Rect.fromLTWH(16, 30, 8, 4)), Room("Backstage", Rect.fromLTWH(4, 18, 7, 8)),
        Room("Mutfak", Rect.fromLTWH(29, 18, 7, 8)), Room("Tuvalet", Rect.fromLTWH(4, 28, 7, 8)),
        Room("Depo", Rect.fromLTWH(29, 28, 7, 8))]);
  }

  int gi(dynamic v) => v is num ? v.toInt() : 0;
  double gd(dynamic v) => v is num ? v.toDouble() : 0.0;
  bool gb(dynamic v) => v == true;
  String gs(dynamic v) => v?.toString() ?? "";
}

// ============================= GELİŞMİŞ ÇİZİCİ =============================
class GamePainter extends CustomPainter {
  final MapDef? map;
  final List<EntityView> entities;
  final GQ q;
  final List<Particle> particles;
  final double shake, jumpscare, gameTime;
  final int myRole;
  final Offset localPos;
  final bool flashOn, blackout, leftClosed, rightClosed, camActive;
  final Random rnd;

  GamePainter({
    required this.map,
    required this.entities,
    required this.q,
    required this.particles,
    required this.shake,
    required this.jumpscare,
    required this.myRole,
    required this.localPos,
    required this.flashOn,
    required this.blackout,
    required this.leftClosed,
    required this.rightClosed,
    required this.camActive,
    required this.rnd,
    required this.gameTime,
  });

  @override
  void paint(Canvas c, Size size) {
    c.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF050508));
    if (map == null) return;

    double scale = min(size.width / 40, size.height / 40);
    double ox = (size.width - 40 * scale) / 2, oy = (size.height - 40 * scale) / 2;
    double sx = 0, sy = 0;
    if (q.shake && shake > 0) {
      sx = (rnd.nextDouble() - 0.5) * shake * 10;
      sy = (rnd.nextDouble() - 0.5) * shake * 10;
    }
    c.save();
    c.translate(sx, sy);

    Offset s(Offset p) => Offset(ox + p.dx * scale, oy + p.dy * scale);
    Rect sr(Rect r) => Rect.fromLTWH(ox + r.left * scale, oy + r.top * scale, r.width * scale, r.height * scale);

    for (var room in map!.rooms) {
      Rect r = sr(room.rect);
      if (q.gradFloor) {
        c.drawRect(r, Paint()..shader = RadialGradient(colors: [const Color(0xFF1A1726), const Color(0xFF0E0C16)]).createShader(r));
      } else {
        c.drawRect(r, Paint()..color = const Color(0xFF141220));
      }
      c.drawRect(r, Paint()..color = const Color(0xFF4A3B63)..style = PaintingStyle.stroke..strokeWidth = 1.2);
    }
    Rect off = sr(map!.office);
    c.drawRect(off, Paint()..color = const Color(0xFF2A1F33));
    c.drawRect(off, Paint()..color = const Color(0xFF6A4B83)..style = PaintingStyle.stroke..strokeWidth = 1.5);

    _door(c, s(map!.leftDoor), leftClosed);
    _door(c, s(map!.rightDoor), rightClosed);
    c.drawCircle(s(map!.vent), 5 * scale, Paint()..color = Colors.yellowAccent);

    for (var e in entities) _entity(c, s(Offset(e.x, e.y)), e);

    for (var p in particles) {
      double a = (p.life / p.maxLife).clamp(0.0, 1.0).toDouble();
      c.drawCircle(s(Offset(p.x, p.y)), p.size * scale * a, Paint()..color = p.color.withOpacity(a));
    }

    if (q.darkness) {
      c.saveLayer(Offset.zero & size, Paint());
      c.drawRect(Offset.zero & size, Paint()..color = Color.fromRGBO(0, 0, 0, blackout ? 0.85 : q.darkAlpha));
      Paint hole = Paint()..blendMode = BlendMode.dstOut;
      if (!blackout) {
        c.drawCircle(s(map!.office.center), 60, hole..shader = RadialGradient(colors: [Colors.white, Colors.transparent]).createShader(Rect.fromCircle(center: s(map!.office.center), radius: 60)));
      }
      if (flashOn && !blackout) {
        c.drawCircle(s(map!.office.center), 110, hole..shader = RadialGradient(colors: [Colors.white, Colors.transparent]).createShader(Rect.fromCircle(center: s(map!.office.center), radius: 110)));
      }
      if (myRole == 1) {
        c.drawCircle(s(localPos), 70, hole..shader = RadialGradient(colors: [Colors.white, Colors.transparent]).createShader(Rect.fromCircle(center: s(localPos), radius: 70)));
      }
      c.restore();
    }

    c.restore();

    if (q.vignette) {
      c.drawRect(Offset.zero & size, Paint()..shader = RadialGradient(colors: [Colors.transparent, Colors.black.withOpacity(0.55)]).createShader(Offset.zero & size));
    }

    if (camActive && q.noise) {
      for (int i = 0; i < 40; i++) {
        c.drawRect(Rect.fromLTWH(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height, rnd.nextDouble() * 30, 1), Paint()..color = Colors.white.withOpacity(0.06));
      }
    }

    if (jumpscare > 0) {
      double a = jumpscare.clamp(0.0, 1.0).toDouble();
      c.drawRect(Offset.zero & size, Paint()..color = Colors.red.withOpacity(a * 0.5));
      c.drawCircle(size.center(Offset.zero), 90 * a, Paint()..color = Colors.black);
      c.drawCircle(size.center(Offset.zero) + const Offset(-30, -20), 14, Paint()..color = Colors.red);
      c.drawCircle(size.center(Offset.zero) + const Offset(30, -20), 14, Paint()..color = Colors.red);
    }
  }

  void _door(Canvas c, Offset p, bool closed) {
    Color col = closed ? const Color(0xFFFF5252) : const Color(0xFF69F0AE);
    if (q.glow) c.drawCircle(p, 12, Paint()..color = col.withOpacity(0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    double h = closed ? 14.0 : 5.0;
    c.drawRect(Rect.fromCenter(center: p, width: 8, height: h), Paint()..color = col);
  }

  void _entity(Canvas c, Offset p, EntityView e) {
    Color body = e.role == 0 ? Colors.cyan : e.role == 2 ? Colors.grey : e.color;
    if (q.glow) c.drawCircle(p, 15, Paint()..color = body.withOpacity(0.25)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    c.drawCircle(p, 9, Paint()..color = body);
    c.drawCircle(p + const Offset(-3, -3), 2, Paint()..color = Colors.white);
    c.drawCircle(p + const Offset(3, -3), 2, Paint()..color = Colors.white);
    c.drawCircle(p + const Offset(-3, -3), 1, Paint()..color = Colors.red);
    c.drawCircle(p + const Offset(3, -3), 1, Paint()..color = Colors.red);
  }

  @override
  bool shouldRepaint(covariant GamePainter o) => true;
}
