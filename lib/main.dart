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
  final String n, emo, act, pas, lore;
  final Color color;
  final double sp, cd;

  CD(this.n, this.emo, int c, this.sp, this.cd, this.act, this.pas, this.lore)
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
  final clean = raw.replaceAll(RegExp(r'[\u0000-\u001F\u007F]'), '').trim();
  if (clean.isEmpty) return 'Oyuncu';
  return clean.length <= 16 ? clean : clean.substring(0, 16);
}

int cr(Color c) => (c.r * 255.0).round().clamp(0, 255);
int cg(Color c) => (c.g * 255.0).round().clamp(0, 255);
int cb(Color c) => (c.b * 255.0).round().clamp(0, 255);

String actDesc(String a) {
  switch (a) {
    case 'speed':
      return '4 sn hız patlaması';
    case 'silent':
      return '5 sn tamamen görünmez';
    case 'ventrush':
      return 'Vente anında giriş';
    case 'doorbreak':
      return 'Yakındaki kapıyı kırar';
    case 'camjam':
      return 'Kameraları 5 sn bozar';
    case 'lightimmune':
      return '5 sn ışık bağışıklığı';
    case 'noise':
      return 'Rastgele kamerada sahte ses';
    case 'fear':
      return 'Güvenliği 3 sn dondurur';
    case 'dash':
      return 'Merkeze doğru atılma';
    case 'drain':
      return 'Ofiste 10 güç emer';
    default:
      return '';
  }
}

String pasDesc(String p) {
  switch (p) {
    case 'speed':
      return '+%15 kalıcı hız';
    case 'ghost':
      return 'Kameralara ASLA görünmez';
    case 'vent':
      return 'Ventten 2 dokunuşla girer';
    case 'door':
      return 'Kapılara 1.5x hasar';
    case 'quiet':
      return 'Kamera hareket yazmaz';
    case 'light':
      return 'Işıkta %50 kaçma şansı';
    default:
      return 'Pasif yok';
  }
}

List<CD> mkChars() {
  return [
    CD('Kanat', '🦅', 0xFFEF5350, 3.6, 10, 'speed', 'speed',
        '1987 yangınında sahne vincine kilitlenen kuş maskotu... O geceden beri koridorlarda süzülüyor. En hızlı o.'),
    CD('Gölge', '👻', 0xFF9575CD, 3.2, 14, 'silent', 'ghost',
        'Yangında kül olan kuklanın gölgesi. Kameralar onu asla kaydedemez; sadece hissedersin.'),
    CD('Fare', '🐭', 0xFF4DB6AC, 3.4, 12, 'ventrush', 'vent',
        'Havalandırma borularında yaşayan ilk prototip. Boruların içini avucu gibi bilir.'),
    CD('Kas', '🐻', 0xFFE57373, 2.9, 16, 'doorbreak', 'door',
        'Fabrikanın eski maskot ayısı. Gece kapıları yumruklayan o; yavaş ama durdurulamaz.'),
    CD('Hacker', '🤖', 0xFF64B5F6, 3.1, 15, 'camjam', 'quiet',
        'Servis robotuydu; bir gece kameraları kendi kendine kapatmaya başladı. Kimse kodunu çözemedi.'),
    CD('Işık', '💡', 0xFFFFD54F, 3.2, 13, 'lightimmune', 'light',
        'Sahne ışıklarının altında eridi. Artık fenerden korkmuyor; ışık ona dokunamıyor.'),
    CD('Gürültücü', '📢', 0xFFA1887F, 3.3, 11, 'noise', 'none',
        'Çocuk partilerinin hoparlörüydü. Şimdi sahte seslerle güvenlikleri yanlış odaya kandırıyor.'),
    CD('Korku', '😱', 0xFF7986CB, 3.0, 17, 'fear', 'none',
        'Korku evi palyaçasının parçalarından kuruldu. Bir bakışı gardiyanın ellerini 3 saniye titretebilir.'),
    CD('Dalga', '🌊', 0xFF81C784, 3.5, 9, 'dash', 'speed',
        'Su parkından getirilen eski maskot. Göz açıp kapayana kadar yanında biter.'),
    CD('Enerji', '⚡', 0xFFF06292, 3.0, 14, 'drain', 'none',
        'Jeneratör odasında şarj olan ilk model. Ofise sızarsa gücünü damar damar emer.'),
  ];
}

