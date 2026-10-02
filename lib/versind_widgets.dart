import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'core.dart';
import 'data.dart';

const Color kVersindGreen = Color(0xFFA8D5A0);
const String kLogoAsset = 'assets/images/versind_logo.png';

// ═════════════════════════ App-wide background ═════════════════════════

/// The app-wide background. 0 = AMOLED black, 1 = Aurora (default), 2 = custom image.
/// Switching cross-fades. This is NOT the per-habit cover image.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.settings});
  final AppSettings settings;

  File? get _file {
    final p = settings.bgImagePath;
    if (p == null || p.isEmpty) return null;
    final f = File(p);
    return f.existsSync() ? f : null;
  }

  Widget _layer() {
    final mode = settings.bgMode;
    if (mode == 0) return const ColoredBox(key: ValueKey('bg-amoled'), color: Color(0xFF000000));
    if (mode == 2) {
      final f = _file;
      if (f != null) {
        return _CustomImageBackground(
          key: ValueKey('bg-img-${f.path}'),
          file: f,
          blur: settings.bgBlurOn ? settings.bgBlur : 0,
        );
      }
    }
    return const AuroraBackground(key: ValueKey('bg-aurora'));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 650),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (current, previous) => Stack(fit: StackFit.expand, children: [...previous, if (current != null) current]),
      child: _layer(),
    );
  }
}

class _CustomImageBackground extends StatelessWidget {
  const _CustomImageBackground({super.key, required this.file, required this.blur});
  final File file;
  final double blur;

  @override
  Widget build(BuildContext context) {
    Widget img = Image.file(file, fit: BoxFit.cover, cacheWidth: 1080, gaplessPlayback: true, errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.black));
    if (blur > 0.5) {
      // scale up a little so the blurred edges never show a dark fringe
      img = Transform.scale(scale: 1.12, child: ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur), child: img));
    }
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Colors.black),
          img,
          // keeps text readable on any photo
          ColoredBox(color: Colors.black.withValues(alpha: 0.4)),
        ],
      ),
    );
  }
}

/// Settings card for the background choice (kept here so Settings only needs one line).
class BackgroundSettingsCard extends StatefulWidget {
  const BackgroundSettingsCard({super.key, required this.store});
  final AppStore store;
  @override
  State<BackgroundSettingsCard> createState() => _BackgroundSettingsCardState();
}

class _BackgroundSettingsCardState extends State<BackgroundSettingsCard> {
  bool _busy = false;

  Future<void> _pick() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final img = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
      if (img == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final ext = img.path.contains('.') ? img.path.split('.').last : 'jpg';
      final dest = '${dir.path}/app_bg_${DateTime.now().millisecondsSinceEpoch}.$ext';
      await File(img.path).copy(dest);
      final old = widget.store.settings.bgImagePath;
      await widget.store.updateSettings((s) {
        s.bgImagePath = dest;
        s.bgMode = 2;
      });
      if (old != null && old != dest) {
        try {
          final f = File(old);
          if (f.existsSync()) f.deleteSync();
        } catch (_) {}
      }
    } catch (_) {
      // picker cancelled or platform quirk — keep the current background
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _mode(String label, int value) {
    final s = widget.store.settings;
    final on = s.bgMode == value;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        HapticFeedback.selectionClick();
        if (value == 2 && (s.bgImagePath == null || !File(s.bgImagePath!).existsSync())) {
          await _pick();
          return;
        }
        await widget.store.updateSettings((x) => x.bgMode = value);
      },
      child: Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Chip2(label, selected: on)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final s = store.settings;
    final hasImage = s.bgImagePath != null && File(s.bgImagePath!).existsSync();
    return Glass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Whole-app background', style: TextStyle(fontSize: 14.5, color: C.text)),
          const SizedBox(height: 4),
          const Text('This changes the background behind every screen. A habit\'s own cover image is set inside that habit.', style: TextStyle(fontSize: 12, height: 1.4, color: C.mute)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [_mode('AMOLED Black', 0), _mode('Aurora', 1), _mode('Custom image', 2)]),
          if (s.bgMode == 2) ...[
            const SizedBox(height: 8),
            Container(height: 1, color: Colors.white.withValues(alpha: 0.08)),
            const SizedBox(height: 12),
            if (hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(height: 92, width: double.infinity, child: Image.file(File(s.bgImagePath!), fit: BoxFit.cover, cacheWidth: 600)),
              ),
            if (hasImage) const SizedBox(height: 10),
            PillButton(label: _busy ? 'Opening…' : (hasImage ? 'Replace image' : 'Choose image'), filled: false, onTap: _pick),
            if (hasImage) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Expanded(child: Text('Blur', style: TextStyle(fontSize: 14.5, color: C.text))),
                  Switch(value: s.bgBlurOn, activeColor: Accent.color, onChanged: (v) => store.updateSettings((x) => x.bgBlurOn = v)),
                ],
              ),
              if (s.bgBlurOn)
                Row(
                  children: [
                    const Text('Soft', style: TextStyle(fontSize: 11, color: C.mute)),
                    Expanded(
                      child: Slider(
                        value: s.bgBlur.clamp(1.0, 30.0).toDouble(),
                        min: 1,
                        max: 30,
                        activeColor: Accent.color,
                        inactiveColor: Colors.white.withValues(alpha: 0.15),
                        onChanged: (v) => store.updateSettings((x) => x.bgBlur = v),
                      ),
                    ),
                    const Text('Heavy', style: TextStyle(fontSize: 11, color: C.mute)),
                  ],
                ),
            ],
          ],
        ],
      ),
    );
  }
}

