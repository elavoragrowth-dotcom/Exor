import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/cupertino.dart' show CupertinoPicker;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class C {
  static const base = Color(0xFF0B0B10);
  static const lime = Color(0xFFD4F25C);
  static const violet = Color(0xFF7B5CFF);
  static const teal = Color(0xFF00D9C0);
  static const orange = Color(0xFFF59E4B);
  static const text = Color(0xFFF2F2F0);
  static const mute = Color(0xFF9A9AA2);
}

const _h1Light = TextStyle(fontSize: 36, height: 1.15, fontWeight: FontWeight.w300, color: C.text);
const _h1Bold = TextStyle(fontSize: 36, height: 1.15, fontWeight: FontWeight.w700, color: C.lime);
const _sub = TextStyle(fontSize: 15, height: 1.55, fontWeight: FontWeight.w400, color: C.mute);
const _pagePad = EdgeInsets.fromLTRB(24, 24, 24, 140);

String fmtHour(int i) {
  final h = i % 12 == 0 ? 12 : i % 12;
  return '$h:00 ${i < 12 ? 'AM' : 'PM'}';
}

String dateLabel(DateTime d) {
  const wd = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];
  const mo = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
  return '${wd[d.weekday - 1]}, ${d.day} ${mo[d.month - 1]}';
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  final prefs = await SharedPreferences.getInstance();
  runApp(DaybookApp(prefs: prefs));
}

class DaybookApp extends StatelessWidget {
  const DaybookApp({super.key, required this.prefs});
  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Daybook',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: C.base,
        colorScheme: ColorScheme.fromSeed(seedColor: C.lime, brightness: Brightness.dark),
      ),
      home: Root(prefs: prefs),
    );
  }
}

// ───────────────────────── Root: aurora + onboarding/shell ─────────────────────────

class Root extends StatefulWidget {
  const Root({super.key, required this.prefs});
  final SharedPreferences prefs;

  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> with SingleTickerProviderStateMixin {
  late final AnimationController _aurora =
      AnimationController(vsync: this, duration: const Duration(seconds: 48))..repeat();
  late bool _onboarded = widget.prefs.getBool('onboarded') ?? false;

  String get _name => widget.prefs.getString('name') ?? '';
  int get _dayStart => widget.prefs.getInt('dayStart') ?? 6;

  Future<void> _finish(String name, int dayStart) async {
    await widget.prefs.setString('name', name);
    await widget.prefs.setInt('dayStart', dayStart);
    await widget.prefs.setBool('onboarded', true);
    if (mounted) setState(() => _onboarded = true);
  }

  Future<void> _reset() async {
    await widget.prefs.clear();
    if (mounted) setState(() => _onboarded = false);
  }

  @override
  void dispose() {
    _aurora.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _aurora,
              builder: (_, __) => CustomPaint(painter: AuroraPainter(_aurora.value)),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            switchInCurve: Curves.easeOutCubic,
            layoutBuilder: (current, previous) =>
                Stack(fit: StackFit.expand, children: [...previous, if (current != null) current]),
            child: _onboarded
                ? Shell(key: const ValueKey('shell'), name: _name, dayStart: _dayStart, onReset: _reset)
                : Onboarding(key: const ValueKey('onb'), onDone: _finish),
          ),
        ],
      ),
    );
  }
}

// ───────────────────────── Aurora background ─────────────────────────

class _Blob {
  const _Blob(this.color, this.alpha, this.cx, this.cy, this.r, this.sx, this.sy, this.phase);
  final Color color;
  final double alpha, cx, cy, r, phase;
  final int sx, sy;
}

class _Star {
  const _Star(this.x, this.y, this.r, this.phase, this.k);
  final double x, y, r, phase;
  final int k;
}

class AuroraPainter extends CustomPainter {
  AuroraPainter(this.t);
  final double t;

  static const _blobs = [
    _Blob(C.violet, .55, .25, .20, .85, 1, 2, 0.0),
    _Blob(C.teal, .36, .85, .45, .75, 2, 1, 2.1),
    _Blob(C.lime, .15, .15, .80, .70, 1, 1, 4.0),
    _Blob(C.orange, .20, .90, .95, .70, 2, 3, 5.2),
  ];