MD mkMap(int i) {
  if (i == 1) {
    final Rect of = Rect.fromLTWH(-25, -20, 50, 40);
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

  final Rect of = Rect.fromLTWH(-20, -15, 40, 30);
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

class NoisePainter extends CustomPainter {
  final int seed;
  final double strength;

  NoisePainter(this.seed, this.strength);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final rnd = Random(seed);
    final p = Paint();

    for (int i = 0; i < 90; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final w = 2 + rnd.nextDouble() * 6;
      final g = 100 + rnd.nextInt(140);
      p.color = Color.fromRGBO(
          g, g, g, (0.04 + rnd.nextDouble() * 0.10) * strength);
      canvas.drawRect(Rect.fromLTWH(x, y, w, 1.5), p);
    }

    p.color = Color.fromRGBO(0, 0, 0, 0.15 * strength);
    for (double y = 0; y < size.height; y += 4) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), p);
    }
  }

  @override
  bool shouldRepaint(covariant NoisePainter oldDelegate) =>
      oldDelegate.seed != seed || oldDelegate.strength != strength;
}

class CheckerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double tile = 24;
    final p = Paint();
    for (double y = 0; y < size.height; y += tile) {
      for (double x = 0; x < size.width; x += tile) {
        final ix = (x / tile).round();
        final iy = (y / tile).round();
        p.color = (ix + iy) % 2 == 0
            ? const Color(0xFF151515)
            : const Color(0xFF0A0A0A);
        canvas.drawRect(Rect.fromLTWH(x, y, tile, tile), p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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

  int page = 0;
  int myId = -1;
  int guard = -1;
  int myRole = -1;
  int myChar = -1;
  int curMap = 0;
  int camRoom = 0;
  int infoChar = 0;

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

  String emo(int id) => (id < 0 || id >= chars.length) ? '❓' : chars[id].emo;

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
    final double progress = (gt / night).clamp(0.0, 1.0).toDouble();
    final int totalMinutes = (progress * 6 * 60).toInt();
    final int hour = totalMinutes ~/ 60;
    final int minute = totalMinutes % 60;
    final int hour12 = hour == 0 ? 12 : hour;
    return '$hour12:${minute.toString().padLeft(2, '0')} AM';
  }

  bool dangerAt(int side) {
    if (map == null) return false;
    final d = side == 0 ? map!.ld : map!.rd;
    for (var v in views()) {
      if (v.role == 1 &&
          !v.inside &&
          !v.hid &&
          (Offset(v.x, v.y) - d).distance < 3.5) {
        return true;
      }
    }
    return false;
  }

  bool ventDanger() {
    if (map == null) return false;
    for (var v in views()) {
      if (v.role == 1 &&
          !v.inside &&
          !v.hid &&
          (Offset(v.x, v.y) - map!.vt).distance < 3.5) {
        return true;
      }
    }
    return false;
  }

  int _usage() {
    int u = 1;
    if (ldC) u++;
    if (rdC) u++;
    if (fl) u++;
    if (cam) u++;
    return u;
  }

  // ========== FNAF GÖRSEL KATMANI ==========

  Widget _animFace(Color color, double size, {bool glow = false}) {
    final Color light = Color.fromARGB(
        255,
        min(255, cr(color) + 45),
        min(255, cg(color) + 45),
        min(255, cb(color) + 45));
    final Color eye = glow ? const Color(0xFFFF2222) : Colors.white;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(children: [
        Positioned(
            left: size * 0.05,
            top: 0,
            child: Container(
                width: size * 0.32,
                height: size * 0.32,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle))),
        Positioned(
            right: size * 0.05,
            top: 0,
            child: Container(
                width: size * 0.32,
                height: size * 0.32,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle))),
        Positioned(
            left: 0,
            top: size * 0.14,
            child: Container(
                width: size,
                height: size * 0.86,
                decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black87, width: 2)))),
        Positioned(
            left: size * 0.17,
            top: size * 0.34,
            child: Container(
                width: size * 0.24,
                height: size * 0.24,
                decoration:
                    BoxDecoration(color: eye, shape: BoxShape.circle))),
        Positioned(
            right: size * 0.17,
            top: size * 0.34,
            child: Container(
                width: size * 0.24,
                height: size * 0.24,
                decoration:
                    BoxDecoration(color: eye, shape: BoxShape.circle))),
        Positioned(
            left: size * 0.26,
            top: size * 0.43,
            child: Container(
                width: size * 0.07,
                height: size * 0.07,
                decoration: const BoxDecoration(
                    color: Colors.black, shape: BoxShape.circle))),
        Positioned(
            right: size * 0.26,
            top: size * 0.43,
            child: Container(
                width: size * 0.07,
                height: size * 0.07,
                decoration: const BoxDecoration(
                    color: Colors.black, shape: BoxShape.circle))),
        Positioned(
            left: size * 0.30,
            top: size * 0.64,
            child: Container(
                width: size * 0.40,
                height: size * 0.26,
                decoration: BoxDecoration(
                    color: light,
                    borderRadius: BorderRadius.circular(size * 0.10)))),
      ]),
    );
  }

  Widget _animBody(Color color, double h, {bool glow = false}) {
    final double w = h * 0.55;
    final Color light = Color.fromARGB(
        255,
        min(255, cr(color) + 60),
        min(255, cg(color) + 60),
        min(255, cb(color) + 60));

    return SizedBox(
      width: w,
      height: h,
      child: Column(children: [
        _animFace(color, w, glow: glow),
        Expanded(
          child: Stack(children: [
            Positioned(
                left: 0,
                top: 2,
                child: Container(
                    width: w * 0.16,
                    height: h * 0.26,
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(w * 0.08)))),
            Positioned(
                right: 0,
                top: 2,
                child: Container(
                    width: w * 0.16,
                    height: h * 0.26,
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(w * 0.08)))),
            Positioned(
                left: w * 0.16,
                right: w * 0.16,
                top: 0,
                bottom: h * 0.22,
                child: Container(
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(w * 0.12)),
                    child: Center(
                        child: Container(
                            width: w * 0.22,
                            height: w * 0.16,
                            decoration: BoxDecoration(
                                color: light,
                                borderRadius:
                                    BorderRadius.circular(4)))))),
            Positioned(
                left: w * 0.22,
                bottom: 0,
                child: Container(
                    width: w * 0.18,
                    height: h * 0.24,
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(w * 0.08)))),
            Positioned(
                right: w * 0.22,
                bottom: 0,
                child: Container(
                    width: w * 0.18,
                    height: h * 0.24,
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(w * 0.08)))),
          ]),
        ),
      ]),
    );
  }

  Widget _card(Widget child, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF101010),
          border: Border.all(color: const Color(0xFF3A0000), width: 1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: child,
      ),
    );
  }

  Widget _fnafButton(String label, Color color, VoidCallback? onTap) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: disabled
              ? const Color(0xFF1A1A1A)
              : Color.fromARGB(70, cr(color), cg(color), cb(color)),
          border: Border.all(
              color: disabled ? Colors.grey.shade800 : color, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
              color: disabled ? Colors.grey : color,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              fontSize: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        title: const Text('🎥 DARKESCAS',
            style: TextStyle(
                color: Color(0xFFB00000),
                fontFamily: 'monospace',
                letterSpacing: 3)),
        actions: [
          PopupMenuButton<Quality>(
            initialValue: quality,
            onSelected: setQ,
            itemBuilder: (context) => [
              const PopupMenuItem(value: Quality.low, child: Text('Düşük')),
              const PopupMenuItem(value: Quality.medium, child: Text('Orta')),
              const PopupMenuItem(value: Quality.high, child: Text('Yüksek')),
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
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 10),
        const Text('🎥 DARKESCAS',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Color(0xFFB00000),
                fontFamily: 'monospace',
                letterSpacing: 4)),
        const Text('GECE GÜVENLİĞİ — LAN KORKU',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.grey,
                fontFamily: 'monospace',
                fontSize: 11,
                letterSpacing: 2)),
        const SizedBox(height: 20),
        _card(Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('📖 NASIL OYNANIR (FNAF 1-2 tarzı)',
                  style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace')),
              SizedBox(height: 6),
              Text('💂 Güvenlik: SADECE ofisi görürsün. Animatronikleri yalnızca KAMERADAN izlersin. Kapı ışığı + kapı + güç yönetimi. Saat 6 AM olana kadar dayan.',
                  style: TextStyle(fontSize: 11, color: Colors.white70)),
              SizedBox(height: 4),
              Text('🐻 Animatronik: kendi bölgende gezersin, ofise sızarsın, güvenliği yakalarsın.',
                  style: TextStyle(fontSize: 11, color: Colors.white70)),
              SizedBox(height: 4),
              Text('🔋 Kapılar, ışık ve kamera güç harcar. Güç biterse karanlık!',
                  style: TextStyle(fontSize: 11, color: Colors.white70)),
            ])),
        _card(TextField(
          controller: nameC,
          maxLength: 16,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
              labelText: 'Adın', labelStyle: TextStyle(color: Colors.grey)),
          onChanged: (v) => myName = sanitizeName(v),
        )),
        _card(const Text('🖥️ HOST OL — odayı kur',
            style: TextStyle(color: Colors.white70)), onTap: () => hostGame()),
        _card(const Text('📡 LOBİ ARA — aynı Wi-Fi ağında hostlar',
            style: TextStyle(color: Colors.white70)), onTap: () => openDisc()),
        _card(
          Column(children: [
            TextField(
              controller: ipc,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  labelText: 'Host IP (cihaz IP)',
                  labelStyle: TextStyle(color: Colors.grey),
                  hintText: '192.168.1.35'),
            ),
            const SizedBox(height: 6),
            _fnafButton('🔌 IP İLE KATIL', Colors.orange, () => joinIp()),
          ]),
        ),
        if (status.isNotEmpty)
          Text(status,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.amber)),
      ],
    );
  }

  Widget _page1() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Text('📡 HOST ARANIYOR... (${disc.length})',
            style: const TextStyle(
                color: Colors.green,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold)),
      ),
      Expanded(
        child: disc.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(12),
                children: disc
                    .map((d) => _card(
                          Row(children: [
                            const Text('🖥️', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(d.s.isEmpty ? 'Host' : d.s,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                    Text('${d.a}:${d.p} — ${d.c}/$maxP',
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.white38)),
                                  ]),
                            ),
                            const Text('▶',
                                style: TextStyle(
                                    color: Colors.red, fontSize: 18)),
                          ]),
                          onTap: () => joinD(d),
                        ))
                    .toList(),
              ),
      ),
      Padding(
        padding: const EdgeInsets.all(12),
        child: _fnafButton('⬅ GERİ', Colors.grey, menu),
      ),
    ]);
  }

  Widget _page2() {
    final me = getP(myId);
    final selected = me?.charId ?? -1;
    final CD inf = chars[infoChar.clamp(0, chars.length - 1)];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('🏚️ LOBİ — ${curMap == 0 ? 'OFİS' : 'DEPO'}',
            style: const TextStyle(
                color: Colors.red,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
                fontSize: 18)),
        if (isHost)
          Row(children: [
            Expanded(
                child: _fnafButton('OFİS', Colors.amber, () => setM(0))),
            const SizedBox(width: 8),
            Expanded(
                child: _fnafButton('DEPO', Colors.amber, () => setM(1))),
          ]),
        const SizedBox(height: 10),
        ...pl.map((p) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: const Color(0xFF0D0D0D),
                  border: Border.all(color: const Color(0xFF333333)),
                  borderRadius: BorderRadius.circular(8)),
              child: Row(children: [
                p.charId >= 0
                    ? _animBody(col(p.charId), 44)
                    : const Text('❔', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(p.name,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      Text(
                          p.charId < 0
                              ? 'karakter seçiyor...'
                              : cn(p.charId),
                          style: const TextStyle(
                              fontSize: 10, color: Colors.white38)),
                    ])),
                if (p.id == guard)
                  const Text('💂 GUARD',
                      style: TextStyle(
                          color: Colors.cyan,
                          fontSize: 10,
                          fontFamily: 'monospace')),
              ]),
            )),
        const SizedBox(height: 12),
        const Text('🎭 ANİMATRONİK SEÇ (dokun = seç + hikayeyi oku)',
            style: TextStyle(
                color: Colors.white54,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: chars.asMap().entries.map((e) {
            final i = e.key;
            final cd = e.value;
            final taken = pl.any((p) => p.id != myId && p.charId == i);
            final sel = selected == i;
            return GestureDetector(
              onTap: taken
                  ? null
                  : () {
                      selC(i);
                      infoChar = i;
                      ui();
                    },
              child: Container(
                width: 78,
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                    color: sel
                        ? Color.fromARGB(80, cr(cd.color), cg(cd.color),
                            cb(cd.color))
                        : const Color(0xFF101010),
                    border: Border.all(
                        color: sel
                            ? cd.color
                            : (taken
                                ? Colors.grey.shade900
                                : Colors.grey.shade700),
                        width: sel ? 2 : 1),
                    borderRadius: BorderRadius.circular(8)),
                child: Column(children: [
                  _animBody(cd.color, 56),
                  const SizedBox(height: 4),
                  Text(cd.n,
                      style: TextStyle(
                          fontSize: 10,
                          color: taken ? Colors.grey : Colors.white,
                          fontWeight: FontWeight.bold)),
                  Text('Hız ${cd.sp} • CD ${cd.cd.toInt()}s',
                      style: const TextStyle(
                          fontSize: 7, color: Colors.white38)),
                ]),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),
        _card(Column(children: [
          Row(children: [
            _animBody(inf.color, 92, glow: true),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('${inf.emo} ${inf.n}',
                      style: TextStyle(
                          color: inf.color,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  const SizedBox(height: 4),
                  Text('AKTİF: ${actDesc(inf.act)}',
                      style: const TextStyle(
                          fontSize: 10, color: Colors.white70)),
                  Text('PASİF: ${pasDesc(inf.pas)}',
                      style: const TextStyle(
                          fontSize: 10, color: Colors.white70)),
                  Text('HIZ ${inf.sp} • BEKLEME ${inf.cd.toInt()} sn',
                      style: const TextStyle(
                          fontSize: 10, color: Colors.white38)),
                ])),
          ]),
          const SizedBox(height: 8),
          Text('📜 ${inf.lore}',
              style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic)),
        ])),
        const SizedBox(height: 10),
        if (isHost)
          _fnafButton('▶ OYUNU BAŞLAT', Colors.green,
              pl.length >= 2 ? startHost : null),
        if (status.isNotEmpty)
          Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(status,
                  style: const TextStyle(color: Colors.amber))),
      ],
    );
  }

  Widget _page3() {
    if (map == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ValueListenableBuilder<int>(
      valueListenable: fr,
      builder: (context, _, __) {
        return Stack(children: [
          if (myRole == 0) _guardView() else _intruderView(),
          Positioned(top: 0, left: 0, right: 0, child: _topHud()),
          if (jump > 0) _jumpscare(),
        ]);
      },
    );
  }

  Widget _topHud() {
    final powerColor =
        en > 60 ? Colors.green : en > 30 ? Colors.orange : Colors.red;
    return Container(
      color: const Color.fromRGBO(0, 0, 0, 0.85),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(children: [
        Text('🕐 ${clock()}',
            style: const TextStyle(
                color: Colors.white70,
                fontFamily: 'monospace',
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const Spacer(),
        if (myRole == 0)
          Text('Kullanım: ${'▮' * _usage()}',
              style: TextStyle(
                  color: powerColor,
                  fontFamily: 'monospace',
                  fontSize: 14)),
        if (myRole == 0) const SizedBox(width: 10),
        Text('🔋 %${en.round()}',
            style: TextStyle(
                color: powerColor,
                fontFamily: 'monospace',
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _guardView() {
    return LayoutBuilder(builder: (context, c) {
      return Stack(children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
                colors: [
                  Color(0xFF000000),
                  Color(0xFF131A22),
                  Color(0xFF000000)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter),
          ),
        ),
        Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: c.maxHeight * 0.30,
            child: CustomPaint(painter: CheckerPainter())),
        Positioned(
            left: 0,
            right: 0,
            bottom: c.maxHeight * 0.24,
            child: Center(
                child: Column(children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                Transform.rotate(
                    angle: fr.value * 0.3,
                    child: const Text('❋',
                        style: TextStyle(
                            fontSize: 26, color: Colors.white24))),
                const SizedBox(width: 14),
                const Text('🖥️', style: TextStyle(fontSize: 46)),
                const SizedBox(width: 14),
                const Text('🎉', style: TextStyle(fontSize: 22)),
              ]),
              const Text('O F İ S',
                  style: TextStyle(
                      color: Colors.white24,
                      fontFamily: 'monospace',
                      letterSpacing: 6)),
              if (black)
                const Text('⚠ GÜÇ BİTTİ — KARANLIKTASIN',
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold)),
            ]))),
        Positioned(
            left: 6,
            top: c.maxHeight * 0.14,
            bottom: c.maxHeight * 0.28,
            child: _doorWidget(0)),
        Positioned(
            right: 6,
            top: c.maxHeight * 0.14,
            bottom: c.maxHeight * 0.28,
            child: _doorWidget(1)),
        if (ventDanger())
          const Positioned(
              top: 46,
              left: 0,
              right: 0,
              child: Center(
                  child: Text('🌀 HAVANDIRMADA SES!',
                      style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold)))),
        Positioned(
            left: 8,
            right: 8,
            bottom: 10,
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                _fnafButton(
                    ldC ? '🚪 SOL AÇ' : '🔒 SOL KAPAT',
                    ldC ? Colors.red : Colors.green,
                    black ? null : () => gAct('doorL')),
                _fnafButton(
                    rdC ? '🚪 SAĞ AÇ' : '🔒 SAĞ KAPAT',
                    rdC ? Colors.red : Colors.green,
                    black ? null : () => gAct('doorR')),
                _fnafButton(
                    fl ? '🔦 IŞIK KAPAT' : '🔦 IŞIK AÇ',
                    Colors.yellow,
                    black ? null : () => gAct('flash')),
                _fnafButton(
                    cam ? '📷 KAMERAYI İNDİR' : '📷 KAMERAYI KALDIR',
                    Colors.cyan,
                    black ? null : () => gAct('cam')),
              ],
            )),
        if (cam) _camView(),
        Positioned.fill(
            child: IgnorePointer(
                child: CustomPaint(
                    painter: NoisePainter(fr.value ~/ 3, 0.35)))),
      ]);
    });
  }

  Widget _doorWidget(int side) {
    final closed = side == 0 ? ldC : rdC;
    final danger = dangerAt(side);
    final showFig = danger && !closed && fl;
    return Column(children: [
      Expanded(
        child: Container(
          width: 64,
          decoration: BoxDecoration(
            color: closed ? const Color(0xFF3D3D3D) : const Color(0xFF030405),
            border: Border.all(
                color: closed ? Colors.red.shade900 : Colors.green.shade900,
                width: 2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: closed
                ? const Text('🔒', style: TextStyle(fontSize: 22))
                : (showFig
                    ? _animBody(const Color(0xFF141414), 110, glow: true)
                    : (fl
                        ? const Text('🌑', style: TextStyle(fontSize: 20))
                        : const Text('·',
                            style: TextStyle(color: Colors.white24)))),
          ),
        ),
      ),
      const SizedBox(height: 6),
      Text(side == 0 ? 'SOL' : 'SAĞ',
          style: const TextStyle(
              color: Colors.white38,
              fontFamily: 'monospace',
              fontSize: 10)),
    ]);
  }

  Widget _camMap(MD m) {
    double minX = m.of.left;
    double maxX = m.of.right;
    double minY = m.of.top;
    double maxY = m.of.bottom;
    for (final r in m.rooms) {
      minX = min(minX, r.r.left);
      maxX = max(maxX, r.r.right);
      minY = min(minY, r.r.top);
      maxY = max(maxY, r.r.bottom);
    }
    const double W = 170;
    const double H = 120;
    final double rw = maxX - minX;
    final double rh = maxY - minY;

    return Container(
      color: const Color.fromRGBO(0, 0, 0, 0.75),
      padding: const EdgeInsets.all(6),
      child: SizedBox(
        width: W,
        height: H,
        child: Stack(children: [
          Positioned(
            left: (m.of.left - minX) / rw * W,
            top: (m.of.top - minY) / rh * H,
            width: m.of.width / rw * W,
            height: m.of.height / rh * H,
            child: Container(
              color: const Color(0xFF223322),
              child: const Center(
                  child: Text('SEN',
                      style: TextStyle(fontSize: 7, color: Colors.amber))),
            ),
          ),
          for (int i = 0; i < m.rooms.length; i++)
            Positioned(
              left: (m.rooms[i].r.left - minX) / rw * W,
              top: (m.rooms[i].r.top - minY) / rh * H,
              width: m.rooms[i].r.width / rw * W,
              height: m.rooms[i].r.height / rh * H,
              child: GestureDetector(
                onTap: () {
                  camRoom = i;
                  ui();
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: i == camRoom
                        ? const Color(0xFF335533)
                        : const Color(0xFF112211),
                    border: Border.all(
                        color:
                            i == camRoom ? Colors.red : Colors.green.shade800),
                  ),
                  child: Center(
                      child: Text('${i + 1}',
                          style: const TextStyle(
                              fontSize: 8, color: Colors.green))),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _camView() {
    final m = map!;
    final inRoom = views()
        .where((v) => v.role == 1 && !v.inside && !v.hid && v.room == camRoom)
        .toList();
    final roomName =
        camRoom >= 0 && camRoom < m.rooms.length ? m.rooms[camRoom].n : '';

    return Positioned.fill(
      child: Container(
        color: const Color.fromRGBO(0, 0, 0, 0.95),
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          Row(children: [
            Text('📷 CAM ${camRoom + 1} — $roomName',
                style: const TextStyle(
                    color: Colors.green,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold)),
            const Spacer(),
            Text(clock(),
                style: const TextStyle(
                    color: Colors.green, fontFamily: 'monospace')),
            const SizedBox(width: 8),
            if (fr.value ~/ 15 % 2 == 0)
              const Text('● REC',
                  style: TextStyle(
                      color: Colors.red,
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          Expanded(
            child: Stack(children: [
              Positioned.fill(
                  child: Container(
                      decoration: BoxDecoration(
                          color: const Color(0xFF02140A),
                          border: Border.all(color: Colors.green.shade900),
                          borderRadius: BorderRadius.circular(8)))),
              Center(
                child: jam > gt
                    ? const Text('▓▒░ PARAZİT ░▒▓',
                        style: TextStyle(
                            color: Colors.green,
                            fontSize: 22,
                            fontFamily: 'monospace'))
                    : inRoom.isEmpty
                        ? const Text('— TEMİZ —',
                            style: TextStyle(
                                color: Colors.green,
                                fontFamily: 'monospace',
                                fontSize: 16))
                        : Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 18,
                            children: inRoom
                                .map((v) => Column(children: [
                                      _animBody(v.color, 96, glow: true),
                                      const SizedBox(height: 4),
                                      Text(cn(v.ch),
                                          style: const TextStyle(
                                              color: Colors.red,
                                              fontWeight:
                                                  FontWeight.bold)),
                                    ]))
                                .toList()),
              ),
              Positioned.fill(
                  child: CustomPaint(
                      painter: NoisePainter(fr.value ~/ 2, 1.0))),
              Positioned(right: 8, bottom: 8, child: _camMap(m)),
            ]),
          ),
          const SizedBox(height: 8),
          _fnafButton('📷 KAMERAYI İNDİR', Colors.cyan, () => gAct('cam')),
        ]),
      ),
    );
  }

  Widget _intruderView() {
    return LayoutBuilder(builder: (context, c) {
      final size = Size(c.maxWidth, c.maxHeight);
      final m = map!;
      const scale = 7.0;
      final wc = m.of.center;

      Offset toScreen(Offset w) => Offset(
            size.width / 2 + (w.dx - wc.dx) * scale,
            size.height / 2 + (w.dy - wc.dy) * scale,
          );

      return Stack(children: [
        Container(color: const Color(0xFF04060A)),
        for (final r in m.rooms) _roomRect(r, toScreen, scale),
        _officeRect(m, toScreen, scale),
        _pointWidget(m.ld, toScreen, ldC ? '🚪' : '🕳️'),
        _pointWidget(m.rd, toScreen, rdC ? '🚪' : '🕳️'),
        _pointWidget(m.vt, toScreen, '🌀'),
        ..._markers(toScreen),
        Positioned(left: 12, bottom: 12, child: _joystick()),
        Positioned(right: 12, bottom: 12, child: _actionButtons()),
        Positioned.fill(
            child: IgnorePointer(
                child: CustomPaint(
                    painter: NoisePainter(fr.value ~/ 4, 0.2)))),
      ]);
    });
  }

  Widget _roomRect(Room r, Offset Function(Offset) toScreen, double scale) {
    final tl = toScreen(r.r.topLeft);
    return Positioned(
      left: tl.dx,
      top: tl.dy,
      width: r.r.width * scale,
      height: r.r.height * scale,
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
            color: const Color(0xFF101820),
            border: Border.all(color: const Color(0xFF2C3A47), width: 1),
            borderRadius: BorderRadius.circular(6)),
        child: Text(r.n,
            style: const TextStyle(
                color: Color(0xFF3E5060),
                fontSize: 8,
                fontFamily: 'monospace'),
            overflow: TextOverflow.ellipsis),
      ),
    );
  }

  Widget _officeRect(MD m, Offset Function(Offset) toScreen, double scale) {
    final tl = toScreen(m.of.topLeft);
    return Positioned(
      left: tl.dx,
      top: tl.dy,
      width: m.of.width * scale,
      height: m.of.height * scale,
      child: Container(
        decoration: BoxDecoration(
            color: const Color(0xFF1A1208),
            border: Border.all(color: Colors.amber.shade900, width: 2),
            borderRadius: BorderRadius.circular(8)),
        child: const Center(
            child: Text('🖥️ OFİS',
                style: TextStyle(
                    color: Colors.amber,
                    fontSize: 10,
                    fontFamily: 'monospace'))),
      ),
    );
  }

  Widget _pointWidget(
      Offset world, Offset Function(Offset) toScreen, String label) {
    final p = toScreen(world);
    return Positioned(
        left: p.dx - 10,
        top: p.dy - 10,
        child: Text(label, style: const TextStyle(fontSize: 16)));
  }

  List<Widget> _markers(Offset Function(Offset) toScreen) {
    final list =
        views().where((v) => isHost || v.id == myId || !v.hid).toList();
    return list.map((v) {
      final p = toScreen(Offset(v.x, v.y));
      final self = v.id == myId;
      return Positioned(
        left: p.dx - 16,
        top: p.dy - 24 - (self ? jump * 6 : 0),
        child: Column(children: [
          v.role == 0
              ? const Text('💂', style: TextStyle(fontSize: 24))
              : _animBody(v.color, 40, glow: true),
          Text(self ? 'SEN' : (v.role == 0 ? 'GÜVENLİK' : cn(v.ch)),
              style: TextStyle(
                  fontSize: 8,
                  color: self ? Colors.white : Colors.white54,
                  fontFamily: 'monospace')),
        ]),
      );
    }).toList();
  }

  Widget _actionButtons() {
    if (win != 0 || myRole != 1) return const SizedBox.shrink();

    final a = ctx();
    return Column(mainAxisSize: MainAxisSize.min, children: [
      _fnafButton(_ctxLabel(a), Colors.red, a == 'none' ? null : inter),
      const SizedBox(height: 8),
      _fnafButton(
          myCd > 0
              ? '⏳ ${myCd.toStringAsFixed(1)}'
              : '✨ YETENEK (${cn(myChar)})',
          Colors.purple,
          myCd > 0 ? null : abil),
    ]);
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
        decoration: BoxDecoration(
          color: const Color.fromRGBO(255, 255, 255, 0.06),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.red.shade900, width: 2),
        ),
        child: Center(
          child: Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color.fromRGBO(255, 255, 255, 0.15),
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

  Widget _jumpscare() {
    return Positioned.fill(
      child: Container(
        color: const Color.fromRGBO(0, 0, 0, 0.9),
        child: Stack(children: [
          Positioned.fill(
              child: CustomPaint(painter: NoisePainter(fr.value, 1.0))),
          Center(
              child: Transform.scale(
                  scale: 1.0 + jump * 0.5,
                  child:
                      _animBody(const Color(0xFF3B0000), 300, glow: true))),
          const Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                  child: Text('!! YAKALANDIN !!',
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace')))),
        ]),
      ),
    );
  }

  String _ctxLabel(String a) {
    switch (a) {
      case 'attack':
        return '💀 SALDIR';
      case 'enterL':
        return '🚪 SOL KAPIDAN GİR';
      case 'enterR':
        return '🚪 SAĞ KAPIDAN GİR';
      case 'forceL':
        return '💥 SOL KAPIYI ZORLA';
      case 'forceR':
        return '💥 SAĞ KAPIYI ZORLA';
      case 'vent':
        return '🌀 HAVANDIRMAYA GİR';
      default:
        return 'ETKİLEŞİM';
    }
  }

  Widget _page4() {
    final winGuard = win == 1;
    return Stack(children: [
      Container(color: const Color(0xFF000000)),
      Positioned.fill(
          child: CustomPaint(painter: NoisePainter(7, 0.4))),
      Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(winGuard ? '🌅 6:00 AM' : '💀 GAME OVER',
              style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  color: winGuard ? Colors.amber : Colors.red)),
          const SizedBox(height: 10),
          Text(endMsg, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 24),
          _fnafButton('ANA MENÜ', Colors.grey, menu),
        ]),
      ),
    ]);
  }
}
