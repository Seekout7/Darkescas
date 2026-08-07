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

class Ep { final InternetAddress a; final int p; Ep(this.a, this.p); }

class PN {
  final int id; String name; int charId, role, room, side;
  double x, y, seen, cd, boost, silent, light, vent, doorTimer;
  bool mv, inside, alive;
  PN(this.id, this.name, {this.charId = -1, this.role = -1, this.x = 0, this.y = 0, this.room = -1, this.side = 0, this.seen = 0, this.cd = 0, this.boost = 0, this.silent = 0, this.light = 0, this.vent = 0, this.doorTimer = 0, this.mv = false, this.inside = false, this.alive = true});
}

class EV { final int id, ch, role, room; final double x, y; final bool mv, hid, inside; final Color color; EV(this.id, this.ch, this.role, this.x, this.y, this.room, this.mv, this.hid, this.inside, this.color); }
class Room { final String n; final Rect r; Room(this.n, this.r); }
class MD { final Rect of; final Offset ld, rd, vt, il, ir, iv; final List<Room> rooms; final List<Offset> vents; MD(this.of, this.ld, this.rd, this.vt, this.il, this.ir, this.iv, this.rooms, this.vents); }
class CD { final String n, act, pas; final Color color; final double sp, cd; CD(this.n, int c, this.sp, this.cd, this.act, this.pas) : color = Color(c); }
class DH { final String a; final int p; String s; int c; double last; DH(this.a, this.p, this.s, this.c, this.last); }

String gs(dynamic v) => v is String ? v.trim() : (v == null ? '' : '$v'.trim());
int gi(dynamic v) => v is int ? v : (v is num ? v.toInt() : (v is String ? int.tryParse(v) ?? 0 : 0));
double gd(dynamic v) => v is double ? v : (v is num ? v.toDouble() : (v is String ? double.tryParse(v) ?? 0.0 : 0.0));
bool gb(dynamic v) => v == true;
String sanitizeName(String raw) { final c = raw.replaceAll(RegExp(r'[\u0000-\u001F\u007F]'), '').trim(); return c.isEmpty ? 'Oyuncu' : (c.length <= 16 ? c : c.substring(0, 16)); }
int cr(Color c) => (c.r * 255).round().clamp(0, 255);
int cg(Color c) => (c.g * 255).round().clamp(0, 255);
int cb(Color c) => (c.b * 255).round().clamp(0, 255);
int kindOf(int id) => id < 0 ? 0 : id % 4;

String actDesc(String a) { switch (a) { case 'speed': return '4 sn hiz'; case 'silent': return '5 sn gorunmez'; case 'ventrush': return 'Vente aninda'; case 'doorbreak': return 'Kapiyi kirar'; case 'camjam': return 'Kamera bozar'; case 'lightimmune': return 'Isik bagisik'; case 'noise': return 'Sahte ses'; case 'fear': return '3 sn dondurur'; case 'scream': return '5 sn kilitler'; case 'dash': return 'Merkeze atilma'; case 'teleport': return 'Isinlanir'; case 'sabotage': return '6 guc emer'; case 'drain': return '10 guc emer'; default: return ''; } }
String pasDesc(String p) { switch (p) { case 'speed': return '+%15 hiz'; case 'ghost': return 'ASLA gorunmez'; case 'vent': return '2 dokunusla'; case 'door': return '1.5x hasar'; case 'quiet': return 'Hareket yazmaz'; case 'light': return '%50 kacma'; case 'focus': return '-%25 bekleme'; default: return 'Pasif yok'; } }

List<CD> mkChars() {
  return [
    CD('Kanat', 0xFFEF5350, 3.6, 10, 'speed', 'speed'),
    CD('Golge', 0xFF9575CD, 3.2, 14, 'silent', 'ghost'),
    CD('Fare', 0xFF4DB6AC, 3.4, 12, 'ventrush', 'vent'),
    CD('Kas', 0xFFE57373, 2.9, 16, 'doorbreak', 'door'),
    CD('Hacker', 0xFF64B5F6, 3.1, 15, 'camjam', 'quiet'),
    CD('Isik', 0xFFFFD54F, 3.2, 13, 'lightimmune', 'light'),
    CD('Gurultucu', 0xFFA1887F, 3.3, 11, 'noise', 'none'),
    CD('Korku', 0xFF7986CB, 3.0, 17, 'fear', 'none'),
    CD('Dalga', 0xFF81C784, 3.5, 9, 'dash', 'speed'),
    CD('Enerji', 0xFFF06292, 3.0, 14, 'drain', 'none'),
    CD('Pas', 0xFF8D6E63, 2.8, 15, 'doorbreak', 'vent'),
    CD('Sis', 0xFF90A4AE, 3.3, 13, 'teleport', 'quiet'),
    CD('Kukla', 0xFFB39DDB, 3.1, 18, 'scream', 'ghost'),
    CD('Anten', 0xFF4FC3F7, 3.0, 12, 'sabotage', 'focus'),
    CD('Kibrit', 0xFFFF8A65, 3.4, 12, 'lightimmune', 'speed'),
    CD('Buz', 0xFF80DEEA, 2.8, 16, 'fear', 'door'),
    CD('Yilan', 0xFFAED581, 3.5, 12, 'ventrush', 'quiet'),
    CD('Radyo', 0xFFFFF176, 3.2, 10, 'noise', 'focus'),
    CD('Makas', 0xFFF48FB1, 3.3, 11, 'dash', 'light'),
    CD('Son', 0xFFE0E0E0, 3.0, 20, 'teleport', 'ghost'),
  ];
}

MD mkMap(int i) {
  if (i == 1) {
    final Rect of = Rect.fromLTWH(-25, -20, 50, 40);
    return MD(of, const Offset(-27, 0), const Offset(27, 0), const Offset(0, -22), const Offset(-18, 0), const Offset(18, 0), const Offset(0, -12), [
      Room('Sol Koridor', const Rect.fromLTWH(-46, -18, 20, 36)),
      Room('Sag Koridor', const Rect.fromLTWH(26, -18, 20, 36)),
      Room('Ust Koridor', const Rect.fromLTWH(-28, -40, 56, 23)),
      Room('Alt Koridor', const Rect.fromLTWH(-28, 17, 56, 19)),
      Room('Sol Depo', const Rect.fromLTWH(-70, -36, 26, 26)),
      Room('Sag Depo', const Rect.fromLTWH(44, -36, 26, 26)),
      Room('Ust Sol Gecis', const Rect.fromLTWH(-46, -40, 20, 23)),
      Room('Ust Sag Gecis', const Rect.fromLTWH(26, -40, 20, 23)),
      Room('Alt Sol Gecis', const Rect.fromLTWH(-46, 17, 20, 19)),
      Room('Alt Sag Gecis', const Rect.fromLTWH(26, 17, 20, 19)),
    ], [const Offset(-15, -22), const Offset(15, -22)]);
  }
  if (i == 2) {
    final Rect of = Rect.fromLTWH(-22, -18, 44, 36);
    return MD(of, const Offset(-24, 0), const Offset(24, 0), const Offset(0, -20), const Offset(-16, 0), const Offset(16, 0), const Offset(0, -11), [
      Room('Sol Kanat', const Rect.fromLTWH(-40, -9, 18, 18)),
      Room('Sag Kanat', const Rect.fromLTWH(22, -9, 18, 18)),
      Room('Sahne Arkasi', const Rect.fromLTWH(-11, -33, 22, 14)),
      Room('Kostum Odasi', const Rect.fromLTWH(-62, -34, 24, 30)),
      Room('Isik Kabini', const Rect.fromLTWH(38, -34, 24, 30)),
      Room('Orkestra Cukuru', const Rect.fromLTWH(-18, 18, 36, 16)),
      Room('Vestiyer', const Rect.fromLTWH(-46, 12, 24, 20)),
      Room('Sol Koridor', const Rect.fromLTWH(-40, -33, 20, 25)),
      Room('Sag Koridor', const Rect.fromLTWH(20, -33, 20, 25)),
      Room('Ust Koridor', const Rect.fromLTWH(-11, -50, 22, 18)),
    ], [const Offset(-10, -20), const Offset(10, -20)]);
  }
  if (i == 3) {
    final Rect of = Rect.fromLTWH(-18, -14, 36, 28);
    return MD(of, const Offset(-20, 0), const Offset(20, 0), const Offset(0, -16), const Offset(-13, 0), const Offset(13, 0), const Offset(0, -9), [
      Room('Sol Tunel', const Rect.fromLTWH(-36, -7, 17, 14)),
      Room('Sag Tunel', const Rect.fromLTWH(19, -7, 17, 14)),
      Room('Kazan Dairesi', const Rect.fromLTWH(-9, -30, 18, 15)),
      Room('Hurda Odasi', const Rect.fromLTWH(-54, -26, 20, 22)),
      Room('Jenerator', const Rect.fromLTWH(34, -26, 20, 22)),
      Room('Asansor Bosu', const Rect.fromLTWH(-12, 14, 24, 14)),
      Room('Ust Gecis', const Rect.fromLTWH(-9, -45, 18, 16)),
      Room('Alt Gecis', const Rect.fromLTWH(-12, 28, 24, 14)),
    ], [const Offset(-8, -16), const Offset(8, -16)]);
  }
  final Rect of = Rect.fromLTWH(-20, -15, 40, 30);
  return MD(of, const Offset(-22, 0), const Offset(22, 0), const Offset(0, -17), const Offset(-15, 0), const Offset(15, 0), const Offset(0, -10), [
    Room('Sol Koridor', const Rect.fromLTWH(-38, -16, 19, 32)),
    Room('Sag Koridor', const Rect.fromLTWH(19, -16, 19, 32)),
    Room('Ust Koridor', const Rect.fromLTWH(-24, -32, 48, 18)),
    Room('Alt Koridor', const Rect.fromLTWH(-24, 13, 48, 18)),
    Room('Sol Depo', const Rect.fromLTWH(-58, -30, 22, 24)),
    Room('Sag Depo', const Rect.fromLTWH(36, -30, 22, 24)),
    Room('Ust Sol Gecis', const Rect.fromLTWH(-38, -32, 19, 18)),
    Room('Ust Sag Gecis', const Rect.fromLTWH(19, -32, 19, 18)),
    Room('Alt Sol Gecis', const Rect.fromLTWH(-38, 13, 19, 18)),
    Room('Alt Sag Gecis', const Rect.fromLTWH(19, 13, 19, 18)),
  ], [const Offset(-12, -17), const Offset(12, -17)]);
}

// YUKSEK GRAFIK: CRT Noise + Scanlines + Vignette + Chromatic Aberration
class NoisePainter extends CustomPainter {
  final int seed; final double strength;
  NoisePainter(this.seed, this.strength);
  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0 || strength <= 0.001) return;
    final rnd = Random(seed); final p = Paint();
    final int count = (90 * strength).round();
    for (int i = 0; i < count; i++) {
      final x = rnd.nextDouble() * size.width; final y = rnd.nextDouble() * size.height;
      final w = 1.5 + rnd.nextDouble() * 8; final g = 80 + rnd.nextInt(180);
      p.color = Color.fromRGBO(g, g, g, (0.05 + rnd.nextDouble() * 0.15) * strength);
      canvas.drawRect(Rect.fromLTWH(x, y, w, 1 + rnd.nextDouble() * 2), p);
    }
    // Scanlines
    p.color = Color.fromRGBO(0, 0, 0, 0.18 * strength);
    for (double y = 0; y < size.height; y += 2.5) canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), p);
    // Chromatic flicker bands
    if (rnd.nextDouble() < 0.15 * strength) {
      final by = rnd.nextDouble() * size.height;
      p.color = Color.fromRGBO(255, 0, 0, 0.08 * strength);
      canvas.drawRect(Rect.fromLTWH(0, by, size.width, 3 + rnd.nextDouble() * 6), p);
      p.color = Color.fromRGBO(0, 255, 255, 0.06 * strength);
      canvas.drawRect(Rect.fromLTWH(2, by + 4, size.width, 2), p);
    }
  }
  @override
  bool shouldRepaint(covariant NoisePainter o) => o.seed != seed || o.strength != strength;
}