  static final List<_Star> _stars = () {
    final r = math.Random(11);
    return List.generate(
      40,
      (i) => _Star(r.nextDouble(), r.nextDouble(), .5 + r.nextDouble() * 1.1, r.nextDouble() * 6.28, 3 + r.nextInt(6)),
    );
  }();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = C.base);
    const tau = 2 * math.pi;
    for (final b in _blobs) {
      final c = Offset(
        size.width * (b.cx + 0.20 * math.sin(tau * t * b.sx + b.phase)),
        size.height * (b.cy + 0.12 * math.cos(tau * t * b.sy + b.phase)),
      );
      final radius = size.longestSide * b.r * 0.55 * (1 + 0.08 * math.sin(tau * t * 2 + b.phase));
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [b.color.withValues(alpha: b.alpha), b.color.withValues(alpha: 0)],
        ).createShader(Rect.fromCircle(center: c, radius: radius));
      canvas.drawCircle(c, radius, paint);
    }
    for (final s in _stars) {
      final a = 0.10 + 0.40 * (0.5 + 0.5 * math.sin(tau * t * s.k + s.phase));
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.r,
        Paint()..color = Colors.white.withValues(alpha: a),
      );
    }
  }

  @override
  bool shouldRepaint(AuroraPainter old) => old.t != t;
}

// ───────────────────────── Shared widgets ─────────────────────────

class Kicker extends StatelessWidget {
  const Kicker(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(fontSize: 12, letterSpacing: 2.4, fontWeight: FontWeight.w500, color: C.lime),
      );
}

class Glass extends StatelessWidget {
  const Glass({super.key, required this.child, this.padding = const EdgeInsets.all(20), this.radius = 28, this.tint = 0.08});
  final Widget child;
  final EdgeInsets padding;
  final double radius, tint;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: br,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white.withValues(alpha: tint + 0.05), Colors.white.withValues(alpha: tint * 0.5)],
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class Reveal extends StatefulWidget {
  const Reveal({super.key, required this.child, this.delayMs = 0});
  final Widget child;
  final int delayMs;
  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 750));
  late final Animation<double> _a = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
  late final Animation<Offset> _s =
      Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero).animate(_a);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _a, child: SlideTransition(position: _s, child: widget.child));
}

class PillButton extends StatefulWidget {
  const PillButton({super.key, required this.label, required this.onTap, this.enabled = true});
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final on = widget.enabled;
    return GestureDetector(
      onTapDown: on ? (_) => setState(() => _down = true) : null,
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: on
          ? () {
              HapticFeedback.lightImpact();
              widget.onTap();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: 58,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: on ? C.lime : Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(40),
            boxShadow: on
                ? [BoxShadow(color: C.lime.withValues(alpha: 0.35), blurRadius: 28, offset: const Offset(0, 8))]
                : [],
          ),
          child: Text(
            widget.label,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: on ? C.base : C.mute),
          ),
        ),
      ),
    );
  }
}

class Chip2 extends StatelessWidget {
  const Chip2(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: C.lime.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: C.lime.withValues(alpha: 0.35)),
        ),
        child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: C.lime)),
      );
}

// ───────────────────────── Onboarding ─────────────────────────

class Onboarding extends StatefulWidget {
  const Onboarding({super.key, required this.onDone});
  final Future<void> Function(String name, int dayStart) onDone;
  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  int _step = 0;
  int _hour = 6;
  final _name = TextEditingController();
  final _picker = FixedExtentScrollController(initialItem: 6);

  bool get _hasName => _name.text.trim().isNotEmpty;

  @override
  void dispose() {
    _name.dispose();
    _picker.dispose();
    super.dispose();
  }

