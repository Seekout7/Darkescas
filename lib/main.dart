import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';

void main() => runApp(const GameApp());
class GameApp extends StatelessWidget {
  const GameApp({super.key});
  @override
  Widget build(BuildContext c) => MaterialApp(debugShowCheckedModeBanner: false, theme: ThemeData.dark(), home: const GS());
}

enum Quality { low, medium, high }
class GQ { bool glow, vig, noise, shake; GQ(this.glow, this.vig, this.noise, this.shake);
  static GQ of(Quality q) => q == Quality.low ? GQ(false, false, false, false) : q == Quality.medium ? GQ(true, true, true, false) : GQ(true, true, true, true); }

class Ep { final InternetAddress a; final int p; Ep(this.a, this.p); }
class PN { final int id; String name; int charId, role, room, side; double x, y, seen, cd, boost, silent, light, vent; bool mv, inside, alive;
  PN(this.id, this.name, {this.charId = -1, this.role = -1, this.x = 0, this.y = 0, this.room = -1, this.side = 0, this.seen = 0, this.cd = 0, this.boost = 0, this.silent = 0, this.light = 0, this.vent = 0, this.mv = false, this.inside = false, this.alive = true}); }
class EV { final int id, ch, role, room; final double x, y; final bool mv, hid, inside; final Color color; EV(this.id, this.ch, this.role, this.x, this.y, this.room, this.mv, this.hid, this.inside, this.color); }
class Room { final String n; final Rect r; Room(this.n, this.r); }
class MD { final String n; final Rect of; final Offset ld, rd, vt, il, ir, iv; final List<Room> rooms; MD(this.n, this.of, this.ld, this.rd, this.vt, this.il, this.ir, this.iv, this.rooms); }
class CD { final String n, act, pas; final Color color; final double sp, cd; CD(this.n, int c, this.sp, this.cd, this.act, this.pas) : color = Color(c); }
class DH { final String a; final int p; String s; int c, m; double last; DH(this.a, this.p, this.s, this.c, this.m, this.last); }

class GS extends StatefulWidget { const GS({super.key}); @override State<GS> createState() => _S(); }

class _S extends State<GS> {
  static const int port = 47777; static const double night = 240.0; static const int maxP = 4;
  final rnd = Random(); final ipc = TextEditingController(); Timer? loop, slow; final fr = ValueNotifier<int>(0); double acc = 0;
  Quality quality = Quality.medium; late GQ q = GQ.of(quality); bool showSet = false;
  int page = 0, myId = -1, guard = -1, myRole = -1, myChar = -1, curMap = 0, camRoom = 0;
  bool isHost = false; String myName = "", status = "", endMsg = "";
  RawDatagramSocket? sock; InternetAddress? hA; int hP = port;
  final Map<int, Ep> eps = {}; final List<PN> pl = []; final List<DH> disc = []; final Map<int, EV> rem = {};
  late List<CD> chars; MD? map;
  double tD = 0, tP = 0, tH = 0, tL = 0, tS = 0, tN = 0;
  double gt = 0, en = 100; bool ldC = true, rdC = true, fl = false, cam = false, black = false; int win = 0, nR = -1;
  double fL = 0, fR = 0, dL = 0, dR = 0, jam = 0, lock = 0, nU = 0;
  Offset pos = Offset.zero; bool mv = false, myIn = false, myB = false; double myCd = 0;
  Offset jt = Offset.zero; double jx = 0, jy = 0, shake = 0, jump = 0;

  @override void initState() { super.initState(); myName = "Oyuncu${rnd.nextInt(900) + 100}"; chars = mkChars(); slow = Timer.periodic(const Duration(seconds: 1), slowT); }
  @override void dispose() { loop?.cancel(); slow?.cancel(); try { sock?.close(); } catch (_) {} ipc.dispose(); super.dispose(); }
  void ui() { if (mounted) setState(() {}); }
  double now() => DateTime.now().millisecondsSinceEpoch / 1000.0;
  void setQ(Quality v) { quality = v; q = GQ.of(v); ui(); }
  String qN() => quality == Quality.low ? "Düşük" : quality == Quality.medium ? "Orta" : "Yüksek";