class VignettePainter extends CustomPainter {
  final double intensity;
  VignettePainter(this.intensity);
  @override
  void paint(Canvas canvas, Size size) {
    if (intensity <= 0) return;
    final p = Paint()..shader = RadialGradient(colors: [const Color(0x00000000), Color.fromRGBO(0, 0, 0, 0.55 * intensity), Color.fromRGBO(0, 0, 0, 0.95 * intensity)], stops: const [0.45, 0.75, 1.0]).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), p);
  }
  @override
  bool shouldRepaint(covariant VignettePainter o) => o.intensity != intensity;
}

class CRTWarpPainter extends CustomPainter {
  final double time;
  CRTWarpPainter(this.time);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..blendMode = BlendMode.plus;
    final rnd = Random((time * 100).toInt());
    p.color = Color.fromRGBO(0, 255, 180, 0.03);
    for (int i = 0; i < 3; i++) {
      final y = rnd.nextDouble() * size.height;
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 0.8), p);
    }
    // Flicker
    if (rnd.nextDouble() < 0.08) {
      p.color = Color.fromRGBO(255, 255, 255, 0.04 + rnd.nextDouble() * 0.05);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), p);
    }
  }
  @override
  bool shouldRepaint(covariant CRTWarpPainter o) => o.time != time;
}

class CheckerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const double tile = 24; final p = Paint();
    for (double y = 0; y < size.height; y += tile) {
      for (double x = 0; x < size.width; x += tile) {
        final odd = ((x / tile).round() + (y / tile).round()) % 2 == 0;
        p.color = odd ? const Color(0xFF151515) : const Color(0xFF0A0A0A);
        canvas.drawRect(Rect.fromLTWH(x, y, tile, tile), p);
        if (!odd) { p.color = const Color(0x22000000); canvas.drawRect(Rect.fromLTWH(x, y + tile - 2, tile, 2), p); }
      }
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

class HazardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..shader = const LinearGradient(colors: [Color(0xFF1A1A1A), Color(0xFF0A0A0A)], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), p);
    p.color = const Color(0xFFD8A400); const double s = 8;
    for (double x = -size.height; x < size.width; x += s * 2) {
      canvas.drawPath(Path()..moveTo(x, size.height)..lineTo(x + s, 0)..lineTo(x + s * 2, 0)..lineTo(x + s, size.height)..close(), p);
    }
    // Edge glow
    p.color = const Color(0x44FFAA00)..maskFilter = const MaskFilter.blur(BlurStyle.outer, 3);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), p);
    p.maskFilter = null;
  }
  @override
  bool shouldRepaint(covariant CustomPainter o) => false;
}

// YUKSEK GRAFIK Karakter Boyasi - detayli golge, glow, ambient
class AnimPainter extends CustomPainter {
  final Color color; final bool glow; final int kind;
  AnimPainter(this.color, this.glow, this.kind);
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width, h = size.height; if (w <= 4 || h <= 4) return;
    final int r = cr(color), g = cg(color), b = cb(color);
    final Color dark = Color.fromARGB(255, (r * 0.35).round().clamp(0,255), (g * 0.35).round().clamp(0,255), (b * 0.35).round().clamp(0,255));
    final Color light = Color.fromARGB(255, min(255, r + 70), min(255, g + 70), min(255, b + 70));
    final Color rim = Color.fromARGB(255, min(255, r + 120), min(255, g + 120), min(255, b + 120));
    Paint grad(Rect rect) => Paint()..shader = LinearGradient(colors: [light, color, dark], begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(rect);
    final Paint flat = Paint();
    final Paint soft = Paint()..maskFilter = MaskFilter.blur(BlurStyle.normal, 4);
    final Paint glowSoft = Paint()..maskFilter = MaskFilter.blur(BlurStyle.normal, 10);

    // Floor shadow (soft)
    soft.color = const Color(0xAA000000);
    canvas.drawOval(Rect.fromLTWH(w * 0.14, h * 0.93, w * 0.72, h * 0.07), soft);
    // Ambient glow under character
    if (glow) {
      glowSoft.color = Color.fromRGBO(r, g, b, 0.35);
      canvas.drawOval(Rect.fromLTWH(w * 0.20, h * 0.88, w * 0.60, h * 0.12), glowSoft);
    }

    flat.color = color;
    // Ears / antenna / hat based on kind
    if (kind == 1) { // Rabbit-ish
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.18, -h * 0.02, w * 0.13, h * 0.20), const Radius.circular(8)), grad(Rect.fromLTWH(w * 0.18, -h * 0.02, w * 0.13, h * 0.20)));
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.69, -h * 0.02, w * 0.13, h * 0.20), const Radius.circular(8)), grad(Rect.fromLTWH(w * 0.69, -h * 0.02, w * 0.13, h * 0.20)));
      flat.color = Color.fromRGBO(255, 180, 200, 0.6);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.22, 0, w * 0.05, h * 0.14), const Radius.circular(3)), flat);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.73, 0, w * 0.05, h * 0.14), const Radius.circular(3)), flat);
    } else if (kind == 2) { // Fox
      canvas.drawPath(Path()..moveTo(w * 0.18, h * 0.18)..lineTo(w * 0.04, -h * 0.01)..lineTo(w * 0.34, h * 0.11)..close(), flat);
      canvas.drawPath(Path()..moveTo(w * 0.82, h * 0.18)..lineTo(w * 0.96, -h * 0.01)..lineTo(w * 0.66, h * 0.11)..close(), flat);
      flat.color = dark;
      canvas.drawPath(Path()..moveTo(w * 0.18, h * 0.18)..lineTo(w * 0.10, h * 0.05)..lineTo(w * 0.24, h * 0.12)..close(), flat);
      canvas.drawPath(Path()..moveTo(w * 0.82, h * 0.18)..lineTo(w * 0.90, h * 0.05)..lineTo(w * 0.76, h * 0.12)..close(), flat);
    } else if (kind == 3) { // Freddy top hat
      flat.color = dark;
      canvas.drawRect(Rect.fromLTWH(w * 0.47, -h * 0.01, w * 0.06, h * 0.13), flat);
      canvas.drawRect(Rect.fromLTWH(w * 0.38, h * 0.08, w * 0.24, h * 0.035), flat);
      if (glow) { glowSoft.color = const Color(0x88FF4444); canvas.drawCircle(Offset(w * 0.5, 0), w * 0.04, glowSoft); }
    } else { // Chica bib
      canvas.drawCircle(Offset(w * 0.20, h * 0.11), w * 0.095, flat);
      canvas.drawCircle(Offset(w * 0.80, h * 0.11), w * 0.095, flat);
      flat.color = dark;
      canvas.drawCircle(Offset(w * 0.20, h * 0.11), w * 0.05, flat);
      canvas.drawCircle(Offset(w * 0.80, h * 0.11), w * 0.05, flat);
    }

    // HEAD
    final Rect headR = Rect.fromLTWH(w * 0.14, h * 0.07, w * 0.72, h * 0.28);
    canvas.drawRRect(RRect.fromRectAndRadius(headR, const Radius.circular(8)), grad(headR));
    // Rim light (top edge highlight)
    flat.color = rim.withOpacity(0.5);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.18, h * 0.075, w * 0.64, h * 0.03), const Radius.circular(2)), flat);

    // Cheeks
    flat.color = Color.fromRGBO(255, 140, 160, 0.25);
    canvas.drawCircle(Offset(w * 0.24, h * 0.26), w * 0.05, flat);
    canvas.drawCircle(Offset(w * 0.76, h * 0.26), w * 0.05, flat);

    // Eye sockets (deep shadow)
    flat.color = const Color(0xFF000000);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.22, h * 0.12, w * 0.22, h * 0.13), const Radius.circular(4)), flat);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.56, h * 0.12, w * 0.22, h * 0.13), const Radius.circular(4)), flat);

    // Eye glow (scary)
    glowSoft.color = glow ? Color.fromRGBO(255, 40, 40, 0.8) : const Color.fromRGBO(200, 255, 170, 0.55);
    canvas.drawCircle(Offset(w * 0.33, h * 0.185), w * 0.075, glowSoft);
    canvas.drawCircle(Offset(w * 0.67, h * 0.185), w * 0.075, glowSoft);
    // Eye core
    flat.color = glow ? const Color(0xFFFF2222) : const Color(0xFFE8E8C8);
    canvas.drawCircle(Offset(w * 0.33, h * 0.185), w * 0.038, flat);
    canvas.drawCircle(Offset(w * 0.67, h * 0.185), w * 0.038, flat);
    // Eye highlight
    flat.color = const Color(0xFFFFFFFF);
    canvas.drawCircle(Offset(w * 0.345, h * 0.17), w * 0.013, flat);
    canvas.drawCircle(Offset(w * 0.685, h * 0.17), w * 0.013, flat);

    // Mouth plate
    flat.color = dark;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.28, h * 0.255, w * 0.44, h * 0.115), const Radius.circular(4)), flat);
    // Nose
    flat.color = const Color(0xFF0A0A0A);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.46, h * 0.26, w * 0.08, h * 0.04), const Radius.circular(3)), flat);
    // Teeth row
    canvas.drawRect(Rect.fromLTWH(w * 0.31, h * 0.305, w * 0.38, h * 0.06), flat);
    flat.color = const Color(0xFFE8E8DC);
    for (int i = 0; i < 6; i++) {
      final double x = w * 0.32 + i * w * 0.06;
      canvas.drawPath(Path()..moveTo(x, h * 0.305)..lineTo(x + w * 0.025, h * 0.34)..lineTo(x + w * 0.05, h * 0.305)..close(), flat);
      canvas.drawPath(Path()..moveTo(x, h * 0.365)..lineTo(x + w * 0.025, h * 0.33)..lineTo(x + w * 0.05, h * 0.365)..close(), flat);
    }

    // BODY (trapezoid)
    canvas.drawPath(Path()..moveTo(w * 0.22, h * 0.36)..lineTo(w * 0.78, h * 0.36)..lineTo(w * 0.70, h * 0.74)..lineTo(w * 0.30, h * 0.74)..close(), grad(Rect.fromLTWH(0, h * 0.36, w, h * 0.38)));
    // Chest detail
    flat.color = light;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.40, h * 0.44, w * 0.20, h * 0.18), const Radius.circular(5)), flat);
    flat.color = dark;
    canvas.drawCircle(Offset(w * 0.50, h * 0.50), w * 0.025, flat);
    canvas.drawCircle(Offset(w * 0.50, h * 0.56), w * 0.025, flat);

    // Rivets
    flat.color = const Color(0xFF222222);
    canvas.drawCircle(Offset(w * 0.28, h * 0.40), w * 0.018, flat);
    canvas.drawCircle(Offset(w * 0.72, h * 0.40), w * 0.018, flat);
    canvas.drawCircle(Offset(w * 0.32, h * 0.70), w * 0.018, flat);
    canvas.drawCircle(Offset(w * 0.68, h * 0.70), w * 0.018, flat);
    flat.color = rim.withOpacity(0.4);
    canvas.drawCircle(Offset(w * 0.285, h * 0.395), w * 0.008, flat);
    canvas.drawCircle(Offset(w * 0.725, h * 0.395), w * 0.008, flat);

    // Arms
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.05, h * 0.38, w * 0.15, h * 0.30), const Radius.circular(6)), grad(Rect.fromLTWH(w * 0.05, h * 0.38, w * 0.15, h * 0.30)));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.80, h * 0.38, w * 0.15, h * 0.30), const Radius.circular(6)), grad(Rect.fromLTWH(w * 0.80, h * 0.38, w * 0.15, h * 0.30)));
    // Claws/fingers
    flat.color = const Color(0xFFCCCCCC);
    for (int i = 0; i < 3; i++) {
      canvas.drawPath(Path()..moveTo(w * 0.065 + i * w * 0.045, h * 0.67)..lineTo(w * 0.08 + i * w * 0.045, h * 0.73)..lineTo(w * 0.10 + i * w * 0.045, h * 0.67)..close(), flat);
      canvas.drawPath(Path()..moveTo(w * 0.815 + i * w * 0.045, h * 0.67)..lineTo(w * 0.83 + i * w * 0.045, h * 0.73)..lineTo(w * 0.845 + i * w * 0.045, h * 0.67)..close(), flat);
    }

    // Legs
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.31, h * 0.73, w * 0.16, h * 0.22), const Radius.circular(5)), grad(Rect.fromLTWH(w * 0.31, h * 0.73, w * 0.16, h * 0.22)));
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.53, h * 0.73, w * 0.16, h * 0.22), const Radius.circular(5)), grad(Rect.fromLTWH(w * 0.53, h * 0.73, w * 0.16, h * 0.22)));
    // Feet
    flat.color = dark;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.28, h * 0.93, w * 0.22, h * 0.055), const Radius.circular(3)), flat);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.50, h * 0.93, w * 0.22, h * 0.055), const Radius.circular(3)), flat);
  }
  @override
  bool shouldRepaint(covariant AnimPainter o) => o.color != color || o.glow != glow || o.kind != kind;
}