// ═════════════════════════ Welcome: logo + name reveal ═════════════════════════

/// The cinematic brand reveal. Runs once (~2.6s) and then stops — nothing keeps animating.
/// Timeline: logo fades/scales in out of a blur → halo blooms and settles → "Versind" appears
/// letter by letter while its tracking tightens → a short accent line draws in.
class WelcomeBrand extends StatefulWidget {
  const WelcomeBrand({super.key});
  @override
  State<WelcomeBrand> createState() => _WelcomeBrandState();
}

class _WelcomeBrandState extends State<WelcomeBrand> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600));
  bool _started = false;

  static const String _name = 'VERSIND';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (MediaQuery.of(context).disableAnimations) {
      _c.value = 1;
    } else {
      Future.delayed(const Duration(milliseconds: 450), () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _iv(double t, double a, double b, [Curve curve = Curves.easeOutCubic]) => curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0).toDouble());

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Versind',
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final logoOpacity = _iv(t, 0.0, 0.26, Curves.easeOut);
          final logoScale = 0.80 + 0.20 * _iv(t, 0.0, 0.40);
          final logoBlur = 16 * (1 - _iv(t, 0.0, 0.36, Curves.easeOut));
          // halo: blooms to a peak, then settles to a quiet glow
          final glow = t < 0.18 ? 0.0 : (t < 0.46 ? _iv(t, 0.18, 0.46, Curves.easeOut) : 1 - 0.55 * _iv(t, 0.46, 0.92, Curves.easeInOut));
          final spacing = 1.0 + 9.0 * (1 - _iv(t, 0.26, 0.88, Curves.easeOutCubic));
          final lineW = 44.0 * _iv(t, 0.62, 0.92);

          Widget logo = Image.asset(kLogoAsset, width: 88, height: 88, filterQuality: FilterQuality.high);
          if (logoBlur > 0.1) logo = ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: logoBlur, sigmaY: logoBlur), child: logo);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 88,
                height: 88,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: -80,
                      top: -80,
                      width: 248,
                      height: 248,
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: (glow * 0.55).clamp(0.0, 1.0).toDouble(),
                          child: const DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [kVersindGreen, Color(0x00A8D5A0)]))),
                        ),
                      ),
                    ),
                    Opacity(opacity: logoOpacity, child: Transform.scale(scale: logoScale, child: logo)),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < _name.length; i++) ...[
                    () {
                      final a = 0.26 + i * 0.05;
                      final p = _iv(t, a, a + 0.24);
                      return Opacity(
                        opacity: p,
                        child: Transform.translate(
                          offset: Offset(0, 14 * (1 - p)),
                          child: Text(_name[i], style: const TextStyle(fontFamily: 'Syncopate', fontSize: 27, height: 1.15, fontWeight: FontWeight.w700, color: C.text)),
                        ),
                      );
                    }(),
                    if (i < _name.length - 1) SizedBox(width: spacing),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: lineW,
                height: 2,
                decoration: BoxDecoration(color: kVersindGreen, borderRadius: BorderRadius.circular(2), boxShadow: [BoxShadow(color: kVersindGreen.withValues(alpha: 0.5), blurRadius: 8)]),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A few slow drifting lights for the Welcome page only. One controller, ~16 dots; stops when
/// the page is left or when Android's "remove animations" is on.
class AmbientMotes extends StatefulWidget {
  const AmbientMotes({super.key});
  @override
  State<AmbientMotes> createState() => _AmbientMotesState();
}

class _AmbientMotesState extends State<AmbientMotes> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 45));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 1800),
        curve: Curves.easeIn,
        builder: (_, fade, child) => Opacity(opacity: fade, child: child),
        child: RepaintBoundary(child: CustomPaint(painter: _MotesPainter(_c), size: Size.infinite)),
      ),
    );
  }
}