  void _go(int s) {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _step = s);
  }

  Widget _welcome() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Reveal(delayMs: 100, child: Kicker('WELCOME')),
          const SizedBox(height: 14),
          const Reveal(delayMs: 250, child: Text('Every day is', style: _h1Light)),
          const Reveal(delayMs: 400, child: Text('a page worth filling.', style: _h1Bold)),
          const SizedBox(height: 24),
          const Reveal(
            delayMs: 600,
            child: Text(
              'Habits, plans, chapters and focus, woven into one calm place. First, two quick questions so it can feel like yours.',
              style: _sub,
            ),
          ),
          const SizedBox(height: 40),
          Reveal(delayMs: 800, child: PillButton(label: 'Begin', onTap: () => _go(1))),
        ],
      );

  Widget _nameStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Reveal(delayMs: 100, child: Kicker('01 · YOU')),
          const SizedBox(height: 14),
          const Reveal(delayMs: 220, child: Text('First things first,', style: _h1Light)),
          const Reveal(delayMs: 340, child: Text('what should I call you?', style: _h1Bold)),
          const SizedBox(height: 32),
          Reveal(
            delayMs: 520,
            child: Glass(
              radius: 40,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: TextField(
                controller: _name,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                cursorColor: C.lime,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: C.text),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  filled: false,
                  hintText: 'Your name',
                  hintStyle: TextStyle(fontSize: 22, fontWeight: FontWeight.w400, color: C.mute),
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) {
                  if (_hasName) _go(2);
                },
              ),
            ),
          ),
          const SizedBox(height: 32),
          Reveal(
            delayMs: 680,
            child: PillButton(label: 'Continue', enabled: _hasName, onTap: () => _go(2)),
          ),
        ],
      );

  Widget _hourStep() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Reveal(delayMs: 100, child: Kicker('02 · YOUR RHYTHM')),
          const SizedBox(height: 14),
          Reveal(delayMs: 220, child: Text('${_name.text.trim()}, when does', style: _h1Light)),
          const Reveal(delayMs: 340, child: Text('your day begin?', style: _h1Bold)),
          const SizedBox(height: 12),
          const Reveal(delayMs: 460, child: Text("I'll shape your plan around this hour.", style: _sub)),
          const SizedBox(height: 24),
          Reveal(
            delayMs: 580,
            child: Glass(
              radius: 32,
              padding: EdgeInsets.zero,
              child: SizedBox(
                height: 200,
                child: CupertinoPicker(
                  scrollController: _picker,
                  itemExtent: 54,
                  backgroundColor: Colors.transparent,
                  useMagnifier: true,
                  magnification: 1.08,
                  onSelectedItemChanged: (i) {
                    HapticFeedback.selectionClick();
                    setState(() => _hour = i);
                  },
                  children: List.generate(
                    24,
                    (i) => Center(
                      child: Text(
                        fmtHour(i),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 24,
                          fontWeight: FontWeight.w500,
                          color: C.text,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Reveal(
            delayMs: 720,
            child: PillButton(
              label: 'Start my day',
              onTap: () {
                widget.onDone(_name.text.trim(), _hour);
              },
            ),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final pages = [_welcome(), _nameStep(), _hourStep()];
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0.08, 0), end: Offset.zero).animate(anim),
                child: child,
              ),
            ),
            child: SizedBox(
              key: ValueKey(_step),
              width: double.infinity,
              child: pages[_step],
            ),
          ),
        ),
      ),
    );
  }
}

// ───────────────────────── Shell + nav ─────────────────────────

class _Tab {
  const _Tab(this.label, this.icon);
  final String label;
  final IconData icon;
}

class Shell extends StatefulWidget {
  const Shell({super.key, required this.name, required this.dayStart, required this.onReset});
  final String name;
  final int dayStart;
  final VoidCallback onReset;
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _i = 0;

  static const _tabs = [
    _Tab('Home', Icons.home_rounded),
    _Tab('Habits', Icons.local_fire_department_rounded),
    _Tab('Projects', Icons.auto_stories_rounded),
    _Tab('Stats', Icons.insights_rounded),
    _Tab('Planner', Icons.calendar_month_rounded),
    _Tab('Settings', Icons.tune_rounded),
  ];

