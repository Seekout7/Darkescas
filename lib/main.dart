import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const GameApp());

class GameApp extends StatelessWidget {
  const GameApp({super.key});

  @override
  Widget build(BuildContext c) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: const GS(),
      );
}

enum Quality { low, medium, high }

class GQ {
  bool glow, vig, noise, shake;
  GQ(this.glow, this.vig, this.noise, this.shake);

  static GQ of(Quality q) => q == Quality.low
      ? GQ(false, false, false, false)
      : q == Quality.medium
          ? GQ(true, true, true, false)
          : GQ(true, true, true, true);
}

class Ep {
  final InternetAddress a;
  final int p;
  Ep(this.a, this.p);
}

class PN {
  final int id;
  String name;
  int charId, role, room, side;
  double x, y, seen, cd, boost, silent, light, vent;
  bool mv, inside, alive;

  PN(
    this.id,
    this.name, {
    this.charId = -1,
    this.role = -1,
    this.x = 0,
    this.y = 0,
    this.room = -1,
    this.side = 0,
    this.seen = 0,
    this.cd = 0,
    this.boost = 0,
    this.silent = 0,
    this.light = 0,
    this.vent = 0,
    this.mv = false,
    this.inside = false,
    this.alive = true,
  });
}

class EV {
  final int id, ch, role, room;
  final double x, y;
  final bool mv, hid, inside;
  final Color color;

  EV(
    this.id,
    this.ch,
    this.role,
    this.x,
    this.y,
    this.room,
    this.mv,
    this.hid,
    this.inside,
    this.color,
  );
}

class Room {
  final String n;
  final Rect r;
  Room(this.n, this.r);
}

class MD {
  final String n;
  final Rect of;
  final Offset ld, rd, vt, il, ir, iv;
  final List<Room> rooms;

  MD(
    this.n,
    this.of,
    this.ld,
    this.rd,
    this.vt,
    this.il,
    this.ir,
    this.iv,
    this.rooms,
  );
}

class CD {
  final String n, act, pas;
  final Color color;
  final double sp, cd;

  CD(this.n, int c, this.sp, this.cd, this.act, this.pas)
      : color = Color(c);
}

class DH {
  final String a;
  final int p;
  String s;
  int c, m;
  double last;

  DH(this.a, this.p, this.s, this.c, this.m, this.last);
}

String gs(dynamic v) {
  if (v is String) return v.trim();
  if (v == null) return '';
  return '$v'.trim();
}

int gi(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? 0;
  return 0;
}