// Office environment painter - detailed desk/monitor/posters
class OfficePainter extends CustomPainter {
  final double time; final bool black;
  OfficePainter(this.time, this.black);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final p = Paint();
    // Back wall gradient
    p.shader = const LinearGradient(colors: [Color(0xFF1A1410), Color(0xFF0A0806)], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(Rect.fromLTWH(0, 0, w, h * 0.7));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h * 0.7), p);
    // Wall texture stripes
    p.color = const Color(0x18FFFFFF);
    for (double x = 0; x < w; x += 6) canvas.drawRect(Rect.fromLTWH(x, 0, 1, h * 0.7), p);
    // Floor
    p.shader = const LinearGradient(colors: [Color(0xFF0A0806), Color(0xFF000000)], begin: Alignment.topCenter, end: Alignment.bottomCenter).createShader(Rect.fromLTWH(0, h * 0.7, w, h * 0.3));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.7, w, h * 0.3), p);

    if (black) {
      p.color = const Color(0xEE000000);
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), p);
      return;
    }

    // Desk
    p.shader = LinearGradient(colors: [const Color(0xFF5A3A22), const Color(0xFF2A1A10)], begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(Rect.fromLTWH(w * 0.15, h * 0.58, w * 0.70, h * 0.18));
    canvas.drawRect(Rect.fromLTWH(w * 0.15, h * 0.58, w * 0.70, h * 0.18), p);
    // Desk edge shadow
    p.color = const Color(0x88000000);
    canvas.drawRect(Rect.fromLTWH(w * 0.15, h * 0.76, w * 0.70, h * 0.012), p);
    // Desk top highlight
    p.color = const Color(0x44FFFFFF);
    canvas.drawRect(Rect.fromLTWH(w * 0.15, h * 0.58, w * 0.70, h * 0.005), p);

    // Monitor (CRT)
    p.color = const Color(0xFF0A0A0A);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.35, h * 0.38, w * 0.30, h * 0.22), const Radius.circular(6)), p);
    // Screen glow
    p.color = const Color(0x6600AA44);
    p.maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.37, h * 0.40, w * 0.26, h * 0.18), const Radius.circular(3)), p);
    p.maskFilter = null;
    // Screen content (scan lines)
    p.color = const Color(0xFF003322);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.37, h * 0.40, w * 0.26, h * 0.18), const Radius.circular(3)), p);
    p.color = const Color(0x8800FF88);
    for (double y = h * 0.405; y < h * 0.575; y += 3) canvas.drawRect(Rect.fromLTWH(w * 0.372, y, w * 0.256, 1), p);
    // Monitor base
    p.color = const Color(0xFF1A1A1A);
    canvas.drawRect(Rect.fromLTWH(w * 0.48, h * 0.60, w * 0.04, h * 0.02), p);

    // Posters on wall
    p.color = const Color(0xFF6A4A2A);
    canvas.drawRect(Rect.fromLTWH(w * 0.08, h * 0.18, w * 0.08, h * 0.14), p);
    canvas.drawRect(Rect.fromLTWH(w * 0.84, h * 0.20, w * 0.08, h * 0.12), p);
    // Poster highlights
    p.color = const Color(0x66E8B84A);
    canvas.drawRect(Rect.fromLTWH(w * 0.09, h * 0.20, w * 0.06, h * 0.015), p);
    canvas.drawRect(Rect.fromLTWH(w * 0.09, h * 0.24, w * 0.06, h * 0.005), p);

    // Fan (rotating)
    final double ang = time * 8;
    canvas.save();
    canvas.translate(w * 0.78, h * 0.12);
    canvas.rotate(ang);
    p.color = const Color(0x88888888);
    for (int i = 0; i < 3; i++) {
      canvas.save();
      canvas.rotate(i * 2.094);
      canvas.drawRect(Rect.fromLTWH(-2, -18, 4, 18), p);
      canvas.restore();
    }
    p.color = const Color(0xFF333333);
    canvas.drawCircle(Offset.zero, 4, p);
    canvas.restore();

    // Lamp light cone
    p.color = const Color(0x44FFDD88);
    p.maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawPath(Path()..moveTo(w * 0.20, h * 0.58)..lineTo(w * 0.14, h * 0.75)..lineTo(w * 0.30, h * 0.75)..close(), p);
    p.maskFilter = null;
    // Lamp
    p.color = const Color(0xFF443322);
    canvas.drawRect(Rect.fromLTWH(w * 0.18, h * 0.50, w * 0.03, h * 0.08), p);
    p.color = const Color(0xFFEEDDAA);
    p.maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawOval(Rect.fromLTWH(w * 0.16, h * 0.48, w * 0.08, h * 0.04), p);
    p.maskFilter = null;

    // Papers scattered
    p.color = const Color(0xFFE8E0C8);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.22, h * 0.60, w * 0.06, h * 0.08), const Radius.circular(1)), p);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.70, h * 0.61, w * 0.08, h * 0.06), const Radius.circular(1)), p);
    p.color = const Color(0x88000000);
    for (int i = 0; i < 3; i++) {
      canvas.drawRect(Rect.fromLTWH(w * 0.23, h * 0.62 + i * h * 0.015, w * 0.04, 0.5), p);
    }
  }
  @override
  bool shouldRepaint(covariant OfficePainter o) => o.time != time || o.black != black;
}

class GS extends StatefulWidget {
  const GS({super.key});
  @override
  State<GS> createState() => _S();
}

class _S extends State<GS> {
  static const int port = 47777; static const double night = 240.0; static const int maxP = 4; static const int maxPacket = 8192;
  final rnd = Random(); final ipc = TextEditingController(); final nameC = TextEditingController();
  Timer? loop, slow; StreamSubscription<RawSocketEvent>? _sub; final fr = ValueNotifier<int>(0);
  int page = 0; int myId = -1; int guard = -1; int myRole = -1; int myChar = -1; int curMap = 0; int camRoom = 0; int infoChar = 0;
  bool isHost = false; String myName = ''; String status = ''; String endMsg = '';
  RawDatagramSocket? sock; InternetAddress? hA; int hP = port;
  final Map<int, Ep> eps = {}; final List<PN> pl = []; final List<DH> disc = []; final Map<int, EV> rem = {};
  late List<CD> chars; MD? map;
  double tD = 0, tP = 0, tH = 0, tL = 0, tS = 0, tN = 0; double gt = 0, en = 100;
  bool ldC = true, rdC = true, fl = false, cam = false, black = false, ventC = false; int win = 0, nR = -1;
  double fL = 0, fR = 0, dL = 0, dR = 0, jam = 0, lock = 0, nU = 0;
  Offset pos = Offset.zero; bool mv = false, myIn = false, myB = false; double myCd = 0;
  double jx = 0, jy = 0, shake = 0, jump = 0;

  @override
  void initState() { super.initState(); myName = 'Oyuncu${rnd.nextInt(900) + 100}'; nameC.text = myName; chars = mkChars(); slow = Timer.periodic(const Duration(seconds: 1), slowT); }
  @override
  void dispose() { loop?.cancel(); slow?.cancel(); _sub?.cancel(); try { sock?.close(); } catch (_) {} ipc.dispose(); nameC.dispose(); fr.dispose(); super.dispose(); }
  void ui() { if (mounted) setState(() {}); }
  double now() => DateTime.now().millisecondsSinceEpoch / 1000.0;