  Widget _body() {
    switch (_i) {
      case 0:
        return HomePage(name: widget.name, dayStart: widget.dayStart);
      case 1:
        return const SoonPage(kicker: 'HABITS', light: 'Small things,', bold: 'done daily.', icon: Icons.local_fire_department_rounded, phase: 2,
            line: 'Streaks, the focus timer and the full habit detail screen will live here.');
      case 2:
        return const SoonPage(kicker: 'PROJECTS', light: 'Chapter by chapter,', bold: 'cleared.', icon: Icons.auto_stories_rounded, phase: 3,
            line: 'Your eight CA Inter subjects and every chapter, with revisions, will live here.');
      case 3:
        return const SoonPage(kicker: 'STATS', light: "How you're", bold: 'really doing.', icon: Icons.insights_rounded, phase: 4,
            line: 'Focus time, consistency and progress will be drawn here, one calm chart at a time.');
      case 4:
        return const SoonPage(kicker: 'PLANNER', light: 'Shape your', bold: 'day.', icon: Icons.calendar_month_rounded, phase: 1,
            line: 'A timeline of time blocks, with reminders, will live here.');
      default:
        return SettingsPage(name: widget.name, dayStart: widget.dayStart, onReset: widget.onReset);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: SafeArea(
            bottom: false,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 380),
              switchInCurve: Curves.easeOutCubic,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(anim),
                  child: child,
                ),
              ),
              child: KeyedSubtree(key: ValueKey(_i), child: _body()),
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 12 + MediaQuery.of(context).padding.bottom,
          child: GlassNav(tabs: _tabs, index: _i, onTap: (i) => setState(() => _i = i)),
        ),
      ],
    );
  }
}