double gd(dynamic v) {
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

bool gb(dynamic v) => v == true;

String sanitizeName(String raw) {
  final clean = raw
      .replaceAll(RegExp(r'[\u0000-\u001F\u007F]'), '')
      .trim();

  if (clean.isEmpty) return 'Oyuncu';
  return clean.length <= 16 ? clean : clean.substring(0, 16);
}

List<CD> mkChars() {
  return [
    CD('Kanat', 0xFFEF5350, 3.6, 10, 'speed', 'speed'),
    CD('Gölge', 0xFF9575CD, 3.2, 14, 'silent', 'ghost'),
    CD('Fare', 0xFF4DB6AC, 3.4, 12, 'ventrush', 'vent'),
    CD('Kas', 0xFFE57373, 2.9, 16, 'doorbreak', 'door'),
    CD('Hacker', 0xFF64B5F6, 3.1, 15, 'camjam', 'quiet'),
    CD('Işık', 0xFFFFD54F, 3.2, 13, 'lightimmune', 'light'),
    CD('Gürültücü', 0xFFA1887F, 3.3, 11, 'noise', 'none'),
    CD('Korku', 0xFF7986CB, 3.0, 17, 'fear', 'none'),
    CD('Dalga', 0xFF81C784, 3.5, 9, 'dash', 'speed'),
    CD('Enerji', 0xFFF06292, 3.0, 14, 'drain', 'none'),
  ];
}

MD mkMap(int i) {
  if (i == 1) {
    final of = Rect.fromLTWH(-25, -20, 50, 40);
    return MD(
      'Depo',
      of,
      const Offset(-27, 0),
      const Offset(27, 0),
      const Offset(0, -22),
      const Offset(-18, 0),
      const Offset(18, 0),
      const Offset(0, -12),
      [
        Room('Sol Koridor', const Rect.fromLTWH(-42, -10, 17, 20)),
        Room('Sağ Koridor', const Rect.fromLTWH(25, -10, 17, 20)),
        Room('Üst Koridor', const Rect.fromLTWH(-12, -35, 24, 15)),
        Room('Sol Depo', const Rect.fromLTWH(-65, -35, 20, 25)),
        Room('Sağ Depo', const Rect.fromLTWH(45, -35, 20, 25)),
        Room('Alt Saha', const Rect.fromLTWH(-20, 20, 40, 18)),
      ],
    );
  }

  final of = Rect.fromLTWH(-20, -15, 40, 30);
  return MD(
    'Ofis',
    of,
    const Offset(-22, 0),
    const Offset(22, 0),
    const Offset(0, -17),
    const Offset(-15, 0),
    const Offset(15, 0),
    const Offset(0, -10),
    [
      Room('Sol Koridor', const Rect.fromLTWH(-35, -8, 15, 16)),
      Room('Sağ Koridor', const Rect.fromLTWH(20, -8, 15, 16)),
      Room('Üst Koridor', const Rect.fromLTWH(-10, -30, 20, 15)),
      Room('Sol Depo', const Rect.fromLTWH(-55, -30, 18, 20)),
      Room('Sağ Depo', const Rect.fromLTWH(37, -30, 18, 20)),
      Room('Alt Bahçe', const Rect.fromLTWH(-15, 15, 30, 15)),
    ],
  );
}

class GS extends StatefulWidget {
  const GS({super.key});

  @override
  State<GS> createState() => _S();
}

class _S extends State<GS> {
  static const int port = 47777;
  static const double night = 240.0;
  static const int maxP = 4;
  static const int maxPacket = 8192;

  final rnd = Random();
  final ipc = TextEditingController();
  final nameC = TextEditingController();

  Timer? loop, slow;
  StreamSubscription<RawSocketEvent>? _sub;
  final fr = ValueNotifier<int>(0);

  Quality quality = Quality.medium;
  late GQ q = GQ.of(quality);
  bool showSet = false;

  int page = 0;
  int myId = -1;
  int guard = -1;
  int myRole = -1;
  int myChar = -1;
  int curMap = 0;
  int camRoom = 0;

  bool isHost = false;
  String myName = '';
  String status = '';
  String endMsg = '';

  RawDatagramSocket? sock;
  InternetAddress? hA;
  int hP = port;

  final Map<int, Ep> eps = {};
  final List<PN> pl = [];
  final List<DH> disc = [];
  final Map<int, EV> rem = {};

  late List<CD> chars;
  MD? map;

  double tD = 0;
  double tP = 0;
  double tH = 0;
  double tL = 0;
  double tS = 0;
  double tN = 0;

  double gt = 0;
  double en = 100;

  bool ldC = true;
  bool rdC = true;
  bool fl = false;
  bool cam = false;
  bool black = false;

  int win = 0;
  int nR = -1;

  double fL = 0;
  double fR = 0;
  double dL = 0;
  double dR = 0;
  double jam = 0;
  double lock = 0;
  double nU = 0;

  Offset pos = Offset.zero;
  bool mv = false;
  bool myIn = false;
  bool myB = false;
  double myCd = 0;

  Offset jt = Offset.zero;
  double jx = 0;
  double jy = 0;
  double shake = 0;
  double jump = 0;

  @override
  void initState() {
    super.initState();
    myName = 'Oyuncu${rnd.nextInt(900) + 100}';
    nameC.text = myName;
    chars = mkChars();
    slow = Timer.periodic(const Duration(seconds: 1), slowT);
  }

  @override
  void dispose() {
    loop?.cancel();
    slow?.cancel();
    _sub?.cancel();

    try {
      sock?.close();
    } catch (_) {}

    ipc.dispose();
    nameC.dispose();
    fr.dispose();
    super.dispose();
  }

  void ui() {
    if (mounted) setState(() {});
  }

  double now() => DateTime.now().millisecondsSinceEpoch / 1000.0;

  void setQ(Quality v) {
    quality = v;
    q = GQ.of(v);
    ui();
  }

  String qN() => quality == Quality.low
      ? 'Düşük'
      : quality == Quality.medium
          ? 'Orta'
          : 'Yüksek';

  Future<bool> hSock() async {
    cN();
    try {
      sock = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
      sock!.broadcastEnabled = true;
      _sub = sock!.listen(onS);
      return true;
    } catch (_) {
      status = 'Host hatası';
      return false;
    }
  }

  Future<bool> cSock() async {
    cN();
    try {
      sock = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      sock!.broadcastEnabled = true;
      _sub = sock!.listen(onS);
      return true;
    } catch (_) {
      status = 'Socket hatası';
      return false;
    }
  }

  void cN() {
    _sub?.cancel();
    try {
      sock?.close();
    } catch (_) {}
    sock = null;
    _sub = null;
  }

  void onS(RawSocketEvent e) {
    if (e != RawSocketEvent.read) return;

    final dg = sock?.receive();
    if (dg == null) return;
    if (dg.data.length > maxPacket) return;

    try {
      final decoded = jsonDecode(utf8.decode(dg.data, allowMalformed: true));
      if (decoded is! Map) return;

      final m = decoded.cast<String, dynamic>();
      final p = m['p'] is Map
          ? (m['p'] as Map).cast<String, dynamic>()
          : <String, dynamic>{};

      final t = gs(m['t']);
      if (isHost) {
        hPk(t, p, dg);
      } else {
        cPk(t, p, dg);
      }
    } catch (_) {}
  }

  void snd(Map d, InternetAddress a, int p) {
    try {
      sock?.send(utf8.encode(jsonEncode(d)), a, p);
    } catch (_) {}
  }

  void toH(Map d) {
    if (hA != null) snd(d, hA!, hP);
  }

  void toA(Map d) {
    if (!isHost) return;
    for (var e in eps.values) {
      snd(d, e.a, e.p);
    }
  }

  int epId(InternetAddress a, int p) {
    for (var e in eps.entries) {
      if (e.value.a.address == a.address && e.value.p == p) return e.key;
    }
    return -1;
  }

  void hPk(String t, Map p, Datagram dg) {
    if (t == 'discover') {
      if (page == 2) {
        snd(
          {
            't': 'hostinfo',
            'p': {
              'name': myName,
              'count': pl.length,
              'map': curMap,
            }
          },
          dg.address,
          dg.port,
        );
      }
      return;
    }

    if (t == 'hello') {
      final ex = epId(dg.address, dg.port);
      if (ex != -1) {
        if (page == 2) {
          snd({'t': 'welcome', 'p': {'id': ex}}, dg.address, dg.port);
        } else {
          snd({'t': 'err', 'p': {'m': 'Lobi kapalı'}}, dg.address, dg.port);
        }
        return;
      }

      if (page != 2 || pl.length >= maxP) {
        snd({'t': 'err', 'p': {'m': 'Katılamazsın'}}, dg.address, dg.port);
        return;
      }

      int id = 1;
      while (pl.any((x) => x.id == id)) id++;

      String nm = gs(p['name']);
      if (nm.isEmpty) nm = 'Oyuncu$id';

      pl.add(PN(id, sanitizeName(nm), seen: now()));
      eps[id] = Ep(dg.address, dg.port);

      snd({'t': 'welcome', 'p': {'id': id}}, dg.address, dg.port);
      lob();
      return;
    }

    final id = epId(dg.address, dg.port);
    if (id == -1) return;

    final me = getP(id);
    if (me != null) me.seen = now();

    if (t == 'ping') return;

    if (t == 'leave') {
      rmP(id);
      return;
    }

    if (t == 'char' && page == 2) {
      selH(id, gi(p['c']));
      return;
    }

    if (t == 'state' && page == 3 && me != null) {
      final nx = gd(p['x']);
      final ny = gd(p['y']);
      final target = Offset(nx, ny);
      final old = Offset(me.x, me.y);

      // Basit anti-teleport:
      // 10 Hz state + network jitter için toleranslı ama büyük sıçramaları reddeder.
      if ((target - old).distance <= 6.0 && walkF(target, me)) {
        me.x = nx;
        me.y = ny;
        me.mv = gb(p['mv']);
        me.room = roomAt(target);
      }
      return;
    }

    if (t == 'act' && page == 3) act(id, gs(p['a']));
  }

  void cPk(String t, Map p, Datagram dg) {
    tH = now();

    if (t == 'hostinfo' && page == 1) {
      DH? f;
      for (var d in disc) {
        if (d.a == dg.address.address && d.p == dg.port) f = d;
      }

      if (f == null) {
        disc.add(DH(
          dg.address.address,
          dg.port,
          gs(p['name']),
          gi(p['count']),
          gi(p['map']),
          now(),
        ));
      } else {
        f.s = gs(p['name']);
        f.c = gi(p['count']);
        f.m = gi(p['map']);
        f.last = now();
      }

      ui();
      return;
    }

    if (t == 'welcome') {
      myId = gi(p['id']);
      page = 2;
      status = 'Lobidesin';
      ui();
      return;
    }

    if (t == 'lobby') {
      pl.clear();
      curMap = gi(p['map']);

      if (p['players'] is List) {
        for (final it in p['players'] as List) {
          if (it is! Map) continue;
          final q2 = it.cast<String, dynamic>();
          pl.add(PN(
            gi(q2['id']),
            sanitizeName(gs(q2['name'])),
            charId: gi(q2['char']),
          ));
        }
      }

      if (page == 2) ui();
      return;
    }

    if (t == 'start') {
      startFrom(p);
      return;
    }

    if (t == 'snap') {
      snap(p);
      return;
    }

    if (t == 'over') {
      endL(gi(p['w']), gs(p['m']));
      return;
    }

    if (t == 'err') {
      status = gs(p['m']);
      page = 0;
      cN();
      ui();
      return;
    }

    if (t == 'closed') {
      cN();
      page = 0;
      status = 'Host kapattı';
      ui();
      return;
    }
  }

  Future<void> hostGame() async {
    if (!await hSock()) {
      ui();
      return;
    }
    if (!mounted) return;

    isHost = true;
    myName = sanitizeName(nameC.text);
    myId = 0;
    guard = -1;
    myRole = -1;
    myChar = -1;
    curMap = 0;

    pl.clear();
    eps.clear();
    rem.clear();

    pl.add(PN(0, myName, seen: now()));

    page = 2;
    status = 'Host hazır';
    lob();
    ui();
  }

  Future<void> openDisc() async {
    if (!await cSock()) {
      ui();
      return;
    }
    if (!mounted) return;

    isHost = false;
    myId = -1;
    disc.clear();
    page = 1;
    d0();
    tD = now();
    ui();
  }

  void d0() {
    try {
      snd({'t': 'discover'}, InternetAddress('255.255.255.255'), port);
      snd({'t': 'discover'}, InternetAddress.loopbackIPv4, port);
    } catch (_) {}
  }

  Future<void> joinIp() async {
    final addr = InternetAddress.tryParse(ipc.text.trim());
    if (addr == null) {
      status = 'Geçerli IP gir';
      ui();
      return;
    }

    if (!await cSock()) {
      ui();
      return;
    }
    if (!mounted) return;

    isHost = false;
    myId = -1;
    hA = addr;
    hP = port;

    hello();

    page = 0;
    status = 'Bağlanıyor';
    tH = now();
    ui();
  }

  Future<void> joinD(DH d) async {
    final addr = InternetAddress.tryParse(d.a);
    if (addr == null) {
      status = 'Geçersiz host';
      ui();
      return;
    }

    if (!await cSock()) {
      ui();
      return;
    }
    if (!mounted) return;

    isHost = false;
    myId = -1;
    hA = addr;
    hP = d.p;

    hello();

    page = 0;
    status = 'Bağlanıyor';
    tH = now();
    ui();
  }

  void hello() => toH({
        't': 'hello',
        'p': {'name': myName}
      });

  void menu() {
    if (isHost) {
      toA({'t': 'closed'});
    } else {
      toH({'t': 'leave'});
    }

    loop?.cancel();
    loop = null;
    cN();

    isHost = false;
    page = 0;
    myId = -1;
    guard = -1;
    myRole = -1;
    myChar = -1;
    win = 0;
    hA = null;

    jx = 0;
    jy = 0;
    camRoom = 0;

    pl.clear();
    eps.clear();
    rem.clear();
    disc.clear();

    status = 'Ana menü';
    ui();
  }

  void selC(int c) {
    if (page != 2) return;
    if (isHost) {
      selH(myId, c);
    } else {
      toH({'t': 'char', 'p': {'c': c}});
    }
  }

  void selH(int id, int c) {
    if (page != 2 || c < 0 || c >= chars.length) return;

    final me = getP(id);
    if (me == null) return;

    for (var o in pl) {
      if (o.id != id && o.charId == c) {
        status = 'Seçili';
        lob();
        return;
      }
    }

    me.charId = c;
    lob();
  }

  void setM(int m) {
    if (!isHost || page != 2) return;
    curMap = m < 0 ? 0 : (m > 1 ? 1 : m);
    lob();
  }

  void lob() {
    if (!isHost) return;

    toA({
      't': 'lobby',
      'p': {
        'map': curMap,
        'players': pl
            .map((p) => {
                  'id': p.id,
                  'name': p.name,
                  'char': p.charId,
                })
            .toList(),
      }
    });

    tL = now();
    ui();
  }

  void startHost() {
    if (!isHost || page != 2 || pl.length < 2) {
      status = 'En az 2 oyuncu';
      ui();
      return;
    }

    map = mkMap(curMap);
    reset();

    final ids = pl.map((e) => e.id).toList();
    guard = ids[rnd.nextInt(ids.length)];

    final used = <int>[];

    for (var p in pl) {
      if (p.id == guard) {
        p.role = 0;
        p.charId = -1;
        p.x = map!.of.center.dx;
        p.y = map!.of.center.dy;
        p.inside = true;
        p.room = -2;
      } else {
        p.role = 1;

        if (p.charId < 0 ||
            p.charId >= chars.length ||
            used.contains(p.charId)) {
          p.charId = freeC(used);
        }

        used.add(p.charId);

        final s = rndS();
        p.x = s.dx;
        p.y = s.dy;
        p.inside = false;
        p.room = roomAt(s);
      }

      p.alive = true;
      p.mv = false;
      p.cd = 0;
      p.boost = 0;
      p.silent = 0;
      p.light = 0;
      p.vent = 0;

      if (p.id == myId) {
        myRole = p.role;
        myChar = p.charId;
        pos = Offset(p.x, p.y);
        myIn = p.inside;
      }
    }

    toA({
      't': 'start',
      'p': {
        'map': curMap,
        'guard': guard,
        'players': pl
            .map((p) => {
                  'id': p.id,
                  'char': p.charId,
                  'role': p.role,
                  'x': p.x,
                  'y': p.y,
                })
            .toList(),
      }
    });

    page = 3;
    startLoop();
    ui();
  }

  void startFrom(Map p) {
    myRole = -1;
    myChar = -1;

    reset();

    curMap = gi(p['map']);
    guard = gi(p['guard']);
    map = mkMap(curMap);

    pl.clear();
    rem.clear();

    if (p['players'] is List) {
      for (final it in p['players'] as List) {
        if (it is! Map) continue;

        final q2 = it.cast<String, dynamic>();

        final id = gi(q2['id']);
        final ch = gi(q2['char']);
        final rl = gi(q2['role']);
        final x = gd(q2['x']);
        final y = gd(q2['y']);

        if (id == myId) {
          myRole = rl;
          myChar = ch;
          pos = Offset(x, y);
          myIn = rl == 0;
        } else {
          rem[id] = EV(
            id,
            ch,
            rl,
            x,
            y,
            rl == 0 ? -2 : roomAt(Offset(x, y)),
            false,
            false,
            rl == 0,
            col(ch),
          );
        }
      }
    }

    if (myRole == -1) {
      status = 'Hatalı başlangıç';
      page = 0;
      cN();
      ui();
      return;
    }

    page = 3;
    startLoop();
    ui();
  }

  void reset() {
    gt = 0;
    en = 100;
    ldC = true;
    rdC = true;
    fl = false;
    cam = false;
    black = false;
    win = 0;
    endMsg = '';

    fL = 0;
    fR = 0;
    dL = 0;
    dR = 0;
    jam = 0;
    lock = 0;
    nR = -1;
    nU = 0;

    mv = false;
    myIn = myRole == 0;
    myCd = 0;
    myB = false;
    camRoom = 0;
    shake = 0;
    jump = 0;
    jx = 0;
    jy = 0;
  }

  void startLoop() {
    loop?.cancel();
    loop = Timer.periodic(const Duration(milliseconds: 16), tick);
  }

  void tick(Timer t) {
    if (page != 3) return;

    const double dt = 1 / 60;

    if (win == 0) {
      if (myRole == 0 || myRole == 1) moveL(dt);

      if (isHost) {
        hostU(dt);
      } else if ((myRole == 0 || myRole == 1) && now() - tS > 0.1) {
        sendS();
      }
    }

    shake = max(0.0, shake - dt * 3);
    jump = max(0.0, jump - dt);
    fr.value++;
  }

  void slowT(Timer t) {
    if (!mounted) return;

    final n = now();

    if (page == 1) {
      if (n - tD > 2) {
        tD = n;
        d0();
      }

      final before = disc.length;
      disc.removeWhere((d) => n - d.last > 6);
      if (before != disc.length) ui();
    }

    if (!isHost && page == 0 && hA != null && n - tH > 10) {
      hA = null;
      cN();
      status = 'Bağlantı zaman aşımı';
      ui();
      return;
    }

    if (!isHost && (page == 2 || page == 3)) {
      if (n - tH > 10) {
        menu();
        return;
      }

      if (n - tP > 2) {
        tP = n;
        toH({'t': 'ping'});
      }
    }

    if (isHost && page == 2 && n - tL > 2) lob();

    if (isHost && (page == 2 || page == 3)) {
      for (int i = pl.length - 1; i >= 0; i--) {
        if (pl[i].id != 0 && n - pl[i].seen > 10) rmP(pl[i].id);
      }
    }
  }

  void hostU(double dt) {
    if (win != 0 || map == null) return;

    gt += dt;

    double dr = 0.08;
    if (ldC) dr += 0.4;
    if (rdC) dr += 0.4;
    if (fl) dr += 0.35;
    if (cam) dr += 0.5;

    en -= dr * dt;

    if (en <= 0 && !black) {
      en = 0;
      black = true;
      ldC = false;
      rdC = false;
      fl = false;
      cam = false;
    }

    if (black) en = 0;

    if (gt >= night) {
      endG(1, 'Güvenlik dayandı');
      return;
    }

    final me = getP(myId);
    if (me != null) {
      myIn = me.inside;
      myCd = max(0.0, me.cd - gt);
      myB = me.boost > gt;
    }

    if (now() - tN > 0.1) {
      tN = now();
      bSnap();
    }
  }

  void moveL(double dt) {
    if (page != 3 || win != 0 || map == null) return;
    if (myRole != 0 && myRole != 1) return;

    final d = Offset(jx, jy);
    mv = d.distance > 0.1;

    if (mv) {
      var dir = d;
      if (dir.distance > 1) dir = dir / dir.distance;

      final sp = spd();
      final next = pos + dir * sp * dt;

      if (walk(next)) {
        pos = next;
      } else {
        final nx = pos + Offset(dir.dx * sp * dt, 0);
        if (walk(nx)) pos = nx;

        final ny = pos + Offset(0, dir.dy * sp * dt);
        if (walk(ny)) pos = ny;
      }
    }

    if (isHost) {
      final me = getP(myId);
      if (me != null) {
        me.x = pos.dx;
        me.y = pos.dy;
        me.mv = mv;
        me.room = roomAt(pos);
      }
    }
  }

  double spd() {
    double s = 3.0;

    if (myChar >= 0 && myChar < chars.length) {
      s = chars[myChar].sp;
      if (chars[myChar].pas == 'speed') s *= 1.15;
    }

    if (myB) s *= 1.6;
    if (myIn) s *= 0.85;

    return s;
  }

  void sendS() {
    tS = now();
    toH({
      't': 'state',
      'p': {
        'x': pos.dx,
        'y': pos.dy,
        'mv': mv,
      }
    });
  }

  void gAct(String a) {
    if (page != 3 || myRole != 0 || win != 0) return;

    if (isHost) {
      act(myId, a);
    } else {
      toH({'t': 'act', 'p': {'a': a}});
    }
  }

  void inter() {
    if (page != 3 || myRole != 1 || win != 0) return;

    final a = ctx();
    if (a == 'none') return;

    if (isHost) {
      act(myId, a);
    } else {
      toH({'t': 'act', 'p': {'a': a}});
    }
  }

  void abil() {
    if (page != 3 || myRole != 1 || win != 0 || myCd > 0) return;

    if (isHost) {
      act(myId, 'ability');
    } else {
      toH({'t': 'act', 'p': {'a': 'ability'}});
    }
  }

  String ctx() {
    if (page != 3 || map == null || myRole != 1) return 'none';

    if (myIn) return 'attack';

    if ((pos - map!.ld).distance < 3) {
      return ldC ? 'forceL' : 'enterL';
    }

    if ((pos - map!.rd).distance < 3) {
      return rdC ? 'forceR' : 'enterR';
    }

    if ((pos - map!.vt).distance < 3) return 'vent';

    return 'none';
  }

  void act(int id, String a) {
    if (page != 3 || win != 0 || map == null) return;

    final p = getP(id);
    if (p == null || !p.alive) return;

    p.seen = now();

    if (id == guard) {
      gAction(a);
      return;
    }

    if (p.role != 1 || p.charId < 0 || p.charId >= chars.length) return;

    final c = chars[p.charId];

    if (a == 'ability') {
      if (gt < p.cd) return;
      p.cd = gt + c.cd;
      applyA(p, c);
    } else if (a == 'enterL') {
      ent(p, 0);
    } else if (a == 'enterR') {
      ent(p, 1);
    } else if (a == 'forceL') {
      forc(p, 0, c);
    } else if (a == 'forceR') {
      forc(p, 1, c);
    } else if (a == 'vent') {
      ven(p, c);
    } else if (a == 'attack') {
      atk(p, c);
    }
  }

  void gAction(String a) {
    if (black || lock > gt) return;

    if (a == 'doorL' && fL <= gt) {
      ldC = !ldC;
      dL = 0;
    } else if (a == 'doorR' && fR <= gt) {
      rdC = !rdC;
      dR = 0;
    } else if (a == 'flash') {
      fl = !fl;
    } else if (a == 'cam') {
      cam = !cam;
    }
  }

  void ent(PN p, int s) {
    if (p.inside || map == null) return;

    final d = s == 0 ? map!.ld : map!.rd;
    if ((Offset(p.x, p.y) - d).distance > 3) return;

    if (s == 0 ? ldC : rdC) return;

    p.inside = true;
    p.side = s;
    p.room = -2;

    final i = s == 0 ? map!.il : map!.ir;
    p.x = i.dx;
    p.y = i.dy;

    if (p.id == myId) {
      myIn = true;
      pos = i;
    }
  }

  void forc(PN p, int s, CD c) {
    if (p.inside || map == null) return;

    final d = s == 0 ? map!.ld : map!.rd;
    if ((Offset(p.x, p.y) - d).distance > 3) return;

    if (!(s == 0 ? ldC : rdC)) return;
    if ((s == 0 ? fL : fR) > gt) return;

    double dm = 25;
    if (c.pas == 'door') dm *= 1.5;

    shake = max(shake, 0.5);

    if (s == 0) {
      dL += dm;
      if (dL >= 100) {
        dL = 0;
        ldC = false;
        fL = gt + 5;
      }
    } else {
      dR += dm;
      if (dR >= 100) {
        dR = 0;
        rdC = false;
        fR = gt + 5;
      }
    }
  }

  void ven(PN p, CD c) {
    if (p.inside || map == null) return;

    if ((Offset(p.x, p.y) - map!.vt).distance > 3) return;

    p.vent += (c.pas == 'vent' ? 0.6 : 0.34);

    if (p.vent >= 1) {
      p.vent = 0;
      p.inside = true;
      p.side = 2;
      p.room = -2;
      p.x = map!.iv.dx;
      p.y = map!.iv.dy;

      if (p.id == myId) {
        myIn = true;
        pos = Offset(p.x, p.y);
      }
    }
  }

  void atk(PN p, CD c) {
    if (!p.inside || map == null) return;

    bool rep = false;

    if (fl && !black && p.light < gt) {
      rep = (c.pas == 'light') ? rnd.nextBool() : true;
    }

    if (rep) {
      final o = outS(p.side);

      p.inside = false;
      p.vent = 0;
      p.x = o.dx;
      p.y = o.dy;
      p.room = roomAt(o);
      p.cd = max(p.cd, gt + 2);

      if (p.id == myId) {
        myIn = false;
        pos = o;
      }
    } else {
      jump = 1.2;
      shake = 1.5;
      endG(2, '${p.name} yakaladı');
    }
  }

  Offset outS(int s) {
    if (map == null) return Offset.zero;
    if (s == 0) return map!.ld;
    if (s == 1) return map!.rd;
    return map!.vt;
  }

  void applyA(PN p, CD c) {
    if (map == null) return;

    if (c.act == 'speed') {
      p.boost = gt + 4;
    } else if (c.act == 'dash') {
      final d = map!.of.center - Offset(p.x, p.y);
      if (d.distance > 0.1) {
        final t = Offset(p.x, p.y) + (d / d.distance) * 4;
        if (walkF(t, p)) {
          p.x = t.dx;
          p.y = t.dy;
          if (p.id == myId) pos = t;
        }
      }
    } else if (c.act == 'camjam') {
      jam = gt + 5;
    } else if (c.act == 'doorbreak') {
      if ((Offset(p.x, p.y) - map!.ld).distance < 3.5) {
        ldC = false;
        fL = gt + 5;
      } else if ((Offset(p.x, p.y) - map!.rd).distance < 3.5) {
        rdC = false;
        fR = gt + 5;
      }
    } else if (c.act == 'ventrush') {
      if ((Offset(p.x, p.y) - map!.vt).distance < 3.5) {
        p.inside = true;
        p.side = 2;
        p.room = -2;
        p.x = map!.iv.dx;
        p.y = map!.iv.dy;

        if (p.id == myId) {
          myIn = true;
          pos = Offset(p.x, p.y);
        }
      }
    } else if (c.act == 'drain') {
      if ((Offset(p.x, p.y) - map!.of.center).distance < 10) {
        en = max(0.0, en - 10);
      }
    } else if (c.act == 'lightimmune') {
      p.light = gt + 5;
    } else if (c.act == 'silent') {
      p.silent = gt + 5;
    } else if (c.act == 'noise') {
      if (map!.rooms.isNotEmpty) {
        nR = rnd.nextInt(map!.rooms.length);
        nU = gt + 3;
      }
    } else if (c.act == 'fear') {
      lock = gt + 3;
    }
  }

  bool walkF(Offset o, PN p) {
    if (map == null) return false;

    if (p.role == 0) return map!.of.contains(o);
    if (p.inside) return map!.of.contains(o);

    if (map!.of.contains(o)) return false;

    for (var r in map!.rooms) {
      if (r.r.contains(o)) return true;
    }

    return false;
  }

  bool walk(Offset o) {
    if (map == null) return false;

    if (myRole == 0) return map!.of.contains(o);
    if (myIn) return map!.of.contains(o);

    if (map!.of.contains(o)) return false;

    for (var r in map!.rooms) {
      if (r.r.contains(o)) return true;
    }

    return false;
  }

  bool _hidden(PN p) {
    if (p.role != 1 || p.charId < 0 || p.charId >= chars.length) return false;

    if (p.silent > gt) return true;

    final pas = chars[p.charId].pas;
    return pas == 'quiet' || pas == 'ghost';
  }

  void bSnap() {
    if (!isHost || page != 3) return;

    final ents = <Map>[];

    for (var p in pl) {
      if (!p.alive) continue;

      ents.add({
        'id': p.id,
        'ch': p.charId,
        'rl': p.role,
        'x': p.x,
        'y': p.y,
        'rm': p.room,
        'mv': p.mv,
        'io': p.inside,
        'cd': max(0.0, p.cd - gt),
        'hid': _hidden(p),
        'sp': p.boost > gt,
      });
    }

    toA({
      't': 'snap',
      'p': {
        't': gt,
        'e': en.round(),
        'ld': ldC,
        'rd': rdC,
        'fl': fl,
        'cam': cam,
        'jam': max(0.0, jam - gt),
        'black': black,
        'w': win,
        'm': endMsg,
        'g': guard,
        'nr': nR,
        'nu': nU,
        'ents': ents,
      }
    });
  }

  void snap(Map p) {
    if (page != 3) return;

    gt = gd(p['t']);
    en = gd(p['e']);
    ldC = gb(p['ld']);
    rdC = gb(p['rd']);
    fl = gb(p['fl']);
    cam = gb(p['cam']);
    jam = gt + gd(p['jam']);
    black = gb(p['black']);
    guard = gi(p['g']);
    nR = gi(p['nr']);
    nU = gd(p['nu']);

    final w = gi(p['w']);
    if (w > 0) {
      final m = gs(p['m']);
      endL(w, m.isEmpty ? 'Oyun bitti' : m);
      return;
    }

    rem.clear();

    if (p['ents'] is List) {
      for (final it in p['ents'] as List) {
        if (it is! Map) continue;

        final e = it.cast<String, dynamic>();
        final id = gi(e['id']);

        if (id == myId) {
          myIn = gb(e['io']);
          myCd = gd(e['cd']);
          myB = gb(e['sp']);

          final hp = Offset(gd(e['x']), gd(e['y']));
          if ((pos - hp).distance > 5) pos = hp;

          continue;
        }

        rem[id] = EV(
          id,
          gi(e['ch']),
          gi(e['rl']),
          gd(e['x']),
          gd(e['y']),
          gi(e['rm']),
          gb(e['mv']),
          gb(e['hid']),
          gb(e['io']),
          col(gi(e['ch'])),
        );
      }
    }

    tH = now();
  }

  void endG(int w, String m) {
    if (page != 3 || win != 0) return;

    win = w;
    endMsg = m;

    toA({'t': 'over', 'p': {'w': w, 'm': m}});
    endL(w, m);
  }

  void endL(int w, String m) {
    if (page == 4) return;

    win = w;
    endMsg = m;
    page = 4;

    loop?.cancel();
    loop = null;

    ui();
  }

  void rmP(int id) {
    if (id == 0) return;

    if (page == 3 && id == guard) {
      pl.removeWhere((p) => p.id == id);
      eps.remove(id);
      endG(2, 'Güvenlik ayrıldı');
      return;
    }

    pl.removeWhere((p) => p.id == id);
    eps.remove(id);

    if (page == 2) {
      lob();
    } else if (page == 3 && !pl.any((p) => p.role == 1 && p.alive)) {
      endG(1, 'Kalmadı');
    }
  }

  PN? getP(int id) {
    for (var p in pl) {
      if (p.id == id) return p;
    }
    return null;
  }

  int roomAt(Offset o) {
    if (map == null) return -1;

    if (map!.of.contains(o)) return -2;

    for (int i = 0; i < map!.rooms.length; i++) {
      if (map!.rooms[i].r.contains(o)) return i;
    }

    return -1;
  }

  Offset rndS() {
    if (map == null || map!.rooms.isEmpty) return const Offset(-30, 0);

    final r = map!.rooms[rnd.nextInt(map!.rooms.length)].r;

    double mx = min(1.0, r.width * 0.25);
    double my = min(1.0, r.height * 0.25);

    double x1 = r.left + mx;
    double x2 = r.right - mx;
    double y1 = r.top + my;
    double y2 = r.bottom - my;

    if (x2 < x1) x1 = x2 = r.center.dx;
    if (y2 < y1) y1 = y2 = r.center.dy;

    return Offset(
      x1 + rnd.nextDouble() * (x2 - x1),
      y1 + rnd.nextDouble() * (y2 - y1),
    );
  }

  int freeC(List<int> u) {
    for (int i = 0; i < 100; i++) {
      int c = rnd.nextInt(chars.length);
      if (!u.contains(c)) return c;
    }

    for (int c = 0; c < chars.length; c++) {
      if (!u.contains(c)) return c;
    }

    return 0;
  }

  String cn(int id) => (id < 0 || id >= chars.length) ? '?' : chars[id].n;

  Color col(int id) =>
      (id < 0 || id >= chars.length) ? Colors.white : chars[id].color;

  List<EV> views() {
    final v = <EV>[];

    if (isHost) {
      for (var p in pl) {
        if (!p.alive) continue;

        v.add(EV(
          p.id,
          p.charId,
          p.role,
          p.x,
          p.y,
          p.room,
          p.mv,
          _hidden(p),
          p.inside,
          p.role == 0 ? Colors.cyan : col(p.charId),
        ));
      }
    } else {
      rem.forEach((id, e) {
        if (id != myId) v.add(e);
      });

      if (myId != -1 && myRole != -1) {
        v.add(EV(
          myId,
          myChar,
          myRole,
          pos.dx,
          pos.dy,
          roomAt(pos),
          mv,
          false,
          myIn,
          myRole == 0 ? Colors.cyan : col(myChar),
        ));
      }
    }

    return v;
  }

  String det() {
    if (map == null || camRoom < 0 || camRoom >= map!.rooms.length) return '';

    if (jam > gt) return 'PARAZİT';

    final names = <String>[];

    for (var v in views()) {
      if (v.role != 0 &&
          !v.inside &&
          v.room == camRoom &&
          v.mv &&
          !v.hid) {
        names.add(cn(v.ch));
      }
    }

    String t = '';
    if (nR == camRoom && nU > gt) t += 'SES!\n';

    t += names.isEmpty ? 'Temiz.' : 'Hareket: ${names.join(', ')}';
    return t;
  }

  String clock() {
    final progress = (gt / night).clamp(0.0, 1.0);
    final totalMinutes = (progress * 24 * 60).toInt();

    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;

    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gece Güvenliği'),
        actions: [
          PopupMenuButton<Quality>(
            initialValue: quality,
            onSelected: setQ,
            itemBuilder: (context) => const [
              PopupMenuItem(value: Quality.low, child: Text('Düşük')),
              PopupMenuItem(value: Quality.medium, child: Text('Orta')),
              PopupMenuItem(value: Quality.high, child: Text('Yüksek')),
            ],
          ),
        ],
      ),
      body: SafeArea(child: _page()),
    );
  }

  Widget _page() {
    switch (page) {
      case 0:
        return _page0();
      case 1:
        return _page1();
      case 2:
        return _page2();
      case 3:
        return _page3();
      case 4:
        return _page4();
      default:
        return _page0();
    }
  }

  Widget _page0() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Gece Güvenliği',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        TextField(
          controller: nameC,
          maxLength: 16,
          decoration: const InputDecoration(labelText: 'Ad'),
          onChanged: (v) => myName = sanitizeName(v),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => hostGame(),
          child: const Text('Host Ol'),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => openDisc(),
          child: const Text('Lobi Ara'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: ipc,
          decoration: const InputDecoration(
            labelText: 'Host IP',
            hintText: '192.168.1.10',
          ),
          keyboardType: TextInputType.url,
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () => joinIp(),
          child: const Text('IP ile Katıl'),
        ),
        const SizedBox(height: 16),
        if (status.isNotEmpty)
          Text(status, style: const TextStyle(color: Colors.amber)),
      ],
    );
  }

  Widget _page1() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text('Bulunan Hostlar (${disc.length})'),
        ),
        Expanded(
          child: disc.isEmpty
              ? const Center(child: Text('Host aranıyor...'))
              : ListView(
                  children: disc
                      .map((d) => ListTile(
                            title: Text(d.s.isEmpty ? 'Host' : d.s),
                            subtitle: Text('${d.a}:${d.p} - ${d.c}/$maxP'),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => joinD(d),
                          ))
                      .toList(),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: ElevatedButton(
            onPressed: menu,
            child: const Text('Geri'),
          ),
        ),
      ],
    );
  }

  Widget _page2() {
    final me = getP(myId);
    final selected = me?.charId ?? -1;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Harita: ${curMap == 0 ? 'Ofis' : 'Depo'}'),
        if (isHost)
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setM(0),
                  child: const Text('Ofis'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => setM(1),
                  child: const Text('Depo'),
                ),
              ),
            ],
          ),
        const SizedBox(height: 12),
        Text('Oyuncular (${pl.length}/$maxP)'),
        ...pl.map((p) => ListTile(
              dense: true,
              leading: CircleAvatar(
                backgroundColor:
                    p.id == guard ? Colors.cyan : col(p.charId),
                child: Text('${p.id}'),
              ),
              title: Text(p.name),
              subtitle: Text(
                p.charId < 0 ? 'Karakter seçilmedi' : cn(p.charId),
              ),
              trailing: p.id == guard ? const Icon(Icons.shield) : null,
            )),
        const SizedBox(height: 12),
        const Text('Karakterler'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: chars.asMap().entries.map((e) {
            final i = e.key;
            final taken =
                pl.any((p) => p.id != myId && p.charId == i);

            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: selected == i ? Colors.blue : null,
                disabledBackgroundColor: Colors.black26,
              ),
              onPressed: taken ? null : () => selC(i),
              child: Text(e.value.n),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        if (isHost)
          ElevatedButton(
            onPressed: pl.length >= 2 ? startHost : null,
            child: const Text('Oyunu Başlat'),
          ),
        if (status.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(status, style: const TextStyle(color: Colors.amber)),
          ),
      ],
    );
  }

  Widget _page3() {
    if (map == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ValueListenableBuilder<int>(
      valueListenable: fr,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            final m = map!;
            const scale = 7.0;
            final worldCenter = m.of.center;

            Offset toScreen(Offset w) => Offset(
                  size.width / 2 + (w.dx - worldCenter.dx) * scale,
                  size.height / 2 + (w.dy - worldCenter.dy) * scale,
                );

            return Stack(
              children: [
                Positioned.fill(
                  child: Container(color: const Color(0xFF0D1117)),
                ),
                ..._mapWidgets(m, toScreen, scale),
                ..._playerWidgets(toScreen),
                Positioned(top: 8, left: 8, right: 8, child: _hud()),
                if (cam && myRole == 0)
                  Positioned(top: 64, left: 8, right: 8, child: _cameraPanel(m)),
                Positioned(left: 16, bottom: 16, child: _joystick()),
                Positioned(right: 16, bottom: 16, child: _actionButtons()),
              ],
            );
          },
        );
      },
    );
  }

  Widget _page4() {
    String title = win == 1
        ? 'Güvenlik kazandı'
        : win == 2
            ? 'Saldırganlar kazandı'
            : 'Oyun bitti';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(endMsg),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: menu,
            child: const Text('Ana Menü'),
          ),
        ],
      ),
    );
  }

  List<Widget> _mapWidgets(
    MD m,
    Offset Function(Offset) toScreen,
    double scale,
  ) {
    return [
      _rectWidget(m.of, toScreen, scale, const Color(0xFF1F2A30)),
      for (final r in m.rooms)
        _rectWidget(r.r, toScreen, scale, const Color(0xFF232D33)),
      _pointWidget(m.ld, toScreen, 'L', Colors.amber),
      _pointWidget(m.rd, toScreen, 'R', Colors.amber),
      _pointWidget(m.vt, toScreen, 'V', Colors.orangeAccent),
    ];
  }

  List<Widget> _playerWidgets(Offset Function(Offset) toScreen) {
    final list = views();
    final visible = list
        .where((v) => isHost || v.id == myId || !v.hid)
        .toList();

    return visible.map((v) {
      final p = toScreen(Offset(v.x, v.y));

      Widget marker = Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: v.color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Center(
          child: Text(
            v.role == 0 ? 'G' : '${v.id}',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      );

      if (v.hid) {
        marker = Opacity(opacity: 0.35, child: marker);
      }

      return Positioned(
        left: p.dx - 12,
        top: p.dy - 12 - (v.id == myId ? jump * 6 : 0),
        child: marker,
      );
    }).toList();
  }

  Widget _hud() {
    final camInfo = cam && myRole == 0 ? det() : '';

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Enerji: ${en.round()} | Süre: ${clock()} | ${qN()}',
            style: const TextStyle(fontSize: 12),
          ),
          if (status.isNotEmpty)
            Text(
              status,
              style: const TextStyle(fontSize: 11, color: Colors.amber),
            ),
          if (camInfo.isNotEmpty)
            Text(
              camInfo,
              style: const TextStyle(fontSize: 11, color: Colors.cyan),
            ),
        ],
      ),
    );
  }

  Widget _cameraPanel(MD m) {
    if (m.rooms.isEmpty) return const SizedBox.shrink();

    final val =
        camRoom >= 0 && camRoom < m.rooms.length ? camRoom : 0;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Text('Kamera:', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: val,
            dense: true,
            items: m.rooms.asMap().entries
                .map((e) => DropdownMenuItem<int>(
                      value: e.key,
                      child: Text(
                        e.value.n,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) {
                camRoom = v;
                ui();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _actionButtons() {
    if (win != 0) return const SizedBox.shrink();

    if (myRole == 0) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: black ? null : () => gAct('doorL'),
                child: Text(ldC ? 'Sol Aç' : 'Sol Kapat'),
              ),
              ElevatedButton(
                onPressed: black ? null : () => gAct('doorR'),
                child: Text(rdC ? 'Sağ Aç' : 'Sağ Kapat'),
              ),
              ElevatedButton(
                onPressed: black ? null : () => gAct('flash'),
                child: Text(fl ? 'Flash Kapat' : 'Flash Aç'),
              ),
              ElevatedButton(
                onPressed: black ? null : () => gAct('cam'),
                child: Text(cam ? 'Cam Kapat' : 'Cam Aç'),
              ),
            ],
          ),
        ],
      );
    }

    if (myRole == 1) {
      final a = ctx();

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ElevatedButton(
            onPressed: a == 'none' ? null : inter,
            child: Text(_ctxLabel(a)),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: myCd > 0 ? null : abil,
            child: Text(
              myCd > 0 ? 'CD ${myCd.toStringAsFixed(1)}' : 'Yetenek',
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _joystick() {
    return GestureDetector(
      onPanStart: (d) => _updateJoystick(d.localPosition),
      onPanUpdate: (d) => _updateJoystick(d.localPosition),
      onPanEnd: (_) {
        jx = 0;
        jy = 0;
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: const BoxDecoration(
          color: Colors.white10,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  void _updateJoystick(Offset local) {
    const double radius = 50.0;
    final center = Offset(60, 60);

    var v = local - center;
    if (v.distance > radius) {
      v = v / v.distance * radius;
    }

    jx = min(1.0, max(-1.0, v.dx / radius));
    jy = min(1.0, max(-1.0, v.dy / radius));
  }

  String _ctxLabel(String a) {
    switch (a) {
      case 'attack':
        return 'Saldır';
      case 'enterL':
        return 'Sol Kapıdan Gir';
      case 'enterR':
        return 'Sağ Kapıdan Gir';
      case 'forceL':
        return 'Sol Kapıyı Zorla';
      case 'forceR':
        return 'Sağ Kapıyı Zorla';
      case 'vent':
        return 'Havalandırma';
      default:
        return 'Etkileşim';
    }
  }

  Widget _rectWidget(
    Rect world,
    Offset Function(Offset) toScreen,
    double scale,
    Color color,
  ) {
    final tl = toScreen(world.topLeft);

    return Positioned(
      left: tl.dx,
      top: tl.dy,
      width: world.width * scale,
      height: world.height * scale,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          border: Border.all(color: Colors.white24),
        ),
      ),
    );
  }

  Widget _pointWidget(
    Offset world,
    Offset Function(Offset) toScreen,
    String label,
    Color color,
  ) {
    final p = toScreen(world);

    return Positioned(
      left: p.dx - 10,
      top: p.dy - 10,
      width: 20,
      height: 20,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}
