import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const GameApp());
class GameApp extends StatelessWidget {
  const GameApp({super.key});
  @override
  Widget build(BuildContext c) => MaterialApp(title: 'Darkescas', debugShowCheckedModeBanner: false, theme: ThemeData.dark(), home: const GameScreen());
}

enum Quality { low, medium, high }
class GQ {
  bool glow, vignette, noise, shake, grad; int cap;
  GQ(this.glow, this.vignette, this.noise, this.shake, this.grad, this.cap);
  static GQ of(Quality q) => q == Quality.low ? GQ(false, false, false, false, false, 0)
      : q == Quality.medium ? GQ(true, true, true, false, true, 50)
      : GQ(true, true, true, true, true, 140);
}

class Endpoint { final InternetAddress a; final int p; Endpoint(this.a, this.p); }
class PlayerNet {
  final int id; String name; int charId, role, roomId, entrySide;
  double x, y, lastSeen, cd, boost, silent, light, vent; bool moving, inside, alive;
  PlayerNet(this.id, this.name, {this.charId = -1, this.role = -1, this.x = 0, this.y = 0, this.roomId = -1, this.entrySide = 0,
    this.lastSeen = 0, this.cd = 0, this.boost = 0, this.silent = 0, this.light = 0, this.vent = 0, this.moving = false, this.inside = false, this.alive = true});
}
class AiNet { final int id, charId; double x, y, tx, ty, speed, think; int roomId; bool moving;
  AiNet(this.id, this.charId, this.x, this.y, this.roomId, this.speed) : tx = x, ty = y, think = 0, moving = false; }
class EntityView { final int id, charId, role, room; final double x, y; final bool moving, hidden, inside; final Color color;
  EntityView(this.id, this.charId, this.role, this.x, this.y, this.room, this.moving, this.hidden, this.inside, this.color); }
class Room { final String name; final Rect r; Room(this.name, this.r); }
class MapDef { final String name; final Rect office; final Offset ld, rd, vt, il, ir, iv; final List<Room> rooms;
  MapDef(this.name, this.office, this.ld, this.rd, this.vt, this.il, this.ir, this.iv, this.rooms); }
class CharDef { final String name, active, passive; final Color color; final double speed, cd;
  CharDef(this.name, int col, this.speed, this.cd, this.active, this.passive) : color = Color(col); }
class DiscoveredHost { final String addr; final int port; String s; int c, m; double last; DiscoveredHost(this.addr, this.port, this.s, this.c, this.m, this.last); }
class Particle { double x, y, vx, vy, life, max, size; Color c; Particle(this.x, this.y, this.vx, this.vy, this.life, this.size, this.c) : max = life; }

class GameScreen extends StatefulWidget { const GameScreen({super.key}); @override State<GameScreen> createState() => _S(); }

class _S extends State<GameScreen> {
  static const int port = 47777; static const double night = 240.0; static const int maxP = 4;
  final rnd = Random(); final ipCtrl = TextEditingController();
  Timer? loop, slow; final frame = ValueNotifier<int>(0); double acc = 0;
  Quality quality = Quality.medium; late GQ q = GQ.of(quality); bool pOn = true, showSet = false;
  int page = 0, myId = -1, guardId = -1, myRole = -1, myChar = -1, curMap = 0, camRoom = 0;
  bool isHost = false; String myName = "", status = "", endMsg = "";
  RawDatagramSocket? sock; InternetAddress? hostA; int hostP = port;
  final Map<int, Endpoint> eps = {}; final List<PlayerNet> pl = []; final List<AiNet> ai = [];
  final List<DiscoveredHost> disc = []; final Map<int, EntityView> rem = {};
  late List<CharDef> chars; MapDef? map;
  double lastDisc = 0, lastPing = 0, lastHost = 0, lastLob = 0, lastState = 0, lastSnap = 0;
  double gt = 0, en = 100; bool ldC = true, rdC = true, fl = false, cam = false, black = false;
  int win = 0, nRoom = -1; double fL = 0, fR = 0, dL = 0, dR = 0, jam = 0, lock = 0, nUntil = 0;
  Offset pos = Offset.zero; bool mov = false, myIn = false, myB = false; double myCd = 0;
  Offset jt = Offset.zero; double jx = 0, jy = 0, shake = 0, jump = 0;
  final List<Particle> parts = [];

  @override void initState() { super.initState(); myName = "Oyuncu ${rnd.nextInt(900) + 100}"; chars = mkChars(); slow = Timer.periodic(const Duration(seconds: 1), slowT); }
  @override void dispose() { loop?.cancel(); slow?.cancel(); try { sock?.close(); } catch (_) {} ipCtrl.dispose(); super.dispose(); }
  void ui() { if (mounted) setState(() {}); }
  double now() => DateTime.now().millisecondsSinceEpoch / 1000.0;
  void setQ(Quality v) { quality = v; q = GQ.of(v); ui(); }