class GlassNav extends StatelessWidget {
  const GlassNav({super.key, required this.tabs, required this.index, required this.onTap});
  final List<_Tab> tabs;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(36);
    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          height: 68,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: br,
            border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          ),
          child: LayoutBuilder(builder: (context, cons) {
            const small = 40.0;
            final big = cons.maxWidth - small * (tabs.length - 1);
            return Row(
              children: [
                for (int i = 0; i < tabs.length; i++)
                  Semantics(
                    button: true,
                    label: tabs[i].label,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (i != index) HapticFeedback.selectionClick();
                        onTap(i);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 420),
                        curve: Curves.easeOutCubic,
                        width: i == index ? big : small,
                        height: 52,
                        decoration: BoxDecoration(
                          color: i == index ? C.lime : Colors.transparent,
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: ClipRect(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                tabs[i].icon,
                                size: 22,
                                color: i == index ? C.base : C.text.withValues(alpha: 0.75),
                              ),
                              if (i == index) ...[
                                const SizedBox(width: 6),
                                Flexible(
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: 1),
                                    duration: const Duration(milliseconds: 450),
                                    builder: (_, v, child) => Opacity(opacity: v, child: child),
                                    child: Text(
                                      tabs[i].label,
                                      maxLines: 1,
                                      softWrap: false,
                                      overflow: TextOverflow.clip,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.base),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

// ───────────────────────── Pages ─────────────────────────

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.name, required this.dayStart});
  final String name;
  final int dayStart;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final h = now.hour;
    final part = (h >= 21 || h < 4) ? 3 : (h < 12 ? 0 : (h < 17 ? 1 : 2));
    const greet = ['Good morning,', 'Good afternoon,', 'Good evening,', 'Still up,'];
    const lines = [
      'A clean page. Fill it gently.',
      'Halfway through. Keep the thread.',
      'Softly now. Finish what matters.',
      'The quiet hours. Rest is part of the plan.',
    ];
    return ListView(
      padding: _pagePad,
      children: [
        Reveal(child: Kicker(dateLabel(now))),
        const SizedBox(height: 14),
        Reveal(delayMs: 120, child: Text(greet[part], style: _h1Light)),
        Reveal(
          delayMs: 240,
          child: Text('$name.', maxLines: 2, overflow: TextOverflow.ellipsis, style: _h1Bold),
        ),
        const SizedBox(height: 10),
        Reveal(delayMs: 380, child: Text(lines[part], style: _sub)),
        const SizedBox(height: 28),
        Reveal(
          delayMs: 520,
          child: Glass(
            child: Row(
              children: [
                const Ripple(),
                const SizedBox(width: 18),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Kicker('TODAY'),
                      SizedBox(height: 6),
                      Text('Nothing planned yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: C.text)),
                      SizedBox(height: 6),
                      Text('Your plan will gather here once the Planner arrives.',
                          style: TextStyle(fontSize: 13, height: 1.45, color: C.mute)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Reveal(
          delayMs: 680,
          child: Glass(
            child: Row(
              children: [
                const Icon(Icons.wb_twilight_rounded, color: C.lime, size: 28),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text('Your day begins', style: TextStyle(fontSize: 15, color: C.mute)),
                ),
                Text(fmtHour(dayStart), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: C.text)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class Ripple extends StatefulWidget {
  const Ripple({super.key});
  @override
  State<Ripple> createState() => _RippleState();
}

class _RippleState extends State<Ripple> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3600))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 88,
        height: 88,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) => CustomPaint(painter: _RipplePainter(_c.value)),
        ),
      );
}

class _RipplePainter extends CustomPainter {
  _RipplePainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final maxR = size.width / 2;
    for (int i = 0; i < 3; i++) {
      final p = (t + i / 3) % 1.0;
      final r = 8 + (maxR - 8) * Curves.easeOut.transform(p);
      canvas.drawCircle(
        c,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..color = C.lime.withValues(alpha: 0.55 * (1 - p)),
      );
    }
    canvas.drawCircle(
      c,
      14,
      Paint()
        ..color = C.lime.withValues(alpha: 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.drawCircle(c, 6, Paint()..color = C.lime);
  }

  @override
  bool shouldRepaint(_RipplePainter old) => old.t != t;
}

class SoonPage extends StatelessWidget {
  const SoonPage({
    super.key,
    required this.kicker,
    required this.light,
    required this.bold,
    required this.line,
    required this.phase,
    required this.icon,
  });
  final String kicker, light, bold, line;
  final int phase;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: _pagePad,
      children: [
        Reveal(child: Kicker(kicker)),
        const SizedBox(height: 14),
        Reveal(delayMs: 120, child: Text(light, style: _h1Light)),
        Reveal(delayMs: 240, child: Text(bold, style: _h1Bold)),
        const SizedBox(height: 28),
        Reveal(
          delayMs: 420,
          child: Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: C.lime, size: 30),
                const SizedBox(height: 16),
                Text(line, style: const TextStyle(fontSize: 16, height: 1.5, color: C.text)),
                const SizedBox(height: 18),
                Chip2('Arrives in Phase $phase'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.name, required this.dayStart, required this.onReset});
  final String name;
  final int dayStart;
  final VoidCallback onReset;

  Widget _row(String k, String v) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: const TextStyle(fontSize: 15, color: C.mute)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(v,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: C.text)),
          ),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: _pagePad,
      children: [
        const Reveal(child: Kicker('SETTINGS')),
        const SizedBox(height: 14),
        const Reveal(delayMs: 120, child: Text('Make it', style: _h1Light)),
        const Reveal(delayMs: 240, child: Text('yours.', style: _h1Bold)),
        const SizedBox(height: 28),
        Reveal(
          delayMs: 400,
          child: Glass(
            child: Column(
              children: [
                _row('Name', name),
                Container(height: 1, margin: const EdgeInsets.symmetric(vertical: 14), color: Colors.white.withValues(alpha: 0.08)),
                _row('Day begins', fmtHour(dayStart)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Reveal(
          delayMs: 560,
          child: Glass(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Start over', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: C.text)),
                const SizedBox(height: 6),
                const Text('Clears your name and day start, then replays the welcome.',
                    style: TextStyle(fontSize: 13, height: 1.45, color: C.mute)),
                const SizedBox(height: 18),
                PillButton(label: 'Replay welcome', onTap: onReset),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const Center(child: Text('Daybook · Phase 0 build', style: TextStyle(fontSize: 12, color: C.mute))),
      ],
    );
  }
}