class _MotesPainter extends CustomPainter {
  _MotesPainter(this.anim) : super(repaint: anim);
  final Animation<double> anim;

  static final List<List<double>> _seeds = List.generate(16, (i) {
    final r = math.Random(i * 7 + 3);
    return [r.nextDouble(), r.nextDouble(), 0.4 + r.nextDouble() * 0.9, r.nextDouble() * 6.283, 0.8 + r.nextDouble() * 1.6];
  });

  @override
  void paint(Canvas canvas, Size size) {
    final t = anim.value;
    for (final s in _seeds) {
      final y = ((s[1] - t * s[2] * 0.9) % 1.0 + 1.0) % 1.0;
      final x = s[0] + math.sin(t * 6.283 * 2 + s[3]) * 0.025;
      final edge = math.sin(y * math.pi); // fade near top and bottom
      final twinkle = 0.55 + 0.45 * math.sin(t * 6.283 * 6 + s[3]);
      final a = (0.32 * edge * twinkle).clamp(0.0, 1.0).toDouble();
      canvas.drawCircle(Offset(size.width * x, size.height * y), s[4], Paint()..color = Colors.white.withValues(alpha: a));
    }
  }

  @override
  bool shouldRepaint(_MotesPainter old) => false;
}

// ═════════════════════════ Date panel (Home + Planner) ═════════════════════════

const _monthNames = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
const _weekdayLong = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

const double _kWeekRowH = 64;
const kShortDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// A week of day "pills" — weekday name on top, a round date bubble below. The selected pill is a
/// single highlight that slides between days, so two days can never be lit at once.
/// selectedIndex < 0 means "the picked day is in another week" and shows no highlight.
class _WeekRow extends StatelessWidget {
  const _WeekRow({required this.days, required this.selectedIndex, this.onSelect});
  final List<DateTime> days;
  final int selectedIndex;
  final ValueChanged<int>? onSelect;