  Future<bool> hostSock() async { closeN(); try { sock = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port); sock!.broadcastEnabled = true; sock!.listen(onS); return true; } catch (e) { status = "Host hatası"; return false; } }
  Future<bool> cliSock() async { closeN(); try { sock = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0); sock!.broadcastEnabled = true; sock!.listen(onS); return true; } catch (e) { status = "Socket hatası"; return false; } }
  void closeN() { try { sock?.close(); } catch (_) {} sock = null; }
  void onS(RawSocketEvent e) { if (e != RawSocketEvent.read) return; var dg = sock?.receive(); if (dg == null) return;
    try { var m = (jsonDecode(utf8.decode(dg.data)) as Map).cast<String, dynamic>(); var p = m["p"] is Map ? (m["p"] as Map).cast<String, dynamic>() : <String, dynamic>{};
      isHost ? hP(gs(m["t"]), p, dg) : cP(gs(m["t"]), p, dg); } catch (_) {} }
  void send(Map d, InternetAddress a, int p) { try { sock?.send(utf8.encode(jsonEncode(d)), a, p); } catch (_) {} }
  void toHost(Map d) { if (hostA != null) send(d, hostA!, hostP); }
  void toAll(Map d) { if (!isHost) return; for (var e in eps.values) send(d, e.a, e.p); }
  int epId(InternetAddress a, int p) { for (var e in eps.entries) if (e.value.a.address == a.address && e.value.p == p) return e.key; return -1; }

  void hP(String t, Map p, Datagram dg) {
    if (t == "discover") { if (page == 2) send({"t": "hostinfo", "p": {"name": "$myName", "count": pl.length, "map": curMap}}, dg.address, dg.port); return; }
    if (t == "hello") { int ex = epId(dg.address, dg.port); if (ex != -1) { send({"t": "welcome", "p": {"id": ex}}, dg.address, dg.port); return; }
      if (page != 2 || pl.length >= maxP) { send({"t": "err", "p": {"m": "Katılamazsın"}}, dg.address, dg.port); return; }
      int id = 1; while (pl.any((x) => x.id == id)) id++;
      pl.add(PlayerNet(id, gs(p["name"]).isEmpty ? "Oyuncu$id" : gs(p["name"]), lastSeen: now()));
      eps[id] = Endpoint(dg.address, dg.port); send({"t": "welcome", "p": {"id": id}}, dg.address, dg.port); lob(); return; }
    int id = epId(dg.address, dg.port); if (id == -1) return; var me = getP(id); if (me != null) me.lastSeen = now();
    if (t == "ping") return;
    if (t == "leave") { rmP(id); return; }
    if (t == "char" && page == 2) { selH(id, gi(p["c"])); return; }
    if (t == "state" && page == 3 && me != null && me.role == 1) { me.x = gd(p["x"]); me.y = gd(p["y"]); me.moving = gb(p["mv"]); if (map != null) me.roomId = roomAt(Offset(me.x, me.y)); return; }
    if (t == "act" && page == 3) act(id, gs(p["a"]));
  }

  void cP(String t, Map p, Datagram dg) {
    lastHost = now();
    if (t == "hostinfo" && page == 1) { String k = dg.address.address; DiscoveredHost? f; for (var d in disc) if (d.addr == k) f = d;
      if (f == null) disc.add(DiscoveredHost(k, dg.port, gs(p["name"]), gi(p["count"]), gi(p["map"]), now())); else { f.s = gs(p["name"]); f.c = gi(p["count"]); f.m = gi(p["map"]); f.last = now(); } ui(); return; }
    if (t == "welcome") { myId = gi(p["id"]); page = 2; status = "Lobidesin"; ui(); return; }
    if (t == "lobby") { pl.clear(); curMap = gi(p["map"]); if (p["players"] is List) for (var it in p["players"]) { var q = (it as Map).cast<String, dynamic>(); pl.add(PlayerNet(gi(q["id"]), gs(q["name"]), charId: gi(q["char"]))); } if (page == 2) ui(); return; }
    if (t == "start") { startFrom(p); return; }
    if (t == "snap") { snap(p); return; }
    if (t == "over") { endL(gi(p["w"]), gs(p["m"])); return; }
    if (t == "err") { status = gs(p["m"]); page = 0; closeN(); ui(); return; }
    if (t == "closed") { closeN(); page = 0; status = "Host kapattı"; ui(); return; }
  }

  Future<void> hostGame() async { if (!await hostSock()) { ui(); return; } isHost = true; myId = 0; guardId = -1; myRole = -1; myChar = -1; curMap = 0;
    pl.clear(); eps.clear(); ai.clear(); rem.clear(); pl.add(PlayerNet(0, myName, lastSeen: now())); page = 2; status = "Host hazır"; lob(); ui(); }
  Future<void> openDisc() async { if (!await cliSock()) { ui(); return; } isHost = false; myId = -1; disc.clear(); page = 1; disc0(); lastDisc = now(); ui(); }
  void disc0() { try { send({"t": "discover"}, InternetAddress("255.255.255.255"), port); } catch (_) {} }
  Future<void> joinIp() async { InternetAddress? a; try { a = InternetAddress(ipCtrl.text.trim()); } catch (_) {} if (a == null) { status = "Geçerli IP gir"; ui(); return; }
    if (!await cliSock()) { ui(); return; } isHost = false; myId = -1; hostA = a; hostP = port; hello(); page = 0; status = "Bağlanıyor"; lastHost = now(); ui(); }
  void joinD(DiscoveredHost d) { try { hostA = InternetAddress(d.addr); hostP = d.port; hello(); page = 0; status = "Bağlanıyor"; lastHost = now(); ui(); } catch (_) {} }
  void hello() => toHost({"t": "hello", "p": {"name": myName}});

  void menu() { if (isHost) toAll({"t": "closed"}); else toHost({"t": "leave"}); loop?.cancel(); loop = null; closeN();
    isHost = false; page = 0; myId = -1; guardId = -1; myRole = -1; myChar = -1; win = 0;
    pl.clear(); eps.clear(); ai.clear(); rem.clear(); disc.clear(); parts.clear(); status = "Ana menü"; ui(); }

  void selC(int c) { if (page != 2) return; isHost ? selH(myId, c) : toHost({"t": "char", "p": {"c": c}}); }
  void selH(int id, int c) { if (page != 2 || c < 0 || c >= chars.length) return; var me = getP(id); if (me == null) return;
    for (var o in pl) if (o.id != id && o.charId == c) { status = "Seçili karakter"; lob(); return; } me.charId = c; lob(); }
  void setM(int m) { if (!isHost || page != 2) return; curMap = (m < 0) ? 0 : (m > 1 ? 1 : m); lob(); }
  void lob() { if (!isHost) return; toAll({"t": "lobby", "p": {"map": curMap, "players": pl.map((p) => {"id": p.id, "name": p.name, "char": p.charId}).toList()}}); lastLob = now(); ui(); }

  void startHost() { if (!isHost || page != 2 || pl.length < 2) { status = "En az 2 oyuncu"; ui(); return; }
    map = mkMap(curMap); reset(); var ids = pl.map((e) => e.id).toList(); guardId = ids[rnd.nextInt(ids.length)]; var used = <int>[];
    for (var p in pl) { if (p.id == guardId) { p.role = 0; p.charId = -1; p.x = map!.office.center.dx; p.y = map!.office.center.dy; p.inside = true; p.roomId = -2; }
      else { p.role = 1; if (p.charId < 0 || p.charId >= chars.length || used.contains(p.charId)) p.charId = freeC(used); used.add(p.charId);
        var s = rndS(); p.x = s.dx; p.y = s.dy; p.inside = false; p.roomId = roomAt(s); }
      p.alive = true; p.moving = false; p.cd = 0; p.boost = 0; p.silent = 0; p.light = 0; p.vent = 0;
      if (p.id == myId) { myRole = p.role; myChar = p.charId; pos = Offset(p.x, p.y); myIn = p.inside; } }
    ai.clear(); int a = -100; for (int c = 0; c < chars.length; c++) if (!used.contains(c)) { var s = rndS(); ai.add(AiNet(a--, c, s.dx, s.dy, max(0, roomAt(s)), 1.0 + rnd.nextDouble() * 0.7)); }
    toAll({"t": "start", "p": {"map": curMap, "guard": guardId, "players": pl.map((p) => {"id": p.id, "char": p.charId, "role": p.role, "x": p.x, "y": p.y}).toList(), "ais": ai.map((x) => {"id": x.id, "char": x.charId, "x": x.x, "y": x.y}).toList()}});
    page = 3; startLoop(); ui(); }

  void startFrom(Map p) { reset(); curMap = gi(p["map"]); guardId = gi(p["guard"]); map = mkMap(curMap); pl.clear(); rem.clear(); ai.clear();
    if (p["players"] is List) for (var it in p["players"]) { var q = (it as Map).cast<String, dynamic>(); int id = gi(q["id"]); int ch = gi(q["char"]); int rl = gi(q["role"]); double x = gd(q["x"]), y = gd(q["y"]);
      if (id == myId) { myRole = rl; myChar = ch; pos = Offset(x, y); myIn = rl == 0; } else rem[id] = EntityView(id, ch, rl, x, y, rl == 0 ? -2 : roomAt(Offset(x, y)), false, false, rl == 0, col(ch)); }
    if (p["ais"] is List) for (var it in p["ais"]) { var q = (it as Map).cast<String, dynamic>(); rem[gi(q["id"])] = EntityView(gi(q["id"]), gi(q["char"]), 2, gd(q["x"]), gd(q["y"]), roomAt(Offset(gd(q["x"]), gd(q["y"]))), false, false, false, col(gi(q["char"]))); }
    page = 3; startLoop(); ui(); }

  void reset() { gt = 0; en = 100; ldC = true; rdC = true; fl = false; cam = false; black = false; win = 0; endMsg = "";
    fL = 0; fR = 0; dL = 0; dR = 0; jam = 0; lock = 0; nRoom = -1; nUntil = 0; mov = false; myIn = myRole == 0; myCd = 0; myB = false; camRoom = 0; parts.clear(); shake = 0; jump = 0; }
  void startLoop() { loop?.cancel(); loop = Timer.periodic(const Duration(milliseconds: 16), tick); }

  void tick(Timer t) { if (page != 3) return; const double dt = 1 / 60;
    if (win == 0) { if (myRole == 1) moveL(dt); if (isHost) hostU(dt); else if (myRole == 1 && now() - lastState > 0.1) sendS(); }
    upParts(dt); shake = max(0.0, shake - dt * 3); jump = max(0.0, jump - dt); frame.value++; acc += dt; if (acc > 0.1) { acc = 0; ui(); } }

  void slowT(Timer t) { double n = now();
    if (page == 1) { if (n - lastDisc > 2) { lastDisc = n; disc0(); } int b = disc.length; disc.removeWhere((d) => n - d.last > 6); if (b != disc.length) ui(); }
    if (!isHost && (page == 2 || page == 3)) { if (n - lastHost > 10) { status = "Koptu"; menu(); return; } if (n - lastPing > 2) { lastPing = n; toHost({"t": "ping"}); } }
    if (isHost && page == 2 && n - lastLob > 2) lob();
    if (isHost && (page == 2 || page == 3)) for (int i = pl.length - 1; i >= 0; i--) if (pl[i].id != 0 && n - pl[i].lastSeen > 10) rmP(pl[i].id); }

  void hostU(double dt) { if (win != 0 || map == null) return; gt += dt;
    double dr = 0.08; if (ldC) dr += 0.4; if (rdC) dr += 0.4; if (fl) dr += 0.35; if (cam) dr += 0.5;
    for (var p in pl) if (p.role == 1 && p.alive && p.charId >= 0 && p.charId < chars.length && chars[p.charId].passive == "energy") if ((Offset(p.x, p.y) - map!.office.center).distance < 10) dr += 0.15;
    en -= dr * dt; if (en <= 0 && !black) { en = 0; black = true; ldC = false; rdC = false; fl = false; cam = false; } if (black) en = 0;
    upAI(dt);
    if (gt >= night) { endG(1, "Güvenlik dayandı"); return; }
    if (!pl.any((p) => p.role == 1 && p.alive)) { endG(1, "Animatronik kalmadı"); return; }
    var me = getP(myId); if (me != null) { myIn = me.inside; myCd = max(0.0, me.cd - gt); myB = me.boost > gt; }
    if (now() - lastSnap > 0.1) { lastSnap = now(); bSnap(); } }

  void upAI(double dt) { if (map == null || map!.rooms.isEmpty) return;
    for (var a in ai) { if (a.roomId < 0 || a.roomId >= map!.rooms.length) a.roomId = rnd.nextInt(map!.rooms.length);
      var r = map!.rooms[a.roomId].r;
      if (gt >= a.think || (Offset(a.x, a.y) - Offset(a.tx, a.ty)).distance < 0.5) { a.think = gt + 2 + rnd.nextDouble() * 3;
        double mx = min(1.0, r.width * 0.25), my = min(1.0, r.height * 0.25);
        double x1 = r.left + mx, x2 = r.right - mx, y1 = r.top + my, y2 = r.bottom - my;
        if (x2 < x1) x1 = x2 = r.center.dx; if (y2 < y1) y1 = y2 = r.center.dy;
        a.tx = x1 + rnd.nextDouble() * (x2 - x1); a.ty = y1 + rnd.nextDouble() * (y2 - y1); }
      var d = Offset(a.tx, a.ty) - Offset(a.x, a.y);
      if (d.distance > 0.2) { var n = Offset(a.x, a.y) + (d / d.distance) * a.speed * dt; a.x = n.dx; a.y = n.dy; a.moving = true; } else a.moving = false; } }

  void moveL(double dt) { if (page != 3 || win != 0 || myRole != 1 || map == null) return; var d = Offset(jx, jy); mov = d.distance > 0.1;
    if (mov) { if (d.distance > 1) d = d / d.distance; double sp = spd(); var n = pos + d * sp * dt;
      if (walk(n)) pos = n; else { var nx = pos + Offset(d.dx * sp * dt, 0); if (walk(nx)) pos = nx; var ny = pos + Offset(0, d.dy * sp * dt); if (walk(ny)) pos = ny; } }
    if (isHost) { var me = getP(myId); if (me != null) { me.x = pos.dx; me.y = pos.dy; me.moving = mov; me.roomId = roomAt(pos); } } }
  double spd() { double s = 3.2; if (myChar >= 0 && myChar < chars.length) { s = chars[myChar].speed; if (chars[myChar].passive == "speed") s *= 1.15; } if (myB) s *= 1.6; if (myIn) s *= 0.85; return s; }
  void sendS() { lastState = now(); toHost({"t": "state", "p": {"x": pos.dx, "y": pos.dy, "mv": mov}}); }

  void gAct(String a) { if (page != 3 || myRole != 0 || win != 0) return; isHost ? act(myId, a) : toHost({"t": "act", "p": {"a": a}}); }
  void inter() { if (page != 3 || myRole != 1 || win != 0) return; var a = ctx(); if (a == "none") return; isHost ? act(myId, a) : toHost({"t": "act", "p": {"a": a}}); }
  void abil() { if (page != 3 || myRole != 1 || win != 0 || myCd > 0) return; isHost ? act(myId, "ability") : toHost({"t": "act", "p": {"a": "ability"}}); }

  String ctx() { if (page != 3 || map == null || myRole != 1) return "none"; if (myIn) return "attack";
    if ((pos - map!.ld).distance < 3) return ldC ? "forceL" : "enterL";
    if ((pos - map!.rd).distance < 3) return rdC ? "forceR" : "enterR";
    if ((pos - map!.vt).distance < 3) return "vent"; return "none"; }

  void act(int id, String a) { if (page != 3 || win != 0 || map == null) return; var p = getP(id); if (p == null || !p.alive) return; p.lastSeen = now();
    if (id == guardId) { gAction(a); return; } if (p.role != 1 || p.charId < 0 || p.charId >= chars.length) return; var c = chars[p.charId];
    if (a == "ability") { if (gt < p.cd) return; p.cd = gt + c.cd; applyA(p, c); }
    else if (a == "enterL") ent(p, 0); else if (a == "enterR") ent(p, 1);
    else if (a == "forceL") forc(p, 0, c); else if (a == "forceR") forc(p, 1, c);
    else if (a == "vent") ven(p, c); else if (a == "attack") atk(p, c); }

  void gAction(String a) { if (black || lock > gt) return;
    if (a == "doorL" && fL <= gt) { ldC = !ldC; dL = 0; } else if (a == "doorR" && fR <= gt) { rdC = !rdC; dR = 0; }
    else if (a == "flash") fl = !fl; else if (a == "cam") cam = !cam; }

  void ent(PlayerNet p, int s) { if (p.inside || map == null) return; var d = s == 0 ? map!.ld : map!.rd; if ((Offset(p.x, p.y) - d).distance > 3) return; if (s == 0 ? ldC : rdC) return;
    p.inside = true; p.entrySide = s; p.roomId = -2; var i = s == 0 ? map!.il : map!.ir; p.x = i.dx; p.y = i.dy; burst(i, Colors.red, 14); if (p.id == myId) { myIn = true; pos = i; } }
  void forc(PlayerNet p, int s, CharDef c) { if (p.inside || map == null) return; var d = s == 0 ? map!.ld : map!.rd; if ((Offset(p.x, p.y) - d).distance > 3) return; if (!(s == 0 ? ldC : rdC)) return; if ((s == 0 ? fL : fR) > gt) return;
    double dm = 25; if (c.passive == "door") dm *= 1.5; burst(d, Colors.orange, 10); shake = max(shake, 0.5);
    if (s == 0) { dL += dm; if (dL >= 100) { dL = 0; ldC = false; fL = gt + 5; } } else { dR += dm; if (dR >= 100) { dR = 0; rdC = false; fR = gt + 5; } } }
  void ven(PlayerNet p, CharDef c) { if (p.inside || map == null) return; if ((Offset(p.x, p.y) - map!.vt).distance > 3) return;
    p.vent += (c.passive == "vent" ? 0.6 : 0.34); if (p.vent >= 1) { p.vent = 0; p.inside = true; p.entrySide = 2; p.roomId = -2; p.x = map!.iv.dx; p.y = map!.iv.dy; burst(map!.iv, Colors.yellow, 12); if (p.id == myId) { myIn = true; pos = Offset(p.x, p.y); } } }
  void atk(PlayerNet p, CharDef c) { if (!p.inside || map == null) return; bool rep = false;
    if (fl && !black && p.light < gt) rep = (c.passive == "light") ? rnd.nextBool() : true;
    if (rep) { var o = outS(p.entrySide); p.inside = false; p.vent = 0; p.x = o.dx; p.y = o.dy; p.roomId = roomAt(o); p.cd = max(p.cd, gt + 2); burst(o, Colors.blue, 12); if (p.id == myId) { myIn = false; pos = o; } }
    else { jump = 1.2; shake = 1.5; burst(Offset(p.x, p.y), Colors.red, 40); endG(2, "${p.name} yakaladı"); } }
  Offset outS(int s) { if (map == null) return Offset.zero; if (s == 0) return map!.ld; if (s == 1) return map!.rd; return map!.vt; }

  void applyA(PlayerNet p, CharDef c) { if (map == null) return;
    if (c.active == "speed") p.boost = gt + 4;
    else if (c.active == "dash") { var d = map!.office.center - Offset(p.x, p.y); if (d.distance > 0.1) { var t = Offset(p.x, p.y) + (d / d.distance) * 4; if (walkF(t, p)) { p.x = t.dx; p.y = t.dy; burst(t, c.color, 10); if (p.id == myId) pos = t; } } }
    else if (c.active == "camjam") jam = gt + 5;
    else if (c.active == "doorbreak") { if ((Offset(p.x, p.y) - map!.ld).distance < 3.5) { ldC = false; fL = gt + 5; burst(map!.ld, Colors.orange, 16); } else if ((Offset(p.x, p.y) - map!.rd).distance < 3.5) { rdC = false; fR = gt + 5; burst(map!.rd, Colors.orange, 16); } }
    else if (c.active == "ventrush") { if ((Offset(p.x, p.y) - map!.vt).distance < 3.5) { p.inside = true; p.entrySide = 2; p.roomId = -2; p.x = map!.iv.dx; p.y = map!.iv.dy; if (p.id == myId) { myIn = true; pos = Offset(p.x, p.y); } } }
    else if (c.active == "drain") { if ((Offset(p.x, p.y) - map!.office.center).distance < 10) en = max(0.0, en - 10); }
    else if (c.active == "lightimmune") p.light = gt + 5;
    else if (c.active == "silent") p.silent = gt + 5;
    else if (c.active == "noise") { if (map!.rooms.isNotEmpty) { nRoom = rnd.nextInt(map!.rooms.length); nUntil = gt + 3; } }
    else if (c.active == "fear") lock = gt + 3; }

  bool walkF(Offset o, PlayerNet p) { if (map == null) return false; if (p.role == 0) return map!.office.contains(o); if (p.inside) return map!.office.contains(o); if (map!.office.contains(o)) return false; for (var r in map!.rooms) if (r.r.contains(o)) return true; return false; }
  bool walk(Offset o) { if (map == null) return false; if (myRole == 0) return map!.office.contains(o); if (myIn) return map!.office.contains(o); if (map!.office.contains(o)) return false; for (var r in map!.rooms) if (r.r.contains(o)) return true; return false; }

  void bSnap() { if (!isHost || page != 3) return; var ents = <Map>[];
    for (var p in pl) { if (!p.alive) continue; bool hid = false; if (p.role == 1 && p.charId >= 0 && p.charId < chars.length) { if (p.silent > gt) hid = true; var pa = chars[p.charId].passive; if (pa == "quiet" || pa == "ghost") hid = true; }
      ents.add({"id": p.id, "ch": p.charId, "rl": p.role, "x": p.x, "y": p.y, "rm": p.roomId, "mv": p.moving, "io": p.inside, "cd": max(0.0, p.cd - gt), "hid": hid, "sp": p.boost > gt}); }
    for (var a in ai) ents.add({"id": a.id, "ch": a.charId, "rl": 2, "x": a.x, "y": a.y, "rm": a.roomId, "mv": a.moving, "io": false, "cd": 0.0, "hid": false, "sp": false});
    toAll({"t": "snap", "p": {"t": gt, "e": en.round(), "ld": ldC, "rd": rdC, "fl": fl, "cam": cam, "jam": max(0.0, jam - gt), "black": black, "w": win, "g": guardId, "nr": nRoom, "nu": nUntil, "ents": ents}}); }

  void snap(Map p) { if (page != 3) return; gt = gd(p["t"]); en = gd(p["e"]); ldC = gb(p["ld"]); rdC = gb(p["rd"]); fl = gb(p["fl"]); cam = gb(p["cam"]); jam = gt + gd(p["jam"]); black = gb(p["black"]); guardId = gi(p["g"]); nRoom = gi(p["nr"]); nUntil = gd(p["nu"]);
    if (gi(p["w"]) > 0) { endL(gi(p["w"]), gs(p["m"])); return; } rem.clear();
    if (p["ents"] is List) for (var it in p["ents"]) { var e = (it as Map).cast<String, dynamic>(); int id = gi(e["id"]);
      if (id == myId) { myIn = gb(e["io"]); myCd = gd(e["cd"]); myB = gb(e["sp"]); var hp = Offset(gd(e["x"]), gd(e["y"])); if ((pos - hp).distance > 5) pos = hp; continue; }
      rem[id] = EntityView(id, gi(e["ch"]), gi(e["rl"]), gd(e["x"]), gd(e["y"]), gi(e["rm"]), gb(e["mv"]), gb(e["hid"]), gb(e["io"]), col(gi(e["ch"]))); }
    lastHost = now(); }

  void endG(int w, String m) { if (page != 3 || win != 0) return; win = w; toAll({"t": "over", "p": {"w": w, "m": m}}); endL(w, m); }
  void endL(int w, String m) { if (page == 4) return; win = w; endMsg = m; page = 4; loop?.cancel(); loop = null; ui(); }
  void rmP(int id) { if (id == 0) return; if (page == 3 && id == guardId) { pl.removeWhere((p) => p.id == id); eps.remove(id); endG(2, "Güvenlik ayrıldı"); return; }
    pl.removeWhere((p) => p.id == id); eps.remove(id); if (page == 2) lob(); else if (page == 3 && !pl.any((p) => p.role == 1 && p.alive)) endG(1, "Kalmadı"); }

  void burst(Offset o, Color c, int n) { if (!pOn || q.cap == 0) return; int k = min(n, q.cap - parts.length);
    for (int i = 0; i < k; i++) { double a = rnd.nextDouble() * 2 * pi; double s = 1 + rnd.nextDouble() * 4; parts.add(Particle(o.dx, o.dy, cos(a) * s, sin(a) * s, 0.4 + rnd.nextDouble() * 0.5, 0.2 + rnd.nextDouble() * 0.4, c)); } }
  void upParts(double dt) { for (int i = parts.length - 1; i >= 0; i--) { var p = parts[i]; p.x += p.vx * dt; p.y += p.vy * dt; p.vx *= 0.92; p.vy *= 0.92; p.life -= dt; if (p.life <= 0) parts.removeAt(i); } }

  PlayerNet? getP(int id) { for (var p in pl) if (p.id == id) return p; return null; }
  int roomAt(Offset o) { if (map == null) return -1; if (map!.office.contains(o)) return -2; for (int i = 0; i < map!.rooms.length; i++) if (map!.rooms[i].r.contains(o)) return i; return -1; }
  Offset rndS() { if (map == null || map!.rooms.isEmpty) return const Offset(20, 20); var r = map!.rooms[rnd.nextInt(map!.rooms.length)].r;
    double mx = min(1.0, r.width * 0.25), my = min(1.0, r.height * 0.25);
    double x1 = r.left + mx, x2 = r.right - mx, y1 = r.top + my, y2 = r.bottom - my;
    if (x2 < x1) x1 = x2 = r.center.dx; if (y2 < y1) y1 = y2 = r.center.dy;
    return Offset(x1 + rnd.nextDouble() * (x2 - x1), y1 + rnd.nextDouble() * (y2 - y1)); }
  int freeC(List<int> u) { for (int i = 0; i < 100; i++) { int c = rnd.nextInt(chars.length); if (!u.contains(c)) return c; } for (int c = 0; c < chars.length; c++) if (!u.contains(c)) return c; return 0; }
  String cn(int id) => (id < 0 || id >= chars.length) ? "?" : chars[id].name;
  Color col(int id) => (id < 0 || id >= chars.length) ? Colors.white : chars[id].color;

  List<EntityView> views() { var v = <EntityView>[];
    if (isHost) { for (var p in pl) { if (!p.alive) continue; bool hid = false; if (p.role == 1 && p.charId >= 0 && p.charId < chars.length) { if (p.silent > gt) hid = true; var pa = chars[p.charId].passive; if (pa == "quiet" || pa == "ghost") hid = true; }
        v.add(EntityView(p.id, p.charId, p.role, p.x, p.y, p.roomId, p.moving, hid, p.inside, p.role == 0 ? Colors.cyan : col(p.charId))); }
      for (var a in ai) v.add(EntityView(a.id, a.charId, 2, a.x, a.y, a.roomId, a.moving, false, false, col(a.charId))); }
    else { v.addAll(rem.values); if (myRole == 1) v.add(EntityView(myId, myChar, 1, pos.dx, pos.dy, roomAt(pos), mov, false, myIn, col(myChar))); }
    return v; }

  String det() { if (map == null || camRoom < 0 || camRoom >= map!.rooms.length) return ""; if (jam > gt) return "PARAZİT";
    var n = <String>[]; for (var v in views()) if (v.role != 0 && !v.inside && v.room == camRoom && v.moving && !v.hidden) n.add(cn(v.charId));
    String t = ""; if (nRoom == camRoom && nUntil > gt) t += "SES!\n"; t += n.isEmpty ? "Temiz." : "Hareket: ${n.join(', ')}"; return t; }
  String clock() { int h = ((gt / night).clamp(0.0, 1.0) * 6).floor(); if (h >= 6) return "06:00"; if (h <= 0) return "12:00"; return "0$h:00"; }

  @override
  Widget build(BuildContext c) => Scaffold(body: ColoredBox(color: const Color(0xFF050508), child: SafeArea(child: Builder(builder: (_) {
    if (page == 0) return menuW(); if (page == 1) return discW(); if (page == 2) return lobW(); if (page == 3) return gameW(); return endW(); }))));

  Widget btn(String t, VoidCallback on, {Color? bg, bool en = true, bool sm = false}) => ElevatedButton(onPressed: en ? on : null,
    style: ElevatedButton.styleFrom(backgroundColor: bg ?? Colors.grey[850], disabledBackgroundColor: Colors.grey[900]),
    child: Padding(padding: EdgeInsets.all(sm ? 8 : 12), child: Text(t, textAlign: TextAlign.center, style: TextStyle(fontSize: sm ? 13 : 18))));

  Widget menuW() => Padding(padding: const EdgeInsets.all(20), child: Column(children: [
    const Text("DARKESCAS", style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: Color(0xFFB388FF))),
    const Text("LAN Korku", style: TextStyle(color: Colors.white54)), const SizedBox(height: 12),
    Text(status, textAlign: TextAlign.center), const SizedBox(height: 20),
    btn("HOST OL", hostGame), btn("OYUN BUL", openDisc),
    TextField(controller: ipCtrl, keyboardType: TextInputType.number, style: const TextStyle(fontSize: 18),
      decoration: InputDecoration(hintText: "192.168.1.x", filled: true, fillColor: Colors.grey[900], border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
    const SizedBox(height: 10), btn("IP İLE KATIL", joinIp), const SizedBox(height: 10),
    btn("GRAFİK AYARLARI", () { showSet = true; ui(); }), const SizedBox(height: 16),
    Text("Kalite: ${qN()}", style: const TextStyle(color: Colors.white70)), const Expanded(child: SizedBox()) ]));

  Widget discW() => Column(children: [
    const Padding(padding: EdgeInsets.all(16), child: Text("Ağdaki Oyunlar", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
    Text(disc.isEmpty ? "Aranıyor..." : "${disc.length} oda"),
    Expanded(child: ListView.builder(itemCount: disc.length, itemBuilder: (c, i) { var d = disc[i];
      return Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6), child: btn("${d.s}\n${d.c}/$maxP - Harita ${d.m + 1}", () => joinD(d))); })),
    Padding(padding: const EdgeInsets.all(16), child: btn("GERİ", menu)) ]);

  Widget lobW() { String pt = pl.map((p) => "${p.name}${p.id == 0 ? " (HOST)" : ""} - ${p.charId >= 0 && p.charId < chars.length ? chars[p.charId].name : 'Seçilmedi'}").join("\n");
    return Padding(padding: const EdgeInsets.all(16), child: Column(children: [
      const Text("LOBİ", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
      Text(status, style: const TextStyle(color: Colors.white60)), const SizedBox(height: 6), Text(pt, textAlign: TextAlign.center), const SizedBox(height: 10),
      Text("Harita: ${mkMap(curMap).name}"),
      Row(children: [ Expanded(child: btn("Harita 1", () => setM(0), bg: curMap == 0 ? Colors.teal : null)), const SizedBox(width: 8), Expanded(child: btn("Harita 2", () => setM(1), bg: curMap == 1 ? Colors.teal : null)) ]),
      const SizedBox(height: 8), btn("OYUNU BAŞLAT", startHost, en: isHost && pl.length >= 2), const SizedBox(height: 8),
      Expanded(child: ListView.builder(itemCount: chars.length, itemBuilder: (c, i) { bool me = false, ot = false; for (var p in pl) if (p.charId == i) { if (p.id == myId) me = true; else ot = true; }
        Color bg = Colors.grey[850]!; if (me) bg = Colors.green[800]!; if (ot) bg = Colors.red[900]!;
        return Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: btn(chars[i].name, () => selC(i), bg: bg, en: !ot || me, sm: true)); })),
      btn("AYRIL", menu) ])); }

  Widget gameW() { var v = views(); bool ca = cam && !black; String top = "${clock()} | Enerji %${en.round()}";
    if (black) top += " | KARANLIK"; if (jam > gt) top += " | PARAZİT"; if (v.any((x) => x.role == 1 && x.inside)) top += " | OFİSTE BİRİ";
    return Stack(children: [
      Positioned.fill(child: ValueListenableBuilder<int>(valueListenable: frame, builder: (c, f, w) => CustomPaint(painter: GP(map, v, q, pOn ? parts : const [], shake, jump, myRole, pos, fl, black, ldC, rdC, ca && myRole == 0, rnd)))),
      Positioned(top: 8, left: 8, right: 8, child: Container(padding: const EdgeInsets.all(8), color: Colors.black54, child: Row(children: [
        Expanded(child: Text(top, textAlign: TextAlign.center, style: const TextStyle(fontSize: 14))),
        IconButton(icon: const Icon(Icons.settings, size: 20), onPressed: () { showSet = true; ui(); }) ]))),
      if (ca && myRole == 0) camW(), if (myRole == 0) guardW(), if (myRole == 1) animW(), if (showSet) setW() ]); }

  Widget camW() { if (map == null) return const SizedBox();
    return Positioned(top: 50, left: 8, right: 8, height: 210, child: Container(padding: const EdgeInsets.all(8), color: const Color(0xDD001400), child: Column(children: [
      Text("KAMERA: ${map!.rooms[camRoom].name}", style: const TextStyle(color: Color(0xFF66FF66))), const SizedBox(height: 4),
      Expanded(child: Text(det(), style: const TextStyle(color: Color(0xFF66FF66)))),
      SizedBox(height: 56, child: ListView.builder(scrollDirection: Axis.horizontal, itemCount: map!.rooms.length, itemBuilder: (c, i) =>
        Padding(padding: const EdgeInsets.only(right: 6), child: btn(map!.rooms[i].name, () { camRoom = i; ui(); }, bg: camRoom == i ? Colors.green[900] : Colors.black, sm: true)))) ]))); }

  Widget guardW() => Positioned(left: 8, right: 8, bottom: 8, height: 76, child: Row(children: [
    Expanded(child: btn(ldC ? "SOL KAPALI" : "SOL AÇIK", () => gAct("doorL"), bg: ldC ? Colors.red[900] : Colors.green[900], sm: true)), const SizedBox(width: 6),
    Expanded(child: btn(rdC ? "SAĞ KAPALI" : "SAĞ AÇIK", () => gAct("doorR"), bg: rdC ? Colors.red[900] : Colors.green[900], sm: true)), const SizedBox(width: 6),
    Expanded(child: btn("FENER", () => gAct("flash"), bg: fl ? Colors.yellow[800] : Colors.grey[850], sm: true)), const SizedBox(width: 6),
    Expanded(child: btn("KAMERA", () => gAct("cam"), bg: cam ? Colors.blue[900] : Colors.grey[850], sm: true)) ]));

  Widget animW() => Positioned.fill(child: Stack(children: [
    Positioned(left: 20, bottom: 20, child: joyW()),
    Positioned(right: 20, bottom: 110, width: 170, height: 64, child: btn(myCd > 0 ? "YETENEK ${myCd.ceil()}s" : "YETENEK", abil, bg: myCd <= 0 ? Colors.purple[800] : Colors.grey[850], en: myCd <= 0, sm: true)),
    Positioned(right: 20, bottom: 30, width: 170, height: 64, child: btn(ctxL(), inter, bg: ctx() == "none" ? Colors.grey[850] : Colors.orange[900], en: ctx() != "none", sm: true)) ]));

  String ctxL() { var a = ctx(); if (a == "attack") return "SALDIR!"; if (a == "enterL") return "SOLDAN SIZ"; if (a == "enterR") return "SAĞDAN SIZ"; if (a == "forceL") return "SOL ZORLA"; if (a == "forceR") return "SAĞ ZORLA"; if (a == "vent") return "HAVALANDIRMA"; return "ETKİLEŞİM"; }

  Widget joyW() => GestureDetector(onPanStart: (d) => joy(d.localPosition), onPanUpdate: (d) => joy(d.localPosition),
    onPanEnd: (_) { jt = Offset.zero; jx = 0; jy = 0; ui(); },
    child: Container(width: 150, height: 150, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white10, border: Border.all(color: Colors.white24)),
      child: Stack(children: [ Positioned(left: 75 + jt.dx - 30, top: 75 + jt.dy - 30, child: Container(width: 60, height: 60, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white38))) ])));
  void joy(Offset l) { var v = l - const Offset(75, 75); double d = v.distance; if (d > 60) v = (v / d) * 60; jt = v; jx = v.dx / 60; jy = v.dy / 60; }

  Widget setW() => Positioned.fill(child: Material(color: Colors.black87, child: Center(child: Container(width: 300, padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(color: const Color(0xFF141220), borderRadius: BorderRadius.circular(16)),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Text("GRAFİK AYARLARI", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)), const SizedBox(height: 12),
      Row(children: [ Expanded(child: btn("Düşük", () => setQ(Quality.low), bg: quality == Quality.low ? Colors.teal : null, sm: true)), const SizedBox(width: 6),
        Expanded(child: btn("Orta", () => setQ(Quality.medium), bg: quality == Quality.medium ? Colors.teal : null, sm: true)), const SizedBox(width: 6),
        Expanded(child: btn("Yüksek", () => setQ(Quality.high), bg: quality == Quality.high ? Colors.teal : null, sm: true)) ]),
      const SizedBox(height: 10), btn(pOn ? "Parçacıklar: AÇIK" : "Parçacıklar: KAPALI", () { pOn = !pOn; ui(); }, sm: true), const SizedBox(height: 8),
      Text("Kalite: ${qN()}", style: const TextStyle(color: Colors.white60)), const SizedBox(height: 12),
      btn