  Future<bool> hSock() async { cN(); try { sock = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port); sock!.broadcastEnabled = true; _sub = sock!.listen(onS); return true; } catch (_) { status = 'Host hatasi'; return false; } }
  Future<bool> cSock() async { cN(); try { sock = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0); sock!.broadcastEnabled = true; _sub = sock!.listen(onS); return true; } catch (_) { status = 'Socket hatasi'; return false; } }
  void cN() { _sub?.cancel(); try { sock?.close(); } catch (_) {} sock = null; _sub = null; }
  void onS(RawSocketEvent e) { if (e != RawSocketEvent.read) return; final dg = sock?.receive(); if (dg == null) return; if (dg.data.length > maxPacket) return; try { final decoded = jsonDecode(utf8.decode(dg.data, allowMalformed: true)); if (decoded is! Map) return; final m = decoded.cast<String, dynamic>(); final p = m['p'] is Map ? (m['p'] as Map).cast<String, dynamic>() : <String, dynamic>{}; final t = gs(m['t']); if (isHost) hPk(t, p, dg); else cPk(t, p, dg); } catch (_) {} }
  void snd(Map d, InternetAddress a, int p) { try { sock?.send(utf8.encode(jsonEncode(d)), a, p); } catch (_) {} }
  void toH(Map d) { if (hA != null) snd(d, hA!, hP); }
  void toA(Map d) { if (!isHost) return; for (var e in eps.values) snd(d, e.a, e.p); }
  int epId(InternetAddress a, int p) { for (var e in eps.entries) if (e.value.a.address == a.address && e.value.p == p) return e.key; return -1; }

  void hPk(String t, Map p, Datagram dg) {
    if (t == 'discover') { if (page == 2) snd({'t': 'hostinfo', 'p': {'name': myName, 'count': pl.length, 'map': curMap}}, dg.address, dg.port); return; }
    if (t == 'hello') {
      final ex = epId(dg.address, dg.port);
      if (ex != -1) { if (page == 2) snd({'t': 'welcome', 'p': {'id': ex}}, dg.address, dg.port); else snd({'t': 'err', 'p': {'m': 'Lobi kapali'}}, dg.address, dg.port); return; }
      if (page != 2 || pl.length >= maxP) { snd({'t': 'err', 'p': {'m': 'Katilamazsin'}}, dg.address, dg.port); return; }
      int id = 1; while (pl.any((x) => x.id == id)) id++;
      String nm = gs(p['name']); if (nm.isEmpty) nm = 'Oyuncu$id';
      pl.add(PN(id, sanitizeName(nm), seen: now())); eps[id] = Ep(dg.address, dg.port);
      snd({'t': 'welcome', 'p': {'id': id}}, dg.address, dg.port); lob(); return;
    }
    final id = epId(dg.address, dg.port); if (id == -1) return;
    final me = getP(id); if (me != null) me.seen = now();
    if (t == 'ping') return;
    if (t == 'leave') { rmP(id); return; }
    if (t == 'char' && page == 2) { selH(id, gi(p['c'])); return; }
    if (t == 'state' && page == 3 && me != null) {
      final nx = gd(p['x']); final ny = gd(p['y']); final target = Offset(nx, ny); final old = Offset(me.x, me.y);
      if ((target - old).distance <= 6.0 && walkF(target, me)) { me.x = nx; me.y = ny; me.mv = gb(p['mv']); me.room = roomAt(target); }
      return;
    }
    if (t == 'act' && page == 3) act(id, gs(p['a']));
  }

  void cPk(String t, Map p, Datagram dg) {
    tH = now();
    if (t == 'hostinfo' && page == 1) {
      DH? f; for (var d in disc) if (d.a == dg.address.address && d.p == dg.port) f = d;
      if (f == null) disc.add(DH(dg.address.address, dg.port, gs(p['name']), gi(p['count']), now()));
      else { f.s = gs(p['name']); f.c = gi(p['count']); f.last = now(); }
      ui(); return;
    }
    if (t == 'welcome') { myId = gi(p['id']); page = 2; status = 'Lobidesin'; ui(); return; }
    if (t == 'lobby') {
      pl.clear(); curMap = gi(p['map']);
      if (p['players'] is List) for (final it in p['players'] as List) { if (it is! Map) continue; final q2 = it.cast<String, dynamic>(); pl.add(PN(gi(q2['id']), sanitizeName(gs(q2['name'])), charId: gi(q2['char']))); }
      if (page == 2) ui(); return;
    }
    if (t == 'start') { startFrom(p); return; }
    if (t == 'snap') { snap(p); return; }
    if (t == 'over') { endL(gi(p['w']), gs(p['m'])); return; }
    if (t == 'err') { status = gs(p['m']); page = 0; cN(); ui(); return; }
    if (t == 'closed') { cN(); page = 0; status = 'Host kapatti'; ui(); return; }
  }

  Future<void> hostGame() async { if (!await hSock()) { ui(); return; } if (!mounted) return; isHost = true; myName = sanitizeName(nameC.text); myId = 0; guard = -1; myRole = -1; myChar = -1; curMap = 0; pl.clear(); eps.clear(); rem.clear(); pl.add(PN(0, myName, seen: now())); page = 2; status = 'Host hazir'; lob(); ui(); }
  Future<void> openDisc() async { if (!await cSock()) { ui(); return; } if (!mounted) return; isHost = false; myId = -1; disc.clear(); page = 1; d0(); tD = now(); ui(); }
  void d0() { try { snd({'t': 'discover'}, InternetAddress('255.255.255.255'), port); snd({'t': 'discover'}, InternetAddress.loopbackIPv4, port); } catch (_) {} }
  Future<void> joinIp() async { final addr = InternetAddress.tryParse(ipc.text.trim()); if (addr == null) { status = 'Gecerli IP gir'; ui(); return; } if (!await cSock()) { ui(); return; } if (!mounted) return; isHost = false; myId = -1; hA = addr; hP = port; hello(); page = 0; status = 'Baglaniyor'; tH = now(); ui(); }
  Future<void> joinD(DH d) async { final addr = InternetAddress.tryParse(d.a); if (addr == null) { status = 'Gecersiz host'; ui(); return; } if (!await cSock()) { ui(); return; } if (!mounted) return; isHost = false; myId = -1; hA = addr; hP = d.p; hello(); page = 0; status = 'Baglaniyor'; tH = now(); ui(); }
  void hello() => toH({'t': 'hello', 'p': {'name': myName}});
  void menu() { if (isHost) toA({'t': 'closed'}); else toH({'t': 'leave'}); loop?.cancel(); loop = null; cN(); isHost = false; page = 0; myId = -1; guard = -1; myRole = -1; myChar = -1; win = 0; hA = null; jx = 0; jy = 0; camRoom = 0; pl.clear(); eps.clear(); rem.clear(); disc.clear(); status = 'Ana menu'; ui(); }
  void selC(int c) { if (page != 2) return; if (isHost) selH(myId, c); else toH({'t': 'char', 'p': {'c': c}}); }
  void selH(int id, int c) { if (page != 2 || c < 0 || (c >= chars.length && c != 99)) return; final me = getP(id); if (me == null) return; if (c != 99) for (var o in pl) if (o.id != id && o.charId == c) { status = 'Secili'; lob(); return; } me.charId = c; lob(); }
  void setM(int m) { if (!isHost || page != 2) return; curMap = m < 0 ? 0 : (m > 3 ? 3 : m); lob(); }
  void lob() { if (!isHost) return; toA({'t': 'lobby', 'p': {'map': curMap, 'players': pl.map((p) => {'id': p.id, 'name': p.name, 'char': p.charId}).toList()}}); tL = now(); ui(); }

  void startHost() {
    if (!isHost || page != 2 || pl.length < 2) { status = 'En az 2 oyuncu'; ui(); return; }
    map = mkMap(curMap); reset();
    final ids = pl.map((e) => e.id).toList(); final vols = pl.where((p) => p.charId == 99).map((p) => p.id).toList(); final pool = vols.isEmpty ? ids : vols; guard = pool[rnd.nextInt(pool.length)];
    final used = <int>[];
    for (var p in pl) {
      if (p.id == guard) { p.role = 0; p.charId = -1; p.x = map!.of.center.dx; p.y = map!.of.center.dy; p.inside = true; p.room = -2; }
      else { p.role = 1; if (p.charId < 0 || p.charId >= chars.length || used.contains(p.charId)) p.charId = freeC(used); used.add(p.charId); final s = rndS(); p.x = s.dx; p.y = s.dy; p.inside = false; p.room = roomAt(s); }
      p.alive = true; p.mv = false; p.cd = 0; p.boost = 0; p.silent = 0; p.light = 0; p.vent = 0; p.doorTimer = 0;
      if (p.id == myId) { myRole = p.role; myChar = p.charId; pos = Offset(p.x, p.y); myIn = p.inside; }
    }
    toA({'t': 'start', 'p': {'map': curMap, 'guard': guard, 'players': pl.map((p) => {'id': p.id, 'char': p.charId, 'role': p.role, 'x': p.x, 'y': p.y}).toList()}});
    page = 3; startLoop(); ui();
  }

  void startFrom(Map p) {
    myRole = -1; myChar = -1; reset(); curMap = gi(p['map']); guard = gi(p['guard']); map = mkMap(curMap); pl.clear(); rem.clear();
    if (p['players'] is List) for (final it in p['players'] as List) { if (it is! Map) continue; final q2 = it.cast<String, dynamic>(); final id = gi(q2['id']); final ch = gi(q2['char']); final rl = gi(q2['role']); final x = gd(q2['x']); final y = gd(q2['y']); if (id == myId) { myRole = rl; myChar = ch; pos = Offset(x, y); myIn = rl == 0; } else rem[id] = EV(id, ch, rl, x, y, rl == 0 ? -2 : roomAt(Offset(x, y)), false, false, rl == 0, col(ch)); }
    if (myRole == -1) { status = 'Hatali baslangic'; page = 0; cN(); ui(); return; }
    page = 3; startLoop(); ui();
  }

  void reset() { gt = 0; en = 100; ldC = true; rdC = true; fl = false; cam = false; ventC = false; black = false; win = 0; endMsg = ''; fL = 0; fR = 0; dL = 0; dR = 0; jam = 0; lock = 0; nR = -1; nU = 0; mv = false; myIn = myRole == 0; myCd = 0; myB = false; camRoom = 0; shake = 0; jump = 0; jx = 0; jy = 0; }
  void startLoop() { loop?.cancel(); loop = Timer.periodic(const Duration(milliseconds: 16), tick); }
  void tick(Timer t) { if (page != 3) return; const double dt = 1 / 60; if (win == 0) { if (myRole == 0 || myRole == 1) moveL(dt); if (isHost) hostU(dt); else if ((myRole == 0 || myRole == 1) && now() - tS > 0.1) sendS(); } shake = max(0.0, shake - dt * 3); jump = max(0.0, jump - dt); fr.value++; }
  void slowT(Timer t) { if (!mounted) return; final n = now(); if (page == 1) { if (n - tD > 2) { tD = n; d0(); } final before = disc.length; disc.removeWhere((d) => n - d.last > 6); if (before != disc.length) ui(); } if (!isHost && page == 0 && hA != null && n - tH > 10) { hA = null; cN(); status = 'Baglanti zaman asimi'; ui(); return; } if (!isHost && (page == 2 || page == 3)) { if (n - tH > 10) { menu(); return; } if (n - tP > 2) { tP = n; toH({'t': 'ping'}); } } if (isHost && page == 2 && n - tL > 2) lob(); if (isHost && (page == 2 || page == 3)) for (int i = pl.length - 1; i >= 0; i--) if (pl[i].id != 0 && n - pl[i].seen > 10) rmP(pl[i].id); }

  void hostU(double dt) {
    if (win != 0 || map == null) return;
    gt += dt; double dr = 0.08; if (ldC) dr += 0.4; if (rdC) dr += 0.4; if (fl) dr += 0.35; if (cam) dr += 0.5; if (ventC) dr += 0.2; en -= dr * dt;
    if (en <= 0 && !black) { en = 0; black = true; ldC = false; rdC = false; fl = false; cam = false; ventC = false; }
    if (black) en = 0;
    if (gt >= night) { endG(1, 'Guvenlik dayandi'); return; }
    for (var p in pl) {
      if (p.role == 1 && !p.inside && p.alive) {
        final distL = (Offset(p.x, p.y) - map!.ld).distance;
        final distR = (Offset(p.x, p.y) - map!.rd).distance;
        if (distL < 3.5 && !ldC) { p.doorTimer += dt; if (p.doorTimer >= 5.0) { jump = 1.2; shake = 1.5; endG(2, '${p.name} kapidan girdi'); return; } }
        else if (distR < 3.5 && !rdC) { p.doorTimer += dt; if (p.doorTimer >= 5.0) { jump = 1.2; shake = 1.5; endG(2, '${p.name} kapidan girdi'); return; } }
        else p.doorTimer = 0;
      }
    }
    final me = getP(myId); if (me != null) { myIn = me.inside; myCd = max(0.0, me.cd - gt); myB = me.boost > gt; }
    if (now() - tN > 0.1) { tN = now(); bSnap(); }
  }

  void moveL(double dt) {
    if (page != 3 || win != 0 || map == null) return; if (myRole != 0 && myRole != 1) return;
    final d = Offset(jx, jy); mv = d.distance > 0.1;
    if (mv) { var dir = d; if (dir.distance > 1) dir = dir / dir.distance; final sp = spd(); final next = pos + dir * sp * dt; if (walk(next)) pos = next; else { final nx = pos + Offset(dir.dx * sp * dt, 0); if (walk(nx)) pos = nx; final ny = pos + Offset(0, dir.dy * sp * dt); if (walk(ny)) pos = ny; } }
    if (isHost) { final me = getP(myId); if (me != null) { me.x = pos.dx; me.y = pos.dy; me.mv = mv; me.room = roomAt(pos); } }
  }

  double spd() { double s = 3.0; if (myChar >= 0 && myChar < chars.length) { s = chars[myChar].sp; if (chars[myChar].pas == 'speed') s *= 1.15; } if (myB) s *= 1.6; if (myIn) s *= 0.85; return s; }
  void sendS() { tS = now(); toH({'t': 'state', 'p': {'x': pos.dx, 'y': pos.dy, 'mv': mv}}); }
  void gAct(String a) { if (page != 3 || myRole != 0 || win != 0) return; if (isHost) act(myId, a); else toH({'t': 'act', 'p': {'a': a}}); }
  void inter() { if (page != 3 || myRole != 1 || win != 0) return; final a = ctx(); if (a == 'none') return; if (isHost) act(myId, a); else toH({'t': 'act', 'p': {'a': a}}); }
  void abil() { if (page != 3 || myRole != 1 || win != 0 || myCd > 0) return; if (isHost) act(myId, 'ability'); else toH({'t': 'act', 'p': {'a': 'ability'}}); }
  String ctx() { if (page != 3 || map == null || myRole != 1) return 'none'; if (myIn) return 'attack'; if ((pos - map!.ld).distance < 3) return ldC ? 'forceL' : 'enterL'; if ((pos - map!.rd).distance < 3) return rdC ? 'forceR' : 'enterR'; if ((pos - map!.vt).distance < 3 && !ventC) return 'vent'; return 'none'; }

  void act(int id, String a) {
    if (page != 3 || win != 0 || map == null) return;
    final p = getP(id); if (p == null || !p.alive) return; p.seen = now();
    if (id == guard) { gAction(a); return; }
    if (p.role != 1 || p.charId < 0 || p.charId >= chars.length) return;
    final c = chars[p.charId];
    if (a == 'ability') { if (gt < p.cd) return; final double cdv = c.pas == 'focus' ? c.cd * 0.75 : c.cd; p.cd = gt + cdv; applyA(p, c); }
    else if (a == 'enterL') ent(p, 0);
    else if (a == 'enterR') ent(p, 1);
    else if (a == 'forceL') forc(p, 0, c);
    else if (a == 'forceR') forc(p, 1, c);
    else if (a == 'vent') ven(p, c);
    else if (a == 'attack') atk(p, c);
  }

  void gAction(String a) {
    if (black || lock > gt) return;
    if (a == 'doorL' && fL <= gt) { ldC = !ldC; dL = 0; }
    else if (a == 'doorR' && fR <= gt) { rdC = !rdC; dR = 0; }
    else if (a == 'flash') fl = !fl;
    else if (a == 'cam') cam = !cam;
    else if (a == 'ventClose') ventC = !ventC;
  }

  void ent(PN p, int s) { if (p.inside || map == null) return; final d = s == 0 ? map!.ld : map!.rd; if ((Offset(p.x, p.y) - d).distance > 3) return; if (s == 0 ? ldC : rdC) return; p.inside = true; p.side = s; p.room = -2; final i = s == 0 ? map!.il : map!.ir; p.x = i.dx; p.y = i.dy; if (p.id == myId) { myIn = true; pos = i; } }
  void forc(PN p, int s, CD c) { if (p.inside || map == null) return; final d = s == 0 ? map!.ld : map!.rd; if ((Offset(p.x, p.y) - d).distance > 3) return; if (!(s == 0 ? ldC : rdC)) return; if ((s == 0 ? fL : fR) > gt) return; double dm = 25; if (c.pas == 'door') dm *= 1.5; shake = max(shake, 0.5); if (s == 0) { dL += dm; if (dL >= 100) { dL = 0; ldC = false; fL = gt + 5; } } else { dR += dm; if (dR >= 100) { dR = 0; rdC = false; fR = gt + 5; } } }
  void ven(PN p, CD c) { if (p.inside || map == null || ventC) return; if ((Offset(p.x, p.y) - map!.vt).distance > 3) return; p.vent += (c.pas == 'vent' ? 0.6 : 0.34); if (p.vent >= 1) { p.vent = 0; p.inside = true; p.side = 2; p.room = -2; p.x = map!.iv.dx; p.y = map!.iv.dy; if (p.id == myId) { myIn = true; pos = Offset(p.x, p.y); } } }
  void atk(PN p, CD c) { if (!p.inside || map == null) return; bool rep = false; if (fl && !black && p.light < gt) rep = (c.pas == 'light') ? rnd.nextBool() : true; if (rep) { final o = outS(p.side); p.inside = false; p.vent = 0; p.x = o.dx; p.y = o.dy; p.room = roomAt(o); p.cd = max(p.cd, gt + 2); if (p.id == myId) { myIn = false; pos = o; } } else { jump = 1.2; shake = 1.5; endG(2, '${p.name} yakaladi'); } }
  Offset outS(int s) { if (map == null) return Offset.zero; if (s == 0) return map!.ld; if (s == 1) return map!.rd; return map!.vt; }

  void applyA(PN p, CD c) {
    if (map == null) return;
    if (c.act == 'speed') p.boost = gt + 4;
    else if (c.act == 'dash') { final d = map!.of.center - Offset(p.x, p.y); if (d.distance > 0.1) { final t = Offset(p.x, p.y) + (d / d.distance) * 4; if (walkF(t, p)) { p.x = t.dx; p.y = t.dy; if (p.id == myId) pos = t; } } }
    else if (c.act == 'camjam') jam = gt + 5;
    else if (c.act == 'doorbreak') { if ((Offset(p.x, p.y) - map!.ld).distance < 3.5) { ldC = false; fL = gt + 5; } else if ((Offset(p.x, p.y) - map!.rd).distance < 3.5) { rdC = false; fR = gt + 5; } }
    else if (c.act == 'ventrush') { if ((Offset(p.x, p.y) - map!.vt).distance < 3.5) { p.inside = true; p.side = 2; p.room = -2; p.x = map!.iv.dx; p.y = map!.iv.dy; if (p.id == myId) { myIn = true; pos = Offset(p.x, p.y); } } }
    else if (c.act == 'drain') { if ((Offset(p.x, p.y) - map!.of.center).distance < 10) en = max(0.0, en - 10); }
    else if (c.act == 'lightimmune') p.light = gt + 5;
    else if (c.act == 'silent') p.silent = gt + 5;
    else if (c.act == 'noise') { if (map!.rooms.isNotEmpty) { nR = rnd.nextInt(map!.rooms.length); nU = gt + 3; } }
    else if (c.act == 'fear') lock = gt + 3;
    else if (c.act == 'scream') { lock = gt + 5; shake = max(shake, 1.0); }
    else if (c.act == 'teleport') { if (!p.inside && map!.rooms.isNotEmpty) { final r = map!.rooms[rnd.nextInt(map!.rooms.length)]; final t = r.r.center; p.x = t.dx; p.y = t.dy; p.room = roomAt(t); if (p.id == myId) pos = t; } }
    else if (c.act == 'sabotage') en = max(0.0, en - 6);
  }

  bool walkF(Offset o, PN p) { if (map == null) return false; if (p.role == 0) return map!.of.contains(o); if (p.inside) return map!.of.contains(o); if (map!.of.contains(o)) return false; for (var r in map!.rooms) if (r.r.contains(o)) return true; return false; }
  bool walk(Offset o) { if (map == null) return false; if (myRole == 0) return map!.of.contains(o); if (myIn) return map!.of.contains(o); if (map!.of.contains(o)) return false; for (var r in map!.rooms) if (r.r.contains(o)) return true; return false; }
  bool _hidden(PN p) { if (p.role != 1 || p.charId < 0 || p.charId >= chars.length) return false; if (p.silent > gt) return true; final pas = chars[p.charId].pas; return pas == 'quiet' || pas == 'ghost'; }

  void bSnap() {
    if (!isHost || page != 3) return;
    final ents = <Map>[];
    for (var p in pl) { if (!p.alive) continue; ents.add({'id': p.id, 'ch': p.charId, 'rl': p.role, 'x': p.x, 'y': p.y, 'rm': p.room, 'mv': p.mv, 'io': p.inside, 'cd': max(0.0, p.cd - gt), 'hid': _hidden(p), 'sp': p.boost > gt}); }
    toA({'t': 'snap', 'p': {'t': gt, 'e': en.round(), 'ld': ldC, 'rd': rdC, 'fl': fl, 'cam': cam, 'vc': ventC, 'jam': max(0.0, jam - gt), 'black': black, 'w': win, 'm': endMsg, 'g': guard, 'nr': nR, 'nu': nU, 'ents': ents}});
  }

  void snap(Map p) {
    if (page != 3) return;
    gt = gd(p['t']); en = gd(p['e']); ldC = gb(p['ld']); rdC = gb(p['rd']); fl = gb(p['fl']); cam = gb(p['cam']); ventC = gb(p['vc']); jam = gt + gd(p['jam']); black = gb(p['black']); guard = gi(p['g']); nR = gi(p['nr']); nU = gd(p['nu']);
    final w = gi(p['w']); if (w > 0) { final m = gs(p['m']); endL(w, m.isEmpty ? 'Oyun bitti' : m); return; }
    rem.clear();
    if (p['ents'] is List) for (final it in p['ents'] as List) { if (it is! Map) continue; final e = it.cast<String, dynamic>(); final id = gi(e['id']); if (id == myId) { myIn = gb(e['io']); myCd = gd(e['cd']); myB = gb(e['sp']); final hp = Offset(gd(e['x']), gd(e['y'])); if ((pos - hp).distance > 5) pos = hp; continue; } rem[id] = EV(id, gi(e['ch']), gi(e['rl']), gd(e['x']), gd(e['y']), gi(e['rm']), gb(e['mv']), gb(e['hid']), gb(e['io']), col(gi(e['ch']))); }
    tH = now();
  }

  void endG(int w, String m) { if (page != 3 || win != 0) return; win = w; endMsg = m; toA({'t': 'over', 'p': {'w': w, 'm': m}}); endL(w, m); }
  void endL(int w, String m) { if (page == 4) return; win = w; endMsg = m; page = 4; loop?.cancel(); loop = null; ui(); }
  void rmP(int id) { if (id == 0) return; if (page == 3 && id == guard) { pl.removeWhere((p) => p.id == id); eps.remove(id); endG(2, 'Guvenlik ayrildi'); return; } pl.removeWhere((p) => p.id == id); eps.remove(id); if (page == 2) lob(); else if (page == 3 && !pl.any((p) => p.role == 1 && p.alive)) endG(1, 'Kalmadi'); }
  PN? getP(int id) { for (var p in pl) if (p.id == id) return p; return null; }
  int roomAt(Offset o) { if (map == null) return -1; if (map!.of.contains(o)) return -2; for (int i = 0; i < map!.rooms.length; i++) if (map!.rooms[i].r.contains(o)) return i; return -1; }
  Offset rndS() { if (map == null || map!.rooms.isEmpty) return const Offset(-30, 0); final r = map!.rooms[rnd.nextInt(map!.rooms.length)].r; double mx = min(1.0, r.width * 0.25), my = min(1.0, r.height * 0.25); double x1 = r.left + mx, x2 = r.right - mx; double y1 = r.top + my, y2 = r.bottom - my; if (x2 < x1) x1 = x2 = r.center.dx; if (y2 < y1) y1 = y2 = r.center.dy; return Offset(x1 + rnd.nextDouble() * (x2 - x1), y1 + rnd.nextDouble() * (y2 - y1)); }
  int freeC(List<int> u) { for (int i = 0; i < 100; i++) { int c = rnd.nextInt(chars.length); if (!u.contains(c)) return c; } for (int c = 0; c < chars.length; c++) if (!u.contains(c)) return c; return 0; }
  String cn(int id) => (id < 0 || id >= chars.length) ? '?' : chars[id].n;
  Color col(int id) => (id < 0 || id >= chars.length) ? Colors.white : chars[id].color;

  List<EV> views() {
    final v = <EV>[];
    if (isHost) { for (var p in pl) { if (!p.alive) continue; v.add(EV(p.id, p.charId, p.role, p.x, p.y, p.room, p.mv, _hidden(p), p.inside, p.role == 0 ? Colors.cyan : col(p.charId))); } }
    else { rem.forEach((id, e) { if (id != myId) v.add(e); }); if (myId != -1 && myRole != -1) v.add(EV(myId, myChar, myRole, pos.dx, pos.dy, roomAt(pos), mv, false, myIn, myRole == 0 ? Colors.cyan : col(myChar))); }
    return v;
  }

  String det() { if (map == null || camRoom < 0 || camRoom >= map!.rooms.length) return ''; if (jam > gt) return 'PARAZIT'; final names = <String>[]; for (var v in views()) if (v.role != 0 && !v.inside && v.room == camRoom && v.mv && !v.hid) names.add(cn(v.ch)); String t = ''; if (nR == camRoom && nU > gt) t += 'SES! '; t += names.isEmpty ? 'Temiz.' : 'Hareket: ${names.join(', ')}'; return t; }
  String clock() { final double progress = (gt / night).clamp(0.0, 1.0).toDouble(); final int totalMinutes = (progress * 6 * 60).toInt(); final int hour = totalMinutes ~/ 60; final int minute = totalMinutes % 60; final int hour12 = hour == 0 ? 12 : hour; return '$hour12:${minute.toString().padLeft(2, '0')} AM'; }
  bool dangerAt(int side) { if (map == null) return false; final d = side == 0 ? map!.ld : map!.rd; for (var v in views()) if (v.role == 1 && !v.inside && !v.hid && (Offset(v.x, v.y) - d).distance < 3.5) return true; return false; }
  bool ventDanger() { if (map == null) return false; for (var v in views()) if (v.role == 1 && !v.inside && !v.hid && (Offset(v.x, v.y) - map!.vt).distance < 3.5) return true; return false; }
  int _usage() { int u = 1; if (ldC) u++; if (rdC) u++; if (fl) u++; if (cam) u++; if (ventC) u++; return u; }

  Widget _animBody(Color color, double h, {bool glow = false, int kind = 0}) => SizedBox(width: h * 0.66, height: h, child: CustomPaint(painter: AnimPainter(color, glow, kind)));
  Widget _card(Widget child, {VoidCallback? onTap}) => GestureDetector(onTap: onTap, child: Container(width: double.infinity, padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: const Color(0xFF0A0806), border: Border.all(color: const Color(0xFF5A0000), width: 1), borderRadius: BorderRadius.circular(10), boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 6, offset: Offset(0, 3))]), child: child));
  Widget _fnafButton(String label, Color color, VoidCallback? onTap) { final disabled = onTap == null; return GestureDetector(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), decoration: BoxDecoration(color: disabled ? const Color(0xFF1A1A1A) : Color.fromARGB(70, cr(color), cg(color), cb(color)), border: Border.all(color: disabled ? Colors.grey.shade800 : color, width: 2), borderRadius: BorderRadius.circular(8), boxShadow: disabled ? null : [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8)]), child: Text(label, style: TextStyle(color: disabled ? Colors.grey : color, fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 12, shadows: disabled ? null : [Shadow(color: color.withOpacity(0.8), blurRadius: 6)])))); }

  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: const Color(0xFF050505), appBar: AppBar(backgroundColor: const Color(0xFF0A0A0A), title: ShaderMask(shaderCallback: (r) => const LinearGradient(colors: [Color(0xFFFF3333), Color(0xFF990000)], begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(r), child: const Text('DARKESCAS', style: TextStyle(color: Colors.white, fontFamily: 'monospace', letterSpacing: 4, fontWeight: FontWeight.w900, shadows: [Shadow(color: Color(0xFFFF0000), blurRadius: 12)]))), body: SafeArea(child: _page()));
  Widget _page() { switch (page) { case 0: return _page0(); case 1: return _page1(); case 2: return _page2(); case 3: return _page3(); case 4: return _page4(); default: return _page0(); } }

  Widget _page0() {
    return Stack(children: [
      Container(decoration: const BoxDecoration(gradient: RadialGradient(colors: [Color(0xFF1A0808), Color(0xFF000000)], stops: [0.3, 1.0]))),
      ListView(padding: const EdgeInsets.all(20), children: [
        const SizedBox(height: 20),
        ShaderMask(shaderCallback: (r) => const LinearGradient(colors: [Color(0xFFFF4444), Color(0xFF660000)], begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(r), child: const Text('DARKESCAS', textAlign: TextAlign.center, style: TextStyle(fontSize: 44, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'monospace', letterSpacing: 6, shadows: [Shadow(color: Color(0xFFFF0000), blurRadius: 20), Shadow(color: Color(0x88000000), blurRadius: 40)]))),
        const Text('GECE GUVENLIGI - LAN KORKU', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF888888), fontFamily: 'monospace', fontSize: 11, letterSpacing: 3)),
        const SizedBox(height: 24),
        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [Text('NASIL OYNANIR', style: TextStyle(color: Color(0xFFFF3333), fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 13)), SizedBox(height: 8), Text('GUVENLIK: Sadece ofisi gorursun. Animatronikleri KAMERADAN izlersin. Kapi + isik + guc yonetimi.', style: TextStyle(fontSize: 11, color: Color(0xFFBBBBBB))), SizedBox(height: 4), Text('ANIMATRONIK: Koridorlarda gez, ofise siz, guvenligi yakala.', style: TextStyle(fontSize: 11, color: Color(0xFFBBBBBB))), SizedBox(height: 4), Text('KAPI ACIK + CANAVAR = 5 sn sonra YENIRSIN.', style: TextStyle(fontSize: 11, color: Color(0xFFFFAA33), fontWeight: FontWeight.bold))])),
        _card(TextField(controller: nameC, maxLength: 16, style: const TextStyle(color: Colors.white, fontSize: 16), decoration: const InputDecoration(labelText: 'Adin', labelStyle: TextStyle(color: Color(0xFF888888)), enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF442222))))), onChanged: (v) => myName = sanitizeName(v))),
        _card(const Text('HOST OL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)), onTap: () => hostGame()),
        _card(const Text('LOBI ARA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)), onTap: () => openDisc()),
        _card(Column(children: [TextField(controller: ipc, style: const TextStyle(color: Colors.white, fontSize: 16), decoration: const InputDecoration(labelText: 'Host IP', labelStyle: TextStyle(color: Color(0xFF888888)), hintText: '192.168.1.35')), const SizedBox(height: 8), _fnafButton('IP ILE KATIL', Colors.orange, () => joinIp())])),
        if (status.isNotEmpty) Text(status, textAlign: TextAlign.center, style: const TextStyle(color: Colors.amber, fontSize: 14, fontWeight: FontWeight.bold)),
      ]),
    ]);
  }

  Widget _page1() {
    return Stack(children: [
      Container(decoration: const BoxDecoration(gradient: RadialGradient(colors: [Color(0xFF001A0A), Color(0xFF000000)], stops: [0.3, 1.0]))),
      Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: ShaderMask(shaderCallback: (r) => const LinearGradient(colors: [Color(0xFF33FF66), Color(0xFF006622)]).createShader(r), child: Text('HOST ARANIYOR... (${disc.length})', style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 18)))),
        Expanded(child: disc.isEmpty ? const Center(child: CircularProgressIndicator(color: Color(0xFF33FF66))) : ListView(padding: const EdgeInsets.all(12), children: disc.map((d) => _card(Row(children: [const Text('H', style: TextStyle(fontSize: 28, color: Color(0xFF33FFCC), fontWeight: FontWeight.bold, shadows: [Shadow(color: Color(0xFF00FFAA), blurRadius: 8)])), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(d.s.isEmpty ? 'Host' : d.s, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)), Text('${d.a}:${d.p} - ${d.c}/$maxP', style: const TextStyle(fontSize: 11, color: Color(0xFF888888)))])), const Text('>', style: TextStyle(color: Color(0xFFFF4444), fontSize: 24, shadows: [Shadow(color: Color(0xFFFF0000), blurRadius: 6)]))]), onTap: () => joinD(d))).toList())),
        Padding(padding: const EdgeInsets.all(12), child: _fnafButton('GERI', Colors.grey, menu)),
      ]),
    ]);
  }

  Widget _page2() {
    final me = getP(myId); final selected = me?.charId ?? -1; final CD inf = chars[infoChar.clamp(0, chars.length - 1)]; final bool guardInfo = infoChar == -1;
    return Stack(children: [
      Container(decoration: const BoxDecoration(gradient: RadialGradient(colors: [Color(0xFF1A0808), Color(0xFF000000)], stops: [0.3, 1.0]))),
      ListView(padding: const EdgeInsets.all(16), children: [
        ShaderMask(shaderCallback: (r) => const LinearGradient(colors: [Color(0xFFFF4444), Color(0xFF660000)]).createShader(r), child: const Text('LOBI', style: TextStyle(color: Colors.white, fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 22, shadows: [Shadow(color: Color(0xFFFF0000), blurRadius: 8)]))),
        const SizedBox(height: 12),
        if (isHost) Wrap(spacing: 8, runSpacing: 8, children: [for (int mi = 0; mi < 4; mi++) SizedBox(width: 150, child: _fnafButton('HARITA ${mi + 1}', curMap == mi ? Colors.green : Colors.amber, () => setM(mi)))]),
        const SizedBox(height: 12),
        ...pl.map((p) => Container(margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFF0A0806), border: Border.all(color: p.id == guard ? const Color(0xFF00FFDD) : const Color(0xFF3A0000), width: p.id == guard ? 2 : 1), borderRadius: BorderRadius.circular(8), boxShadow: p.id == guard ? [BoxShadow(color: const Color(0x8800FFDD), blurRadius: 12)] : null), child: Row(children: [p.charId == 99 ? const Text('G', style: TextStyle(fontSize: 26, color: Color(0xFF00FFDD), fontWeight: FontWeight.bold, shadows: [Shadow(color: Color(0xFF00FFDD), blurRadius: 10)])) : (p.charId >= 0 ? _animBody(col(p.charId), 50, glow: true, kind: kindOf(p.charId)) : const Text('?', style: TextStyle(fontSize: 24, color: Colors.grey))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)), Text(p.charId < 0 ? 'secim...' : (p.charId == 99 ? 'GUVENLIK' : cn(p.charId)), style: const TextStyle(fontSize: 10, color: Color(0xFFBBBBBB)))])), if (p.id == guard) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFF00FFDD), borderRadius: BorderRadius.circular(4)), child: const Text('GUARD', style: TextStyle(color: Color(0xFF000000), fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold)))]))),
        const SizedBox(height: 14),
        const Text('ANIMATRONIK SEC', style: TextStyle(color: Color(0xFFBBBBBB), fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          GestureDetector(onTap: () { selC(99); infoChar = -1; ui(); }, child: Container(width: 82, padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: selected == 99 ? const Color(0x5500FFDD) : const Color(0xFF0A0806), border: Border.all(color: selected == 99 ? const Color(0xFF00FFDD) : const Color(0xFF3A3A3A), width: selected == 99 ? 2 : 1), borderRadius: BorderRadius.circular(8), boxShadow: selected == 99 ? const [BoxShadow(color: Color(0x8800FFDD), blurRadius: 12)] : null), child: const Column(children: [Text('G', style: TextStyle(fontSize: 30, color: Color(0xFF00FFDD), fontWeight: FontWeight.bold, shadows: [Shadow(color: Color(0xFF00FFDD), blurRadius: 8)])), SizedBox(height: 4), Text('GUVENLIK', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold))]))),
          ...chars.asMap().entries.map((e) { final i = e.key; final cd = e.value; final taken = pl.any((p) => p.id != myId && p.charId == i); final sel = selected == i; return GestureDetector(onTap: taken ? null : () { selC(i); infoChar = i; ui(); }, child: Container(width: 82, padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: sel ? Color.fromARGB(100, cr(cd.color), cg(cd.color), cb(cd.color)) : const Color(0xFF0A0806), border: Border.all(color: sel ? cd.color : (taken ? const Color(0xFF1A1A1A) : const Color(0xFF3A3A3A)), width: sel ? 2 : 1), borderRadius: BorderRadius.circular(8), boxShadow: sel ? [BoxShadow(color: cd.color.withOpacity(0.6), blurRadius: 10)] : null), child: Column(children: [_animBody(cd.color, 60, glow: sel, kind: kindOf(i)), const SizedBox(height: 4), Text(cd.n, style: TextStyle(fontSize: 10, color: taken ? Colors.grey : Colors.white, fontWeight: FontWeight.bold)), Text('H${cd.sp} C${cd.cd.toInt()}', style: const TextStyle(fontSize: 8, color: Color(0xFF888888)))]))); }).toList(),
        ]),
        const SizedBox(height: 16),
        _card(guardInfo ? const Column(children: [Row(children: [Text('G', style: TextStyle(fontSize: 56, color: Color(0xFF00FFDD), fontWeight: FontWeight.bold, shadows: [Shadow(color: Color(0xFF00FFDD), blurRadius: 16)])), SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('GUVENLIK', style: TextStyle(color: Color(0xFF00FFDD), fontWeight: FontWeight.bold, fontSize: 18, shadows: [Shadow(color: Color(0xFF00FFDD), blurRadius: 6)])), SizedBox(height: 6), Text('Kapilar, isik, kameralar, guc. Saat 6 AM dayan.', style: TextStyle(fontSize: 11, color: Color(0xFFBBBBBB)))]))]), SizedBox(height: 10), Text('Gece vardiyasinda tek basinasin...', style: TextStyle(fontSize: 12, color: Color(0xFF888888), fontStyle: FontStyle.italic))]) : Column(children: [Row(children: [_animBody(inf.color, 100, glow: true, kind: kindOf(infoChar)), const SizedBox(width: 14), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(inf.n, style: TextStyle(color: inf.color, fontWeight: FontWeight.w900, fontSize: 20, shadows: [Shadow(color: inf.color.withOpacity(0.8), blurRadius: 10)])), const SizedBox(height: 6), Text('AKTIF: ${actDesc(inf.act)}', style: const TextStyle(fontSize: 11, color: Color(0xFFBBBBBB))), Text('PASIF: ${pasDesc(inf.pas)}', style: const TextStyle(fontSize: 11, color: Color(0xFFBBBBBB))), Text('HIZ ${inf.sp} - CD ${inf.cd.toInt()}s', style: const TextStyle(fontSize: 10, color: Color(0xFF888888)))]))]), const SizedBox(height: 10)])),
        const SizedBox(height: 12),
        if (isHost) _fnafButton('OYUNU BASLAT', Colors.green, pl.length >= 2 ? startHost : null),
        if (status.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text(status, textAlign: TextAlign.center, style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold))),
      ]),
    ]);
  }

  Widget _page3() { if (map == null) return const Center(child: CircularProgressIndicator()); return ValueListenableBuilder<int>(valueListenable: fr, builder: (context, _, __) { final shk = shake > 0.01 ? Offset((rnd.nextDouble() - 0.5) * shake * 8, (rnd.nextDouble() - 0.5) * shake * 5) : Offset.zero; return Stack(children: [Transform.translate(offset: shk, child: myRole == 0 ? _guardView() : _intruderView()), Positioned(top: 0, left: 0, right: 0, child: _topHud()), if (jump > 0) _jumpscare(), Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: VignettePainter(0.9))))]); }); }

  Widget _topHud() { final powerColor = en > 60 ? Colors.green : en > 30 ? Colors.orange : Colors.red; return Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0xEE000000), const Color(0x88000000)], begin: Alignment.topCenter, end: Alignment.bottomCenter), boxShadow: const [BoxShadow(color: Color(0xAA000000), blurRadius: 10)]), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10), child: Row(children: [ShaderMask(shaderCallback: (r) => LinearGradient(colors: [const Color(0xFFFFDD88), const Color(0xFF886633)]).createShader(r), child: Text(clock(), style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.w900))), const Spacer(), if (myRole == 0) Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: powerColor.withOpacity(0.2), border: Border.all(color: powerColor, width: 1), borderRadius: BorderRadius.circular(4)), child: Text("KULLANIM: ${List.filled(_usage(), 'I').join()}", style: TextStyle(color: powerColor, fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold))), if (myRole == 0) const SizedBox(width: 10), Text('GUC %${en.round()}', style: TextStyle(color: powerColor, fontFamily: 'monospace', fontSize: 18, fontWeight: FontWeight.w900, shadows: [Shadow(color: powerColor.withOpacity(0.8), blurRadius: 8)]))])); }

  Widget _guardView() {
    return LayoutBuilder(builder: (context, c) {
      return Stack(children: [
        CustomPaint(size: Size(c.maxWidth, c.maxHeight), painter: OfficePainter(fr.value / 60.0, black)),
        Positioned(left: 0, right: 0, bottom: 0, height: c.maxHeight * 0.28, child: CustomPaint(painter: CheckerPainter())),
        if (dangerAt(0) || dangerAt(1)) Positioned(top: 8, left: 0, right: 0, child: Center(child: Container(width: 22, height: 22, decoration: BoxDecoration(color: fr.value ~/ 10 % 2 == 0 ? const Color(0xFFFF2222) : const Color(0xFF440000), shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Color(0xFFFF0000), blurRadius: 24), BoxShadow(color: Color(0x88FF0000), blurRadius: 40)])))),
        Positioned(left: 6, top: c.maxHeight * 0.12, bottom: c.maxHeight * 0.30, child: _doorWidget(0)),
        Positioned(right: 6, top: c.maxHeight * 0.12, bottom: c.maxHeight * 0.30, child: _doorWidget(1)),
        if (ventDanger() && !ventC) Positioned(top: 50, left: 0, right: 0, child: Center(child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: const Color(0x88FF8800), borderRadius: BorderRadius.circular(4)), child: const Text('HAVANDIRMADA SES!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, shadows: [Shadow(color: Color(0xFFFF4400), blurRadius: 8)])))),
        if (black) Positioned.fill(child: Container(color: const Color(0xEE000000), child: const Center(child: Text('GUC BITTI', style: TextStyle(color: Color(0xFFFF3333), fontSize: 36, fontWeight: FontWeight.w900, fontFamily: 'monospace', shadows: [Shadow(color: Color(0xFFFF0000), blurRadius: 20)])))),
        Positioned(left: 8, right: 8, bottom: 10, child: Wrap(alignment: WrapAlignment.center, spacing: 8, runSpacing: 8, children: [_fnafButton(ldC ? 'SOL AC' : 'SOL KAPAT', ldC ? Colors.red : Colors.green, black ? null : () => gAct('doorL')), _fnafButton(rdC ? 'SAG AC' : 'SAG KAPAT', rdC ? Colors.red : Colors.green, black ? null : () => gAct('doorR')), _fnafButton(fl ? 'ISIK KAPAT' : 'ISIK AC', Colors.yellow, black ? null : () => gAct('flash')), _fnafButton(cam ? 'KAMERAYI INDIR' : 'KAMERAYI KALDIR', Colors.cyan, black ? null : () => gAct('cam')), _fnafButton(ventC ? 'VENT AC' : 'VENT KAPAT', ventC ? Colors.red : Colors.green, black ? null : () => gAct('ventClose'))])),
        if (cam) _camView(),
        Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: CRTWarpPainter(fr.value / 60.0)))),
        Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: NoisePainter(fr.value ~/ 2, 0.4)))),
      ]);
    });
  }

  Widget _doorWidget(int side) { final closed = side == 0 ? ldC : rdC; final danger = dangerAt(side); final showFig = danger && !closed && fl; return Column(children: [Expanded(child: CustomPaint(painter: HazardPainter(), child: Container(margin: const EdgeInsets.all(4), width: 72, decoration: BoxDecoration(color: closed ? const Color(0xFF2A2A2A) : const Color(0xFF020204), border: Border.all(color: closed ? const Color(0xFFFF0000) : const Color(0xFF00AA44), width: 2), borderRadius: BorderRadius.circular(4), boxShadow: [BoxShadow(color: (closed ? const Color(0xFFFF0000) : const Color(0xFF00AA44)).withOpacity(0.5), blurRadius: 10)]), child: Center(child: closed ? const Text('X', style: TextStyle(fontSize: 28, color: Color(0xFFFF2222), fontWeight: FontWeight.w900, shadows: [Shadow(color: Color(0xFFFF0000), blurRadius: 12)])) : (showFig ? _animBody(const Color(0xFF1A0808), 120, glow: true, kind: 1) : (fl ? const Text('-', style: TextStyle(fontSize: 24, color: Colors.white70)) : const Text('.', style: TextStyle(color: Colors.white24, fontSize: 24))))))), const SizedBox(height: 6), ShaderMask(shaderCallback: (r) => const LinearGradient(colors: [Color(0xFFDDDDDD), Color(0xFF666666)]).createShader(r), child: Text(side == 0 ? 'SOL' : 'SAG', style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold)))]); }

  Widget _camMap(MD m) { double minX = m.of.left; double maxX = m.of.right; double minY = m.of.top; double maxY = m.of.bottom; for (final r in m.rooms) { minX = min(minX, r.r.left); maxX = max(maxX, r.r.right); minY = min(minY, r.r.top); maxY = max(maxY, r.r.bottom); } const double W = 180; const double H = 130; final double rw = maxX - minX; final double rh = maxY - minY; return Container(decoration: BoxDecoration(color: const Color(0xFF0A140A), border: Border.all(color: const Color(0xFF00FF44), width: 1), borderRadius: BorderRadius.circular(4), boxShadow: const [BoxShadow(color: Color(0x8800FF44), blurRadius: 10)]), padding: const EdgeInsets.all(6), child: SizedBox(width: W, height: H, child: Stack(children: [Positioned(left: (m.of.left - minX) / rw * W, top: (m.of.top - minY) / rh * H, width: m.of.width / rw * W, height: m.of.height / rh * H, child: Container(color: const Color(0xFF223322), child: const Center(child: Text('SEN', style: TextStyle(fontSize: 8, color: Colors.amber, fontWeight: FontWeight.bold, shadows: [Shadow(color: Color(0xFFFFAA00), blurRadius: 6)]))))), for (int i = 0; i < m.rooms.length; i++) Positioned(left: (m.rooms[i].r.left - minX) / rw * W, top: (m.rooms[i].r.top - minY) / rh * H, width: m.rooms[i].r.width / rw * W, height: m.rooms[i].r.height / rh * H, child: GestureDetector(onTap: () { camRoom = i; ui(); }, child: Container(decoration: BoxDecoration(color: i == camRoom ? const Color(0xFF336633) : const Color(0xFF0A140A), border: Border.all(color: i == camRoom ? const Color(0xFFFF3333) : const Color(0xFF00AA44), width: i == camRoom ? 2 : 1)), child: Center(child: Text('${i + 1}', style: TextStyle(fontSize: 9, color: i == camRoom ? const Color(0xFFFF6666) : const Color(0xFF00FF66), fontWeight: FontWeight.bold, shadows: [Shadow(color: i == camRoom ? const Color(0xFFFF0000) : const Color(0xFF00FF00), blurRadius: 4)])))))]) ))); }

  Widget _camView() { final m = map!; final inRoom = views().where((v) => v.role == 1 && !v.inside && !v.hid && v.room == camRoom).toList(); final roomName = camRoom >= 0 && camRoom < m.rooms.length ? m.rooms[camRoom].n : ''; return Positioned.fill(child: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF001A0A), Color(0xFF000804)], begin: Alignment.topLeft, end: Alignment.bottomRight)), padding: const EdgeInsets.all(14), child: Stack(children: [Column(children: [Row(children: [ShaderMask(shaderCallback: (r) => const LinearGradient(colors: [Color(0xFF33FF66), Color(0xFF008833)]).createShader(r), child: Text('CAM ${camRoom + 1} - $roomName', style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontWeight: FontWeight.w900, fontSize: 18))), const Spacer(), ShaderMask(shaderCallback: (r) => const LinearGradient(colors: [Color(0xFF33FF66), Color(0xFF008833)]).createShader(r), child: Text(clock(), style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 14))), const SizedBox(width: 8), if (fr.value ~/ 15 % 2 == 0) Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: const Color(0xFFFF2222), borderRadius: BorderRadius.circular(3), boxShadow: const [BoxShadow(color: Color(0xFFFF0000), blurRadius: 8)]), child: const Text('REC', style: TextStyle(color: Colors.white, fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 11)))], ), const SizedBox(height: 10), Expanded(child: Stack(children: [Container(decoration: BoxDecoration(color: const Color(0xFF02140A), border: Border.all(color: const Color(0xFF00FF44), width: 1), borderRadius: BorderRadius.circular(6))), Center(child: jam > gt ? ShaderMask(shaderCallback: (r) => const LinearGradient(colors: [Color(0xFF33FF66), Color(0xFF008833)]).createShader(r), child: const Text('PARAZIT', style: TextStyle(color: Colors.white, fontSize: 28, fontFamily: 'monospace', fontWeight: FontWeight.w900))) : inRoom.isEmpty ? ShaderMask(shaderCallback: (r) => const LinearGradient(colors: [Color(0xFF33FF66), Color(0xFF008833)]).createShader(r), child: const Text('- TEMIZ -', style: TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 18))) : Wrap(alignment: WrapAlignment.center, spacing: 20, children: inRoom.map((v) => Column(children: [_animBody(v.color, 110, glow: true, kind: kindOf(v.ch)), const SizedBox(height: 6), ShaderMask(shaderCallback: (r) => const LinearGradient(colors: [Color(0xFFFF5555), Color(0xFF880000)]).createShader(r), child: Text(cn(v.ch), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, shadows: [Shadow(color: Color(0xFFFF0000), blurRadius: 8)]))])).toList())), Positioned(left: 0, right: 0, top: (fr.value * 4.0) % 600 - 60, height: 30, child: Container(decoration: BoxDecoration(gradient: LinearGradient(colors: [const Color(0x00FFFFFF), const Color(0x22FFFFFF), const Color(0x00FFFFFF)])))), Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: NoisePainter(fr.value ~/ 1, 0.9)))), Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: VignettePainter(0.7)))), Positioned(right: 10, bottom: 10, child: _camMap(m))])), const SizedBox(height: 10), _fnafButton('KAMERAYI INDIR', Colors.cyan, () => gAct('cam'))]), ])); }

  Widget _intruderView() { return LayoutBuilder(builder: (context, c) { final size = Size(c.maxWidth, c.maxHeight); final m = map!; const scale = 7.0; final wc = m.of.center; Offset toScreen(Offset w) => Offset(size.width / 2 + (w.dx - wc.dx) * scale, size.height / 2 + (w.dy - wc.dy) * scale); return Stack(children: [Container(decoration: const BoxDecoration(gradient: RadialGradient(colors: [Color(0xFF0A1018), Color(0xFF000204)], stops: [0.3, 1.0]))), for (final r in m.rooms) _roomRect(r, toScreen, scale), _officeRect(m, toScreen, scale), _pointWidget(m.ld, toScreen, ldC ? 'K' : 'A', const Color(0xFFFF4444)), _pointWidget(m.rd, toScreen, rdC ? 'K' : 'A', const Color(0xFFFF4444)), _pointWidget(m.vt, toScreen, ventC ? 'X' : 'V', const Color(0xFFFFAA00)), ..._markers(toScreen), Positioned(left: 12, bottom: 12, child: _joystick()), Positioned(right: 12, bottom: 12, child: _actionButtons()), Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: VignettePainter(0.85)))), Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: NoisePainter(fr.value ~/ 3, 0.3))))]); }); }

  Widget _roomRect(Room r, Offset Function(Offset) toScreen, double scale) { final tl = toScreen(r.r.topLeft); return Positioned(left: tl.dx, top: tl.dy, width: r.r.width * scale, height: r.r.height * scale, child: Container(decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF1A2432), Color(0xFF0A1018)], begin: Alignment.topCenter, end: Alignment.bottomCenter), border: Border.all(color: const Color(0xFF3A5578), width: 1.5), borderRadius: BorderRadius.circular(6), boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 6, offset: Offset(0, 2))]), child: Align(alignment: Alignment.topLeft, child: Padding(padding: const EdgeInsets.all(3), child: Container(decoration: BoxDecoration(color: const Color(0xCC000000), borderRadius: BorderRadius.circular(2)), padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), child: Text(r.n, style: const TextStyle(color: Color(0xFF88AABB), fontSize: 8, fontFamily: 'monospace', fontWeight: FontWeight.bold)))))); }

  Widget _officeRect(MD m, Offset Function(Offset) toScreen, double scale) { final tl = toScreen(m.of.topLeft); return Positioned(left: tl.dx, top: tl.dy, width: m.of.width * scale, height: m.of.height * scale, child: Container(decoration: BoxDecoration(gradient: const RadialGradient(colors: [Color(0xFF664A22), Color(0xFF18100A)], stops: [0.2, 1.0]), border: Border.all(color: const Color(0xFFFFAA33), width: 2), borderRadius: BorderRadius.circular(8), boxShadow: const [BoxShadow(color: Color(0x88FFAA33), blurRadius: 16)]), child: Center(child: ShaderMask(shaderCallback: (r) => const LinearGradient(colors: [Color(0xFFFFDD88), Color(0xFF885522)]).createShader(r), child: const Text('OFIS', style: TextStyle(color: Colors.white, fontSize: 12, fontFamily: 'monospace', fontWeight: FontWeight.w900)))))); }

  Widget _pointWidget(Offset world, Offset Function(Offset) toScreen, String label, Color color) { final p = toScreen(world); return Positioned(left: p.dx - 12, top: p.dy - 12, child: Container(width: 24, height: 24, decoration: BoxDecoration(color: const Color(0xFF1A1A1A), border: Border.all(color: color, width: 2), borderRadius: BorderRadius.circular(4), boxShadow: [BoxShadow(color: color.withOpacity(0.7), blurRadius: 10)]), child: Center(child: Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold, shadows: [Shadow(color: color, blurRadius: 4)]))))); }

  List<Widget> _markers(Offset Function(Offset) toScreen) { final list = views().where((v) => isHost || v.id == myId || !v.hid).toList(); return list.map((v) { final p = toScreen(Offset(v.x, v.y)); final self = v.id == myId; return Positioned(left: p.dx - 18, top: p.dy - 28 - (self ? jump * 8 : 0), child: Column(children: [v.role == 0 ? Container(width: 30, height: 30, decoration: BoxDecoration(color: const Color(0xFF0A3344), shape: BoxShape.circle, border: Border.all(color: const Color(0xFF00FFDD), width: 2), boxShadow: const [BoxShadow(color: Color(0xFF00FFDD), blurRadius: 12)]), child: const Center(child: Text('G', style: TextStyle(color: Color(0xFF00FFDD), fontWeight: FontWeight.bold, fontSize: 16)))) : _animBody(v.color, 44, glow: true, kind: kindOf(v.ch)), Text(self ? 'SEN' : (v.role == 0 ? 'GUVENLIK' : cn(v.ch)), style: TextStyle(fontSize: 9, color: self ? const Color(0xFF00FFDD) : const Color(0xFFBBBBBB), fontFamily: 'monospace', fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 3)]))])); }).toList(); }

  Widget _actionButtons() { if (win != 0 || myRole != 1) return const SizedBox.shrink(); final a = ctx(); return Column(mainAxisSize: MainAxisSize.min, children: [_fnafButton(_ctxLabel(a), Colors.red, a == 'none' ? null : inter), const SizedBox(height: 10), _fnafButton(myCd > 0 ? 'BEKLE ${myCd.toStringAsFixed(1)}' : 'YETENEK', Colors.purple, myCd > 0 ? null : abil)]); }

  Widget _joystick() { return Container(width: 120, height: 120, decoration: BoxDecoration(color: const Color.fromRGBO(255, 255, 255, 0.08), shape: BoxShape.circle, border: Border.all(color: const Color(0xFFFF4444), width: 2), boxShadow: const [BoxShadow(color: Color(0x88FF0000), blurRadius: 12)]), child: Center(child: Container(width: 48, height: 48, decoration: BoxDecoration(color: Color.fromRGBO(255, 255, 255, 0.18 + (jx * jx + jy * jy) * 0.1), shape: BoxShape.circle, border: Border.all(color: const Color(0xFFFF4444), width: 1), boxShadow: const [BoxShadow(color: Color(0x88FFFFFF), blurRadius: 4)]), child: Center(child: Transform.translate(offset: Offset(jx * 10, jy * 10), child: Container(width: 20, height: 20, decoration: BoxDecoration(color: const Color(0xFFFF4444), shape: BoxShape.circle, boxShadow: const [BoxShadow(color: Color(0xFFFF0000), blurRadius: 8)]))))), ), )..add(GestureDetector(onPanStart: (d) => _updateJoystick(d.localPosition), onPanUpdate: (d) => _updateJoystick(d.localPosition), onPanEnd: (_) { jx = 0; jy = 0; ui(); })); }

  void _updateJoystick(Offset local) { const double radius = 50.0; final center = Offset(60, 60); var v = local - center; if (v.distance > radius) v = v / v.distance * radius; jx = min(1.0, max(-1.0, v.dx / radius)); jy = min(1.0, max(-1.0, v.dy / radius)); ui(); }

  Widget _jumpscare() { return Positioned.fill(child: Container(color: const Color.fromRGBO(0, 0, 0, 0.95), child: Stack(children: [Positioned.fill(child: CustomPaint(painter: NoisePainter(fr.value, 1.0))), Center(child: Transform.scale(scale: 1.0 + jump * 0.6, child: _animBody(const Color(0xFF3B0000), 340, glow: true))), const Positioned(bottom: 50, left: 0, right: 0, child: Center(child: Text('YAKALANDIN', style: TextStyle(color: Color(0xFFFF2222), fontSize: 36, fontWeight: FontWeight.w900, fontFamily: 'monospace', letterSpacing: 4, shadows: [Shadow(color: Color(0xFFFF0000), blurRadius: 20), Shadow(color: Color(0x88000000), blurRadius: 40)]))))])); }

  String _ctxLabel(String a) { switch (a) { case 'attack': return 'SALDIR'; case 'enterL': return 'SOL GIR'; case 'enterR': return 'SAG GIR'; case 'forceL': return 'SOL ZORLA'; case 'forceR': return 'SAG ZORLA'; case 'vent': return 'VENT'; default: return 'ETKILESIM'; } }

  Widget _page4() { final winGuard = win == 1; return Stack(children: [Container(color: const Color(0xFF000000)), Positioned.fill(child: CustomPaint(painter: NoisePainter(7, 0.5))), Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: VignettePainter(1.0)))), Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [ShaderMask(shaderCallback: (r) => LinearGradient(colors: winGuard ? [const Color(0xFFFFDD88), const Color(0xFF886633)] : [const Color(0xFFFF3333), const Color(0xFF660000)]).createShader(r), child: Text(winGuard ? '6:00 AM' : 'GAME OVER', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, fontFamily: 'monospace', letterSpacing: 6, color: Colors.white, shadows: [Shadow(color: winGuard ? const Color(0xFFFFAA00) : const Color(0xFFFF0000), blurRadius: 30), Shadow(color: const Color(0x88000000), blurRadius: 60)]))), const SizedBox(height: 16), Text(endMsg, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 16, fontStyle: FontStyle.italic)), const SizedBox(height: 30), _fnafButton('ANA MENU', Colors.grey, menu)]))]); }
}