  @override
  Widget build(BuildContext context) {
    final today = dateOnly(DateTime.now());
    final accent = Accent.color;
    final n = days.length;
    return LayoutBuilder(
      builder: (context, cons) {
        final cell = cons.maxWidth / n;
        final pillW = cell - 4;
        final bubble = math.min(pillW - 8, 28.0);
        const h = _kWeekRowH;
        final pillR = BorderRadius.circular(pillW / 2);
        return SizedBox(
          height: h,
          child: Stack(
            children: [
              Row(
                children: List.generate(
                  n,
                  (i) => SizedBox(
                    width: cell,
                    height: h,
                    child: Center(
                      child: Container(
                        width: pillW,
                        height: h,
                        decoration: BoxDecoration(borderRadius: pillR, color: Colors.white.withValues(alpha: 0.05), border: Border.all(color: Colors.white.withValues(alpha: 0.08))),
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                left: cell * (selectedIndex < 0 ? 0 : selectedIndex) + 2,
                top: 0,
                width: pillW,
                height: h,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: selectedIndex < 0 ? 0 : 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: pillR,
                      color: accent.withValues(alpha: 0.20),
                      border: Border.all(color: accent.withValues(alpha: 0.75), width: 1.3),
                      boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.28), blurRadius: 12, offset: const Offset(0, 3))],
                    ),
                  ),
                ),
              ),
              Row(
                children: List.generate(n, (i) {
                  final d = days[i];
                  final on = i == selectedIndex;
                  final isToday = dateOnly(d) == today;
                  return SizedBox(
                    width: cell,
                    height: h,
                    child: Semantics(
                      button: onSelect != null,
                      selected: on,
                      label: '${_weekdayLong[d.weekday - 1]} ${d.day} ${_monthNames[d.month - 1]}',
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onSelect == null
                            ? null
                            : () {
                                HapticFeedback.selectionClick();
                                onSelect!(i);
                              },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 220),
                              style: TextStyle(fontSize: 11, fontWeight: on ? FontWeight.w700 : FontWeight.w500, color: on ? C.text : C.mute),
                              child: Text(kShortDays[d.weekday - 1]),
                            ),
                            const SizedBox(height: 5),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 260),
                              curve: Curves.easeOutCubic,
                              width: bubble,
                              height: bubble,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: on ? accent : Colors.white.withValues(alpha: 0.08),
                                border: Border.all(color: isToday && !on ? accent : Colors.transparent, width: 1.5),
                              ),
                              child: AnimatedDefaultTextStyle(
                                duration: const Duration(milliseconds: 220),
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: on ? C.base : C.text),
                                child: Text('${d.day}'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        );
      },
      );
  }
}

/// Fixed week panel for Home: month + year, the date, and one week of pills.
class DatePanel extends StatelessWidget {
  const DatePanel({super.key, required this.days, required this.selectedIndex, this.onSelect});
  final List<DateTime> days;
  final int selectedIndex;
  final ValueChanged<int>? onSelect;

  @override
  Widget build(BuildContext context) {
    final sel = days[selectedIndex.clamp(0, days.length - 1).toInt()];
    final today = dateOnly(DateTime.now());
    return Glass(
      radius: 28,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(child: Text('${_monthNames[sel.month - 1]} ${sel.year}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: C.text))),
                Text(
                  dateOnly(sel) == today ? 'Today' : '${_weekdayLong[sel.weekday - 1].substring(0, 3)}, ${sel.day} ${_monthNames[sel.month - 1].substring(0, 3)}',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Accent.color),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _WeekRow(days: days, selectedIndex: selectedIndex, onSelect: onSelect),
        ],
      ),
    );
  }
}

/// Planner week panel: swipe sideways (or use the arrows) to move through any week, past or future.
class PagedDatePanel extends StatefulWidget {
  const PagedDatePanel({super.key, required this.selected, required this.onSelect});
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;
  @override
  State<PagedDatePanel> createState() => _PagedDatePanelState();
}

class _PagedDatePanelState extends State<PagedDatePanel> {
  static const int _base = 5000;
  late final DateTime _baseMonday = _mondayOf(DateTime.now());
  late final PageController _pc = PageController(initialPage: _pageOf(widget.selected));
  late int _page = _pageOf(widget.selected);

  static DateTime _mondayOf(DateTime d) => DateTime(d.year, d.month, d.day - (d.weekday - 1));
  int _pageOf(DateTime d) => _base + (_mondayOf(d).difference(_baseMonday).inDays / 7).round();

  List<DateTime> _week(int page) {
    final m = DateTime(_baseMonday.year, _baseMonday.month, _baseMonday.day + 7 * (page - _base));
    return List.generate(7, (i) => DateTime(m.year, m.month, m.day + i));
  }

  @override
  void didUpdateWidget(PagedDatePanel old) {
    super.didUpdateWidget(old);
    if (dateOnly(widget.selected) != dateOnly(old.selected)) {
      final p = _pageOf(widget.selected);
      if (p != _page && _pc.hasClients) {
        _pc.animateToPage(p, duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
      }
    }
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    HapticFeedback.selectionClick();
    _pc.animateToPage(page, duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    final mid = _week(_page)[3];
    final sel = dateOnly(widget.selected);
    final today = dateOnly(DateTime.now());
    final accent = Accent.color;
    return Glass(
      radius: 28,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(tooltip: 'Previous week', visualDensity: VisualDensity.compact, onPressed: () => _goTo(_page - 1), icon: const Icon(Icons.chevron_left_rounded, color: C.mute)),
              Expanded(
                child: Text('${_monthNames[mid.month - 1]} ${mid.year}', maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: C.text)),
              ),
              IconButton(tooltip: 'Next week', visualDensity: VisualDensity.compact, onPressed: () => _goTo(_page + 1), icon: const Icon(Icons.chevron_right_rounded, color: C.mute)),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onSelect(today);
                  if (_page != _base && _pc.hasClients) _pc.animateToPage(_base, duration: const Duration(milliseconds: 380), curve: Curves.easeOutCubic);
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 10, 8, 10),
                  child: Text('Today', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: sel == today ? C.mute : accent)),
                ),
              ),
            ],
          ),
          SizedBox(
            height: _kWeekRowH,
            child: PageView.builder(
              controller: _pc,
              onPageChanged: (p) => setState(() => _page = p),
              itemBuilder: (context, page) {
                final days = _week(page);
                final idx = days.indexWhere((d) => dateOnly(d) == sel);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: _WeekRow(days: days, selectedIndex: idx, onSelect: (i) => widget.onSelect(days[i])),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════ Week capsules (habit streak visual) ═════════════════════════

/// A habit's week: a number over a weekday name for each day. Days completed in a row are joined into
/// ONE continuous capsule; days not done sit in faint pills; days the habit isn't scheduled stay dim.
class WeekCapsules extends StatelessWidget {
  const WeekCapsules({super.key, required this.days, required this.states, required this.color, this.todayIndex, this.showWeekday = true});
  final List<DateTime?> days; // null = empty cell
  final List<DotState?> states;
  final Color color;
  final int? todayIndex;
  final bool showWeekday;

  @override
  Widget build(BuildContext context) {
    final n = days.length;
    final rowH = showWeekday ? 56.0 : 38.0;
    final key = Object.hashAll([...states.map((e) => e?.index ?? -1), color.value]);
    final reduce = MediaQuery.of(context).disableAnimations;
    return TweenAnimationBuilder<double>(
      key: ValueKey(key),
      tween: Tween(begin: 0, end: 1),
      duration: reduce ? Duration.zero : const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => LayoutBuilder(
        builder: (context, cons) {
          final cell = cons.maxWidth / n;
          // runs of consecutive completed days
          final runs = <List<int>>[];
          int i = 0;
          while (i < n) {
            if (states[i] == DotState.done) {
              int j = i;
              while (j + 1 < n && states[j + 1] == DotState.done) {
                j++;
              }
              runs.add([i, j]);
              i = j + 1;
            } else {
              i++;
            }
          }
          final r = BorderRadius.circular(rowH / 2);
          return SizedBox(
            height: rowH,
            child: Stack(
              children: [
                for (int k = 0; k < n; k++)
                  if (states[k] == DotState.miss || (todayIndex == k && states[k] != DotState.done))
                    Positioned(
                      left: cell * k + 2,
                      width: cell - 4,
                      top: 0,
                      height: rowH,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: r,
                          color: Colors.white.withValues(alpha: states[k] == DotState.miss ? 0.07 : 0.04),
                          border: todayIndex == k ? Border.all(color: Accent.color, width: 1.4) : null,
                        ),
                      ),
                    ),
                for (final run in runs)
                  Positioned(
                    left: cell * run[0] + 2,
                    width: (cell - 4) + (cell * (run[1] - run[0])) * t,
                    top: 0,
                    height: rowH,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: r,
                        color: color,
                        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 3))],
                      ),
                    ),
                  ),
                Row(
                  children: List.generate(n, (k) {
                    final d = days[k];
                    final st = states[k];
                    if (d == null || st == null) return SizedBox(width: cell, height: rowH);
                    final done = st == DotState.done;
                    final off = st == DotState.off;
                    return SizedBox(
                      width: cell,
                      height: rowH,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('${d.day}', style: TextStyle(fontSize: showWeekday ? 15 : 13.5, fontWeight: FontWeight.w700, color: done ? C.base : (off ? C.mute.withValues(alpha: 0.55) : C.text))),
                          if (showWeekday) ...[
                            const SizedBox(height: 2),
                            Text(kShortDays[d.weekday - 1].toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 0.4, color: done ? C.base.withValues(alpha: 0.75) : C.mute.withValues(alpha: off ? 0.5 : 1))),
                          ],
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Number that counts up to its value, and re-counts whenever the value changes.
class CountUp extends StatelessWidget {
  const CountUp({super.key, required this.value, required this.style, this.suffix = ''});
  final int value;
  final TextStyle style;
  final String suffix;
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return Text('$value$suffix', style: style, maxLines: 1);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 750),
      curve: Curves.easeOutCubic,
      builder: (_, v, __) => Text('${v.round()}$suffix', style: style, maxLines: 1),
    );
  }
}

// ═════════════════════════ Connected dots (habit streak visual) ═════════════════════════

enum DotState { off, miss, done }

/// A row of dots where consecutive completed days are joined by a line.
/// Give [labels] (e.g. day numbers) to print inside the dots; otherwise done dots show a tick when large.
class ConnectedDots extends StatelessWidget {
  const ConnectedDots({super.key, required this.states, required this.color, this.todayIndex, this.radius = 6, this.labels});
  final List<DotState?> states; // null = empty cell (padding)
  final Color color;
  final int? todayIndex;
  final double radius;
  final List<String?>? labels;

  @override
  Widget build(BuildContext context) {
    final key = Object.hashAll([...states.map((e) => e?.index ?? -1), color.value]);
    return TweenAnimationBuilder<double>(
      key: ValueKey(key),
      tween: Tween(begin: 0, end: 1),
      duration: MediaQuery.of(context).disableAnimations ? Duration.zero : const Duration(milliseconds: 520),
      curve: Curves.easeOutCubic,
      builder: (_, t, __) => CustomPaint(
        size: Size(double.infinity, radius * 2 + 10),
        painter: _DotsPainter(states, color, todayIndex, radius, labels, t),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  _DotsPainter(this.states, this.color, this.today, this.r, this.labels, this.t);
  final List<DotState?> states;
  final Color color;
  final int? today;
  final double r, t;
  final List<String?>? labels;

  @override
  void paint(Canvas canvas, Size size) {
    final n = states.length;
    if (n == 0) return;
    final cw = size.width / n;
    final cy = size.height / 2;
    double cx(int i) => cw * (i + 0.5);

    // links first, so dots sit on top
    final link = Paint()
      ..color = color
      ..strokeWidth = r * 0.7
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < n - 1; i++) {
      if (states[i] == DotState.done && states[i + 1] == DotState.done) {
        final a = cx(i), b = cx(i + 1);
        canvas.drawLine(Offset(a, cy), Offset(a + (b - a) * t, cy), link);
      }
    }

    for (int i = 0; i < n; i++) {
      final s = states[i];
      if (s == null) continue;
      final c = Offset(cx(i), cy);
      switch (s) {
        case DotState.done:
          canvas.drawCircle(c, r, Paint()..color = color);
          if (labels != null && labels![i] != null) {
            _text(canvas, c, labels![i]!, C.base, r);
          } else if (r >= 10) {
            final p = Path()
              ..moveTo(c.dx - r * 0.42, c.dy + r * 0.02)
              ..lineTo(c.dx - r * 0.1, c.dy + r * 0.36)
              ..lineTo(c.dx + r * 0.46, c.dy - r * 0.32);
            canvas.drawPath(p, Paint()..style = PaintingStyle.stroke..strokeWidth = 2.2..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..color = C.base);
          }
          break;
        case DotState.miss:
          canvas.drawCircle(c, r, Paint()..color = Colors.white.withValues(alpha: 0.10));
          canvas.drawCircle(c, r - 0.7, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.4..color = Colors.white.withValues(alpha: 0.26));
          if (labels != null && labels![i] != null) _text(canvas, c, labels![i]!, C.mute, r);
          break;
        case DotState.off:
          canvas.drawCircle(c, r * 0.5, Paint()..color = Colors.white.withValues(alpha: 0.10));
          if (labels != null && labels![i] != null) _text(canvas, c, labels![i]!, C.mute.withValues(alpha: 0.6), r, shrink: true);
          break;
      }
      if (today == i) {
        canvas.drawCircle(c, r + 3.5, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.4..color = Accent.color);
      }
    }
  }

  void _text(Canvas canvas, Offset c, String text, Color col, double r, {bool shrink = false}) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontFamily: 'Poppins', fontSize: shrink ? r * 0.8 : r * 0.95, fontWeight: FontWeight.w600, color: col)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(c.dx - tp.width / 2, c.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(_DotsPainter o) => o.t != t || o.color != color || o.today != today || o.r != r || o.states.length != states.length || !_same(o.states, states);

  bool _same(List<DotState?> a, List<DotState?> b) {
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

// ═════════════════════════ Wavy consistency line ═════════════════════════

/// A smooth wavy line through connected circular points. Heights follow the rolling consistency;
/// it draws itself in once, eases when values change, and breathes very slightly while visible.
class WavyConsistency extends StatefulWidget {
  const WavyConsistency({super.key, required this.values, required this.color, this.height = 120});
  final List<double> values; // 0..1, oldest first
  final Color color;
  final double height;
  @override
  State<WavyConsistency> createState() => _WavyConsistencyState();
}

class _WavyConsistencyState extends State<WavyConsistency> with TickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1300));
  late final AnimationController _morph = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
  late final AnimationController _wave = AnimationController(vsync: this, duration: const Duration(seconds: 7));
  late List<double> _from = List.of(widget.values);
  late List<double> _to = List.of(widget.values);
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.of(context).disableAnimations;
    if (!_started) {
      _started = true;
      if (reduce) {
        _intro.value = 1;
      } else {
        _intro.forward();
      }
    }
    if (reduce) {
      _wave.stop();
    } else if (!_wave.isAnimating) {
      _wave.repeat();
    }
  }

  @override
  void didUpdateWidget(WavyConsistency old) {
    super.didUpdateWidget(old);
    if (!_same(old.values, widget.values)) {
      _from = _current();
      _to = List.of(widget.values);
      if (MediaQuery.of(context).disableAnimations) {
        _morph.value = 1;
      } else {
        _morph.forward(from: 0);
      }
    }
  }

  bool _same(List<double> a, List<double> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if ((a[i] - b[i]).abs() > 0.001) return false;
    }
    return true;
  }

  List<double> _current() {
    final k = Curves.easeOutCubic.transform(_morph.value);
    final n = _to.length;
    return List.generate(n, (i) {
      final f = i < _from.length ? _from[i] : _to[i];
      return f + (_to[i] - f) * k;
    });
  }

  @override
  void dispose() {
    _intro.dispose();
    _morph.dispose();
    _wave.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Consistency trend over the last ${widget.values.length} days',
      child: SizedBox(
        height: widget.height,
        child: RepaintBoundary(
          child: CustomPaint(
            size: Size.infinite,
            painter: _WavyPainter(
              values: () => _current(),
              color: widget.color,
              intro: _intro,
              wave: _wave,
              morph: _morph,
            ),
          ),
        ),
      ),
    );
  }
}

class _WavyPainter extends CustomPainter {
  _WavyPainter({required this.values, required this.color, required this.intro, required this.wave, required this.morph})
      : super(repaint: Listenable.merge([intro, wave, morph]));
  final List<double> Function() values;
  final Color color;
  final Animation<double> intro, wave, morph;

  @override
  void paint(Canvas canvas, Size size) {
    final v = values();
    final n = v.length;
    if (n < 2) return;
    const padX = 10.0, padTop = 14.0, padBottom = 12.0;
    final w = size.width - padX * 2;
    final h = size.height - padTop - padBottom;
    final phase = wave.value * math.pi * 2;
    final prog = Curves.easeOutCubic.transform(intro.value);

    // faint guides at 0 / 50 / 100 %
    final guide = Paint()..color = Colors.white.withValues(alpha: 0.06)..strokeWidth = 1;
    for (final g in [0.0, 0.5, 1.0]) {
      final y = padTop + (1 - g) * h;
      canvas.drawLine(Offset(padX, y), Offset(size.width - padX, y), guide);
    }

    final pts = List.generate(n, (i) {
      final x = padX + w * i / (n - 1);
      final wobble = math.sin(phase + i * 0.75) * 3.0 * (0.4 + 0.6 * v[i]); // slight, scaled by level
      final y = padTop + (1 - v[i].clamp(0.0, 1.0)) * h + wobble;
      return Offset(x, y);
    });

    // smooth path (Catmull-Rom → cubic)
    final path = Path()..moveTo(pts[0].dx, pts[0].dy);
    for (int i = 0; i < n - 1; i++) {
      final p0 = i == 0 ? pts[i] : pts[i - 1];
      final p1 = pts[i];
      final p2 = pts[i + 1];
      final p3 = i + 2 < n ? pts[i + 2] : pts[i + 1];
      final c1 = Offset(p1.dx + (p2.dx - p0.dx) / 6, p1.dy + (p2.dy - p0.dy) / 6);
      final c2 = Offset(p2.dx - (p3.dx - p1.dx) / 6, p2.dy - (p3.dy - p1.dy) / 6);
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }

    final metrics = path.computeMetrics().toList();
    final total = metrics.fold<double>(0, (a, m) => a + m.length);
    final drawn = Path();
    double left = total * prog;
    for (final m in metrics) {
      if (left <= 0) break;
      drawn.addPath(m.extractPath(0, math.min(left, m.length)), Offset.zero);
      left -= m.length;
    }

    // soft area under the line (clipped to the drawn x-range)
    final reachX = padX + w * prog;
    canvas.save();
    canvas.clipRect(Rect.fromLTRB(0, 0, reachX + 1, size.height));
    final area = Path.from(path)
      ..lineTo(pts.last.dx, size.height - padBottom)
      ..lineTo(pts.first.dx, size.height - padBottom)
      ..close();
    canvas.drawPath(
      area,
      Paint()..shader = ui.Gradient.linear(Offset(0, padTop), Offset(0, size.height), [color.withValues(alpha: 0.26), color.withValues(alpha: 0.0)]),
    );
    canvas.restore();

    // glow + line
    canvas.drawPath(drawn, Paint()..style = PaintingStyle.stroke..strokeWidth = 7..strokeCap = StrokeCap.round..color = color.withValues(alpha: 0.18)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    canvas.drawPath(drawn, Paint()..style = PaintingStyle.stroke..strokeWidth = 3.2..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round..color = color);

    // connected circular points — each appears as the line reaches it
    for (int i = 0; i < n; i++) {
      final frac = i / (n - 1);
      final pp = ((prog - frac) / 0.08 + 1).clamp(0.0, 1.0).toDouble();
      if (pp <= 0) continue;
      final last = i == n - 1;
      final r = (last ? 6.5 : 3.8) * pp;
      canvas.drawCircle(pts[i], r + 2.2, Paint()..color = const Color(0xFF000000).withValues(alpha: 0.55));
      canvas.drawCircle(pts[i], r, Paint()..color = last ? color : Colors.white.withValues(alpha: 0.92));
      if (!last) canvas.drawCircle(pts[i], r, Paint()..style = PaintingStyle.stroke..strokeWidth = 1.6..color = color);
      if (last) canvas.drawCircle(pts[i], r + 5, Paint()..color = color.withValues(alpha: 0.22 * pp));
    }
  }

  @override
  bool shouldRepaint(_WavyPainter old) => old.color != color;
}
