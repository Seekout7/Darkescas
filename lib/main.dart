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