  Future<bool> hSock() async { cN(); try { sock = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port); sock!.broadcastEnabled = true; sock!.listen(onS); return true; } catch (e) { status = "Host hatası"; return false; } }
  Future<bool> cSock() async { cN(); try { sock = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0); sock!.broadcastEnabled = true; sock!.listen(onS); return true; } catch (e) { status = "Socket hatası"; return false; } }
  void cN() { try { sock?.close(); } catch (_) {} sock = null; }
  void onS(RawSocketEvent e) { if (e != RawSocketEvent.read) return; var dg = sock?.receive(); if (dg == null) return;
    try { var m = (jsonDecode(utf8.decode(dg.data)) as Map).cast<String, dynamic>(); var p = m["p"] is Map ? (m["p"] as Map).cast<String, dynamic>() : <String, dynamic>{};
      if (isHost) hPk(gs(m["t"]), p, dg); else cPk(gs(m["t"]), p, dg); } catch (_) {} }
  void snd(Map d, InternetAddress a, int p) { try { sock?.send(utf8.encode(jsonEncode(d)), a, p); } catch (_) {} }
  void toH(Map d) { if (hA != null) snd(d, hA!, hP); }
  void toA(Map d) { if (!isHost) return; for (var e in eps.values) snd(d, e.a, e.p); }
  int epId(InternetAddress a, int p) { for (var e in eps.entries) if (e.value.a.address == a.address && e.value.p == p) return e.key; return -1; }

  void hPk(String t, Map p, Datagram dg) {
    if (t == "discover") { if (page == 2) snd({"t": "hostinfo", "p": {"name": myName, "count": pl.length, "map": curMap}}, dg.address, dg.port); return; }
    if (t == "hello") { int ex = epId(dg.address, dg.port); if (ex != -1) { snd({"t": "welcome", "p": {"id": ex}}, dg.address, dg.port); return; }
      if (page != 2 || pl.length >= maxP) { snd({"t": "err", "p": {"m": "Katılamazsın"}}, dg.address, dg.port); return; }
      int id = 1; while (pl.any((x) => x.id == id)) id++;
      pl.add(PN(id, gs(p["name"]).isEmpty ? "Oyuncu$id" : gs(p["name"]), seen: now()));
      eps[id] = Ep(dg.address, dg.port); snd({"t": "welcome", "p": {"id": id}}, dg.address, dg.port); lob(); return; }
    int id = epId(dg.address, dg.port); if (id == -1) return; var me = getP(id); if (me != null) me.seen = now();
    if (t == "ping") return;
    if (t == "leave") { rmP(id); return; }
    if (t == "char" && page == 2) { selH(id, gi(p["c"])); return; }
    if (t == "state" && page == 3 && me != null && me.role == 1) { me.x = gd(p["x"]); me.y = gd(p["y"]); me.mv = gb(p["mv"]); if (map != null) me.room = roomAt(Offset(me.x, me.y)); return; }
    if (t == "act" && page == 3) act(id, gs(p["a"]));
  }

  void cPk(String t, Map p, Datagram dg) {
    tH = now();
    if (t == "hostinfo" && page == 1) { String k = dg.address.address; DH? f; for (var d in disc) if (d.a == k) f = d;
      if (f == null) disc.add(DH(k, dg.port, gs(p["name"]), gi(p["count"]), gi(p["map"]), now())); else { f.s = gs(p["name"]); f.c = gi(p["count"]); f.m = gi(p["map"]); f.last = now(); } ui(); return; }
    if (t == "welcome") { myId = gi(p["id"]); page = 2; status = "Lobidesin"; ui(); return; }
    if (t == "lobby") { pl.clear(); curMap = gi(p["map"]); if (p["players"] is List) for (var it in p["players"]) { var q2 = (it as Map).cast<String, dynamic>(); pl.add(PN(gi(q2["id"]), gs(q2["name"]), charId: gi(q2["char"]))); } if (page == 2) ui(); return; }
    if (t == "start") { startFrom(p); return; }
    if (t == "snap") { snap(p); return; }
    if (t == "over") { endL(gi(p["w"]), gs(p["m"])); return; }
    if (t == "err") { status = gs(p["m"]); page = 0; cN(); ui(); return; }
    if (t == "closed") { cN(); page = 0; status = "Host kapattı"; ui(); return; }
  }

  Future<void> hostGame() async { if (!await hSock()) { ui(); return; } isHost = true; myId = 0; guard = -1; myRole = -1; myChar = -1; curMap = 0;
    pl.clear(); eps.clear(); rem.clear(); pl.add(PN(0, myName, seen: now())); page = 2; status = "Host hazır"; lob(); ui(); }
  Future<void> openDisc() async { if (!await cSock()) { ui(); return; } isHost = false; myId = -1; disc.clear(); page = 1; d0(); tD = now(); ui(); }
  void d0() { try { snd({"t": "discover"}, InternetAddress("255.255.255.255"), port); } catch (_) {} }
  Future<void> joinIp() async { InternetAddress? a; try { a = InternetAddress(ipc.text.trim()); } catch (_) {} if (a == null) { status = "Geçerli IP gir"; ui(); return; }
    if (!await cSock()) { ui(); return; } isHost = false; myId = -1; hA = a; hP = port; hello(); page = 0; status = "Bağlanıyor"; tH = now(); ui(); }
  void joinD(DH d) { try { hA = InternetAddress(d.a); hP = d.port; hello(); page = 0; status = "Bağlanıyor"; tH = now(); ui(); } catch (_) {} }
  void hello() => toH({"t": "hello", "p": {"name": myName}});
  void menu() { if (isHost) toA({"t": "closed"}); else toH({"t": "leave"}); loop?.cancel(); loop = null; cN();
    isHost = false; page = 0; myId = -1; guard = -1; myRole = -1; myChar = -1; win = 0;
    pl.clear(); eps.clear(); rem.clear(); disc.clear(); status = "Ana menü"; ui(); }

  void selC(int c) { if (page != 2) return; if (isHost) selH(myId, c); else toH({"t": "char", "p": {"c": c}}); }
  void selH(int id, int c) { if (page != 2 || c < 0 || c >= chars.length) return; var me = getP(id); if (me == null) return;
    for (var o in pl) if (o.id != id && o.charId == c) { status = "Seçili"; lob(); return; } me.charId = c; lob(); }
  void setM(int m) { if (!isHost || page != 2) return; curMap = (m < 0) ? 0 : (m > 1 ? 1 : m); lob(); }
  void lob() { if (!isHost) return; toA({"t": "lobby", "p": {"map": curMap, "players": pl.map((p) => {"id": p.id, "name": p.name, "char": p.charId}).toList()}}); tL = now(); ui(); }

  void startHost() { if (!isHost || page != 2 || pl.length < 2) { status = "En az 2 oyuncu"; ui(); return; }
    map = mkMap(curMap); reset(); var ids = pl.map((e) => e.id).toList(); guard = ids[rnd.nextInt(ids.length)]; var used = <int>[];
    for (var p in pl) { if (p.id == guard) { p.role = 0; p.charId = -1; p.x = map!.of.center.dx; p.y = map!.of.center.dy; p.inside = true; p.room = -2; }
      else { p.role = 1; if (p.charId < 0 || p.charId >= chars.length || used.contains(p.charId)) p.charId = freeC(used); used.add(p.charId);
        var s = rndS(); p.x = s.dx; p.y = s.dy; p.inside = false; p.room = roomAt(s); }
      p.alive = true; p.mv = false; p.cd = 0; p.boost = 0; p.silent = 0; p.light = 0; p.vent = 0;
      if (p.id == myId) { myRole = p.role; myChar = p.charId; pos = Offset(p.x, p.y); myIn = p.inside; } }
    toA({"t": "start", "p": {"map": curMap, "guard": guard, "players": pl.map((p) => {"id": p.id, "char": p.charId, "role": p.role, "x": p.x, "y": p.y}).toList()}});
    page = 3; startLoop(); ui(); }

  void startFrom(Map p) { reset(); curMap = gi(p["map"]); guard = gi(p["guard"]); map = mkMap(curMap); pl.clear(); rem.clear();
    if (p["players"] is List) for (var it in p["players"]) { var q2 = (it as Map).cast<String, dynamic>(); int id = gi(q2["id"]); int ch = gi(q2["char"]); int rl = gi(q2["role"]); double x = gd(q2["x"]), y = gd(q2["y"]);
      if (id == myId) { myRole = rl; myChar = ch; pos = Offset(x, y); myIn = rl == 0; } else rem[id] = EV(id, ch, rl, x, y, rl == 0 ? -2 : roomAt(Offset(x, y)), false, false, rl == 0, col(ch)); }
    page = 3; startLoop(); ui(); }

  void reset() { gt = 0; en = 100; ldC = true; rdC = true; fl = false; cam = false; black = false; win = 0; endMsg = "";
    fL = 0; fR = 0; dL = 0; dR = 0; jam = 0; lock = 0; nR = -1; nU = 0; mv = false; myIn = myRole == 0; myCd = 0; myB = false; camRoom = 0; shake = 0; jump = 0; }
  void startLoop() { loop?.cancel(); loop = Timer.periodic(const Duration(milliseconds: 16), tick); }

  void tick(Timer t) { if (page != 3) return; const double dt = 1 / 60;
    if (win == 0) { if (myRole == 1) moveL(dt); if (isHost) hostU(dt); else if (myRole == 1 && now() - tS > 0.1) sendS(); }
    shake = max(0.0, shake - dt * 3); jump = max(0.0, jump - dt); fr.value++; acc += dt; if (acc > 0.1) { acc = 0; ui(); } }

  void slowT(Timer t) { double n = now();
    if (page == 1) { if (n - tD > 2) { tD = n; d0(); } int b = disc.length; disc.removeWhere((d) => n - d.last > 6); if (b != disc.length) ui(); }
    if (!isHost && (page == 2 || page == 3)) { if (n - tH > 10) { menu(); return; } if (n - tP > 2) { tP = n; toH({"t": "ping"}); } }
    if (isHost && page == 2 && n - tL > 2) lob();
    if (isHost && (page == 2 || page == 3)) for (int i = pl.length - 1; i >= 0; i--) if (pl[i].id != 0 && n - pl[i].seen > 10) rmP(pl[i].id); }

  void hostU(double dt) { if (win != 0 || map == null) return; gt += dt;
    double dr = 0.08; if (ldC) dr += 0.4; if (rdC) dr += 0.4; if (fl) dr += 0.35; if (cam) dr += 0.5;
    en -= dr * dt; if (en <= 0 && !black) { en = 0; black = true; ldC = false; rdC = false; fl = false; cam = false; } if (black) en = 0;
    if (gt >= night) { endG(1, "Güvenlik dayandı"); return; }
    var me = getP(myId); if (me != null) { myIn = me.inside; myCd = max(0.0, me.cd - gt); myB = me.boost > gt; }
    if (now() - tN > 0.1) { tN = now(); bSnap(); } }

  void moveL(double dt) { if (page != 3 || win != 0 || myRole != 1 || map == null) return; var d = Offset(jx, jy); mv = d.distance > 0.1;
    if (mv) { if (d.distance > 1) d = d / d.distance; double sp = spd(); var n = pos + d * sp * dt;
      if (walk(n)) pos = n; else { var nx = pos + Offset(d.dx * sp * dt, 0); if (walk(nx)) pos = nx; var ny = pos + Offset(0, d.dy * sp * dt); if (walk(ny)) pos = ny; } }
    if (isHost) { var me = getP(myId); if (me != null) { me.x = pos.dx; me.y = pos.dy; me.mv = mv; me.room = roomAt(pos); } } }
  double spd() { double s = 3.2; if (myChar >= 0 && myChar < chars.length) { s = chars[myChar].sp; if (chars[myChar].pas == "speed") s *= 1.15; } if (myB) s *= 1.6; if (myIn) s *= 0.85; return s; }
  void sendS() { tS = now(); toH({"t": "state", "p": {"x": pos.dx, "y": pos.dy, "mv": mv}}); }

  void gAct(String a) { if (page != 3 || myRole != 0 || win != 0) return; if (isHost) act(myId, a); else toH({"t": "act", "p": {"a": a}}); }
  void inter() { if (page != 3 || myRole != 1 || win != 0) return; var a = ctx(); if (a == "none") return; if (isHost) act(myId, a); else toH({"t": "act", "p": {"a": a}}); }
  void abil() { if (page != 3 || myRole != 1 || win != 0 || myCd > 0) return; if (isHost) act(myId, "ability"); else toH({"t": "act", "p": {"a": "ability"}}); }
  String ctx() { if (page != 3 || map == null || myRole != 1) return "none"; if (myIn) return "attack";
    if ((pos - map!.ld).distance < 3) return ldC ? "forceL" : "enterL";
    if ((pos - map!.rd).distance < 3) return rdC ? "forceR" : "enterR";
    if ((pos - map!.vt).distance < 3) return "vent"; return "none"; }

  void act(int id, String a) { if (page != 3 || win != 0 || map == null) return; var p = getP(id); if (p == null || !p.alive) return; p.seen = now();
    if (id == guard) { gAction(a); return; } if (p.role != 1 || p.charId < 0 || p.charId >= chars.length) return; var c = chars[p.charId];
    if (a == "ability") { if (gt < p.cd) return; p.cd = gt + c.cd; applyA(p, c); }
    else if (a == "enterL") ent(p, 0); else if (a == "enterR") ent(p, 1);
    else if (a == "forceL") forc(p, 0, c); else if (a == "forceR") forc(p, 1, c);
    else if (a == "vent") ven(p, c); else if (a == "attack") atk(p, c); }

  void gAction(String a) { if (black || lock > gt) return;
    if (a == "doorL" && fL <= gt) { ldC = !ldC; dL = 0; } else if (a == "doorR" && fR <= gt) { rdC = !rdC; dR = 0; }
    else if (a == "flash") fl = !fl; else if (a == "cam") cam = !cam; }

  void ent(PN p, int s) { if (p.inside || map == null) return; var d = s == 0 ? map!.ld : map!.rd; if ((Offset(p.x, p.y) - d).distance > 3) return; if (s == 0 ? ldC : rdC) return;
    p.inside = true; p.side = s; p.room = -2; var i = s == 0 ? map!.il : map!.ir; p.x = i.dx; p.y = i.dy; if (p.id == myId) { myIn = true; pos = i; } }
  void forc(PN p, int s, CD c) { if (p.inside || map == null) return; var d = s == 0 ? map!.ld : map!.rd; if ((Offset(p.x, p.y) - d).distance > 3) return; if (!(s == 0 ? ldC : rdC)) return; if ((s == 0 ? fL : fR) > gt) return;
    double dm = 25; if (c.pas == "door") dm *= 1.5; shake = max(shake, 0.5);
    if (s == 0) { dL += dm; if (dL >= 100) { dL = 0; ldC = false; fL = gt + 5; } } else { dR += dm; if (dR >= 100) { dR = 0; rdC = false; fR = gt + 5; } } }
  void ven(PN p, CD c) { if (p.inside || map == null) return; if ((Offset(p.x, p.y) - map!.vt).distance > 3) return;
    p.vent += (c.pas == "vent" ? 0.6 : 0.34); if (p.vent >= 1) { p.vent = 0; p.inside = true; p.side = 2; p.room = -2; p.x = map!.iv.dx; p.y = map!.iv.dy; if (p.id == myId) { myIn = true; pos = Offset(p.x, p.y); } } }
  void atk(PN p, CD c) { if (!p.inside || map == null) return; bool rep = false;
    if (fl && !black && p.light < gt) rep = (c.pas == "light") ? rnd.nextBool() : true;
    if (rep) { var o = outS(p.side); p.inside = false; p.vent = 0; p.x = o.dx; p.y = o.dy; p.room = roomAt(o); p.cd = max(p.cd, gt + 2); if (p.id == myId) { myIn = false; pos = o; } }
    else { jump = 1.2; shake = 1.5; endG(2, "${p.name} yakaladı"); } }
  Offset outS(int s) { if (map == null) return Offset.zero; if (s == 0) return map!.ld; if (s == 1) return map!.rd; return map!.vt; }

  void applyA(PN p, CD c) { if (map == null) return;
    if (c.act == "speed") p.boost = gt + 4;
    else if (c.act == "dash") { var d = map!.of.center - Offset(p.x, p.y); if (d.distance > 0.1) { var t = Offset(p.x, p.y) + (d / d.distance) * 4; if (walkF(t, p)) { p.x = t.dx; p.y = t.dy; if (p.id == myId) pos = t; } } }
    else if (c.act == "camjam") jam = gt + 5;
    else if (c.act == "doorbreak") { if ((Offset(p.x, p.y) - map!.ld).distance < 3.5) { ldC = false; fL = gt + 5; } else if ((Offset(p.x, p.y) - map!.rd).distance < 3.5) { rdC = false; fR = gt + 5; } }
    else if (c.act == "ventrush") { if ((Offset(p.x, p.y) - map!.vt).distance < 3.5) { p.inside = true; p.side = 2; p.room = -2; p.x = map!.iv.dx; p.y = map!.iv.dy; if (p.id == myId) { myIn = true; pos = Offset(p.x, p.y); } } }
    else if (c.act == "drain") { if ((Offset(p.x, p.y) - map!.of.center).distance < 10) en = max(0.0, en - 10); }
    else if (c.act == "lightimmune") p.light = gt + 5;
    else if (c.act == "silent") p.silent = gt + 5;
    else if (c.act == "noise") { if (map!.rooms.isNotEmpty) { nR = rnd.nextInt(map!.rooms.length); nU = gt + 3; } }
    else if (c.act == "fear") lock = gt + 3; }

  bool walkF(Offset o, PN p) { if (map == null) return false; if (p.role == 0) return map!.of.contains(o); if (p.inside) return map!.of.contains(o); if (map!.of.contains(o)) return false; for (var r in map!.rooms) if (r.r.contains(o)) return true; return false; }
  bool walk(Offset o) { if (map == null) return false; if (myRole == 0) return map!.of.contains(o); if (myIn) return map!.of.contains(o); if (map!.of.contains(o)) return false; for (var r in map!.rooms) if (r.r.contains(o)) return true; return false; }

  void bSnap() { if (!isHost || page != 3) return; var ents = <Map>[];
    for (var p in pl) { if (!p.alive) continue; bool hid = false; if (p.role == 1 && p.charId >= 0 && p.charId < chars.length) { if (p.silent > gt) hid = true; var pa = chars[p.charId].pas; if (pa == "quiet" || pa == "ghost") hid = true; }
      ents.add({"id": p.id, "ch": p.charId, "rl": p.role, "x": p.x, "y": p.y, "rm": p.room, "mv": p.mv, "io": p.inside, "cd": max(0.0, p.cd - gt), "hid": hid, "sp": p.boost > gt}); }
    toA({"t": "snap", "p": {"t": gt, "e": en.round(), "ld": ldC, "rd": rdC, "fl": fl, "cam": cam, "jam": max(0.0, jam - gt), "black": black, "w": win, "g": guard, "nr": nR, "nu": nU, "ents": ents}}); }

  void snap(Map p) { if (page != 3) return; gt = gd(p["t"]); en = gd(p["e"]); ldC = gb(p["ld"]); rdC = gb(p["rd"]); fl = gb(p["fl"]); cam = gb(p["cam"]); jam = gt + gd(p["jam"]); black = gb(p["black"]); guard = gi(p["g"]); nR = gi(p["nr"]); nU = gd(p["nu"]);
    if (gi(p["w"]) > 0) { endL(gi(p["w"]), gs(p["m"])); return; } rem.clear();
    if (p["ents"] is List) for (var it in p["ents"]) { var e = (it as Map).cast<String, dynamic>(); int id = gi(e["id"]);
      if (id == myId) { myIn = gb(e["io"]); myCd = gd(e["cd"]); myB = gb(e["sp"]); var hp = Offset(gd(e["x"]), gd(e["y"])); if ((pos - hp).distance > 5) pos = hp; continue; }
      rem[id] = EV(id, gi(e["ch"]), gi(e["rl"]), gd(e["x"]), gd(e["y"]), gi(e["rm"]), gb(e["mv"]), gb(e["hid"]), gb(e["io"]), col(gi(e["ch"]))); }
    tH = now(); }

  void endG(int w, String m) { if (page != 3 || win != 0) return; win = w; toA({"t": "over", "p": {"w": w, "m": m}}); endL(w, m); }
  void endL(int w, String m) { if (page == 4) return; win = w; endMsg = m; page = 4; loop?.cancel(); loop = null; ui(); }
  void rmP(int id) { if (id == 0) return; if (page == 3 && id == guard) { pl.removeWhere((p) => p.id == id); eps.remove(id); endG(2, "Güvenlik ayrıldı"); return; }
    pl.removeWhere((p) => p.id == id); eps.remove(id); if (page == 2) lob(); else if (page == 3 && !pl.any((p) => p.role == 1 && p.alive)) endG(1, "Kalmadı"); }

  PN? getP(int id) { for (var p in pl) if (p.id == id) return p; return null; }
  int roomAt(Offset o) { if (map == null) return -1; if (map!.of.contains(o)) return -2; for (int i = 0; i < map!.rooms.length; i++) if (map!.rooms[i].r.contains(o)) return i; return -1; }
  Offset rndS() { if (map == null || map!.rooms.isEmpty) return const Offset(20, 20); var r = map!.rooms[rnd.nextInt(map!.rooms.length)].r;
    double mx = min(1.0, r.width * 0.25), my = min(1.0, r.height * 0.25);
    double x1 = r.left + mx, x2 = r.right - mx, y1 = r.top + my, y2 = r.bottom - my;
    if (x2 < x1) x1 = x2 = r.center.dx; if (y2 < y1) y1 = y2 = r.center.dy;
    return Offset(x1 + rnd.nextDouble() * (x2 - x1), y1 + rnd.nextDouble() * (y2 - y1)); }
  int freeC(List<int> u) { for (int i = 0; i < 100; i++) { int c = rnd.nextInt(chars.length); if (!u.contains(c)) return c; } for (int c = 0; c < chars.length; c++) if (!u.contains(c)) return c; return 0; }
  String cn(int id) => (id < 0 || id >= chars.length) ? "?" : chars[id].n;
  Color col(int id) => (id < 0 || id >= chars.length) ? Colors.white : chars[id].color;

  List<EV> views() { var v = <EV>[];
    if (isHost) { for (var p in pl) { if (!p.alive) continue; bool hid = false; if (p.role == 1 && p.charId >= 0 && p.charId < chars.length) { if (p.silent > gt) hid = true; var pa = chars[p.charId].pas; if (pa == "quiet" || pa == "ghost") hid = true; }
        v.add(EV(p.id, p.charId, p.role, p.x, p.y, p.room, p.mv, hid, p.inside, p.role == 0 ? Colors.cyan : col(p.charId))); } }
    else { v.addAll(rem.values); if (myRole == 1) v.add(EV(myId, myChar, 1, pos.dx, pos.dy, roomAt(pos), mv, false, myIn, col(myChar))); }
    return v; }

  String det() { if (map == null || camRoom < 0 || camRoom >= map!.rooms.length) return ""; if (jam > gt) return "PARAZİT";
    var n = <String>[]; for (var v in views()) if (v.role != 0 && !v.inside && v.room == camRoom && v.mv && !v.hid) n.add(cn(v.ch));
    String t = ""; if (nR == camRoom && nU > gt) t += "SES!\n"; t += n.isEmpty ? "Temiz." : "Hareket: ${n.join(', ')}"; return t; }
  String clock() { int h = ((gt / night).clamp(0.0, 1.0)
